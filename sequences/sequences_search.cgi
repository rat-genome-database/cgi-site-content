#!/usr/bin/perl

##############################
#
# sequence_search.cgi Simon Twigger May 2000
#
# Looks for a sequence entry matching various parameters
#
##############################
use lib '/rgd/tools/common';
use RGD::DB;   #NEED TO CHANGE AFTER TESTING!!!!!!!!!!!
use RGD::HTML;
use CGI qw(:standard);
use strict;
use LWP::UserAgent;

my $form = new CGI;
my $db = RGD::DB->new();  #NEED TO CHANGE AFTER TESTING!!!!!!!!!!!

my $html = RGD::HTML->new(
			  title      => "Sequence Search Results - Rat Genome Database",
			  doc_title  => "Sequence Search Report",
			  version    => "2.0",
			  tool_dir   => "sequences",
			  link_dir   => "sequences",
			 );
my $baseURL=$html->get_baseURL; 
my $baseCGI=$html->get_baseCGI;
my $seq_tool="$baseCGI/sequences/sequences_view.cgi?id=";

my $dataPATH=$html->get_dataPATH; # /rgd/DATA
my $wwwPATH= $html->get_wwwPATH; # /rgd/WWW
my $cachePATH="$dataPATH/cache/sequences"; # to save query results

# Reference for the table hash with column info for all tables
my $table_ref = $db->get_table_hash_ref();


# Read in parameters
my $id      = $form->param('id')      || "0"; 
my $format  = $form->param('fmt')     || "html";
my $keyword = $form->param('keyword') || "36200";
my $chr     = $form->param('chr')     || 4;
my $length  = $form->param('length')  || "short"; 
my $chr_limit = $form->param('chr_limit') || "no";
my $hmlg_limit = $form->param('hmlg_limit') || "no"; 
my %tmp = ();
my %results = (); # empty hash into which we will store the hits

# the order of things to look for
my $search_ids = 0;

# remove any RGD: tag from the start of the ID. if passed in
if( ($keyword =~ s/RGD://i) || ($keyword =~ /^(\d+|\d+\%\d*)$/)) {
  $search_ids = 1;  # they passed in an RGD ID or a plain number
  my $new_id=$keyword;
  &request($new_id);
}else{

  $html->html_head;  
  $html->tool_start;

  my $keyword_lc = lc($keyword); # convert to lowercase for subsequent queries

  &keyword_search($keyword);
  
  my %seq_join = ();
  my %sequences = ();
  
  # Delete all the hits that dont have a sequence already
  foreach my $hit (keys %results) {
    if($hit){
      $seq_join{$hit} = $db->get_seq_for_rgd_id($hit);  #DP 5-21-01
    }
    delete $results{$hit} unless $seq_join{$hit};
  }
  
  if($format =~ /text/i) {
    #skip
  }
  else {
    &display_html(\%results, \%seq_join);
  }
  
  $html->tool_end;  
  $html->html_foot;
}
exit;

########################

sub request{
my $rgd_id= shift @_;

my $agent = new LWP::UserAgent;
my $request = new HTTP::Request('GET', 
				"http://localhost/$seq_tool$rgd_id",
			       );
my $response =  $agent->request($request);
die "Couldn't get the URL. Status code =  ", $response->code
  unless $response->is_success;
print "Content-type: text/html\n\n" . $response->content;
exit;
}

sub display_html {

  my ($hits_ref, $seq_ref) = @_;
  my $number_of_hits = 0;

  #if(%$hits_ref) {
    #$number_of_hits = keys %{ $hits_ref };

    #if($number_of_hits == 112345) {
      #foreach my $rgd_id ( keys %{ $hits_ref}) {
      #&request($rgd_id); 
      #}
    #}
  #}
  
    
  #$html->html_head;  ###
  #$html->tool_start; ###
  
  if(%{$hits_ref}) {
    my $number_of_hits = keys %{ $hits_ref };
    print "Found $number_of_hits results:<BR><BR>\n";
    my %tmp = ();
    foreach my $rgd_id (sort keys %$hits_ref) {
      my ($symbol, @trash) = split "#",$hits_ref->{$rgd_id};
      $tmp{$symbol} = $rgd_id;
    }
    
    foreach my $rgd_id (sort keys %$hits_ref) {      
      my ($sym, $ssym, @trash) = split "#", $hits_ref->{$rgd_id};   
      if($ssym) {
	#print "<A HREF=\"$baseCGI/query/query.cgi?id=$rgd_id\">$ssym</A>: ";
    	print "<A HREF=\"$baseURL/generalSearch/RgdSearch.jsp?quickSearch=1&searchKeyword=$rgd_id\">$ssym</A>: ";
      }
      else {
	#print "<A HREF=\"$baseCGI/query/query.cgi?id=$rgd_id\">$sym</A>: ";
    	print "<A HREF=\"$baseURL/generalSearch/RgdSearch.jsp?quickSearch=1&searchKeyword=$rgd_id\">$sym</A>: ";
      }
      
      my @seqs = split ':', $seq_ref->{$rgd_id};
      foreach my $seq (@seqs) {
	my ($rgd,$key,$type) = split '#',$seq;
	print "<a href=\"$baseCGI/sequences/sequences_view.cgi?id=$rgd\">$type</A>&nbsp;\n";
      }
      print "<BR>\n";
    }
  }
  else {
    print "<p>Your search returned no hits<BR>";
  }
  
  print "<p><font size=-1><b>Parameters</b><BR>Keyword: $keyword<BR></font>";
 


} # end of display_html

sub keyword_search {

  my ($kw) =  @_;
  my $sql = "select rgd_id, UPPER(KEYWORD_lc) from RGD_QUERY ";
  my $kw_lc=lc($kw);
  if($kw =~ / OR /){
    my ($w1,$w2)=split(/OR/,$kw);
    $w1=lc($w1);
    $w2=lc($w2);
    $sql .= "where keyword_lc='$w1' or keyword_lc='$w2' ";
    
  }elsif($kw =~ / AND /){
    $kw =~ s/AND //g;
    my $w_lc = lc($kw);
    $sql .= "where keyword_lc='$w_lc'";
  }elsif($kw =~ /\*/){
    my $w_lc=$kw_lc;
    $w_lc =~ s/\*/%/g;
    $sql .= "where keyword_lc like '$w_lc'";
  }else{
    $sql .= "where keyword_lc = '$kw_lc'";
  }
  my ($recordcount, @ids) = $db->query_Data(2,$sql);
 
  foreach my $id (@ids){
    my @tmp = split(/\:\:/,$id);
    $results{$tmp[0]} = join "#",@tmp;
#    print "<p>$tmp[0],  $results{$tmp[0]}";
  }
}
