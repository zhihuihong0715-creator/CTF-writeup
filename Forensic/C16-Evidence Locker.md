# Evidence Locker

**Event:** CyberSpectre CTF 2026
**Category:** Forensics 
**Difficulty:** Medium-Hard
**Flag:** `cyberspectre{th3_m3ss4g3_w4s_th3_m4p}`

## Challenge
![alt text](<C16-evidence locker_1.png>)
![alt text](<C16-evidence locker_2.png>)
A company employee has gone missing, and a workstation belonging to the company's Access Administrator was recovered. It holds employee records, security images, browser history, system logs, notes and an email. One employee appears repeatedly across the evidence. The objective is to correlate the evidence, follow the trail, and access the secured archive. The flag is not stored in the initial evidence files.

**Hints given:**
1. Read the forensics intake note first. It names the employee tied to the workstation.
2. Search for that employee in the directory. Record username, department, access zone and badge number.
3. Look for the odd URL that does not fit the social media, video and developer pages.
4. Open the internal Building 7 page and log in with the employee's username and badge number. Then follow the clue to Room 12.

## Approach

Each file holds one piece of the trail, and no single file is enough. The plan was to identify the subject, pull his identifiers from the directory, decode the message in the email, confirm the location with the logs and browser history, and then use the identifiers to log in to the page that the evidence points to.

Tools used: WinRAR and Windows PowerShell.

## Evidence layout

```
csi-2026-0417_remnants\
    FORENSICS_INTAKE_NOTE.txt
    company_directory.csv
    browser_history.csv
    system_log.txt
    desktop_notes.txt
    final_email.eml
    evidence\corridor_photo.jpg, meeting_photo.jpg, office_photo.jpg
```

## Steps

### 0. Extract the archive

Extract `csi-2026-0417_remnants.rar` with WinRAR, then open PowerShell inside the extracted folder.

```powershell
cd "$HOME\Desktop\csi-2026-0417_remnants"
dir
```

**Why:** PowerShell commands work on the current folder, and `dir` confirms the files are where you expect.

### 1. Identify the subject

```powershell
Get-Content .\FORENSICS_INTAKE_NOTE.txt
```

**Why:** Hint 1 says to start here. The note names the subject: **Daniel Mercer, Access Administrator, Infrastructure**, unaccounted for since Tuesday. He held full administrative access to the directory, badge system and zone provisioning. That explains why he appears across the evidence.

### 2. Get his identifiers from the directory

```powershell
Select-String -Path .\company_directory.csv -Pattern "Mercer"
```

**Why:** `Select-String` searches a file for a pattern, like `grep`. It returns only his row:

```
EMP-4817,Daniel Mercer,dmercer,Infrastructure,B-07,4817
```

| Field | Value |
|---|---|
| Username | `dmercer` |
| Department | Infrastructure |
| Access zone | `B-07` |
| Badge number | `4817` |

### 3. Decode the email

```powershell
Get-Content .\final_email.eml
```

**Why:** The email was sent by Mercer the day before the disappearance, and it reads like filler. Its wording is odd: a paranoid opening line, then a list of short instructions. Taking the first letter of each of those lines reveals a hidden message.

```powershell
(Get-Content .\final_email.eml | Where-Object { $_.Trim() } | Select-Object -Skip 10 -First 15 | ForEach-Object { $_[0] }) -join ''
```

How the command works:
- `Where-Object { $_.Trim() }` drops blank lines.
- `Select-Object -Skip 10 -First 15` skips the 8 header lines plus "Hey Sarah," and the opening paragraph, then keeps the next 15 lines, which run from "My apologies..." to "7 sharp...".
- `ForEach-Object { $_[0] }` takes the first character of each line.
- `-join ''` joins them into one string.

Output:

```
MEETATBUILDING7
```

This reads **MEET AT BUILDING 7**.

| Line starts with | Letter |
|---|---|
| My apologies... | M |
| Everything is set... | E |
| Everyone must... | E |
| Tomorrow determines... | T |
| Always check... | A |
| Try to arrive... | T |
| Bring your badge... | B |
| Under no circumstance... | U |
| It matters... | I |
| Let's not repeat... | L |
| Don't tell the team... | D |
| I already spoke... | I |
| No exceptions... | N |
| Get there a little early... | G |
| 7 sharp... | 7 |

The first four lines of `desktop_notes.txt` (Remember, Every, Always, Don't) spell READ. This is a small nudge to read the email closely.

### 4. Confirm the location with the logs and browser history

```powershell
Select-String -Path .\system_log.txt -Pattern "dmercer|4817"
```

**Why:** The message needs confirming against independent evidence. The log shows `dmercer` authenticating in zone `B-07` at 08:54:14 and badge `4817` verified at 08:55:15, right before the meeting time in the email.

To find the odd URL, count how often each site appears in the browser history:

```powershell
Import-Csv .\browser_history.csv | ForEach-Object { ([uri]$_.url).Host } | Group-Object | Sort-Object Count | Select-Object Count, Name
```

**Why:** Normal browsing repeats. GitHub, YouTube, Instagram and LinkedIn appear 49 times each. Only two hosts appear twice: `intranet.example.local` (generic "Internal Resource" pages) and `cybersecure-industries.netlify.app`. The second one is the odd URL:

```powershell
Select-String -Path .\browser_history.csv -Pattern "netlify"
```

```
24,8:41:02,https://cybersecure-industries.netlify.app/,Employee Dashboard (B0-7)
31,8:52:11,https://cybersecure-industries.netlify.app/,Building 7 Archive
```

The page title says "Building 7 Archive", and the visit at 8:52:11 is two minutes before `dmercer` authenticated. This is the page the email pointed to.

### 5. Open the Building 7 page

Open `https://cybersecure-industries.netlify.app/` in a browser.

### 6. Log in

Use the identifiers from the directory:

| Field | Value |
|---|---|
| Username | `dmercer` |
| Badge ID | `4817` |

**Why:** Hint 4 says to log in with the employee's username and badge number. Both came from step 2, and the log in step 4 shows the same pair being used.

### 7. Follow the post-login clue to Room 12

After login, the page gives information pointing to **Room 12**.

`<ADD: text or screenshot of the page shown after login>`

### 8. Open the Room 12 link

Follow the Room 12 link from that page.

`<ADD: URL or screenshot of the Room 12 page>`

### 9. Log in again

The Room 12 page asks for credentials again. Use the same username and badge ID (`dmercer` / `4817`).

### 10. Recover the final archive and read the flag

The final page provides the secured archive. Its contents give the flag:

```
cyberspectre{th3_m3ss4g3_w4s_th3_m4p}
```

`<ADD: screenshot of the final page or archive contents>`

## Command summary

| Command | Purpose |
|---|---|
| `Get-Content <file>` | Read a text file |
| `Select-String -Path <file> -Pattern "<text>"` | Search a file for a name or keyword |
| `Where-Object { $_.Trim() }` | Drop blank lines |
| `Select-Object -Skip 10 -First 15` | Keep only the 15 lines that carry the hidden message |
| `ForEach-Object { $_[0] }` | Take the first letter of each line |
| `Import-Csv ... \| Group-Object` | Count how often each site appears in the history |

## Decoys

- The three photos in `evidence` hold only image signing metadata and no hidden text.
- The other log entries and the generic `intranet.example.local` pages are noise.
- The `READ` acrostic in the desktop notes only points back to the email.

## Lesson

No file in the package holds the answer alone. The intake note gave the name, the directory gave the login, the email gave the destination, and the logs and browser history confirmed it and revealed the URL. In an investigation, an odd detail in one file, such as a paranoid email with unusual line openings or a single site visited twice, is worth checking against every other file. SOC analysts do the same when they connect a suspicious login in an authentication log to a URL in proxy logs and a user's identity in a directory.