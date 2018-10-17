package RGD::HTML;

#############
#
# HTML object for RGD v2 - increased flexibility to add meta
# information to the page
#
#############

use strict;
require 5.003;

# Below line added by DP 6-20-01
use lib "/rgd/tools/common";

use RGD::DB;  # Put at top to be global DP 6-20-01
my $db = RGD::DB->new();

################
#
# 1/26/01 - Fixed map display for cytogenetic map and band locations. Simon T.
# 6/25/2002 - added sub show_notes, JL
# 11/10/2003 - modified sub html_head and tool_start, Weihong J.
#
################


sub new {
      my ($class, %arg)  = @_;
      
      bless {
      _title        => $arg{title}       || "Rat Genome Database",
      _doc_title    => $arg{doc_title}   || "",
      _version      => $arg{version}     || "3.0",
      _show_version => $arg{show_version}|| 0,
      _tool_dir     => $arg{tool_dir}    || "",
      _link_dir     => $arg{link_dir}    || "",
      _help_title   => $arg{help_title}  || "Main Help Page",
      _help_url     => $arg{help_url}    || "/help.html",				      
      _style_url    => $arg{style_url}   || "/common/style/rgd_styles.css",
      _base_url     => $arg{base_url}    || "",
      _base_cgi     => $arg{base_cgi}    || "/tools",
      _www_path     => $arg{www_path}    || "/rgd/www",
      _tool_path    => $arg{tool_path}   || "/rgd/tools",
      _data_path    => $arg{data_path}   || "/rgd/data",
      _log_path     => $arg{log_path}    || "/rgd/logs",
      _category     => $arg{category}    || "data",   # added on 11/10/2003.
      _show_sidebar => $arg{show_sidebar}|| "yes",    # added on 11/10/2003.
      _desc => $arg{desc} || "",
      _keywords => $arg{keywords} || "genes, qtl, strain, rat", 
      },$class;
}# end of new

# accessor methods for  web and system global variables
sub get_baseURL{
  return  $_[0]->{_base_url};
}
sub get_baseCGI{ 
  return  $_[0]->{_base_cgi};
}
sub get_wwwPATH{
  return  $_[0]->{_www_path};
}
sub get_toolPATH{
  return  $_[0]->{_tool_path};
}

sub get_dataPATH{
  return  $_[0]->{_data_path};
}

sub get_logPATH{
  return  $_[0]->{_log_path};
}

sub get_domain{
  return  $_[0]->{_domain};
}

####
#
# returns the content type and opens the <HEAD> tag
#
###

sub _html_contentType {
  my ($no_content)=@_;
  my ($tag);
  if($no_content){
      $tag = <<"__end_of_tag__";
__end_of_tag__
  }else{
    $tag = <<"__end_of_tag__";
Content-type: text/html

__end_of_tag__
  }
  return $tag;
}



####
#
# returns the content type and opens the <HEAD> tag
#
###

sub _html_tags {
  my ($no_content)=@_;
  my ($tag);
  if($no_content){
      $tag = <<"__end_of_tag__";
<HTML>
<HEAD>
__end_of_tag__
  }else{
    $tag = <<"__end_of_tag__";
Content-type: text/html

<HTML>
<HEAD>
__end_of_tag__
  }
  return $tag;
}

#
# Print out google analytics information on this page. 
# Tracked in the rgd.user@gmail.com account . See george / mary for password. 
#
sub printGoogle { 

 print '<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">';
 print '</script>';
 print '<script type="text/javascript">';
 print '_uacct = "UA-2739107-2";';
 print 'urchinTracker();</script>';
 print "\n";

}

sub html_head{
  
  my $self = shift @_;
  my $no_content_type = shift; # to specify not need Content-type 
  my $wwwPATH = $self->{_www_path};
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  my $styleURL= $self->{_style_url};
  my $title   = $self->{_title};
  my $desc = $self->{_desc};
  my $keywords = $self->{_keywords};
 
  my $category = $self->{_category};   # added on 11/10/2003;

  # the Content type and start of head tags
  print &_html_contentType($no_content_type); 
  
  # add in the search area from standard.html
  my $header = "$wwwPATH/common/header/standard.shtml";

  open(HD,"$header");
  while (my $line=<HD>){
    next if($line=~ /include virtual/);
    $line =~ s/--title--/$title/;
    
    if ($desc eq "") {
        $line =~ s/--desc--//;
    } else {    
      $line =~ s/--desc--/<meta name=\"description\" content=\"$desc\" \/>/;
    } 

    print $line;
  }
  close(HD);
}

sub html_foot{
  my $self = shift @_;
  my $wwwPATH = $self->{_www_path};
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};


  my $footer="$wwwPATH/common/footer/standard.shtml";
  open(FT,"$footer");
  while (my $line=<FT>){
    next if($line=~ /include virtual/);
    print $line;
  }
  close(FT); 
}



# tool_start
sub tool_start{
  my $self = shift @_;
  my $wwwPATH = $self->{_www_path};
  my $toolDIR = $self->{_tool_dir};
  my $linkDIR = $self->{_link_dir};
  my $toolPATH= $self->{_tool_path};
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  my $tool_dir="$wwwPATH/$toolDIR";
  my $link_dir="$wwwPATH/$linkDIR";
  my $toolfile="$tool_dir/tools.shtml";

  my $category = $self->{_category};  # added on 11/10/2003;
  my $showSidebar = $self->{_show_sidebar};  # added on 11/10/2003;
  
  
  # added on 11/19/2003;
  my $linkfile;
  if($category eq "forum") {
     $linkfile="$link_dir/common/navigation/sidebar2.shtml";
  }
  else{
     $linkfile="$link_dir/links.shtml";  
  }
  

  ###########
  # following template's modified on 11/10/2003;
  ###########

  my $myshimimage = "$baseURL/common/images/shim.gif";
  my $mybkgdimage = "$baseURL/common/images/dotline2.gif";

  if ($showSidebar eq "no" ) {
      
    print<<__TOOLSTART0__;
    
      <TABLE border="0" cellpadding="0" cellspacing="0" width="100%">
        <TR>
          <TD width="74"><img src="$myshimimage" width="74" height="1"></TD>
          <TD valign="top" width="100%">

__TOOLSTART0__

  }

  else {

    print<<__TOOLSTART1__;

      <TABLE border="0" cellpadding="0" cellspacing="0" width="100%">
        <TR>
          <TD valign="top" align="left" > 
          <!-- SIDE BAR --> 
        <TABLE border="0" cellpadding="0" cellspacing="0" width="115">
          <TR>
             <TD valign="top" align="left"><div class="sidebar">

__TOOLSTART1__


      if (-e $linkfile) {
        open(FT,"$linkfile");
        while (my $line=<FT>){
          $line=~ s/<\!--\#echo var=\"webroot\"-->/$baseURL/g;
          $line=~ s/<\!--\#echo var=\"toolroot\"-->/$baseCGI/g;
          next if($line=~ /include virtual/);
      
          print $line;
        }
        close(FT);
      }


      print<<__TOOLSTART2__;

             </div>  </TD>
            </TR>
          </TABLE>
        </TD>
        <TD width="1" bgcolor="#E6E6E6"><img src="$myshimimage" width="1" height="1"></TD>
        <TD width="20"><img src="$myshimimage" width="20" height="1"></TD>
        <TD valign="top" width="100%">
   
__TOOLSTART2__

  }


  print "<img src=$myshimimage width=1 height=10><br>"; # added 11/10/2003;
  
  print "<h2>$self->{_doc_title}</h2>\n" if($self->{_doc_title});
  print "<h4>Version: $self->{_version}</h4>\n" if(($self->{_version}) && ($self->{_show_version}));

}





# tool_end
sub tool_end{
  print<<__TOOLEND__;

       </TD>
       <TD width="20">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</TD>
    </TR>
</table>

__TOOLEND__
}


sub view_notes {

  my ($self, $db, @rgd_ids) = @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};

  print "\t<h3>Related Notes</h3>\n";
  # print "\t<p>To add a note to this record, <a href='/tools/notes/notes.cgi?id=$rgd_ids[0]'>click here</a>\n";
     
  my %notes = $db->get_rgd_id_notes("", @rgd_ids);
 
  if (keys %{$notes{$rgd_ids[0]}}) {
  
    print "\t<table border=0 cellpadding=3 cellspacing=0>\n";
    print "\t<tr><td class=label>Note Type</td>\n";
    print "\t    <td class=label>Creation Date</td>\n";
    print "\t    <td class=label>Notes</td></tr>\n";
  
    my $note_key ="";

    foreach $note_key (sort keys %{$notes{$rgd_ids[0]}}) {
       
      print "\t\t<tr><td valign=top>$notes{$rgd_ids[0]}{$note_key}{'note_type_name_lc'}</td>\n";
      print "\t\t    <td valign=top>$notes{$rgd_ids[0]}{$note_key}{'creation_date'}</td>\n";
      print "\t\t    <td valign=top>$notes{$rgd_ids[0]}{$note_key}{'notes'}</td></tr>\n";
       
    }

    print "\t</table>";
     
  } else {
     
    print "<p>No related notes\n";

  } 
  
}


##########
#
# get_xdb_html
#
# returns the html code for the xdb links for a given RGD id
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
# Moved from DB.pm to HTML.pm December 14th 2000
# Added if clause for RHDB link DP 6-20-01
# Revised in order to display multiple ids to one database DP 1-2-02
# Revised to truncate off the Rn. of Unigene Ids DP 11-18-02
###########


sub get_xdb_html {
      my ($self, $db_ref, $rgd_id) = @_;  
  my %xdb_list = ();
  my %xdbs = ${$db_ref}->get_rgd_id_xdb($rgd_id);
  my $html_text;
  $html_text .= "<table>\n";
foreach my $xdb_type (sort keys %{$xdbs{$rgd_id}}) {  
  my @acc=undef;
  my $len = undef; 
  my @link=undef;
  chop $xdbs{$rgd_id}{$xdb_type}{acc_id};  #DP think that the DB.pm module changed #DP 11-01-02
  chop $xdbs{$rgd_id}{$xdb_type}{acc_id};
  chop $xdbs{$rgd_id}{$xdb_type}{link_text};
  chop $xdbs{$rgd_id}{$xdb_type}{link_text};
  @acc= split (/::/, $xdbs{$rgd_id}{$xdb_type}{acc_id});
  @link= split (/::/,$xdbs{$rgd_id}{$xdb_type}{link_text});
  $len = scalar @acc;
  $len=$len-1;

  
  if($xdbs{$rgd_id}{$xdb_type}{xdb_key} eq "9") { #RHdb
    $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
    for my $i (0 .. $len){ 
      my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}"."$acc[$i]";   
      $html_text .= "<tr><td><dd><a href=\"$url"."']\">$link[$i]</a>($acc[$i])</td></tr>\n "; 
    }
  }    
  elsif ($xdbs{$rgd_id}{$xdb_type}{xdb_key} eq "2"){  #Pubmed
    $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
    for my $i (0 .. $len){
      my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}"."$acc[$i]"; 
      $html_text .="<tr><td><dd><a href=\"$url\">"."$link[$i]"."</a> ($acc[$i]) </td></tr>\n";
    }
  }
### DP 11-18-02
  elsif ($xdbs{$rgd_id}{$xdb_type}{xdb_key} eq "4"){  #Unigene
    $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
    for my $i (0 .. $len){
      $acc[$i]=~ s/Rn.//g;
      my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}"."$acc[$i]"; 
      $html_text .="<tr><td><dd><a href=\"$url\">"."$link[$i]"."</a> ($acc[$i]) </td></tr>\n";
    }
  }
###
### DP 06-14-04
  elsif ($xdbs{$rgd_id}{$xdb_type}{xdb_key} eq "17"){  #KEGG
    $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
    for my $i (0 .. $len){

      my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}:"."$acc[$i]"; 
      $html_text .="<tr><td><dd><a href=\"$url\">"."$link[$i]"."</a> ($acc[$i]) </td></tr>\n";
    }
  }
###
### DP 02-02-04
  elsif ($xdbs{$rgd_id}{$xdb_type}{xdb_key} eq "18"){  #Germonline
    $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
    for my $i (0 .. $len){
      my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}:"."$acc[$i]"; 
      $html_text .="<tr><td><dd><a href=\"$url\">"."$link[$i]"."</a> ($acc[$i]) </td></tr>\n";
    }
  }
###  
   else{
    if($xdbs{$rgd_id}{$xdb_type}{link_text}){
      $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
      for my $i (0 .. $len){ 
	my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}"."$acc[$i]";  
	$html_text .= "<tr><td><dd><a href=\"$url\">"."$link[$i]"."</a> ($acc[$i])</td></tr>\n"; 
      } 
    }  
    else{
      $html_text .= "<tr><td><b>$xdbs{$rgd_id}{$xdb_type}{xdb_name} </b></td></tr>\n";
      for my $i (0 .. $len){ 
	my $url = "$xdbs{$rgd_id}{$xdb_type}{xdb_url}"."$acc[$i]";  
	$html_text .="<tr><td><dd><a href=\"$url\">"."$acc[$i]"."</a></td></tr>\n "; 	
      }
    }
  }
} #end of foreach 
$html_text .= "</table>\n";
 

return $html_text;

} #End of sub get_xdb_html


##########
#
# get_citation_html
#
# returns the html code for the citations for a given RGD id
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
#
###########

sub get_citation_html {

  my ($self, $db_ref, $rgd_id) = @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  # Strip any RGD: prefixes
  $rgd_id =~ s/^RGD://;

  my @ref_keys = split ',', ${$db_ref}->get_ref_keys($rgd_id);
  my %refdata = ();

  my $citations = "";
  my $citation_count = 1;

  if($ref_keys[0]) {
    $citations = "<table cellpadding=2>\n";
    foreach my $ref (@ref_keys) {
      
      my %data = ${$db_ref}->get_ref_data($ref);
      
      $refdata{$ref} = { %data};
      
      $citations .= "<tr valign=\"top\" class=\"citationRow\"><td><b>$citation_count:</b></td><td><a href=\"$baseCGI/query/query.cgi?id=$refdata{$ref}{rgd_id}\">$refdata{$ref}{citation}</a></td></tr>\n";
      $citation_count++;
    }
$citations .= "</table>\n";

    # if($ref_keys[0]) {
    return $citations;
  }
  else {
    return "No references are currently curated for this object</p>\n";
  }
  
  

} # end of get_citation_html

##########
#
# get_nomen_html
#
# returns the html code for the nomenclature events for a given RGD id or original RGD ID
#
# Author: Simon T. 5/19/00
# Added:  5/19/00 by Simon T.
#
###########
sub get_nomen_html { #Modified by Tan Liu 8-28-03

  my ($self, $db_ref, $rgd_id, $object) = @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  # Strip any RGD: prefixes
  $rgd_id =~ s/^RGD://;
  
  my %nomen = ${$db_ref}->get_nomen_events($rgd_id,$object);

  
  my $nomen_text = "No Nomenclature events are recorded for this object";

  my @debug = keys % nomen;
  if(%nomen) {
    
    $nomen_text = "<table>\n";
    $nomen_text .= "<tr class=\"mapDataHeader\" valign=\"top\"><td class=submenu>Date</td>\n";
    $nomen_text .= "<td class=submenu>Current Symbol</td>\n";
    $nomen_text .= "<td class=submenu>Current Name</td>\n";
    $nomen_text .= "<td class=submenu>Previous Symbol</td>\n";   
    $nomen_text .= "<td class=submenu>Previous Name</td>\n";   
    $nomen_text .= "<td class=submenu>Status</td>\n";
    $nomen_text .= "<td class=submenu>Description</td>\n";
    $nomen_text .= "<td class=submenu>Reference</td></tr>\n";

    #my @events = sort ( keys %nomen);
    #my @revEnt = reverse (@events);    

     my %rHash = ();
     my $aTime = undef;
     foreach my $e (keys %nomen)
     {
         #print "$nomen{$e}{event_date} ";
         $aTime = &convertDate($nomen{$e}{event_date});
         $rHash{$aTime} = $e;
         # warn "$aTime;";
     }
     # warn "\n";
     my @events = sort (keys %rHash);
     my @revEnt = reverse (@events);
     

    foreach my $e (@revEnt) {
      my  $event = $rHash{$e};
      $nomen_text .= "<tr valign=top><td class=submenu>$nomen{$event}{event_date}:</td>\n";
      $nomen_text .= "<td class=submenu><a href=\"$baseCGI/query/query.cgi?id=$nomen{$event}{original_rgd_id}\">$nomen{$event}{object_symbol}</a></td>\n";
      
      if($nomen{$event}{object_name}){
      	$nomen_text .= "<td class=submenu>$nomen{$event}{object_name}</td>\n";
      }else{
	 $nomen_text .= "<td class=submenu>NA</td>\n";
      }
      
      if($nomen{$event}{prev_sym}){	
	$nomen_text .= "<td class=submenu>$nomen{$event}{prev_sym}</td>\n";
      }else{
	$nomen_text .= "<td class=submenu>NA</td>\n";	
      }
      if($nomen{$event}{prev_name}){
      	$nomen_text .= "<td class=submenu>$nomen{$event}{prev_name}</td>\n";
      }else{
      	$nomen_text .= "<td class=submenu>NA</td>\n";
      }
      if($nomen{$event}{nomen_status_type}){
	$nomen_text .= "<td class=submenu>$nomen{$event}{nomen_status_type}</td>\n";
      }else{
      	$nomen_text .= "<td class=submenu>NA</td>\n";
      }
     
      if($nomen{$event}{description}){
      	$nomen_text .= "<td class=submenu>$nomen{$event}{description}</td>\n";
      }else{
      	$nomen_text .= "<td class=submenu>NA</td>\n";
      }
      $nomen_text .= "<td class=submenu><a href=\"/rgdweb/report/reference/main.html?id=RGD:$nomen{$event}{ref_rgd_id}\">$nomen{$event}{ref_rgd_id}</a></td></tr>\n";
      
    }
    $nomen_text .= "</table>\n";
  }

return $nomen_text;


} # end of get nomen html

##########
# convertDate
##########
sub convertDate
{
   my $myDate = shift @_;

   my %months1 = ( 
	'JAN' => '01',
	'FEB' => '02',
	'MAR' => '03',
	'APR' => '04',
	'MAY' => '05',
	'JUN' => '06',
	'JUL' => '07',
	'AUG' => '08',
	'SEP' => '09',
	'OCT' => '10',
	'NOV' => '11',
	'DEC' => '12',
	);

    my @dates = split /-/, $myDate;
    my $res = undef;

    # warn "@dates\n";

    $dates[1] =~ s/\s*//g;
    # warn "--$months1{'FEB'}--";
    # right now hard coded here.
    if ($dates[2] lt '50') {$dates[2] = '20'.$dates[2];}
    else{$dates[2] = '19'.$dates[2]; }

    $res = $dates[2].$months1{$dates[1]}.$dates[0];
    return $res;
}


sub new_get_nomen_html {

  my ($self, $db_ref, $rgd_id, $object, $noHtml) = @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  # Strip any RGD: prefixes
  $rgd_id =~ s/^RGD://;
  
  my %nomen = ${$db_ref}->get_nomen_events($rgd_id,$object);
  
  	my $nomen_text = "No Nomenclature events are recorded for this object";
	my $currentStatus = "";
  #print "$nomen_text";
  if(%nomen) {
    
    $nomen_text = "<table>\n";
    $nomen_text .= "<tr><td class=submenu>Date</td>\n";
    $nomen_text .= "<td class=submenu>Current Symbol</td>\n";
    $nomen_text .= "<td class=submenu>Current Name</td>\n";
    $nomen_text .= "<td class=submenu>Previous Symbol</td>\n";   
    $nomen_text .= "<td class=submenu>Previous Name</td>\n";   
    $nomen_text .= "<td class=submenu>Status</td>\n";
    $nomen_text .= "<td class=submenu>Description</td>\n";
    $nomen_text .= "<td class=submenu>Reference</td></tr>\n";

    #my @events = sort ( keys %nomen);
    #my @revEnt = reverse (@events);    

     my %rHash = ();
     my $aTime = undef;
     foreach my $e (keys % nomen)
     {
         $aTime = convertDate($nomen{$e}{event_date});
         $rHash{$aTime} = $e;
     }
     my @events = sort (keys % rHash);
     my @revEnt = reverse (@events);
     

	
    foreach my $e (@revEnt) {
        my  $event = $rHash{$e};
    	
    	$currentStatus = $nomen{$event}{nomen_status_type} if !$currentStatus;
    	
 
      #print "$event ";
      $nomen_text .= "<tr valign=top><td class=submenu>$nomen{$event}{event_date}:</td>\n";
      $nomen_text .= "<td class=submenu><a href=\"$baseCGI/query/query.cgi?id=$nomen{$event}{original_rgd_id}\">$nomen{$event}{object_symbol}</a></td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{object_name}</td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{prev_sym}</td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{prev_name}</td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{nomen_status_type}</td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{description}</td>\n";
      $nomen_text .= "<td class=submenu><a href=\"/rgdweb/report/reference/main.html?id=RGD:$nomen{$event}{ref_rgd_id}\">$nomen{$event}{ref_rgd_id}</a></td></tr>\n";
      
    }
    $nomen_text .= "</table>\n";
  }


if($noHtml) {
	return $currentStatus || "Unknown";
}
else {
	return $nomen_text;
}

} # end of get nomen html



sub old_get_nomen_html {

  my ($self, $db_ref, $rgd_id, $object) = @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  # Strip any RGD: prefixes
  $rgd_id =~ s/^RGD://;
  
  my %nomen = ${$db_ref}->get_nomen_events($rgd_id,$object);
  
my $nomen_text = "No Nomenclature events are recorded for this object";

  if(%nomen) {
    
    $nomen_text = "<table>\n";
    $nomen_text .= "<tr><td class=submenu>Date</td>\n";
    $nomen_text .= "<td class=submenu>Symbol</td>\n";
    $nomen_text .= "<td class=submenu>Name</td>\n";
    $nomen_text .= "<td class=submenu>Status</td>\n";
    $nomen_text .= "<td class=submenu>Description</td>\n";
    $nomen_text .= "<td class=submenu>Reference</td></tr>\n";


    foreach my $event (keys %nomen) {
      
      $nomen_text .= "<tr valign=top><td class=submenu>$nomen{$event}{event_date}:</td>\n";
      $nomen_text .= "<td class=submenu><a href=\"$baseCGI/query/query.cgi?id=$nomen{$event}{original_rgd_id}\">$nomen{$event}{object_symbol}</a></td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{object_name}</td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{nomen_status_type}</td>\n";
      $nomen_text .= "<td class=submenu>$nomen{$event}{description}</td>\n";
      $nomen_text .= "<td class=submenu><a href=\"/rgdweb/report/reference/main.html?id=RGD:$nomen{$event}{ref_rgd_id}\">$nomen{$event}{ref_citation}</a></td></tr>\n";
      
    }
    $nomen_text .= "</table>\n";
  }

return $nomen_text;


} # end of get nomen html


sub show_notes{
  
  my ($self,$id) = @_;
  my $baseCGI = $self->{_base_cgi};
  use LWP::Simple;
  my $url = "$baseCGI/notes/notes.cgi?id=$id"; 
 
  my $content = LWP::Simple::get($url);
  
  if($content !~ /\!notes not found\!/){
    #print "<p><hr><h3>Curation Notes</h3>$content";
    print "<p>$content";
  }
}


#####################################################
# purpose:  display Notes information for objects except Genes on Web site
# modified by Jiali chen  11/06/06
####################################################
sub display_notes {
  my ($self,$rgd_id,$object_key) = @_;
  my $baseCGI = $self->{_base_cgi};
 
  my %note=(); ##undef;
 
  my $sql = 'select n.note_key, n.notes, t.note_desc from notes n, note_types t '
           ."where n.rgd_id = ? and public_y_n = 'Y' and t.NOTES_TYPE_NAME_LC = n.NOTES_TYPE_NAME_LC ";

  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr $sql \n";
  $sth->execute($rgd_id) or die "Can't execute statement: $DBI::errstr $sql";
 
  my $sql_ref_id = 'select r.rgd_id from note_ref_id n, references r ';
  $sql_ref_id .= ' where  n.note_key = :note_key and r.ref_key = n.ref_key ';
  my $sth_ref_id=$db->{dbh}->prepare($sql_ref_id) or die "Can't Prepare statement: $DBI::errstr $sql_ref_id\n";
 
  while (my ($note_key, $note, $type) = $sth->fetchrow_array() ){
    $sth_ref_id->bind_param(':note_key',$note_key);
    $sth_ref_id->execute or die "Can't execute statement: $DBI::errstr $sql";
    my $refs = '';

    while (my $ref_rgd_id = $sth_ref_id->fetchrow_array() ){
      if($refs){
        $refs .= ", <A href=\"$baseCGI/query/query.cgi?id=RGD:$ref_rgd_id\">$ref_rgd_id</A>";
      }else{
        $refs = "<A href=\"$baseCGI/query/query.cgi?id=RGD:$ref_rgd_id\">$ref_rgd_id</A>";
      }
    }

    next if ($type =~ /curation comments/i );

    if($object_key == 6){   ## qtls
      next if ($type =~ /QTL Cross Pair/ or $type =~ /QTL Cross Type/ or $type =~ /Related QTLs/);
    }
    $refs = "&nbsp;" unless $refs;
    
    unless($note{$type}){
      $note{$type} = "$note#=#$refs";
    }else{
      $note{$type} .= "&=&$note#=#$refs";
    }
  } 
  $sth->finish;
  $sth_ref_id->finish;

  ## display notes information on Web site ##
  if(scalar(keys %note)){
    print "<BR><HR><BR><A name='Anno'></A>\n";
    print "<h3>Annotations:</h3>\n";
    print "<TABLE width=\"100%\" valign=\"left\" border=\"1\" cellspacing=\"0\" cellpadding=\"2\">\n";
	print "<TR bgcolor=\"#cccccc\"><TD><B>Note</B></TD><TD><B>Reference</B></TD></TR>\n";
    if($object_key == 6){   ## qtls
      my $type = "Disease";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Gene";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Mapping";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Other";
      print_note_info($type, $note{$type}) if $note{$type};
    }elsif($object_key == 3){   ## sslps
      my $type = "SSLPs General";
      print_note_info($type, $note{$type}) if $note{$type};
    }elsif($object_key == 5){   ## strains
      my $type = "General";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Reproduction";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Lifespan and Spontaneous Disease";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Physiology and Biochemistry";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Immunology";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Infection";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Drugs and Chemicals";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Anatomy";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Behavior";
      print_note_info($type, $note{$type}) if $note{$type};
      $type = "Other";
      print_note_info($type, $note{$type}) if $note{$type};
    }
    print "</TABLE>\n";
  } 

} ## end sub display_notes


############################
sub print_note_info {
  my ($type, $note_info) = @_;
  my @notes = split(/&=&/, $note_info);

  print "<TR><TD colspan=\"2\" bgcolor=\"#e0e0e0\"><B>$type</B></TD></TR>\n";
  foreach my $note_ref (@notes) {
    my ($note, $ref) = split(/\#=\#/, $note_ref);
    print "<TR valign=\"top\"><TD>$note</TD><TD>$ref</TD></TR>\n";
  }

} ## end sub print_note_info 


#####################################################
# purpose:  display Ontology information on Web site
#           for objects except Genes 
# author :  Jiali Chen 
# date   :  11-06-06
#####################################################
sub display_ontology{
  my ($self,$rgd_id,$object_key) = @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};

  my %ASPECT = (
              C => "Cellular Component",
              P => "Biological Process",
              F => "Molecular Function",
              N => "Phenotype",
              D => "Disease",
              B => "Behavior",
              W => "Pathway",
             );


  my %TYPE  = (
              C => 'go',
              P => 'go',
              F => 'go',
              N => 'po',
              D => 'do',
              B => 'bo',
              W => 'wo',
             );


  my $sql = "select term,evidence,aspect,ref_rgd_id,with_info,term_acc,qualifier,notes,data_src ";
  $sql .= "from full_annot ";
  $sql .= "where RGD_OBJECT_KEY = $object_key ";
  $sql .= "and ANNOTATED_OBJECT_RGD_ID = ? ";
  $sql .= "order by term  ";

  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr $sql";
  $sth->execute($rgd_id) or die "Can't execute statement: $DBI::errstr $sql";

  my %xdb_urls = (
            MGI => 'http://www.informatics.jax.org/searches/accession_report.cgi?id=MGI:',
            'Swiss-Prot' => 'http://expasy.org/cgi-bin/sprot-search-de?',
			'SP_KW' => 'http://expasy.org/cgi-bin/sprot-search-de?',
            'rno' => 'http://www.genome.ad.jp/dbget-bin/show_pathway?rno',
			'RGD' => '/tools/genes/genes_view.cgi?id=',
			'UniProtKB' => 'http://www.pir.uniprot.org/cgi-bin/upEntry?id=',
            'Ensembl' => 'http://www.ensembl.org/Rattus_Norvegicus/geneview?gene=',
            'InterPro' => 'http://www.ebi.ac.uk/interpro/IEntry?ac=',
            );
  my %ont;

  while (my ($term,$evid,$aspect,$ref_rgd_id,$with,$term_acc,$qlf,$note,$src) = $sth->fetchrow_array()) {

    my $rgd_ont_url="<A HREF=\"/rgdweb/ontology/annot.html?acc_id=$term_acc\">";

    my $xdb_ref = '.';
	if( $with ) {
		my ($xdb_code,$xdb_acc) = split ':',$with;
		$xdb_ref = "(from <A HREF=\"$xdb_urls{$xdb_code}$xdb_acc\" target=\"_blank\">$with</a>)";
	}
    my $ref_url = "<A href=\"$baseCGI/query/query.cgi?id=RGD:$ref_rgd_id\">$ref_rgd_id</A>";

    if(!$qlf) {$qlf='.';}
    if(!$note) {$note='.';}

    chomp $aspect;
    $ont{$ASPECT{$aspect}} = "<TR><TD colspan=\"7\" bgcolor=\"#e0e0e0\"><B>$ASPECT{$aspect}</B></TD></TR>\n" unless $ont{$ASPECT{$aspect}};

    $ont{$ASPECT{$aspect}} .= "<TR valign=\"top\"><TD>$rgd_ont_url$term</A></TD><TD>$qlf</TD><TD>$evid</TD><TD>$xdb_ref</TD><TD>$ref_url</TD><TD>$note</TD><TD>$src</TD></TR>\n";


  }

  $sth->finish;
  
  if(scalar(keys %ont)){

    print "<h3>Ontology <A href=\"$baseURL/tu/ontology/\">(?)</a></h3>\n";

    print '<TABLE width="100%" valign="left" border="1" cellpadding="2" cellspacing="0"><TR bgcolor="#cccccc">';
    print '<TD><B>Term</B></TD>';
    print '<TD><B>Qualifier</B></TD>';
    print '<TD><B>Evidence</B></TD>';
    print '<TD><B>With</B></TD>';
    print '<TD><B>Reference</B></TD>';
    print '<TD><B>Notes</B></TD>';
    print '<TD><B>Source</B></TD>';
    print "</TR>\n";

    my $type = "Molecular Function";
    print "$ont{$type} \n" if $ont{$type};
    $type = "Biological Process";
    print "$ont{$type} \n" if $ont{$type};
    $type = "Cellular Component";
    print "$ont{$type} \n" if $ont{$type};
    $type = "Disease";
    print "$ont{$type} \n" if $ont{$type};
    $type = "Phenotype";
    print "$ont{$type} \n" if $ont{$type};
    $type = "Behavior";
    print "$ont{$type} \n" if $ont{$type};
    $type = "Pathway";
    print "$ont{$type} \n" if $ont{$type};
    print "</TABLE>\n";
  }

} ## end sub display_ontology



#####################################################
# purpose:  display Ontology information on Web site
# author :  Lan Zhao 
# date   :  8-21-03
# modified sql on 5/23/07 in order to show human and mouse ontology
#####################################################
sub display_ontology_for_genes{
  my ($self,$rgd_id)= @_;
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};

  my %ASPECT = (
              C => "Cellular Component",
              P => "Biological Process",
              F => "Molecular Function",
              N => "Phenotype",
              D => "Disease",
              B => "Behavior",
              W => "Pathway",
             );
  my %TYPE  = (
              C => "go",
              P => "go",
              F => "go",
              N => "po",
              D => "do",
              B => "bo",
              W => "wo",
             );

  my $sql = "select term,evidence,aspect,ref_rgd_id,with_info,qualifier,notes,data_src,term_acc ";
  $sql .= "from full_annot ";
  $sql .= "where ANNOTATED_OBJECT_RGD_ID = :rgd_id ";
  $sql .= "order by term  ";

  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr $sql";
  $sth->bind_param(':rgd_id',$rgd_id);
  $sth->execute or die "Can't execute statement: $DBI::errstr $sql";

  # Updated xdb_urls to correct swiss-prot and KEGG linkouts

  my %xdb_urls = (
		   MGI => "http://www.informatics.jax.org/searches/accession_report.cgi?id=MGI:",
		   'Swiss-Prot' => "http://expasy.org/cgi-bin/sprot-search-de?",
		   'SP_KW' => "http://expasy.org/cgi-bin/sprot-search-de?",
		   'rno' => "http://www.genome.ad.jp/dbget-bin/show_pathway?rno",
           'RGD' => "/tools/genes/genes_view.cgi?id=",
		   'UniProtKB' => 'http://www.pir.uniprot.org/cgi-bin/upEntry?id=',
           'Ensembl' => 'http://www.ensembl.org/Rattus_Norvegicus/geneview?gene=',
           'InterPro' => 'http://www.ebi.ac.uk/interpro/IEntry?ac=',
		  );
  my %ont;
  my %ont_summary = ();
  
  while(my ($term,$evid,$aspect,$ref_rgd_id,$with,$qlf,$note,$src,$term_acc)=$sth->fetchrow_array()) {
    my $rgd_ont_url = "<A HREF=\"/rgdweb/ontology/annot.html?acc_id=$term_acc\">"; 
    
    my ($xdb_code,$xdb_acc) = split (':',$with) if($with);
    my $xdb_ref = '';
    if( $xdb_acc && $with ){
       $xdb_ref = "<A HREF=\"$xdb_urls{$xdb_code}$xdb_acc\" target=\"_blank\">$with</A>";
    }

    my $ref_url = $ref_rgd_id ? "<A href=\"$baseCGI/query/query.cgi?id=RGD:$ref_rgd_id\">$ref_rgd_id</A>" : '';

	# add the terms to an array
	$ont_summary{$ASPECT{$aspect}}{"$rgd_ont_url$term</A>"} += 1;
	
    $ont{$ASPECT{$aspect}} = "<TR><TD colspan=\"7\" style=\"padding-top:6px;padding-right:2px;padding-bottom:3px;padding-left:2px;\"><a name=\"$ASPECT{$aspect}\"><B>$ASPECT{$aspect}</B></a></TR>\n<TR valign=\"top\" class=\"ontologyRowHeader\"><TD>Term</TD><TD>Qualifier</TD><TD>Evidence</TD><TD>With</TD><TD>Reference</TD><TD>Notes</TD><TD>Source</TD></TR>\n\n" unless $ont{$ASPECT{$aspect}};

    if($ont{$ASPECT{$aspect}}){    
      if( !$qlf ) {
	    $qlf = '';
	  }
	  if( !$note ) {
	    $note = '';
	  }

      $ont{$ASPECT{$aspect}} .= "<TR valign=\"top\" class=\"ontologyRow\"><TD>$rgd_ont_url$term</A></TD><TD>$qlf</TD><TD>$evid</TD><TD>$xdb_ref</TD><TD>$ref_url</TD><TD>$note</TD><TD>$src</TD></TR>\n";
    }
  }
 
  $sth->finish;
  
  ## display ontology information on web site ##
  if(scalar(keys %ont)){
    my $type = "Molecular Function";
   	$ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};
    $type = "Biological Process";
    $ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};
    $type = "Cellular Component";
    $ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};
    $type = "Disease";
    $ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};
    $type = "Phenotype";
    $ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};
    $type = "Behavior";
    $ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};
    $type = "Pathway";
    $ont_summary{$type}{'html'} = "$ont{$type} \n" if $ont{$type};

  }

  return %ont_summary;
} ## end sub display_ontology_for_genes



###############################################################
# sub html_head_ndp, html_foot_ndp and tool_start_ndp
# added on 06/15/2005 for Neurological Disease Portal: ndp;
###############################################################

sub html_head_ndp{

  my $self = shift @_;
  my $no_content_type = shift; # to specify not need Content-type 
  my $wwwPATH = $self->{_www_path};
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  my $styleURL= $self->{_style_url};
  my $title   = $self->{_title};
  my $category = $self->{_category}; # added on 11/10/2003;

  # the Content type and start of head tags
  print &_html_tags($no_content_type); 

  # include the style sheet ref if one is defined
  if($styleURL) {
    print "<link rel=stylesheet type=\"text/css\" href=\"$styleURL\">\n";
  }

  #include the title
  print "<TITLE>$title</TITLE>\n";

  # add in any meta tags
  foreach my $tag (keys %{$self->{_meta_tags}} ) {
    print "<meta name=\"$tag\" content=\"$self->{_meta_tags}->{$tag}\">\n";
  }

  # add in javascript code;
  my $jscode = "$wwwPATH/common/diseaseportal/ndp_sub-js.shtml";
  open(JSC,"$jscode");
  while (my $line=<JSC>){
    $line=~ s/<\!--\#echo var=\"webroot\"-->/$baseURL/g;
    $line=~ s/<\!--\#echo var=\"toolroot\"-->/$baseCGI/g;

    next if($line=~ /include virtual/);
    print $line;
  }
  close(JSC);  
  
  # end the head tag and start the body tag
  print "</HEAD>\n<BODY "; 

  #grab the body tags from the common body tag file;
  my $body = "$wwwPATH/common/diseaseportal/ndp_body.shtml";
  open (BODY, "$body");
  while (<BODY>) {
    print $_;
  } 
  close(BODY);
  print ">\n";


  ### added on 11/10/2003;
  my $mytitleimage;
  if($category eq "data") {
      $mytitleimage = "$baseURL/common/images/header-data.gif";
  }
  elsif($category eq "tools") {
      $mytitleimage = "$baseURL/common/images/header-tool.gif";
  }
  elsif($category eq "forum") {
      $mytitleimage = "$baseURL/common/images/header-forum.gif";
  }
  elsif($category eq "submitdata") {
        $mytitleimage = "$baseURL/common/images/header-submitdata.gif";
  }
  else{
      $mytitleimage = "$baseURL/common/images/header.gif";
  }
  ### end added 11/10/2003;


  # add in the header and search area from ndp_header.shtml;
  my $header = "$wwwPATH/common/diseaseportal/ndp_header.shtml";
  open(HD,"$header");
  while (my $line=<HD>){
    $line=~ s/<\!--\#echo var=\"webroot\"-->/$baseURL/g;
    $line=~ s/<\!--\#echo var=\"toolroot\"-->/$baseCGI/g;
    $line=~ s/<\!--\#echo var=\"title-image\"-->/$mytitleimage/g; # added on 11/10/2003;
    next if($line=~ /include virtual/);
    print $line;
  }
  close(HD);

  # navi area below header;
  my $content = "$wwwPATH/common/diseaseportal/ndp_sub-navi.shtml";
  open(CT,"$content");
  while (my $line=<CT>){
    $line=~ s/<\!--\#echo var=\"webroot\"-->/$baseURL/g;
    $line=~ s/<\!--\#echo var=\"toolroot\"-->/$baseCGI/g;
    next if($line=~ /include virtual/);
    print $line;
  }
  close(CT);
} ## end html_head_ndp;


sub html_foot_ndp{
  my $self = shift @_;
  my $wwwPATH = $self->{_www_path};
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};

  my $footer="$wwwPATH/common/diseaseportal/ndp_footer.shtml";
  open(FT,"$footer");
  while (my $line=<FT>){
    $line=~ s/<\!--\#echo var=\"webroot\"-->/$baseURL/g;
    $line=~ s/<\!--\#echo var=\"toolroot\"-->/$baseCGI/g;
    next if($line=~ /include virtual/);
    print $line;
  }
  close(FT); 
} ## end html_foot_ndp;


sub tool_start_ndp{
  my $self = shift @_;
  my $wwwPATH = $self->{_www_path};
  my $toolDIR = $self->{_tool_dir};
  my $linkDIR = $self->{_link_dir};
  my $toolPATH= $self->{_tool_path};
  my $baseURL = $self->{_base_url};
  my $baseCGI = $self->{_base_cgi};
  my $tool_dir="$wwwPATH/$toolDIR";
  my $link_dir="$wwwPATH/$linkDIR";
  my $toolfile="$tool_dir/tools.shtml";

  # added on 11/10/2003;
  my $category = $self->{_category};
  my $showSidebar = $self->{_show_sidebar};


  # following template's modified on 11/10/2003;
  my $myshimimage = "$baseURL/common/images/shim.gif";
  my $mybkgdimage = "$baseURL/common/images/dotline2.gif";

#  if ($showSidebar eq "no" ) {

    print<<__TOOLSTART0__;

      <TABLE border="0" cellpadding="0" cellspacing="0" width="100%">
        <TR>
          <TD width="30"><img src="$myshimimage" width="30" height="1"></TD>
          <TD valign="top" width="100%">

__TOOLSTART0__


  # add a gap between header and content, 11/10/2003;
  print "<img src=$myshimimage width=1 height=10><br>"; 
  
  print "<h2>$self->{_doc_title}</h2>\n" if($self->{_doc_title});
  print "<h4>Version: $self->{_version}</h4>\n" if(($self->{_version}) && ($self->{_show_version}));

} ## end tool_start_ndp;

1;

__END__

=head1 NAME

RGD::HTML - RGD HTML module

Used for creating the entire html code for the RGD headesr and footers and displaying the RGD submenus for Related Tools, Links, etc. as are shown on the non-script generated web pages.

=head1 SYNOPSIS

   use RGD::HTML;
 

   my $rgd = RGD::HTML->new(
			   title      => "Rat Genome Database", # <TITLE> of web page
			   doc_title  => "RGD Tool", # Title to appear in the web page text
			   version    => "1.0",
			   tool_dir   => "",
			   help_title => "Main Help Page",
			   help_url   => "/help.html",
			   meta       =>  { author   => "rgd.web\@mcw.edu",
					    keywords => "rgd,rat,genome,database",
					  },		   
			   style_url  =>  "/common/style/rgd_styles.css",
			   base_url   =>  "",
			   base_cgi   =>  "/tools",
			   www_path   =>  "/rgd/www",
			   tool_path  =>  "/rgd/tools",
			  );

   $rgd->html_head;  # opens the HTML tags, sets up style and other tags in the <HEAD>
   $rgd->tool_start; # call before sending the main HTML data output from your tool

   # Script output subroutines will go here, sending HTML to the browser
   # This will appear in the main body of the page

   $rgd->tool_end;  # closes various table tags
   $rgd->html_foot; # Ends the HTML page with the RGD footer


=head1 CHANGES

5/18/00  Simon T.  Added in doc_title param, changed parameter names from www_dir and tool_dir to www_path and tool_path.


=head1 USAGE

This script can be used to create an RGD::HTML object that will provide a standard interface for developers wishing to use the RGD look and feel for the their tools. The constructor method passes parameters in by values rather than as a comma separate list. The advantage is somewhat self documenting code and you only need to redefine the tags you need to change. It it is not necessary to pass all the tags shown above, you could leave it blank and still get a valid page. The values shown above are the default values for the script. If you wish to leave them as they are dont include the tag in the constructor method.

The help_title and help_url tags are currently unused, however, they could be used in conjunction with a help script to tailor help or feedback info to the script. Eg. Automatically send the user to the correct help page.

One could also add a C<script> tag at a later date to pass in Javascript that needed to go in the <HEAD> section of the page.

The C<base_url>, C<base_cgi>, C<www_path> and C<tool_path> probably shouldnt be altered but are included so you know they are there and you can change them if you need to.

Example:
To create an HTML object for a basic tool page: 


 $rgd = RGD::HTML->new(
			   title      => "Rat Genome Database Genome Scanner",
			   doc_title  => "Genome Scanner",
			   version    => "1.5",
			   tool_dir   => "genomescanner",
			  );


You would then start the page by calling 

   $rgd->html_head;

which prints the HTML code to STDOUT. This would return HTML code looking something like this:

   <HTML>
     <HEAD>
   <link rel=stylesheet type="text/css" href="/common/header/rgd_styles.css">
   <TITLE>Rat Genome Database Genome Scanner</TITLE>
   <meta name="keywords" content="rgd,rat,genome,database">
   <meta name="author" content="rgd.web@mcw.edu">
   </HEAD>
   <BODY>

   <table width="100%" border="0" cellspacing="0" cellpadding="3" bgcolor="#CC9966">
  
   <!-- Navigation menu stuff omitted -->

   </table>
   <h2>Genome Scanner</h2>
   <h4>Version: 1.5</h4>


=head2 Subroutines

=head3 To get server environmental variables 

  $baseURL=$rgd->get_baseURL; # http://dev.rgd.mcw.edu

  $baseCGI=$rgd->get_baseCGI; # http://dev.rgd.mcw.edu/tools

  $wwwPATH=$rgd->get_wwwPATH;   # /rgd_home/rgd/WWW

  $toolPATH=$rgd->get_toolPATH; # /rgd_home/rgd/TOOLS

  $dataPATH=$rgd->get_dataPATH; # /rgd_home/rgd/DATA

  $logPATH=$rgd->get_logPATH; # /rgd_home/rgd/LOGS

=head3 html_head()

  $rgd->html_head;

Generates the HTML for the <HEAD> section, including style sheet links, meta tags, etc. It places the standard RGD navigation menu table at the top of the page. This is copied from the standard SSI files used in the static HTML files to ensure consistency.

=head3 tool_start()

  $rgd->tool_start;

This takes the value of C<tool_dir> which is the name of the directory that this tool is located in and checks to see if it exists. If so, it reads in tools.html and links.html files in that directory which will contain the related tools HTML and related links html sections. Ths then creates the various submenus along the left hand side of the page showing the RGD site links, plus Associated Tools and Links menus. The script then creates a main table for the page, the submenus are placed in one column, your tool output will go in the remaining main section of the page. 

=head3 tool_end()

  $rgd->tool_end;

Must be called after the CGI has finished outputing to the web page. It closes the table tags opened by $rgd->tool_start.

=head3 html_foot()

  $rgd->html_foot; 

Creates the HTML for the RGD footer table, showing the Copyright notice, help, feedback and other links. This also finishes off the HTML for the page, closing the <BODY> and <HTML> tags.

=head1 CONTACT 
  

Contact Jian Lu (jianlu@mcw.edu) for reporting bugs, adding or modifying modules.

 
Copyright (c) 2000, Bioinformatics Research Center, 
Medical College of Wisconsin.
