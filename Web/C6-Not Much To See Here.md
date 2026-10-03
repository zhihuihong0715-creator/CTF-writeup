# Not Much To See Here

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Easy-Medium
**Flag:** `[cyberspectre{v13w_s0urc3_g4ng]`

## Challenge description
![alt text](<C6-no much to see here.png>)
The page doesn't seem to contain anything interesting.

Sometimes the browser shows less than what the server actually sent you.

Link: https://totally-normal-site.netlify.app/

**Hint 1:** Don't only inspect what is rendered.

**Hint 2:** Check the page source.

**Hint 3:** Look at the files loaded by the page.

## Tools used
- Web browser
- View Page Source (`Ctrl + U`)
- Browser DevTools (`F12`)

## Initial recon
I read the description and the three hints first.

- **"The browser shows less than what the server actually sent you"** means some of the content is not visible on the screen but is still delivered to my browser.
- **Hint 1** says that looking at the rendered page is not enough. The rendered page is what the browser draws on the screen.
- **Hint 2** says to check the page source, which is the raw code the server sent.
- **Hint 3** says to look at the files the page loads, such as JavaScript and CSS files.

I then opened the link. The page has the title "Cool Website" and one heading, "Welcome to my totally normal website", followed by a line saying there is nothing to see. There is nothing else to click or read, so the answer has to be in the code behind the page.

## What the browser shows and what the server sends
When I open a website, the server sends my browser files, mainly:

- **HTML:** the structure and text of the page.
- **CSS:** the styling, such as colors and layout.
- **JavaScript (`.js` files):** the code that makes the page do things.

The browser reads all of these and draws the page. Only part of that is visible on the screen. Comments in the HTML, values inside JavaScript, and text hidden by CSS are all delivered to my computer, but they are not drawn. Anything the server sends to my browser is readable by me, because the browser needs it to run the page.

## Solution
1. **Open the page.** It shows only a heading and a line saying there is nothing to see.

2. **View the page source.** I pressed `Ctrl + U`. On a Mac, use `Cmd + Option + U`. Another way is to right-click the page and choose **View page source**. This opens a new tab with the raw HTML the server sent, without any drawing. The rendered page and the source can look very different.

3. **Look for loaded files.** In the source, I looked for `<script>` tags. A tag like `<script src="script.js">` means the page loads a JavaScript file named `script.js`. This matches Hint 3. The source also lists CSS files in `<link>` tags, which are worth checking too.

4. **Open `script.js`.** There are three ways to do it:
   - In the page source tab, click the file name in the `<script>` tag. The browser opens the file.
   - Type the file name after the domain name in the address bar:
     ```
     https://totally-normal-site.netlify.app/script.js
     ```
     A `src` value without a full address is relative to the page, so the file is at the site's root, right after the domain name.
   - Press `F12` to open DevTools. In Chrome or Edge, use the **Sources** tab. In Firefox, use the **Debugger** tab. Both list every file the page loaded. The **Network** tab lists them too, and refreshing the page while it is open shows each file as it loads.

5. **Search the file for the flag.** In `script.js`, I pressed `Ctrl + F` and searched for `cyberspectre`, the start of every flag in this CTF. Searching for `flag` also works. The file contained:
   ```
   [paste the line from script.js that contains the flag]
   ```

6. **Read the flag:**
   ```
   [add flag]
   ```

## Dead ends
- None.

## Vulnerability / technique
This is sensitive information left in client-side code (CWE-540, inclusion of sensitive information in source code). The flag was placed in a JavaScript file that every visitor downloads, so any visitor can read it. The technique is to inspect what the server sends, not only what the browser shows.

This is the same technique as Method 2 in the Nightglass challenge, where the expected value and the flag were stored in the page's JavaScript.

## Fix / defense
- **Keep secrets on the server.** Passwords, API keys, tokens, and private notes must never be in HTML, JavaScript, or CSS. Anything sent to the browser is public.
- **Do not rely on hiding.** Minifying or obfuscating JavaScript makes it harder to read, but the values are still in the file and can be recovered.
- **Clean up before publishing.** Remove test notes, debug code, and comments from files before deploying a site. Tools such as `gitleaks` and GitHub secret scanning search code for keys and passwords before they go public.
- **SOC relevance.** Reading the page source and its scripts is a standard step when an analyst investigates a suspicious page, such as a phishing site. The source shows where a login form sends the data it collects and which other files the page loads.

## Lessons learned
- The rendered page is not the whole page. Always check the source in web challenges.
- The steps are: view the page source (`Ctrl + U`), find the `<script>` and `<link>` tags, open each file, and search for `flag` or `cyberspectre`.
- DevTools **Sources** and **Network** list every file a page loads, including ones the page source does not make obvious.
- The three hints described the exact order of the solution.

## References
- MDN, what happens when you request a web page: https://developer.mozilla.org/en-US/docs/Learn_web_development/Getting_started/Web_standards/How_the_Web_works
- Chrome DevTools, Sources panel overview: https://developer.chrome.com/docs/devtools/sources
- CWE-540, Inclusion of Sensitive Information in Source Code: https://cwe.mitre.org/data/definitions/540.html
- gitleaks, tool for finding secrets in code: https://github.com/gitleaks/gitleaks