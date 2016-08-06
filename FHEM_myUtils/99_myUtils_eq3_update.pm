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
myUtils_eq3_update_Initialize($$)
{
  my ($hash) = @_;
}

# Enter you functions below _this_ line.

sub eq3StateFormat() {
  my $name = "eq3";
 
  my $ret ="";
  my $lastCheck = ReadingsTimestamp($name,"MATCHED_READINGS","???");
  $ret .= '<div style="text-align:left">';   
  $ret .= 'last <a title="eq3-downloads" href="http://www.eq-3.de/downloads.html">homematic</a>-fw-check => '.$lastCheck;    
  $ret .= '<br><br>';    
  $ret .= '<pre>';   
  $ret .= "| device                  | model                   | old_fw | new_fw | release    |\n";  
  $ret .= "------------------------------------------------------------------------------------\n";  
  my $check = ReadingsVal($name,"newFwForDevices","???");    
  if($check eq "no fw-updates needed!") {        
    $ret .= '| '.$check.'                                                            |';     
  } else {         
    my @devices = split(',',$check);         
    foreach my $devStr (@devices) {
      my ($dev,$md,$ofw,$idx,$nfw,$date) = $devStr =~ m/^([^\s]+)\s\(([^\s]+)\s\|\sfw_(\d+\.\d+)\s=>\sfw(\d\d)_([\d\.]+)\s\|\s([^\)]+)\)$/;          
      my $link = ReadingsVal($name,"fw_link-".$idx,"???");           
      $ret .= '| ';          
      $ret .= '<a href="/fhem?detail='.$dev.'">';            
      $ret .= sprintf("%-23s",$dev);             
      $ret .= '</a>';            
      $ret .= " | ";             
      $ret .= '<b'.(($md eq "?")?' title="missing attribute model => set device in teach mode to receive missing data" style="color:yellow"':' style="color:lightgray"').'>';            
      $ret .= sprintf("%-23s",$md);          
      $ret .= '</b>';            
      $ret .= " | ";             
      $ret .= '<b'.(($ofw eq "0.0")?' title="missing attribute firmware => set device in teach mode to receive missing data" style="color:yellow"':' style="color:lightgray"').'>';              
      $ret .= sprintf("%6s",$ofw);           
      $ret .= '</b>';            
      $ret .= " | ";             
      $ret .= '<a title="eq3-firmware.tgz" href="'.$link.'">';           
      $ret .= '<b style="color:red">';           
      $ret .= sprintf("%6s",$nfw);           
      $ret .= '</b>';            
      $ret .= '</a>';            
      $ret .= " | ";             
      $ret .= sprintf("%-10s",$date);            
      $ret .= " |\n";        
    }   
  }  
  $ret .= '</pre>';  
  $ret .= '</div>';  
  return $ret;
}

1;
