package RGD::Getrefs;

############################
#
# Ratref.pm
#
#
# (c) Simon Twigger, Rat Genome Database, 2000
#
############################


use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use LWP::UserAgent;

require Exporter;


@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';


############################
# Module constructor method
#

sub new {

  my ($class, %arg) = @_;

  bless {
	 _data_dir      => $arg{data_directory} || "../data/",
	 _log_dir       => $arg{log_directory}  || "../logs/",
	 _log_file      => $arg{log_file}       || "ratref_log",
	 _pause_time    => $arg{pause_time}     || 15,
	 _getid_url     => $arg{getid_url}      || 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi',
	 _getref_url    => $arg{getref_url}     || 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi',
	 _getesummary_url	=> $arg{getesummary_url}     || 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi',
	 _getsumm_url => $arg{getsumm_url}    || 'https://www.ncbi.nlm.nih.gov/entrez/query.fcgi',
	 _db            => $arg{db}             || 'm',
	 _field         => $arg{field}          || 'MeSH',
	 _dopt          => $arg{dopt}           || 'd',
	 _mode          => $arg{mode}           || 'sgml',
	 _dispmax       => $arg{dispmax}        || '800',
	 _term          => $arg{search_term}    || '',
	 _report        => $arg{report}         || 'medlars',
	 _relentrezdate => $arg{relentrezdate}  || '',
	 _minentrezdate => $arg{minentrezdate}  || '',
	 _authors       => $arg{search_author}  || "",
	 _year          => $arg{search_year}    || "",
	 _tool          => "RatGenomeDatabase",
	}, $class;


} # end of new()


############################
# Connect to database and download the id's
#

sub get_ids {

  my $me = shift @_;

  my $options = "&tool=$me->{_tool}&db=$me->{_db}&Dopt=$me->{_dopt}&mode=$me->{_mode}&retmax=$me->{_dispmax}";


  my $full_term = "";
  if ($me->{_term}) {
    $full_term .=  $me->{_term}."[TIAB]";
  }
  if ($me->{_authors}) {
    if($full_term) {
      $full_term = "$full_term AND ";
    }
    $full_term .=  $me->{_authors}."[AU]";
  }
  if ($me->{_year}) {
    if($full_term) {
      $full_term = "$full_term AND ";
    }
    $full_term .=  $me->{_year}."[DP]";
  }

  # escape spaces to '+' 
  $full_term =~ s/\s+/\+/g;

  my $agent = new LWP::UserAgent;
  my $request = new HTTP::Request('GET', 
				  $me->{_getid_url} . "?term=" . $full_term . $options
				 );
				 
  my $response =  $agent->request($request);
  die "Couldn't get the URL. Status code =  ", $response->code
    unless $response->is_success;

  return $response->content;

} # end of get_idfs()


############################
# Connect to database and download the id's
#

sub get_refs {

  my ($me,%args) = @_;

  my $id_list = $args{id_list};
  my $db = $args{db}         || $me->{_db};
  my $report = $args{report} || $me->{_report};
  my $mode = $args{mode}     || $me->{_mode};

  #my $options = "&tool=$me->{_tool}&db=$db&report=$report&mode=$mode";
  if($report){
	if(($report) =~ /pubmed/i){
		$report = "pubmed";
	}
  }
  if($mode){
	if($mode eq "medlars"){
		$mode = "medline";
	}
  }
  my $options = "&tool=$me->{_tool}&db=$db&rettype=$report&retmode=$mode";

  my $agent = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
  warn "$me->{_getref_url}?id=$id_list$options\n";
  my $request = new HTTP::Request('GET', "$me->{_getref_url}?id=$id_list$options");

  my $response =  $agent->request($request);
  die "Couldn't get the URL. Status code =[", $response->code."] [".$response->status_line."]" unless $response->is_success;

  return $response->content;
}


############################
# Connect to database and download summary for a given PMID
#

sub get_summary_refs {

  my ($me,%args) = @_;

  my $id_list = $args{id_list};
  my $db = $args{db}         || $me->{_db};
  #my $report = $args{report} || $me->{_report};
  #my $mode = $args{mode}     || $me->{_mode};

 my $options = "&tool=$me->{_tool}&db=pubmed";

  my @tempar = split /,/,$id_list;
  my $size = @tempar;

  my $agent = new LWP::UserAgent;
  my $request = new HTTP::Request('GET', 
#				  $me->{_getref_url} . "?id=" .
				$me->{_getesummary_url} . "?id=" .
				  $id_list . 
				  $options);

  my $response =  $agent->request($request);

  die "Couldn't get the URL. Status code =  ", $response->code unless $response->is_success;
  #print "Response: $options, $response\n";
  return $response->content;

}



# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

########################################################
# POD Documentation follows.
########################################################

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Ratref::Getrefs - Perl extension for Accessing Pubmed Database and downloading
references into the Ratref database.

=head1 SYNOPSIS

  use Ratref::Getrefs;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Ratref::Getrefs was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

S.N. Twigger (simont@mcw.edu)

=head1 SEE ALSO

perl(1).

=cut
