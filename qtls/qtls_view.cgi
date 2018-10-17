#!/usr/bin/perl

#---------------------------------------------
#    
#    id = RGD_id
#    ot = Object_Type
#    fm = Display Foramt
#           html, xml, csv
#   
#   Purpose: forward qtls_view.cgi to qtlReport.jsp
#   Author:  Lan Zhao
#   Date:    3/22/04
#   Modified date: 04/19/04 to fit QTLS view
#
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
#my $ot   = $cgi->param('ot') || 'db'; # Object_Type
#my $fmt  = $cgi->param('fmt');   # display format, plain text, XML, HTML

my $keyword;
if($id){
   $keyword = $id;
 }elsif($kw){
   $keyword = $kw;
 }

# to customize the title, version and tool_dir
my $rgd = RGD::HTML->new();
my $baseURL=$rgd->get_baseURL;   # http://rgd. mcw.edu

print "Status: 302 Moved Temporarily\r\n" .
      "Location: $baseURL/objectSearch/qtlReport.jsp?rgd_id=$keyword\r\n" .
      "\r\n";

 
exit;


