#!/usr/bin/perl

#--------------------------------------------
#
#  reference_view.cgi
#
#  Author: Nathan Pedretti
#    Date: 05/19/2000
#
#--------------------------------------------
#
#################
# Bug fixes etc.
#################
#
# 6-03-01  Fixed author display and searches for surnames with spaces (eg Van Dokkum or St. Lezin);
#
#################

use lib '/rgd/tools/common';
use CGI;
use CGI qw(:standard);

my $cgi = CGI::new();

#----------------------------
#
#  Get all of the parameters
#
#----------------------------

my %form = (
	    action => $cgi->param('action') || 'none',
            id     => $cgi->param('id') || 'none',
            fm     => $cgi->param('fm') || 'html',
            start  => $cgi->param('start') || '1',
            maxnum => $cgi->param('maxnum') || '25',
            count  => $cgi->param('count') || '1',
            sessionid => $cgi->param('sessionid') || 'none',
            keywords => $cgi->param('keywords') || 'none',
	    author => $cgi->param('author') || 'none',
	    year => $cgi->param('year') || 'none',
	    initials =>  $cgi->param('initials') || 'none',
	    override => $cgi->param('override') || 'none',
	    order => $cgi->param('order') || 'year',
	   );


$form{keywords} =~ tr/A-Z/a-z/; # make them lowercase
$form{author} =~ tr/A-Z/a-z/; # make them lowercase

if($form{keywords} =~ /^RGD:(\d+)/i) {
  $form{id} = $1;
  $form{action} = "blah";
}
else {
  $form{id} =~ s/rgd://i;
}

#Redirecting page with status 301 - Pushkala Jayaraman 8th December 2011
my $url2 = "/rgdweb/report/reference/main.html?id=$form{id}";
print(redirect(-uri => $url2, -status => 301));
exit;


__END__
