#!/usr/bin/perl

#--------------------------------------------
#
# notes.cgi
#
#  Author: JL, 6/24/2002
#--------------------------------------------
use lib '/rgd_home/2.0/TOOLS/common';

use RGD::DB;
use RGD::HTML;
use CGI;

my $db = RGD::DB->new();
my $cgi = CGI::new();

my $public = $cgi->param('public') || 'Y';
my $object = $cgi->param('object') || 'genes';
my $type   = $cgi->param('type');
my $id     = $cgi->param('id');

my $html = RGD::HTML->new();
# for local test purpose

my $baseURL=$html->get_baseURL;   # http://rgd.mcw.edu
my $baseCGI=$html->get_baseCGI;   # http://rgd.mcw.edu/tools

my %notes=undef;
my %note_types=undef;
my %note_cnt = undef;
my $remote_IP = $ENV{'REMOTE_ADDR'};
my $access_IP = "141.106";

print "Content-type:text/html \n\n";
print <<JS;
<SCRIPT LANGUAGE="JavaScript">
function popWin(type,id) {
  if(type == '') {
    alert("Please select note type!");
    return;
  } else {
  var w = window.open("$baseCGI/notes/notes_view.cgi?key="+type+"&ID="+id,"Window_Handler","width=400,height=500,toolbar=no,menubar=yes,scrollbars=yes,resizable=yes");
  }
}

</SCRIPT>
JS

my %DisplayType = ( gene_expression => 'Expression',
                    gene_disease => 'Disease',
                    gene_general => 'Other',
                   );

&get_note_type;

if($id){
  my $record = &get_notes;
  
  if($record){
      &display_notes;
  }else{
    print "!notes not found!";
  }
}else{
  &display_note_form;
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

sub get_notes{
  my $sql = "SELECT NOTE_KEY,NOTES_TYPE_NAME_LC,PUBLIC_Y_N,
                 NOTES,CREATION_DATE
            from NOTES where RGD_ID = $id ";
  #print "$sql";
  my ($r, @records) = $db->query_Data(5,$sql);

  if($r){
   
    foreach my $n (@records){
      my ($key,$type,$pub,$notes,$date)=split(/::/,$n);
      
      $note_types{$type}->{'key'} .=$key.",";
      $note_types{$type}->{'total'}++;
      $note_types{$type}->{'public'}++ if($pub =~ "$public");
      $note_types{$type}->{'flag'} .=$pub.",";
      $note_cnt{$type}->{$key}->{'notes'}=$notes;
      $note_cnt{$type}->{$key}->{'pub'}=$pub || "Dis";
      $note_cnt{$type}->{$key}->{'date'}=$date || "missing";
    }
  }
  return $r;
}

sub display_notes{
  
=head1 form
  print "<form name=notesForm> View Notes <select name=key onChange=popWin((this.options[this.selectedIndex].value),\"$id\");>";
  print "<option value=\"\">Select Notes";  
  foreach my $t (keys (%note_types)){
    if($t){
      my $desc = $notes{$t}->{'desc'};
      my $key  = $note_types{$t}->{'key'};
      chop $key;
      print "<option value=$t:$key>$desc ($note_types{$t}->{'total'} notes)";
    }  
  }
  print "</select>";
  print "</form>";
=cut


  # display public notes only
  # need to be displayed in an order of note_type as
  # Expression, then Disease, and finally General(Other)
  foreach my $type (sort {substr($b,6,1) cmp substr($a,6,1) } keys (%note_cnt)){
    print "<table border=0 cellpadding=0 cellspacing=0 width=620>";
    if($type) {
      my $keys = $note_types{$type}->{'key'};
      chop $keys;

      my $flags = $note_types{$type}->{'flag'};
      chop $flags;
      my @pub_flags = split(/,/,$flags);
      my @note_key = split(/,/,$keys);
      my $num = 1;
      my $flag = 0;

      print "<TR valign=top>";
      foreach my $f (@pub_flags) {
       if($f eq 'Y') {
        $flag = 1;
       }
      }

      if($flag) {
        print "<TD width=95><H4>$DisplayType{$type}</H4></TD>";
        print "<td colspan=2><table>";
        foreach my $key (@note_key){
          if($note_cnt{$type}->{$key}->{'pub'} eq 'Y') {
             print qq[<tr><td align=left><b>$num.</b> $note_cnt{$type}->{$key}->{'notes'}</td></tr>];
            $num++;
          }
        }
       print "</table></td>\n";
      }
      print "</tr>";
   }
   print "</table>\n";
 }

  
=hold

  if($remote_IP =~ /$access_IP/){     #display all notes
    
    print "<P><table border=1 cellpadding=0 cellspacing=0 width=650>";
    print "<tr><td colspan=4 align=center><h4>Internal display ($remote_IP)</h4></td>";
    print "<tr align=center><td>Note Type</td>";
    print "<td>Notes (<a href=\"$baseCGI/curation/online/main.cgi\">Edit Notes?</a>)</td>";
    print "<td width=100>Creation<br>Date</td>";
    print "<td width=30>Public?<br>(Y/N)</td></tr>\n";
    foreach my $type (keys (%note_cnt)){
      if($type){
	my $num = $note_types{$type}->{'total'};
	my $keys = $note_types{$type}->{'key'};
	chop $keys;
	print "<tr><td width=120 valign=top align=center>$notes{$type}->{'desc'}</td><td width=530 colspan=3><table border=0 cellpadding=0 cellspacing=5 width=530>";
	my @note_key = split(/,/,$keys);
	print "<ul>";
	foreach my $key (@note_key){
	  print "<tr><td width=400><li>$note_cnt{$type}->{$key}->{'notes'}</td>";
	  print "<td width=100>$note_cnt{$type}->{$key}->{'date'}</td>";
	  print "<td width=30 align=left>$note_cnt{$type}->{$key}->{'pub'}</td></tr>\n";

	}
	print "</ul>";
	print "</table></td></tr>\n";
      }
    }
    print "<tr><td colspan=4><dd>note: Y -- public, N -- private, Dis -- disabled</td></tr>";
    print "</table>\n";
  }

=cut


}      


sub display_note_form{
  print <<_FORM_;
<form method=post action="$baseCGI/notes/notes.cgi">
<table border=0>
  <tr><td>Enter RGD_ID:</td><td><input type=text name=id size=18></td></tr>\n
  <tr><td></td><td><input type=submit value="Submit"></td></tr>\n
  </table>
</form>
_FORM_

}
