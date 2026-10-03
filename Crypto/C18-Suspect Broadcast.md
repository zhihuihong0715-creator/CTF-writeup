# Suspect Broadcast — Writeup

**Event:** CyberSpectre CTF 2026
**Category:** Crypto
**Difficulty:** Easy
**Flag format:** `cyberspectre{v1g3n3r3_1s_a_cl4ss1c_c1ph3r}`

## Challenge
![alt text](<Screenshot 2026-09-22 121133.png>)
The file has four separate "transmissions," each with its own protocol tag:

1. `ROT-v3` — `qeb{nrfzh_yoltk_clu}`
2. `HEX-v1` — `4e4f5f414354494f4e5f52455155495245447b4e4f57484552457d`
3. `VIG-v2` — `ewciikeiemii{x1e3o3v3_1j_s_rp4ul1t_g1rf3s}`
4. `B64-v1` — `Q0xFQVJFRF9GT1JfTk9XezIwMjZ9`

The challenge description says the real cipher is polyalphabetic. That's the whole trick: three of these four transmissions are decoys, and you're meant to notice which one is polyalphabetic before wasting time decoding all four by hand.

## What "polyalphabetic" means

A **monoalphabetic** cipher uses one fixed substitution for the whole message. Caesar cipher is monoalphabetic: shift every letter by the same amount, always. That's what ROT-v3 is (a Caesar shift by 3).

A **polyalphabetic** cipher uses a different shift for different letters, based on a repeating key. Same letter in the plaintext can turn into different letters in the ciphertext depending on where it sits. Vigenère is the classic example of this, and it's what VIG-v2 is tagged as.

So step one is just reading the tags: ROT, HEX, and B64 aren't polyalphabetic at all. VIG is your target.

## Tools you'll use

Everything here can be done in one place: **CyberChef** (https://gchq.github.io/CyberChef/).

It's a free browser tool where you build a "recipe" out of operations (drag them from the left panel into the Recipe area), paste your text into Input, and the Output updates live. No installs needed.

## Step 1: Confirm the decoys (optional but good practice)

Even though these aren't the answer, decoding them fast builds confidence that VIG-v2 is correct.

**ROT-v3** (`qeb{nrfzh_yoltk_clu}`)
In CyberChef, drag in "ROT13," then change the amount field from 13 to 3. Paste the ciphertext into Input.
Result: `the{quick_brown_fox}` — a reference to the pangram sentence, not a real flag.

**HEX-v1** (`4e4f5f...`)
Drag in "From Hex." Paste the ciphertext.
Result: `NO_ACTION_REQUIRED{NOWHERE}` — the message is literally telling you to move on.

**B64-v1** (`Q0xFQVJFRF9GT1JfTk9XezIwMjZ9`)
Drag in "From Base64." Paste the ciphertext.
Result: `CLEARED_FOR_NOW{2026}` — another dead end.

None of these three match the flag format used across this CTF (`cyberspectre{...}`), which confirms they're decoys.

## Step 2: Understand Vigenère and the formula

Vigenère works by assigning each letter a number: a=0, b=1, c=2, all the way to z=25.

To encrypt, you add the key letter's number to the plaintext letter's number, then wrap around if you go past 25 (that's the "mod 26" part):

```
cipher = (plain + key) mod 26
```

To decrypt, you reverse it:

```
plain = (cipher − key) mod 26
```

The key is a word, and it repeats over and over across the message. So if your key is `cat` and your message is 9 letters long, the key stream is `catcatcat`. Each letter of the message gets shifted by the matching letter of the key.

The problem: you don't know the key yet. That's where the hint comes in.

## Step 3: Recover the key using a crib

The challenge hint says: "Look at what all our flags have in common." Every flag in this CTF starts with `cyberspectre{`. That's called a **crib** — a piece of plaintext you already know, which lets you work backwards to find the key instead of guessing.

Ciphertext: `ewciikeiemii{...}`
Known plaintext: `cyberspectre{...}`

Since `plain = cipher − key`, we can rearrange that to solve for the key instead:

```
key = (cipher − plain) mod 26
```

Going letter by letter through the first 12 characters:

| Position | Plaintext | Ciphertext | Key letter |
|---|---|---|---|
| 1 | c (2) | e (4) | c (2) |
| 2 | y (24) | w (22) | y (24) |
| 3 | b (1) | c (2) | b (1) |
| 4 | e (4) | i (8) | e (4) |
| 5 | r (17) | i (8) | r (17) |
| 6 | s (18) | k (10) | s (18) |
| 7 | p (15) | e (4) | p (15) |
| 8 | e (4) | i (8) | e (4) |
| 9 | c (2) | e (4) | c (2) |
| 10 | t (19) | m (12) | t (19) |
| 11 | r (17) | i (8) | r (17) |
| 12 | e (4) | i (8) | e (4) |

The recovered key spells `cyberspectre`. That's the twist: the key is the same word as the flag prefix.

You don't have to do this math by hand every time. CyberChef has a "Vigenère Decode" recipe once you know the key, but for recovering an unknown key from a crib, doing it manually like this (or with a Vigenère solver like https://www.dcode.fr/vigenere-cipher, which shows the letter math) is the standard approach.

## Step 4: Decode the rest of the message

Now that you have the key (`cyberspectre`), decode the part inside the braces: `x1e3o3v3_1j_s_rp4ul1t_g1rf3s`

One important detail: Vigenère only shifts **letters**. Digits and underscores pass straight through unchanged, and they don't consume a letter from the key stream either. So when you hit a `1`, `3`, `4`, or `_`, skip it and keep the key position where it was.

In CyberChef:
1. Paste `x1e3o3v3_1j_s_rp4ul1t_g1rf3s` into Input.
2. Drag "Vigenère Decode" into the Recipe.
3. Type `cyberspectre` into the Key field.
4. Read the Output.

Result: `v1g3n3r3_1s_a_cl4ss1c_c1ph3r`

That's leetspeak (1=i, 3=e, 4=a). Read normally, it says: **vigenere is a classic cipher**.

## Step 5: Final flag

Combine the known prefix with the decoded content:

```
cyberspectre{v1g3n3r3_1s_a_cl4ss1c_c1ph3r}
```

The leetspeak digits stay exactly as they are in the flag. They were never shifted by Vigenère in the first place, so there's nothing to convert back.

## Solve path summary

1. Read the challenge description: the target cipher is polyalphabetic.
2. Check the four transmission tags. Only VIG-v2 is polyalphabetic (Vigenère). Decode the other three with CyberChef ("ROT13" set to 3, "From Hex," "From Base64") just to confirm they're decoys.
3. Use the shared flag prefix (`cyberspectre{`) as a crib against the VIG-v2 ciphertext to recover the key by hand: `key = (cipher − plain) mod 26`.
4. Feed the recovered key (`cyberspectre`) and the rest of the ciphertext into CyberChef's "Vigenère Decode" operation.
5. Assemble the final flag from the prefix and the decoded content.