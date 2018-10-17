#!/usr/bin/perl
#########################################################
#  file name:rhmap_placement.cgi
#  author: JIAN LU
#  date: 3-26-1999
#  show rh placement results to the user
#  modified: 4-16-1999 
#            6-23-1999 added summary report
#            5-18-2000 use RGD::HTML module
########################################################
use lib '/rgd/tools/common';
use lib '/rgd/tools/common/RGD';
use RGD::HTML;
require "cgi-lib.pl";

# to customize the title, version and tool_dir
my $rgd = RGD::HTML->new(
			 title      => "Rat Radiation Hybrid Map Server",
			 doc_title  => "Rat RH Map Server",
			 version    => "1.1",
			 category   => "tools",
		       );
my $baseURL=$rgd->get_baseURL;   # http://rgd.mcw.edu
my $baseCGI=$rgd->get_baseCGI;   # http://rgd.mcw.edu/tools
my $wwwPATH=$rgd->get_wwwPATH;   # /rgd/WWW
my $toolPATH=$rgd->get_toolPATH; # /rgd/TOOLS

&ReadParse(*in);

#######################################################
# parsing values
#######################################################
my $data=$in{'data'};
my $user_id=$in{'user_id'};
$user_id=~ s/\s+//g;
my $section=$in{'section'};
$section=~ s/\D//g;
my $report=$in{'report'};
my $version=$in{'version'};      ######### passed in version value

my $user_dir="$toolPATH/rhmapserver/data/user_data/$user_id";
my $raw_data="$user_dir/$section/rhdata\.raw";
my $result="$user_dir/$section/result\.txt";
my $file_dir="$user_dir/$section";
my $rpt="$user_dir/$section/report";
my $download_dir="$wwwPATH/RHMAPSERVER/download/$user_id";

# print HTML head
$rgd->html_head;

# tool start here
$rgd->tool_start;


if(-e $rpt){
    &Results_Link;
    &Get_Chrom($result);
    if(!$data){
	&instruction;
        &generate_map_gif;
    }
	
    if($data eq "result_txt"){ 
	&Show_Text($result);
    }elsif($data eq "summary"){
	&Summary_Link;
	&Show_Summary;
    }elsif($data eq "map_gif"){ 
	&Show_Map_GIF($result);
    }elsif($data eq "map_txt"){ 
	&Show_Map_TXT;
    }elsif($data eq "raw"){ 
	&Show_Text($raw_data);
    }elsif($data eq "remove"){
	&Remove_Data; 
	&JVscript;
    }elsif($data eq "download"){
        &download;
    }
    &Results_Link;
}else{
  if($section && $user_id){
    &error_message_1;
  }else{
    if($user_id){
      &error_message_2;
    }else{
      &error_message_3;
    }
  }
}

# tool page end here
$rgd->tool_end;

# print HTML foot
$rgd->html_foot;

##########################################################
#   END
#########################################################
exit;

###################################################
# error_message_1
###################################################
sub error_message_1{
   print <<_TXT_;
   <h2>Apologies</h2>
   <p>The server has not completed the processing of your data.  
      You will be notified by an email when the analysis finishes.
   <p>You may click "Reload" below to check your results too.
   <h3>Retrieve Results</h3>   
<p><form method=post action="$baseCGI/rhmapserver/rhmap_placement.cgi">
<p>user_id:<input type=text name=user_id value="$user_id" size=30> 
<p>section:<input type=text name=section value="$section"> 
<p><input type=submit value="Reload">
<input type=hidden name=version value="$version">
</form>
_TXT_
}
###################################################
# error_message_2
###################################################
sub error_message_2{
   print <<_TXT_;

   <p>Your data have been deleted on the server. 
     
<p><form method=post action="$baseCGI/rhmapserver/rhmapserver.cgi">
<p><input type=submit value="Re-run RH Map Server"> 
</form>
<p>If you have any conment, contact
<a href="mailto:rgd.data\@mcw.edu">RH Map Server</a>.
_TXT_
}
###################################################
# error_message_3
###################################################
sub error_message_3{
   print <<_TXT_;

   <p>Your data have not been found on the server.   
<p><form method=post action="$baseCGI/rhmapserver/rhmapserver.cgi">
<p><input type=submit value="Run RH Map Server"> 
</form>
<p>If you have any problem to run this server, contact 
<a href="mailto:rgd.data\@mcw.edu">RH Map Server</a>.
_TXT_
}

###################################################
# instruction
###################################################
sub instruction{
    print <<HTM;
<p>The report contains the following contents:
<ul>
<li><U>Maps(text):</U> Placement maps in text format, organized by chromosomes
<li><U>Maps(gif):</U> Placement maps in gif format, organized by chromosomes
<li><U>Raw output:</U> Placement raw output
<li><U>Raw data:</U> Your original data input to run RH mapping
<li><U>Remove data:</U> For your privacy, you can delete all of your data and results
<li><U>Download:</U> Download all your results in a zip or tar file
<li><U>Summary report:</U> Statistic report for your placement
  <ul>
  <li><U>Placed markers:</U> List markers in your data set that are placed on RH maps, organized by chromosomes
  <li><U>Multilinked markers:</U> List markers in your data set that have multiple chromosomal linkages
  <li><U>Non-placed markers:</U> List markers in your data set that have no linkages to framework markers
  </ul>
</ul>
<p><h3>NOTE:</h3>
Please save your results. They are only kept in our server for 3 days. 
<p>For further question or comment, simply reply the email you received.
HTM
}
###################################################
#  JVscript for redirecting subject
###################################################
sub JVscript{
  print <<JS;
 <SCRIPT LANGUAGE="JavaScript"><!--
window.location.href = '$baseURL/RHMAPSERVER/';
//--></SCRIPT>
JS
}

##########################################################
#   Results_Link
#########################################################
sub Results_Link
{
    print <<TXT;
    
<table width=650 border=0 bgcolor="#EEEEEE" cellspacing=0 cellpadding='5'>
<tr><td>

<div align=center>
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=summary&version=$version">Summary</a>]&nbsp;
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=map_txt&version=$version">Maps(text)</a>]&nbsp;
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=map_gif&version=$version">Maps(gif)</a>]&nbsp;
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=result_txt&version=$version">Raw output</a>]&nbsp;
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=raw&version=$version">Raw data</a>]&nbsp;
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=remove&version=$version">DELETE</a>]&nbsp;
[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=download&version=$version">Download</a>]&nbsp;
</div>

</td></tr>
</table>

TXT
}

##########################################################
#   Show_Text
#########################################################
sub Show_Text
{    
    my ($file)=@_;
    open(TXT,$file);
    if($data eq "result_txt" || $data eq "")
    {
	$pid=<TXT>;
    }
    print "<pre><small>";
    while($line=<TXT>)
    {
	print "$line";
    }
    print "</small></pre>";
    close(TXT);
}
##########################################################
#  Get_Chrom 
#########################################################
sub Get_Chrom
{
    my ($file)=@_;
    open(FILE,$file);
    
    my $i=0;
    while($line=<FILE>)
    {
	$line=~ /Chromosome\s(\w+)$/;
	if($1)
	{
	    $chrom{$1}=$1;
	}
    }
    close(FILE);
    $i=0;
    foreach $_ (keys(%chrom))
    {
	if($_ =~ /[xX]/){ $_=21;}
	$chrom[$i]=$_;
	$i++;
    }
    &numerically;
    @chrom=sort numerically (@chrom);
#    print "@chrom\n";
}
##########################################################
#   Summary_Link
#########################################################
sub Summary_Link
{
    print <<TXT;
    
<h2>Summary Results</h2>    
<p>[<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=summary&report=link&version=$version">Placed markers</a>]&nbsp;
  [<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=summary&report=multilink&version=$version">Multi-linked markers</a>]&nbsp;
  [<a href="$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&data=summary&report=nolink&version=$version">Non-placed markers</a>]
TXT
}
##########################################################
#   Show_Summary
#########################################################
sub Show_Summary
{   
    if(!$report){
	my $summary="$file_dir/report";
	open(SUM,$summary);
	print "<pre><small>";
	while($line=<SUM>)
	{
	    print "$line";
	}
	print "</small></pre>";
	close(SUM);
    }else{
	if($report ne "link"){
	    my $file="$file_dir/$report\.txt";
	    open(FILE,$file);
	    my $i=0;
	    print "<pre><small>";
	    while($line=<FILE>)
	    {
		print "$line";
		($mk,$string)=split(/\s+/,$line,2);
#		print "$mk\n";
		$report_mk[$i]=$mk;
		$i++;
	    }
	    print "</small></pre>";
	    close(FILE);
	    if(!$i){
               if($report eq "multilink"){
                  print "<h3>MULTI-LINKED MARKERS</h3>\n";
                  print "<p>None of the markers you submitted mapped to multiple locations.\n";
               }else{
                  print "<h3>NON-MAPPED MARKERS</h3>\n";
                  print "<p>All of your markers were mapped.\n";
               }
	    }else{
		my $string=join(',',@report_mk);
		$data=undef;
		open(TXT,"$raw_data");
		while($line=<TXT>){
		    ($mk_name,$vectors)=split(/\t/,$line);
		    if($string =~ /\b$mk_name\b/){
			$data .=$line;
		    }
		}
		close(TXT);
		print <<HTML;
<p>You might rerun the above markers by changing LOD cutoff value.
<p>
<form method=post action="$baseCGI/rhmapserver/rhmapserver.cgi">
<input type=hidden name=datatext value="$data">
<input type=hidden name=user_id value="$user_id">
<input type=submit value="Rerun Markers">
</form>
HTML
	    }
	}else{
	    if(@chrom >0){
		my $j=0;
		foreach $chrom (@chrom)
		{
		    if($chrom <10){
			$chr_file="CHR0$chrom\.dat";   
		    }else{
			$chr_file="CHR$chrom\.dat";
		    }
		    $file="$file_dir/$chr_file";
		    if($chrom == 21){
			print "<p>CHROM X";
		    }else{
			print "<p>CHROM $chrom";
		    }
		    print "<br>----------<p>";
		    open(FILE,$file);
		    print "<pre><small>";
		    while($line=<FILE>)
		    {
			print "$line";
		    }
		    print "</small></pre>";
		    close(FILE);
		}
	    }else{
	      print "<p align=center>None of the markers you submitted was placed on any of the maps.";
	    }
	}
    }
}
##########################################################
#   Show_Map_GIF
#########################################################
sub Show_Map_GIF{
  if(@chrom >0){
    print "<p><center><table border=0>";
    my $j=0;
    foreach $_ (@chrom) {
      if($j % 2 ==0){
	print "<tr align=center>";
      }
      print "<td valign=top><img src=\"$baseCGI/rhmapserver/map_viewer.cgi?user_id=$user_id&section=$section&chrom=$_&version=$version\" border=1></td>";
      $j++;
      if($j % 2 ==0){
	print "</tr>";
      }
    }
    print "</table></center>";
  }else{
    print "<p align=center>No placement map available since no markers were placed.";
  }
}

##########################################################
#  generate_map_gif  added by Jian 2-2-2000
#########################################################
sub generate_map_gif{
  
  if(@chrom >0) {
    foreach $_ (@chrom) {
      my $gif="$file_dir/CHR$_\.gif";
      if(-e $gif){
	next;
      }else{
        #print "$toolPATH/rhmapserver/map_gif_generator.pl $user_id $section $_ $version&";
        #exit;
	system ("$toolPATH/rhmapserver/map_gif_generator.pl $user_id $section $_ $version&");
      }
    }
  }
}

##########################################################
#   Show_Map_TEXT
#########################################################
sub Show_Map_TXT{
  if(@chrom >0){
    my $j=0;
    foreach my $chrom (@chrom){
      if($chrom <10){
	$chr_file="CHR0$chrom\.txt";   
      }else{
	$chr_file="CHR$chrom\.txt";
      }
      $file="$file_dir/$chr_file";
      if($chrom == 21){
	print "<p>CHROM X";
      }else{
	print "<p>CHROM $chrom";
      }
      print "<br>----------<p>";
      open(FILE,$file);
      print "<pre>";
      while(my $line=<FILE>){
        if($line =~ /P>3.00/){
	  print "<font color=red>$line</font>";
	}else{
	  print "$line";
	}
      }
      print "</pre>";
      close(FILE);
    }
  }else{
    print "<p align=center>No placement map available since no markers were placed.";
  }
}

##########################################################
#   numerically
##########################################################
sub numerically {
  $a<=>$b;
}

##########################################################
#  Remove_Data 
#########################################################
sub Remove_Data{
  print "<p><center>Your data has been deleted from the server</center>";
  
  `rm -rf $user_dir/$section`;

  my $zip="RH_$section\.zip";
  my $tar="RH_$section\.tar";
  `rm -f $download_dir/$zip`;
  `rm -f $download_dir/$tar`;
  `rm -rf $download_dir`;
}

##########################################################
# download user data & results 
#########################################################
sub download
{
   print "<p>The compressed files contain following contents: ";
   my $file_list= `ls $file_dir`;
   print "<p><pre>$file_list</pre>";

   # make zip and tar  files 
   my @file=split(/\s+/,$file_list);
   my $zip="RH_$section\.zip";
   my $zfile="$user_dir/$zip";
   my $tar="RH_$section\.tar";
   my $tfile="$user_dir/$tar";

   `/usr/bin/rm $zfile $tfile`;

   my $data=undef;
   foreach(@file){
      $data .="$section/$_ ";
   }
   chop $data;
   `cd $user_dir 
    /usr/bin/zip $zfile $data`;
   my $zip_size= `ls -l $zfile`;
   my @zip_size=split(/\s+/,$zip_size);
   my $z_size=$zip_size[4];
   `cd $user_dir
    /usr/bin/tar -cvf $tfile $section`; 

   `mkdir $download_dir`;
   `mv  $zfile $download_dir/$zip`;
   `mv  $tfile $download_dir/$tar`;
   
#   my $tar_size= `ls -l $tfile`;
#   my @tar_size=split(/\s+/,$tar_size);
#   my $t_size=$tar_size[4];
  
#   my $z_unit="Bytes";
#   if(length($z_size)>3){
#      $z_size=int ($z_size/1000);
#      $z_unit="KB";
#   }

#   my $t_unit="Bytes";
#   if(length($t_size)>3){
#      $t_size=int ($t_size/1000);
#      $t_unit="KB";
#   }
      
    print <<TXT;
<p>For PC user, download <a href="$baseURL/RHMAPSERVER/download/$user_id/$zip">ZIP</a> file. 
<p>For Unix user, download <a href="$baseURL/RHMAPSERVER/download/$user_id/$tar">TAR</a> file.
<p>
TXT
}
