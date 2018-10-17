#!/usr/bin/perl

##############################
#
# strain_form.cgi Simon Twigger May 2000
#
# Gets the strain symbols and associated RGD Ids from the Strains
# table for the simple form listing 
#
##############################
use lib '/rgd/tools/common';
use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);


my $db = RGD::DB->new();
my $html = RGD::HTML->new();
my $baseURL=$html->get_baseURL; 
my $baseCGI=$html->get_baseCGI;

my %strains = ();

print "Content-type: text/html\n\n";
&get_strain_info; # access the db and get strain information

if (%strains) {
  print "<form action=\"$baseCGI/strains/strains_view.cgi\" method=\"POST\">";
  print "<select name=\"id\" size=\"5\">";
  
  foreach my $strain (sort keys %strains) {
    
    print "<option value=\"$strains{$strain}\">$strain\n";
    
  }
  
  print "</select>";

  print "<INPUT type=\"submit\" name=\"Submit\" value=\"View Strain\">";
  print "</form>";
  
}else {
  
  print <<"__end_of_HTML__";
  <h2>There has been an error in the excution of this script</h2>
    
__end_of_HTML__
      
  }

exit;

sub get_strain_info {

my $sql = "select s.rgd_id, s.strain_symbol from strains s, rgd_ids r where r.object_status = 'ACTIVE' and r.rgd_id = s.rgd_id order by strain_symbol";

my ($n,@results) = $db->query_Data(2,$sql);

for (my $rec = 0; $rec <= $#results; $rec++) {

  my ($key,$symbol) = split /::/, $results[$rec];
  $strains{$symbol} = $key;

}


}

sub get_strain_info2 {

 my $sql = "select s.strain_key, s.strain_symbol from strains s, rgd_ids r where r.object_status = 'ACTIVE' and r.rgd_id = s.rgd_id order by strain_symbol";

 my $sth = $db->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

 $sth->execute() or die "Can't execute statement: $DBI::errstr";

 my @rows = [];

 while ( @rows =  $sth->fetchrow_array() ) {

   my ($key,$symbol) = @rows;

   $strains{$symbol} = $key;

 }
}


__END__
