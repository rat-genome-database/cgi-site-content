#!/usr/bin/perl  -w

# ----------------------------------------------
#
# RGD::DB.pm 
#
# Module for writing standard RGD XML code for data files
#
# ----------------------------------------------

package RGD::XML::Writer;

use strict;
use RGD::_Initializable;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use XML::DOM;


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.  20
# Do not simply export all your public functions/methods/constants.

@EXPORT = qw();
@RGD::XML::Writer::ISA = qw ( RGD::_Initializable );

$VERSION = '1.0';





sub _init {

  my ($self, %args) = @_;

  $self->{_doc_ref}         = $args{doc_ref};
}



#############################################
#
# create_element
#
#############################################

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



#############################################
#
# create_xdb_element
#
#############################################

sub create_xdb_element {


  my %defaults  =  (
		    database_name => "RGD",
		    database_url => "http://dev.rgd.mcw.edu",
		    accession => "RGD:0000",
		    link_text => "RGD Object",
		    report_url => "http://dev.rgd.mcw.edu",
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
  if ($arg{parent}) {
    ${ $arg{parent} }->appendChild($xdb_el);
}

return $xdb_el
  
}


sub create_reference_element {

  my %defaults  =  (
		    title => "RGD_reference",
		    editors => "",
		    publication => "",
		    volume => "",
		    issue => "",
		    pages => "none",
		    pub_status => "unpublished",
		    pub_date => "2000",
		    rgd_id => "0",
		    ref_key => "0",
		    notes => "",
		    reference_type => "JOURNAL ARTICLE",
		    citation => "Default Reference",
		    abstract => "",
		    publisher => "",
		    publisher_city => "",
		    url_web_reference => "",
		    job_key => "",
		   );
  
  
  my ($self,%arg) =  @_;
  
  my $ref_el = $self->create_element(
				     name => "reference",
				     atts => {
					      rgd_id => $arg{rgd_id},
					      ref_key => $arg{ref_key},
					      type => $arg{reference_type},
					      action => $arg{action} || "load",
					     }
				    );
  
  my $publication_el = $self->create_element(
					     name => "publication_data",
					     parent => \$ref_el,
					    );
  my $title_el = $self->create_element(
				     name => "title",
				     text => $arg{title},
				     parent => \$ref_el,
				    );
  
  my $pub_el = $self->create_element(
				     name => "publication",
				     text => $arg{publication},
				     parent => \$publication_el,
				    );
  my $volume_el = $self->create_element(
					name => "volume",
					text => $arg{volume},
					parent => \$publication_el,
				       );
  my $issue_el = $self->create_element(
				       name => "issue",
				       text => $arg{issue},
						 parent => \$publication_el,
				      );
  
  my $pages_el = $self->create_element(
				       name => "pages",
				       text => $arg{pages},
				       parent => \$publication_el,
				      );
  
  my $pubstatus_el = $self->create_element(
				       name => "pub_status",
				       text => $arg{pub_status},
				       parent => \$ref_el,
				      );

  my $pubdate_el =  $self->create_element(
					  name => "pub_date",
					  text => $arg{pub_date},
					  parent => \$publication_el,
					 );
  

  
  
  # add the publication data to the reference element
  $ref_el->appendChild($publication_el);
  
  my $abstract_el =  $self->create_element(
						     name => "abstract",
						     text => $arg{abstract},
						     parent => \$ref_el,
						    );
  
  my $citation_el =  $self->create_element(
						     name => "citation",
						     text => $arg{citation},
						     parent => \$ref_el,
						    );
  
  my $author_list_el = $self->create_element(
						name => "author_list",
						parent => \$ref_el,
					       );
  # deference an array reference
  my @authors = @{$arg{author_ref}};
  
  if(@authors) {
    
    # warn ">>> There are @{$arg{author_ref}} $#authors in the array\n\n";

    for my $author (0 .. $#authors) {
      
      # regex to pull out the initials from the surname for people with spaces in
      # their surname, eg. 'Van Etten W'. Assumes that the W is the first name initial
      # and everything else is the surname.


      $authors[$author] =~ s/\s+(\w+)\s*$//;

      my $firstname = $1;
      my $lastname = $authors[$author];
      $lastname =~ s/^\s+//; # remove any initial whitespace

      # my ($lastname,$firstname) = split '\s', $authors[$author];
      
      my $author_el = $self->create_element(
						      name => "author",
						      parent => \$author_list_el,
						     );
      
      $self->create_element(
				      name => "lastname",
				      text => $lastname,
				      parent => \$author_el,
				     );
      
      $self->create_element(
				      name => "firstname",
				      text => $firstname,
				      parent => \$author_el,		 
				     );
    } # end of author loop
    
  } # end of if @authors
  # add in the URL if it exists


  my $url_el = $self->create_element(
					       name   => "url_web_reference",
					       text   => $arg{url_web_reference},
					       parent => \$ref_el,
					      );

  if($arg{PMID}) {
    
    my $xdb_data_el = $self->create_element(
						      name   => "xdb_data",
						      parent => \$ref_el,
						     );
    
    $self->create_xdb_element(
					
					database_name => "PubMed",
					database_url  => "https://www.ncbi.nlm.nih.gov/PubMed/",
					accession => $arg{PMID},
					link_text => $arg{citation},
					report_url => "https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=",
					
					parent => \$xdb_data_el,
				       );
    
  }

my $editors_el =  $self->create_element(
					  name => "editors",
					  text => $arg{editors},
					  parent => \$ref_el,
					 );
  
  my $publisher_el =  $self->create_element(
					    name => "publisher",
					    text => $arg{publisher},
					    parent => \$ref_el,
					   );
  my $publisher_city_el =  $self->create_element(
						 name => "publisher_city",
						 text => $arg{publisher_city},
						 parent => \$ref_el,
						);
  my $job_key_el =  $self->create_element(
					   name => "job_key",
					   text => $arg{job_key},
					   parent => \$ref_el,
					  );


  if ($arg{parent}) {
    ${ $arg{parent} }->appendChild($ref_el);
}

return $ref_el;


} # end of add_reference_element


############
# 
# print_xml - takes the XML in $self->{doc} and returns it to the calling function
# in a more formatted pretty_print format
#
############

sub print_xml {
  
  my ($self,$doc) =  @_;

  my $pretty_xml = ${$doc}->toString; #dereference the $doc object
  
  $pretty_xml =~  s/(>)(<\/)/$1\n$2/g;
  $pretty_xml =~  s/(>)(<[^\/])/$1\n\t$2/g;
  
  
  return $pretty_xml;
  
} # end print XML








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
