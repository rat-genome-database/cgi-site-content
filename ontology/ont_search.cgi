#!/usr/bin/perl

use strict;

# perl modules
use CGI;
my $hostname = $ENV{SERVER_NAME};

my $cgi = CGI::new();
my $search_string = $cgi->param('search_string');

#Redirecting with status 301 - Pushkala Jayaraman 8th December 2011
my $url2 = "http://$hostname/rgdweb/ontology/search.html?term=$search_string";
print $cgi->header(-location => $url2, -status => 301);
exit;


