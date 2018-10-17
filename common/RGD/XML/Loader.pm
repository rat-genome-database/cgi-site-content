#!/usr/bin/perl

# ----------------------------------------------
#
# RGD::XML::Loader.pm 
#
# Module for loading standard RGD XML code into RGD
#
# ----------------------------------------------

#############################################
#
# Bug Fixes and additions
#
#############################################
#
# 030601 - Added in regex to remove [pubmed comments] in square brackets
#

package RGD::XML::Loader;

use lib "/rgd/tools/common";
use strict;
use RGD::_Initializable;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use XML::DOM;
use RGD::XML::Simple;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw();
@RGD::XML::Loader::ISA = qw ( RGD::_Initializable );

$VERSION = '1.0';

my $DEBUG = 0; # Set to 0 to avoid error messages


sub _init {

  my ($self, %args) = @_;
  # print "Init called!\n";
  $self->{_doc_ref}         = $args{doc_ref};
  $self->{contents}         = (); # anonymous hash to hold the list of contents from the file
  $self->{_db} = $args{db_ref};

  # the list of data to get from RGD for a given object type
  $self->{objects} = {
		      qtl => ['sslp','gene'],
		     };

  # read in the contents of the file
  # $self->check_contents;
  # Get basic info from RGD based on the contents
  # $self->get_object_data_from_rgd;

  # print keys %{$self->{contents}};

}


sub get_contents {

  my $self = shift @_;
  return keys %{$self->{contents}};

}



###########################
#
# check_contents - examines the XML file and reads in the contents so we know
# what info to read in from the database to check this data
#
###########################


sub check_contents {

  my $self = shift @_;
  
  my $contents_node_list = ${ $self->{_doc_ref}}->getElementsByTagName("contents");

my $object_list = $contents_node_list->item(0)->getElementsByTagName("object");

# Now loop through the object elements reading in their contents
for my $object_num (0 .. ($object_list->getLength)-1) {
  
  my $object = $object_list->item($object_num)->getAttribute("type");
  # print "Found Object type: $object\n";
  $self->{contents}{$object} = 1;
}
}





################################################
# 
# create_reference_entry - creates the reference entry in the database
#
################################################


sub create_reference_entry {

  # Have to break apart the Reference entry into more manageable data
  # to allow it to be entered into the database fields

  # Need to create PMID XDB entry for the reference - need a new function for this


  # Need a hash of attributes plus an array of authors and a hash of XDB ids
  # Do this using XML::Simple.pm

  # &debug("Parsing XML reference using Simple.pm\n");

  my ($self,$refref) = @_;

  my $xml = $$refref->toString;

  my $simple = XML::Simple->new;

  my $ref_hash = $simple->XMLin(
				$xml,
				suppressempty => '',
				forcearray => ['author','xdb_entry']			
			       );

  # Need to create the new RGD_ID for the reference object
  
  my $new_rgd_id =  $self->create_new_rgd_id(12); # Object type 12, Reference
  my $new_ref_key = ${$self->{_db}}->generate_Key('ref_key','REFERENCES'); 


  # warn "Generating keys: $new_rgd_id and $new_ref_key\n";

  my $sql = <<"_EOSQL_";
insert into references
(
 rgd_id,
 ref_key,
 reference_type,
 title,
 abstract,
 publication,
 volume,
 issue,
 pages,
 pub_status,
 pub_date,
 doi,
 citation,
 editors,
 publisher,
 publisher_city,
 url_web_reference,
 notes
)
values (?,?,?,?,?,?,?,?,?,?,TO_DATE(?,'YYYY'),?,?,?,?,?,?,?)

_EOSQL_
  
  warn "here is refHash:\t $ref_hash->{doi}\n";
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

$sth->execute($new_rgd_id,
	      $new_ref_key,
	      $ref_hash->{type},
	      $ref_hash->{title},
	      $ref_hash->{abstract},
	      $ref_hash->{publication_data}->{publication},
	      $ref_hash->{publication_data}->{volume},
	      $ref_hash->{publication_data}->{issue},
	      $ref_hash->{publication_data}->{pages},
	      $ref_hash->{publication_data}->{status},
	      $ref_hash->{publication_data}->{pub_date},
		  $ref_hash->{publication_data}->{doi},
	      $ref_hash->{citation},
	      $ref_hash->{editors},
	      $ref_hash->{publisher},
	      $ref_hash->{publisher_city},
	      $ref_hash->{url_web_reference},
	      $ref_hash->{notes}
		  
	     )
  or die "Can't execute statement: $DBI::errstr"; # return $DBI::errstr;  # if update failed, return false

$sth->finish;

####
#
# Need to update reference's RGD_ID here based on the $new_rgd_id loaded
#
####

$$refref->setAttribute("rgd_id",$new_rgd_id);


####
# Now need to update the author list
# Is it Faster to delete author entries
# from the rgd_ref_author table and reconstruct?

my @authors = @{$ref_hash->{author_list}->{author}};
my @author_info = ();


for (my $a = 0; $a <= $#authors; $a++) {
  # rgd_id of reference, author first and last names, author order number, 
  
  $author_info[$a] = {
		      firstname => $authors[$a]->{firstname},
		      lastname => $authors[$a]->{lastname},
		     };

}

$self->load_authors($new_rgd_id,$new_ref_key,\@author_info, "LOAD");

# Need a load_xdb_link routine here
warn "Looking for XDB links\n";

if($ref_hash->{xdb_data}->{xdb_entry}) {

  my @xdbs = @{$ref_hash->{xdb_data}->{xdb_entry}};
  
  
  
  for (my $x = 0; $x <= $#xdbs; $x++) {
    warn "Found..xdb $xdbs[$x]->{database}->{content}\n";
    
    if($xdbs[$x]->{database}->{content} =~ /pubmed/i) {
      warn "Found PubMed entry for reference, trying to load\n";
      $self->load_xdb_entry(
			    database => "PubMed",
			    link_text => $ref_hash->{citation},
			    acc_id => $xdbs[$x]->{accession},
			    rgd_id => $new_rgd_id,
			   );
      
    }
=hold #DP disable creating a medline acc_id 9-22-03 (NCBI is discontinuing Medline)
    elsif($xdbs[$x]->{database}->{content} =~ /medline/i) {
      warn "Found Medline entry for reference, trying to load\n";
      $self->load_xdb_entry(
			    database => "Medline",
			    link_text => $ref_hash->{citation},
			    acc_id => $xdbs[$x]->{accession},
			    rgd_id => $new_rgd_id,
			   );
      
    }
=cut
    # Ignore other types of XDB links from a reference for the moment - Medline for example.
    
  }
  
}

return "$new_rgd_id,$new_ref_key"; # Loading worked OK, return new_Rgd_id

}


################################################
# 
# laod_xdb_entry - Loads the xdb information for a new xdb link.
#
################################################


sub load_xdb_entry {

  my ($self, %args) = @_;

  warn "Loading $args{database} $args{link_text}\n";

  my %xdb_types = $self->get_xdb_types;
  my $xdb_key = $xdb_types{$args{database}} || die "Cant match the supplied XDB type with one in RGD\n";
  my $acc_xdb_key = ${$self->{_db}}->generate_Key('acc_xdb_key','RGD_ACC_XDB');
  
  # Should really check to see if this xdb is already in the table linked to a different object

  my $sql = "insert into rgd_acc_xdb (acc_xdb_key, rgd_id,xdb_key,acc_id,creation_date,link_text) values (?,?,?,?,SYSDATE,?)";

my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't prepare statement: $DBI::errstr";

warn "inserting $args{rgd_id}, $xdb_key, $args{acc_id}, $args{link_text}\n";

$args{acc_id} =~ s/^0+//; # Strip off leading zeros

$sth->execute(
	      $acc_xdb_key,
		  $args{rgd_id},
	      $xdb_key,
	      $args{acc_id},
	      $args{link_text}
	     ) or die "Can't execute statement: $DBI::errstr";

return 1;

}



##################
#
# get_xdb_types - retrieve the XDB type data to link type key with the name of the database link
#
##################

sub get_xdb_types {

  my $self = shift @_;

  my $sql = "select xdb_key,xdb_name from rgd_xdb";
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql);
  
  $sth->execute();
  
  my %result = ();

  while( my($type,$name) = $sth->fetchrow_array) {
    $result{$name} = "$type";
  }

  return %result;

} # end get_xdb_types




################################################
# 
# laod_authors - Loads the author information for a new reference.
#
################################################


sub load_authors {

  my ($self, $rgd_id, $ref_key, $auth_ref, $action) = @_;

  # Foreach author, have to check that he (or She, Loretta) isnt already in RGD AUTHORS table
  # If they are already in, insert entry into RGD_REF_AUTHOR using existing author_key
  # if the are new, create new author table entry and insert into RGD_REF_AUTHOR

  my %authors = (); # hash to hold the author list and attributes grabbed from RGD

  if($action eq "UPDATE") {
    # if we are updating the authors for a reference, delete any existing
    # entries in the RGD_REF_AUTHOR table so they can be entered afresh.
    $self->delete_author_ref_associations($ref_key);
  }

  for (my $auth_num = 0; $auth_num <= $#{$auth_ref}; $auth_num++) {
    
    $authors{$auth_num}{fname} = $auth_ref->[$auth_num]->{firstname};
    $authors{$auth_num}{lname} = $auth_ref->[$auth_num]->{lastname};
    $authors{$auth_num}{auth_key} = $self->get_author_key(
							  $authors{$auth_num}{fname},
							  $authors{$auth_num}{lname}
							 ) || 
							   $self->create_author(
										"\U$authors{$auth_num}{fname}",
										"\u$authors{$auth_num}{lname}"
									       );
    
    warn "Found .$authors{$auth_num}{fname}.$authors{$auth_num}{lname}. = $authors{$auth_num}{auth_key}.";
    
    $self->link_authors_to_ref( ($auth_num+1), $ref_key, $authors{$auth_num}{auth_key}) unless !$authors{$auth_num}{auth_key}
    
  }



} # end of load authors


################################################
# 
# create_author - Creates a new author
#
################################################

sub create_author {

  my ($self,$fname, $lname) = @_;

  # need a new author key
  my $auth_key = ${$self->{_db}}->generate_Key('author_key','AUTHORS'); 

  my $sql = "insert into authors (author_key, author_lname, author_fname) values (?,?,?)";
  
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't prepare statement: $DBI::errstr";

$sth->execute($auth_key, $lname, $fname ) or die "Can't execute statement: $DBI::errstr";

warn "Creating new author entry: $fname $lname, key: $auth_key\n";

return $auth_key;

}


################################################
# 
# link_authors_to_ref - Fills in the rgd_ref_author table to link the authors to the reference
#
################################################

sub link_authors_to_ref {

  my ($self, $auth_order, $ref_key, $auth_key) = @_;


my $sql = "insert into rgd_ref_author (author_key, author_order, ref_key) values (?,?,?)";
  warn "Linking $auth_key with ref $ref_key, order: $auth_order";
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't prepare statement: $DBI::errstr";

$sth->execute($auth_key, $auth_order, $ref_key ) or die "Can't execute statement: $DBI::errstr";
warn "...doner\n";
return 1;

} # end of link_authors_to_ref




################################################
# 
# delete_author_ref_associations  - Deletes entries in rgd_ref_author for
# a given ref_key
#
################################################

sub delete_author_ref_associations {

  my ($self, $ref_key) = @_;

  my $sql = "delete from rgd_ref_author where ref_key = ?";
  
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or return 0;

warn "Deleting existing author ref associations for ref_key $ref_key\n";
  $sth->execute($ref_key) or return 0;

return 1;

} # end of delete_author_ref_associations


################################################
# 
# get_author_key  - Gets author key for a given first and lastname
#
################################################

sub get_author_key {

  my ($self, $fname, $lname) = @_;

  # Do a lowercase match against the author_lc_view table
  $fname =~ tr/A-Z/a-z/;
  $lname =~ tr/A-Z/a-z/;
  
  #my $sql = " select author_key from author_lc_view where author_name_lc = ?";
  
  # 1/14/02 sql changed to fix bug checking against author_lc_view table
  my $sql = " select author_key from author_lc_view where author_lname_lc = ? and author_fname_lc = ?";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or return 0;

# 1/14/02 execute statement changed to reflect altered SQL statement (above)
# make sure to compare to whole name (last_first) for author key
$sth->execute($lname,$fname ) or return 0;
  
  my @hits = ();
  
  while( my $a_key = $sth->fetchrow_array() ) {
    push @hits, $a_key;
    warn "Author hit with $fname, .$lname. : $a_key\n";
  }
  
  $sth->finish();
  
  if(@hits && !$hits[1]) {
    return $hits[0];
  }
  else {
    return undef;
  }
  
}



################################################
# 
# update_reference_entry - updates the reference entry in the database
#
################################################


sub update_reference_entry {

  # Have to break apart the Reference entry into more manageable data
  # to allow it to be entered into the database fields

  # Need a hash of attributes plus an array of authors and a hash of XDB ids
  # Do this using XML::Simple.pm

  &debug("Parsing XML reference using Simple.pm\n");

  my ($self,$refref) = @_;

  my $xml = $$refref->toString;

  my $simple = XML::Simple->new;

  my $ref_hash = $simple->XMLin(
				$xml,
				suppressempty => '',
				forcearray => ['author'],
			       );

  my $sql = <<"_EOSQL_";
update references
set
reference_type = ?,
 title = ?,
 abstract = ?,
 publication = ?,
 volume = ?,
 issue = ?,
 pages = ?,
 pub_status = ?,
 pub_date = TO_DATE(?,'YYYY'),
 citation = ?,
 editors = ?,
 publisher = ?,
 publisher_city = ?,
 url_web_reference = ?,
 notes = ?
where rgd_id = ?

_EOSQL_
  
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";


my $type = $ref_hash->{type}; # "DIRECT DATA TRANSFER";
my $citation = $ref_hash->{citation};
my $pages = $ref_hash->{publication_data}->{pages};
my $volume = $ref_hash->{publication_data}->{volume};
my $issue = $ref_hash->{publication_data}->{issue};
my $publication = $ref_hash->{publication_data}->{publication};
my $pub_date = $ref_hash->{publication_data}->{pub_date};
my $abstract = $ref_hash->{abstract};
my $url_web_reference = $ref_hash->{url_web_reference};
my $rgd_id = $ref_hash->{rgd_id};

# warn "Pub_date: $pub_date, $ref_hash->{publication_data}->{volume}\n";

$sth->execute($ref_hash->{type},
	      $ref_hash->{title},
	      $ref_hash->{abstract},
	      $ref_hash->{publication_data}->{publication},
	      $ref_hash->{publication_data}->{volume},
	      $ref_hash->{publication_data}->{issue},
	      $ref_hash->{publication_data}->{pages},
	      $ref_hash->{publication_data}->{status},
	      $ref_hash->{publication_data}->{pub_date},
	      $ref_hash->{citation},
	      $ref_hash->{editors},
	      $ref_hash->{publisher},
	      $ref_hash->{publisher_city},
	      $ref_hash->{url_web_reference},
	      $ref_hash->{notes},
	      $ref_hash->{rgd_id}
	     )
  or return $DBI::errstr;  # if update failed, return false

$sth->finish;

# Now need to update the author list
# Is it Faster to delete author entries
# from the rgd_ref_author table and reconstruct?

my @authors = @{$ref_hash->{author_list}->{author}};
my @author_info = ();


for (my $a = 0; $a <= $#authors; $a++) {
  # rgd_id of reference, author first and last names, author order number, 
  
  $author_info[$a] = {
		      firstname => $authors[$a]->{firstname},
		      lastname => $authors[$a]->{lastname},
		     };

}

$self->load_authors($ref_hash->{rgd_id}, $ref_hash->{ref_key}, \@author_info, "UPDATE");

return 1; # Updating worked OK, return true

}



############
# 
# Output an debug message if debugging messages are turned on
#
############

sub debug {
  my $message = shift @_;
  my $date = scalar localtime();

  if ($DEBUG) {
    print "$message";
  }

}



sub create_new_rgd_id {


  my ($self,$obj_type) = @_;

  my $new_rgd_id = ${$self->{_db}}->generate_Key('rgd_id','RGD_IDS'); 

  my $sql = "insert into RGD_IDS (RGD_ID, OBJECT_KEY, CREATED_DATE,LAST_MODIFIED_DATE) values (?,?,SYSDATE,SYSDATE)";
  
  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or return 0;
  
  $sth->execute($new_rgd_id, $obj_type) or return 0;
  $sth->finish();
  return $new_rgd_id;
  
}


1;  # RETURN 1 AT THE END OF THE MODULE'S CODE SECTION

__END__


=head1 NAME:  RGD::XML::Loader.pm

RGD XML Writer Module

=head1 SYNOPSIS:

=head1 CHANGES:

=head1 USAGE:

=head2 CONSTRUCTOR:

=head2 ACCESSORS:



=head1 CONTACT: 
  

Contact Simon Twigger (simont@mcw.edu) for bug reports or if you need any additions or modifications.

 
Copyright (c) 2000, Bioinformatics Research Center, 
Medical College of Wisconsin.
