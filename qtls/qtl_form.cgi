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
use CGI qw(:standard);


my $db = RGD::DB->new();

my %qtls = ();
&get_qtl_info; # access the db and get qtl information

my %traits = ();

&get_traits_info(\%traits);

if (%qtls) {

  print "\n<select name=\"traits\" size=\"5\">\n";
  print "<option value=\"any\" selected>-- Any Trait --</option>\n";
  
  foreach my $t (sort keys %traits) {
    
    print "<option value=\"$traits{$t}\">$t</option>\n";
    
  }
  print "</select>\n";
  

}
else {
  
  print <<"__end_of_HTML__";
  <p> We are currently loading QTLs into the rat genome 
  database.  Please check back in the near future to use this search.</p>
    
__end_of_HTML__
      
  }

exit;


############
#
# get_qtl_info
#
############

sub get_qtl_info {

my $sql = "select rgd_id, qtl_symbol, qtl_name from qtls order by qtl_symbol";

my ($n,@results) = $db->query_Data(3,$sql);

for (my $rec = 0; $rec <= $#results; $rec++) {

  my ($key,$symbol, $name) = split /::/, $results[$rec];
  $qtls{"$symbol - $name"} = $key;

}


}

############
#
# get_traits_info
#
############

sub get_traits_info {

  my $traits_ref = shift @_;

  my $sql = "select trait_name from traits";
  
  my ($n,@results) = $db->query_Data(2,$sql);
  
  for (my $rec = 0; $rec <= $#results; $rec++) {

	my ($trait) = split /::/, $results[$rec];
    $traits_ref->{"$trait"} = $trait;

  }  
}



__END__
