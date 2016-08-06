##############################################
# $Id: 99_RFritzBox.pm $
#
# Module by Erwin Menschhorn
# interface to PRESENCE function
# for situations were FHEM is NOT running on Fritzbox and
# you still want the functions as described in PRESENCE Fritzbox
# MH 12/2013
## usage (using Telnet): 
##     define <myDevice> PRESENCE function {RemoteFritzBox("<devicename in Fritzbox>")} [ <check-interval> [ <present-check-interval> ] ]
##     define <myDevice> PRESENCE function {RemoteFritzBox("<MAC-address of device in Fritzbox>")} [ <check-interval> [ <present-check-interval> ] ]
## or (using Web): 
##     define <myDevice> PRESENCE function {RemoteFritzBoxWeb("<devicename in Fritzbox>"[,(0|1)])} [ <check-interval> [ <present-check-interval> ] ]
##     define <myDevice> PRESENCE function {RemoteFritzBoxWeb("<MAC-address of device in Fritzbox>"[,(0|1)])} [ <check-interval> [ <present-check-interval> ] ]
##                                                                                                     ^- FB number 0 or 1, 0 can be omitted
##     define RemoteFritzBoxWeb dummy  # required to store login-sid! - exactly this name!
##     attr   RemoteFritzBoxWeb event-on-update-reading none # avoid unneccesary events / eventtypes
##     attr   RemoteFritzBoxWeb verbose (1-5) # debug info
##
## debugging hint: define RemoteFritzBox dummy # debugging telnet (optional)
##                 attr RemoteFritzBox verbose 5
##
# requirements: Rpresence.sh in der remote Fritzbox
#               RFritzBox.pm im FHEM Verzeichnis
#               RFritzBoxScan.pl im FHEM Verzeichnis 
#               credentials.cfg im modpath directory    
#               unmodified Fritzbox - Telnet enabled
#
# update history:
# 2013-12-20 initial version (for RPI)
# 2014-02-02 improved starting of daemon and some debug msgs
# 2014-02-14 RemoteFrizBoxWeb added
# 2014-02-20 somec improvement to RemoteFrizBoxWeb & RemoteFrizBox (ping/ok handshake)
# 2014-03-25 minor fix of unitialized message
# 2014-10-20 public version 1.3 minor fixes & MAC-address support in addition to name 
# 2014-11-18 public version 1.4 fixes in RFritzBoxScan, fix for connection refused on startup 
# 2015-01-08 test   version 1.5 persistent login to FB for RemoteFrizBoxWeb 
# 2015-01-20 test   version 1.6 avoid parallel queries for RemoteFrizBoxWeb
#                      support Fritz1750E Repeater (via RemoteFrizBoxWeb)
#                      support 2 Fritzboxes (2 ip-Addresses) at same time    
# 2015-01-22 public version 1.7 
# 2015-03-22 public version 1.9 improved startup, use telnetforblocking for reporting back
#                               changed 'pidof' to 'ps -ef' for OSX compatibility
# 2015-03-25 public version 1.9.1 Loglevel change, fix unint msg on not found (line 272), no modification of global vars ($ipadress,...)
##############################################
package main;

use strict;
use warnings;
use POSIX;
use IO::Socket::INET; ## only for Telnet Access
use FritzBoxUtils; ## only for web access login
use Blocking;

sub FB_checkPw1($$$$);
sub BlockingInformFHEM($);

### config file - usually no change required
my $fullcfgfile =  $attr{global}{modpath} . "/credentials.cfg";
###get config from file
  if(!open(CONFIG, $fullcfgfile)) {
     my $msg = "Cannot open RFritzbox configuration file $fullcfgfile.";
     Log3 "RemoteFritzBox", 1,$msg;
     return $msg;
  }
  my @config = <CONFIG>;
  close(CONFIG);
  my %credentials;
  eval join("", @config);

#  if(!(defined($credentials{RemoteFritzBox}{ipadress}) && defined($credentials{RemoteFritzBox}{username}) && defined($credentials{RemoteFritzBox}{password})) && defined($credentials{RemoteFritzBox}{serverbin}) ) {
  if(!(defined($credentials{RemoteFritzBox}{ipadress}) && defined($credentials{RemoteFritzBox}{username}) && defined($credentials{RemoteFritzBox}{password})) ) {
     my $msg = "Syntax error in RFritzbox configuration file $fullcfgfile.";
     Log3 "RemoteFritzBox", 1,$msg;
     return $msg;
  }

  my $ipstring = $credentials{RemoteFritzBox}{ipadress};
  my $user = $credentials{RemoteFritzBox}{username};
  my $pwd = $credentials{RemoteFritzBox}{password};
  my $FBmodel = $credentials{RemoteFritzBox}{model}; # optional: valid values: FB, FBLAN, 1750E
  my $serverhost = $credentials{RemoteFritzBox}{serverhost};
  my $serverport = $credentials{RemoteFritzBox}{serverport};
  my $serverbin = $credentials{RemoteFritzBox}{serverbin};
  my $speedmatching = $credentials{RemoteFritzBox}{speedmatching}; # if 1 match for speed instead of status
  
  my $fullserverbin = "echo \$serverbin not defined\n";
  $fullserverbin =  $attr{global}{modpath} . "/FHEM/$serverbin $fullcfgfile" if (defined($serverbin)); # full path to Fritzbox daemon 
  $speedmatching = 0 if (! defined($speedmatching)); # default: go for state
  $FBmodel = "FB" unless(defined($FBmodel)); # 7270,7390,7490,...

  my $RFritzBox_debug = 0; # debug level 1-4

  # prevent parallel WEB-queries
  my $FBlockfile = $attr{global}{modpath} . "fhem-RFritzBox-lock.tmp";
  my $telnetDevice; 
  my $telnetClient;
  
sub
RFritzBox_Initialize($$)
{
  my ($hash) = @_;
}

### query Remote FB via telnet interface
sub RemoteFritzBox($) {
   my ($devname) = @_;

   return "RemoteFritzBox($devname) fhem init phase ... query not executed" if (!$init_done); ### patch against zombies during fhem start

   ### check if my server is running
#   my ($serverstatus) = qx(pidof -x $serverbin);
   Log3 "RemoteFritzBox", 5,"RemoteFritzBox Server scanning for device: $devname";
#   if (defined ($serverstatus)) {
#   my $serverstatus = qx(ps -ef | grep $serverbin | grep -v grep | wc -l);
   my $serverstatus = qx(ps -ef | grep -v grep | grep -c RFritzBoxScan);
   chomp $serverstatus; 
   if ($serverstatus > 0) {
#      chomp $serverstatus;
      Log3 "RemoteFritzBox", 5,"RemoteFritzBox Server-Task is running";
   } else {
     ### trying to start the server
     Log3 "RemoteFritzBox", 2, "RemoteFritzBox Server-Task $serverbin starting";
     my $alloutput = "> /dev/null 2>&1";
     system("$fullserverbin $alloutput &");
     select(undef, undef, undef, 2.0); # give daemon time to start before connecting
     Log3 "RemoteFritzBox", 5, "RemoteFritzBox Server-Task $serverbin starting2";
#     my ($serverstatus) = qx(pidof -x $serverbin);
#     if (defined ($serverstatus)) {
#        chomp $serverstatus;
     $serverstatus = qx(ps -ef | grep -v grep | grep -c RFritzBoxScan);
     chomp $serverstatus;
     if ($serverstatus > 0) {
        sleep 10; #additional wait for server process
#        Log3 "RemoteFritzBox", 5,"RemoteFritzBox Server-started by pid $$ with pid $serverstatus for device $devname";
        Log3 "RemoteFritzBox", 2,"RemoteFritzBox Server-started for device $devname";
     } else {
        Log3 "RemoteFritzBox", 1,"RemoteFritzBox Server could not be started";
        return "RemoteFritzBox Server could not be started";
     }
   }

   ### auto-flush on socket
   $| = 1;
 
   ### create a connecting socket
   my $socket = new IO::Socket::INET (
     PeerHost => $serverhost,
     PeerPort => $serverport,
     Proto => 'tcp',
     Timeout => 5,
   );
   unless ($socket) {
      Log3 "RemoteFritzBox", 1, "RemoteFritzBox cannot connect to Server $!";
      return "RemoteFritzBox cannot connect to Server: $!\n"; #  unless $socket;
   }
   my $sockport = $socket->sockport();
   Log3 "RemoteFritzBox", 5, "RemoteFritzBox connected: $serverhost:$serverport on socket $sockport pid=$$";

   my $pingresponse = "";
   do {
      my $pingsize = $socket->send('ping'); # test socket
      $socket->flush;
      $socket->recv($pingresponse, 100);
      Log3 "RemoteFritzBox", 5, "in ack loop"; 
      sleep 0.05; 
   } until ($pingresponse eq "ok");

   my $size = $socket->send($devname);
   Log3 "RemoteFritzBox", 5, "RemoteFritzBox sending request: $devname for socket $sockport";
   ### notify server that request has been sent
   $socket->shutdown(1);
 
   ### receive a response of up to 1024 characters from server
   my $response = "";
   $socket->recv($response, 100);
   Log3 "RemoteFritzBox", 5, "RemoteFritzBox receiving response: $response for socket $sockport";
   $socket->close();
   undef $socket;
   return "$response";
}

### query FB via Web Interface 
sub RemoteFritzBoxWeb($;$) {
   my ($devname,$FBnumber) = @_;
   return "RemoteFritzBoxWeb($devname) fhem init phase ... query not executed" if (!$init_done);
#   $RFritzBox_debug = 0 if (!defined($RFritzBox_debug));

#   $FBnumber = 0 unless(defined($FBnumber) && $FBnumber == 1); # more than one FB to query
   $FBnumber = 0 unless(defined($FBnumber));
   $FBnumber = ($FBnumber == 1)?1:0; # either FB 0 or 1

   my $wipstring = $credentials{RemoteFritzBox}{ipadress};
   my $wuser =     $credentials{RemoteFritzBox}{username};
   my $wpwd =      $credentials{RemoteFritzBox}{password};
#    my $wFBmodel =  $credentials{RemoteFritzBox}{model} if (defined($credentials{RemoteFritzBox}{model}));
#    my $wFBmodel = 'FB' unless (defined($wFBmodel));
   my $wFBmodel =  (defined($credentials{RemoteFritzBox}{model}))?$credentials{RemoteFritzBox}{model}:'FB';

   if ($FBnumber == 1) {  # 2nd Fritzbox
      if (defined($credentials{RemoteFritzBox1}{ipadress})) {  # 2nd FB
         $wipstring = $credentials{RemoteFritzBox1}{ipadress};
         $wuser = $credentials{RemoteFritzBox1}{username} if (defined($credentials{RemoteFritzBox1}{username}));
         $wpwd =  $credentials{RemoteFritzBox1}{password} if (defined($credentials{RemoteFritzBox1}{password}));
         $wFBmodel = $credentials{RemoteFritzBox1}{model} if (defined($credentials{RemoteFritzBox1}{model}));
      } else {
         return "RemoteFritzBoxWeb($devname) 2nd Fritzbox requested but credentials undefined";
      } 
   }

#   unless ( $FBmodel ~~ ['FB', '1750E'] ) {  # supported models
#   unless ( $FBmodel =~ m/\b(FB|FBLAN|1750E)\b/g) { # supported models - more readable...
   unless ( $wFBmodel =~ /(FB|FBLAN|1750E)/) { # supported models - more readable...
      Log3 "RemoteFritzBoxWeb", 3, "RemoteFritzBoxWeb($devname) invalid model $wFBmodel specified, changing to FB";
      $wFBmodel = 'FB';
   }
   Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) FB-number/model set to $FBnumber/$wFBmodel";

   ##try to avoid parallel queries....
   my $wait = 0;
   while ((!open(FBLOCKFILE, ">$FBlockfile")) and ($wait < 10)) {  
        my $sleeptime = int(rand(3)) + 1;
        $wait += $sleeptime;
        Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) waiting $sleeptime seconds for previous scan to complete.";
        sleep $sleeptime;
   }
   return "RemoteFritzBoxWeb($devname) timeout waiting for lockfile" if ($wait >= 10);

   # try a login to the FB return sid on sucess
   $telnetDevice = "telnetForBlockingFn" if($defs{telnetForBlockingFn}); # startup ???
   Log3 "RemoteFritzBoxWeb", 5, "Login to fb with $wipstring,$wuser,$wpwd,$FBnumber";
   my $sid = FB_checkPw1($wipstring,$wuser,$wpwd,$FBnumber);
   Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) Login SID=$sid";

   if (! $sid || $sid eq "0") {
      Log3 "RemoteFritzBoxWeb", 1, "RemoteFritzBoxWeb($devname) Login to Fritzbox $wipstring failed";
      return "Fritzbox login failed";
   }

   my $waittime = time();
   flock(FBLOCKFILE,2); # this is blocking!!!
   $waittime = time() - $waittime;
   Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) was waiting $wait / $waittime seconds for previous scan to complete."; # if ($wait > 0);

   my $url = "http://$wipstring/";
   $url   .= "wlan/wlan_settings.lua" if ($wFBmodel eq "FB");
   $url   .= "net/network_user_devices.lua" if ($wFBmodel eq "FBLAN");
   $url   .= "wlan/rep_settings.lua" if  ($wFBmodel eq "1750E");  
   $url   .= '?sid=' . "$sid";

   Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) HTTP request=$url";
   my $request = {hideurl   => 0,
               url       => $url,
               timeout   => 3,
               data      => '',
               noshutdown=> 1,
               loglevel  => 5,
             };
   my ($err, $data) = HttpUtils_BlockingGet($request);
 
   sleep 1; # additional wait before unlink....
   flock(FBLOCKFILE,8); #unlock
   close(FBLOCKFILE);

   if ($err) {
      return "RemoteFritzBoxWeb error $err during Web query";
      BlockingInformFHEM("deletereading RemoteFritzBoxWeb lastOkSid$FBnumber"); # try a fresh login next time
   }

   my $retval = "";
   $retval =  '***###***' . "$data" .  '***###***' . "\n\n"; # if ($RFritzBox_debug >= 3);
   my @data2 = split(/landevice\:settings\/landevice/, $data) if defined($data);
   my @data3 = split(/\[\d{1,2}\]/, $data2[1]) if defined($data2[1]); # must be 2nd record
   ### check if parse ok
#   if (! (@data3 || (int(@data3) < 1))) {
   if ((! (@data3) || (int(@data3) < 1))) {
      Log3 "RemoteFritzBoxWeb", 4, "parsing of FB-Website failed";
      Log3 "RemoteFritzBoxWeb", 5, "Webcontent returned: $retval \n";
      BlockingInformFHEM("deletereading RemoteFritzBoxWeb lastOkSid$FBnumber"); # try a fresh login next time
      return  "parsing of FB-Website failed";
   }
   $retval = "";
   for (my $i=1; $i<int(@data3); $i++) {
      $retval = "******record = $data3[$i]\n"; # if ($RFritzBox_debug >= 2);
      my ($presence, $padress, $pmac, $pname, $pspeed ) = $data3[$i] =~ /\["active"\] = "(.+?)".*?  \["ip"\] = "(.+?)".*?\["mac"\] = "(.+?)".*?\["name"\] = "(.+?)".*?\["speed"\] = "(.+?)".*/s;
      next if (! defined($presence));  # fix uninit on not found
      $retval .= "******result=$padress***$pmac***$pname***$presence***$pspeed***\n"; # if ($RFritzBox_debug >= 1) ;
#      $presence = 0 if (! defined($presence)); # MH fix uninit on not found 20140325
      $pspeed = 0 if (! $pspeed);
      ($presence == 0)?0:1;
      my $pstate = $presence;
#      $pstate = $presence;
      $pstate = 1 if (($presence == 1) && ($pspeed > 0) && ($speedmatching eq "acctive"));  ### speed matching
      Log3 "RemoteFritzBoxWeb", 5, "$retval"; 

      $retval = "";
      if (defined($pname)) {
         my $msg = "***$presence***$pname***$padress***$pmac***$pspeed***Res:$pstate";
         Log3 "RemoteFritzBoxWeb", 5, $msg;
         $retval .= "$msg\n";
         ### match with requested name or mac
         $pname = $pmac if $devname =~ /^\s*([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}\s*$/; 
         if ($pname eq $devname) {
            Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) match found... status=$pstate";
            return $pstate; # we are done 0==absent , 1==present
         }
      }
   }
   Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb($devname) device not found";
   return "RemoteFritzBoxWeb device=$devname not found";
}


sub
FB_checkPw1($$$$)
{
  my ($host, $user, $pw, $FBnum) = @_;
#  my ($host, $p1, $p2, $FBnum) = @_;
#  my $user = ($p2 ? $p1 : ""); # Compatibility mode: no user parameter
#  my $pw   = ($p2 ? $p2 : $p1);

  my $now = time();

  my $myreading = ReadingsVal("RemoteFritzBoxWeb","lastOkSid" . $FBnum,0);
#  Log3 "RemoteFritzBoxWeb", 5, "readingsval= $myreading";
  my ($lastOkSid, $lastOkTs) = split('\.', $myreading);
  my $rstring = ""; 
#  my $telnetblockingport = (§defs{Internal}{PORT}

  if (defined($lastOkTs) && $lastOkTs != 0) {
#    Log3 "RemoteFritzBoxWeb", 5, "readingsval= $lastOkTs $lastOkSid";
    my $timediff = $now - $lastOkTs;
    if ($timediff < 300) {
       $rstring .= $lastOkSid . '.' . $now;
#       system("(exec $^X $0 7072 'setreading RemoteFritzBoxWeb lastOkSid$FBnum $rstring')&");
       BlockingInformFHEM("setreading RemoteFritzBoxWeb lastOkSid$FBnum $rstring");
       Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb access FB $FBnum using sid from cache $lastOkSid";
       return $lastOkSid
    }
  }

  my $sidtry = (FB_doCheckPW($host, $user, $pw));
  if($sidtry) {
     $rstring .= "$sidtry" . '.' . $now;
#     system("(exec $^X $0 7072 'setreading RemoteFritzBoxWeb lastOkSid$FBnum $rstring')&");
     BlockingInformFHEM("setreading RemoteFritzBoxWeb lastOkSid$FBnum $rstring");
     Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb access with new login ok $rstring";
     return $sidtry;

  } else {
#     system("(exec $^X $0 7072 'deletereading RemoteFritzBoxWeb lastOkSid$FBnum')&");
     BlockingInformFHEM("deletereading RemoteFritzBoxWeb lastOkSid$FBnum");
     return 0;
  }
}


# send result to fhem (modelled after BlockingInformParent)
sub
BlockingInformFHEM($)
{
  my ($param) = @_;
  my $tName = "telnetForBlockingFn";
  $telnetDevice = $tName if($defs{$tName});

  if(!$telnetDevice) {  # search for a suitable telnet device
    foreach my $d (sort keys %defs) {
      my $h = $defs{$d};
      next if(!$h->{TYPE} || $h->{TYPE} ne "telnet" || $h->{SNAME});
      next if($attr{$d}{SSL} || $attr{$d}{password} ||
              AttrVal($d, "allowfrom", "127.0.0.1") ne "127.0.0.1");
      next if($h->{DEF} =~ m/IPV6/);
      $telnetDevice = $d;
      last;
    }
  }

  if(!$telnetDevice) {
    Log3 "RemoteFritzBoxWeb", 1, "RemoteFritzBoxWeb no telnet port found and cannot create one.";
    return;
  }


  # get the telnetclient
  if(!$telnetClient) {
    my $addr = "localhost:$defs{$telnetDevice}{PORT}";
    return if (!$addr); # startup ?, 
    Log3 "RemoteFritzBoxWeb", 4, "RemoteFritzBoxWeb connecting for Inform on addr: $addr"; 
    $telnetClient = IO::Socket::INET->new(PeerAddr => $addr);
    Log3 "RemoteFritzBoxWeb", 1, "RemoteFritzBoxWeb can't connect to $addr $@" if(!$telnetClient);
    return if (!$telnetClient);
  }

  $param =~ s/;/;;/g;

  syswrite($telnetClient, "$param\n");
  return;
}




1;

=pod
=begin html

<a name="RFritzBox"></a>
<h3>RFritzBox - Remote PRESENCE-Fritzbox</h3>

  <p>This Module is an addon to the PRESENCE Module and provides support for PRESENCE-fritzbox functions in situations where FHEM is <b>NOT</b> running on a Fritzbox.
  <p>A complete description how to install, requirements and testing hints is available in the wiki, see: <a href="http://www.fhemwiki.de/wiki/Anwesenheitserkennung_-_Remote_Fritzbox">Remote Fritzbox Wiki</a> and the recent code-versions are published in this thread in <a href="http://forum.fhem.de/index.php/topic,17957.0.html">FHEM Forum</a> ( Top Entry ). This is also the place for support questions.
  <p>2 options are available:
  <ul>
  <li><b>using Telnet</b>
  <ul>
   <li>Definition:
   <pre>
   define &lt;myDevice&gt; PRESENCE function {RemoteFritzBox("&lt;devicename in Fritzbox&gt;")} [ &lt;check-interval&gt; [ &lt;present-check-interval&gt; ] ]
   define &lt;myDevice&gt; PRESENCE function {RemoteFritzBox("&lt;MAC-address of device in Fritzbox&gt;")} [ &lt;check-interval&gt; [ &lt;present-check-interval&gt; ] ]
   define RemoteFritzBox dummy # debugging telnet (optional)
   attr RemoteFritzBox verbose 5
   </pre>
   </li>
  </ul> 
  </li>
  <li><b>using Web-Access</b>
  <ul>
   <li>Definition:
   <pre>
   define &lt;myDevice&gt; PRESENCE function {RemoteFritzBoxWeb("&lt;devicename in Fritzbox&gt;"[,(0|1)])} [ &lt;check-interval&gt; [ &lt;present-check-interval&gt; ] ]
   define &lt;myDevice&gt; PRESENCE function {RemoteFritzBoxWeb("&lt;MAC-address of device in Fritzbox&gt;"[,(0|1)])} [ &lt;check-interval&gt; [ &lt;present-check-interval&gt; ] ]
   ## the parameter after the devicename is the FB number (0 or 1), 0 can be omitted
   define RemoteFritzBoxWeb dummy  # required to store login-sid! - exactly this name!
   attr   RemoteFritzBoxWeb event-on-update-reading none # avoid unneccesary events / eventtypes
   attr   RemoteFritzBoxWeb verbose (1-5) # debug info
   </pre>
   supported models (see credential.cfg) are: 
   <ul>
      <li><b>FB</b>    Fritzbox Models 7270, 7390, 7490, ... queries WLAN-page</li>
      <li><b>FBLAN</b> Fritzbox Models 7270, 7390, 7490, ... queries LAN-page</li>
      <li><b>1750E</b> AVM 1750E Repeater</li>
   </ul>
   </li>
 </ul>
 </li> 
 <li>Requirements: Detail description is available on the wiki, see above link.
 </li>  
</ul>
=end html


