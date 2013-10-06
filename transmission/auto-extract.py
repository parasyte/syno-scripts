#!/usr/bin/env python
# Script:   Auto-Extract (Python edition)
# Author:   Mark Stahler <markstahler@gmail.com>
# Website:  http://bitbucket.org/markstahler/auto-unrar-python/, http://www.markstahler.ca
# Version:  1.02
# Released: January 24 2010
# License:  BSD
#
# Description:  Auto-Extract is a script designed to be run as a cron job (or scheduled task).
#   Its purpose is to recursively scan a directory for archive files and extract them. The script
#   is designed to be run at regular intervals and will create a file named .unrared in each
#   directory that contains an archive extracted by the script. This file is used to tell the
#   script, on subsequent scans, that the archive in the marked folder has previously been
#   extracted.
#
# Limitations:  Auto-Extract has been written to support one archive group per directory scanned
#   (Example a movie in its own directory with files .rar, .r01, .r02, .nfo, etc). This works well
#   with movies and other files that are packed and downloaded in individual directories.
#
#   Auto-Extract will overwrite previously extracted files if it does not find a .unrared file
#   present in the archive directory.
#
# Requirements:
# -Python 2.4 or newer
# -unrar in your path [Freeware command line version available from http://www.rarlab.com/]
#
# BUGS:
#   -Cannot tell if an archive has been fully downloaded
#
# TODO:
#   -Proper logging (ie. debug, info messages)
#   -Check for available disk space and estimate required
#   -Support for other archive types
#

import logging
logging.basicConfig(
    level="INFO",
    format="%(asctime)s %(module)s %(levelname)s %(message)s"
)

import os
import os.path
import sys

class Unrar(object):
    def __init__(self):
        # Class Variables
        #------------------
        self.lock_file_name = ".auto-extract.locked"
        self.mark_file_name = ".unrared"
        self.extensions_unrar = [".rar", ".r01"]        # List of extensions for auto-extract to look for
        self.extensions_unzip = [".zip"]
        self.supported_filetypes = []                   # Filled by extensions_list function
        self.extensions_list()
        self.download_dir = ""

        # Sanity Checks
        #------------------
        # Check that we can find unrar on this system
        self.unrar_check()

    def extensions_list(self):
        """Creates the list of extensions supported by the script"""
        self.supported_filetypes.extend(self.extensions_unrar)       # rar support
        self.supported_filetypes.extend(self.extensions_unzip)       # zip support (Not implemented yet)

    def get_unrar_exe(self):
        """Figures out what the unrar executable name should be"""
        unrar_name = "unrar"
        # If on Windows, add .exe to the end of the program file name
        if sys.platform == "win32":
            unrar_name = "UnRAR.exe"
        return unrar_name

    def find_exe(self, exe_name):
        """Attempts to find unrar on the system path and return the directory unrar is found in"""
        # Search the default Unrar for Windows directory
        if sys.platform == "win32":
            win_unrar_dir = os.path.join(os.getenv("PROGRAMFILES"), "unrar")
            if os.path.exists(win_unrar_dir):
                files = os.listdir(win_unrar_dir)
                if exe_name in files:
                    # Found Unrar for Windows
                    logging.debug("Found %s in %s", exe_name, win_unrar_dir)
                    return os.path.join(win_unrar_dir, exe_name)
        
        # Search the system path for the unrar executable
        for dirname in os.getenv("PATH").split(os.pathsep):
            # Ensure the dir in the path is a real directory
            if os.path.exists(dirname):
                files = os.listdir(dirname)
                if exe_name in files:
                    # Found it!
                    logging.debug("Found %s in %s", exe_name, dirname)
                    return os.path.join(dirname, exe_name)
            else:
                # The directory in the path does not exist
                pass
        
        # unrar not found on this system
        return False

    def unrar_check(self):
        """Sanity check to make sure unrar is found on the system"""
        unrar_name = self.get_unrar_exe()
        self.unrar_exe = self.find_exe(unrar_name)
        if self.unrar_exe == False:
            logging.error("%s not found in the system path", unrar_name)
            sys.exit(1)

    def traverse_directories(self):
        """Scan the download directory and its subdirectories"""
        # Search download directory and all subdirectories
        logging.info("Walking %s...", self.download_dir)
        for dirname, dirnames, filenames in os.walk(self.download_dir):
            self.scan_for_archives(dirname)

    def scan_for_archives(self, dirname):
        """Check for rar files in each directory"""
        # Look for a .rar archive in dir
        dir_listing = sorted(os.listdir(dirname), key=str.lower)
        # First archive that is found with .rar extension is extracted
        # (for directories that have more than one archives in it)
        for filename in dir_listing:
            if filename in (self.mark_file_name, self.lock_file_name):
                logging.debug("Skipping %s", dirname)
                break

            if os.path.splitext(filename)[1] in self.supported_filetypes:
                # Start extracting file
                self.start_unrar(dirname, filename)
                # .rar was found, dont need to search for .r01
                break

    def start_unrar(self, dirname, archive_name):
        """Extract a rar archive"""
        # Create command line arguments for rar extractions
        cmd_args = [
            self.unrar_exe,                         # unrar
            "e",                                    # command line switches: e - extract
            "-idq",                                 # Quiet mode
            "-y",                                   # Assume yes to all queries (overwrite)
            os.path.join(dirname, archive_name),    # archive path
            self.download_dir                       # destination
        ]

        logging.info("Extracting %s...", archive_name)
        try:
            os.spawnv(os.P_WAIT, self.unrar_exe, cmd_args)
        except OSError:
            logging.error("%s not found in the given path", self.unrar_name)
            sys.exit(1)

        # Sucessfully extracted archive, mark the dir with a hidden file
        self.mark_dir(dirname)

    def mark_dir(self, dirname):
        """Creates a hidden file so the same archives will not be extracted again"""
        mark_file = os.path.join(dirname, self.mark_file_name)
        f = open(mark_file, "w")
        f.close()
        logging.debug("%s file created", self.mark_file_name)

    def lock(self):
        """Creates a hidden file so the script cannot run multiple times"""
        os.close(os.open(
            os.path.join(self.download_dir, self.lock_file_name),
            os.O_CREAT | os.O_EXCL,
            0644
        ))
        logging.debug("%s file created", self.lock_file_name)

    def unlock(self):
        """Deletes the hidden lock file"""
        os.unlink(os.path.join(self.download_dir, self.lock_file_name))
        logging.debug("%s file deleted", self.lock_file_name)

if __name__ == "__main__":
    unrar = Unrar()

    # Ensure download dir argument is in fact a directory
    if len(sys.argv) > 1 and os.path.isdir(sys.argv[1]):
        unrar.download_dir = os.path.abspath(sys.argv[1])
    else:
        unrar.download_dir = os.getenv("TR_TORRENT_DIR", "")

    if not os.path.isdir(unrar.download_dir):
        print "usage: %s <download_dir>" % sys.argv[0]
        sys.exit(1)

    try:
        # Obtain the global lock
        unrar.lock()

        def unlock():
            """Unlock the global lock file"""
            unrar.unlock()

        import atexit
        atexit.register(unlock)
    except:
        logging.error("Unable to obtain global lock")
        exit(1)

    # Extract
    unrar.traverse_directories()

    # Re-index
    perl = unrar.find_exe("perl")
    if perl != False:
        logging.info("Reindexing %s...", unrar.download_dir)
        reindexer = os.path.join(
            os.path.dirname(os.path.realpath(__file__)),
            "update-syno.pl"
        )
        os.spawnv(os.P_WAIT, perl, [
            perl,
            reindexer,
            unrar.download_dir
        ])
    else:
        logging.error("perl not found in the system path")
        sys.exit(1)

