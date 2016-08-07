##############################################
# $Id: myUtils_thereestateTimer.pm 1001 2016-08-07 13:29:44Z christianuhlmann $
#
# mapping des Zustands der Fenster und Türen an den Homematic WindowRec 
# inkl. Timer bei Türen

package main;

use strict;
use warnings;
use POSIX;
use HTTP::Date;
use DateTime;

####################################################
sub
myUtils_thereestateTimer_Initialize($$)
{
  my ($hash) = @_;
}
# end sub myUtils_thereestateTimer_Initialize($$)
####################################################


####################################################
sub
mapthereestatetimer($$) {
	my ($dev, $state) = @_;
	my $hash = {};
	my $statevirt = $state;

    if ($defs{$dev}) {
		my $devtype=AttrVal($dev,'subType','');

	  	if ($devtype eq "threeStateSensor") {
    		Log 1, ("mapthereestatetimer ($dev): $state");
			my $devvirt=$dev.".virt_WindowRec";

			if ($defs{$devvirt}) {
				if ($state eq "opened") 	{ $statevirt = "open"; }
			 	elsif ($state eq "tilted")	{ $statevirt = "open"; }
			 	elsif ($state eq "close")	{ $statevirt = "closed"; } 
			 	else 						{ $statevirt = $state; }
				my $virt_dev_state = ReadingsVal("$devvirt","virt_state","unknown");

				if($virt_dev_state ne $state) {
   	InternalTimer(gettimeofday()+3, "mapthereestatewithtime", $hash, 0);
				}
			}
    	}
   elsif ($devtype eq "threeStateSensor") {
   	InternalTimer(gettimeofday()+30, "mapthereestatewithtime", $hash, 0);
   }
	}
}

sub mapthereestatewithtime($$$) {
	my ($hash,$dev, $state) = @_;
	my $statevirt = $state;

    if ($defs{$dev}) {
		my $devtype=AttrVal($dev,'subType','');

	  	if ($devtype eq "threeStateSensor") {
    		Log 1, ("mapthereestatetimer ($dev): $state");
			my $devvirt=$dev.".virt_WindowRec";

			if ($defs{$devvirt}) {
				if ($state eq "opened") 	{ $statevirt = "open"; }
			 	elsif ($state eq "tilted")	{ $statevirt = "open"; }
			 	elsif ($state eq "close")	{ $statevirt = "closed"; } 
			 	else 						{ $statevirt = $state; }
				my $virt_dev_state = ReadingsVal("$devvirt","virt_state","unknown");

				if($virt_dev_state ne $state) {
#					fhem("set $devvirt postEvent $statevirt");
#					fhem("setreading  $devvirt virt_state $statevirt");
					Log 1, ("mapthereestatewithtime");
				}
			}
    	}
   elsif ($devtype eq "threeStateSensor2") {
   	InternalTimer(gettimeofday()+30, "Log 1, ("HAHA")", $hash, 0);
   }
	}
}



1;
