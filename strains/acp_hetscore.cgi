#!/usr/bin/perl

##############################
# 
#
##############################
use lib '/rgd/tools/common';

use RGD::HTML;
use CGI qw(:standard);

my $cgi = CGI::new();
my $html = RGD::HTML->new();
my $baseURL=$html->get_baseURL; 
my $baseCGI=$html->get_baseCGI;
my $wwwPATH= $html->get_wwwPATH; # /rgd/WWW

my $col = $cgi->param('col') || 1; # sorted by column
print "Content-type: text/html\n\n";

my $acp_hetscore = "$wwwPATH/strains/acp_hetscore$col\.txt";

&part1;
&part2;

exit;

sub part1{
  print<<_TXT_;
<h2>ACP Strain Heterozygote Scores</h2>
<p>This is a table showing the number of heterozygotic allele sizes detected
 when 48 strains were screened with 4000+ SSLPs. A completely inbred strain 
would be expected to have very few (ideally zero) heterozygotic markers, 
higher numbers of hets would suggest a less inbred strain.
<p>Note: by clicking <img src="$baseURL/common/images/sort.gif" border=0>, it will sort the scores by that column.
<p><A HREF="index.shtml">Return to Strains</A>

<p><p>

_TXT_
}

sub part2{
  
  if(-e $acp_hetscore){
    print <<_TAB_;
<TABLE CELLSPACING=0 BORDER=1>
<TR bgcolor="#CCCCCC">
<TD WIDTH=86 HEIGHT=16 ALIGN=CENTER><B><FONT SIZE=2>Strain</FONT></B></TD>
<TD WIDTH=106 HEIGHT=16 ALIGN=CENTER><B><FONT SIZE=2>Number of Hets</FONT></B></TD>
<TD WIDTH=86 HEIGHT=16 ALIGN=CENTER><B><FONT SIZE=2>Total Markers</FONT></B></TD>
<TD WIDTH=86 HEIGHT=16 ALIGN=CENTER><B><FONT SIZE=2>% of Hets vs Markers</FONT></B></TD>
</TR>
<TR bgcolor="#CCCCCC">
<TD WIDTH=86 HEIGHT=16 ALIGN=CENTER><a href= '$baseURL/strains/hetscores1.shtml'><img src="$baseURL/common/images/sort.gif" border=0 alt="sorted by Strain"></a></TD>
<TD WIDTH=106 HEIGHT=16 ALIGN=CENTER><a href='$baseURL/strains/hetscores2.shtml'><img src="$baseURL/common/images/sort.gif" border=0 alt="sorted by Number of Hets"></a></TD>
<TD WIDTH=86 HEIGHT=16 ALIGN=CENTER><a href='$baseURL/strains/hetscores3.shtml'><img src="$baseURL/common/images/sort.gif" border=0 alt="sorted by Total Markers"></a></TD>
<TD WIDTH=86 HEIGHT=16 ALIGN=CENTER><a href='$baseURL/strains/hetscores4.shtml'><img src="$baseURL/common/images/sort.gif" border=0 alt="sorted by % of Hets vs Markers"></a></TD>
</TR>
_TAB_
    open(IN,$acp_hetscore);
    my $header=<IN>;
    while(my $line=<IN>){
      my ($col1,$col2,$col3,$col4)=split(/\t/,$line);
      print "<tr><td WIDTH=86 HEIGHT=16><FONT SIZE=2>$col1</FONT></td><td  WIDTH=86 HEIGHT=16 ALIGN=CENTER><FONT SIZE=2>$col2</FONT></td><td  WIDTH=86 HEIGHT=16 ALIGN=CENTER><FONT SIZE=2>$col3</FONT></td><td  WIDTH=86 HEIGHT=16 ALIGN=CENTER><FONT SIZE=2>$col4</FONT></td></tr>\n";
    }
    
    close(IN);
  }
  print "</table>\n";
}


