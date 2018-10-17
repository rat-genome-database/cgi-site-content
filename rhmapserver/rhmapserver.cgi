#!/usr/bin/perl
#########################################################
#  file name:rhmapserver.cgi (was rh_placement.cgi)
#  author: JIAN LU
#  date: 3-22-1999
#  modified: 5-3-1999, made more user friendly
#            11-24-1999, Nathan, added look and feel
#            5-16-2000, JL use RGD::HTML  model
#            5-22-2000, ST edited opening page text,
#                       changed HTML module tool_dir to RHMAPSERVER
#		 1-22-2004, PB, added RH Map version option
########################################################
use lib '/rgd/tools/common';
use lib '/rgd/tools/common/RGD';
use RGD::HTML;
require "cgi-lib.pl";


# to customize the title, version and tool_dir
my $rgd = RGD::HTML->new(
			 title      => "Rat Radiation Hybrid Map Server",
			 version    => "1.1",
			 category   => "tools",
		       );
my $baseURL=$rgd->get_baseURL;   # http://rgd.mcw.edu
my $baseCGI=$rgd->get_baseCGI;   # http://rgd.mcw.edu/tools
my $wwwPATH=$rgd->get_wwwPATH;   # /rgd_home/rgd/WWW
my $toolPATH=$rgd->get_toolPATH; # /rgd_home/rgd/TOOLS

&ReadParse(*in);
#print "<p> *in\n";
# print HTML head
$rgd->html_head;

# tool start here
$rgd->tool_start;

#######################################################
# parsing values
#######################################################
my $action=$in{'action'};
my $user_id=$in{'user_id'}; # user_id is user's email address
my $user_id=lc($user_id);
$user_id=~ s/\s+//g;
my $section=$in{'section'}; # section number is time stamp
my $lod_cutoff=$in{'lod_cutoff'};

my $version=$in{'RHMAP_version'};

my @marker=split(/\0/,$in{'marker'});
my ($user_home,$user_subdir,$data,$ERROR);
if($in{'datafile'}) { $data=$in{'datafile'}; }
if($in{'datatext'}) { $data=$in{'datatext'}; }

# skip cell lines
my $cell_1=65;
my $cell_2=87;

# hybrids MIT genbridge panel=93, MCW rat panel=100
my $hybrids=106;
my $framework_hybrids=100;

my $user_home="$toolPATH/rhmapserver/data/user_data/$user_id";
my $user_subdir="$user_home/$section";

my $ERROR=undef;

if($action eq "") { 
  &Data_Form;
}

if($action eq "screen_data") { 
  if($data){
    &Check_Data; 
    if($ERROR) { &Data_Form; }
    else { &Screen_Vector; }
  }else{
    &Data_Form;
  }
}

#$rhmap_version = "3.0"; #DP

if($action eq "placement") { 
  if($user_id !~ /\@/ || !$user_id){
    $ERROR="<font color=red><b><-- Invalid email address</b></font>";
    &Check_Data;
    &Screen_Vector;
    
  }else{
    if(@marker) {
      print "<p>Sending the data ...";
      &Save_Data;
      &Run_Place_Marker;
      &JVscript;
    }else {
      &NoMarkers;
    }
  }
}
if($action eq "done") {
  &Post_Message;
}
####print "<p>version: $version section: $section lod_cutoff: $lod_cutoff user_id: $user_id\n";
####print "<p> system ($toolPATH/rhmapserver/run_place_markers.pl -v $version -u $user_id -s $section -l $lod_cutoff&)";
# tool page end here
$rgd->tool_end;

# print HTML foot
$rgd->html_foot;
##########################################################
#   END
#########################################################
exit;


##########################################################
#   No Markers
##########################################################

sub NoMarkers{
  
  print<<__NOMARKERS__;
    
    <h1>No Markers Selected</h1>
    <p>You did not select any markers to be run.  If you would like to submit some markers, 
    please use your browsers back button and submit your markers.
    <p>If you would like to submit some different markers, you may return to the 
    <a href="$baseURL/RHMAPSERVER/">RHMap Server</a> main page.
   
__NOMARKERS__
}

##########################################################
#    Data_Form   
##########################################################
sub Data_Form{
  my $form_file="$wwwPATH/RHMAPSERVER/cnt_index.shtml";
  open(FM,"$form_file");
  while(my $line=<FM>){
    $line=~ s/<\!--\#echo var=\"webroot\"-->/$baseURL/g;
    $line=~ s/<\!--\#echo var=\"toolroot\"-->/$baseCGI/g;
    next if($line=~ /include virtual/);
    print $line;
  }
  close(FM);
 
}

######################################################################
#  Check_Data
#####################################################################
sub Check_Data{ 
  my $datatext=$data;
  $datatext =~ s/,/\t/g;
  my @data=split(/\n/,$datatext);
  
  my $i=0;
  foreach $line (@data){
    $line =~ s/\s+/,/g;
    @line=split(/,/,$line);
    $marker=$line[0];
    $vector=$line[1];
    $vector=~ s/\s+//g;
    $marker=~ s/\s+//g;
    $marker[$i]=$marker;
    $vector[$i]=$vector;
    $str_len=length($vector);
    
    if($vector=~ /\D/ || $vector=~ /[3-9]/){
      $ERROR .="<li>marker <font color=red>$marker</font> has error in which one or more of the numbers is not equal to 0,1,or 2.</li>\n";
    }
    if($vector!~ /1/ ){
      $ERROR .="<li>marker <font color=red>$marker</font> has no scored value .</li>\n";
    }
    if($vector !~ /[01]/) {
      $ERROR .="<li>marker <font color=red>$marker</font> has invalid vector.</li>\n";
    }
    if($str_len > $hybrids) {
      $ERROR .="<li>marker <font color=red>$marker</font> has a vector greater than the length allowed. ($str_len > $hybrids)\.</li>\n";
    }
    if($vector eq "" || $vector !~ /[1]/) {
      $ERROR .="<li>marker <font color=red>$marker</font> has no vector.</li>\n";
    }
    $i++;
  }
  if($ERROR) {
    print "<H3>Error Message:</h3>\n<ul>$ERROR\n</ul>\n";
  }
}


######################################################################
#   Screen_Vector
#####################################################################
sub Screen_Vector{
  print<<TXT;
<p>The criteria for acceptable vector are
<ul>
   <li>total number of 2\'s < 10</li>
   <li>total number of 1\'s < 40 and > 9</li>
</ul>
<p><b>NOTE</b>: 2\`s of cell lines 65, 87, 101 through 106 are not counted since 
the framework data ignore those 2\'s.

<h3>Results</h3>
<p>Please use the following table to select the markers you would like to place 
on the map. If a marker is shaded with a red color, it has failed one or more 
catagory criteria. If the vector itself contains one or more red number 2\'s, those
ambiguous components were added by the  program to bring the vector length up to 
106. 
<p>Please uncheck any vectors you do not want to run:
<p>
<form method=post action="$baseCGI/rhmapserver/rhmapserver.cgi">
<p>Enter your email address to receive the results (required)
<br><input type=text name=user_id size=30 value=$user_id> $ERROR
<p>
<table border=1>
<tr><td>Check</td><td>Marker</td><td>Num_of_2\'s</td><td>Num_of_1\'s</td>
    <td>Vectors</td>
</tr>
TXT
  
  my $i=0;

  foreach $str (@vector){
    my $num_2=0;
    my $num_1=0;
    my $num_0=0;
    $str=~ s/\s+//g;
    $str=~ s/\D//g;
    $string_length=length($str);
    $length_diff=106 - $string_length;
    $string_2="22222222222222222222222222222222222222222222222222222222222222";
    $add_2=substr($string_2,0,$length_diff);
    $num_2= $str=~ s/2/2/g;
    $num_1= $str=~ s/1/1/g;
    $num_0= $str=~ s/0/0/g;
    
    if(($num_1 < 40 && $num_1 > 9) && $num_2 <= 10){
      print "<tr bgcolor=\"#CCCCCC\"><td><input type=checkbox checked name=marker value=\"$marker[$i]\"></td>\n
         <td>$marker[$i]</td><td>$num_2</td><td>$num_1</td>\n
         <td>$str<font color=red>$add_2</font></td></tr>\n";
    }else{
      print "<tr bgcolor=\"#CCCCCC\"><td>";
      print "<input type=checkbox checked name=marker value=\"$marker[$i]\"></td>\n";
      print "<td><font color=red>$marker[$i]</font></td><td>$num_2</td><td>$num_1</td>\n";
      print "<td>$str<font color=red>$add_2</font></td></tr>\n";
    }
    $i++;
  }
  
  print <<__TXT__;
</table>
<p>LOD CUTOFF <input type=text name=lod_cutoff value="10.0" size=5>   

<input type=hidden name="action" value="placement">
<input type=hidden name="datatext" value="$data">
<input type=hidden name="RHMAP_version" value="$version">
<input type="submit"  value="Run RH Placement">
</form>

<form method=post action="rhmapserver.cgi">
<input type=hidden name=datatext value=$data>
<input type=hidden name=user_id value=$user_id>
<input type=hidden name=RHMAP_version value=$version>
<input type=submit value="Back to Text Form">
</form>
__TXT__
}

######################################################################
#   Save_Data
#####################################################################
sub Save_Data{  
  $DATE=`/bin/date`;
  $section=time();
  $user_subdir="$user_home/$section";
  `mkdir  -m 777 -p $user_home`;
  `mkdir  -m 777 -p $user_subdir`;
  
  
  my $datatext=$data;
  $datatext =~ s/,/\t/g;
  my @data=split(/\n/,$datatext);
  
  open(DAT,">$user_subdir/rhdata\.dat") || print "cannot open file\n";
  open(RAW,">$user_subdir/rhdata\.raw") || print "cannot open file\n";
  open(SUB, ">>$toolPATH/rhmapserver/data/submission/$user_id") || print "cannot open file\n";
  print SUB "//$section\t$DATE";
  my $i=0;
  my $new_vector="";
  foreach $line (@data){
    $line =~ s/\s+/,/g;
    $string=$line;
    $string=~ s/,/\t/g;
    chomp($string);
    @line=split(/,/,$line);
    $marker=$line[0];
    $vector=$line[1];
    $vector=~ s/\D//g;
    
    $string_length=length($vector);
    $length_diff=106 - $string_length;
    $string_2="22222222222222222222222222222222222222222222222222222222222222222";
    $add_2=substr($string_2,0,$length_diff);
    $new_vector=$vector.$add_2;
    
    $marker=~ s/\s+//g;
    foreach $mk (@marker){
      if($marker eq "$mk"){
	print DAT "$marker\t$new_vector\n";
	#		print "$marker\t$vector\n<br>";
	print RAW "$string\n";
	print SUB "$string\n";
      }
    }
  } 
  close(DAT);
  close(RAW);
  close(SUB);
}

###################################################
#  JVscript for redirecting subject
###################################################
sub JVscript{
  print <<__JS__;
  <SCRIPT LANGUAGE="JavaScript"><!--
window.location.href = '$baseCGI/rhmapserver/rhmapserver.cgi?user_id=$user_id&section=$section&action=done&RHMAP_version=$version&lod_cutoff=$lod_cutoff';
//--></SCRIPT>
__JS__
}

###################################################
#  Post_Message
###################################################
sub Post_Message{
  open(DAT, "$user_subdir/rhdata\.raw");
  @data=<DAT>;
  close(DAT);
  
  print <<EOF;
<p><hr>
<!--
<h1>Notice</h1>
<p><b>Since our network configuration changed, the RH Map Server mail is not functioning now.
<br>After you submit the data, please stay online to retrieve your results by clicking 
<a href="rhmap_placement.cgi?user_id=$user_id&section=$section&version=$version">HERE</a>, 
<br>or write down
the section number and come back to get your results through this URL:
<a href="$baseCGI/rhmapserver/rhmap_placement.cgi">$baseCGI/rhmapserver/rhmap_placement.cgi</a> by entering your email address and the section number. 
</b>
<p>We are working on this issue and sorry for any inconvenience.
<p><hr>
-->
    <h2>Thank You</h2>
    <p>We hope your submission process was easy.  If you have any suggestions 
    to streamline the data submission process, or simplify your work online, send the 
    <a href='mailto:mapserver\@rgd.mcw.edu?subject=RGD:TOOLS:MAPPING:RHP'>RGD Map Server</a> 
    your comments..

    <h3>Your Results</h3>
    <p>You will be notified by an email as soon as the server has completed the processing 
of your data.
    You may also click
<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&version=$version"><font color=red size=3>HERE</font></a> 
    to check your results available. 
<!--
<p>version: $version section: $section lod_cutoff: $lod_cutoff user_id: $user_id
<p>($toolPATH/rhmapserver/run_place_markers.pl -v $version -u $user_id -s $section -l $lod_cutoff&)
-->

    <h3>Data Management Policy</h3>
    <p>Your results will only be kept for a total of THREE days. Please check your results 
     as soon as you recieve your email notification to ensure that you can take 
     advantage of your submissions.
     <p>You may
also delete your data by your own through our online service.

<p>You submitted the following data for RH placement:
<p><table border=0>
EOF

  foreach $_ (@data){
    @line=split(/\t/,$_);
    print "<tr><td>$line[0]</td><td>$line[1] $line[2] $line[3]</td></tr>\n";
  }
  print "</table>";
  print "<p><a href=\"$baseURL/RHMAPSERVER/\">Do another placement</a>";
}

###################################################
#  Run_Placement_Marker
###################################################
sub Run_Place_Marker{
  $user_id=~ s/\0//g;
  $user_id=~ s/\s+//g;
#  print "<p> run run_place_markers.pl to start placement at background";
  #system ("$toolPATH/rhmapserver/run_place_markers.pl $user_id $section $lod_cutoff $rhmap_version &");
  system ("$toolPATH/rhmapserver/run_place_markers.pl -v $version -u $user_id -s $section -l $lod_cutoff&");
}
