##############################################
# $Id: myUtilsTemplate.pm 7570 2015-01-14 18:31:44Z rudolfkoenig $
#
# Save this file as 99_myUtils.pm, and create your own functions in the new
# file. They are then available in every Perl expression.

package main;

use strict;
use warnings;
use POSIX;
use HTTP::Date;
use DateTime;

sub
myUtils_mapmotion_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub mapmotion($$) {
 my ($triggerdev, $brightness) = @_;

 my $virtdev=$triggerdev.".virt_Motion";
 my $readinglastTrigger=$triggerdev."-lastTrigger";
 my $readingbrightness=$triggerdev."-brightness";
 my $minInterval=AttrVal($virtdev,"minInterval","600");
 my $triggertime=time();
 my $triggertimestring= strftime "%F %T", localtime;
 my $triggerdevtype=AttrVal($triggerdev,'subType','');
 my $peerlist=ReadingsVal($virtdev,'peerList','');
 my $lastTriggertime=ReadingsTimestamp("$virtdev","$readinglastTrigger",0 );

 Log 5, ("mapmotion - triggerdev            $triggerdev");
 Log 5, ("mapmotion - brightness            $brightness");
 Log 5, ("mapmotion - virtdev               $virtdev");
 Log 5, ("mapmotion - readinglastTrigger    $readinglastTrigger");
 Log 5, ("mapmotion - readingbrightness     $readingbrightness");
 Log 5, ("mapmotion - minInterval           $minInterval");
 Log 5, ("mapmotion - triggertime           $triggertime");
 Log 5, ("mapmotion - triggerdevtype        $triggerdevtype");
 Log 5, ("mapmotion - peerlist              $peerlist");
 Log 5, ("mapmotion - lastTriggertime       $lastTriggertime");
 Log 5, ("mapmotion - triggertimestring     $triggertimestring");

 if ($triggerdevtype eq "motionDetector") {
  if ((time - time_str2num($lastTriggertime)) >= $minInterval
  or $lastTriggertime == 0) {
    fhem("setreading $virtdev $readinglastTrigger $triggertimestring");
    fhem("setreading $virtdev $readingbrightness $brightness");
    fhem("set $virtdev postEvent $brightness");
    fhem("set $virtdev pressS");
	Log 3, ("mapmotion - virtdev       $virtdev");
  } 
 }
}

1;
