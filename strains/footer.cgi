#!/usr/bin/perl

#####################################################################################
#test
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;

my $html = RGD::HTML->new();


#$html->html_head;
#$html->tool_start;

print "i am cgi file<br>";
#$html->tool_end;
$html->html_foot;

############################################################### end script ##################################################################