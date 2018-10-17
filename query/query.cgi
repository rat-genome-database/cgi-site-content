#!/usr/bin/perl -w

#---------------------------------------------
#    
#    id = RGD_id
#    kw = keyword
#   
#   Purpose: redirection of legacy queries to rgdweb
#
#---------------------------------------------
use lib '/rgd/tools/common';
use RGD::HTML;
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
      "Location: $baseURL/rgdweb/search/search.html?term=$keyword\r\n" .
      "\r\n";
 
exit;
