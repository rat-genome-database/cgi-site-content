#!/usr/bin/perl

##############################
#
# genes_view.cgi Simon Twigger May 2000
#
# Displays the Gene report for a given Gene RGD ID
#
#
##############################

##############################
# Bug Fixes and Improvements
##############################
#
# 9/8/00  Added in SSLP map location table into the Mapping Data section [ST]
# 9/11/00 Altered Map location table to look nicer! Need to move to DB.pm
# 10/18.01 - Added in Gene Brief display script (ST)
# 12/4/01 - Added in GO report, Product and Function reports
# 12/5/01 - updated to use $baseCGI and $baseURL
#
##############################
use lib "/rgd/tools/common";
use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);
use strict;

my $VERSION = 1.1; # New version 1.1 9/8/00
my $form = new CGI;

my $db = RGD::DB->new();

my $html = RGD::HTML->new(
                          title => "RGD Gene Report",
                          doc_title  => "",
                          link_dir   => "genes",
			  category  => "data",
                         ); 

my $baseURL= $html->get_baseURL;
my $baseCGI= $html->get_baseCGI;
my $baseDATA=$html->get_dataPATH;

my $QUERY_URL = "$baseCGI/query/query.cgi?id=";

# Reference for the table hash with column info for all tables
my $table_ref = $db->get_table_hash_ref();

my %ref_list = ();
my %ref_data = ();

# Read in parameters
my $id      = $form->param('id')  || 2018; #die "No ID value was provided\n";
my $format  = $form->param('fmt') || "html";
my $keyword = $form->param('kwd') || "";
my $length  = $form->param('length') || "short"; # Do we show all the gene data

# remove any RGD: tag from the start of the ID
$id =~ s/RGD://;

# Assume the ID is a gene for the moment... =)

my @data = &get_gene_data($id);
# Get the Reference information for the ID
my @rgd_ids = ($id);
$db->get_rgd_id_refs(\%ref_list, \%ref_data, @rgd_ids);


if(!@data) {
  # HTML error about strain not found
  exit;
}

if($format =~ /text/i) {

}
else {
  &display_html(\@data);
}

exit;

########################

sub display_html {

  my $data_ref = shift @_;

  my @columns = split ',',$table_ref->{genes}{select};
  my %data = ();

  for my $i (0 .. $#columns) {
    if ($data_ref->[$i]) {
      $data{$columns[$i]} = $data_ref->[$i];
    }
    else {
      $data{$columns[$i]} = "";
    }

    # print "$columns[$i] \t $data{$columns[$i]} \n";

  }


  my $title="Gene"; #used to display type of gene on report (ex: gene, splice, allele, predicted, etc.)
  my $type;
  my %parent_genes = &get_gene_type($data{gene_key});
  my $parents = "";
  my @confidence = ();
  if(%parent_genes) {
    foreach my $var (sort keys %parent_genes) {
      $type=$parent_genes{$var}{'type'};
      if ($parent_genes{$var}{'type'} eq "splice"){
	$title="Variant";
      }
      elsif ($parent_genes{$var}{'type'} eq "allele"){
	$title="Allele";
      }
      #elsif ($parent_genes{$var}{'type'} eq "predicted"){ #DP 7-19-04
      #	$title="Predicted Gene";
      #}
      # Jiali 1/5/05.    
      elsif ($parent_genes{$var}{'type'} =~ /predicted.*/) {
         $title="Predicted Gene";
      }
      else {
	$title="Gene";
      }
      
    }
  }
 
  @confidence = split(/\-/,$type);
  my $html = RGD::HTML->new(title => "RGD Reference Report: $data{gene_symbol}",
                            doc_title => "Reference Report for $data{gene_symbol}",
                            version   => "1.0",
                            link_dir  => "genes",
                           );

  $html->html_head;
  $html->tool_start;

  # Jiali 01/05/05
  &javascript;


  my %aliases = $db->get_rgd_id_alias($id);
  my $alias_name = "";
  my $alias_symbol = "";
 
  if ($aliases{$id}) {

    foreach my $key (keys %{ $aliases{$id}}) {

      if($aliases{$id}{$key}{alias_type_name_lc} eq "old_gene_symbol" ) {
	$alias_symbol .= "$aliases{$id}{$key}{alias_value}; "; #DP 7-16-02
      }
      else {
	$alias_name .= "$aliases{$id}{$key}{alias_value}; ";#DP 7-16-02
      }
    }
   chop     $alias_symbol;  #DP 7-16-02
   chop     $alias_name;    #DP 7-16-02
  }

  #
  # Added ST 5/30/02 to display splice variant information and
  # detect/show if this gene is a splice variant of another gene
  #

  my %parent_genes = &get_parent_gene($data{gene_key});
  my $parents = "";
  if(%parent_genes) {
  	$parents = "($title of ";
    foreach my $var (sort keys %parent_genes) {
      my $url = "$baseCGI/genes/genes_view.cgi?id=$parent_genes{$var}";
      $parents .= "<a href=\"$url\">$var</a>";
    }
    $parents .= ")";
  }
 

  print "<HR>\n";
  
  # Add in the main RGD stylesheet
  print '<link rel="stylesheet" type="text/css" href="/common/style/rgd_styles.css">';
  
  print "<p><table>\n";
  
  if($confidence[1]) {
    print "<tr valign=\"top\"><td><b>Predicted Confidence</b>:</td><td>$confidence[1]</td></tr>"; 
  }
  
   # print "<tr valign=\"top\"  class=\"sectionHead\"><td colspan=\"3\">Summary</td></tr>";
  print "<tr valign=\"top\"><td class=\"subsectionTitle\"><b>Gene</b>:</td><td ><span class=\"objectSymbol\"><a href=\"/tools/genes/genes_view.cgi?id=$id\">$data{gene_symbol}</a> - $data{full_name}</span></td></tr>";

#####
#
# Check to see if the Gene has been retired/withdrawn
#
#####

  if($data_ref->[9] ne "ACTIVE") {
    print "<tr valign=\"top\"><td><b>Status</b>:</td>";
    if($data_ref->[9] eq "RETIRED") {
      
      # Get the history data for this object
      my @new_ids = &get_history($id);
      
      # Got list of new IDs, now need to get symbols and make link
      my $symbol_list= "";

      for my $new (0 .. $#new_ids) {
	my %symbols = $db->get_rgd_id_symbol($new_ids[$new]);
	$symbol_list .= "<li>Replaced by <a href=\"$QUERY_URL$new_ids[$new]\">$symbols{$new_ids[$new]}{symbol}</a> (RGD:$new_ids[$new])</li>\n";
      }


      print "<td>RETIRED<ul>$symbol_list</UL></td></tr></table>";
      print "<h3>Nomenclature for $data{gene_symbol}</h3>\n";
      print "<P>" . $html->get_nomen_html(\$db,$id,"ORIGINAL");
    }
    else {
      print "<tr><td>Withdrawn, no replacement object</td></tr></table>";

      print "<h3>Nomenclature for $data{gene_symbol}</h3>\n";
      print "<P>" . $html->get_nomen_html(\$db,$id);

    }
  }


#
# Gene entry is still active so display as normal
#
  else {
    
  # print "<tr valign=\"top\"><td class=\"subsectionTitle\"><b>Name</b>:</td><td>$data{full_name}</td></tr>";
   print "<tr valign=\"top\"><td class=\"subsectionTitle\"><b>Description</b>:</td><td>$data{gene_desc}</td></tr>" if $data{gene_desc}; #dp 9-23-03
	print "<tr><td colspan=\"3\">&nbsp;</td></tr>";

 print "<tr><td colspan=2>&nbsp;</td></tr>"; 
  print qq[<tr class=\"sectionHead\"><td colspan=3><img src=\"/objectSearch/images/icon-r.gif\">&nbsp;<a name=\"References\" id=\"References\">References</a></td></tr>];
  
  	  print qq[<tr valign="top"><td class="subsectionTitle">Curated References</td><td>];
  
  print $html->get_citation_html(\$db,$id);
  
   print qq[</td></tr>];
 	 # Do references - PubMed
   print qq[<tr valign="top"><td class="subsectionTitle">Other References</td><td>];

  my @pubmed_ids = &get_uncurated_pubmed_ids($id);
  if($#pubmed_ids >= 0) {
    my $ref_list = join(',', @pubmed_ids);
    my $number_of_refs = $#pubmed_ids+1;
    my $url_retrieve_pubmed = "https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=PubMed&dopt=Summary&list_uids=" .   $ref_list . "&";
	print "<span class=\"xdbRow\" style='padding-left:8px;padding-right:4px;margin-left:4px;'>";
    print qq[<A HREF=\"$url_retrieve_pubmed">$number_of_refs other references</A> at PubMed related to $data{gene_symbol}];
	print '</span>';
  }  	
  
  print "</td></tr>\n";
  print '</table>';
  print "<!-- End of References  section -->\n";
} # end of active gene object report

  $html->tool_end;
  $html->html_foot;


} # end of display_html


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


sub get_gene_data {

  my $id = shift @_;

  my $cols = $table_ref->{genes}{select};
  $cols =~ s/,/,g./g;
  $cols = "g.".$cols;

  my $sql = "select $cols, r.object_status from rgd_ids r, genes g where r.rgd_id = ? and r.rgd_id = g.rgd_id";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($id) or die "Can't execute statement: $DBI::errstr";
  
  my @rows =  $sth->fetchrow_array();
  
  #warn "Found: @rows\n";

  return @rows;
}

sub get_candidate_qtls {
  
  my $gene_key = shift @_;

  my %results = ();

  my $sql = "select r.qtl_key, q.qtl_symbol, q.qtl_name, q.rgd_id from rgd_gene_qtl r, qtls q 
 where r.gene_key = ? and q.qtl_key = r.qtl_key";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($gene_key) or die "Can't execute statement: $DBI::errstr";
  
  while (my ($qtl_key,$qtl_symbol,$name, $rgd_id)  =  $sth->fetchrow_array() ) {
    $results{$rgd_id}{qtl_key} = $qtl_key;
    $results{$rgd_id}{qtl_symbol} = $qtl_symbol;
    $results{$rgd_id}{qtl_name} = $name;
  }

  return %results;

}

sub get_gene_sslps {

  my $gene_key = shift @_;

  my %results = ();

  my $sql = "select g.gene_key, g.sslp_key, s.rgd_name, s.rgd_id
              from rgd_gene_sslp g, sslps s
 where g.gene_key = ? and s.sslp_key = g.sslp_key";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($gene_key) or die "Can't execute statement: $DBI::errstr";
  
  while (my ($gene_key,$sslp_key,$sslp_name, $sslp_rgd_id)  =  $sth->fetchrow_array() ) {
    $results{$sslp_name} = $sslp_rgd_id;
  }

  return %results;

}

##############
#
# Retrieves any genes that this is a splice variant of -  a link back to the 'parent' gene object
#
#############

sub get_parent_gene {
  my $gene_key = shift @_;
  my %results = ();
  my $sql = "select v.gene_key, v.variation_key, v.gene_variation_type, g.gene_symbol, g.rgd_id
              from genes_variations v, genes g where v.variation_key = ? and v.gene_key = g.gene_key";  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute($gene_key) or die "Can't execute statement: $DBI::errstr"; 
  while (my ($gene_key,$var_key,$var_type,$gene_symbol, $gene_rgd_id)  =  $sth->fetchrow_array() ) {
  	#warn "get_parent: Found $gene_symbol = $gene_rgd_id\n"; 	
    $results{$gene_symbol} = $gene_rgd_id;  
	
  }
  return %results;
}

# Find out if gene is a splice (variant) or an allele (variant) #DP 11-05-03
sub get_gene_type {
  my $gene_key = shift @_;
  my %results = ();
  #my $sql = "select v.gene_variation_type, g.gene_symbol, g.rgd_id, g.gene_type_lc
              #from genes_variations v, genes g where v.variation_key = ? and v.variation_key=g.gene_key"; 
  my $sql = "select g.gene_symbol, g.rgd_id, g.gene_type_lc
              from genes g where g.gene_key= ?"; 
 
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute($gene_key) or die "Can't execute statement: $DBI::errstr"; 
  while (my ($gene_symbol, $gene_rgd_id, $type)  =  $sth->fetchrow_array() ) {
  	#warn "get_parent: Found $gene_symbol = $gene_rgd_id\n"; 	
    $results{$gene_symbol}{'id'} = $gene_rgd_id;  #DP 11-05-03
    $results{$gene_symbol}{'type'} = $type;  #DP 11-05-03	
  }
  return %results;
}





##############
#
# Retrieves any splice variants of this gene using the gene key to query the genes_variations table
#
#############

sub get_gene_variants {

  my $gene_key = shift @_;

  my %results = ();

  my $sql = "select v.gene_key, v.variation_key, v.gene_variation_type, g.gene_symbol, g.rgd_id
              from genes g, genes_variations v where v.gene_key = ? and v.variation_key = g.gene_key";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($gene_key) or die "Can't execute statement: $DBI::errstr";
  
  while (my ($gene_key,$var_key,$var_type,$v_gene_symbol, $v_gene_rgd_id)  =  $sth->fetchrow_array() ) {
  	warn "Found $v_gene_symbol = $v_gene_rgd_id\n";
  	
    $results{$v_gene_symbol} = $v_gene_rgd_id;
  }

  return %results;

}

##############
# get array of uncurated pubmed ids
#
##############

sub get_uncurated_pubmed_ids {
  
  my $id = shift @_;

  my @pubmed_ids = ();

  my $sql = "SELECT x.acc_id ".
            "FROM rgd_acc_xdb x ".
            "WHERE x.rgd_id=? AND x.xdb_key = 2 ".
            "AND NOT EXISTS( SELECT 1 ".
            "  FROM rgd_ref_rgd_id r, rgd_acc_xdb x2, references rf ".
            "  WHERE r.rgd_id=x.rgd_id AND r.ref_key=rf.ref_key AND rf.rgd_id=x2.rgd_id ".
                "AND x2.xdb_key=x.xdb_key AND x2.acc_id=x.acc_id)";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute($id) or die "Can't execute statement: $DBI::errstr";
  
  while (my ($pubmed_id) = $sth->fetchrow_array() ) {
    push(@pubmed_ids, $pubmed_id);
  }

  return @pubmed_ids;
}


#######
# Simon T. 2005-November
# new and improved homolog script to return something more meaningful to the user.
#
#######

sub get_gene_homolog_data {

	my $id = shift @_;

	my %results = ();
	
	my $sql = "select h.homolog_symbol, h.rgd_id, h.HMLG_ORG_TYPE_KEY from homologs h, rgd_hmlg_rgd_id r where r.homolog_key = h.homolog_key and r.rgd_id = ?";

	my $sth = $db->{dbh}->prepare($sql) 
               or die "Can't Prepare statement: $DBI::errstr"; 

  	$sth->execute($id) or die "Can't execute statement: $DBI::errstr";
  	

  	while (my ($h_symbol, $h_rgd_id,$h_org_type)=$sth->fetchrow_array() ) {
  	
  		$results{$h_org_type} = $h_symbol;
  	
  	}
	
	return %results;
	
}

sub get_seq_info  {

  my ($id) = @_;
  
  my %results = ();
  ################################################################
  ## modified by Lan Zhao   1/26/2003
  ##
  ##my $sql = qq[ select s.rgd_id,st.sequence_type,sc.clone_name
  ##               from rgd_ids r, 
  ##                    rgd_seq_rgd_id rr, 
  ##                    sequences s,
  ##                    seq_clones sc,
  ##                    seq_types st
  ##              where r.rgd_id = rr.rgd_id
  ##                and rr.sequence_key = s.sequence_key
  ##                and st.sequence_type_key = s.sequence_type_key
  ##                and s.sequence_key = sc.sequence_key
  ##                and r.rgd_id = ? ];
  ### do following query if SEQUENCE_TYPE='primer pair' or 'oligo'
  #my $sql_seq = qq[ select s.rgd_id,st.sequence_type 
  #                    from rgd_ids r,
  #                         rgd_seq_rgd_id rr,
  #                         sequences s,
  #                         seq_types st,
  #                         seq_primer_pairs sp
  #                   where r.rgd_id = rr.rgd_id
  #                     and rr.sequence_key = s.sequence_key
  #                     and st.sequence_type_key = s.sequence_type_key
  #                     and s.sequence_key = sp.sequence_key
  #                     and r.rgd_id =? ];
  
  my $sql = qq[ select rr.sequence_key, s.rgd_id,st.sequence_type
                  from rgd_seq_rgd_id rr, 
                       sequences s,
                       seq_types st
                 where rr.rgd_id= ? 
                   and rr.sequence_key = s.sequence_key
                   and st.sequence_type_key = s.sequence_type_key];

  my $sth = $db->{dbh}->prepare($sql) 
               or die "Can't Prepare statement: $DBI::errstr"; 

  $sth->execute($id) or die "Can't execute statement: $DBI::errstr";
 
  while (my ($seq_key, $seq_rgd_id,$seq_type)=$sth->fetchrow_array() ) {
     my $sql_clone = qq[ select clone_name
                         from   seq_clones
                         where  sequence_key = ? ];
    
     my $sth = $db->{dbh}->prepare($sql_clone) 
                or die "Can't Prepare statement: $DBI::errstr"; 

     $sth->execute($seq_key) or die "Can't execute statement: $DBI::errstr";
    
     while (my ($clone_name)=$sth->fetchrow_array() ) {
        $results{$seq_rgd_id}{seq_type} = $seq_type;
        $results{$seq_rgd_id}{clone_name} = $clone_name;
     }
     
     ### if SEQUENCE_TYPE='primer pair' or 'oligo'
     if($seq_type =~ /primer pair|oligo/){
       $results{$seq_rgd_id}{seq_type} = $seq_type;
     }
  }
 
  return %results;
  
}


#####Jiali 01/05/05
sub javascript{
    print <<JS;
        <SCRIPT LANGUAGE="JavaScript">

           function chaseBrowsers(url){
              if(url!=""){
                  window.open(url,"views","height=800, width=1000, resizable=yes, status=yes, location=yes,scrollbars=yes"); 
              }
           }
        </SCRIPT>
JS

}

