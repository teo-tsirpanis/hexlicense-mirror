Hexlicense 1.0.3
================

This intermediate update adds two important factors:

1. The inclusion of HexBuffers which brings a wealth of low-level data manipulation features
2. Hotfix of potential data loss [*]

* Potential data loss
Textual data should have been stored as shortstring, sadly it was stored using a vanilla string.
This causes potential loss of characters should it breach 255 characters.

Important:
==========
This update is *NOT* binary compatible with previous generated license data.
To use this update, make sure customers activate using the new code.

We realize this is an inconvenience, and in Ironwood a secondary loader has been added that
will recognize the old format and attempt to handle it. This is optional.

Having a "backup-loader" does open up for potential weakness, we strongly suggest that you
use this new edition as much as possible. There will be no more changes to the original
HexLicense fileformat.

Ironwood has different components and it's own IO mechanisms.
Once out, Hexlicense classic (which is the current product line) is regarded as legacy.
It will be maintained ofcourse, and updated, but focus will then shift to Ironwood and server-side
solutions.

Thank you

Jon Lennart Aasenden