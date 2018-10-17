#!/usr/bin/perl

#--------------------------------------------
#
# notes.cgi
#
#  Author: JL, 6/24/2002
#--------------------------------------------
use lib '/rgd_home/2.0/TOOLS/common';
use RGD::DB;

use CGI;

my $db = RGD::DB->new();
my $cgi = CGI::new();

my $key     = $cgi->param('key');
my $rgd_id  = $cgi->param('ID');
my ($type,$keys)=split(/:/,$key);
my @keys = split(/,/, $keys); # multi-values

my %notes=undef;
my %note_ctn=undef;
my %obj=(
	 genes => {
		   symbol => "gene_symbol",
		   desc   => "Gene",
		   table  => "genes",
		  },
	 sslps => {
		   symbol => "rgd_name",
		   desc   => "SSLP",
		   table  => "sslps",
		  },
	);
print <<_HTML_;
Content-type:text/html \n\n
<html>
<head>
<title>RGD Notes Report</title>
</head>
<body bgcolor=white>
<center>

<h3>RGD Notes Report</h3>
<hr>
<p>
_HTML_

&get_note_type;

if($key){
  &display_notes;
}else{
  print "<p>No notes_key is specified.";
}

print <<_HTML_;
<center>
<h4><a href="javascript:parent.close()">Close This Window</a></h4>
</center>
</body>
</html>
_HTML_

exit;


sub display_notes{
  my $obj = $notes{$type}->{'obj'};
  my $attr = $obj{$obj}->{'symbol'};
  my $table = $obj{$obj}->{'table'};
  my ($s, $symbol);
  if($attr && $table){
    my $sql = "select $attr from $table where rgd_id=$rgd_id";
    ($s, $symbol) = $db->query_Data(1,$sql);
  }

  print "<table bgcolor=\"#CCCCCC\">";
  print "<tr><td>$obj{$obj}->{'desc'}: $symbol</td></tr>\n";
  print "<tr><td>Notes Type: $notes{$type}->{'desc'}</td></tr>\n";
  print "<tr><td><table border=1 bgcolor=\"#FFFFFF\" width=100%>";
  print "<tr align=center><td>Creation Date</td><td>Notes</td></tr>\n";
  foreach my $k (@keys){
    my $sql = "SELECT NOTES,CREATION_DATE,NOTES_TYPE_NAME_LC
                 from NOTES 
                where NOTE_KEY = $k";
  
    my ($r, $records) = $db->query_Data(3,$sql);
    if($r){
      my ($notes,$date,$type)=split(/::/,$records);
      $date = "&nbsp;" if(!$date);
      print "<tr><td>$date</td><td>$notes</td></tr>\n";
 
    }
  }
  print "</table></td></tr></table>";
  return $r;
}

sub get_note_type{
  my  $sql = "SELECT NOTE_OBJECT,NOTES_TYPE_NAME_LC,NOTE_DESC
             from note_types";
  my ($recordcount, @records) = $db->query_Data(3,$sql);
  foreach my $r (@records){
    my ($obj,$t,$desc)=split(/::/,$r);
    $notes{$t}->{'obj'}=$obj;
    $notes{$t}->{'desc'}=$desc;
  }
}
