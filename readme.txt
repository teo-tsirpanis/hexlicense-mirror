Hexlicense 1.0.4
================

- "THexLicense.Automatic" property has been removed, license sessions must be 
  manually started in your code by calling BeginSession(). The reason for this is that
  the encryption layer could not be ready when HexLicense started. Before the encryption
  layer can report ready, the cipher-key must be generated; This must be done early,
  and the best place is the OnCreate event in either the main-form or a datamodule.

  Example:

	procedure TForm1.FormCreate(Sender: TObject);
	const
	  LCipher = '{2C2844FB-19D4-41CF-85BC-219864D460D9}';
	begin
	  // Build cipher key first
	  HexKeyRC41.Build(LCipher, SizeOf(LCipher));

	  // Make sure cipher is ready
	  if not HexKeyRC41.Ready then
	  begin
		// Start a new licensed session
	    HexLicense.BeginSession();
	  end else
	  raise Exception.Create('Internal error, code: 667');
	  // Note: You dont want to use informative exceptions when it comes to your
	  // license management system
	end;
	
- THexLicense had its own encryption methods that was used on the license packet.
  This has been removed since the whole point of separate encryption, was to 
  compartmentalize the functionality.
  
- THexEncoder.EncodePtr has been rewritten, now returns the size of the encoded data
- THexEncoder.DecodePtr has been rewritten, now returns the size of the decoded data
  NOTE: Depending on the cipher, the data produced when encoding can be larger than the.
        original. Likewise, encoded data can be smaller than the decoded result.
		Hence the actual size is now returned by both.
- THexEncoder.GetResultSizeOf() has been added. Like explained above, encoded/decoded data
  can have different sizes. The GetResultSizeOf() takes the encoded data-length, and returns
  a safe buffer-size to house the decoded version.

- Fixed a problem where properties were omitted in the FMX unit. For some reason the VCL_TARGET
  switch was used to check if generics is supported (which obviously is 100% wrong). We now use
  the switch for "modern filenames" as an indicator for generics. But that is a temporary "fix".
  Generics should get it's own switch.

- Various minor adjustments and refactoring.
	
Hexlicense 1.0.3
================

This intermediate update adds two important factors:

1. The inclusion of HexBuffers which brings a wealth of low-level data manipulation features
2. Hotfix of potential data loss [*]

* Potential data loss
Textual data should have been stored as shortstring, sadly it was stored using a vanilla string.
This causes potential loss of characters should it breach 255 characters.

Important:

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