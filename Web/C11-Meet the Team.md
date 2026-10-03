# Meet the Team

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Medium-Hard
**Flag:** `[cyberspectre{th3_m0tt0_w4s_th3_k3y}]`

## Challenge description
![alt text](<C11-meet the team.png>)
Not everything on the site is meant to be taken at face value.

There may be more to the company's online presence than what's immediately visible. Look around and see what you can uncover.

Link: https://nebula-meet-the-team.gamer.free/

**Hint 1:** Read the employee profiles carefully.

**Hint 2:** Look for something some employee has in common.

**Hint 3:** The answer isn't necessarily written as a username/password pair.

**Brief (from the challenge):** Each staff profile lists a personal "motto". One of them is actually a password.

## Tools used
- Web browser

## Initial recon
I read the description, the three hints, and the brief first.

- **"Not everything on the site is meant to be taken at face value"** and **"more to the company's online presence than what's immediately visible"** both say that something is hidden in plain sight among normal-looking content.
- **Hint 1** says to read the employee profiles carefully, so the login material is inside the profiles, not somewhere technical like a cookie or a header.
- **Hint 2** says to look for something some employees have in common. A "motto" is one type of content every profile has, so this points at comparing the mottos against each other.
- **Hint 3** says the answer isn't written as an obvious username/password pair. This warns that the credentials are not sitting together as `username: ...` and `password: ...`, so I had to build the pair myself.

## Solution
1. **Read every profile.** I opened the team page and went through each staff member's photo, name, role, and personal motto.

2. **Compare the mottos (Hint 2).** Most mottos read like normal phrases, for example an inspirational quote or a personal saying. One motto stood out because it did not read like a sentence at all. It looked like a password: no spaces, mixed upper and lower case, and numbers at the end.
   ```
   HighkeyMonkey123
   ```
   This matches Hint 3 directly. It was not labelled as a password, and it was not paired with a username on the same profile. It was disguised as a motto.

3. **Find the matching username.** Since the password was not paired with its own name, I had to pair it with a different profile. I tried the password against different staff names shown on the page until one combination worked, which is how "trying every possible possibility" is meant here. I paired it with:
   ```
   Marcus Johnson
   ```

4. **Log in.** I found the site's login form and entered:
   ```
   Username: Marcus Johnson
   Password: HighkeyMonkey123
   ```
   [Note where the login form was, for example a "Staff login" link, and note the exact username format the form accepted, since a login field often wants something like `marcus.johnson` rather than the full name shown on the page.]

5. **Read the flag.** Logging in revealed:
   ```
   [add flag]
   ```

## Dead ends
- Trying the odd-looking password against the profile it was listed under did not work, since the challenge deliberately separates the password from its matching username.
- [Add any names you tried before finding the right match, if you remember them.]

## Vulnerability / technique
This challenge is modelled on open-source intelligence, or OSINT, the practice of gathering information from public sources such as a company website, social media, or public documents. Real attackers use OSINT to build lists of employee names, job titles, email formats, and personal details, then use those details to guess passwords or answer security questions.

The specific weakness here is a predictable, personally meaningful password (CWE-521, weak password requirements) combined with information about it being published publicly by accident (CWE-200, exposure of sensitive information). A password built from a nickname and a short number, like `HighkeyMonkey123`, is exactly the kind of password a person picks because it is easy to remember, which also makes it easy to guess once an attacker knows a little about that person.

## Fix / defense
- **Never publish personal details that double as password material.** Pet names, nicknames, birthdays, and personal sayings are common password choices, so publishing them on a public team page helps an attacker guess passwords for that exact person.
- **Do not reuse personal information as a password anywhere**, even informally, since a phrase used in one public place, such as a company bio, can end up guessed for a login elsewhere.
- **Enforce strong, unpredictable passwords** through a policy or a password manager, and enable multi-factor authentication so a guessed password alone is not enough to log in.
- **SOC relevance.** Attackers build target lists from public employee pages before a phishing or credential-guessing campaign. A security team reviewing what is public about its own staff, sometimes called an OSINT self-assessment, is a normal defensive step, and unusual login attempts using employee names shortly after a public team page is updated is a pattern worth watching for.

## Lessons learned
- Content that looks harmless, like a personal motto, can be exactly where a challenge hides real login data.
- When a hint says the answer "isn't written as a pair", expect to build the pair yourself from two separate pieces of information on the page.
- Public "About us" or "Meet the team" pages are a real source of information attackers use, not just a CTF trick.

## References
- OWASP, testing for weak password policy: https://owasp.org/www-project-web-security-testing-guide/
- CWE-521, Weak Password Requirements: https://cwe.mitre.org/data/definitions/521.html
- CWE-200, Exposure of Sensitive Information to an Unauthorized Actor: https://cwe.mitre.org/data/definitions/200.html