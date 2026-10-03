# Needle in a Haystack: Writeup

**CTF:** Cyberspectre(MMU), September 2026
**Category:** MISC
**Difficulty:** Easy
**Flag:** `cyberspectre{ctrl_f_1s_p0werful}`

## Challenge Descriptions
![alt text](<C13- needle in haystack.png>)
The challenge gives one very large file and says reading every line manually is not realistic. Hint 1 says to search for something specific.

## Approach

The flag is a short string hidden in a large amount of filler text. Reading the file line by line would take too long, so the fastest way is to search for a string that only the flag contains. Flags in this CTF use the format `cyberspectre{...}`, so the search term is the flag prefix.

## Steps

**1. Open the file**

Open the downloaded file (`<FILE NAME>`) in a text editor such as Notepad, Notepad++ or VS Code.

**2. Search with Ctrl+F**

Press `Ctrl+F` and type the flag prefix:

```
cyberspectre{
```

The editor jumps to the only match in the file. If the prefix finds nothing, try a shorter term such as `flag` or `{`.

**3. Copy the flag**

The match was on line `<LINE NUMBER>`:

```
<PASTE THE MATCHED LINE HERE>
```

**4. Submit**

Copy the full flag, from the prefix to the closing `}`, and submit it.

## Alternative: search from the command line

Command Prompt:

```
findstr /n /i "cyberspectre{" <FILE NAME>
```

PowerShell:

```powershell
Select-String -Path .\<FILE NAME> -Pattern "cyberspectre\{"
```

Linux or macOS:

```
grep -n "cyberspectre{" <FILE NAME>
```

`/n` and `-n` print the line number, so you can find the match again later. `/i` ignores upper and lower case.

## Notes

- If the file is too large for Notepad to open, use VS Code or the command line methods above.
- If the search returns many matches, narrow the term or search for the closing brace pattern `cyberspectre{.*}` with `grep -o` or `Select-String`.

## Lesson

When a file is too big to read, do not read it. Search for a string you know must be in the answer. Knowing the flag format is enough to find it in seconds. This is the same idea as `grep` searches through log files in SOC work.