##############################################
package main;

use strict;
use warnings;
use POSIX;
use Time::HiRes qw(gettimeofday);

my $timerParam;

sub
perfmon_Initialize($$)
{
  my ($hash) = @_;
  $hash->{UndefFn} = "perfmon_Undef";

  my $next = int(gettimeofday()) +1; 
  $timerParam -> {'next'} = $next;
  InternalTimer($next, 'perfmon_ProcessTimer', $timerParam, 0);
  Log 2, "Perfmon: ready to watch out for delays greater than one second";
  return $hash;
}

sub
perfmon_ProcessTimer(@)
{

  my $param = shift;
  my $now = gettimeofday();
  my $freeze = $now - $param -> {'next'};

  if ($freeze > 1)
  {

    $freeze = int($freeze * 1000) / 1000;
    Log 1, strftime("Perfmon: possible freeze starting at %H:%M:%S, delay is $freeze", localtime($param -> {'next'}));
  }

  $param -> {'next'} = int($now) +1;
  InternalTimer($param -> {'next'}, 'perfmon_ProcessTimer', $param, 0);
}

sub
perfmon_Undef($$)
{
  RemoveInternalTimer($timerParam -> {'next'});
  Log 2, "Perfmon: clean-up";
  return undef;
}


1;

=pod
=begin html

<a name="Perfmon"></a>
<h3>Performance Monitor</h3>
<ul>
This auto loaded module creates a watchdog process and monitors the "responsiveness" of fhem. If there is a delay of more than 1000msec (where fhem is unable to process it) a fhem log line will be created. Helpful for tuning fhem an / or finding out the course of delays in processing fhem commands.
</ul>   

=end html
=cut



