#!/usr/bin/perl -w

##############################
#
# sequences_view.cgi Simon Twigger May 2000
#
# Displays the sequence report for a given sequence RGD ID
#
##############################
use lib '/rgd/tools/common';

use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);
use strict;

my $form = new CGI;
my $db = RGD::DB->new();
my $html = RGD::HTML->new(
			  title      => "Sequence Report - Rat Genome Database",
			  doc_title  => "Sequence Report",
			  version    => "1.1",
			  tool_dir   => "sequences",
			  link_dir   => "sequences",
			  category   => "data",
			 );

my $baseURL=$html->get_baseURL;   # http://rgd.mcw.edu
my $baseCGI=$html->get_baseCGI;   # http://rgd.mcw.edu/tools

# Reference for the table hash with column info for all tables
my $table_ref = $db->get_table_hash_ref();

my %ref_list = ();
my %ref_data = ();

# Read in parameters
my $id      = $form->param('id')  || 33490; # The RGD ID of the RGD object to show the homologs for
my $format  = $form->param('fmt') || "html";
my $keyword = $form->param('kwd') || "";
my $length  = $form->param('length') || "short"; # Do we show all the strain characteristics and stuff
my $gene_symbol = $form->param('symbol') || ""; # The rat gene symbol

my $pubmed_keyword = "";

# remove any RGD: tag from the start of the ID
$id =~ s/RGD://;

# First get the sequence key and what type of sequence this is:
my %seq_info = get_seq_info_for_rgdid($id);


if($format =~ /text/i) {
  
}else {
  $html->html_head;
  $html->tool_start;
  
  if($seq_info{'SEQUENCE_TYPE_KEY'}){
    
    &display_html();
  }else{
    print "<p>No sequence result linked to this ID $id.";
    print "<p>Please try another query about this id: ";
    print "<a href=\"$baseCGI/query/query.cgi?id=$id\">$id</a>\n";
  }
  $html->tool_end;
  $html->html_foot;
}

exit;

########################

sub display_html {

  #my $data_ref = shift @_;

  my @columns = split ',',$table_ref->{sequences}{select}; 
 
  
  
  my %data = ();
  
  if($seq_info{SEQUENCE_TYPE_KEY} == 4) { # its a Primer Pair
    %data = get_primer_pair_data($seq_info{SEQUENCE_KEY});
    # &print_seq_header(\%seq_info);
    &print_primer_page(\%data,\%seq_info);
  }
  else {
    %data = get_clone_data($seq_info{SEQUENCE_KEY});
    # &print_seq_header(\%seq_info);
    &print_clone_page(\%data,\%seq_info);
  }
  
  #my %xdbs = $db->get_rgd_id_xdb($id);
  print "<BR><HR><BR>\n";
  print "<h3>External Database Links</h3>\n";
  ### Replaced the code below DP 7-1-02
  print $html->get_xdb_html(\$db,$id);
  ###
   my $url_genbank = "https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=nucleotide&term=$pubmed_keyword";
  print "<p><A HREF=\"$url_genbank\">Search for related sequences at Genbank</A><BR>\n";
  print "<BR><HR><BR>\n";
  print "<h3>References</h3>\n";

  print "<P>" . $html->get_citation_html(\$db,$seq_info{RGD_ID});

  my $url_pubmed = "https://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=PubMed&term=$pubmed_keyword+AND+Rat+[MH]";

  print "<A HREF=\"$url_pubmed\">Search for related articles at PubMed</A><BR>\n";

  my %info = $db->get_RGDid_data($id);
  
  print "<BR><HR>\n";
  print "<B>RGD ID:</B> $info{'rgd_id'}<BR>\n";
  print "<B>Created:</B> $info{'created_date'}<BR>\n";
  print "<B>Released:</B> $info{'released_date'}<BR>" if $info{'released_date'};
  print "<BR>\n";

} # end of display_html


sub print_seq_header {

  my $seq_info_ref = shift @_;
 
  
  print "Accession: RGD: $seq_info_ref->{RGD_ID} (Seq Key: $seq_info_ref->{SEQUENCE_KEY})<BR>\n";
  print "<b>Sequence Type</b>: $seq_info_ref->{SEQ_TYPE_DESC}<BR>\n";
  print "<p><HR>\n";
}



sub print_primer_page {

  my ($seq_ref,$seq_info_ref)  =  @_;

  # Basic print routine

  my %parent_info = get_parent_obj_info($seq_ref->{SEQUENCE_KEY});

  # This will break once we have more than one object attached to a sequence...

  print "<TABLE>\n";

  foreach my $parent (keys %parent_info) {

    my ($name,$obj_type) = split '::',$parent_info{$parent};
    $obj_type =~ s/S$//; # Remove the last S from the object type;
    print "<tr><td><b>Parent</b>:</td><td><A HREF=\"$baseCGI/query/query.cgi?id=$parent\">$name</A> ($obj_type)</td></tr>\n";
    $pubmed_keyword = $name;

  }
  print "<tr><td><b>Sequence Type</b>: </td><td>$seq_info_ref->{SEQ_TYPE_DESC}</td></tr>\n";
  print "<tr><td><b>Primer Name</b>: </td><td>$seq_ref->{PRIMER_NAME}</td></tr>\n";
  print "<tr><td><b>Primer Description</b>: </td><td>$seq_ref->{PRIMER_DESC}</td></tr>\n";
  print "<tr><td><b>Forward</b>: </td><td>$seq_ref->{FORWARD_SEQ}</td></tr>\n";
  print "<tr><td><b>Reverse</b>: </td><td>$seq_ref->{REVERSE_SEQ}</td></tr>\n";
  print "</table>\n";
}



sub print_clone_page {

  my ($seq_ref,$seq_info_ref)  =  @_; 

  my %parent_info = get_parent_obj_info($seq_ref->{SEQUENCE_KEY});
 
  # This will break once we have more than one object attached to a sequence...
 print "<TABLE>\n";
  foreach my $parent (keys %parent_info) {

    my ($name,$obj_type) = split '::',$parent_info{$parent};
    $obj_type =~ s/S$//; # Remove the last S from the object type;
    print "<tr><td><b>Parent</b>: </td><td><A HREF=\"$baseCGI/query/query.cgi?id=$parent\">$name</A> ($obj_type)</td></tr>\n";
    $pubmed_keyword = $name;
    
  }
  
  print "<tr><td><b>Sequence Type</b>: </td><td>$seq_info_ref->{SEQ_TYPE_DESC}<BR></td></tr>\n";
  print "<tr><td><b>Clone Name</b>: </td><td>$seq_ref->{CLONE_NAME}</td></tr>\n";

  print "<tr><td><b>Sequence</b>: </td><td>$seq_ref->{SEQ_LENGTH} bp</td></tr>\n";
  print "<tr><td colspan=2><p><font face=\"courier\">$seq_ref->{SEQUENCE}</font></td></tr>";
  print "</table>\n";
}


sub get_parent_obj_info {

  my $seq_key = shift @_;

  my %related_obj = &get_related_rgdids($seq_key);

  my %results = ();

  my @obj_list = ("-","GENES","SSLPS","-","STRAINS","QTLS","-","PHENOTYPES","SEQUENCES","MAPS","REFERENCES","-","HOMOLOGS");

  my %obj_types = (
		      GENES => 1,
		      SSLPS => 3,
		      STRAINS => 5,
		      QTLS => 6,
		      PHENOTYPES => 8,
		      SEQUENCES => 9,
		      MAPS => 10,
		      REFERENCES => 11,
		      HOMOLOGS => 13,
		     );

  my %obj_names = (
		      GENES => 'GENE_SYMBOL',
		      SSLPS => 'RGD_NAME',
		      STRAINS => 'STRAIN_SYMBOL',
		      QTLS => 'QTL_SYMBOL',
		      PHENOTYPES => 'PHE_SYMBOL',
		      SEQUENCES => 'SEQUENCE_KEY',
		      MAPS => 'MAP_NAME',
		      REFERENCES => 'CITATION',
		      HOMOLOGS => 'HOMOLOG_SYMBOL',
		     );

  foreach my $rgd_id (keys %related_obj) {
   
    my $sql = "select $obj_names{ $obj_list[$related_obj{$rgd_id}] } from $obj_list[$related_obj{$rgd_id}] where RGD_ID = $rgd_id";
    
    my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
    $sth->execute() or die "Can't execute statement: $DBI::errstr";

    my ($name)= $sth->fetchrow_array();

    $results{$rgd_id} = "$name" . "::" . "$obj_list[$related_obj{$rgd_id}]";
    
    # print "\n\n\n$sql <BR> $results{$rgd_id} \n\n";

  }

  return %results;

}


sub get_primer_pair_data {

  my $key = shift @_;

  my $cols = $table_ref->{homologs}{select};

  my $sql = <<"EOF";
  select sequence_key,primer_name, primer_desc,forward_seq, reverse_seq, notes
  from seq_primer_pairs
  where sequence_key = ?
EOF
      
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($key) or die "Can't execute statement: $DBI::errstr";
  
  my @rows =  $sth->fetchrow_array();

  my %results = ();
  $results{SEQUENCE_KEY} = $rows[0] || "Unknown";
  $results{PRIMER_NAME} = $rows[1] || "Unknown";
  $results{PRIMER_DESC} = $rows[2] || "-";
  $results{FORWARD_SEQ} = $rows[3] || "-";
  $results{REVERSE_SEQ} = $rows[4] || "-";
  $results{NOTES} = $rows[5] || "None";
 
  return %results;
  
}

sub get_clone_data {

  my $key = shift @_;

  my $sql = <<"EOF";
  select clone_key,clone_name,vector_name,notes, sequence from seq_clones where sequence_key = $key
EOF
      
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute() or die "Can't execute statement: $DBI::errstr";
  my %results = ();
  
  my ($clone_key,$clone_name,$vec_name,$notes,$sequence) =  $sth->fetchrow_array;
  
  # print "#############\n\n\n $clone_key:\n$sequence \n";

  $results{SEQUENCE_KEY} = $key || "Unknown";
  $results{CLONE_KEY} = $clone_key || "Unknown";
  $results{CLONE_NAME} = $clone_name || "Unknown";
  $results{VECTOR_NAME} = $vec_name || "-";
  $results{SEQUENCE} = $sequence || "-";
  $results{SEQ_LENGTH} = length($sequence) || 0;
  $results{NOTES} = $notes || "None";
   

  # Need to paginate the sequence if its longer than 50 bp into 50bp per line.
  
  if($results{SEQ_LENGTH} > 50) {
    
    my @seq_blocks = ();
    my $interval = 50; # bp per line
    my $start = 1;
    my $end = $start + $interval;

    while ($start <= $results{SEQ_LENGTH}) {
      push @seq_blocks, substr($results{SEQUENCE}, $start, $interval);
      $start += $interval;
    }
    
    $results{SEQUENCE} = join "<BR>\n", @seq_blocks;

    
  }
	    
  
  return %results;
  
  
}


sub get_seq_info_for_rgdid {

  my $id = shift @_;
  
  my $sql = "select s.sequence_key,s.sequence_type_key, s.sequence_desc, t.sequence_type from sequences s,seq_types t where s.rgd_id = ? and t.sequence_type_key = s.sequence_type_key";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($id) or die "Can't execute statement: $DBI::errstr";
  
  my @rows =  $sth->fetchrow_array();
  
  my %results = ();

  $results{SEQUENCE_KEY} = $rows[0] || "0";
  $results{SEQUENCE_TYPE_KEY} = $rows[1] || "0";
  $results{SEQUENCE_DESC} = $rows[2] || "Unknown";
  $results{SEQ_TYPE_DESC} = $rows[3] || "Unknown";
  $results{RGD_ID} = $id;

 
 
  return %results;

}


# See what other objects are related to this sequence via the rgd_seq_rgd_id table (what a mouthfull)

sub get_related_rgdids {

  my ($seq_key, $seq_type) =  @_; # sequence_key and sequence type for this sequence obj.

  my $sql = <<"EOF";
  select r.rgd_id, r.sequence_key, o.object_key
  from rgd_seq_rgd_id r, rgd_ids o
  where sequence_key = ? and o.rgd_id = r.rgd_id
EOF
      
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute($seq_key) or die "Can't execute statement: $DBI::errstr";
  
  my %results = ();
 
  while ( my ($rgd_id, $key, $obj_type) = $sth->fetchrow_array()) {

    $results{$rgd_id} = $obj_type;

    # print "$results{$rgd_id} = $obj_type\n";

  }
 
  return %results;
  



}


__END__
