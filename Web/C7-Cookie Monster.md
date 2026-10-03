# Cookie Monster

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Easy-Medium
**Flag:** `[cyberspectre{c00k13s_4r3_d3l1c10us}]`

## Challenge description
![alt text](<C7-cookie monster.png>)
This website baked something special for you.

Your browser may have already received everything you need.

Link: https://cookie-monster-ctf.netlify.app/

**Hint 1:** Don't only inspect what is rendered.

**Hint 2:** Open the browser's developer tools.

**Hint 3:** Look under the site's stored cookie.

## Tools used
- Web browser
- Browser DevTools (`F12`), Application tab

## Initial recon
I read the description and the three hints first.

- **"Baked something special"** and the challenge name are word play on cookies, the small pieces of data a website stores in the browser.
- **"Your browser may have already received everything you need"** means the flag was sent to my browser when the page loaded, so I do not need to click anything.
- **Hint 1** says that looking at the rendered page is not enough.
- **Hint 2** says to open the developer tools.
- **Hint 3** says to look at the site's stored cookie.

I then opened the link. It is a bakery website called "The Cookie Monster", with sections on the story, the cookies, the process, and the shop. Nothing on it looked like a flag, and one line near the bottom says "Nothing to see here. Move along." The answer has to be in the cookie the site stored.

## What is a cookie?
A cookie is a small piece of data that a website stores in my browser. Websites use cookies to remember things, such as a login session or a language choice.

Each cookie has a few fields:

| Field | Meaning |
|---|---|
| Name | The label of the cookie, for example `session`. |
| Value | The data stored in the cookie. |
| Domain | The website the cookie belongs to. |
| Path | The part of the site where the cookie is sent. `/` means the whole site. |
| Expires | When the browser deletes the cookie. |
| HttpOnly | If ticked, JavaScript on the page cannot read the cookie. |
| Secure | If ticked, the cookie is only sent over HTTPS. |

A site sets a cookie in one of two ways. The server can send a `Set-Cookie` header in its response, or JavaScript on the page can set it. In both cases the cookie is stored on my computer, and my browser sends it back to the site on later requests. Because the cookie is stored on my computer, I can read it in the browser's developer tools.

## Solution
1. **Open the site.** It is a bakery page with no visible flag.

2. **Open the developer tools.** I pressed `F12`. Another way is to right-click the page and choose **Inspect**, or press `Ctrl + Shift + I`. On a Mac, use `Cmd + Option + I`.

3. **Open the storage view.** In Chrome or Edge, I clicked the **Application** tab. If it is not visible, click the `»` arrow at the end of the tab row to see the hidden tabs. In Firefox, the same view is in the **Storage** tab.

4. **Open the cookie list.** In the left sidebar, I expanded **Cookies** under the **Storage** heading and clicked the site's address:
   ```
   https://cookie-monster-ctf.netlify.app
   ```
   The table on the right lists every cookie the site stored. If the table is empty, press `F5` to reload the page while DevTools is open, so the cookies are set again.

5. **Read the odd cookie.** The table has one column for each field in the table above. I found this cookie:
   ```
   Name:  [cookie name]
   Value: [cookie value]
   ```

6. **Read the flag:**
   ```
   [add flag]
   ```

Two other ways to see the same data:
- **Console:** open the **Console** tab in DevTools, type `document.cookie`, and press Enter. It prints the cookies that JavaScript is allowed to read, which excludes ones marked HttpOnly.
- **Network tab:** reload the page with the **Network** tab open, click the first request (the page itself), and look for `Set-Cookie` in the **Response Headers**. This shows a cookie that the server sent.

## Dead ends
- None.

## Vulnerability / technique
This is sensitive information stored in a cookie (CWE-315, cleartext storage of sensitive information in a cookie). A cookie is stored on the visitor's computer, so the visitor can read it and can also change it. Anything placed in a cookie is visible to that visitor.

Real attacks use the same idea. Some websites store values such as `admin=false` or a user ID in a cookie and trust it, so a visitor who edits the cookie to `admin=true` gains access. Attackers also steal session cookies to take over a logged-in account without knowing the password. Malware called infostealers collects the cookies stored in browsers for this purpose.

## Fix / defense
- **Never store secrets or trust decisions in a cookie value.** Use a long random session ID as the cookie value, and keep the real data on the server.
- **Sign or encrypt any data that must be stored in a cookie.** Then a visitor cannot change it without the server noticing.
- **Set the security flags.** `HttpOnly` stops JavaScript from reading a cookie, `Secure` sends it only over HTTPS, and `SameSite` limits when it is sent with requests from other sites. These flags protect against attacks on the cookie, but the owner of the browser can still see all of their own cookies in DevTools, including HttpOnly ones. They do not make a flag or a secret safe to store there.
- **SOC relevance.** A session cookie used from a new country or a new browser shortly after login is a sign of session hijacking. Analysts watch for this in sign-in logs.

## Lessons learned
- Cookies are stored on the visitor's computer, so they are readable and editable by the visitor.
- The Application tab in DevTools (Storage tab in Firefox) shows cookies. Local storage and session storage are listed there as well, and are worth checking in web challenges.
- If a cookie value does not look like readable text, it may be encoded, for example in Base64, as in the Base64 Decode challenge. Try decoding it.
- The hints described the exact path: open DevTools, then look at the cookie.

## References
- MDN, HTTP cookies: https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Cookies
- Chrome DevTools, view and edit cookies: https://developer.chrome.com/docs/devtools/application/cookies
- CWE-315, Cleartext Storage of Sensitive Information in a Cookie: https://cwe.mitre.org/data/definitions/315.html
- OWASP, session management: https://owasp.org/www-community/attacks/Session_hijacking_attack