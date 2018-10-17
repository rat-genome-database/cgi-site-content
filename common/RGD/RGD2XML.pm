#!/usr/bin/perl

package RGD::RGD2XML;

############################
#
# Ratref::RGD2XML.pm
#
#
# (c) Simon Twigger, Rat Genome Database, 2000
#
############################


use strict;
use lib qw (/rgd/tools/common/);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use DBI;
use RGD::Log;
use Data::Dumper;
use RGD::XML::Writer;
use RGD::_Initializable;
@RGD::RGD2XML::ISA = qw ( RGD::_Initializable );
require Exporter;

# @ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();

my $VERSION = '0.01';
my $SCRIPT_NAME = "RGD2XML.pm";

# Direct mapping of Medline tags to ratref ARTICLE_LIST attributes
my %tag_fields = (
		  UI   => "MEDLINE_ID",
		  TI   => "TITLE",
		  LA   => "LANGUAGE",
		  PT   => "PUBLICATION_TYPE",
		  PG   => "PAGES",
		  IP   => "ISSUE",
		  VI   => "VOLUME",
		  AB   => "ABSTRACT",
		  PMID => "PMID",
		  SO   => "CITATION",
		  URLF => "URL_FULL_TEXT",
		  URLS => "URL_SUMMARY",
		  AU   => "AUTHOR_STR",
		  MH   => "MESH_STR",
		  AID   => "DOI",
		  );


############################
# Module constructor method
#

sub _init {

  my ($self, %args) = @_;

  $self->{_doc_ref}       = $args{doc_ref};
  $self->{ _db_user}      = $args{db_user}   || 'cur_1';
  $self->{_db_pwd}        = $args{db_pwd}    || 'rgd_1';
  $self->{_db_sid}        = $args{db_sid}    || 'cur';
  $self->{ _db_driver}    = $args{db_driver} || 'dbi:Oracle';
  $self->{_type}          = $args{type} || 'references';
  $self->{_script}        = $args{script} || $SCRIPT_NAME;
  $self->{_version}       = $args{version} || $VERSION;
  $self->{_log_obj}       = RGD::Log->new(
						log_file => 'rgd2xml.pm',
						script_name   => 'rgd2xml',
						script_version => $VERSION,
					       );
  
  my $parser = new XML::DOM::Parser;
  
  my $xml = "<rgd_dataset></rgd_dataset>"; # create the initial XML doc element - kludge
  $self->{doc}    = $parser->parse($xml);
  $self->{writer} = RGD::XML::Writer->new(
					  doc_ref => \$self->{doc},
					 ) ;
  
  # Set the attributes for the dataset as a whole
  $self->{doc}->getDocumentElement->setAttribute("type",$self->{_type});
  $self->{doc}->getDocumentElement->setAttribute("script_name",$self->{_type});
  $self->{doc}->getDocumentElement->setAttribute("script_version",$self->{_version});
  $self->{doc}->getDocumentElement->setAttribute("creation_date", scalar localtime);
  
  # create contents element to list the objects in the dataset
  my $contents_el = $self->{writer}->create_element(
						    name => "contents",
						    parent => \$self->{doc}->getDocumentElement,
						   );
  # Add an object entry to the contents, type QTL
  $self->{writer}->create_element(
				  name => "object",
				  atts => {
					   type => "references",
					  },
				  parent => \$contents_el,
				 );
  
}


############
# 
# print_xml - takes the XML in $self->{doc} and returns it to the calling function
# in a more formatted pretty_print format
#
############

sub print_xml {
  
  my $self = shift @_;

  my $pretty_xml = $self->{doc}->toString; #dereference the $doc object
  
  $pretty_xml =~  s/(>)(<\/)/$1\n$2/g;
  $pretty_xml =~  s/(>)(<[^\/])/$1\n\t$2/g;
  
  
  return $pretty_xml;
  
} # end print XML


############
# 
# medline_2_xml takes references in the Medlars format and converts them to 
# RGD XML formats
#
############

sub medline_2_xml {

  my $self = shift(@_);
  my $ref_list = shift(@_);

  # parse the reference list data into individual reference objects
  # which are then passed back into @ref_obj_ary
  my @ref_obj_ary = _parse_refs(\$ref_list);
  
  my ($day,$month,$date,$time,$year) = split ' ', scalar localtime();

  # Loop around each reference object, dealing with the appropriate
  # tag and its contents in the appropriate way!

  my $xml_ref_array = ();


  REF_LOOP:
  for (my $rf=0; $rf <= $#ref_obj_ary; $rf++) {

    $self->{_insert_ok} = 1;

    # For this reference, loop around each tag and load it into the database
    # need to get the appropriate new reference ID from the sequence

   

    # my $ARTICLE_ID  = $ref_id;
    my $MEDLINE_ID  = $ref_obj_ary[$rf]->{UI}[0] || "NULL";
    my $PMID        = $ref_obj_ary[$rf]->{PMID}[0] || "NULL";
    my $PUB_TYPE    = $ref_obj_ary[$rf]->{PT}[0] || "NULL";
    my $VOLUME      = $ref_obj_ary[$rf]->{VI}[0] || "NULL";
    my $ISSUE       = $ref_obj_ary[$rf]->{IP}[0] || "NULL";
	
	my $DOI = "";
	my $d = $ref_obj_ary[$rf]->{AID};
	if($d){
		my @arr = @$d;
		warn "this is the array: @arr";
		
		for my $doi(@arr){
			if($doi=~/\[doi\]/gi){
				$DOI = $doi;
			}else{
				$DOI = "";
			}
		}
	}
		
	
	#print "\n$MEDLINE_ID\t$PMID\t$PUB_TYPE\t$VOLUME\t$ISSUE\t$DOI\n";

    $ref_obj_ary[$rf]->{DP}[0] =~ /(\d\d\d\d) (\D\D\D)/;
    my $YEAR = $1 || 1000;
    my $MONTH = $2 || "Jan";

    #$YEAR           = "TO_DATE(\'$MONTH-$YEAR\',\'MON-YYYY\')";
    #$MONTH          = "TO_DATE(\'$MONTH\',\'MON\')";
    my $PAGES       = $ref_obj_ary[$rf]->{PG}[0] || "NULL";
    my $TITLE       = $ref_obj_ary[$rf]->{TI}[0] || "NULL";
    # Remove any [PUBMED comments] in square brackets
    # Could contain alphanumeric, space, or parentheses
    $TITLE          =~ s/\[[\w\s\(\)]+\]//;

    my $JOURNAL     = $ref_obj_ary[$rf]->{TA}[0] || "NULL";
    my $UC_TITLE    = $TITLE;
    $UC_TITLE       =~ tr/a-z/A-Z/;
    my $AUTH_LIST   = $ref_obj_ary[$rf]->get_authors || "NULL";
    my $UC_AUTHOR_LIST = $AUTH_LIST;
    $UC_AUTHOR_LIST  =~ tr/a-z/A-Z/;
    my $CITATION    = $ref_obj_ary[$rf]->{SO}[0] || "NULL";
    my $ABSTRACT    = $ref_obj_ary[$rf]->{AB}[0] || "NULL";
    my $UC_ABS      = $ABSTRACT;
    $UC_ABS         =~ tr/a-z/A-Z/;
    my $LANGUAGE    = $ref_obj_ary[$rf]->{LA}[0] || "NULL";
    my $URL         = $ref_obj_ary[$rf]->{URL}[0] || "";
    my $URL_FULL    = $ref_obj_ary[$rf]->{URL}[0] || "";
    my $URL_SUMM    = $ref_obj_ary[$rf]->{URL}[0] || "";
    my $RGD_ID      = "NULL";
    my $CURATN_STAT = "NO_STATUS";
    my $CREATN_DATE = "SYSDATE"; # "TO_DATE(\'$date-$month-$year\',\'DD-MON-YYYY\')";
    my $CURATN_DATE = "NULL";
    my $LAST_MOD_DT = $CREATN_DATE || "NULL";
    my $ASSOC_IDS   = $ref_obj_ary[$rf]->{SI}[0] || undef;

    # first insert the journal, or get back its existing ID

    # create contents element to list the objects in the dataset
    my $ref_el = $self->{writer}->create_element(
					 name => "reference",
					 atts => {
						  rgd_id => "",
						  type => "JOURNAL ARTICLE",
						 },
					 parent => \$self->{doc}->getDocumentElement,
					);
    
    # Create the title element
    $self->{writer}->create_element(
			    name => "title",
			    parent => \$ref_el,
			    text => $TITLE,
			   );
    
    my $publication_el = $self->{writer}->create_element(
						 name => "publication_data",
						 parent => \$ref_el,
						);
    my $pub_el = $self->{writer}->create_element(
					 name => "publication",
					 text => $JOURNAL,
					 parent => \$publication_el,
					);
    my $volume_el = $self->{writer}->create_element(
					    name => "volume",
					    text => $VOLUME,
					    parent => \$publication_el,
					   );
    my $issue_el = $self->{writer}->create_element(
					   name => "issue",
					   text => $ISSUE,
					   parent => \$publication_el,
					  );
    
    my $pages_el = $self->{writer}->create_element(
					   name => "pages",
					   text => $PAGES,
					   parent => \$publication_el,
					  );
  
    my $pubdate_el =  $self->{writer}->create_element(
					      name => "pub_date",
					      text => $YEAR,
					      parent => \$publication_el,
					     );
	$DOI =~ s/.\[doi\]//gi;
	if($DOI =~m/.\[pii\]/gi){
		$DOI = "";
	}
	my $doi_el =  $self->{writer}->create_element(
						  name => "doi",
						  text => $DOI,
						  parent => \$publication_el,
						 );
    
    # add the publication data to the reference element
    $ref_el->appendChild($publication_el);

    my $abstract_el =  $self->{writer}->create_element(
						name => "abstract",
						text => $ABSTRACT,
						parent => \$ref_el,
					       );

    my $cit_authors = $ref_obj_ary[$rf]->get_citation_authors || "";

    my $cit_text = "$cit_authors $CITATION";

    my $citation_el =  $self->{writer}->create_element(
						name => "citation",
						text => $cit_text,
						parent => \$ref_el,
						      );

   
    my $author_list_el = $self->{writer}->create_element(
						name => "author_list",
						parent => \$ref_el,
					       );

    my @authors = $ref_obj_ary[$rf]->get_author_list;

    if(@authors) {

		AUTHOR_LOOP:
		for my $author (0 .. $#authors) {

			# Avoid etal as an author!
			next AUTHOR_LOOP if $authors[$author] =~ /et al\./i;

			$authors[$author] =~ s/\s(\w+)$//;
			my $firstname = $1;
			
			#$authors[$author] =~ s/$firstname//;
			$authors[$author] =~ s/\s+$//;
			my $lastname = $authors[$author];
		
			# my ($lastname,$firstname) = split '\s', $authors[$author];
			my $author_el = $self->{writer}->create_element(
						  name => "author",
						  parent => \$author_list_el,
						 );

			$self->{writer}->create_element(
						  name => "lastname",
						  text => $lastname,
						  parent => \$author_el,
						  );

			$self->{writer}->create_element(
						  name => "firstname",
						  text => $firstname,
						  parent => \$author_el,		 
						 );
		} # end of author loop

    } # end of if @authors


    # add in the URL if it exists
    my $url_el = $self->{writer}->create_element(
						 name   => "url_web_reference",
						 text   => $URL,
						 parent => \$ref_el,
						);
    
    my $xdb_data_el = $self->{writer}->create_element(
						 name   => "xdb_data",
						 parent => \$ref_el,
						);

    # If the PubMed reference lists any associated sequences,
    # include them here and then link into RGD as a direct link
    # if the object is already in RGD, or as an XDB link
    # if the object is not currently present in RGD.

    if($ASSOC_IDS) {
		my $assoc_el = $self->{writer}->create_element(
						     name   => "associated_objects",
						     parent => \$ref_el,
						    );
		my @ids = split ',',$ASSOC_IDS;

		for my $id (0 .. $#ids) {

			my ($db,$acc) = split '/',$ids[$id];

			my $obj_el = $self->{writer}->create_element(
						    name   => "rgd_object",
						    atts   => {
									rgd_id => "",
									type => "unknown",
									database => "$db",
							    },
						    parent => \$assoc_el,
						    text => "$acc",
						);
		}
    }

    $self->{writer}->create_xdb_element(
					
					database_name => "PubMed",
					database_url  => "https://www.ncbi.nlm.nih.gov/PubMed/",
					accession => $PMID,
					link_text => $cit_text,
					report_url => "https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=",
					
					parent => \$xdb_data_el,
				       );

    $self->{writer}->create_xdb_element(
					
					database_name => "Medline",
					database_url  => "https://www.ncbi.nlm.nih.gov/PubMed/",
					accession => $MEDLINE_ID,
					link_text => $cit_text,
					report_url => "https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Abstract&list_uids=",
					
					parent => \$xdb_data_el,
				       );
    
  } # end of reference loop

} # end of load_refs()



############
# 
# _db_error
#
# Logs database errors
#
############

sub _db_error {

  my ($self,$err_num, $err_str, $ref_id) = @_;

  if ($err_num == 1) {
    # warn "Primary Key Constraint problem: $err_str\n";
    $self->{_insert_ok} = 0;
  }
  $self->{_insert_ok} = 0;

  $self->{_log_obj}->add_entry(
			       input_parameters => {
						    err_num => $err_num,
						    err_msg =>  $err_str,
						    ref_id  => $ref_id,
						   },
			     );

} # end of _db_error

############
# 
# get_all_PMIDS
#
# gets a HASH of all the loaded PMIDs to avoid reloading things
#
############

sub get_all_PMIDS {

  my ($self, $PMID_hash_ref) = @_;

  my $sql = "SELECT PMID from ARTICLE_LIST";
  my $sth = $self->{dbh}->prepare($sql) || die ("$DBI::errstr\n");
  $sth->execute || die ("$DBI::errstr\n");
  
  my $PMID = "";

  $sth->bind_columns(undef, \$PMID);

  while ($sth->fetch) {
    # print "Already found $PMID\n";
    $PMID_hash_ref->{$PMID} = 1;
  }
    
  $sth->finish || die ("$DBI::errstr\n");
 
} # end of get_all_PMIDs


sub _db_error2 {

  my ($self,$err_num, $err_str, $ref_id) = @_;

  if ($err_num == 1) {
    # warn "Primary Key Constraint problem: $err_str\n";
    $self->{_insert_ok} = 0;
  }
  $self->{_insert_ok} = 0;

  $self->{_log_obj}->add_entry(
			       input_parameters => {
						    err_num => $err_num,
						    err_str => $err_str,
						    ref_id  => $ref_id,
						   },
			       );

}




############
# 
# _get_sequence (private function)
#
# gets the next sequence value for various db IDs
#
############

sub get_sequence {

  my %SEQUENCES = (
		   articles => 'ARTICLE_SEQ',
		   annotations => 'ANNO_SEQ',
		   journals    => 'JOURNAL_SEQ',
		   misc_hdg    => 'HDG_SEQ',		   
		   );

  my ($me,$seq) = @_;

  # my $me = $$self_ref; # dereference the reference. Is there an easier way?

  $me->connect unless $me->{_db_open};

  my $sql = "SELECT $SEQUENCES{$seq}.nextval FROM DUAL";

  my $sth = $me->{dbh}->prepare($sql) || die ("$DBI::errstr\n");
  
  $sth->execute || die ("$DBI::errstr\n");

  my ($sequence) = $sth->fetchrow_array;

  return $sequence;
  

} # end of get_sequence


############
# 
# _parse_refs (private function)
#
# takes references in the Medlars format
# and loads them into separate reference objects and returns an array of
# reference objects to the calling subroutine
#
############

sub _parse_refs {
  
  my $ref_list_ref = shift(@_);

  # need to parse the incoming references into individual entries
  # then load the appropriate parts into the db.
  # the UI tag is the start of record indicator.

  my @ref_ary = split /^/m,$$ref_list_ref;
  my $line = "";

  my $current_tag = "";
  my $current_data = "";
  my $tmp_tag = "";
  my $ref_obj = undef;
  my @total_refs = ();

  # print "parsing data\n";
  
  # do {

  while ($line = shift(@ref_ary)) {
      
    #print "\n^^^^$line\n";
    
    my $tag = "";
    chomp($line);

    $line =~ /(^\w\w(\w*|\s*|\w\s))\-/;

    # if there is a new tag
    if($1) {

		# if($ref_obj->{UI} ne "start") {
		# if the refobj has a UI tag value already (ie this isnt the first
		# time through this loop)
		# push the last tag and its data into the RefObj's tag array
      if(defined $ref_obj) {
		$current_data =~ s/^\s+//;
		push( @{$ref_obj->{$tmp_tag}},$current_data);
      }
      
		# print "\t>>> $current_tag \t $current_data\n";

      $current_tag = $1; # holds the tag w. whitespace
      $current_data = "";

      $tmp_tag = $current_tag;
      $tmp_tag =~ s/\s//g;
      
		#if($tmp_tag eq "UI") {
      if($tmp_tag eq "PMID") { #DP 9-18-03 Pubmed changed their format, PMID is now the delimitor
		if(defined $ref_obj) {
			# add the current ref obj to the total refs array
			push (@total_refs,$ref_obj);
		}
	
		# print "creating a new refobj\n";
		# create a new refs object for the subsequent data
		$ref_obj = Ratref::Reference->new();
	
      }
	  
    }

    $line =~ s/^$current_tag\-//g;
    $line =~ s/\s+/ /g;

    $current_data .= $line;
	#print "\n***$current_data###\n";

    # If we are at the end of the reference file, add this last
    # refobject to the total_refs array
    if($#ref_ary == -1) {
      $current_data =~ s/^\s+//;
      push( @{$ref_obj->{$tmp_tag}},$current_data);
      push (@total_refs,$ref_obj);
    }

  } # until ($#ref_ary == -1);
  
  return @total_refs;

} # end of parse_refs



# Autoload methods go after =cut, and are processed by the autosplit program.

1;



package Ratref::Reference;

############################
#
# Ratref::Reference
#
#
# (c) Simon Twigger, Rat Genome Database, 2000
#
############################


# Very generic reference object simply consisting of an
# anonymous hash into which I can dump the tag values
# to be retrieved at a later time and processed

use strict;
use lib qw (/project1/refs/bin /project1/rgd/TOOLS/common);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use XML::DOM;
use RGD::XML::Writer;

$VERSION = '0.01';



############################
# Module constructor method
#

sub new {

  my $class = shift (@_);

  bless { }, $class;
  
} # end of new()


sub get_authors {
  
  my $self = shift @_;

  if ($self->{AU}) {
    return join(',',@{ $self->{AU}});
  }
  else {
    return "NO_AUTHOR";
  }
  
}

sub get_author_list {

  my $self = shift @_;

  if ($self->{AU}) {
    return @{ $self->{AU}};
  }
  else {
    return 0;
  }

}

sub get_citation_authors {
  
  my $self = shift @_;
  
  if ($self->{AU}) {
    
    my $num_authors = $#{ $self->{AU}}+1;
    
    if($num_authors > 2) {
      return "$self->{AU}[0], etal.,";
    }
    elsif ($num_authors == 2) {
      return "$self->{AU}[0] and $self->{AU}[1],";
    }
    else {
      return join(',',@{ $self->{AU}});
    }
  }
  else {
    return "NO_AUTHOR";
  }
  
}


1;






########################################################
# POD Documentation follows.
########################################################

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Ratref::Loadrefs - Perl extension for loading references into RatRef db

=head1 SYNOPSIS

  use Ratref::Loadrefs;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Ratref::Loadrefs was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

S.N. Twigger (simont@mcw.edu)

=head1 SEE ALSO

perl(1).

=cut
