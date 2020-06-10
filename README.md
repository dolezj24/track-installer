# Track installer

Script usage:
1. Fill track info in the script (between lines 8 and 26).
2. Insert track files to track-files folder in coresponding RBR directory structure. See track-files folder as an example. 
3. Put tracksettings.ini info of the track to tracksettings-ini.txt file.
4. (optional) If you add some non-standard track files you must specify them in Uninstall section with Delete "$INSTDIR\\<path_to_file>" command in order to delete them with uninstaller.
5. Compile track-installer.nsi script with NSIS (NsArray plugin is required).
