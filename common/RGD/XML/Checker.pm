#!/usr/bin/perl

# ----------------------------------------------
#
# RGD::XML::Checker.pm 
#
# Module for comparing standard RGD XML code against RGD
#
# ----------------------------------------------

#############################################
#
# Bug Fixes and additions
#
#############################################
#
# 030601 - Fixed date comparison with RGD, needed TO_CHAR(att,'YYYY') = "date_string"
#
#
#
#
#############################################

package RGD::XML::Checker;

use strict;
use RGD::_Initializable;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use XML::DOM;
use Data::Dumper;

# open (LOG, ">>ref_load_errors.log") or die "Cant open ref_load_errors.log: $!";


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.  20
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw();
@RGD::XML::Checker::ISA = qw ( RGD::_Initializable );

$VERSION = '1.0';



###########################
#
# init - initializing function from RGD::_Initializable
#
###########################

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
  $self->check_contents;
  # Get basic info from RGD based on the contents
  $self->get_object_data_from_rgd;

  # print keys %{$self->{contents}};
  open (LOG, ">>ref_load_errors.log") or die "Cant open ref_load_errors.log: $!";
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


###########################
#
# get_object_data_from_rgd
#
###########################


sub get_object_data_from_rgd {

  my $self = shift @_;

  if ($self->{contents}{qtl}) {
    $self->get_sslp_info_from_rgd;
    $self->get_sslp_alias_info_from_rgd;
    $self->get_gene_info_from_rgd;
    $self->get_gene_alias_info_from_rgd;
    $self->get_strain_info_from_rgd;
  }
  if ($self->{contents}{reference}) {
    # print '@@NB@@ Need to get appropriate info in Checker.pm\n';

    # $self->get_ref_info_from_rgd;
  }


}

###########################
#
# get_ref_info_from_rgd
#
###########################


sub get_ref_info_from_rgd {

  my $self = shift @_;

  my $sql = "select r.rgd_id,r.ref_key,r.volume,r.pages,r.year,r.url_web_reference,a.author_key from references r, rgd_ref_author a where a.ref_key = r.ref_key and a.author_order = 1";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

  $sth->execute or die "Can't execute statement: $DBI::errstr";
  while ( my @results = $sth->fetchrow_array() ) {
    $self->{refs}{$results[0]} = {
				  ref_key => $results[1],
				  volume => $results[2],
				  pages => $results[3],
				  year => $results[4],
				  url_web_reference => $results[5],
				  author_key => $results[6],
				  
				 };
  }
  $sth->finish;
}



###########################
#
# get_sslp_info_from_rgd
#
###########################


sub get_sslp_info_from_rgd {

  my $self = shift @_;

  my $sql = "select s.rgd_name_lc,r.rgd_id from sslps s, rgd_ids r where s.rgd_id = r.rgd_id and object_key = 3";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

  $sth->execute or die "Can't execute statement: $DBI::errstr";
  while ( my ($symbol, $rgd_id) = $sth->fetchrow_array() ) {
    $self->{sslps}{$symbol} = $rgd_id;
  }
  $sth->finish;
}

###########################
#
# get_gene_info_from_rgd
#
###########################


sub get_gene_info_from_rgd {

  my $self = shift @_;

  my $sql = "select g.gene_symbol_lc,r.rgd_id from genes g, rgd_ids r where g.rgd_id = r.rgd_id and r.object_key = 1";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

  $sth->execute or die "Can't execute statement: $DBI::errstr";
  while ( my ($symbol, $rgd_id) = $sth->fetchrow_array() ) {
    $self->{genes}{$symbol} = $rgd_id;
  }
  $sth->finish;
}

###########################
#
# get_alias_info_from_rgd
#
###########################


sub get_gene_alias_info_from_rgd {

  my $self = shift @_;

  my $sql = "select a.alias_value_lc,r.rgd_id from aliases a, rgd_ids r where a.rgd_id = r.rgd_id and r.object_key = 1";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

  $sth->execute or die "Can't execute statement: $DBI::errstr";
  while ( my ($symbol, $rgd_id) = $sth->fetchrow_array() ) {

    if($self->{genes}{$symbol}) {
      # print "Alias $symbol (RGD:$rgd_id) also in genes table with RGDID: $self->{genes}{$symbol}\n";
    }

    # print "$symbol is a gene alias for $rgd_id\n";

    $self->{alias}{$symbol} = $rgd_id;
    $self->{rgd_id}{"RGD:$rgd_id"} = {type => ["alias"],};
  }
  $sth->finish;
}

###########################
#
# get_sslp_alias_info_from_rgd
#
###########################


sub get_sslp_alias_info_from_rgd {

  my $self = shift @_;

  my $sql = "select a.alias_value_lc,r.rgd_id from aliases a, rgd_ids r where a.rgd_id = r.rgd_id and object_key = 3";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

  $sth->execute or die "Can't execute statement: $DBI::errstr";
SSLP:
  while ( my ($symbol, $rgd_id) = $sth->fetchrow_array() ) {

    if(!$symbol) {
      # print "Alias without symbol attached to SSLP object RGD:$rgd_id\n";
      next SSLP;
    }

    if($self->{sslps}{$symbol}) {
      # print "Alias $symbol also in sslps table, RGDID: $self->{sslps}{$symbol}\n";
    }
    
    $self->{alias}{$symbol} = $rgd_id;
    $self->{rgd_id}{"RGD:$rgd_id"} = {type => ["alias"],};
  }
  $sth->finish;
}


###########################
#
# get_strain_info_from_rgd
#
###########################


sub get_strain_info_from_rgd {

  my $self = shift @_;

  my $sql = "select s.strain_symbol_lc, r.rgd_id from strains s, rgd_ids r where s.rgd_id = r.rgd_id and object_key = 5";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";

  $sth->execute or die "Can't execute statement: $DBI::errstr";
  while ( my ($symbol, $rgd_id) = $sth->fetchrow_array() ) {
    $self->{strains}{$symbol} = $rgd_id;
  }
  $sth->finish;
}


#$VAR1 = {
#          'creation_date' => 'Wed Nov 15 16:18:16 2000',
#          'script_version' => '1.0',
#          'type' => 'references',
#          'script_name' => 'ref_edit.cgi',
#          'contents' => {
#                          'object' => {
#                                        'type' => 'reference'
#                                      }
#                        },
#          'reference' => {
#                           'rgd_id' => '0',
#                           'type' => 'BOOK',
#                           'citation' => '',
#                           'publication_data' => {
#                                                   'pages' => '',
#                                                   'volume' => '',
#                                                   'issue' => '',
#                                                   'publication' => '',
#                                                   'pub_date' => ''
#                                                 },
#                           'abstract' => 'this is a load of text',
#                           'url_web_reference' => '',
#                           'author_list' => {
#                                              'author' => {
#                                                            'firstname' => 'we',
#                                                            'lastname' => 'blah'
#                                                          }
#                                            },
#                           'action' => 'update'
#                         }
#        };


###########################
#
# check_reference - pass in the ref_element from the XML doc
#
###########################

sub check_reference {

  my ($self,$ref_ref) = @_;


  # For this reference we have to check if exists already in RGD
  # convert to a more perl friendly format for analysis
  my $xml = $$ref_ref->toString;

  my $simple = XML::Simple->new;

  my $ref_hash = $simple->XMLin(
				$xml,
				suppressempty => '',
				forcearray => ['author']
			       );
	
  warn "checking to see what ref_hash has\n";

  use Data::Dumper;  
  warn "here is the accession:$ref_hash->{xdb_data}->{xdb_entry}[0]->{accession}\n";
  
  my @matching_refs = ();
  my @matching_rgdIds = ();
  
  # First test just checks no other ref with same first author, publication, volume, pages, pub_date(year)
  
  
  push(@matching_rgdIds, &comp_pubmed_to_rgd($self, 
						$ref_hash->{xdb_data}->{xdb_entry}->[0]->{accession},
						)
	);


   warn "heres a bunch of matching rgdids:\t".$matching_rgdIds[0]." and here is the rest!!!";
  
  push (@matching_refs,&comp_reftext_to_rgd($self,
					    $ref_hash->{author_list}->{author}->[0]->{lastname} . '_' . $ref_hash->{author_list}->{author}->[0]->{firstname},
					    $ref_hash->{publication_data}->{publication} || 'NULL',
					    $ref_hash->{publication_data}->{volume} || 'NULL',
					    $ref_hash->{publication_data}->{pages} || 'NULL',
					    $ref_hash->{publication_data}->{pub_date} || 'NULL',
					    $ref_hash->{url_web_reference} || 'NULL',
					   )
       );
	   
	   
  # Could add in new Reference identity tests here, perhaps checking PMID doesnt 
  # already exist in db linked to existing object


  # use Data::Dumper;
  # die Dumper($ref_hash);

  if(!@matching_rgdIds) {
    return 0;
  }
  elsif($matching_rgdIds[0] ne "") {
    return "@matching_rgdIds\n";
  }
  elsif($matching_refs[0] ne ""){
    return "@matching_refs\n";
  }

}


###########################
#
# comp_reftext_to_rgd
#
###########################

sub comp_pubmed_to_rgd {

	my($self, $pubmedId) = @_;
	
	print LOG "checking to see if PMID exists in RGD_ACC_XDB table";
	
	my $sql = <<"__eosql__";
select x.RGD_ID from RGD_ACC_XDB x, REFERENCES f, RGD_IDS r 
where x.ACC_ID = ? 
and x.RGD_ID=f.RGD_ID
and x.RGD_ID=r.RGD_ID
and r.OBJECT_STATUS='ACTIVE'
and x.XDB_KEY = 2
__eosql__

	#sql
	my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't prepare statement: $DBI::errstr";

	my @results = ();

	$sth->execute($pubmedId) or die "Can't execute statement: $DBI::errstr";

warn "retrieving results..";

while((my $rgdId)= $sth->fetchrow_array()){
	warn "here is the RGDIDs:\t$rgdId\n";
	push @results, $rgdId;	
}

	$sth->finish;

return @results;

}

sub comp_reftext_to_rgd {

  # my ($self,$volume,$pages,$year,$url_web_reference) = @_;
  my ($self,$first_author,$publication,$volume,$pages,$year) = @_;

  print LOG  "Checking $first_author,$publication,$volume,$pages,$year, vs RGD \n";

  my $sql = <<"__eosql__";
select r.rgd_id, arv.author_name from references r, author_ref_view arv
where r.publication = ?
and r.volume = ?
and r.pages = ?
and TO_CHAR(r.pub_date,'YYYY') = ?
and arv.author_order = 1
and arv.ref_rgd_id = r.rgd_id
__eosql__
  
  # $sql = "select rgd_id from references where url_web_reference = ?";

  my $sth = ${$self->{_db}}->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  my @results = ();

$sth->execute($publication, $volume, $pages, $year) or die "Can't execute statement: $DBI::errstr";

# print LOG  "Retrieving results...\n";

while(my ($rgd_id,$author) = $sth->fetchrow_array() ) {
  $first_author =~ tr/A-Z/a-z/;
  $author =~ tr/A-Z/a-z/;
  $author =~ s/\s+$//g; # Remove any trailing whitespace..
  print LOG  "Found RGD:$rgd_id $author, matching to $first_author\n";
  if($author eq $first_author) {
    print LOG  "They are a match\n";
    push @results,$rgd_id;
  }
}

$sth->finish;


# Now we've retrieved

  return @results;
  
}


################################################

sub create_element {
  
  
  my ($self, %arg) =  @_;
  
  # print "Create element $arg{name}\n";
  
  my $el = ${$self->{_doc_ref}}->createElement($arg{name});
  
  if($arg{atts}) {
    foreach my $att (keys %{$arg{atts}} ) {
      $el->setAttribute($att,$arg{atts}->{$att});
    }
  }
  if($arg{text}) {
    my $el_text_node = ${$self->{_doc_ref}}->createTextNode($arg{text});
  $el->appendChild($el_text_node);
}

if ($arg{parent}) {
  ${ $arg{parent} }->appendChild($el);
}

return $el;

}


sub create_xdb_element {


  my %defaults  =  (
		    database_name => "RGD",
		    database_url => "http://rgd.mcw.edu",
		    accession => "RGD:0000",
		    link_text => "RGD Object",
		    report_url => "http://rgd.mcw.edu",
		   );


  my ($self,%arg) =  @_;
  
  my $xdb_el = $self->create_element(
			      name => "xdb_entry",
			     );
  
  my $datatbase_el = $self->create_element(
				    name => "database",
				    text => $arg{database_name},
				   atts => {
					    base_url => $arg{database_url},
					   },	  
				    parent => \$xdb_el,
				   );
  
  my $acc_el = $self->create_element(
			      name => "accession",
			      text => $arg{accession},
			      parent => \$xdb_el,
			     );
  
  
  my $link_text_el = $self->create_element(
				    name => "link_text",
				    text => $arg{link_text},
				    parent => \$xdb_el,
				   );
  
  my $report_url_el = $self->create_element(
				     name => "report_url",
				     text => $arg{report_url},
				     parent => \$xdb_el,
				    );
  
  return $xdb_el
    

}

sub add_curation_flag {

  my ($self, %arg) = @_;
  
  $self->create_element(
			name => $arg{severity},
			atts => {
				 element => $arg{element},
				},
			text => $arg{text},
			parent => \${ $arg{parent} },
 );


}


sub add_element_attribute {

  my ($self, $element_ref,$key, $value) = @_;

  $self->{_doc}->getDocumentElement->setAttribute($key, $value);

}






=head1 NAME:  RGD::XML::Writer.pm

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
