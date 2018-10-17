#!/usr/bin/perl -w

##############################
#
# strain_view.cgi Simon Twigger May 2000
#
# Displays the Strain report for a given Strain ID
#
##############################
use lib '/rgd/tools/common';

use RGD::HTML;
use CGI qw(:standard);
use strict;

my $form = new CGI;

# Read in parameters
my $id      = $form->param('id')  || 61107; #die "No ID value was provided\n";
# remove any RGD: tag from the start of the ID
$id =~ s/RGD://;

my $host = $form->server_name();
my $url2 = "http://$host/rgdweb/report/strain/main.html?id=$id";
print(redirect(-uri => $url2, -status => 301));
exit;

__END__