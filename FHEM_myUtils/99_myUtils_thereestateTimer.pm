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
mapthereestatetimer($$$$) {
	my ($name,$event,$dev,$state) = @_;
	my $hash = {};

	Log 1, ("mapthereestatetimer: name $name");
	Log 1, ("mapthereestatetimer: event $event");

    if ($defs{$dev}) { 
		my $devtype=AttrVal($dev,'subType','');
    		Log 1, ("mapthereestatetimer subType: $devtype - $dev: $state:");
	  	if ($devtype eq "threeStateSensor") {
			my $threeStateType=AttrVal($dev,'threeStateType','');
    		Log 1, ("mapthereestatetimer threeStateType: $threeStateType - $dev: $state:");

				$hash->{NAME} = $defs{$name};
				$hash->{DEV} = $defs {$dev};
				$hash->{STATE} = $defs {$state};

			if ($threeStateType eq "window") {
    			Log 1, ("mapthereestatetimer InternalTimer 3");
	   			InternalTimer(gettimeofday()+3, "mapthereestatewithtime", $hash, 0);			
			}
			elsif ($threeStateType eq "door") {
    			Log 1, ("mapthereestatetimer InternalTimer 30");
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
	my $name_hash = $hash->{NAME};
	my $dev_hash = $hash->{"DEV"};
	my $state_hash = $hash->{"NAME"};
	
	my $name = $name_hash->{NAME};
	my $dev = $dev_hash->{NAME};
	my $state = $state_hash->{NAME};

	my $statevirt = $state;
	
	my $devvirt=$dev.".virt_WindowRec";
	
	Log 1, ("mapthereestatewithtime: devvirt: $devvirt");

#	if ($defs{$devvirt}) {
#		if    ($state eq "opened") 	{ $statevirt = "open"; }
#	 	elsif ($state eq "tilted")	{ $statevirt = "open"; }
#	 	elsif ($state eq "close")	{ $statevirt = "closed"; } 
#	 	else 						{ $statevirt = $state; }

#		my $virt_dev_state = ReadingsVal("$devvirt","virt_state","unknown");

#		if($virt_dev_state ne $state) {

			# fhem("set $devvirt postEvent $statevirt");
			# readingsSingleUpdate($devvirt,'virt_state',"$statevirt",0);
#			Log 1, ("mapthereestatewithtime ($devvirt): $statevirt");
			Log 1, ("mapthereestatewithtime");

#		}
#	}
	# alle timer löschen
	RemoveInternalTimer($hash); 
}

# end sub mapthereestatewithtime
##############################################

1;
