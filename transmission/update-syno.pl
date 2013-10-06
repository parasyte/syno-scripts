#!/usr/bin/perl

#
# Synology Media Indexer
#
# The Synology's synoindexd service will only index files if those have been copied to the media
# directory via FTP, SMB, AFP. If you move or copy media files via Telnet/SSH, the indexer is not
# aware of those, and you would have to manually reindex (which is time-consuming).
#
# This script will scan the video directory for modified files over the last two days and will then
# query the synoindex-service if the file was already indexed. If the file does not exist in the index
# database, the script will manually add it for immediate indexing.
#
# The logging component is handy, if you want to monitor when files are indexed and possibly tune your
# cronjob settings. I run the script in a cronjob every 10 minutes, which will then result in little
# overhead.
#
# I have included my most common media types in the script, but if I missed something, you are welcome
# to extend the script (and let me know what types I have missed).
#
# Usage: perl update-syno.sh /volume1/video
#
# Or add to crontab:
# */10 * * * * root perl /volume1/Extensions/scripts/update-syno.sh /volume1/video
#
# DISCLAIMER: 
#
# (C) 2010 by Gerd W. Naschenweng (Gerd@Naschenweng.info / http://www.naschenweng.info)

### Logging: Adjust the path below to the base-directory where you place the script (if you don't need logging, comment out)
use lib qw(/var/packages/transmission/scripts/syno-media-indexer);
use Logging::Log;

@include_files = ("ASF","AVI","DIVX","IMG","ISO","M1V","M2P","M2T","M2TS","M2V",
	"M4V","MKV","MOV","MP4","MPEG4","MPE","MPG","MPG4","MTS","QT","RM","TP","TRP","TS","VOB","WMV","XVID"
);

# message of synoindex indicating that file is not indexed
# for English this is: "Failed to get MediaInfo."
# You can get the message in your locale with the following command (execute as is): synoindex -g "myfile.test" -t video
my $SYNO_ERROR_MSG = "Failed to get MediaInfo.";


## Initialise logging (comment out if you don't need it - but then also comment out the relevant sections in the code below
my $log = Logging::Log->new();
#my $log = Logging::Log->new(Handle => \*F);
#my $log = Logging::Log->new(File => "/var/log/media-update.log", Mode => 'append');

# pass in number the directory to scan, this will be a recursive scan
my $scan_dir = shift;

if (!$scan_dir) {
	$log->entry("No scanning directory passed, using /volume1/video");
	$scan_dir="/volume1/video";
}

### Search for files which have changed during the last two days (adjust if necessary to shorter/longer intervals)
my @files = `find $scan_dir -type f -mtime -2`;
my $files_indexed = 0;

foreach (@files) {
	my $file = $_;
	chomp($file);
	my $ext = ($file =~ m/([^.]+)$/)[0];

	### Check if the file-name extension is a valid media file
	if (grep {lc $_ eq lc $ext} @include_files) {
		my $result = `synoindex -g \"$file\" -t video`;
		chomp($result);
  
		if ($result =~ m/^$SYNO_ERROR_MSG/i) {
			$log->entry("Adding file to index: $file");
			my @synorc = `synoindex -a \"$file\"`;
			++$files_indexed;
		}
	}
}

if ($files_indexed) {
	$log->entry("Synology Media Indexer added $files_indexed new media file(s)");
} else {
	$log->entry("Synology Media Indexer did not find any new media");
}

# Close the log-file - remove/comment out if you disable logging
$log->close;