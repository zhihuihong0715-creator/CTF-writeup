# Elevated

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Hard
**Flag:** `[cyberspectre{cook1e_t4mp3r1ng_succ3ss}]`

## Challenge description
![alt text](C11-elevated.png)
The dashboard welcomes regular users. Somewhere behind the same application is an administrative view.

Do you belong there?

Link: https://corestack-ctf.netlify.app/

**Hint 1:** Think about how the application remembers who you are.

**Hint 2:** Inspect your browser's stored session information.

**Hint 3:** What happens if the role represented by the session changes?

**Hint 4:** Look closely at the value associated with your current authorization level.

## Tools used
- Web browser
- Browser DevTools (`F12`), Application tab

## Initial recon
I read the description and the four hints first.

- **"The dashboard welcomes regular users"** and **"somewhere behind the same application is an administrative view"** describe two roles in the same app: a regular user and an admin, and only the admin view has the flag.
- **Hint 1** asks how the application remembers who I am, which describes a session.
- **Hint 2** says to inspect the browser's stored session information. That is a cookie or a stored value, the same kind of place checked in the Cookie Monster challenge.
- **Hint 3** asks what happens if the role in the session changes. This is the core of the challenge: the role is not fixed once I log in, and changing it might change what I can access.
- **Hint 4** says to look at the value tied to my "authorization level", meaning the value that decides what I am allowed to do.

Read together, the hints describe checking a session value that stores a role, and testing what happens if that value is edited.

## What is a session, and what does "role" mean here?
A **session** is how a website remembers a visitor between page loads, since normal web requests do not otherwise carry any memory of who asked before. The site stores a piece of data, often in a cookie, that identifies the visitor and sometimes their permissions.

A **role** is a label that decides what a visitor can do, such as `guest`, `user`, or `admin`. A site that stores the role directly in a cookie and trusts it is making a mistake: the cookie lives on the visitor's own computer, so the visitor can read and change it. If the server does not check the role again on its own side, changing the cookie is enough to change what the visitor can access.

## Solution
1. **Enter the site as a guest.** No login was required. This gave me a normal dashboard, described in the challenge as the view for regular users.

2. **Open DevTools.** I pressed `F12`, then opened the **Application** tab (Chrome and Edge) or the **Storage** tab (Firefox), matching Hint 2. This is the same tab used in the Cookie Monster challenge.

3. **Find the role.** Under **Cookies**, I expanded the site's address and looked through the cookie table for a value that looked like a role or permission level, matching Hint 4. I found:
   ```
   Name:  [cookie name]
   Value: guest
   ```
   Local storage and session storage, also listed in the Application tab, are worth checking too, since some apps store the role there instead of in a cookie.

4. **Edit the value.** In the cookie table, I double-clicked the **Value** column for that cookie and changed it from `guest` to `admin`, then pressed Enter to save it. This directly tests Hint 3: what happens if the role in the session changes.

5. **Reload the page.** I pressed `Ctrl + R`. The dashboard now showed the administrative view, because the page (or the server) read the cookie again on reload and treated me as an admin this time.

6. **Read the flag.** The admin view contained:
   ```
   [add flag]
   ```

## Dead ends
- None. The hints described each step directly.

## Vulnerability / technique
This is broken access control through client-side role storage (CWE-602, client-side enforcement of server-side security, and it also fits CWE-269, improper privilege management). The application decided my role from a cookie that I control, instead of checking on its own server who I really am and what I am allowed to do.

This is a form of **privilege escalation**, where a visitor gains access to features or data beyond what they should have. It's one of the most common issues found in real web applications, and the OWASP Top 10 lists Broken Access Control as the single most common weakness category in web apps as of the 2021 list.

A well-known real-world case: in 2019, a Capital One breach exposed over 100 million customer records after an attacker exploited a misconfigured web application firewall to gain elevated access to cloud resources, another case of a system trusting a request more than it should have.

## Fix / defense
- **Never decide a user's role from data the browser controls.** The server should look up the visitor's real role from its own database, tied to a secure, unguessable session ID, on every request that needs authorization.
- **Sign or encrypt session data that has to leave the server**, so the browser cannot edit it without the server detecting the change. A common way to do this is a signed session token such as a JWT, checked and verified by the server rather than trusted at face value.
- **Check permissions on every request, not only at login.** Even if a role is set correctly at login, every later action that needs a permission should be re-checked on the server.
- **Test for this weakness directly.** Try changing role or ID values in cookies, local storage, and request parameters, and check whether the app still enforces the correct permission.
- **SOC relevance.** Logs showing a session suddenly gaining admin actions without a matching login or role-change event on the server side are worth investigating. This pattern also shows up in incident reports for privilege escalation attacks.

## Lessons learned
- A session or a role stored only in the browser is not trustworthy, because the visitor can change it.
- The Application (or Storage) tab in DevTools is the place to check stored session data, whether it is in a cookie, local storage, or session storage.
- Reading the hints as a sequence, not separately, made the intended path clear: find the session value, understand what it does, then test changing it.
- This challenge and Cookie Monster both used the Application tab, but for different purposes: Cookie Monster hid a flag directly in a cookie, while Elevated hid a flag behind an access check that trusted a cookie.

## References
- OWASP Top 10, A01:2021 Broken Access Control: https://owasp.org/Top10/A01_2021-Broken_Access_Control/
- CWE-602, Client-Side Enforcement of Server-Side Security: https://cwe.mitre.org/data/definitions/602.html
- CWE-269, Improper Privilege Management: https://cwe.mitre.org/data/definitions/269.html
- MDN, HTTP cookies: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Cookies