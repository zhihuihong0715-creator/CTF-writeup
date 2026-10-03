# Behind the Lens

**CTF:** Cyberspectre, September 2026
**Category:** OSINT
**Difficulty:** Easy
**Flag format:** `cyberspectre{h1dden_1n_metadata}`

## What we're given
![alt text](<C20-behind the lens.png>)
![alt text](<C20-DontDigMore .jpg>)
A single image file: `C20-DontDigMore_.jpg`, a picture of yellow-and-black striped pyramids over water.

The challenge description says the image "contains information the photographer never intended to share," and the second hint points straight at metadata. So the flag isn't hidden in the pixels, it's hidden in the file itself.

## What EXIF is

EXIF stands for **Exchangeable Image File Format**. It's a standard for storing extra data inside image files, mostly JPEGs and TIFFs, separate from the actual picture. When you take a photo on a phone or camera, the device automatically writes a bunch of information into the file alongside the image data.

Typical EXIF fields include:

- Camera make and model
- Date and time the photo was taken
- GPS coordinates (if location services were on)
- Camera settings: aperture, shutter speed, ISO, focal length
- Software used to edit or export the image
- A free-text "User Comment" field, which some tools use for notes, watermarking, or in this case, hiding a flag

None of this shows up when you just look at the image. It's stored as text inside the file's header, invisible unless you specifically go looking for it. That's exactly the kind of thing this challenge is testing: whether you remember to check the metadata before assuming the answer is hidden visually in the picture itself.

## Why this matters outside CTFs

EXIF data is a real privacy and OPSEC issue. People post photos online without realizing GPS coordinates are embedded, which has been used to track down someone's home address or reveal a location they meant to keep private. Journalists and security researchers routinely check EXIF on leaked or suspicious images for exactly this reason. This challenge is a simplified version of that same technique.

## Tools you'll use

**ExifTool** (https://exiftool.org/), accessed here through the web version at https://exiftools.com/. It's a widely used utility for reading and writing metadata across nearly every image, video, and document format. You can also run it from the command line if you have it installed locally, but for a quick check, the web version works fine.

## Step 1: Upload the image

Go to https://exiftools.com/ and upload `C20-DontDigMore_.jpg`. The tool reads the file and lists out every metadata field it finds.

## Step 2: Scan the output

Most fields will be standard camera/software info, resolution, color space, that sort of thing. What you're looking for is anything unusual, a field that clearly doesn't belong, like a comment, description, or note that isn't normal camera output.

In this image, the flag is sitting in the **UserComment** field. This field exists specifically for free-text notes, which makes it a common place to plant a hidden flag in forensics challenges, since it's not something a camera fills in automatically.

## Step 3: Read the flag

The UserComment field contains:

```
cyberspectre{h1dden_1n_metadata}
```

No further decoding needed. It's stored as plain text.

## Solve path summary

1. Read the challenge hints: the information isn't visible in the image itself, check the metadata.
2. Upload the image to an EXIF viewer (https://exiftools.com/).
3. Look through the listed metadata fields for anything that doesn't belong.
4. Find the flag in the UserComment field: `cyberspectre{h1dden_1n_metadata}`.