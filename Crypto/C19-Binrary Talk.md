# Binary Talk — Writeup

**Event:** CyberSpectre CTF 2026
**Category:** Crypto / Encoding
**Difficulty:** Easy
**Flag format:** `cyberspectre{b1nary1s_fun}`

## Challenge
![alt text](<C19-binrary talk.png>)

A string of binary digits, grouped in 8-bit chunks:

```
01100011 01111001 01100010 01100101 01110010 01110011 01100101 01100011 01110100 01110010 01100101 01111011 01100010 00110001 01101110 01100001 01110010 01111001 00110001 01110011 01011111 01100110 01110101 01101110 01111101
```

The challenge description tells you straight up it's binary. No decoy, no misdirection here, just a straightforward encoding to reverse.

## What binary encoding is

Binary is base-2, meaning it only uses two digits: 0 and 1. Every character you can type has a corresponding number in the ASCII table, and that number can be written in binary using 8 digits (a "byte"). So a long text message becomes a long string of 8-bit chunks, one chunk per character.

To decode it, you reverse the process: split the string into groups of 8, convert each group from binary to decimal, then look up which character that decimal number represents in ASCII.

## Tools you'll use

**CyberChef** (https://gchq.github.io/CyberChef/) again. It has a "From Binary" operation that does the entire conversion for you in one step.

## Step 1: Convert binary to decimal (the manual version)

Binary-to-decimal works by giving each position a power of 2, starting from the rightmost digit at 2⁰. You add up the value of every position where there's a 1.

Take the first byte as an example: `01100011`

| Position (left to right) | 128 | 64 | 32 | 16 | 8 | 4 | 2 | 1 |
|---|---|---|---|---|---|---|---|---|
| Bit | 0 | 1 | 1 | 0 | 0 | 0 | 1 | 1 |

Add up the columns where the bit is 1: 64 + 32 + 2 + 1 = 99.

In ASCII, decimal 99 is the letter **c**.

Repeating this for the next few bytes:

| Binary | Decimal | Character |
|---|---|---|
| 01100011 | 99 | c |
| 01111001 | 121 | y |
| 01100010 | 98 | b |
| 01100101 | 101 | e |
| 01110010 | 114 | r |

You can already see it spelling out "cyber."

## Step 2: Decode the whole thing with CyberChef

Doing this by hand for 25 bytes is slow and easy to mess up. In CyberChef:

1. Paste the full binary string into Input.
2. Drag "From Binary" into the Recipe.
3. Read the Output.

Result:

```
cyberspectre{b1nary1s_fun}
```

## Step 3: Final flag

```
cyberspectre{b1nary1s_fun}
```

Same as the last challenge, the digits inside the braces are leetspeak (1=i), so it reads as "binary is fun." No further decoding needed on that part, it comes out correct straight from the binary conversion.

## Solve path summary

1. Recognize the input as binary (groups of 8 bits, only 0s and 1s).
2. Understand that each 8-bit group maps to one ASCII character.
3. Use CyberChef's "From Binary" operation to convert the whole string in one pass.
4. Read off the flag: `cyberspectre{b1nary1s_fun}`.