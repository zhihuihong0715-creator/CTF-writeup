# Base64 Decode
 
**CTF:** Cyberspectre(MMU), September 2026
**Category:** MISC
**Difficulty:** Easy
**Flag:** `cyberspectre{33sy_p0ints_to_st4rt}`
 
## Challenge description
![alt text](<C1-warm up.png>)

Every CTF starts somewhere. Decode the message and get your first flag.
 
**Hint 1:** The encoded text only uses a small set of characters and ends with `==`.
 
**Hint 2:** Think about common text-to-data encoding rather than encryption.
 
Given: `Y3liZXJzcGVjdHJlezMzc3lfcDBpbnRzX3RvX3N0NHJ0fQ==`
 
## Tools used
- Terminal `base64` command (or CyberChef)

## Initial recon
The string used only letters, numbers, `+`, and `/`, and it ended with `==` padding. That pattern points to Base64. Its length is 48 characters, a multiple of 4, which also fits. Hint 2 confirmed the idea: the challenge wants an encoding, not encryption.
 
## Solution
1. Identified the encoding from the character set and the `==` padding.
2. Decoded it on the command line(linux):
```
   echo 'Y3liZXJzcGVjdHJlezMzc3lfcDBpbnRzX3RvX3N0NHJ0fQ==' | base64 -d
```
Output: `cyberspectre{33sy_p0ints_to_st4rt}`
3. Checked the result against the flag format `cyberspectre{...}`. The first four encoded characters, `Y3li`, decode to `cyb`, which matches the prefix.
4. The final output was the flag: `cyberspectre{33sy_p0ints_to_st4rt}`
 
**CyberChef** gives the same result: add the **From Base64** recipe and paste the string as input.

 
## Dead ends
- None. The `==` padding and the hints pointed to Base64 straight away.
## Vulnerability / technique
Base64 is an encoding, not encryption. It converts binary data to text so it can travel through systems that only handle text. Anyone can reverse it without a key. Sensitive data stored as Base64 is effectively stored in plain text.
 
The flag uses leetspeak (`33sy` = easy, `p0ints` = points, `st4rt` = start), a common style in CTF flags.
 
## Fix / defense
- Never use Base64 to protect passwords, tokens, or secrets. Use proper hashing for passwords (bcrypt, Argon2) and encryption (AES-GCM) for data that must stay secret.
- For detection, a SOC analyst should recognize Base64 in logs. Attackers often hide PowerShell commands in it, such as `powershell -enc JAB...`. Decoding those strings is a routine triage step.

## Lessons learned
- Recognize Base64 by its character set and `=` padding.
- Encoded data can be layered, so check whether the output needs another decode.
- Knowing the flag prefix helps confirm a decode is correct.
## References
- RFC 4648, the Base64 specification: https://datatracker.ietf.org/doc/html/rfc4648
- CyberChef: https://gchq.github.io/CyberChef/


