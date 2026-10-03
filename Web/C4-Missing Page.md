# Missing Page

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Warm-up
**Flag:** `[cyberspectre{404_custom_3rr0r]`

## Challenge description
![alt text](<C4-missing page.png>)
We couldn't find the page you were looking for.

But perhaps the error page knows more than it should.

Link: https://missing-page.netlify.app/

**Hint 1:** Trigger an error.

**Hint 2:** What happens when you request a page that doesn't exist?

## Tools used
- Web browser

## Initial recon
I read the description and hints first.

- **"The error page knows more than it should"** tells me the flag is not on the normal pages. It is on the error page, which may show information it was not meant to show.
- **Hint 1** says to trigger an error.
- **Hint 2** says what to do: request a page that does not exist.

I then opened the link. The homepage is a normal company website for "CyberSpectre Systems", with sections such as About, Services, and Research. Nothing on it looked like a flag, which confirmed that the answer is on the error page.

## Solution
1. **Trigger the error page.** I added a made-up word to the end of the website address:
   ```
   https://missing-page.netlify.app/asdf1234
   ```
   The word `asdf1234` can be anything, as long as no real page has that name. The site is hosted on a domain name, so I added the word after the domain name and a `/`.

2. **Understand what happened.** When a browser asks for a page, the server looks for it. If the page does not exist, the server answers with the status code **404 Not Found** and shows an error page. This is called a 404 page. Developers often build a custom 404 page and sometimes leave information on it that should not be there.

3. **Examine the 404 page.** This page showed different content from the homepage, so I checked it for hidden information. On an error page, the places to check are:
   - The visible text on the page
   - The page source (`Ctrl + U`), including HTML comments written as `<!-- ... -->`
   - The JavaScript files, in the **Sources** tab of DevTools (`F12`)
   - The response headers, in the **Network** tab of DevTools

   Where I found it: [describe where the flag was, for example "in the visible text of the 404 page" or "in an HTML comment in the page source"].

4. **Read the flag:**
   ```
   [add flag]
   ```

## Dead ends
- None.

## Vulnerability / technique
This is information disclosure through an error page (CWE-209, error messages that contain sensitive information). The site's 404 page showed more than a normal "page not found" message should. The technique is called forced browsing: request a page that does not exist, or one that is not linked anywhere, and see what the server returns.

## Fix / defense
- **Keep error pages generic.** A 404 page should only say the page was not found. It should not contain debug information, internal notes, comments, secrets, or flags.
- **Turn off verbose errors in production.** Detailed error messages help developers and attackers alike.
- **Watch for 404 spikes in logs (SOC relevance).** Attackers probe websites by requesting many paths that may exist, such as `/admin`, `/.env`, or `/wp-login.php`. Each miss is logged as a 404, so many 404 responses from one IP address in a short time is a common sign of scanning. A SOC analyst can spot this in web server logs.

## Lessons learned
- Read the hints as instructions. "Trigger an error" and "request a page that doesn't exist" describe the exact step.
- Error pages are worth checking in every web challenge, not just the main page.
- Check both the visible text and the page source, because information can be hidden in either.

## References
- MDN, HTTP 404 Not Found: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404
- CWE-209, Generation of Error Message Containing Sensitive Information: https://cwe.mitre.org/data/definitions/209.html