# Description:
# Calculate bandwidth between router and host(variable laddr) 
# via Mikrotik Bandwidth Server
#
# Prerequisites:
#   host on other side, should have turned on Bandwidth Server
# Variables:
#   luser - user for bandwidth server
#   lpass - password for bandwidth server
#   laddr - host with bandwidth server
#   filename - name for file with measurements results


:log info "------------ BW-TEST Starts--------------";

:local luser "username";
:local lpass "password";
:local laddr "ip_address";

:local avrRX 0;
:local avrTX 0;


# DOWNLOAD TEST
:log info "----> Measuring RX (30 sec)........";
:do {/tool
   bandwidth-test duration=30s user=$luser password=$lpass protocol=tcp address=$laddr direction=receive do={
     :set $avrRX ("rx-total-average: " . ($"rx-total-average" / 1048576) . "." . ($"rx-total-average" % (1048576) / 1024) . " Mbps" );
   }
} on-error={:log error message="RX script failed"}

:delay 2s;

# UPLOAD TEST
:log info "----> Measuring TX (30 sec) ........";
:do {/tool
  bandwidth-test duration=30s user=$luser password=$lpass protocol=tcp address=$laddr direction=transmit do={
     :set $avrTX ("tx-total-average: " . ($"tx-total-average" / 1048576) . "." . ($"tx-total-average" % (1048576) / 1024) . " Mbps" );
  }
} on-error={:log error message="TX script failed"}

:log info message=$avrRX;
:log info message=$avrTX;
:log info "-------- End of  BW-TEST------------";


################# SAVING RESULTS WITH DATE ######################
:local filename "LOG_BW_TEST.txt";
:local ds [/system clock get date];
:local ts [/system clock get time];
:local months ("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec");
:local month [ :pick $ds 0 3 ];
:local mm ([ :find $months $month -1 ] + 1);
:if ($mm < 10) do={ :set mm ("0" . $mm); };
:set ds ([:pick $ds 7 11] . $mm . [:pick $ds 4 6]);

:if  ( [:len [/file find name=$filename]] = 0) do={
:log info "Log file does not exist. Creating a new one.....";
/file print file=$filename where name="";
}

:log info "Adding result to the end of the lof file......";
/file set $filename contents=([get $filename contents]  ."\n".$ds." ".$ts." --> ");
/file set $filename contents=([get $filename contents]  . $avrRX ."    ". $avrTX);

################# SEND TO EMAIL ######################
:local date [/system clock get date];
:local body1 "Mikrotik speedtest: $date device_name";
:local smtpserv [:resolve "smtp.gmail.com"];
:local email "e-mail";
:local pass "password";
:local toemail "e-mail";
/tool e-mail send server=$smtpserv port=587 user=$email password=$pass start-tls=yes \
     to=$toemail \
     from=$email \
     subject="$body1" \
     body="$body1" \
     file=$filename;
:delay 60;
:log info "Sent speed result to e-mail";
