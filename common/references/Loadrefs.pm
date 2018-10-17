package Loadrefs;

############################
#
# Ratref::Loadrefs.pm
#
#
# (c) Simon Twigger, Rat Genome Database, 2000
#
############################


use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use RGD::DB;

use DBI;
# use Site::LOG::Log;

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

my $DBI = DBI->connect("dbi:Oracle:rgd_dev","rgd_owner","rgd_2k", {RaiseError => 1} );

unlink "dbitrace.log" if -e "dbitrace.log";
$DBI->trace(1);


# Direct mapping of Medline tags to ratref ARTICLE_LIST attributes
my %tag_fields = (
		  UI   => "MEDLINE_ID",
		  TI   => "TITLE",
		  LA   => "LANGUAGE",
		  PT   => "REFERENCE_TYPE",
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
		  );


############################
# Module constructor method
#

sub new {

  my ($class, %arg) = @_;

  bless {

	 dbh   => RGD::DB->new(),
	 PMIDS => {
		   test => 'test',
		  },
	}, $class;
  

} # end of new()

# Preloaded methods go here.




############
# 
# load_refs takes references in the Medlars format and loads them
# into the database.
#
############

sub load_refs {

  my $self = shift(@_);
  my $ref_list = shift(@_);

  # parse the reference list data into individual reference objects
  # which are then passed back into @ref_obj_ary
  my @ref_obj_ary = _parse_refs(\$ref_list);

  my ($day,$month,$date,$time,$year) = split ' ', scalar localtime();

  # Loop around each reference object, dealing with the appropriate
  # tag and its contents in the appropriate way!

 REF_LOOP:
  # for (my $rf=0; $rf <= $#ref_obj_ary; $rf++) {

  for (my $rf=0; $rf <= 10; $rf++) {

    $self->{_insert_ok} = 1;
    #my $PMID        = $ref_obj_ary[$rf]->{PMID}[0] || "NULL";
    
    
    #next REF_LOOP if $self->{PMIDS}{$PMID};
    
    #$self->{PMIDS}{$PMID} = 1;
    
    # For this reference, loop around each tag and load it into the database
    # need to get the appropriate new reference ID from the sequence

    my $ref_id = 0; # FIX THIS

    my $tag = "";

    my $REF_KEY  = $rf+1;
    
    my $REFERENCE_TYPE    = "JOURNAL ARTICLE"; # $ref_obj_ary[$rf]->{PT}[0] || "JOUR";
    my $VOLUME      = $ref_obj_ary[$rf]->{VI}[0] || "NULL";
    my $ISSUE       = $ref_obj_ary[$rf]->{IP}[0] || "NULL";

    $ref_obj_ary[$rf]->{DP}[0] =~ /(\d\d\d\d) (\D\D\D)/;
    my $YEAR = $1 || 1000;
    my $MONTH = $2 || "Jan";

    my $PUB_DATE = "TO_DATE(\'$MONTH-$YEAR\',\'MON-YYYY\')";

    my $PAGES       = $ref_obj_ary[$rf]->{PG}[0] || "NULL";
    my $TITLE       = $ref_obj_ary[$rf]->{TI}[0] || "NULL";
    my $PUBLICATION     = $ref_obj_ary[$rf]->{TA}[0] || "NULL";
    my $UC_TITLE    = $TITLE;

    my $AUTH_LIST   = $ref_obj_ary[$rf]->get_authors || "NULL";
 
    my $CITATION    = $ref_obj_ary[$rf]->{SO}[0] || "NULL";
    my $ABSTRACT    = $ref_obj_ary[$rf]->{AB}[0] || "NULL";
 
    
    my $URL_FULL    = $ref_obj_ary[$rf]->{URLF}[0] || "NULL";
    my $URL_SUMM    = $ref_obj_ary[$rf]->{URLS}[0] || "NULL";
    my $MEDLINE_ID  = $ref_obj_ary[$rf]->{UI}[0]   || "NULL";
   

    my $LAST_MOD_DT = "SYSDATE" || "NULL";
    
    #print $ref_obj_ary[$rf]->get_citation_authors;
    print "Citation: $CITATION\n";

    $CITATION = $ref_obj_ary[$rf]->get_citation_authors . " $CITATION";

    next REF_LOOP unless $self->{_insert_ok};

    # my $sql = "insert into REFERENCES (REF_KEY,TITLE,PUBLICATION,VOLUME,ISSUE,PAGES,NOTES,REFERENCE_TYPE,CITATION,ABSTRACT) VALUES (?,?,?,?,?,?,NULL,?,?,?)";

    my $q_TITLE = $DBI->quote($TITLE);
    my $q_ABSTRACT = $DBI->quote($ABSTRACT);
    my $q_CITATION = $DBI->quote($CITATION);
    my $q_PUBLICATION = $DBI->quote($PUBLICATION);
    my $q_VOLUME = $DBI->quote($VOLUME);
    my $q_ISSUE = $DBI->quote($ISSUE);
    my $q_PAGES = $DBI->quote($PAGES);
    my $q_REFERENCE_TYPE = $DBI->quote($REFERENCE_TYPE);
   

    # my $sql = "insert into REFERENCES (REF_KEY,TITLE,PUBLICATION,VOLUME,ISSUE,PAGES,PUB_DATE,REFERENCE_TYPE,CITATION,ABSTRACT) VALUES ($REF_KEY,$q_TITLE,$PUBLICATION,$VOLUME,$ISSUE,$PAGES,$PUB_DATE,$REFERENCE_TYPE,$q_CITATION,$q_ABSTRACT)";

    my $sql = "insert into REFERENCES (REF_KEY,VOLUME) VALUES (?,?)";
    

    my $sth = $DBI->prepare($sql) || die  ("$TITLE, $DBI::errstr\n");
    
    $sth->execute($REF_KEY,'123') || die  ("Execute: $TITLE, $DBI::errstr\n");;

    $sth->finish || die ("$DBI::errstr\n");

    # Initial insert Ok at this point, so insert Author Tags
    # create SQL code to add author information

    # my $sth = $self->{dbh}->{dbh}->prepare("BEGIN add_authors(:1, :2, :3, :4, :5, :6); END;") || die ("$DBI::errstr\n");

  AUTHOR_LOOP:
    #my $auth = "";
    #for ($auth = 0; $auth <= $#{ $ref_obj_ary[$rf]->{AU}}; $auth++) {

      #my ($surname,$initials,$suffix) = split ' ',$ref_obj_ary[$rf]->{AU}[$auth];
      #$suffix = 'NULL' unless $suffix; # make it null if there is no suffix

      # print "$ref_obj_ary[$rf]->{AU}[$auth],$surname,$initials,$suffix,$ref_id \n";

      # $sth->execute($ref_obj_ary[$rf]->{AU}[$auth],$surname,$initials,$suffix,0,$ref_id);
      # $sth->finish || die ("$DBI::errstr\n");
    # }
    

}
  
} # end of load_refs()


# Deletes all the references from the table...




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
  
  do {

    $line = shift(@ref_ary);
      
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
      
      # print "$current_tag \t $current_data\n";

      $current_tag = $1; # holds the tag w. whitespace
      $current_data = "";

      $tmp_tag = $current_tag;
      $tmp_tag =~ s/\s//g;
      
      if($tmp_tag eq "UI") {

	if(defined $ref_obj) {
	  # add the current ref obj to the total refs array
	  push (@total_refs,$ref_obj);
	}
	
	# print "creating a new refobj\n";
	# create a new refs object for the subsequent data
	$ref_obj = Reference->new();
	
      }
    }

    $line =~ s/^$current_tag\-//g;
    $line =~ s/\s+/ /g;

    $current_data .= $line;

    # If we are at the end of the reference file, add this last
    # refobject to the total_refs array
    if($#ref_ary == -1) {
      push (@total_refs,$ref_obj);
    }

  } until ($#ref_ary == -1);



  return @total_refs;

} # end of parse_refs



# Autoload methods go after =cut, and are processed by the autosplit program.

1;



package Reference;

############################
#
# Reference
#
#
# (c) Simon Twigger, Rat Genome Database, 2000
#
############################


# Very generic reference object simply consisting of an
# anonymous hash into which I can dump the tag values
# to be retrieved at a later time and processed

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

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

sub get_citation_authors {

  my $self = shift (@_);

  if ($self->{AU}) {
    
   return $self->{AU}->[0] unless $self->{AU}->[1];
   
   return "$self->{AU}->[0] and $self->{AU}->[1]" unless $self->{AU}->[2];

   return "$self->{AU}->[0], etal.";

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
