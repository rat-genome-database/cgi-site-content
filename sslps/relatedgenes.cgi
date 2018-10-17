#!/usr/bin/perl

#--------------------------------------------
#
#  Genes related to sslps
#
#  Author: Nathan Pedretti
#    Date: 05/19/2000
#  Last modified by JL, 01-10-2001
#  dispay results 20 per page instead of all
#--------------------------------------------
use lib '/rgd/tools/common';
use RGD::DB;
use RGD::HTML;
use CGI;

my $db = RGD::DB->new();
my $cgi = CGI::new();

my $show_num =20;
my $next = $cgi->param('next') || 1;
my $prev = $cgi->param('prev') || 0;
#my $chr  = $cgi->param('chr');

#my %count=undef; # count sslp
#my %data=undef; # for whole sslps
#my %newdata=undef; # only for spsecific chrom sslps

my ($min,$max); 

if($next){
  $min  = $next;
  $max  = $next+$show_num-1;
}
if($prev >$show_num){
  $min  = $prev-$show_num;
  $max  = $prev-1;
}else{
  $min  = $next;
  $max  = $next+$show_num-1;
}


my $html = RGD::HTML->new(
			  title  => "Rat Genome Database: SSLPs related to Genes", 
			  doc_title  => "SSLPs related to Genes", 
			  version    => "1.1",
			  tool_dir   => "sslps",
			  meta       =>  { author   => "pedretti\@mcw.edu",
					   keywords => "rgd,rat,genome,database,objects,statistics,sslp,genes",
					 },               
			 
			  
			 );
my $baseURL=$html->get_baseURL;   # http://rgd.mcw.edu
my $baseCGI=$html->get_baseCGI;   # http://rgd.mcw.edu/tools

$html->html_head;
$html->tool_start;



my $helpURL = "$baseURL/help/sslps/sslpgenes.shtml";
my $gene_url = "$baseCGI/genes/genes_view.cgi?id=";
my $sslp_url = "$baseCGI/sslps/sslps_view.cgi?id=";
my $script = "$baseCGI/sslps/relatedgenes.cgi";

my ($recordcount,@records)=&get_data;
#&process_results(@records);
&display_query($recordcount,@records);

$html->tool_end;
$html->html_foot;


sub get_data{
  my  $sql = "SELECT s.rgd_name,
		     s.rgd_id,
		     g.gene_symbol,
                     g.full_name,
		     g.rgd_id
	      FROM sslps s,
		   rgd_gene_sslp gs,genes g
	      WHERE s.sslp_key = gs.sslp_key
     	      AND gs.gene_key = g.gene_key
              order by rgd_name,s.rgd_id";
 

  my ($recordcount, @data) = $db->query_Data(5,$sql);
#  print "<p>$recordcount";
  return($recordcount,@data);
}

sub display_query{
  my ($recordcount,@data)=@_;
 
  my $page=undef;
  my $text=undef;
 
    
  $next = $min+$show_num;
  
  if($next >= $recordcount){
    $next =$recordcount;  
    $page = "n";   
  }
  $prev = $next-$show_num;
  if($prev <$min){
    $prev = $min;
    $page = "p"; 
  }
  
  if($max >= $recordcount){
    $max = $recordcount;
    $page = "n";  # no next page
  } 
  if($min <=1){
    $min =1;
    $page = "p";
  }
  if($recordcount <= $show_num){
    $page = "np";  # no next and prev page
    $min =1;
    $max = $recordcount;
  }
  
  $text = "total $recordcount";
  
  
  print<<__HEADINFORMATION__;

  <p>This report lists all sslps with related genes.
  <p> $min - $max of $text \n
      
  <table border=0 cellpadding=4 cellspacing=0>
  <tr><td>SSLP</td>
      <td>GENE</td></tr>

__HEADINFORMATION__
  my $index=0;
  my $total=0;
  foreach my $key (@data){
    my @tmp = split(/::/, $key);
    my $rgd_id=$tmp[1];
    my $rgd_name=$tmp[0];
    my $gene_rgd_id=$tmp[4];
    my $gene_symbol=$tmp[2];
    my $full_name =$tmp[3];
    $total++;
    if($total>= $min){
      
      print "<tr><td><a href='$sslp_url$rgd_id'>$rgd_name</a></td>";
      print "    <td><a href='$gene_url$gene_rgd_id'>$gene_symbol($full_name)</a></td></tr>";
      $index++;
      
      if($index==$show_num){   
	last;
      } 
    }
  }
  
  print "</table>\n ";
  if($page eq "n"){
    print "<p><< <a href='$script?prev=$prev&chr=$chr'>Previous</a> -- Next >>\n"; 
  }elsif($page eq "p"){
    print "<p><< Previous -- <a href='$script?next=$next&chr=$chr'>Next</a> >>\n";
  }elsif($page eq "np"){
    print "<p><< Previous -- Next >>\n";
  }else{
    print "<p><< <a href='$script?prev=$prev&chr=$chr'>Previous</a> -- <a href='$script?next=$next&chr=$chr'>Next</a> >>\n";
  }
  print "<p><a href=\"/\">Back to RGD Home</a>";
} 

sub process_results{
  my (@data)=@_;
  my $count=0;
  my $count_chr=0;
  my $index=0;

  foreach my $record (@data) {
    
    my @fields = split(/::/, $record);
 #   print "<p>$fields[0],$fields[1]";
    my $name = $fields[0];
    my $id = $fields[1];
#    $data{$id}->{'rgd_name'}= $fields[0];
#    $data{$id}->{'gene_symbol'}= $fields[2];
#    $data{$id}->{'full_name'}= $fields[3];
#    $data{$id}->{'gene_rgd_id'}= $fields[4];
    
    $data{$id}{gene_rgd_id};
    print "<p>$name";
    if($chr){
      
      my $chrom=undef;
      my $rgd_name=undef;
      my $rgd_id=undef;
      my $gene_symbol=undef;
      my $full_name=undef;
      my $gene_rgd_id=undef;
      
      if($name=~/^d(x|y|\d{1,2})\w{2,3}\d+/i || $name=~/^d(x|y|\d{1,2})\M(x|y|\d{1,2})\w{2,3}\d+/i) {
	if($name =~ /DX/i){
	  $chrom="X";
	  $rgd_name=$fields[0];
	  $rgd_id=$fields[1];
	  $gene_symbol=$fields[2];
	  $full_name=$fields[3];
	  $gene_rgd_id=$fields[4];
	}else{
	  my @tmp=split(/\D/,$name);
	  $chrom=$tmp[1];
	  $rgd_name=$fields[0];
	  $rgd_id=$fields[1];
	  $gene_symbol=$fields[2];
	  $full_name=$fields[3];
	  $gene_rgd_id=$fields[4];
	}
      }else{
	$chrom="others";
	$rgd_name=$fields[0];
	$rgd_id=$fields[1];
	$gene_symbol=$fields[2];
	$full_name=$fields[3];
	$gene_rgd_id=$fields[4];
      }
      if($rgd_id){
	my $key="$rgd_id-$chrom";
	$newdata{$key}->{'rgd_name'}=$rgd_name; 
	$newdata{$key}->{'chr'}=$chrom;
	$newdata{$key}->{'full_name'}=$full_name;
	$newdata{$key}->{'gene_symbol'}=$gene_symbol;
	$newdata{$key}->{'gene_rgd_id'}=$gene_rgd_id;
      }    
    }
  }
  
  foreach my $key (keys (%data)){
    my $newkey="$key-$chr" if($chr);
    
    $count_chr++ if($newdata{$newkey}->{'rgd_name'});
    $count++ if($data{$key}->{'rgd_name'});
  }
  
  $count{'chr'} =$count_chr;  
  $count{'total'}=$count;
  
  print "<p>total=$count{'total'}, chr $chr=$count{'chr'}";

}

sub show_chrom{
  my @chr=(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,X,"others");
  print "<p>Listed by <b>Chromosome</b> ";
  for(my $i=0;$i<@chr;$i++){
    print "<a href='$script?chr=$chr[$i]'>$chr[$i]</a> ";
  }
}

__END__
