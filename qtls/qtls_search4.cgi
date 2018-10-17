#!/usr/bin/perl

##############################
#
# qtls_search4.cgi Simon Twigger May 2001
#
# Searches QTL tables, XML cache for results
#
##############################

##############################
# BUGS
# The LOG.pm writing seems to have broken since installation.
# 'incorrect permissions to open log file to write to it'
# Was the web user changed since then? Yes - to webm! Would have been nice to know...
#
# LOG file directory was hard-coded, changed to $toolPATH, JL
# in &display_html: replaced  with $baseURL
#
#
##############################

use lib ("/rgd/tools/common","/rgd/tools/common/RGD");

use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);
use strict;
use LWP::UserAgent;
use RGD::Log;
use RGD::XML::Cache;

my $SCRIPT_NAME = "qtls_search4.cgi";
my $VERSION = 2;
my $form = new CGI;
my $db = RGD::DB->new();

# added by JL, 01-09-2001
my $rgd = RGD::HTML->new();
my $baseURL=$rgd->get_baseURL;   # http://your.dpmain.com
my $baseCGI=$rgd->get_baseCGI;   # http://your.dpmain.com/cgi-bin
my $toolPATH=$rgd->get_toolPATH; # /fullpath/name,/rgd_home/2.0/TOOLS
my $dataPATH=$rgd->get_dataPATH; # /fullpath/name,/rgd_home/2.0/DATA
my $logPATH=$rgd->get_logPATH; # /fullpath/name,/rgd_home/2.0/LOGS
### END by JL ###

# Reference for the table hash with column info for all tables
my $table_ref = $db->get_table_hash_ref();


my %QUERY_URLS = (
		  GENES => "$baseCGI/genes/genes_view.cgi?id=",
		  SSLPS => "$baseCGI/sslps/sslps_view.cgi?id=",
		  QTLS => "$baseCGI/qtls/qtls_view.cgi?id=",
		  
		 );

my $LOG = RGD::Log->new(
			log_directory => "$logPATH/qtls",
			log_file => 'qtls_search',
			script_name   => 'qtls_search4.cgi',
			script_version => 1,
		       );

# Read in parameters
my $id      = $form->param('id')      || 0; #die "No ID value was provided\n";
my $format  = $form->param('fmt')     || "html";
my $keyword = $form->param('keyword') || "";
my $chr     = $form->param('chr')     || "any"; #4;
my $traits  = $form->param('traits')     || "any"; #4;
my $lod     = $form->param('lod_limit') || 0;

my $length  = $form->param('length')  || "short"; # Do we show all the strain characteristics and stuff
my $search_fields = $form->param('search_fields')  || "no";
my $order   = $form->param('order') || "symbol"; # How to order the results of the search

my $hmlg_limit = $form->param('hmlg_limit') || "no";
my $sslp_limit = $form->param('sslp_limit') || "no";
my $match_type = $form->param('match_type') || "equals";

my %tmp = ();

##############
# New code to try cacheing the data sets that are returned in an XML file
##############

my $num_hits = $form->param('num_hits') || 25; # number of hits to display if
my $page = $form->param('page'); # which page/file to display, if 0 this is the original search
my $pid = $form->param('pid') || $$;  # process ID of the original CGI script to ID file

my $cache_file = $form->param('cache') || "none";
if($cache_file =~ /\./) {
  ($pid,$num_hits) = split /\./,$cache_file; # Reset these values based on cache file data
}

my $new_cache_file = $form->param('cache') || $pid . ".$num_hits";

my %params = $form->Vars;

my $cache_dir = "$dataPATH/cache_files/qtls/";
my $cache = RGD::XML::Cache->new(
                                 base_url    => $baseURL,
				 page_length => $num_hits,
				 cache_directory => $cache_dir,
				 cache_file => $pid . ".$num_hits",
				 script_dir => "$baseCGI/qtls/",
				 script_name => $SCRIPT_NAME,
				 script_version => $VERSION,
				 order_field => $order,
				 parameters => \%params, # get the CGI form parameter list as a hash
				);

# if we have been passed a cache file name, load that file and display, no searching needed
if($cache_file ne "none") {
  # read in the file
  my $cache_el = $cache->retrieve_cache_file($cache_file);
  
  if(!$cache_el) {
    &rerun_search();
  }
  else {   
    # pass it to display_html
    &display_html($cache_el);
  }
  
  # exit
  exit;
}

###############
# End of Cache Specific Code
###############

my %object_status_limit_sql = (
			   symbols => " and q.object_status = 'ACTIVE' ",
			   symbols_names => " and q.object_status = 'ACTIVE' ",
			   active_retired => " and q.object_status in ('ACTIVE','RETIRED')",
			   all_with_aliases => " and q.object_status in ('ACTIVE','RETIRED')", 
			  );

my %order_sql = (
		 symbol => "q.qtl_symbol",
		 name => "q.qtl_name",
		 chromosome => "q.chromosome, q.qtl_symbol",
		 lod => "q.lod",
		 p_value => "q.p_value",
		 );


# the order of things to look for
my $search_ids = 0;

$keyword =~ s/\*/\%/g;

# remove any RGD: tag from the start of the ID. if passed in
if( ($keyword =~ s/RGD://i) || ($keyword =~ /^(\d+|\d+\%\d*)$/)) {
 $search_ids = 1;  # they passed in an RGD ID or a plain number, look for an RGD_ID match first.
}

my $keyword_lc = lc($keyword); # convert to lowercase for subsequent queries



my %results = (); # empty hash into which we will store the hits
my $search_aliases = 0;
my $order_num = 0;

&rgd_qtl_symbol_search($keyword_lc, \%results);

if($search_fields eq "all_with_aliases") {
  # third, search gene aliases if we have no hits up to now
  $search_aliases = 1; # set the aliase search flag and research
  &rgd_qtl_symbol_search($keyword_lc, \%results);
}


$LOG->add_entry(
		input_parameters => {
				     id         => $id || 'null',
				     keyword    => $keyword || 'null',
				     chrs       => $chr || 'null',
				     hmlg_limit => $hmlg_limit || 'null',
				     sslp_limit => $sslp_limit || 'null',
				     format     => $format || 'null',
				    },
		output_parameters => {
				      num_hits => scalar keys %{$results{QTLS}},
				     },
	       );


if($format =~ /text/i) {
  
}
else {
  my $page_1_el = $cache->create_cache_file(\%{$results{QTLS}});
  &display_html($page_1_el);
}
exit;

exit;

########################  

sub display_html {

  my $el_ref = shift @_;

 
  my $html = RGD::HTML->new(
			    title      => "RGD QTL Search Report",
			    doc_title  => "QTL Search Report",
			    version    => "2.0",
			    link_dir   => "qtls",
			   );
  my $number_of_hits = 0;

# Now we have XML hits so parse the cache page tree for row elements
  use XML::Simple;
  my $simple= new XML::Simple;
  
  my $ref = $simple->XMLin(
			   $el_ref->toString,
			   suppressempty => '',
			   forcearray => ['row'],
			   keyattr => "number",
			  );

  my @row_list = $el_ref->getElementsByTagName("row");
  my $current_page = $ref->{number};
  my $next_page = $ref->{next}->{page} || "0";
  my $prev_page = $ref->{previous}->{page} || "0";
  my $page_length = $ref->{page_length} || "0";
  my $total_num_records = $ref->{number_of_hits};
  my $total_num_pages = $ref->{total_pages};
  
  use Data::Dumper;
  warn Dumper($ref);
  
  $html->html_head;
  $html->tool_start;
 
   if($total_num_records >= 1) {

    my $first_hit_number = (($current_page -1) * $page_length)+1;
    my $last_hit_number = (($current_page) * $page_length);
    
    if($total_num_records < $last_hit_number) {
      $last_hit_number = $total_num_records;
    }
    
    print "Found $total_num_records hits, showing $first_hit_number to $last_hit_number (Page $current_page of $total_num_pages) $#row_list entries\n";
    print "<table cellspacing=\"5\" cellpadding=\"3\">";
    
    my $nav_html = $cache->create_html_navbar(
					      current => $current_page,
					      next => $next_page,
					      prev => $prev_page,
					      total_pages => $total_num_pages,
					      total_hits => $total_num_records
					     );    

    if($ref->{parameters}->{search_fields} =~ /aliases/) {
      print "<TR><TD colspan=\"7\" align=\"center\">$nav_html</TD></TR>";
      print "<TR><TD><b>#</b></TD><TD><b>Symbol</b></TD><TD><b>LOD</b></TD><TD><b>Alias</b></TD><TD><b>Chr</b></TD><TD><b>Name</b></TD><TD><b>Trait</b></TD></TR>\n";
    }
    else {
      print "<TR><TD colspan=\"6\" align=\"center\">$nav_html</TD></TR>";
      print "<TR><TD><b>#</b></TD><TD><b>Symbol</b></TD><TD><b>LOD</b></TD><TD><b>Chr</b></TD><TD><b>Name</b></TD><TD><b>Trait</b></TD></TR>\n";
    }
    
    my $r_count = $first_hit_number;
    
    foreach my $row (sort keys %{$ref->{row}}) {
      
      warn "Key: $row\n";
      $r_count = &print_row(
			    \%{$ref->{row}->{$row}},
			    $r_count,
			    $ref->{parameters}->{search_fields}
			   );
    }
    
    if($ref->{parameters}->{search_fields} =~ /aliases/) {
      print "<TR><TD colspan=\"7\">$nav_html</TD></TR>";
    }
    else {
      print "<TR><TD colspan=\"6\">$nav_html</TD></TR>";
    }
    print "</table>\n";
    
  }
  else { # search returned no hits
    
    print "No Hits were found";
    
  }
  
  # &print_search_parameters_table();
  
  print "<p><FONT SIZE=-1><b>Parameters</b>:<BR>Keyword: $keyword<BR>Total Hits: $total_num_records<BR></FONT>";
 
  $html->tool_end;
  $html->html_foot;


} # end of display_html


sub print_row {

  my ($rref,$r_count,$search_fields) = @_;
  
  ################
  # Handle retired objects, display Symbols and links to replacements if available
  ###############
  
  if($rref->{status} ne "ACTIVE") {
    if($rref->{status} eq "RETIRED") {
      # Get the history data for this object
      my @new_ids = &get_history($rref->{rgd_id});
      
      # Got list of new IDs, now need to get symbols and make link
      my $symbol_list= "";
      
      $rref->{name}= ""; # clear this entry then add to it from new symbols
      for my $new (0 .. $#new_ids) {
	my %symbols = $db->get_rgd_id_symbol($new_ids[$new]);
	$rref->{name} .= "<p><i>Object Replaced by <a href=\"$QUERY_URLS{GENES}$new_ids[$new]\">$symbols{$new_ids[$new]}{symbol}</a> (RGD:$new_ids[$new])</i></P>\n";
      }
      
    }
    else {
      $rref->{name} = "Withdrawn, no replacement object";
    }
  }
  ################
  # End of retirement handling
  ###############
  
  my $view_script_url = "$baseCGI/qtls/qtls_view.cgi?id=" . $rref->{rgd_id};
  
  if($search_fields =~ /aliases/) {
    print "<TR><TD>$r_count</TD>
<TD><a href=\"$view_script_url\">$rref->{symbol}</a></TD>
<TD>$rref->{lod}</TD>
<TD>$rref->{alias}</TD>
<TD>$rref->{chromosome}</TD>
<TD>$rref->{name}</TD>
<TD>$rref->{trait}</TD>
</TR>\n";
  }
  else {
    print "<TR><TD>$r_count</TD>
<TD><a href=\"$view_script_url\">$rref->{symbol}</a></TD>
<TD>$rref->{lod}</TD>
<TD>$rref->{chromosome}</TD>
<TD>$rref->{name}</TD>
<TD>$rref->{trait}</TD>
</TR>\n";
  }
  
  $r_count++;
  return $r_count;
}


sub rgd_qtl_symbol_search {

  my ($id, $hash_ref ) =  @_;
  my $sql = "";
  my $chr_sql = "";
  my $name_sql ="";
  #my $trait_limit ="";
  #my $lod_limit ="";
  #my $object_status_limit_sql ="";
  #my $order_sql{$order} ="";
  #my $query =""; 
  #my $name_sql ="";
  #my $trait_limit =""; 
  #my $lod_limit =""; 
  #my $object_status_limit_sql ="";
  my $search_fields ="";
  
  # $id = '%transporter%';
  
  
  my $query = "";
  unless($search_fields eq "symbols") {
    if($match_type eq "equals") {
      $name_sql = " or qtl_name_lc like '$id'"
    }
    elsif($match_type eq "contains") {
      $name_sql = " or qtl_name_lc like '%$id%'";
    }
    elsif($match_type eq "begins") {
      $name_sql = " or qtl_name_lc like '$id%'";
    }
    elsif($match_type eq "ends") {
      $name_sql = " or qtl_name_lc like '%$id'";
    }
  }
  
  my $trait_limit = "";
  if($traits ne "any") {
    $trait_limit = " q.trait_name = '$traits' ";
  }
  else {
    $trait_limit = " q.trait_name is not null ";
  }
  
  my $lod_limit = "";
  if($lod > 0) {
    $lod_limit = " and q.lod >= $lod ";
  }
  
  if($match_type eq "equals") {
    $query = "like '$id'"
  }
  elsif($match_type eq "contains") {
    $query = "like '%$id%'";
  }
  elsif($match_type eq "begins") {
    $query = "like '$id%'";
  }
  elsif($match_type eq "ends") {
    $query = "like '%$id'";
  }
  
  my $std_sql = "select q.rgd_id, q.qtl_symbol,q.qtl_name, q.chromosome, q.object_status, q.trait_name, q.lod, q.p_value";
  
  if($search_ids) {
    $sql = $std_sql . "from qtls_search_view q where q.rgd_id $query and $trait_limit $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  elsif($search_aliases) {
    $sql = $std_sql . ", a.alias_value from qtls_search_view q, aliases a
where a.alias_value_lc $query
and q.rgd_id = a.rgd_id
and $trait_limit $lod_limit
$object_status_limit_sql{$search_fields} ";
  }
  elsif(!$id) {
    $sql = $std_sql . " from qtls_search_view q where $trait_limit $lod_limit $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  else {
    $sql = $std_sql . " from qtls_search_view q where (q.qtl_symbol_lc $query $name_sql) and $trait_limit $lod_limit $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  #print "Content-type: text/html\n";
  
 # open (OUT, ">qtl_sql_error.txt")|| die "Can't open the variable_value.txt : $!";
  print OUT "test\n";
  print OUT "$sql\n";
  
  warn $sql;
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute() or die "Can't execute statement: $DBI::errstr";
  
 HIT_LOOP:
  while ( my ($rgd_id, $symbol, $name, $chrom, $status, $trait,$lod,$p_value,$alias) = $sth->fetchrow_array() ) {
    $order_num += 1;
    if(!$chrom) { $chrom = " UN "; }
    if(!$alias) { $alias = " - "; }
    
    use Math::BigFloat;
    
    if($p_value) {
      #$p_value = log(1/$p_value);
      $p_value = "p<0". $p_value;
    }
    
    if($chr eq "any") {
      $hash_ref->{QTLS}{$rgd_id}{rgd_id} = $rgd_id;
      $hash_ref->{QTLS}{$rgd_id}{symbol} = $symbol;
      $hash_ref->{QTLS}{$rgd_id}{name} = $name;
      $hash_ref->{QTLS}{$rgd_id}{chromosome} = $chrom;
      $hash_ref->{QTLS}{$rgd_id}{status} = $status;
      $hash_ref->{QTLS}{$rgd_id}{alias} = $alias;
      $hash_ref->{QTLS}{$rgd_id}{trait} = $trait;
      $hash_ref->{QTLS}{$rgd_id}{lod} = $lod || $p_value || " - ";
      $hash_ref->{QTLS}{$rgd_id}{order} = $order_num unless $hash_ref->{QTLS}{$rgd_id}{order}
    }
    elsif ($chrom eq $chr) {
      $hash_ref->{QTLS}{$rgd_id}{rgd_id} = $rgd_id;
      $hash_ref->{QTLS}{$rgd_id}{symbol} = $symbol;
      $hash_ref->{QTLS}{$rgd_id}{name} = $name;
      $hash_ref->{QTLS}{$rgd_id}{chromosome} = $chrom;
      $hash_ref->{QTLS}{$rgd_id}{status} = $status;
      $hash_ref->{QTLS}{$rgd_id}{alias} = $alias;
      $hash_ref->{QTLS}{$rgd_id}{trait} = $trait;
      $hash_ref->{QTLS}{$rgd_id}{lod} = $lod || $p_value || " - ";
      $hash_ref->{QTLS}{$rgd_id}{order} = $order_num unless $hash_ref->{QTLS}{$rgd_id}{order}
    }
  }
  #th->execute() or die "Can't execute statement: $DBI::errstr";
  $sth->finish; 
  
  
}



##########
#
# get_history - returns rgd_ids for retired objects
#
##########

sub get_history {

  my $id = shift @_;
  my $sql = "select new_rgd_id from rgd_id_history where old_rgd_id = ?";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($id) or die "Can't execute statement: $DBI::errstr";
  
  my @rows =  ();

  while(my $new_id = $sth->fetchrow_array()) {

    push @rows,$new_id;
  }
  
  # print "Found: @rows\n";

  return @rows;
}

######
#
# Detect Expired Cache files and Allow user to do something appropriate like rerun
# the search from the parameter data stored in the original document.
#
######

sub rerun_search {

  # Cache file has been deleted, tell user and ask if they want to rerun the search - maybe later!

  my $html = RGD::HTML->new(
			    title      => "Cache file expired",
			    doc_title  => "Cache file expired",
			    version    => "1.0",
			    link_dir   => "qtls",
			   );
  $html->html_head;
  $html->tool_start;
  
  # print "<h4>QTL Search Cache file expired</h4>";
  print "<p>The original file containing your search results has expired:\n";

  print "</UL>\n";
  

  $html->tool_end;
  $html->html_foot;

}

__END__
