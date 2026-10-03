# Auditor's Vault

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Medium
**Flag:** `[cyberspectre{h3ad3rs_t3ll_th3_ful1_st0ry}]`

## Challenge description
![alt text](<C9-auditor's vault.png>)
A security auditor inspected this application before it was locked down. They left something behind.

Take a closer look at what the application sends back.

Link: https://ridgeback-motorsport.netlify.app/

**Hint 1:** The browser receives more information than the HTML.

**Hint 2:** Open Developer Tools and watch the network traffic.

**Hint 3:** Inspect the response headers.

## Tools used
- Web browser
- Browser DevTools (`F12`), Network tab
- `curl` (optional, for the second route)

## Initial recon
I read the description and the three hints first.

- **"What the application sends back"** means the server's response, not only the page I see. A response has more parts than the visible page.
- **Hint 1** says the browser receives more than the HTML. That extra information is in the response headers.
- **Hint 2** says to open DevTools and watch the network traffic.
- **Hint 3** says exactly where to look: the response headers.

I then opened the link. It is a website for a racing team called "Ridgeback Motorsport", with pages for the team, the calendar, and partners. Nothing on the page looked like a flag. The footer says "Independent third-party security review completed prior to public launch", which matches the story of an auditor who left something behind.

## What are HTTP headers?
Every time a browser opens a page or loads a file such as an image, it sends a **request** to the server, and the server sends back a **response**. A response has two parts:

- **The body:** the content itself, such as the HTML of the page or the image.
- **The headers:** lines of extra information about the response, sent before the body. A browser uses headers but does not draw them on the page.

Headers are written as `Name: value`. Common examples:

```
Content-Type: text/html
Cache-Control: max-age=3600
Server: nginx
Set-Cookie: session=abc123
```

Headers whose names start with `X-` are custom headers. Developers can invent them, for example `X-Request-Id`. This challenge uses a custom header called `X-Audit-Trail`.

Because the server sends headers to every visitor, a visitor can read them. A normal page never shows them, so they are an easy place to leave information by mistake.

## Solution
There are two valid routes.

### Route 1: the Network tab in DevTools

1. **Open DevTools.** I pressed `F12`. Another way is to right-click the page and choose **Inspect**.

2. **Open the Network tab.** This tab lists every request the page makes, including the page itself, images, and scripts.

3. **Reload the page.** I pressed `Ctrl + R` with the Network tab open. Requests only appear in the list if they happen while the tab is open.

4. **Search for the flag.** I searched for `cyberspectre`, the start of every flag in this CTF. In Chrome and Edge, pressing `Ctrl + F` while the Network tab is open searches inside the headers and content of all requests. The filter box at the top of the tab only matches request names, so it does not search inside headers by default. In Firefox, the filter box can also match header text.

5. **Open the matching request.** I clicked the request that matched, which was `[request name]`, and opened the **Headers** section. Under **Response Headers**, I found the custom header:
   ```
   X-Audit-Trail: [paste the header value]
   ```

6. **Read the flag.** The flag sits inside the value of `X-Audit-Trail`:
   ```
   [add flag]
   ```

### Route 2: request `svg.svg` directly

The file `svg.svg` is served with the same `X-Audit-Trail` header, so the flag can be recovered without searching through the Network tab.

1. Open the file by adding its name after the domain name:
   ```
   https://ridgeback-motorsport.netlify.app/svg.svg
   ```
   The browser only draws the image and does not show its headers.

2. Read the headers with `curl`, a command-line tool that requests a URL. The option `-I` asks for the headers only:
   ```
   curl -I https://ridgeback-motorsport.netlify.app/svg.svg
   ```
   On Windows PowerShell, type `curl.exe` instead of `curl`, because PowerShell uses `curl` as a shortcut for a different command. If no headers appear, use `curl -i`, which prints the headers followed by the file.

3. The output includes the same line as Route 1:
   ```
   X-Audit-Trail: [paste the header value]
   ```

## Dead ends
- None.

## Vulnerability / technique
This is sensitive information exposed in an HTTP response header (CWE-200, exposure of sensitive information to an unauthorized actor). The header was sent to every visitor, so anyone who looked at the response could read it. The technique is inspecting the parts of a response that the browser does not display.

Real servers leak information the same way. A header such as `Server: Apache/2.4.49` tells an attacker the exact software version. That version has a known path traversal flaw, CVE-2021-41773, so the header shows the attacker which exploit to try.

## Fix / defense
- **Never put secrets, notes, or flags in response headers.** Headers go to every visitor.
- **Remove debug and audit headers before launch.** On Netlify, custom headers are set in a `_headers` file or in `netlify.toml`, so those files should be reviewed before a site goes live.
- **Remove headers that reveal software and versions**, such as `Server` and `X-Powered-By`, or set them to a generic value.
- **Review the responses, not only the pages.** A security review should check the headers of every file the site serves, including images such as `svg.svg`. A tool such as `curl -I` makes this quick.
- **SOC relevance.** Analysts often check the headers of a suspicious URL with `curl -I`. This shows the server type, redirects, and cache details without opening the page in a browser, so the page's JavaScript never runs.

## Lessons learned
- A response has a body and headers, and the browser only draws the body. Information can be hidden in either one.
- The Network tab shows every request and response, including headers. The Cookie Monster challenge used the same tab for the `Set-Cookie` header.
- Custom headers usually start with `X-`.
- Searching for the flag prefix, `cyberspectre`, is faster than opening requests one by one.
- Files other than the page, such as images, have their own headers and can leak information too.

## References
- MDN, HTTP headers: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers
- Chrome DevTools, Network panel reference: https://developer.chrome.com/docs/devtools/network/reference
- Netlify, custom headers: https://docs.netlify.com/manage/routing/headers/
- CWE-200, Exposure of Sensitive Information to an Unauthorized Actor: https://cwe.mitre.org/data/definitions/200.html
- NVD, CVE-2021-41773: https://nvd.nist.gov/vuln/detail/CVE-2021-41773