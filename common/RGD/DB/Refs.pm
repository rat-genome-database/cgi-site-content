#!/usr/bin/perl  -w

################################
#
# RGD::DB::Refs.pm - returns the Refs associated with a provided RGD ID
#
# Simon Twigger, RGD 2000
#
################################

package RGD::DB::Refs;

# use lib "/rgd/TOOLS/common/RGD/";
use strict;
use RGD::_Initializable;
use RGD::DB;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;

require Exporter;

@RGD::DB::Refs::ISA = qw( RGD::_Initializable RGD::DB );

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.  20
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw();

$VERSION = '1.0';

# Constructor is inherited from RGD::DB.pm

# call the parent class _init method to ensure everything
# is created as expected. See 'Object Oriented Perl, p 174'
sub _init {
  my($self, %args) = @_;

  $self->RGD::DB::_init(%args);

}

##########
#
# get_rgd_id_refs()
#
# Returns the references associated with the supplied RGD_ID(s)
# Requies two hash references:
# %{$reflist_ref} will be a hash of arrays, keyed on RDG ID with the returned
# ref_keys in the array
# %{$refdata_ref} will be a hash of hashes keyed on the ref_keys containing the reference
# data itself for further use
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
#
#
#
##########

sub get_rgd_id_refs {


  my ($self, $reflist_ref, $refdata_ref, @rgd_ids) = @_;

  # For each supplied RGD Id in the array, check to see if it has references

 RGD_ID_LOOP:
  for (my $ids = 0; $ids <= $#rgd_ids; $ids++) {

    # $self->get_ref_keys($rgd_ids[$ids]);

    $reflist_ref->{$rgd_ids[$ids]} = $self->get_ref_keys($rgd_ids[$ids]);  

  } # RGD_ID_LOOP

  foreach my $ref (keys %{ $self->{_all_ref_keys}} ) {

    my %data = $self->get_ref_data($ref);

    $refdata_ref->{$ref} = { %data};

  }


} # end of get_rgd_id_refs


##########
#
# get_citation_html
#
# returns the html code for the citations for a given RGD id
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
#
###########

sub get_citation_html {

  my ($self, $rgd_id) = @_;

  my @ref_keys = split ',', $self->get_ref_keys($rgd_id);
  my %refdata = ();

  my $citations = "";
  my $citation_count = 1;

  foreach my $ref (@ref_keys) {

    my %data = $self->get_ref_data($ref);

    $refdata{$ref} = { %data};

    $citations .= "<b>$citation_count:</b>$refdata{$ref}{citation}<br>";
    $citation_count++;
  }

  if($ref_keys[0]) {
    return $citations;
  }
  else {
    return "<p>No References were found associated with this object</p>\n";
  }
  


} # end of get_citation_html




##########
#
# get_ref_keys
#
# returns the ref_keys for a given RGD_ID
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
#
###########

sub get_ref_keys {

  my ($self, $rgd_id) =  @_;

  my $sql = "select ref_key from rgd_ref_rgd_id where rgd_id = ?";

  my $sth = $self->{dbh}->prepare($sql);

  $sth->execute($rgd_id) or die "$DBI::Errstr";

  my $results = "";

  # get the ref keys for this rgd_id and store them in the 
  # results array
  while( my ($ref_key) = $sth->fetchrow_array) {

   $results .= "$ref_key,";
   $self->{_all_ref_keys}{$ref_key} += 1; # master hash of all returned refs
  }

  return $results;

} # end of get_ref_keys


##########
#
# get_ref_data
#
# returns the ref_data for a give ref_key
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
#
###########

sub get_ref_data {

  my ($self, $ref_key) = @_;

  my $sql = "select citation, pub_date from references where ref_key = ?";

  my $sth = $self->{dbh}->prepare($sql);

  $sth->execute($ref_key);

  my @data = $sth->fetchrow_array;

  my %results = ();
  $results{citation} = $data[0];
  $results{pub_date} = $data[1];

  return %results;

}

1;

__END__
