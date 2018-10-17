#!/usr/bin/perl

#####################################################################################
# File Name: qtlsResistrationIndex.cgi		
# Usage:		this script calls the qtlRegistrationInput.shtml to display 
#                  the data input form			
# Author:		Henry Fan, modified by Pete Bazeley 11/12/03
# Date:		04/16/2003			
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;
use strict;

my $html = RGD::HTML->new(
			 category => "submitdata"
			 );

my $WWW_path=$html->get_wwwPATH; 

my $shtml_file="$WWW_path/qtls/qtlRegistrationInput.shtml";

$html->html_head;
$html->tool_start;

open (DISPLAY,"$shtml_file")|| die "can not open the file:$!\n";

	while(<DISPLAY>){
		print $_;	
	}

close(DISPLAY);
 
$html->tool_end;
$html->html_foot;

