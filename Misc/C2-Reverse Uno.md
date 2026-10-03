# Reverse Uno

**CTF:** Cyberspectre, September 2026
**Category:** [Misc]
**Difficulty:** Warm-up
**Flag:** `cyberspectre{r34d1ng_b4ckw4rds}`

## Challenge description
![alt text](<C2-reverse uno.png>)
Something here seems to have been written backwards: `s}dr4wkc4b_gn1d34r{ertcepsrebyc`

Can you turn it around?

Given: `s}dr4wkc4b_gn1d34r{ertcepsrebyc`

## Tools used
- Terminal `rev` command (Linux, macOS, WSL)
- Python
- CyberChef (alternative, no install needed)

## Initial recon
Before doing anything, I looked at the clues and the string itself.

**Clues in the challenge text**
- The title is "Reverse Uno". An Uno reverse card flips the direction of play, so the title hints at reversing something.
- The description says the text was "written backwards" and asks me to "turn it around". That confirms the task: put the characters in the opposite order.

**Clues in the string**
- The string is `s}dr4wkc4b_gn1d34r{ertcepsrebyc`. It has a `}` near the start and a `{` in the middle. Flags normally look like `prefix{text}`, with `{` first and `}` last. Here they are in swapped positions, which is what a reversed flag looks like.
- The end of the string is `ertcepsrebyc`. Reading that from right to left gives `cyberspectre`, which is the name of this CTF and the flag prefix I saw in challenge 1. This told me the flag format is `cyberspectre{...}` and that reversing was the right idea.
- The string is 31 characters long, so I can check my answer has the same length.

## Solution
Reversing means reading the characters from the last one to the first one, so the last character becomes the first.

**Method 1: by hand (good for understanding)**

Number each character from the left, then write them again starting from number 31 and counting down to 1.

| Position | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Char | s | } | d | r | 4 | w | k | c | 4 | b | _ | g | n | 1 | d | 3 |

| Position | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Char | 4 | r | { | e | r | t | c | e | p | s | r | e | b | y | c |

Reading from position 31 down to position 1 gives:

```
cyberspectre{r43d1ng_b4ckw4rd}s
```

**Method 2: terminal**

The `rev` command reverses the characters on each line. The `echo` command prints the text, and the `|` symbol sends that text into `rev`.

```
echo 's}dr4wkc4b_gn1d34r{ertcepsrebyc' | rev
```

Output:

```
cyberspectre{r43d1ng_b4ckw4rd}s
```

`rev` is not built into Windows PowerShell or Command Prompt. On Windows, use WSL, Python, or CyberChef.

**Method 3: Python**

```python
text = "s}dr4wkc4b_gn1d34r{ertcepsrebyc"
print(text[::-1])
```

`[::-1]` means "take the whole string, but step backwards one character at a time". It prints the same result.

**Method 4: CyberChef (no install)**
1. Open https://gchq.github.io/CyberChef/
2. Search for **Reverse** in the operations list and double-click it.
3. Set **By** to **Character**.
4. Paste the string into the **Input** box. The **Output** box shows the reversed text.

**Reading the result**

The reversed text is `cyberspectre{r43d1ng_b4ckw4rd}s`. Read it out loud and two things look wrong:

1. The `s` sits after the closing `}`. A flag should end with `}`. The word inside the braces is `b4ckw4rd`, and "backwards" ends with an `s`, so the `s` belongs inside the braces.
2. `r43d1ng` should be `r34d1ng`. In leetspeak, 3 stands for `e` and 4 stands for `a`. The word is "reading", spelled r, e, a, d, i, n, g, so the `3` comes first and the `4` second. With `43` it would spell "raeding".

Fixing both gives the final flag:

```
cyberspectre{r34d1ng_b4ckw4rds}
```

The flag uses leetspeak, where numbers replace similar-looking letters:
- `r34d1ng` = reading (3 = e, 4 = a, 1 = i)
- `b4ckw4rds` = backwards (4 = a)

## Dead ends
- None. The title, the description, and the `ertcepsrebyc` ending all pointed to a simple reversal.

## Vulnerability / technique
Reversing a string is obfuscation, not encryption. There is no key and no secret, and anyone can undo it in seconds. It only stops a person from reading the text at a quick glance.

## Fix / defense
- Do not rely on reversed or scrambled text to hide sensitive data. Use real encryption (AES-GCM) for data that must stay secret.
- For detection, attackers use reversed strings to slip past tools that search for known words. In PowerShell, this code rebuilds the command `IEx`, an alias for `Invoke-Expression`, which runs text as code:
  ```
  'xEI'[-1..-3] -join ''
  ```
  A search for the word `IEx` would never match, because it only appears in the script backwards. A SOC analyst who sees `-join` together with a reversed index like `[-1..-N]` should reverse the string and check what it runs.

## Lessons learned
- Read the title and description first. They often state the technique.
- Look for the known flag prefix in the string, forwards or backwards. Here `ertcepsrebyc` was `cyberspectre` reversed.
- Reversed brackets (`}` before `{`) are a sign that text is written backwards.
- Read the result out loud and check it against the flag format. The stray `s` after `}` and the `43` in `r43d1ng` both showed the text needed a small fix.

## References
- CyberChef: https://gchq.github.io/CyberChef/
- Python string slicing: https://docs.python.org/3/tutorial/introduction.html#strings