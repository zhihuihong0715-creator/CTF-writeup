# Robots Don't Lie

**CTF:** Cyberspectre, September 2026
**Category:** [Web]
**Difficulty:** Easy
**Flag:** `[cyberspectre{r0b0ts_ar3nt_s3cr3t}]`

## Challenge description
![alt text](<C5-robot dont lie.png>)
The site administrator left instructions for search engines.

Maybe they accidentally left something useful behind.

Link: https://robots-dont-lie.netlify.app/

**Hint 1:** Look for a standard file used to control crawler access.

## Tools used
- Web browser

## Initial recon
I read the description and the hint first.

- **"Instructions for search engines"** describes a file that tells search engines what to do on a website.
- **Hint 1** says the file is a standard one that controls crawler access. A crawler is a program that visits websites automatically. That file is `robots.txt`.

I then opened the link. The homepage is a page themed on the TV show Mr. Robot, with an "About" section, an operations log, and a manifesto. Nothing on it looked like a flag. The last lines of the Contact section say: "Maybe start with what the robots know." This points to the same file, because "robots" refers to crawlers.

## What is robots.txt?
Search engines such as Google use programs called **crawlers** (or bots) to visit websites and add their pages to search results. The website owner can leave instructions for these crawlers in a plain text file called `robots.txt`.

Key facts about the file:

- **It always has the same name and place.** It is called `robots.txt` (all lowercase) and it sits at the top level of the site, called the root. Because every site follows this rule, you can find it on almost any website without searching.
- **It is a standard.** It is called the Robots Exclusion Protocol and is documented in RFC 9309.
- **It is plain text.** A browser shows it as text on a blank page.

Here is an example of what the file looks like. This is a generic example, not the one from this challenge:

```
User-agent: *
Disallow: /private/
Disallow: /old-backups/
Allow: /public/
Sitemap: https://example.com/sitemap.xml
```

What each line means:

| Line | Meaning |
|---|---|
| `User-agent: *` | The rules below apply to all crawlers. The `*` means "everyone". A specific name, such as `Googlebot`, targets one crawler. |
| `Disallow: /private/` | Crawlers are asked not to visit this path. |
| `Allow: /public/` | Crawlers may visit this path. |
| `Sitemap: ...` | The address of a list of pages the owner wants indexed. |

## Why adding /robots.txt to the address works
A website address has parts:

```
https://robots-dont-lie.netlify.app/robots.txt
|_____| |__________________________| |________|
protocol        domain name            path
```

- `https://` is the protocol the browser uses.
- `robots-dont-lie.netlify.app` is the domain name of the site.
- `/robots.txt` is the path, which is the file to request from the site.

The file lives at the root of the site, which is directly after the domain name. To read it, I put `/robots.txt` after the domain name and press Enter. The browser then asks the server for that file and displays it. This works the same way on other sites, for example `https://example.com/robots.txt`.

The `Disallow` lines are the useful part for a challenge like this one. They list the paths the owner does not want crawlers to visit, which are often the paths the owner wants to keep hidden. Anyone can read the file, so it shows exactly where to look.

## Solution
1. **Open the homepage.** It is a Mr. Robot themed page with no flag, and a line telling me to check "what the robots know".

2. **Choose the file to check.** The hint and the homepage both point to `robots.txt`.

3. **Open the file.** I edited the address bar so it ended after the domain name, added `/robots.txt`, and pressed Enter:
   ```
   https://robots-dont-lie.netlify.app/robots.txt
   ```
   The same file can be read from a terminal with `curl.exe https://robots-dont-lie.netlify.app/robots.txt` (on Linux or macOS, use `curl`).

4. **Read the rules.** The file contained:
   ```
   [paste the contents of the robots.txt file here]
   ```

5. **Open the Disallow path.** The `Disallow` line listed `[the disallowed path]`. I added it after the domain name:
   ```
   https://robots-dont-lie.netlify.app/[the disallowed path]
   ```

6. **Read the flag.** The page contained the flag:
   ```
   [add flag]
   ```

## Dead ends
- None.

## Vulnerability / technique
This is information disclosure through `robots.txt` (CWE-200), combined with reliance on hiding as protection (CWE-656).

`robots.txt` is a polite request for crawlers. Nothing enforces it, so a person, or a crawler that ignores the rules, can open any path listed in it. The file is also public, so the `Disallow` lines give a list of the paths the owner wanted to keep hidden. Checking `robots.txt` is a standard early step in web application testing, and the OWASP Web Security Testing Guide includes it under the test "Review Webserver Metafiles for Information Leakage".

## Fix / defense
- **Do not list sensitive paths in robots.txt.** Every path in the file is visible to everyone.
- **Protect private pages with authentication.** A page that must stay private needs a login. Hiding the address is not enough.
- **Use the right tool to keep pages out of search results.** A `noindex` meta tag or an `X-Robots-Tag` header does this. `robots.txt` only asks crawlers not to visit, and Google can still list a blocked page if other sites link to it.
- **Watch for the recon pattern in logs (SOC relevance).** A request for `/robots.txt` followed by requests to the paths inside it, from the same IP address, is a common sign of someone mapping a site. A SOC analyst can find this pattern in web server logs.

## Lessons learned
- `robots.txt` is at `/robots.txt` on the root of nearly every website. It is one of the first files to check in a web challenge.
- `Disallow` lines show the paths the owner wants to hide.
- Similar standard files are worth checking too, such as `/sitemap.xml`, which lists the pages of a site.
- Read the hint and the page text. The homepage line about "what the robots know" said the same thing as the hint.

## References
- RFC 9309, Robots Exclusion Protocol: https://www.rfc-editor.org/rfc/rfc9309
- Google, introduction to robots.txt: https://developers.google.com/search/docs/crawling-indexing/robots/intro
- OWASP Web Security Testing Guide: https://owasp.org/www-project-web-security-testing-guide/
- CWE-656, Reliance on Security Through Obscurity: https://cwe.mitre.org/data/definitions/656.html