# Function-to-download-a-file-via-HTTP

Function to download a file via HTTP.  Allows very large file transfers as it writes to the disk instead of to RAM.  There are two versions included in the file.  One with a progress bar and one without.  The progress bar version is 2-2.5x faster than the previous version as it only updates the progress bar on a set refresh interval and doesn't waste cycles on displaying every single byte downloaded.  If the download link is really slow, the counter will adjust itself so the progress bar will still refesh at the correct time.

Compatible with Powershell v2.

This is a reposting from my Microsoft Technet Gallery.
