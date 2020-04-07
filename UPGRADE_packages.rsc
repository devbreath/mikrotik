# Description:

/system package update check-for-updates
:delay 5
:if ( [/system package update get installed-version] != [/system package update get latest-version] ) do={
/system script run backup
/system package update download
/system reboot
}