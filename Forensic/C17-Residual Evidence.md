# Residual Evidence: Writeup

**Event:** CyberSpectre CTF 2026
**Category:** Forensics / Cryptography
**Difficulty:** Hard+
**Flag:** `cyberspectre{D4T4B4S3_L3AK_4CC0UNT_0WN3D}`

## Challenge
![alt text](<C17-residual evidence_1.png>)
![alt text](<C17-residual evidence_2.png>)
A service account, `svc_backup`, was compromised. A snapshot of the application database (`app.db`) was recovered before the system went offline. Something was left behind in the data. The task is to examine the database and follow whatever evidence the attacker left, and the final flag is in the format `cyberspectre{...}`.

**Requirements stated:** a SQLite browser such as DB Browser for SQLite, and WinRAR to extract the archive.

**Hints given:**
1. The database holds more than ordinary application data. Look at unusual or encoded-looking values.
2. If a hash doesn't crack normally, don't assume the hash is the problem. Look for something used alongside it.
3. Look for a value that could be a salt, and use the correct hash format and attack mode.
4. The recovered plaintext isn't the final answer. Decode it layer by layer, and watch for another form of encoded communication.

## Approach

Nothing about the destination was known in advance. The method was to open every file the archive contained, read every value in the database rather than skimming it, and follow each output into the next step only after confirming it, instead of assuming what the next layer would be.

Tools used: WinRAR, a SQLite reader, Python (for base64, XOR, hash cracking, and Morse timing analysis), and a text editor.

## Steps

### 1. Extract the archive

Extract `Residual_Evidence.rar` with WinRAR.

**Why:** the challenge requires WinRAR specifically, the same requirement seen in Ghost File, so a different extractor may drop something or fail on the RAR5 format.

**What was inside:**

```
Residual_Evidence\
    app.db
    audio_drop.rar
    README_players.txt
```

`README_players.txt` restates the brief: `svc_backup` was compromised, and a copy of the database was pulled before takedown.

### 2. Open `app.db` and list every table

```sql
SELECT name FROM sqlite_master WHERE type='table';
```

**Why:** before reading rows, it's necessary to know how many tables exist. Reading only the obvious one risks missing a table that holds the actual clue. This returned two tables: `users` and `notes`.

### 3. Dump every row of every table

```sql
SELECT * FROM users;
SELECT * FROM notes;
```

**Why:** hint 1 says to look for unusual or encoded-looking values, which means every field needs to be read, not just the ones that look like normal app data.

`users` returned two rows:

| id | username | password_hash | salt |
|---|---|---|---|
| 1 | admin | `$2b$12$k9J1z8v7hQmXbYyN0pRZOuVvz1H9y1qkq5m4a8rXK2s3fN5tW0e9C` | (empty) |
| 2 | svc_backup | `3f20fd300b3af1d625a52af4f658418ff5630b0c7ef3574e98d755726f2885ad` | (empty) |

The `admin` row is a normal bcrypt hash (`$2b$12$...`) and is not the target, since the compromised account is `svc_backup`. Its hash is 64 hex characters, which is the length of a SHA-256 digest, and its `salt` column is empty even though the challenge says the account needs one.

`notes` returned one row from `svc_backup`:

```
reminder to self: rotate the vault salt someday. hardcoded value is still
Q1lCM1ItUzNDLTc3 lol. blob below is XOR'd with the account password,
repeating key.
FQ4CEUICHgkCHE8BDA0DDw1PGxwHQR4JFRtBVBEECUwHGxsVAQkJCFxPDgEGCAMzAh0ABEwbBRw=
```

**Why this matters:** this single note answers hint 1 (the unusual value), hint 2 (something used alongside the hash), and hint 3 (a value that could act as a salt) all at once. It says outright that the salt column being empty is because it's hardcoded elsewhere, gives that value as base64, and separately gives a base64 blob that is XOR'd with the account password.

### 4. Decode the salt

The note gives the salt as base64: `Q1lCM1ItUzNDLTc3`.

```python
import base64
base64.b64decode('Q1lCM1ItUzNDLTc3')
```

**Why base64:** the string is exactly the right length and character set for base64 (letters, digits, no obviously random distribution of symbols), which made it the first thing to try before assuming it was some other encoding.

**Output:** `CYB3R-S3C-77`

### 5. Build the hash:salt file and crack it

```
3f20fd300b3af1d625a52af4f658418ff5630b0c7ef3574e98d755726f2885ad:CYB3R-S3C-77
```

Hashcat mode 1410 is `sha256($pass.$salt)`, meaning the password is concatenated in front of the salt before hashing:

```
hashcat -m 1410 -a 0 svc.txt rockyou.txt
```

**Why mode 1410 and not another mode:** a 64-character hex string is a SHA-256 digest. Hint 3 says to use "the correct hash format and attack mode", which rules out guessing; the salt found in step 4 needs to be tried on both sides of the password (`salt.pass` and `pass.salt`) since hashcat has a separate mode for each order.

Cracking this against rockyou.txt (a wordlist of real leaked passwords, the standard first wordlist for this kind of challenge) found a match:

**Cracked password:** `football`

Verification: `sha256("football" + "CYB3R-S3C-77")` produces exactly `3f20fd300b3af1d625a52af4f658418ff5630b0c7ef3574e98d755726f2885ad`, confirming the crack against the hash straight from the database.

### 6. Decode the base64 blob with the cracked password as an XOR key

The note said the blob is XOR'd with the account password, using a repeating key. This is a standard repeating-key XOR: decode the base64 to raw bytes, then XOR each byte with the password bytes, cycling the password when it runs out.

```python
import base64
blob = "FQ4CEUICHgkCHE8BDA0DDw1PGxwHQR4JFRtBVBEECUwHGxsVAQkJCFxPDgEGCAMzAh0ABEwbBRw="
raw = base64.b64decode(blob)
key = b"football"
out = bytes([b ^ key[i % len(key)] for i, b in enumerate(raw)])
print(out.decode())
```

**Output:** `same creds unlock the rest. see attached: audio_drop.zip`

**Why this matters:** the plaintext is not the flag piece. This is where hint 4 becomes relevant: the plaintext must be treated as another layer, not the answer. It also confirms the recovered password (`football`) is meant to be reused, and it names a file to look for next.

### 7. Locate and open the next archive

The decoded note names `audio_drop.zip`, but the file actually delivered in the archive is `audio_drop.rar`. This mismatch is expected: file names inside a decoded message are not guaranteed to match reality, so the real file needs to be located by its content, not assumed from the name.

The RAR is password protected. Using the same credential recovered in step 5:

**Password:** `football`

This opens the archive and reveals two files:

```
audio_drop\
    hint.txt
    morse_signal.wav
```

**Why the same password worked:** the note in step 6 explicitly said "same creds unlock the rest," which is confirmed by this step succeeding.

### 8. Read `hint.txt`

```
audio_drop.wav uses standard International Morse Code.

One thing to note: this doesn't spell the whole flag format, just the
part that goes inside cyberspectre{...}. Word gaps (the longer silences)
represent underscores. Instead of a space between words it should be an
underscore.
```

**Why this file was read before touching the audio:** the audio alone doesn't say how to interpret silences. Standard Morse timing has three gap lengths (intra-character, inter-character, inter-word), and this file overrides the normal meaning of the longest gap, so decoding without reading it first would produce the wrong punctuation even with correct letters.

### 9. Measure the audio instead of trusting an online decoder

`morse_signal.wav` is a mono 44100 Hz, 16-bit PCM file, about 25.5 seconds long.

Rather than upload it to a third-party web tool and copy whatever it displayed, the tone pattern was measured directly, because an adaptive online decoder can mis-time a file with tight, low-noise timing, and its output can't be checked without redoing the analysis anyway.

**Method:**
1. Compute the amplitude envelope of the waveform using a short moving average, which smooths the raw waveform into a signal that clearly shows "tone on" versus "tone off."
2. Threshold the envelope at 25% of its peak to classify each sample as ON or OFF.
3. Group consecutive samples of the same state into runs, and measure each run's duration in milliseconds.

This produced runs with two clearly separated ON durations (~82ms and ~242ms) and three clearly separated OFF durations (~77ms, ~237ms, and longer). This immediately fit standard Morse timing:
- Short ON (~82ms) = dot, one unit.
- Long ON (~242ms) = dash, three units.
- Short OFF (~77ms) = gap inside a letter, ignored.
- Medium OFF (~237ms) = gap between letters, flush the current letter.
- Long OFF (beyond that) = gap between words, flush the current letter and insert the hint's underscore.

**Why measure rather than assume standard 1:3 timing applies automatically:** the actual dot length (82ms) sets the "unit," and every other duration in the file is a multiple of that same unit. Confirming this from the data, instead of assuming a textbook 50ms dot, is what makes the character boundaries correct.

### 10. Decode the timed runs into letters

Each run was converted to a dot or dash while it was ON, and each gap decided whether to continue the current letter, close it, or close it and insert an underscore, using the standard International Morse Code table.

**Decoded output:** `D4T4B4S3_L3AK_4CC0UNT_0WN3D`

This reads as leetspeak for **DATABASE LEAK ACCOUNT OWNED**, with the underscores in place of spaces as `hint.txt` specified, and with `4` substituted for `A`, `3` for `E`, and `0` for `O`.

**Why leetspeak and not plain English:** Morse code has no way to represent the difference between the letter and its leetspeak substitute; `4`, `3`, and `0` are Morse digits, not stand-ins for letters. The decoded output is what the digits and letters spell literally, and it happens to read as leetspeak by design, so the digits stay as digits in the final answer rather than being converted back to the letters they visually resemble.

### 11. Assemble the flag

Wrapping the decoded message in the challenge's flag format:

```
cyberspectre{D4T4B4S3_L3AK_4CC0UNT_0WN3D}
```

## Full chain summary

| Step | Input | Action | Output |
|---|---|---|---|
| 1 | `Residual_Evidence.rar` | Extract with WinRAR | `app.db`, `audio_drop.rar`, `README_players.txt` |
| 2–3 | `app.db` | List and dump every table | Hash, empty salt column, a note with an encoded salt and an XOR blob |
| 4 | `Q1lCM1ItUzNDLTc3` | Base64 decode | Salt: `CYB3R-S3C-77` |
| 5 | Hash + salt | Hashcat mode 1410 against rockyou.txt | Password: `football` |
| 6 | XOR blob + password | Repeating-key XOR decode | Pointer text naming the next archive |
| 7 | `audio_drop.rar` | Open with password `football` | `hint.txt`, `morse_signal.wav` |
| 8 | `hint.txt` | Read decoding rules | Word gaps = underscores |
| 9–10 | `morse_signal.wav` | Measure tone/gap timing, decode Morse | `D4T4B4S3_L3AK_4CC0UNT_0WN3D` |
| 11 | Decoded message | Wrap in flag format | `cyberspectre{D4T4B4S3_L3AK_4CC0UNT_0WN3D}` |

## Notes

- **`audio_drop.zip` versus `audio_drop.rar`:** the decoded note names a `.zip`, but the real file is a `.rar`. A decoded message describing a file is not proof of that file's actual name or format; the archive itself has to be checked.
- **Leetspeak matters for the flag.** The full-English phrasing "DATABASE LEAK ACCOUNT OWNED" is what the message means, but it is not what was decoded. The decoded digits (`4`, `3`, `0`) are part of the literal output and belong in the submitted flag as digits.
- **The salt column being empty in the database is not a bug.** It's the clue: an empty salt with a SHA-256-length hash means the salt lives somewhere else, which is exactly what the note explains.

## Lesson

Layered challenges require verifying each layer's output before assuming what the next layer is. The database's empty salt column, the mismatched archive name inside the decoded note, and the non-standard Morse timing with a custom rule for word gaps are all places where following an assumption instead of the actual evidence would have produced a wrong flag. Reading every field in every table, decoding every encoded value fully before moving on, and measuring the audio directly rather than trusting a black-box tool's output are what kept the chain correct end to end.