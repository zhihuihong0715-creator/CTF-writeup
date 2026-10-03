# AeroDyn Systems - Unlinked Portal

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Medium
**Flag:** `[cyberspectre{unl1nk3d_d1r3ct0ry_l34k_2026}]`

## Challenge description
![alt text](<C12-aerodyn systems.png>)
AeroDyn Systems is a defense and logistics company. We suspect their internal employee portal is exposed somewhere on their infrastructure, but it isn't linked from the public site.

Find your way to it.

**Note: Bruteforcing is not permitted.**

Link: https://aerodyn-systems.netlify.app/

**Hint 1:** Developers sometimes leave clues in places normal users never see.

**Hint 2:** Look for staging or development infrastructure.

**Hint 3:** Old backups can reveal information that the live application doesn't.

## Tools used
- Web browser
- View Page Source (`Ctrl + U`)

## Initial recon
I read the description and the three hints first.

- **"Exposed somewhere on their infrastructure, but it isn't linked from the public site"** means there is a real, working page with no link pointing to it. It has to be found by guessing a path, not by clicking.
- **"Bruteforcing is not permitted"** rules out testing large numbers of random paths or PINs. Every step has to come from a clue left somewhere in the site.
- **Hint 1** says clues sit in places normal users never see, which points at the page source, matching earlier challenges such as Not Much To See Here and Front-Door.
- **Hint 2** says to look for staging or development infrastructure, meaning a copy of the site meant for developers to test on, not for the public.
- **Hint 3** says old backups can reveal information the live app doesn't, meaning a saved copy of a file, often with an extension like `.bak`, can be read even though it is not meant to be public.

Together, the hints describe a chain: a hidden comment leads to a dev area, the dev area leads to a backup, and the backup leads to the real portal.

## Solution

### Step 1: find the hidden path in the page source
I checked the page source of each page on the site, matching Hint 1. On `about.html`, the HTML contained a commented-out link:
```html
<!-- /dev_v2/ -->
```
An HTML comment (`<!-- ... -->`) does not show on the rendered page but is still sent to every visitor and readable in the source. This one is a leftover reference to a development version of the site, matching Hint 2.

### Step 2: read the notes in the dev area
I visited the path from the comment:
```
https://aerodyn-systems.netlify.app/dev_v2/
```
Inside, two text files were readable:
```
https://aerodyn-systems.netlify.app/dev_v2/notes.txt
https://aerodyn-systems.netlify.app/dev_v2/deployment_log.txt
```
These files gave three pieces of information:
- A path, `/backups/`, matching Hint 3.
- A target username, `m_jenkins`.
- A mention that a PIN is required to log in, without stating the PIN itself.

### Step 3: find the PIN from the team page
The username `m_jenkins` looks like it belongs to a real staff member, so I checked `team.html`, the same kind of page used for the credential clue in the Meet the Team challenge. It listed a staff member named Mark Jenkins with an Employee ID:
```
EMP-4912
```
The notes from step 2 said a PIN was required, and the numeric part of the employee ID, `4912`, is the PIN. This matches the username, `m_jenkins`, formed from the first letter of "Mark" and the surname "Jenkins".

### Step 4: read the backup file
I visited the backups path found in step 2:
```
https://aerodyn-systems.netlify.app/backups/
```
Inside was a file named `config.json.bak`. The `.bak` extension marks it as a backup copy of a configuration file. A `.bak` file is often left behind by an editor or a deployment script and is not meant to be served to visitors, but if it sits in a folder the web server can read, the server will send it to anyone who asks for it by name, matching Hint 3. Opening it:
```
https://aerodyn-systems.netlify.app/backups/config.json.bak
```
showed a JSON configuration containing a vault path:
```
/staff_vault_8812/
```

### Step 5: log in to the portal
I visited the vault path:
```
https://aerodyn-systems.netlify.app/staff_vault_8812/
```
This is the internal employee portal the challenge description mentioned. I logged in with the username and PIN gathered from steps 2 and 3:
```
Username: m_jenkins
PIN: 4912
```
This revealed the flag:
```
[add flag]
```

## Attack chain
```
about.html source
  → HTML comment: /dev_v2/
  → dev_v2/notes.txt, deployment_log.txt
  → username m_jenkins, PIN required, path /backups/
  → team.html: Mark Jenkins, EMP-4912 → PIN 4912
  → /backups/config.json.bak
  → vault path /staff_vault_8812/
  → login: m_jenkins / 4912
  → Flag
```

## Dead ends
- None. Each hint pointed to the next file in the chain.

## Vulnerability / technique
This challenge chains several weaknesses that are common together in real assessments:

1. **Security through obscurity (CWE-656).** The developer portal and the dev area were not protected by a login or a firewall rule, only by having no public link. Anyone who finds or guesses the path can reach them.
2. **Sensitive information in comments (CWE-615).** The `/dev_v2/` path was left in an HTML comment on a public page.
3. **Backup files left accessible (CWE-530, exposure of backup file to an unauthorized control sphere).** `config.json.bak` was reachable by direct request, even though it was never meant to be browsed to.
4. **PIN-based authentication built from public data (CWE-521).** A four-digit PIN taken directly from a public employee ID is guessable by anyone who reads the team page, and normally would also be a very short brute-force target, which is why this challenge explicitly rules bruteforcing out and expects the PIN to be found instead.

## Fix / defense
- **Never rely on a hidden link as the only protection for a real system.** Staging environments, admin portals, and internal tools need their own authentication and, ideally, should not be reachable from the public internet at all.
- **Remove references to internal or staging paths from public code**, including HTML comments, JavaScript, and configuration files shipped to the browser.
- **Do not leave backup files inside a folder the web server can serve.** Store backups outside the web root, or block extensions such as `.bak`, `.old`, and `.zip` at the server configuration level.
- **Do not build authentication secrets, such as a PIN, from data that is public elsewhere**, like an employee ID shown on a team page.
- **SOC relevance.** Automated scanners, both attacker tools and legitimate ones, request common backup and staging paths such as `/backup/`, `/.bak`, `/dev/`, and `/staging/` against any site they find. A burst of requests to unusual paths like these, especially ones returning a 200 OK rather than a 404, is worth flagging in web server logs.

## Lessons learned
- Read every page's source, not just the homepage, since a clue can sit on a page like `about.html` that looks unrelated to login.
- Build a chain of information as it is found: a hidden path led to notes, the notes led to a username and a required field, and a separate page (team.html) supplied the missing field.
- File extensions like `.bak` and folder names like `dev_v2` or `staging` are common patterns for developer leftovers, worth trying directly when a challenge or a real test says bruteforcing is off-limits.
- Public employee information can double as authentication material by accident, which is the same lesson as the Meet the Team challenge.

## References
- CWE-656, Reliance on Security Through Obscurity: https://cwe.mitre.org/data/definitions/656.html
- CWE-615, Information Exposure Through Comments: https://cwe.mitre.org/data/definitions/615.html
- CWE-530, Exposure of Backup File to an Unauthorized Control Sphere: https://cwe.mitre.org/data/definitions/530.html
- OWASP Testing Guide, testing for old backup and unreferenced files: https://owasp.org/www-project-web-security-testing-guide/