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

sub
myUtils_thereestateTimer_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.
sub mapthereestatetimer($$) {
	my ($dev, $state) = @_;
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
					fhem("set $devvirt postEvent $statevirt");
					fhem("setreading  $devvirt virt_state $statevirt");
					Log 1, ("mapthereestatetimer ($devvirt): $statevirt");
				}
			}
    	}
	}
}

1;
