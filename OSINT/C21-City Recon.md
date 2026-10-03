# City Recon — Writeup

**CTF:** Cyberspectre, September 2026
**Category:** OSINT
**Difficulty:** Easy
**Flag format:** `cyberspectre{cliff_street}`

## What we're given
![alt text](<C21-city recon 1.png>)

![alt text](<C21-city_recon 2.jpg>)
A single photo: `C21-city_recon_2.jpg`, showing an industrial street with warehouses, parked vehicles, power lines, and two visible business signs: **"BAKER SUPPLY LTD."** and **"Auto Parts Plus."**

The challenge asks you to identify the exact street the photo was taken on. This is an **OSINT** (Open Source Intelligence) challenge, meaning the answer isn't hidden in the file itself. It's something you have to research using public information, in this case, a reverse-search based on what's visible in the image.

## The approach: use what's visible as search terms

When you have no metadata to fall back on (or when metadata has been stripped, which is common for these challenges), the next move is treating the image like a detective would: what's written on the signs, what businesses are named, what's distinctive enough to search for.

Here, "BAKER SUPPLY LTD." is the strongest lead. It's a specific business name, not a generic chain, which means it's far more likely to show up as a unique, searchable result rather than getting lost among thousands of similar stores.

## Step 1: Pull out identifiable text

Looking at the image, two signs stand out clearly:

- **BAKER SUPPLY LTD.**
- **Auto Parts Plus** (a known auto parts chain, less useful on its own since it has many locations, but useful for confirming a match once you have a candidate location)

## Step 2: Search the business name

Searching "Baker Supply Ltd" on Google turns up a specific company, and from there you can find its listed address. Since it's a specific named business rather than a chain, it should map to one real-world location.

## Step 3: Confirm with Google Maps

Once you have the address, drop it into Google Maps and switch to Street View. Compare what you see there against the uploaded photo: the building layout, the warehouse colors, the power line pattern, the angle of the street. If they match, you've confirmed the exact location, not just the right city.

This matching step matters. A business name search can return an address, but Street View confirmation is what proves you've got the right spot and not a similarly-named business elsewhere.

## Step 4: Read the street name

Once confirmed in Street View, the street the photo was taken on is **Cliff Street**.

## Step 5: Format the flag

The challenge tells you exactly how to format it: lowercase, underscores instead of spaces, matching the example `hill_street` for a street named "Hill Street."

```
cyberspectre{cliff_street}
```

## Solve path summary

1. Note that there's no metadata angle here, the puzzle is entirely visual.
2. Read the visible signage in the photo: "BAKER SUPPLY LTD." is the strongest, most specific lead.
3. Search that business name to find its real-world address.
4. Use Google Maps Street View to visually confirm the match against the photo.
5. Read off the street name from Street View: Cliff Street.
6. Format it to match the challenge's required style: `cyberspectre{cliff_street}`.