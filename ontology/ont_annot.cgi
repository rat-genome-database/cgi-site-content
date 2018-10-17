#!/usr/bin/perl

################################################################
## ont_annot.cgi to present reports on ontology terms         ##
##                                                            ##
################################################################

use strict;

# perl modules
use CGI;

####################################
## assemble data
####################################

my $cgi = CGI::new();
my $ont_id = $cgi->param('ont_id');
my $term = $cgi->param('term');
my $hostname = $ENV{SERVER_NAME};

#added to allow for lookup based on acc key instead of term key.  jd
if ($ont_id) {

	#Redirecting with status 301 - Pushkala Jayaraman 8th December 2011
	my $url2 = "http://$hostname/rgdweb/ontology/annot.html?acc_id=$ont_id";
	print $cgi->header(-location => $url2, -status => 301);
	exit;
}

#convert term name into term acc
if ($term) {
    
	#Redirecting with status 301 - Pushkala Jayaraman 8th December 2011
	my $db = RGD::DB->new();
    my $sql = "select TERM_ACC from ONT_TERMS where TERM=?";
    my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
    $sth->execute($term) or die "Can't execute statement: $DBI::errstr";
    my $stuff = $sth->fetchrow_array();
	
	my $url2 = "http://$hostname/rgdweb/ontology/annot.html?acc_id=$stuff";
	print $cgi->header(-location => $url2, -status => 301);
	exit;
}

#if we got here, the parameters could not be reasonably translated
# redirect to generic ontology search page

#Redirecting with status 301 - Pushkala Jayaraman 8th December 2011
my $url2 = "http://$hostname/rgdweb/ontology/search.html";
print $cgi->header(-location => $url2, -status => 301);
exit;

