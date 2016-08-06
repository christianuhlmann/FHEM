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

 Log 1, ("mapmotion - triggerdev            $triggerdev");
 Log 1, ("mapmotion - brightness            $brightness");
 Log 1, ("mapmotion - virtdev               $virtdev");
 Log 1, ("mapmotion - readinglastTrigger    $readinglastTrigger");
 Log 1, ("mapmotion - readingbrightness     $readingbrightness");
 Log 1, ("mapmotion - minInterval           $minInterval");
 Log 1, ("mapmotion - triggertime           $triggertime");
 Log 1, ("mapmotion - triggerdevtype        $triggerdevtype");
 Log 1, ("mapmotion - peerlist              $peerlist");
 Log 1, ("mapmotion - lastTriggertime       $lastTriggertime");
 Log 1, ("mapmotion - triggertimestring     $triggertimestring");

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
