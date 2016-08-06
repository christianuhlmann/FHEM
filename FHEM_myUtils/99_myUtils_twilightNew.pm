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
myUtils_twilightNew_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub twilightNew($$$$$) {
  my ($twilight, $reading, $min, $max, $offset) = @_;

  $offset = 0 if(!$offset);


  my $t = hms2h(ReadingsVal($twilight,$reading,0));

  $t = hms2h($min) if(defined($min) && (hms2h($min) > $t));
  $t = hms2h($max) if(defined($max) && (hms2h($max) < $t));

  $t = $t + ($offset/3600);

  return h2hms_fmt($t);
}

1;
