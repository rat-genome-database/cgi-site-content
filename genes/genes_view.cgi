#!/usr/bin/perl -w
##############################
#
# genes_view.cgi Simon Twigger May 2000
#
# Displays the Gene report for a given Gene RGD ID
#
##############################
use CGI qw(:cgi); # use :cgi functions instead of :standard to avoid name conflict with LWP module
use strict;

my $VERSION = 1.1; # New version 1.1 9/8/00
my $form = new CGI;

my $page = "";
my $id      = $form->param('id')  || 2018; #die "No ID value was provided\n";

#################################################################
####redirecting to new Gene Report Pages: 08/05/2011 Pushkala ###
#################################################################
my $host = $form->server_name();
my $url2 = "http://$host/rgdweb/report/gene/main.html?id=$id";
print(redirect(-uri => $url2, -status => 301));

exit;
