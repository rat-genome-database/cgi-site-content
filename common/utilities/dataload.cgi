#!/usr/bin/perl

##############################
#
# dataload.cgi Simon Twigger May 2000
#
# Gets the strain symbols and associated RGD Ids from the Strains
# table for the simple form listing 
#
##############################

use lib "/rgd/TOOLS/common";
use RGD::DB;
use RGD::HTML;
use CGI qw(:standard);


my $db = RGD::DB->new();
my $html = RGD::HTML->new(
			  title => "Data Loading Tool",
			  tool_dir => "strains",
			 );
my $tables = $db->get_table_hash_ref;

my $form = CGI->new();

my $action = $form->param('action') || "display_form";
my $table = $form->param('table') || "strains";


if ($action eq "display_form") {
  &display_form;
}
elsif ($action eq "insert") {
  exit;
  # &insert_data;
}
elsif ($action eq "update") {

}
else {
  &get_data;
}

exit;


sub display_form {

  # based on table, get the column headings

  $html->html_head();
  $html->tool_start;

  my @cols = split ',',$tables->{$table}->{select};
  
  print "<FORM ACTION=\"/tools/common/utilities/dataload.cgi\" METHOD=\"POST\">";
  print "<select name=\"action\" size=\"1\">\n";
  print <<"EOF";
  <OPTION value="get">Get Data for existing record
<OPTION value="insert">Insert new record
<OPTION value="update">Update exisiting record
</SELECT>
EOF

print "<input type=\"submit\" value=\"Enter Data\">";
  print "<INPUT type=\"hidden\" name=\"table\" value=\"$table\">\n";
  
  foreach $attribute (@cols) {

    print <<"__end_of_input__";
<h3>$attribute</h3>
<INPUT name="$attribute" size="50"><BR>
__end_of_input__

  }

  print "<input type=\"checkbox\" name=\"new_rgd_id\" value=\"1\">Create New RGD Object<BR>";
 


  print "</FORM>";

  $html->tool_end;
  $html->html_foot;


}

sub get_data {

  my $id = $form->param('RGD_ID');

  my $atts = $tables->{$table}->{select};
  my @att_list = split ',',$atts;

  my $sql = "select ($atts) from  $table";
  my $sth = $db->{dbh}->prepare($sql);

  $sth->execute();


}



sub insert_data {

  my $atts = $tables->{$table}->{select};

  my @att_list = split ',',$atts;

  my @input = ();

  # create a string of questionmarks to bind the variables to
  my $bindstring = "?," x ($#att_list);
  $bindstring = "$bindstring?";

  $html->html_head();
  $html->tool_start;
  #print "<P>$bindstring\n";

  my $sql = "insert into $table ($atts) values ( $bindstring)";
  
  #print "$sql\n";
  
  my $sth = $db->{dbh}->prepare($sql);

  # read in the attributes, bind them to the variables and off we go!
  for my $i (0 .. $#att_list) {
    $input[$i] = $form->param( $att_list[$i] );
    $sth->bind_param( ($i+1), $att_list[$i]);
  }

  $sth->execute();

  print "Data loaded successfully!\n";

  $html->tool_end;
  $html->html_foot;

}
__END__
