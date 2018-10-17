#!/usr/bin/perl -w

##############################
#
# keyword_search.cgi Simon Twigger May 2000
#
# Displays the Strain report for a given Strain ID
#
##############################
use lib '/rgd/tools/common';

use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);
use strict;

my %headings = (
		strain_symbol_lc => "Strain symbol",
		origin => "Origin",
		color => "Color",
		chr_altered => "Chromosome Altered",
		source => "Source",
		inbred_gen => "Inbred generations",
	       );

my @all_fields = qw(strain_symbol_lc origin color chr_altered source inbred_gen);

my $form = new CGI;
my $db = RGD::DB->new();

# Reference for the table hash with column info for all tables
my $table_ref = $db->get_table_hash_ref();

my %ref_list = ();
my %ref_data = ();

# Read in parameters

my $keyword = $form->param('keyword') || "hypertension";
$keyword =~ tr/[A-Z]/[a-z]/;
my @fields = $form->param('fields'); #) || ('origin','strain');

if($fields[0] eq "all") {
  @fields = @all_fields;
}
#my @fields  = ('origin','strain');

# concatenate the fields for the sql statement

my $fields = join ',',@fields;

my %results = search_strain_lc($fields, $keyword);
my $format = "html";
my $html = RGD::HTML->new(title      => "Strain Keyword Search",
			  doc_title  => "Strain Keyword Search",
			  version    => "1.0",
			  link_dir   => "strains");
my $baseURL=$html->get_baseURL; 
my $baseCGI=$html->get_baseCGI;

if($format =~ /text/i) {

}
else {
  &display_html(\%results);
}

exit;

########################

sub display_html {

  $html->html_head;
  $html->tool_start;

  my $matches = keys %results;

  print "<p>Found $matches matches:</p>\n";
 
  print "<table><tr><td><b>Strain</b></td><td><b>Field</b></td><td><b>Keyword context</b></td></tr>\n";

  foreach my $strain (sort keys %results) {

    my $url = "/rgdweb/report/strain/main.html?id=$results{$strain}{rgd_id}";

    print "<tr><td><b><a href=\"$url\">$strain</a></b></td><td colspan=2>&nbsp;</td></tr>";
  RESULT:
    foreach my $entry (keys %{$results{$strain}}) {

      if($results{$strain}{$entry} !~ /$keyword/i || $entry eq "rgd_id") {
	next RESULT;
      }
      $results{$strain}{$entry} =~ s/$keyword/<font color=\"red\">$keyword<\/font>/g;

      print "<tr><td>&nbsp;</td><td>$headings{$entry}</td><td>$results{$strain}{$entry}</td></tr>\n";
    }
    print "<tr><td colspan=3>&nbsp;</td></tr>\n";
  }
  print "</table>\n";
  
  print "<p><font size=-1><b>Parameters</b><BR>\n";
  print "Keyword: $keyword<BR>\n";
  print "Fields: $fields<BR>\n";
  print "</font>\n";

  $html->tool_end;
  $html->html_foot;


} # end of display_html


sub search_strain_lc {

  my ($fields, $keywords) = @_;
  my %results = ();

  # Create the SQL query
  
  my $att_list = "";
  my @search_list = ();

  for my $f (0 .. $#fields) {
    $att_list .= ",'... ' || substr($fields[$f],instr($fields[$f],'$keywords')-20,50) || ' ...'";
    push @search_list, "($fields[$f] like '%$keywords%')";
  }

  my $search_list = join " or ",@search_list;
  if($search_list) {
  	$search_list = "(" . $search_list . " ) and ";
  }

  my $sql = <<"SQL";
SELECT s.strain_symbol, s.rgd_id $att_list
FROM strains_lc s, rgd_ids r WHERE $search_list r.object_status = 'ACTIVE' and r.rgd_id = s.rgd_id
	order by s.strain_symbol
SQL

  warn $sql;
  
  # exit;
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute() or die "Can't execute statement: $DBI::errstr";
  
  while(my($strain,$rgd_id,@search_results) = $sth->fetchrow_array() ) {
    $results{$strain}{rgd_id} = $rgd_id;
    for my $hits (0 .. $#search_results) {
      $results{$strain}{$fields[$hits]} = $search_results[$hits]
    }
  }

  return %results;

}


sub get_allele_data {

  my $id = shift @_;

  my $sql = <<"SQL";
SELECT count(allele_key) FROM sslps_alleles WHERE strain_key =
	(SELECT strain_key
	 FROM strains
	 WHERE rgd_id = $id)
SQL

  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute() or die "Can't execute statement: $DBI::errstr";

  my ($num_alleles) = $sth->fetchrow_array();

  return $num_alleles;
  
}


__END__
SELECT strain_symbol, substr(origin,instr(origin,'provoost')-20,40) FROM strains_lc WHERE origin like '%provoost%' order by strain_symbol
SQL
