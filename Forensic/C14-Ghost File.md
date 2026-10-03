# Ghost File: Writeup
**CTF:** Cyberspectre(MMU), September 2026
**Category:** MISC
**Difficulty:** Easy
**Flag:** `cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}`

## Challenge
![alt text](<C14-ghost file_1.png>)
![alt text](<C14-ghost file_2.png>)

The challenge gives a `.rar` archive that must be extracted with WinRAR. After extraction, the folder looks empty.

**Hints given:**
1. The archive may not be as empty as it looks. Check everything, not just the visible files.
2. It is Windows. Some files hold data that does not appear in the normal file contents.
3. If you find `recovery.txt`, look into the file's alternate streams.

## Approach

The hints pointed to Windows and NTFS. On NTFS, a file can carry **ALTERNATIVE DATA SREAM (ADS)**, which normal programs and Explorer do not show. The plan was to rule out hidden attributes first, then search for streams.

## Steps

### 1. Extract with WinRAR onto an NTFS drive

Extract the `.rar` to a folder on C:. WinRAR restores NTFS streams on extraction. Other extractors, and non-NTFS drives such as FAT32 or exFAT, drop them.

### 2. Open Command Prompt and go to the folder

```
cd desktop
cd ghost_files
```

`dir /a` showed 0 files and one subfolder, also named `ghost_files`. The real content sits one level down.

```
cd ghost_files
```

### 3. Check hidden attributes

```
dir /a
attrib /s /d
```

`dir /a` listed 4 files and 2 folders (`archive`, `logs`). `attrib /s /d` showed only the `A` (archive) attribute on every file, so nothing was hidden by attributes. It also revealed two files named `recovery.txt`: one in the current folder and one in `logs`.

### 4. List alternate data streams

```
dir /s /r
```

`/s` searches all subfolders and `/r` lists streams. Only one file had an extra line under it:

```
Directory of ...\ghost_files\ghost_files\logs

               247 recovery.txt
                38 recovery.txt:secret.txt:$DATA
```

The indented line has no date, so it is not a separate file. It is a stream attached to the file above it, split into host file (`recovery.txt`), stream name (`secret.txt`) and type (`$DATA`). The 38 is its size in bytes. The other `recovery.txt` had no stream, so it was a decoy.

To filter the output down to folders and streams only:

```
dir /r /s | findstr /c:"Directory of" /c:":$DATA"
```

### 5. Read the stream

```
cd logs
more < recovery.txt:secret.txt
```

Output:

```
cyberspectre{d0t_f1l3s_h1d3_s3cr3ts}
```

## Commands used(command prompt)

| Command | Purpose |
|---|---|
| `dir /a` | List files, including hidden and system ones |
| `attrib /s /d` | Show attributes for all files and folders in all subfolders |
| `dir /s /r` | List all files and their alternate data streams |
| `cd logs` | Move into the folder that holds the stream |
| `more < recovery.txt:secret.txt` | Print the stream content |

PowerShell equivalent:

```powershell
Get-ChildItem -Recurse -File | Get-Item -Stream * | Where-Object Stream -ne ':$DATA'
Get-Content .\logs\recovery.txt -Stream secret.txt
```

## Notes

- **Read streams with `more <`, not Notepad.** Opening `recovery.txt:secret.txt` in Notepad and saving overwrote the stream during testing. It shrank from 38 to 11 bytes and the flag was lost from that copy. Choosing "Yes" to create a new file in the wrong folder also created a new empty stream. If this happens, delete the folder and extract the `.rar` again.
- **Typos matter.** `secret/txt` fails because `/` is read as a command switch. The name is `secret.txt`.
- **Two files with the same name** in different folders is a reason to check both.

## Lesson

A Windows file that looks empty or too small can hold data in an alternate stream. Check attributes with `dir /a`, then search for streams with `dir /s /r`. MITRE ATT&CK lists this technique as T1564.004 (Hide Artifacts: NTFS File Attributes).