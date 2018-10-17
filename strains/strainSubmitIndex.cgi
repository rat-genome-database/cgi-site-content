#!/usr/bin/perl

#####################################################################################
# File Name:	strainSubmitIndex.cgi												#
# Usage:		this script calls the contactInput.shtml to display the	contact		#
#				data input form														#
# Author:		Henry Fan															#
# Date:			05/21/2003															#
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;
use strict;

my $html = RGD::HTML->new();

my $WWW_path=$html->get_wwwPATH; 

my $shtml_file="$WWW_path/strains/strainContactInput.shtml";

$html->html_head;
$html->tool_start;

open (DISPLAY,"$shtml_file")|| die "can not open the file:$!\n";

	while(<DISPLAY>){
		print $_;	
	}

close(DISPLAY);
 
$html->tool_end;
$html->html_foot;

############################################################### end script ##################################################################