#!/usr/bin/perl

##############################
#
# sslps_search3.cgi Simon Twigger May 2001
#
# Displays the SSLP report for a given SSLP ID
#
##############################

##############################
#
# Added in the SSLP limiting function - ST 7/12/00
# Fixed the gene name search function using full_name_lc attribute - ST 10/27/00
#
#
##############################
# BUGS
# The LOG.pm writing seems to have broken since installation.
# 'incorrect permissions to open log file to write to it'
# Was the web user changed since then? Yes - to webm! Would have been nice to know...
#
# LOG file directory was hard-coded, changed to $logPATH, JL
# in &display_html: replace fuxi.ifrc.mcw.edu with $baseURL
#
#
##############################

use lib '/rgd/tools/common';
use lib '/rgd/tools/common/RGD';
use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);
use strict;
use LWP::UserAgent;
use RGD::Log;
use RGD::XML::Cache;

my $SCRIPT_NAME = "sslps_search4.cgi";
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

my %QUERY_URLS = (
		  GENES => "$baseCGI/genes/genes_view.cgi?id=",
		  SSLPS => "$baseCGI/sslps/sslps_view.cgi?id=",
		 );

my $LOG = RGD::Log->new(
			log_directory => "$logPATH/sslps",
			log_file => 'sslps_search',
			script_name   => 'sslps_search3.cgi',
			script_version => 1,
		       );

# Read in parameters
my $id      = $form->param('id')      || 0; #die "No ID value was provided\n";
my $format  = $form->param('fmt')     || "html";
my $keyword = $form->param('keyword') || "";
my $chr     = $form->param('chr')     || "any"; #4;
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

my $cache_dir = "$dataPATH/cache_files/sslps";
my $cache = RGD::XML::Cache->new(
                                 base_url    => $baseURL,
				 page_length => $num_hits,
				 cache_directory => $cache_dir,
				 cache_file => $pid . ".$num_hits",
				 script_dir => "$baseCGI/sslps/",
				 script_name => $SCRIPT_NAME,
				 script_version => $VERSION,
				 order_field => $order,
				 parameters => \%params, # get the CGI form parameter list as a hash
				 object => "sslps",
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
			   symbols => "s.object_status = 'ACTIVE' ",
			   symbols_names => "s.object_status = 'ACTIVE' ",
			   active_retired => "s.object_status in ('ACTIVE','RETIRED')",
			   all_with_aliases => "s.object_status in ('ACTIVE','RETIRED')", 
			  );

my %order_sql = (
		 symbol => "s.rgd_name",
		 name => "s.expected_size",
		 chromosome => "s.chromosome, s.rgd_name",
		 );


# the order of things to look for
my $search_ids = 0;

$keyword =~ s/\*/\%/g;
# $keyword = '%' . $keyword;

# remove any RGD: tag from the start of the ID. if passed in
if( ($keyword =~ s/RGD://i) || ($keyword =~ /^(\d+|\d+\%\d*)$/)) {
 $search_ids = 1;  # they passed in an RGD ID or a plain number, look for an RGD_ID match first.
}

my $keyword_lc = lc($keyword); # convert to lowercase for subsequent queries



my %results = (); # empty hash into which we will store the hits
my $search_aliases = 0;
my $order_num = 0;

&rgd_sslp_symbol_search($keyword_lc, \%results);

if(($search_fields eq "all_with_aliases") && ($keyword_lc)) {
  # third, search gene aliases if we have no hits up to now
  $search_aliases = 1; # set the aliase search flag
  rgd_sslp_symbol_search($keyword_lc, \%results);
}

if($sslp_limit eq "yes") {
  my %things_with_sslps = &rgd_sslp_w_gene_list;
  
  foreach my $rid (keys %{$results{SSLPS}} ) {
    # remove the entry if this rgd_id doesnt have an associated SSLP
    delete $results{SSLPS}{$rid} unless $things_with_sslps{$rid};
  }
  
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
				      num_hits => scalar keys %{$results{SSLPS}},
				     },
	       );


if($format =~ /text/i) {
  
}
else {
  my $page_1_el = $cache->create_cache_file(\%{$results{SSLPS}});
  &display_html($page_1_el);
}
exit;

########################  

sub display_html {
  
  my $el_ref = shift @_;
 
  my $html = RGD::HTML->new(
			    title      => "RGD SSLP Search Report",
			    doc_title  => "SSLP Search Report",
			    version    => "1.0",
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
    
  $html->html_head;
  $html->tool_start;
 
   if($total_num_records >= 1) {

    my $first_hit_number = (($current_page -1) * $page_length)+1;
    my $last_hit_number = (($current_page) * $page_length);
    
    if($total_num_records < $last_hit_number) {
      $last_hit_number = $total_num_records;
    }
    
    print "Found $total_num_records hits, showing $first_hit_number to $last_hit_number (Page $current_page of $total_num_pages)\n";
    print "<table cellspacing=\"5\" cellpadding=\"3\">";
    
    my $nav_html = $cache->create_html_navbar(
					      current => $current_page,
					      next => $next_page,
					      prev => $prev_page,
					      total_pages => $total_num_pages,
					      total_hits => $total_num_records
					     );    
   
      print "<TR><TD colspan=\"3\" align=\"center\">$nav_html</TD></TR>";
      print "<TR><TD><b>#</b></TD><TD><b>Symbol</b></TD><TD><b>Chr</b></TD></TR>\n";

    
    my $r_count = $first_hit_number;
    foreach my $row (sort keys %{$ref->{row}}) {

      ################
      # Handle retired objects, display Symbols and links to replacements if available
      ###############
      
      if($ref->{row}->{$row}->{status} ne "ACTIVE") {
	if($ref->{row}->{$row}->{status} eq "RETIRED") {
	  # Get the history data for this object
	  my @new_ids = &get_history($ref->{row}->{$row}->{rgd_id});
	  
	  # Got list of new IDs, now need to get symbols and make link
	  my $symbol_list= "";
	  
	  $ref->{row}->{$row}->{name}= ""; # clear this entry then add to it from new symbols
	  for my $new (0 .. $#new_ids) {
	    my %symbols = $db->get_rgd_id_symbol($new_ids[$new]);
	    $ref->{row}->{$row}->{name} .= "<p><i>Object Replaced by <a href=\"$QUERY_URLS{SSLPS}$new_ids[$new]\">$symbols{$new_ids[$new]}{symbol}</a> (RGD:$new_ids[$new])</i></P>\n";
	  }
	  
	}
	else {
	  $ref->{row}->{$row}->{name} = "Withdrawn, no replacement object";
	}
      }
      ################
      # End of retirement handling
      ###############
      
      my $view_script_url = "$baseCGI/sslps/sslps_view.cgi?id=" . $ref->{row}->{$row}->{rgd_id};
      
      my $alias_text = "";
      if($ref->{row}->{$row}->{alias} != "") {
	$alias_text = " ($ref->{row}->{$row}->{alias})";
      }

	print "<TR><TD>$r_count</TD><TD><a href=\"$view_script_url\">$ref->{row}->{$row}->{symbol}</a>$alias_text</TD><TD>$ref->{row}->{$row}->{chromosome}</TD></TR>\n";

      
      $r_count++;
    }
    if($ref->{parameters}->{search_fields} =~ /aliases/) {
      print "<TR><TD colspan=\"5\">$nav_html</TD></TR>";
    }
    else {
      print "<TR><TD colspan=\"4\">$nav_html</TD></TR>";
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



sub rgd_sslp_symbol_search {

  my ($id, $hash_ref ) =  @_;
  my $sql = "";
  my $chr_sql = "";
  my $name_sql ="";
  my $query = "";

  # Currently no SSLP Name field

  #unless($search_fields eq "symbols") {
#    if($match_type eq "equals") {
#      $name_sql = " or full_name_lc like '$id'"
#    }
#    elsif($match_type eq "contains") {
#      $name_sql = " or full_name_lc like '%$id%'";
#    }
#    elsif($match_type eq "begins") {
#      $name_sql = " or full_name_lc like '$id%'";
#    }
#    elsif($match_type eq "ends") {
#      $name_sql = " or full_name_lc like '%$id'";
#    }
#  }

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

  if($search_ids) {
    $sql = "select s.rgd_id, s.rgd_name,s.expected_size, s.chromosome, s.object_status from sslps_search_view where s.rgd_id $query and $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  elsif($search_aliases) {
    $sql = "select a.rgd_id, s.rgd_name,s.expected_size, s.chromosome, s.object_status, a.alias_value from sslps_search_view s, aliases a
where a.alias_value_lc $query
and a.alias_type_name_lc in('sslp_assay_name')
and s.rgd_id = a.rgd_id
and $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  elsif(!$id) {
    $sql = "select s.rgd_id, s.rgd_name, s.expected_size, s.chromosome, s.object_status from sslps_search_view s where $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  else {
    $sql = "select s.rgd_id, s.rgd_name, s.expected_size, s.chromosome, s.object_status from sslps_search_view s where (rgd_name_lc $query $name_sql) and $object_status_limit_sql{$search_fields} order by $order_sql{$order}";
  }
  # warn $sql;
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute() or die "Can't execute statement: $DBI::errstr";
  
 HIT_LOP:
  while ( my ($rgd_id, $symbol, $exp_size, $chrom, $status, $alias) = $sth->fetchrow_array() ) {
    next HIT_LOOP if $hash_ref->{GENES}{$rgd_id}; # Ignore duplicates
    $order_num += 1;
    
    if(!$chrom) { $chrom = "UN"; }
    if(!$exp_size) {
      $exp_size = " - ";
    }
    else {
      $exp_size .= " bp";
    }

    if($chr eq "any") {      
      $hash_ref->{SSLPS}{$rgd_id}{rgd_id} = $rgd_id;
      $hash_ref->{SSLPS}{$rgd_id}{symbol} = $symbol;
      $hash_ref->{SSLPS}{$rgd_id}{name} = $exp_size;
      $hash_ref->{SSLPS}{$rgd_id}{chromosome} = $chrom;
      $hash_ref->{SSLPS}{$rgd_id}{status} = $status;
      $hash_ref->{SSLPS}{$rgd_id}{alias} = $alias || "";
      $hash_ref->{SSLPS}{$rgd_id}{order} = $order_num unless $hash_ref->{SSLPS}{$rgd_id}{order}
    }
    elsif ($chrom == $chr) {      
      $hash_ref->{SSLPS}{$rgd_id}{rgd_id} = $rgd_id;
      $hash_ref->{SSLPS}{$rgd_id}{symbol} = $symbol;
      $hash_ref->{SSLPS}{$rgd_id}{name} = $exp_size;
      $hash_ref->{SSLPS}{$rgd_id}{chromosome} = $chrom;
      $hash_ref->{SSLPS}{$rgd_id}{status} = $status;
      $hash_ref->{SSLPS}{$rgd_id}{alias} = $alias || "";
      $hash_ref->{SSLPS}{$rgd_id}{order} = $order_num unless $hash_ref->{SSLPS}{$rgd_id}{order}
    }
  }
  $sth->finish; 
  
  
}



sub rgd_sslp_w_gene_list {
  
  my $sql = "select s.rgd_id, ss.gene_key, s.sslp_key, g.gene_symbol,g.rgd_id from sslps s, rgd_gene_sslp ss, genes g where s.sslp_key = ss.sslp_key and ss.gene_key=g.gene_key";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute() or die "Can't execute statement: $DBI::errstr";
  
  my %results = ();
  
  while (my ($sslp_rgd_id,$gene_key,$sslp_key,$gene_symbol,$gene_rgd_id) = $sth->fetchrow_array()) {
    
   $results{$sslp_rgd_id}{g_symbol} = "$gene_symbol";
   $results{$sslp_rgd_id}{g_rgd_id} = "$gene_rgd_id";
  }
  
  return %results
  
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
			   );
  $html->html_head;
  $html->tool_start;
  
  # print "<h4>SSLP Search Cache file expired</h4>";
  print "<p>The original file containing your search results has expired.\n";

  $html->tool_end;
  $html->html_foot;

}

__END__
