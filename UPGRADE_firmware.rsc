# Description:

:if ( [/system routerboard get current-firmware] != [/system routerboard get upgrade-firmware] ) do={
/system routerboard upgrade
/system reboot
}