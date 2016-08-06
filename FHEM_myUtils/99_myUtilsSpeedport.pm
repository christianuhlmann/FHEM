##############################################
# $Id: myUtilsSpeedport.pm 
#
# requires:
# https://github.com/melle/l33tport
#
# forum:
# https://forum.fhem.de/index.php/topic,53989.0.html
package main;

use strict;
use warnings;
use POSIX;
use JSON qw( decode_json );

my $l33tport_path = '/home/christian/l33tport-master/l33tport.js';
my $dummy_device = 'SYS.Speedport';


sub
myUtilsSpeedport_Initialize($$)
{
  my ($hash) = @_;
}

sub
SpeedportStatus {
fhem("defmod $dummy_device dummy");
fhem("attr $dummy_device room System");
fhem("deletereading $dummy_device .*",1);
SpeedportStatus_function();
#SpeedportOverview_function();
SpeedportLTE_function();
SpeedportLan_function();
}

sub
SpeedportStatus_function {
my $json_text = `node $l33tport_path -o json -f Status`;
my $records = decode_json($json_text);
for my $record (@$records) {
	if ($record->{'varid'} eq 'addphonenumber'){
		has_more($record->{'varid'},$record->{'varvalue'});
		}
	else {
		set_reading($record->{'varid'},$record->{'varvalue'});
  		}
	}
}

#sub
#SpeedportOverview_function {
#my $json_text = `node $l33tport_path -o json -f Overview`;
#my $records = decode_json($json_text);
##Log 1, Dumper ($records);
#for my $record (@$records) {
#	if ($record->{'varid'} eq 'addipnumber' || $record->{'varid'} eq 'addmdevice' || $record->{'varid'} eq 'addphonenumber'){
#		has_more($record->{'varid'},$record->{'varvalue'});
#		}
#	else {	
#		set_reading($record->{'varid'},$record->{'varvalue'});
#  		}
#	}
#}

sub
SpeedportLan_function {
my $json_text = `node $l33tport_path -o json -f lan`;
my $records = decode_json($json_text);
#Log 1, Dumper($records);
for my $record (@$records) {
	if ($record->{'varid'} eq 'addmdevice'){
		has_more($record->{'varid'},$record->{'varvalue'});
		}
	else {
		set_reading($record->{'varid'},$record->{'varvalue'});
		}
  	}
}

sub
has_more($$) {
my ($prefix,$data) = @_ ;
my $i = "";
for my $key (@$data) {
	if ($key->{'varid'} =~ 'id'){
		$i = $key->{'varvalue'};
		}
	if ($key->{'varvalue'}){	
		fhem("setreading $dummy_device " . $prefix . "_id_" . $i ."_$key->{'varid'} $key->{'varvalue'}");
		}
    }
}

sub
set_reading($$){
my ($r_name,$r_value) = @_;
if ($r_value){
	fhem("setreading $dummy_device $r_name $r_value");
	}
}

sub
SpeedportLTE_function {
my $json_text =  `node $l33tport_path -o json -f lteinfo`;
my $data = decode_json($json_text);
my %f = %{$data} ;
foreach my $key (keys(%f)) {
	if ($f{$key}){
		fhem("setreading $dummy_device $key $f{$key}");
		}
    }
}



1;

