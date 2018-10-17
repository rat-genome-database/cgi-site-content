#!/usr/bin/perl
use CGI qw(:standard);
use strict;

#redirect to new strain submission tool
my $form = new CGI;
my $host = $form->server_name();
my $url2 = "http://$host/rgdweb/models/strainSubmissionForm.html?new=true";
print(redirect(-uri => $url2, -status => 301));
exit;

__END__
