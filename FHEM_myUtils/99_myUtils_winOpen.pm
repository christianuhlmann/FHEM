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
myUtils_winOpen_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub winOpenStart($;$) {
    #Als Parameter muss der device-Name übergeben werden
    my $dev=shift(@_);
   
    #Optional kann noch ein Zähler für das erneute Triggern übergeben werden,
    #dieser ist per default 0
    my $retrigger=shift(@_);
    $retrigger=0 if (!$retrigger);
   

    #Erst mal prüfen, ob das übergebene device überhaupt existiert
    if ($defs{$dev}) {
   
        #Aus dem device, sofern vorhanden das Attribut winOpenMaxTrigger auslesen, das
        #angibt, wie oft eine Meldung ausgegeben werden soll.
        #Fehlt dieses Attribut oder ist 0, dann wird für das device gar keine Offen-Meldung ausgegeben
        my $maxtrigger=AttrVal($dev,'winOpenMaxTrigger',0);
   
        if($maxtrigger) {
   
    	  #Festlegen des Namens für den Timer, der angelegt wird um die Meldung nach gewünschter
          #Zeit auszugeben.
          my $devtimer=$dev.'_OpenTimer';

          #Sollte dieser Timer bereits existieren, so wird er zunächst gelöscht.
          fhem("delete $devtimer") if ($defs{$devtimer});

		 
          #Holen von weiteren Attributen, sofern vorhanden:
         
          #Zeit, nach der die Meldung ausgegeben werden soll
          #Default sind 10 Minuten, falls nicht angegeben
          my $waittime=AttrVal($dev,'winOpenTimer','00:10:00');

          #Zeit für die Folge-Meldungen, sofern abweichend angegeben
          #Default ist die normale Zeit, die oben schon ermittelt wurde
          my $devtimer2=AttrVal($dev,'winOpenTimer2',$waittime);

          #Ein eventuell definierter "schöner" Name für das Device, der in der Meldung ausgegeben werden soll.
          #Ist der nicht angegeben, wird das Device-Alias genommen, fehlt auch das, wir einfach der
          #device-Name genommen.
          my $devname=AttrVal($dev,'winOpenName',AttrVal($dev,'alias',$dev));
         
          #Eine Art Typ (Tür oder Fenster), der bei mir quasi im Betreff der Offen-Meldung angegeben wird
          my $devtype=AttrVal($dev,'winOpenType','Fenster/Tür');

          #Hier wandeln wir noch den state des devices in deutschen Klartext um
          my $devstate='offen';
          $devstate='gekippt' if (ReadingsVal($dev,'state','') eq 'tilted');
         
          #Hier wird, sofern bereits eine Wiederholung der Offen-Meldung ausgegeben werden soll,
          #dies textlich auch so berücksichtigt.
          my $immer='noch ';
          $immer='immer noch ' if ($retrigger>0);

		  # Test für Raum
		  my $room = AttrVal($dev,'room','');

          #Jetzt wird der Ausgabebefehl für die Offenmeldung zusammengebaut
          #(Ich habe eine sub PushInfo, die Betreff und Text als Parameter erhält und aktuell
          # meine Meldungen über Pushover ausgibt)
          my $pushcmd="PushInfo('Raum: $room $devtype: $devname','ist $immer $devstate');;";
         
          #Sind wir schon beim Einrichten einer Folgemeldung, muss die Wartezeit für die Folgemeldungen
          #genommen werden.
          $waittime=$devtimer2 if ($retrigger);

          #Wir erhöhen hier den Trigger-Zähler um 1...
          $retrigger+=1;
          #... und fügen das Re-Triggern als weitere Code-Zeile für das at-DEF an.
          #das sorgt dann dafür, dass diese Funktion hier nach Ablauf des Timers einfach wieder
          #getriggert wird, um einen neuen Timer anzulegen für die Folgemeldung
          $pushcmd.="winOpenStart('$dev','$retrigger');;" if($retrigger < $maxtrigger);

         
          #Nachdem wir hier alles zusammen haben,
          #legen wir den Timer (das at) an und legen ihn freundlicherweise in den, bzw. die
          #selben Räumen ab, wie auch das auslösende device.
          fhem("define $devtimer at +$waittime {$pushcmd}");
          fhem("attr $devtimer room ".AttrVal($dev,'room','Unsorted'));
        }
    }
}

sub winOpenStop($) {
    #Dazu muss das entsprechende device (TK/FK) per Name hierher übergeben werden

    #Den übergebenen device-Namen holen
    my ($dev)=@_;

    #Den Namen des Timers zusammenbauen
    my $devtimer=$dev.'_OpenTimer';
       
    #Existiert ein Timer diesen Namens, so wird er jetzt gelöscht und das war's auch schon.
    if ($defs{$devtimer}) {
        fhem("delete $devtimer");
    }
}

1;
