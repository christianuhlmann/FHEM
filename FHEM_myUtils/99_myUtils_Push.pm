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
myUtils_Push_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub PushInfo($$) {
   my ($msgsubj,$msgtext) = @_;

#   fhem("set SYS.Telegrambot message '$msgsubj - $msgtext' ")
   fhem("set SYS.Telegrambot message @#Hausautomation '$msgsubj - $msgtext' ")
}

1;
