#!/usr/bin/perl

##############################
#
# strain_form.cgi Simon Twigger May 2000
#
# Gets the strain symbols and associated RGD Ids from the Strains
# table for the simple form listing 
#
##############################

use lib "/rgd/TOOLS/common";
use RGD::DB;
use CGI qw(:standard);


my $db = RGD::DB::Refs->new();

# $db->connect();

my %ref_list = ();
my %ref_data = ();

my @rgd_ids = (10000,10001);

$db->get_rgd_id_refs(\%ref_list, \%ref_data, @rgd_ids);

for (my $ids = 0; $ids <= $#rgd_ids; $ids++) {
  
  print "ID# $rgd_ids[$ids] has refs: $ref_list{$rgd_ids[$ids]}\n";

  my @refs = split /,/,$ref_list{$rgd_ids[$ids]};

  foreach my $ref_key (@refs) {

    foreach my $field (keys %{$ref_data{$ref_key}}) {

      print "$field:\t$ref_data{$ref_key}{$field} \n";
    }
  }

}

__END__
