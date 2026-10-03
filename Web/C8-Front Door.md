# Front-Door

**CTF:** Cyberspectre, September 2026
**Category:** Web
**Difficulty:** Easy-Medium
**Flag:** `cyberspectre{d3f4ult_cr3ds_4lw4ys_w1n}`

## Challenge description
![alt text](<C8-front door.png>)
Someone deployed a website and apparently didn't spend much time thinking about the login. Can you get through the front door?

Link: https://cyberspectre-front-door.chals.io/

**Hint 1:** Developers sometimes leave useful information behind while working on a site. Inspect the source code of the pages, especially areas that seem related to staff or administration.

**Hint 2:** Try common credentials.

## Tools used
- Web browser
- View Page Source (`Ctrl + U`)

## Initial recon
I read the description and the two hints first.

- **"Didn't spend much time thinking about the login"** hints at a weak or default login, not a technical flaw.
- **Hint 1** says to check the page source, especially pages related to staff or admin.
- **Hint 2** says to try common credentials, meaning usernames and passwords that people often set without thinking.

I then explored the site. It is a small studio website, "Fernhollow Studio", with five pages: `index.html`, `about.html`, `team.html`, `contact.html`, and `admin.html`. The footer has a "Staff login" link, which points to the admin page and matches Hint 1's mention of staff and administration areas.

## Solution

### Step 1: explore the site
I clicked through the five pages. Nothing on the rendered pages showed a login or a password. The footer's "Staff login" link was the only clue pointing toward an admin area.

### Step 2: inspect the page source
I checked the source of each page with `Ctrl + U` (page source, not to be confused with `F12` DevTools, though both work here). A page's source is the raw HTML the server sends, and it can contain text that the browser does not draw on the screen, such as comments. `team.html` was the page with something hidden.

### Step 3: find the developer note
Inside the HTML of `team.html`, I found this comment:

```html
<!-- DEVELOPER NOTE - remove before launch
     The admin console is still running the temporary login from the
     staging build: admin : qwerty ... -->
```

An HTML comment starts with `<!--` and ends with `-->`. Anything between those marks is invisible on the rendered page, but it is still sent to every visitor and readable in the source. This one is a note a developer wrote for themselves and forgot to delete before the site went live.

The comment gives a username and a password, separated by a colon: `admin : qwerty`.

**About "common credentials" (Hint 2):** even without this comment, `admin` / `qwerty` is one of the first combinations any attacker tries. Lists of the most common leaked passwords, such as the SecLists project's `10-million-password-list-top-100.txt`, always contain `qwerty` near the top. Staging or test logins are often left with a simple password like this because a developer meant to change it before launch and forgot.

**About brute forcing:** the challenge notes that brute forcing is allowed but not needed here, since the password was found directly in the comment. Brute forcing means trying every password in a list until one works, using a tool such as `hydra` or Burp Suite's Intruder. It's a fallback for when no credential is given directly, and it works well against short lists of common passwords, but poorly against long, random ones.

### Step 4: reach the admin console
I used the "Staff login" link in the footer. The same page can also be reached by typing `/admin` after the site's address:

```
https://cyberspectre-front-door.chals.io/admin
```

### Step 5: authenticate
I entered:

```
Username: admin
Password: qwerty
```

and submitted the form. The check happens on the server, meaning the server receives the username and password and decides whether they are correct, rather than the check running in the page's own JavaScript. Login succeeded, and the page showed the flag:

```
cyberspectre{d3f4ult_cr3ds_4lw4ys_w1n}
```

## Attack chain
```
Website
  → Inspect page source
  → team.html
  → Developer HTML comment
  → Recovered credentials (admin : qwerty)
  → Admin / Staff login
  → Server-side auth
  → Flag
```

## Dead ends
- None. The developer comment gave the credentials directly.

## Vulnerability / technique
This challenge combines two weaknesses.

1. **Sensitive information left in a code comment (CWE-615, information exposure through comments).** The credentials sit in the HTML source, which the server sends to every visitor.
2. **Use of default or weak credentials (CWE-521, weak password requirements, and CWE-1392, use of default credentials).** `qwerty` is one of the most common passwords in the world, and staging credentials left unchanged in production are a frequent real-world finding.

## Fix / defense
- **Never leave credentials, even temporary ones, in HTML, JavaScript, comments, or any file sent to the browser.** Remove developer notes before deploying, and check for them with a search across the codebase for words like `TODO`, `FIXME`, `password`, and `staging` before every release.
- **Never reuse staging credentials in production**, and never use predictable passwords such as `qwerty`, `admin123`, or `password1`, even temporarily.
- **Rate-limit and lock out login attempts.** This slows down brute forcing, so weaker passwords become harder to exploit even if one is guessed.
- **SOC relevance.** Repeated login attempts against an admin page, especially with common usernames like `admin` or `root`, are a classic brute-force pattern in web server and application logs. A successful login right after many failures from the same source is worth investigating.

## Lessons learned
- Check the page source of every page in a web challenge, not just the homepage. The hidden clue here was on `team.html`, a page that looked unrelated to login.
- HTML comments (`<!-- ... -->`) are invisible on the page but fully readable in the source. They're a common place for developers to leave notes, including ones they should not.
- Try common credentials such as `admin`/`admin`, `admin`/`password`, or `admin`/`qwerty` even without a direct hint, since they are a normal first move in web testing.
- "Server-side auth" means the password check happens on the server, so the answer cannot be read out of the page's JavaScript the way it could in the Nightglass challenge.

## References
- CWE-615, Information Exposure Through Comments: https://cwe.mitre.org/data/definitions/615.html
- CWE-1392, Use of Default Credentials: https://cwe.mitre.org/data/definitions/1392.html
- SecLists, common password and credential lists: https://github.com/danielmiessler/SecLists
- OWASP Testing Guide, testing for default credentials: https://owasp.org/www-project-web-security-testing-guide/