# autoit_scripts

AutoIt applications intended to aid with certain tasks during my first job. Files are dated 2014-2015, this is way before I started professional work in IT.

FolderCreator is an finished application, it's purpose is to generate a bunch of empty folders with specific pattern name.

Copy Handler is much bigger, unfinished application (15% of planned features done). It utilizes inter process communication via shared variables using Windows kernel calls, between master process and a service responsible for file copy process (AutoIt was single threaded back then and probably still is today). IPC doesn't work with Windows 10 or above anymore.

Icons not included.
