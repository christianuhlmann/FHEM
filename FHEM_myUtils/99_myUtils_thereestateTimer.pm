##############################################
# $Id: 99_myUtils_thereestateTimer.pm 1001 2016-08-07 13:29:44Z christianuhlmann $
#
# mapping des Zustands der Fenster und Türen an den Homematic WindowRec 
# inkl. Timer bei Türen

package main;

use strict;
use warnings;
use POSIX;
use HTTP::Date;
use DateTime;

##############################################
sub
myUtils_thereestateTimer_Initialize($$)
{
  my ($hash) = @_;
}
# end sub myUtils_thereestateTimer_Initialize
##############################################


##############################################
sub
mapthereestatetimer($$) {
	my ($dev,$state) = @_;
	my $hash = {};

	Log 5, ("mapthereestatetimer: name $dev");
	Log 5, ("mapthereestatetimer: event $state");

    if ($defs{$dev}) { 
		my $devtype=AttrVal($dev,'subType','');
    		Log 5, ("mapthereestatetimer subType: $devtype - $dev: $state:");
	  	if ($devtype eq "threeStateSensor") {
			my $threeStateType=AttrVal($dev,'threeStateType','');
    		Log 5, ("mapthereestatetimer threeStateType: $threeStateType - $dev: $state:");

				$hash->{DEV} = $dev;
				$hash->{STATE} = $state;

				Log 5, ("mapthereestatetimer: dev $dev");
				Log 5, ("mapthereestatetimer: state $state");
				

			if ($threeStateType eq "window") {
    			Log 3, ("mapthereestatetimer start InternalTimer in 1 sec for device: $dev");
	   			InternalTimer(gettimeofday()+1, "mapthereestatewithtime", $hash, 0);			
			}
			elsif ($threeStateType eq "door") {
    			Log 3, ("mapthereestatetimer start InternalTimer in 30 sec for device: $dev");
	   			InternalTimer(gettimeofday()+30, "mapthereestatewithtime", $hash, 0);			
			}
	  	}
    }
}
# end sub mapthereestatetimer
##############################################

##############################################
sub mapthereestatewithtime($) {
	my ($hash) = @_;

	my $dev = $hash->{DEV};
	my $state = $hash->{STATE};

	my $statevirt = $state;
	my $devvirt=$dev.".virt_WindowRec";

	Log 5, ("mapthereestatewithtime: dev: $dev");
	Log 5, ("mapthereestatewithtime: state: $state");
	Log 5, ("mapthereestatewithtime: statevirt: $statevirt");
	Log 5, ("mapthereestatewithtime: devvirt: $devvirt");

#	if ($defs{$devvirt}) {
		if    ($state eq "opened") 	{ $statevirt = "open"; }
	 	elsif ($state eq "tilted")	{ $statevirt = "open"; }
	 	elsif ($state eq "close")	{ $statevirt = "closed"; } 
	 	elsif ($state eq "closed")	{ $statevirt = "closed"; } 
	 	else 						 { $statevirt = $state; }

		my $virt_dev_state = ReadingsVal("$devvirt","virt_state","unknown");

		if($virt_dev_state ne $state) {

			fhem("set $devvirt postEvent $statevirt");
			fhem("setreading  $devvirt virt_state $statevirt");
			Log 3, ("mapthereestatewithtime ($devvirt): $statevirt");
		}
#	}
	# alle timer löschen
	RemoveInternalTimer($hash); 
}

# end sub mapthereestatewithtime
##############################################

1;
