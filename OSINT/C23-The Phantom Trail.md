# The Phantom Trail — Writeup

**CTF:** Cyberspectre, September 2026
**Category:** OSINT / Capstone
**Difficulty:** Capstone
**Flag format:** `cyberspectre{japan}`

## What we're given
![alt text](<C23-the phantom trail_1.png>)
![alt text](<C23-the phantom trail_2.png>)

One link: `https://phantom-canine.netlify.app/`

No name, no email, no starting point beyond the URL itself. The brief tells you three things worth paying attention to:

1. The target is a developer
2. Developers commonly publish their projects and code online
3. Not everything you find along the way should be trusted at face value

That last point matters more than it looks like at first. Keep it in mind for later.

## Step 1: Look at the site itself

Visiting the link shows a small personal blog titled **"House & Rufus"**, described as "notes on home life, mostly Rufus." It's gated behind a login screen, username and password fields, no public content behind them.

So there's nothing to read yet. But the URL itself is the first real clue: `phantom-canine.netlify.app`. Netlify is a free static-site host, which is exactly the kind of platform an individual developer would use for a personal blog, not a company. And `phantom-canine` isn't a generic subdomain, it reads like a deliberately chosen name.

## Step 2: Try a plain search first, then pivot

A plain Google search for `phantom-canine` mostly returns noise, generic pages, nothing tied to a real person. That's expected: it's a project codename, not something indexed widely across the open web.

The brief already told you where developers put their work: code hosting platforms. So the next move is searching GitHub directly rather than a general search engine, since project names and repo names are exactly what GitHub indexes and surfaces well.

Searching GitHub for `phantom-canine` turns up a real account:

**https://github.com/JeradFever**

## Step 3: Enumerate what this account has

The profile shows 6 public repositories, joined recently, one follower, and two pinned repos: `phantom-tools` (described as "small collection of experimental security utilities") and a fork of `VirusTotalUploader`. The naming convention, "phantom" showing up again, ties this account back to the blog's URL.

Going through the account's repositories rather than stopping at the pinned ones is the important move here. Pinned repos are what the owner wants visible; the real trail is usually in the repos they didn't bother curating.

Among the six repos is one named:

**https://github.com/JeradFever/cyber-phantom-99**

Its README reads: *"This is a personal blog, not accessible by randoms!"* with a direct link back to `https://phantom-canine.netlify.app`. That confirms the connection: this repo is the codebase behind the blog you started with.

## Step 4: Don't just read the current code, read the history

This is where Hint 3 comes in: *"If a secret appears to have been removed, remember that Git keeps a record of what happened."*

Git doesn't delete history by default. If a developer commits a secret (an API key, a password, a config file) and later removes it in a following commit, that secret is still sitting in the repository's commit history, fully readable, unless someone deliberately rewrites history to scrub it (which most people don't know how to do, or forget to do).

So instead of only looking at the latest version of the files, the move is checking the repo's commit log:

```
https://github.com/JeradFever/cyber-phantom-99/commits/main
```

Scrolling through the commit history, one entry stands out by its message alone:

**Commit `85dbfb4` — "chore: backup env before migration"**

That phrasing is a giveaway. "Backup env before migration" describes exactly the kind of throwaway, unthinking commit that happens when a developer copies their live environment file (the file that usually holds credentials, API keys, and database URLs) as a quick backup before restructuring their project, and forgets that committing it to Git means it's now permanent unless explicitly purged.

## Step 5: Read the diff

Opening that specific commit shows its changes: an environment/config file was added containing plaintext admin credentials, an `admin` username and a working password. Because Git preserves every commit even after later ones "remove" or overwrite a file, this credential pair is still fully visible by browsing to that exact commit, even if the current, latest version of the repo no longer shows it.

## Step 6: Use the credentials

Taking that recovered username and password back to the blog's login page:

```
https://phantom-canine.netlify.app/
```

logs in successfully. Access granted.

## Step 7: Read carefully, don't take everything at face value

This is where the brief's warning matters: *"don't assume everything you come across is genuine."*

Once inside, the blog's actual content is personal, low-key posts about home life and a dog named Rufus, plausible-sounding, easy to skim past. But scattered through the posts are small, easy-to-miss details, including references to **yen** as a currency. A currency mention in an otherwise mundane personal blog isn't filler, it's a planted signal. Yen is the currency of Japan, which is the detail the challenge is actually built around.

The instruction to stay skeptical is a reminder not to treat every post as equally meaningless small talk. Some of it is scenery. One or two details are the actual answer, dressed up as something forgettable.

## Step 8: Assemble the flag

Combining that currency reference with the country it belongs to:

```
cyberspectre{japan}
```

## Solve path summary

1. Start from the given blog URL and read it carefully, both the page content (gated, personal blog) and the URL itself (`phantom-canine`, hosted on Netlify).
2. Try a plain web search for `phantom-canine` first. It returns nothing useful, confirming this needs a more targeted search.
3. Recall the brief's hint that the target is a developer who publishes code online, and pivot to searching GitHub specifically for `phantom-canine`.
4. Find the matching account: `github.com/JeradFever`.
5. Enumerate all of the account's repositories, not just the pinned ones. Find `cyber-phantom-99`, whose README explicitly links back to the blog, confirming it's the right codebase.
6. Check the repo's commit history rather than just its current files. Git retains old commits even after later ones appear to remove sensitive data.
7. Find the suspicious commit `85dbfb4`, "chore: backup env before migration", and open its diff to recover a leftover admin username and password.
8. Log into the blog with the recovered credentials.
9. Read the unlocked content skeptically rather than skimming it as generic filler. A reference to yen currency is the planted clue pointing to Japan.
10. Submit: `cyberspectre{japan}`.