# Scripts for Transmission

A collection of scripts that are useful in combination with the Transmission bittorrent client.

## Installation

1. Copy the contents of this directory to /var/packages/transmission/scripts/
2. Edit /usr/local/transmission/var/settings.json with the following keys:

    "script-torrent-done-enabled": true,                                        
    "script-torrent-done-filename": "/var/packages/transmission/scripts/auto-extract.py",

