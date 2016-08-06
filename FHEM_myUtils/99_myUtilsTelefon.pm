#################################################
# $Id: 99_myUtilsTelefon.pm 1932 2012-10-06 20:15:33Z ulimaass $
package main;

use strict;
use warnings;
use POSIX;
use FritzBoxUtils;

# fuer Telefonanrufe
our @A;
our @B;
our @C;
our @D;
our @E;
our %TelefonAktionsListe;


sub myUtilsTelefon_Initialize($$) {
    my ($hash) = @_;

    #...

}
################################################################

sub SendSMS ($$) {
    my $adress = $_[0] . '@sms.kundenserver.de';
    my $body   = $_[1];
    Log( 3, "SendSMS: $adress - $body" );
    FB_mail( $adress, "", $body );

    # end sub SendSMS
}
#####################################
# Anruffunktionen ueber Fritzbox

sub FBCall ($$) {

    my $callnr   = $_[0];
    my $duration = $_[1];

    Log( 3, "FBCall: $callnr mit Dauer $duration" );

    $callnr = "ATDT" . $callnr . "#";
    my $ret = "ATD: " . `echo $callnr | nc 127.0.0.1 1011`;
    InternalTimer( gettimeofday() + $duration, "FBHangOn", "", 0 );
    return;
}

sub FBHangOn () {
    Log( 3, "FBHangOn aufgerufen" );

    my $ret = " ATH: " . `echo "ATH" | nc 127.0.0.1 1011`;
    $ret =~ s,[\r\n]*,,g;
    return;
}

######################################

sub TelefonAktion($$) {

    # es wird der Name und die interne angerufene Nummer uebergeben

    my ($caller) = split( '\(', $_[0] );
    $caller = ltrim( rtrim($caller) );

    my $intern = $_[1];

    # Log(3,"TelefonAktion: $caller $intern");
    # Sound ausgeben

    my $com = $main::TelefonAktionsListe{$caller};

    if ($com) {
        Log( 3, "TelefonAktion: commando: $com" );
        sig2_repeat( $com, 5, 4 );
    }    # falls commando vorhanden

}    # end sub TelefonAktion

######################################

sub TelefonMonitor($) {
    our $extnum;
    our $intnum;
    our $extname;
    our $callID;
    our $callDuration;
    # Anrufdauer als Integervariable speichern
    our $intCallDuration;  
    our $stat;
    our @lastPhoneEvent;
    my $i;
    my $j;
    our $ab;
    my $callmonitor = $defs{"callmonitor"};

    my ( $event, $arg ) = split( ':', $_[0] );
    $arg = ltrim($arg);

    # Log(3,"TM: event: $event arg: $arg");
    if ( $event eq "event" ) {
        $stat = $arg;
        return;
    }    # end if event

    if ( $stat eq "ring" ) {
        if ( $event eq "external_number" ) {
            $extnum = $arg;
            return;
        }    # if external number

        if ( $event eq "external_name" ) {
            $extname = $arg;
            return;
        }
        if ( $event eq "internal_number" ) {
            $intnum = $arg;
            return;
        }    # end if intnum

        if ( $event eq "call_id" ) {
            $callID = $arg;
            
            $lastPhoneEvent[$callID] = $stat;
            
            # hier koennen wir eine anrufgesteuerte Aktion starten
            TelefonAktion( $extname, $intnum );

            $B[$callID] = EventZeit();
            $C[$callID] = $extname;
            $D[$callID] = $extnum;
            return;
        }    # end if callid
        return;
    }    # end if ring loop

    if ( $stat eq "connect" ) {
        if ( ( $event eq "internal_connection" ) && ( $arg =~ m/Answering_Machine_.*/ ) )
        {
            $ab = "AB";
        }    # end if internal_connection
    }    # end if connect

    if ( $stat eq "call" ) {
        if ( $event eq "external_number" ) {
            $extnum = $arg;
            return;
        }    # if external number

        if ( $event eq "external_name" ) {
            $extname = $arg;
            return;
        }
        if ( $event eq "call_id" ) {
            $callID     = $arg;

            $B[$callID] = EventZeit();
            $C[$callID] = $extname;
            $D[$callID] = $extnum;
            
            $lastPhoneEvent[$callID] = $stat;
            return;
        }    # end if callid
        return;
    }    # end if callloop

    if ( $stat eq "disconnect" ) {

        if ( $event eq "call_duration" ) {
            $intCallDuration = $arg;
            $callDuration = sprintf( "%2d:%02d", ( $arg / 60 ), $arg % 60 );
            return;
        }    # if call_duration
        
        if ( $lastPhoneEvent[$callID] eq "call" ) {
            if ( $intCallDuration eq 0 ) {
                $A[$callID] = "out_notconnected";
                # hier notieren was passieren soll, wenn es ein eingehender Anruf war,
                # der nicht angenommen wurde
            } elsif ( $intCallDuration gt 0 ) {
                $A[$callID] = "out_connected";
                # hier notieren was passieren soll, wenn es ein eingehender Anruf war,
                # der angenommen wurde
            }
        } elsif ( $lastPhoneEvent[$callID] eq "ring") {
            if ( $intCallDuration eq 0 ) {
                $A[$callID] = "in_notconnected";
                # hier notieren was passieren soll, wenn es ein ausgehender Anruf war,
                # der nicht angenommen wurde

                $intCallDuration = undef;
            } elsif ( $ab eq "AB" ) {
                $A[$callID] = "AB";
                $ab = undef;
                # hier notieren was passieren soll, wenn der AB dranging

                $intCallDuration = undef;
            } elsif ($intCallDuration gt 0 ){
                $A[$callID] = "in_connected";
                # hier notieren was passieren soll, wenn es ein ausgehender Anruf war, 
                # der angenommen wurde
                
                $intCallDuration = undef;
            }
        }
        
        # hier notieren was generell passieren soll, sobald ein Anruf beendet wurde 
        # (egal ob angenommen, nicht angenommen, aus- oder eingehend oder der AB dranging)

        if ( $event eq "call_id" ) {
            $callID = $arg;

            # shiften der alten Inhalte
            my $tt;
            readingsBeginUpdate($callmonitor);

            for ( $i = 4 ; $i > 0 ; $i-- ) {
                foreach $j ( 'A' .. 'E' ) {

                    #   $defs{"callmonitor"}{READINGS}{$j.($i-1)}{VAL};

                    $tt = ReadingsVal( "callmonitor", $j . ( $i - 1 ), "-" );
                    readingsBulkUpdate( $callmonitor, $j . $i, $tt );
                }    # end j
            }    # end i
            $E[$callID] = $callDuration;
            readingsBulkUpdate( $callmonitor, "A0", $A[$callID] );
            readingsBulkUpdate( $callmonitor, "B0", $B[$callID] );
            readingsBulkUpdate( $callmonitor, "C0", $C[$callID] );
            readingsBulkUpdate( $callmonitor, "D0", $D[$callID] );
            readingsBulkUpdate( $callmonitor, "E0", $E[$callID] );

            readingsEndUpdate( $callmonitor, 1 );
            $stat = "";

            return;
        }    # end if callid

    }    # end if disconnect

##############################
}    #end sub TelefonMonitor

sub EventZeit() {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime( time() );
    return sprintf(
        "%2d:%02d:%02d %2d.%02d.%4d",
        $hour, $min, $sec, $mday,
        ( $mon + 1 ),
        ( $year + 1900 )
    );
}    # end sub EventZeit
###################

1;
