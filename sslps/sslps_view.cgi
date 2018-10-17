#!/usr/bin/perl

#---------------------------------------------
#    id = RGD_id
#---------------------------------------------
use lib '/rgd/tools/common';

# RGD modules #
use RGD::HTML;

# perl modules
use strict;
use CGI;

my $cgi = CGI::new();

my $id   = $cgi->param('id');    # RGD_ID
my $kw   = $cgi->param('kw');    # searching key word

my $keyword;
if($id){
   $keyword = $id;
 }elsif($kw){
   $keyword = $kw;
 }

# to customize the title, version and tool_dir
my $rgd = RGD::HTML->new();
my $baseURL=$rgd->get_baseURL;   # http://rgd.mcw.edu

print "Status: 301 Moved Permanently\r\n" .
      "Location: $baseURL/rgdweb/report/marker/main.html?id=$keyword\r\n" .
      "\r\n";

 
exit;


