#!/usr/bin/perl -w

#--------------------------------------------
#
#  nomen_report.cgi
#
#  Author: Simon Twigger
#    Date: 11/05/2000
#
#--------------------------------------------

use lib '/rgd/tools/common';

use RGD::DB;
use RGD::HTML;
use CGI;


##################
#
# Basic Curation tool to list nomen_events
#
##################



my $form = new CGI; # Create a new CGI object
my $db = RGD::DB->new(); # new RGD::DB module for database access.
my $VERSION = "1.0";

my $order_field = $form->param('order') || "n.event_date";
my $limit = $form->param('limit') || "none";
my $direction = $form->param('dir') || "asc";
my $date_limit = $form->param('date') || "month";
my $rev_dir = "";
if ($direction eq "asc") {
  $rev_dir = "desc";
}
else {
  $rev_dir = "asc";
}

my $conditions  = "";

my %COLOR_SCHEME = (
		    APPROVED => "#FFFFFF",
		    WITHDRAWN => "#FFFFFF",
		   );

my %DATE = (
	    week => "where n.event_date between (sysdate-7) and sysdate",
	    two_weeks => "where n.event_date between (sysdate-14) and sysdate",
	    month => "where n.event_date between (sysdate-30) and sysdate",
	    year => "where n.event_date between (sysdate-365) and sysdate",
	    all => "",
	   );

my $order = "";
my $doc_sql = ""; # empty field for the SQL statement for debugging

# show all nomen_events
$order = "order by $order_field";
my %hits = &fetch_nomen_events($order);
&display_report(\%hits,"All Nomenclature Events");

exit;



##################
#
# fetch_nomen_events
#
##################

sub fetch_nomen_events {

  my $order = shift @_;
  
  my $sql = "select n.nomen_event_key, n.rgd_id, n.original_rgd_id, n.symbol, n.name, n.nomen_status_type, n.description, n.event_date, n.notes, n.object_status, n.object_type, n.ref_rgd_id, n.ref_citation from nomen_search_view n $DATE{$date_limit} $order $direction";

  $doc_sql = "$sql\n";
  
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  
  $sth->execute or die "Can't execute statement: $DBI::errstr";
  
  my %results =();
  my $rank = 1;
  while ( my ($nomen_event_key,$rgd_id,$orig_rgd_id,$symbol,$name,$status,$desc,$date,$notes,$original_obj_status, $obj_type,$ref_rgd_id, $ref_citation) = $sth->fetchrow_array() ) {
    
    $results{$nomen_event_key} = {
				  order => $rank,
				  rgd_id => $rgd_id,
				  original_rgd_id => $orig_rgd_id,
				  symbol => $symbol,
				  name => $name,
				  status => $status,
				  event_date => $date,
				  notes => $notes,
				  description => $desc,
				  object_status => $original_obj_status,
				  object_type => $obj_type,
				  ref_rgd_id => $ref_rgd_id,
				  ref_citation => $ref_citation,
			 };
    # warn "Found $nome_event_key,$rgd_id,$status\n";
    $rank++;
  }
  
  $sth->finish;
  
  return %results;
  
}

##################
#
# display_report
#
##################

sub display_report {

  my ($hit_ref,$title) =  @_;

  my $date = scalar localtime;

   my $html = RGD::HTML->new(
			 
			    title          => "RGD Nomenclature Event Report: $date",
			    doc_title      => "RGD Nomenclature Event Report: $date",
			    version        => "1.0",
			   );
  my $baseURL=$html->get_baseURL;
  my $baseCGI=$html->get_baseCGI;

  $html->html_head;
  $html->tool_start;
  print "<table width=\"95%\"><TR><TD>";
  print "<P><P><P>Nomenclature Event Report for events in the last $date_limit<BR>";
  print "<p><p>Return to <a href=\"$baseURL/nomen/nomen.shtml\">Nomenclature Page</a>";
  
  my $ref_key_list = "";
  my $ref_count = 0;
  if(%$hit_ref) {
    
    print "<p><p><TABLE WIDTH=\"95%\" BORDER=0 CELLSPACING=1 CELLPADDING=3>\n";

    my $sort_img_html = "<img src=\"$baseURL/common/images/reverse_sort.gif\" alt=\"sort\" border=\"0\" align=\"abs_middle\">";

    print <<"EOFORM2";
<TR valign="top" BGCOLOR="#DDDDDD"><TD>#</TD>
<TD><a href="$baseCGI/nomen/nomen_report.cgi?order=n.object_type&dir=$rev_dir">$sort_img_html</A>&nbsp;RGD_ID</TD>
<!--
<TD><a href="$baseCGI/nomen/nomen_report.cgi?order=n.original_rgd_id&dir=$rev_dir"><image src="/curation/images/reverse.gif" border=0></A>&nbsp;Object</TD>
<TD>&nbsp;Object Status</A>&nbsp;
<a href="$baseCGI/nomen/nomen_report.cgi?order=r.object_status&dir=$rev_dir">$sort_img_html</A></TD>
-->
<TD><a href="$baseCGI/nomen/nomen_report.cgi?order=n.symbol&dir=$rev_dir">$sort_img_html</A>&nbsp;Symbol</TD>
<td><a href="$baseCGI/nomen/nomen_report.cgi?order=n.name&dir=$rev_dir">$sort_img_html</A>&nbsp;Name</td>
<td><a href="$baseCGI/nomen/nomen_report.cgi?order=n.nomen_status_type&dir=$rev_dir">$sort_img_html</A>&nbsp;Nomen&nbsp;Status</td>
<td><a href="$baseCGI/nomen/nomen_report.cgi?order=n.description&dir=$rev_dir">$sort_img_html</A>&nbsp;Description</td>
<td><a href="$baseCGI/nomen/nomen_report.cgi?order=n.event_date&dir=$rev_dir">$sort_img_html</A>&nbsp;Date</td>
<td><a href="$baseCGI/nomen/nomen_report.cgi?order=n.ref_citation&dir=$rev_dir">$sort_img_html</A>&nbsp;Reference</td>
</TR>

EOFORM2
  
  foreach my $ref (sort { $hit_ref->{$a}->{order} <=> $hit_ref->{$b}->{order}} keys %{$hit_ref} ) {
      $ref_count += 1;
      $ref_key_list .= "$ref,";
      
      print <<"EOFORM";
<TR VALIGN="TOP" bgcolor="$COLOR_SCHEME{$hit_ref->{$ref}->{status}}">
<TD ALIGN="CENTER">$ref_count</TD>
<!--
<TD>$ref</TD>
-->
<TD>$hit_ref->{$ref}->{original_rgd_id}</TD>
<!--
<TD>$hit_ref->{$ref}->{object_type}</TD>
<TD>$hit_ref->{$ref}->{object_status}</TD>
-->
<TD><a href="$baseCGI/query/query.cgi?id=$hit_ref->{$ref}->{original_rgd_id}">$hit_ref->{$ref}->{symbol}</a></TD>
<td>$hit_ref->{$ref}->{name}</td>
<td>$hit_ref->{$ref}->{status}</td>
<td>$hit_ref->{$ref}->{description}</td>
<td>$hit_ref->{$ref}->{event_date}</td>
<td><a href="$baseCGI/query/query.cgi?id=$hit_ref->{$ref}->{ref_rgd_id}">$hit_ref->{$ref}->{ref_citation}</a></td>
<TR>
EOFORM
    }
    
    print "</TABLE><P><P><input type=\"hidden\" name=\"num_refs\" value=\"$ref_count\"><input type=\"hidden\" name=\"ref_key_list\" value=\"$ref_key_list\"></form>\n";
  }
  else  {
    $date_limit =~ s/_/ /g; # replace underscores with spaces for better reading!
    print "<h4>No nomenclature updates have occured over the last $date_limit</h4>\n";
  }
  print "</TD></TR></TABLE>\n";

  $html->tool_end;
  $html->html_foot;
  
} # end of display_report




__END__

