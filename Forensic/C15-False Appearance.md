# False Appearance: Writeup

**Event:** CyberSpectre CTF 2026
**Category:** Forensics
**Difficulty:** Medium
**Flag:** `cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}`

## Challenge
![alt text](<C15-false appearence.png>)
> A file recovered from an old drive appears to be an ordinary photograph. However, the system refuses to open it, and the surrounding files provide conflicting clues about what happened during recovery.
> Determine what the file actually contains and recover the hidden message.

**Hints given:**
1. A filename is only a label. Check what the operating system thinks the file really is.
2. Examine the file signature.
3. If the file is not an image, try opening or renaming it according to the format it actually contains.

## Approach

A file extension is only part of the name. The real format is set by the first bytes of the file, called the file signature or magic bytes. The plan was to read the clue files, compare the extension of each image with its real signature, find the file that is not an image, and read it as text.

Tools used: Windows PowerShell 5.1. There is no `file` command on Windows, so the signature was read with `Get-Content -Encoding Byte`.

## Reasoning

**1. Read the challenge text for what it says about the file.**
"The system refuses to open it" means at least one file fails as an image. "Conflicting clues" means some files are decoys. All three hints say the same thing: a filename is only a label, and the file signature (the first bytes) shows the real type. That gives one question to answer: which file's name and real content disagree?

**2. Read the clue files.**
`case_notes.txt`, `README.txt` and `emails.txt` repeat the warning not to trust filenames. `README.old` adds that anything found may have been added by the recovery process. These files confirm the method but do not hold the answer. The meeting minutes, `index.db` and `thumbnail_cache.dat` are noise.

**3. List the files and compare sizes.**
`recovered_photo.png` is only 239 bytes. A real photo is much larger. It also sits at the top level, outside `camera_roll`, where the real camera exports are. That makes it the first suspect.

**4. Check the signature of every "image", not just the suspect.**

| File | Name says | First bytes | Real type |
|---|---|---|---|
| `IMG_1041.png` | PNG | `89 50 4E 47` | PNG (matches) |
| `IMG_1042.jpg` | JPEG | `89 50 4E 47` | PNG (name is wrong, file is fine) |
| `recovered_photo.png` | PNG | `4F 4C 44 20` = "OLD " | Plain text |

**5. Decide which mismatch matters.**
Two files have a false extension:
- `IMG_1042.jpg` is a working image with the wrong suffix. It opens normally, so it does not fit "the system refuses to open it". Its only text is a metadata comment, and it holds no flag.
- `recovered_photo.png` is not an image at all. That fits "refuses to open" and "hidden message".

The note inside `recovered_photo.png` says `asset: IMG_1042`, which makes `IMG_1042.jpg` look important. That is the decoy.

**6. Read it as text.**
Because the bytes are letters, the copy was opened as text. The last line is the flag, and the note inside the file says to rename it to the format it actually contains, which agrees with hint 3.

**7. Cross-check.**
`SHA256SUMS` lists only the two real images, and both hashes match. `recovered_photo.png` is not listed, so it was added by the recovery process. A search for `cyberspectre` across all files matches only `recovered_photo.png`, so there is no competing flag.

**The rule:** do not trust a name. Read the first bytes, find the file whose content and label disagree, and check that the disagreement explains the symptom in the challenge text. A wrong extension on a working file is a distraction. A file that fails as what its name claims is the target.

## Evidence layout

The extracted challenge folder looked like this:

```
False_appearance\
    case_notes.txt
    emails.txt
    README.txt
    recovered_photo.png
    archive\README.old
    camera_roll\IMG_1041.png, IMG_1042.jpg, SHA256SUMS
    docs\meeting_minutes.txt
    system\thumbnail_cache.dat
    system\.cache\index.db
```

The challenge folder is nested twice (`False_Appearance\False_appearance`), so the first `cd` is not enough.

## Steps

### 1. Go to the challenge folder

```powershell
cd $HOME\Desktop
cd "C:\Users\asus\Desktop\False_Appearance\False_appearance"
```

**Why:** PowerShell commands work on the current folder. `$HOME` expands to `C:\Users\asus`, so the first line reaches the Desktop without typing the username. The second line goes into the inner folder where the real files are. Running commands in the wrong folder gives "cannot find path" errors.

### 2. List the top folder

```powershell
dir
```

**Why:** This shows what is there before touching anything. Output showed four folders (`archive`, `camera_roll`, `docs`, `system`) and four files, including `recovered_photo.png` at 239 bytes. A 239-byte "photo" is far too small for a real image, which is the first warning sign.

### 3. List every subfolder

```powershell
dir -Recurse
```

**Why:** `-Recurse` also lists the contents of all subfolders, so nothing is missed. It showed `IMG_1041.png` (930 bytes) and `IMG_1042.jpg` (2122 bytes) in `camera_roll`, a `SHA256SUMS` file next to them, and small cache files in `system` and `system\.cache`. Real images are bigger than 239 bytes, so `recovered_photo.png` stood out.

### 4. Read the clue files (optional but useful)

```powershell
Get-Content .\case_notes.txt, .\README.txt, .\archive\README.old
```

**Why:** These files describe how the drive was recovered. The useful lines:
- `case_notes.txt`: compare what the suffix claims with what the file signature and content actually say.
- `README.txt`: do not assume that a familiar suffix means a familiar format.
- `README.old`: the folder was empty when the drive was imaged, so anything found may have been added by the recovery process.

The emails, meeting minutes, `index.db` and `thumbnail_cache.dat` are noise.

### 5. Read the file signature of the suspicious file

```powershell
Get-Content .\recovered_photo.png -Encoding Byte -TotalCount 16 | ForEach-Object { '{0:X2}' -f $_ }
```

**Why:** This prints the first 16 bytes as hex, which is the file signature. Breakdown:
- `Get-Content ... -Encoding Byte` reads the file as raw bytes instead of text.
- `-TotalCount 16` stops after 16 bytes.
- `ForEach-Object { '{0:X2}' -f $_ }` formats each byte as two hex digits.

`Format-Hex -Count 16` is the shorter option, but the `-Count` parameter exists only in PowerShell 7 and failed on PowerShell 5.1 with "A parameter cannot be found that matches parameter name 'Count'".

Output:

```
4F 4C 44 20 44 52 49 56 45 20 52 45 43 4F 56 45
```

Decoded as ASCII, this reads `OLD DRIVE RECOVE`.

| Hex | 4F | 4C | 44 | 20 | 44 | 52 | 49 | 56 | 45 | 20 | 52 | 45 | 43 | 4F | 56 | 45 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Char | O | L | D | space | D | R | I | V | E | space | R | E | C | O | V | E |

A real PNG starts with `89 50 4E 47 0D 0A 1A 0A`, and a real JPEG starts with `FF D8 FF`. This file starts with readable letters, so it is plain text and the `.png` extension is false.

### 6. Compare with the other "image" (optional)

```powershell
Get-Content .\camera_roll\IMG_1042.jpg -Encoding Byte -TotalCount 8 | ForEach-Object { '{0:X2}' -f $_ }
```

**Why:** This checks whether the file named `.jpg` really is a JPEG. Output:

```
89 50 4E 47 0D 0A 1A 0A
```

That is the PNG signature, so `IMG_1042.jpg` is a real PNG with the wrong extension. It is still a valid image and holds no flag (its only text is a metadata comment telling you to check the neighboring filenames). It is a decoy: a wrong extension on a working image is not the problem the challenge describes. The file that "the system refuses to open" is the one that is not an image at all, `recovered_photo.png`.

### 7. Copy the file and rename the copy to `.txt`

```powershell
Copy-Item .\recovered_photo.png .\recovered_photo.txt
```

**Why:** The hints say to treat the file according to what it really contains. Since the bytes are text, the copy gets a `.txt` extension. Working on a copy keeps the original evidence unchanged. This matters because editing evidence in place can destroy it, as happened while testing the Ghost File challenge.

### 8. Read the file

```powershell
Get-Content .\recovered_photo.txt
```

**Why:** This prints the text. Output:

```
OLD DRIVE RECOVERY NOTE
asset: IMG_1042
capture_time: 2014-06-18 03:14:15 UTC
format_hint: the extension is not a reliable witness
operator_note: rename this file to the format it actually contains
---
cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}
```

The note itself confirms the idea of the challenge, and the flag is the last line.

### 9. Extract only the flag line

```powershell
Select-String -Path .\recovered_photo.txt -Pattern "cyberspectre\{.*\}"
```

**Why:** `Select-String` searches for a pattern, like `grep`. The pattern `cyberspectre\{.*\}` matches the flag format from the opening text to the closing brace. The backslashes stop `{` and `}` from being read as special regex characters. Output:

```
recovered_photo.txt:7:cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}
```

The `7` is the line number of the match. This confirms the exact flag text to copy and submit.

### 10. Optional: confirm the file was added by the recovery process

```powershell
Get-Content .\camera_roll\SHA256SUMS
Get-FileHash .\camera_roll\IMG_1041.png, .\camera_roll\IMG_1042.jpg, .\recovered_photo.png -Algorithm SHA256
```

**Why:** `SHA256SUMS` lists hashes for `IMG_1041.png` and `IMG_1042.jpg` only. Both hashes match. `recovered_photo.png` is not in the list, which supports what `README.old` says: it was added by the recovery process and is not part of the original drive.

## Command summary

| Command | Purpose |
|---|---|
| `cd $HOME\Desktop` | Move to the Desktop without typing the username |
| `cd "...\False_appearance"` | Move into the inner challenge folder |
| `dir` | List the top folder |
| `dir -Recurse` | List all subfolders and files |
| `Get-Content <files>` | Read the clue text files |
| `Get-Content <file> -Encoding Byte -TotalCount 16 \| ForEach-Object { '{0:X2}' -f $_ }` | Read the file signature as hex |
| `Copy-Item <file> <file>.txt` | Copy the file under the correct extension |
| `Get-Content recovered_photo.txt` | Read the text and find the flag |
| `Select-String -Path ... -Pattern "cyberspectre\{.*\}"` | Print only the flag line |
| `Get-FileHash` | Verify which files match the original hash list |

## Result

`recovered_photo.png` was plain text with a `.png` extension. Its last line holds the flag:

```
cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}
```

## Notes

- **The flag matches the Ghost File challenge.** Both challenges accept `cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}`, so the flag was reused by the authors. The text in this file is what was found, and the team confirmed it.
- **Wrong extension does not mean hidden data.** `IMG_1042.jpg` has a wrong extension but is a normal image. The target was the file that would not open as an image.
- **Extensions can be changed by anyone.** Renaming `.png` to `.txt` did not modify the bytes. It only changed how Windows chooses a program to open it.

## Lesson

A filename is a label, and the first bytes of a file decide its real type. When a file will not open as what its name says, read its signature first (`89 50 4E 47` for PNG, `FF D8 FF` for JPEG, readable letters for text). SOC analysts use the same check on attachments and dropped files, because malware often hides behind a trusted extension such as `.jpg` or `.pdf`. On Linux, the `file` command does this check in one step.