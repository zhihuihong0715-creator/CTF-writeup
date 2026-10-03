# Forgotten Directory — CTF Writeup

**CTF:** Cyberspectre, September 2026
**Category:** Web / Linux
**Points:** 250
**Flag:** `cyberspectre{v3rb_t4mp3r_1d0r_r00t}`

## What this challenge is actually testing

Three separate mistakes, chained together:

1. A developer left their `.git` folder exposed on a live web server.
2. An internal service only checks the HTTP method (GET vs POST), not real authentication.
3. That same service trusts a user-supplied ID number without checking who's asking for it (IDOR — Insecure Direct Object Reference).

None of these are exotic. They're the kind of mistakes real companies make constantly. That's exactly why this challenge is worth doing slowly.

---

## Part 1: Finding the exposed Git repo

### Why you even check for this

When developers use Git and later `git push` their code to a live server, they sometimes forget to exclude the `.git` folder from what the web server serves publicly. If that folder is reachable, you're not just looking at the current website — you're looking at its **entire history**, including files that were deleted before anyone made the site public.

### The check

Visit this in your browser, or use a terminal command:

```
https://target-site/.git/HEAD
```

**What you're looking for:** a `200 OK` response instead of `404 Not Found`. A `200` means the file exists and the server is happily serving it to anyone who asks.

**Linux/Mac (curl):**
```bash
curl -I https://target-site/.git/HEAD
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://target-site/.git/HEAD" -Method Head
```

Both do the same thing: send a HEAD request (headers only, no body) and show you the status code.

---

## Part 2: Dumping the repository

### Why

You can't just browse to `/.git/` in a browser and see a nice file tree — Git stores its data as compressed binary objects. You need a tool that understands Git's internal structure to walk through those objects and rebuild the actual files and folders.

### The tool: git-dumper

This tool crawls the exposed `.git` folder, downloads every object it can find, and reconstructs a working copy of the repository locally — as if you'd cloned it normally.

### Linux (Kali or any distro)

Git-dumper is usually preinstalled on Kali, or a single `pip install` away:

```bash
pip install git-dumper
git-dumper https://target-site/.git/ forgotten-repo
cd forgotten-repo
```

### Windows

Install Python first if you don't have it (check "Add Python to PATH" during setup — this matters, explained below), then:

```powershell
pip install git-dumper
```

**Important Windows-specific gotcha:** pip often installs the `git-dumper.exe` command into a folder that isn't on your PATH. PATH is the list of folders Windows searches through when you type a command name. If the folder isn't listed, typing `git-dumper` gives you "not recognized" even though the tool is installed correctly.

Fix it by adding the Scripts folder to PATH:

1. Start menu → search "Edit the system environment variables" → open it
2. Click **Environment Variables**
3. Under "User variables," select `Path` → **Edit** → **New**
4. Paste the folder path pip mentioned in its warning message (something like `...\LocalCache\local-packages\Python313\Scripts`)
5. OK your way out, then **close and reopen your terminal** — PATH only loads when a terminal starts, so an already-open window won't see the change

Then run:
```powershell
git-dumper https://target-site/.git/ forgotten-repo
cd forgotten-repo
```

---

## Part 3: Reading the commit history

### Why

Every commit is a snapshot with a message describing what changed. Attackers (and CTF players) read commit messages the same way you'd read a diary — looking for anything that hints at secrets, cleanup, or things someone wanted gone.

```bash
git log --oneline --all
```

The `--all` flag matters here — it shows commits across every branch, not just the one you happen to be on. A deleted file's commit might live on a branch that isn't checked out by default.

Somewhere in that log, a commit message reads something like **"remove leftover deploy notes"**. That phrasing alone is a strong signal — someone consciously removed something related to deployment, which often means credentials, config files, or internal notes.

---

## Part 4: Finding exactly what got deleted

### Why this specific command

`git log` on its own shows every commit. You don't want to scroll through all of them by hand — you want Git to filter for you.

```bash
git log --all --diff-filter=D --summary
```

Breaking that down:
- `--diff-filter=D` tells Git: only show commits where files were **D**eleted
- `--summary` prints which specific files changed in each commit

This narrows a long history down to just the handful of commits where something was removed. In this challenge, it points you straight to `deploy/credentials.txt`, deleted in commit `1f11a08`.

---

## Part 5: Recovering the deleted file

### Why this works at all

This is the core lesson of the whole challenge: **deleting a file in a new commit does not erase it from history.** The file still exists in every commit *before* the deletion. Git just stops showing it in the current working directory.

```bash
git show 1f11a08^:deploy/credentials.txt
```

The `^` after the commit hash means "the parent of this commit" — i.e., the state of the repo one step *before* the deletion happened. `:deploy/credentials.txt` tells Git which file, at that point in time, you want printed to your screen.

This returns the file's old contents:

```
ssh_user: devuser
ssh_pass: P@ssw0rd_Legacy2019
```

A working set of SSH credentials, recovered from a "deleted" file. This works identically on Windows and Linux — Git's internal history doesn't care what OS you're running it from.

---

## Part 6: Getting a shell

### Why SSH

The credentials you just recovered are for logging into the actual machine, not the website. This is the pivot point — you go from "reading a public web server" to "having a shell on the box."

**Linux:**
```bash
ssh devuser@target -p 17251
```

**Windows:**
Windows 10 and 11 ship with an OpenSSH client built in — you don't need PuTTY. Run the exact same command in PowerShell:
```powershell
ssh devuser@target -p 17251
```

Enter the recovered password when prompted. From this point on, you're inside the target machine's Linux shell. It no longer matters whether you connected from Windows or Linux — every command you type next runs on the remote box.

---

## Part 7: Finding the internal service

### Why you look here at all

Once you have a shell, the challenge hints tell you to look for something "running locally that isn't immediately visible from the outside." That's a strong pointer toward a service bound to `127.0.0.1` (localhost) — meaning it only accepts connections from inside the machine itself, not from the internet.

Poking around the filesystem turns up a world-readable file:

```bash
cat /opt/internal_service/app.py
```

Reading it shows a small Flask-style application, and the comments in the code describe its own weaknesses (a nice touch by the challenge author — read the code, don't just run it blind). It's bound to `127.0.0.1:9000`.

### Why "local only" matters

A service listening on `127.0.0.1` won't respond to requests from outside the machine, even if the machine has a public IP. You either need to interact with it *from inside* the machine (which you now can, via SSH), or forward that port out to your own computer using SSH port forwarding — the hint about "forwarding a remote port to your local system" is pointing at exactly this technique, useful if you want to poke at the service through your own browser instead of `curl` on the box.

---

## Part 8: The HTTP verb trick

### Why GET failed

```bash
curl http://127.0.0.1:9000/
```

This returns `405 Method Not Allowed`. Many people would stop here, assuming the route is broken or protected. It isn't — it's just picky about *how* you ask.

### Why POST worked

```bash
curl -X POST http://127.0.0.1:9000/
```

The route was coded to only accept `POST` requests, not `GET`. This is a deliberate (if slightly artificial) example of "verb tampering" — testing more than one HTTP method against the same endpoint before assuming it's inaccessible. Real-world APIs sometimes have this exact flaw, usually by accident rather than design.

---

## Part 9: The IDOR

### Why this is a vulnerability, not a feature

Once inside the portal, there's a route like:

```
/profile?id=8
```

The application fetches whatever profile matches the ID in the URL — **without checking whether the logged-in user is actually allowed to view that profile.** This is the textbook definition of IDOR: the "object" (a user profile) is referenced "directly" by an ID that anyone can just change.

### Why you'd think to try different IDs

If one ID works, nearby numbers probably work too. Walking through IDs (`?id=1`, `?id=2`, `?id=3`...) is a standard move once you spot a numeric ID in a URL with no visible access control.

ID 8 turns out to belong to the System Administrator.

---

## Part 10: Reading past what's visible

### Why "view all data on the profile" was a hint

The rendered page for admin's profile might look completely normal at first glance. The trick is that the *page source* — the raw HTML — contains more than what's rendered visually. Comments (`<!-- like this -->`) are invisible in a normal browser view but sit right there in the HTML if you look.

**In a browser:** right-click → View Page Source, or press Ctrl+U
**Or from the command line:**
```bash
curl http://127.0.0.1:9000/profile?id=8
```
and read the raw output rather than trying to render it.

Buried in a hidden HTML comment:
```
root / N0v4C0re_R00t_2024!
```

---

## Part 11: Root

### Why `su` instead of a fresh SSH login

The challenge instructions specifically say to use `su` rather than opening a new SSH session as root. This matters for two reasons: it's less disruptive to a shared environment (you're not opening a second connection), and it's simply the intended, tested path — deviating from it on a shared box risks weird side effects for other players.

```bash
su root
# enter: N0v4C0re_R00t_2024!
cat /root/root.txt
```

That last command prints your flag.

---

## The chain, in one line

Exposed `.git` → recovered deleted credentials → SSH access → local-only service found → verb tampering bypassed a 405 → IDOR walked the ID → hidden HTML comment leaked root → `su` → flag.

## Cleanup reminder

This was a shared instance. Before you're done:
- Delete the `forgotten-repo` folder you dumped locally (it's yours to keep for notes, but nothing needs to stay *on the target machine*)
- Don't leave any files you uploaded to the box itself
- Don't change permissions or touch anything beyond what the challenge asked for