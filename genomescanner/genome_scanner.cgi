#! /usr/bin/perl


################
#
# genome_scanner.cgi
#
# Copyright (c) Simon Twigger, Medical College of Wisconsin, Laboratory for Genetic Research, 1999
#
################


################
#
# v0.2     6/1/99 - Added in multiple chromosome selection to make things easier to download - smaller file
#
# v1.1     8/8/00 - Changed form ACTION url to relative URL (was pointing at fuxi)
#                   Added in use lib qw( /project1/rgd/TOOLS/common ) to get access to RGD modules
#                   Fixed bug where only the first chromosome's markers appear on a runlist.
#                   Added in ability for user to enter the allele size difference range
#                   which is highlighted on bin list output.
#                   Added ability to only display markers in the allele range
#                   Assay name option for the Runlist display
#                   Marker names on runlist link to SSLP display script.
# v1.2     8/11/00- Added output as CSV option to runlist
#                   Added Chromosome statistics table to marker page
#                   Added output content options to marker page (stats, table or both)
#                   
# v.1.3    1/24/01- Converted to RGD 2.0 module use, removed hardcoded DB module stuff
#
# v2.1     11/20/01- reorgnaized scripts, added a few subroutines for easier debug,JL

################

use strict;
use FileHandle;
use CGI;
use lib '/rgd/tools/common';


# Adapt for RGD use
use DBI;
use RGD::DB;
use RGD::HTML;


###############
#
# Make initial RGD connections
#
###############

# turn on auto flush! Kohler beware.
$| = 1;

# get path and db parameters using HTML.pm

my $rgd = RGD::HTML->new(
			 title     => "Rat Genome Database Genome Scanner",
			 doc_title => "Genome Scanner",
			 version   => 2,
			 link_dir  => "GENOMESCANNER",
			 category  => "tools",
			);

my $baseURL  = $rgd->get_baseURL;
my $baseCGI  = $rgd->get_baseCGI;
my $dataPATH = $rgd->get_dataPATH;
my $logPATH  = $rgd->get_logPATH;

# open the database connection

my $db = RGD::DB->new() || &HTML_Error("$DBI::errstr\n");


my @ACP_STRAINS = ("ACI","AVN","BB(DP)","BB(DR)","BC/CPBU","BDIX","BDVII","BN/CUBLX","BN/SSN","BP","BUF","COP","DA","DRY","FHH","F344","GH","GK","IS/KYO","LH","LE","LEW","LOU/C","LN","M520","MHS","MNR","MNRA","MNS","MR","NEDH","NP","ODU","OKA","OM","P","PVG","SD","SHR","SR/JR","SHRSP","SS/JR","WAG","WF","WIST","WKY","WN","WTC");

my %S_D = (
	   'ACI' =>  "ACI",
	   'AVN' => "AVN/Orl",
	   'BB(DP)' =>"BBDP/WorAp",
	   'BB(DR)' => "BBDR/WorAp",
	   'BC/CPBU' => "BC/CpbU",
	   'BDIX' => "BDIX/Han",
	   'BDVII'   =>   "BDVII/Cub",
	   'BN/CUBLX'   =>   "BN/Cub-lx",
	   'BN/SSN'   =>   "BN/SsNHsd",
	   'BP'   =>   "BP/Cub",
	   'BUF'   =>  "BUF/Pit",
	   'COP'   =>   "COP/OlaHsd",
	   'DA'   =>   "DA/Pit",
	   'DRY'   =>  "DONRYU/Melb",
	   'FHH'   =>  "FHH/Eur",
	   'F344'   =>  "F344/Pit",
	   'GH'   =>   "GH/Omr",
	   'GK'   =>  "GK",
	   'IS/KYO'   =>   "IS/KYO",
	   'LH'   =>   "LH/Mav",
	   'LE'   =>       "LE/Mol",
	   'LEW'   =>      "LEW/Pit",
	   'LOU'   =>     "LOU/CHan",
	   'LN'   =>     "LN/Mav",
	   'M520'   =>     "M520/N",
	   'MHS'   =>     "MHS/Gib",
	   'MNR'   =>     "MNR/N",
	   'MNRA'   =>     "MNRA/Har",
	   'MNS'   =>     "MNS/Gib",
	   'MR'   =>     "MR/Pit",
	   'NEDH'   =>     "NEDH/K",
	   'NP'   =>     "NP9",
	   'ODU'   =>     "ODU/N",
	   'OKA'   =>     "OKA/Wsl",
	   'OM'   =>     "OM/Han",
	   'P'   =>      "P5C",
	   'PVG'   =>      "PVG/Pit",
	   'SD'   =>      "SD/Rij",
	   'SHR'   =>     "SHR/OlaHsd",
	   'SR/JR'   =>      "SR/JrIpcw",
	   'SHRSP'   =>      "SHRSP/Riv",
	   'SS/JR'   =>      "SS/JrMcw",
	   'WAG'   =>     "WAG/RijKyo",
	   'WF'   =>      "WF/Pit",
	   'WIST'   =>     "WIST/Nhg",
	   'WKY'   =>     "WKY/OlaHsd",
	   'WN'   =>     "WN/N",
	   'WTC'   =>     "WTC/Kyo",
	  );



###############
#
# Define various global variables 
#
###############

my $number_of_markers = 0; # the number of markers on this chromosome.
my @bin_data = ();         # array of hashes for the binned markers 
my @chromosomes = ();      # array of the chromosomes selected for display
my %chr_stats = ();        # hash keyed by chromosome number, holding number of markers, number polymorphic, etc.
my %titles = ();
my %markers = ();
my @marker_chrom = ();
my %strain_names = ();
my %strain_ids = ();
my %strain1_alleles = (); # holds the strain 1 allele sizes keyed by rgd_id
my %strain2_alleles = (); # holds the strain 2 allele sizes keyed by rgd_id
my %map_info = ();
my %map_data = ();
my %other_name = ();
my %run_list = ();
my $script_name = "genome_scanner";
my $date = scalar localtime();

my $SSLP_RGD_ID_URL = "$baseCGI/sslps/sslps_view.cgi?id="; # URL to display SSLP record given the RGD ID value
my $map_data_path = $dataPATH."/maps/dbflatfiles/";
my $VERSION = 1.2;


###############
#
# Get HTML form parameters from the CGI object
#
##############
my $form = new CGI;

my $display = $form->param('display');
my $content = $form->param('content') || "table_stats"; # default to showing all the info
my $bin_size = $form->param('bin_size') || 10;        # default to 10 cM distance
my $map_key = $form->param('map') || 1;      # default FHHxACI
my $output_format = $form->param('output') || "html"; # default to HTML output
my $show_only_polymorphic = $form->param('show_only_poly') || "1"; # default to HTML output
my $bp_lo = $form->param('bp_lo') || 1;  # color range bottom limit
my $bp_hi = $form->param('bp_hi') || 10; # color range top limit
if ($bp_lo > $bp_hi) {
  &HTML_Error("The lower limit of the base pair range ($bp_lo bp) is higher than the upper limit ($bp_hi bp)!<BR> Please ensure that the lower limit is less than or equal to the upper limit");
  exit;
}

my $bp_range_display = $form->param('only_show_range') || 0; # only show markers in the range if set to 1
my $auto_select = $form->param('auto_select') || 0; # auto select polymorphic markers within bp_range
my @chr_list = $form->param('chromosome');
my @chr = $form->param('chromosome');
@chromosomes = @chr;

if( (join ',',@chr) =~ /all/i) {
  @chromosomes = (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21); 
}


my $s1 = $form->param('strain1_1') || 10;
my $s2 = $form->param('strain1_2') || 28;

if ($s1 == $s2) {
    &HTML_Error("You must choose two different strains");
    exit;
}

###############
#
# Get data from subroutines
#
##############

# read in the strain names and ID# from rgd into %strain_names
&get_strain_ids_from_rgd(\%strain_names, \%strain_ids);

# read in the selected map information
&get_map_data_from_file(\%map_data, $map_key) ||  &HTML_Error("Map data file error\n");

#read in the various allele sizes into the respective arrays (passed by ref)
&get_strain_allele_sizes_from_rgd($s1,\%strain1_alleles);
&get_strain_allele_sizes_from_rgd($s2,\%strain2_alleles);

# divide it all up into bins for the polymorphic markers

@bin_data = &bin_markers(\@chromosomes, $bin_size);

&get_map_names_from_rgd;

my $map_name = $map_info{$map_key}{name};
my $map_type = $map_info{$map_key}{description};
my $map_version =$map_info{$map_key}{version};

###############
#
# main scripts
#
##############

if($display eq "run_list") {
  
  &display_runlist;  
}elsif($display eq "results") {

  &display_results;
}else{
  print "Content-type: text/html \n\n";
  print <<_JS_;
<SCRIPT LANGUAGE="JavaScript">
window.location.href = "$baseURL/GENOMESCANNER/";
</SCRIPT>
_JS_

  print "<p>redirect to home page.";
}

$db->{dbh}->disconnect;

# END of main script
exit;

sub display_results{

  if($output_format eq "html") {
    $rgd->html_head;
    $rgd->tool_start;
    print <<"EOF";
<TABLE WIDTH="550">
<TR><TD>

<P><A NAME="top"></A><B>Note:</B> Markers with an allele size difference between $bp_lo - $bp_hi bp are colored with a green background
to facilitate picking markers which will have convenient allele separation when run on polyacrylamide gels.
</P>
<P>To generate a run list, check each marker you wish to add to the run list, enter in any desired comments in the fields provided at the
 <A HREF="#bottom">bottom of this page</A> and click the 'Generate Run List' button to produce a run list of only those markers you selected.</P>

<B>LOD Score Color Scheme:</B>
<UL>
    <LI><FONT COLOR="#0000FF">Framework marker</FONT> on genetic map (LOD > 3)
    <LI><FONT COLOR="#449944">Unique placement marker</FONT> on genetic map (LOD > 2)
    <LI><FONT COLOR="#000000">Non-unique placement marker</FONT> on genetic map (LOD < 2)
</UL>

<HR>
</P>
EOF
  }elsif ($output_format eq "csv") {
    print "Content-type: text/html \n\n";
  }else {
    print "Content-type: text/xml\n\n";
    print <<"EOF";
<?xml version = "1.0" ?>
<genome_scanner_record>
  <map name="$map_name" type="$map_type" version="$map_version"/>
  <strain1>$strain_ids{$s1}</strain1>
  <strain2>$strain_ids{$s2}</strain2>
EOF
  }
  
  &disply_content($output_format);

  #now go through each bin, displaying the data
  &display_bin_data;

  if($output_format eq "html") {
    my $chrs = "@chromosomes";  
    print <<"EOF";
</TR></TABLE>
   <!-- The total number of polymorphic markers in the list -->
<HR>
<A NAME="bottom"></A>
<TABLE WIDTH="550">
<TR><TD>Selected Map:</TD>
<TD>$map_name, v$map_version
<INPUT TYPE="hidden" NAME="map_name" VALUE="$map_name, v$map_version"></TD>
</TR>
<TR><TD>Run List Comments:</TD>
<TD> <INPUT TYPE="TEXT" NAME="comments" VALUE="$strain_ids{$s1} x $strain_ids{$s2} polymorphic markers, $bin_size cM/cR intervals, Chr: $chrs" SIZE=30></TD>
</TR>
<TR><TD>Run List Date:</TD>
<TD><INPUT TYPE="TEXT" NAME="date" VALUE="$date" SIZE=30></TD>
</TR>
<TR><TD>Sort Run List by Marker Name</TD>
<TD><INPUT TYPE="checkbox" NAME="order"></TD>
</TR>
<TR><TD>Show Assay names on runlist</TD>
<TD><INPUT TYPE="checkbox" NAME="show_assay"></TD>
</TR>
<TR><TD>Output Format</TD>
<TD>
<select name="output" size="1">
	      <option value="html" selected>HTML
	      <option value="csv">CSV	      
</select>
</TD>
</TR>
    <TR><TD>&nbsp;</TD>
<TD><INPUT TYPE="submit" NAME="runlist" VALUE="Generate Runlist"></TD>
</TABLE>
</FORM>
<BR>
<HR>
EOF
  }elsif ($output_format eq "csv") {
    print "</PRE>";
    print "</BODY></HTML>";
  }elsif ($output_format eq "xml") {
    print <<"EOXML";
</genome_scanner_record>
EOXML
  }
  
  # close OUT;
  if ($output_format eq "html") {
    print <<"EOF";
</TD></TR></TABLE>
</CENTER>
EOF

    $rgd->tool_end;
    $rgd->html_foot;
  }

}# end of display_results

# 
# Display chromosome statistics table if required. 
# Includes anchors to start of chromosome in table
# 
sub disply_content{
  my ($output_format)=@_;
  if($content =~ /stats/) {
    if ($output_format eq "html" ) {
      print "<center><table border=1><tr><td colspan=5><strong>Chromosome Report</strong></td></tr>";
      print "<tr><td>Chromosome</td><td>Length</td><td>Number of Bins</td><td>Poly Markers</td><td>Chr Poly %</td></tr>";
    
      my $list_counter = 1;
      for $list_counter ( 0 .. $#chromosomes ) {
	
	my $chr_num = $chromosomes[$list_counter];
	
	# only put the anchor links in if the table is being displayed.
	my $chr_anchor_text = "$chromosomes[$list_counter]";
	if($content =~ /table/) {
	  $chr_anchor_text = "<A HREF=\"\#chromosome_$chromosomes[$list_counter]\">$chromosomes[$list_counter]</A>";
	}
	
	print "<tr align=\"center\"><td>$chr_anchor_text</td>";
	print "<td>$chr_stats{$chr_num}{chr_length}</td>";
	print "<td>", $chr_stats{$chr_num}{num_of_bins}+1 , "</td>";
	print "<td>$chr_stats{$chr_num}{poly_markers} out of $chr_stats{$chr_num}{total_markers}</td>";
	my $poly_percentage = int(($chr_stats{$chr_num}{poly_markers}/$chr_stats{$chr_num}{total_markers})*100);
	print "<td>$poly_percentage %</td></tr>";
	
      }
      
      print <<"EOF";
    </table>
</CENTER>
<BR><BR>
<HR>
EOF
    }elsif ($output_format eq "csv") {
    
      print "<pre>chromosome,length,number_of_bins,number_poly_markers,number_of_markers,poly_percentage\n";
      
      my $list_counter = 1;
      for $list_counter ( 0 .. $#chromosomes ) {
	print "$chromosomes[$list_counter],";
	print "$chr_stats{$chromosomes[$list_counter]}{chr_length},";
	print  $chr_stats{$chromosomes[$list_counter]}{num_of_bins}+1 . ",";
	print "$chr_stats{$chromosomes[$list_counter]}{poly_markers},$chr_stats{$chromosomes[$list_counter]}{total_markers},";
	my $poly_percentage = int(($chr_stats{$chromosomes[$list_counter]}{poly_markers}/$chr_stats{$chromosomes[$list_counter]}{total_markers})*100);
	print "$poly_percentage\n";
	
      }
      print "\n\n</pre>";
    }
  } # end of show statistics section

  if ($content =~ /table/) { # only show if they want to see the table data or this is non-xml output 
    if ($output_format eq "html" ) {
      print <<"EOF";
<BR><BR>
<FORM ACTION ="$baseCGI/genomescanner/genome_scanner.cgi" METHOD="POST">
<INPUT TYPE="HIDDEN" NAME="display" VALUE="run_list">
<!-- Pass some basic strain info to the next script -->
<INPUT TYPE="HIDDEN" NAME="strain1" VALUE="$strain_ids{$s1},$s1">
<INPUT TYPE="HIDDEN" NAME="strain2" VALUE="$strain_ids{$s2},$s2">

<TABLE BORDER="1" WIDTH="550">
<TR>
    <TD>Marker</TD>
    <TD>Distance</TD>
    <TD>LOD</TD>
    <TD>$strain_ids{$s1} Size</TD>
    <TD>$strain_ids{$s2} Size</TD>
    <TD>Difference</TD>
    <TD>Add to Runlist</TD>
</TR>

EOF

    }elsif ($output_format eq "csv")  {
      print "<PRE>chromosome,bin,marker,assay,distance,lod,$strain_ids{$s1},$strain_ids{$s2},difference\n";
    }
  }
}# end of display_content


######################################
#
# Subroutines follow from here 
#
######################################



sub bin_markers {

  # Go through the markers on the map for the chromosomes selected (in $chrs_ref)
  # pick the polymorphic markers Maps: %map_data = keyed by rgd-id
  # bin these according to the bin size selected
  # return an array of bin objects to display

  my ($chrs_ref, $bin_size) = @_;

  my $bin_start = 0;
  my $current_chr = 1;
  my @bin_data = ();
    

 MARKER_LOOP:
  foreach my $marker ( sort by_abs_dist keys %map_data) {

    # print "$marker: $map_data{$marker}{name}, $map_data{$marker}{chr},$map_data{$marker}{abs_dist}\n";

    # ignore the markers that dont have both values
    next MARKER_LOOP unless ($strain1_alleles{ $map_data{$marker}{obj_key} } &&  $strain2_alleles{ $map_data{$marker}{obj_key} });

    my $s1_size = $strain1_alleles{ $map_data{$marker}{obj_key}};
    my $s2_size = $strain2_alleles{ $map_data{$marker}{obj_key}};
    
    # calculate the difference between the marker sizes
    my $diff = abs($s1_size - $s2_size);
    # $chr_stats{$map_data{$marker}{chr}}{total_markers} += 1; # increase the total marker count for this chr
    $chr_stats{$map_data{$marker}{chr}}{total_markers} += 1;

    # track the length of the chromosome by the marker mapped furthest down the chr.
    if($map_data{$marker}{'abs_dist'}) {
      if($map_data{$marker}{'abs_dist'} > $chr_stats{$map_data{$marker}{chr}}{chr_length}) {
	$chr_stats{$map_data{$marker}{chr}}{chr_length} = int($map_data{$marker}{'abs_dist'});
      }
    }
    # ignore markers that are the same size, if we are set up to do that
    if($show_only_polymorphic) {
     
      next MARKER_LOOP unless $diff;
    }

    # print "$map_data{$marker}{name} $map_data{$marker}{obj_key}\t$s1_size, $s2_size\n";
   
    if ($map_data{$marker}{chr} != $current_chr){
      $current_chr = $map_data{$marker}{chr}
    }

    my $bin_num =  int($map_data{$marker}{abs_dist} / $bin_size);

    # $chr_stats{$map_data{$marker}{chr}}{poly_markers} += 1; # increase the total poly. marker count for this chr
    $chr_stats{$map_data{$marker}{chr}}{poly_markers} += 1;
    $chr_stats{$map_data{$marker}{chr}}{num_of_bins} = $bin_num unless ($bin_num < $chr_stats{$map_data{$marker}{chr}}{num_of_bins});
    $bin_data[$current_chr][$bin_num] .= "$marker,";
    
  }

  return @bin_data;


} # end of bin markers


sub by_abs_dist {
    $map_data{$a}{chr} <=> $map_data{$b}{chr}
  or
  $map_data{$a}{abs_dist} <=> $map_data{$b}{abs_dist}

}


sub display_runlist {

  my ($strain1,$strain1_id) = split /,/,$form->param('strain1');
  my ($strain2,$strain2_id) = split /,/,$form->param('strain2');
  my $num_markers = $form->param('num_markers') || 10;
  my $date = $form->param('date') || "today";
  my $comments = $form->param('comments') || "test comments!";
  my $order_by_rname = $form->param('order') || 0;
  my $map_name = $form->param('map_name') || "Unknown";
  my $show_assay_name = $form->param('show_assay') || 0;
  my $output_format = $form->param('output') || "html";
  my %run_list = ();
  my %order_list = ();
  
  
  # Print out the HTML header information for the top of the page
  
  if($output_format eq "html") {
    $rgd->html_head;
    $rgd->tool_start;
    
    
    print <<"EOF";
<P>
<TABLE>
<TR>
    <TD><B>Selected Map:</B></TD>
    <TD> $map_name</TD>
</TR>
<TR>
    <TD><B>Cross:</B></TD>
    <TD> $strain1 x $strain2</TD>
</TR>
<TR>
    <TD><B>Date:</B></TD>
    <TD>$date</TD>
<TR>
    <TD><B>Comments:</B></TD>
    <TD>$comments</TD>
</TR>
</TABLE>
<HR>
<BR>
<TABLE BORDER=1>
<TR>
    <TD><B>Chromosome</B></TD>
    <TD><B>Marker Name</B></TD>
EOF

    if($show_assay_name) {
      print "<TD><B>Assay Name</B></TD>";
    }
    
    print <<"EOF";
    <TD><B>Distance</B></TD>
    <TD><B>LOD</B></TD>
    <TD><B>$strain1 size</B></TD>
    <TD><B>$strain2 size</B></TD>
    <TD><B>Difference</B></TD>
    <TD><B>Run List Comments</TD>
</TR>
EOF
  }elsif($output_format eq "csv") {
    print "Content-type: text/html\n\n";
    print "<pre>Chromosome,Marker Name,";
    if($show_assay_name) {
      print "Assay Name,";
    }
    print "Distance,LOD,$strain1 size,$strain2 size,Difference\n<br>";
    
  }
  
 # loop through each marker on the list, if its selected, add it to the runlist

  my $marker = 0;
  my $num_selected = 0; # total number of markers selected
  
  for $marker ( 0 .. $num_markers) {
	
    my $check_num = "marker_$marker";
    my $info_num = "info_$marker";
    
    # if this marker was selected
    if($form->param($check_num)) {
      
      my ($name,$size1,$size2,$diff,$chr,$pos,$lod,$rgd_id) = split /,/,$form->param($info_num);
      my $assay_names = "";
      
      if($show_assay_name) {
	$assay_names = &get_sslp_assay_names_from_rgd($rgd_id) || "-";	      
      }
      
      my $text = "";
      
      if($output_format eq "html") {
	
	$text = <<"EOF";

<TR>
    <TD ALIGN=CENTER>$chr</TD>
    <TD><a href="$SSLP_RGD_ID_URL$rgd_id">$name</a></TD>
EOF

	if($show_assay_name) {
	  $text .="<TD ALIGN=CENTER>$assay_names</TD>";
	}

	$text .= <<"EOF";
    <TD ALIGN=CENTER>$pos</TD>
    <TD ALIGN=CENTER>$lod</TD>
    <TD ALIGN=CENTER>$size1</TD>
    <TD ALIGN=CENTER>$size2</TD>
    <TD ALIGN=CENTER>$diff</TD>
    <TD>&nbsp;</TD>
</TR>\n
EOF
      } # end of HTML options
      elsif($output_format eq "csv") {

	$text = "$chr,$name,";
	
	if($show_assay_name) {
	  $text .= "$assay_names,";
	}
	
	$text .= "$pos,$lod,$size1,$size2,$diff\n<br>";
      }
      
      
      $run_list{$name} = "$num_selected\|\|$text";
      $order_list{$num_selected} = "$num_selected\|\|$text";
      $num_selected++;
    } # end of if marker selected
    
  } # end of looping through all markers on the list
    
    
  if($order_by_rname) {
      
    foreach my $rn (sort keys %run_list) {
      my ($num,$text) = split /\|\|/,$run_list{$rn};
      print $text;
    }
    
  }
  else {
    foreach my $rn (sort keys %order_list) {
      my ($num,$text) = split /\|\|/,$order_list{$rn};
      print $text;
    }
  }
  
  if($output_format eq "html") {
    print <<"EOF";
<!-- Finish up the HTML page -->
</TABLE>
<BR>
There were $num_selected markers selected for this runlist.<BR>
<BR><BR>
<HR>
EOF

    $rgd->tool_end;
    $rgd->html_foot;
    
  }
  elsif ($output_format eq "csv") {
    print "</pre></html>\n";
  }
}




#######################
#######################
#
# display_bin_data
#
#######################

sub display_bin_data {
  # Now for each chromosome in the list
  my $chr = 0;
  my $marker_tally = 1;

  for (my $c_count = 0;  $c_count <=  $#chromosomes; $c_count++) { # chromosome loop
    
    $chr = $chromosomes[$c_count];
    
    if($output_format eq "xml") {
      print "<chromosome number=\"$chr\">\n";
    }
    
    my $b = 1;
    
  BIN_LOOP:
    for ($b = 0; $b <= $#{$bin_data[$chr]}; $b++) { # bin loop
      # if($output_format eq "html") {

	my $real_bin_number = $b + 1;
	my $start = $b * $bin_size;
	my $end = ($b+1) * $bin_size;

	if($output_format eq "html") {
	  # first bin for this chromosome, add an anchor link
	  if($b == 0) {
	    print "<TR><TD COLSPAN=7 BGCOLOR=\"\#DDDDDD\"><STRONG><A NAME=\"chromosome_$chr\">Chromosome $chr (Bin $real_bin_number, $start - $end)</A></STRONG>   (<A HREF=\"\#top\">top</A>)</TD></TR>";
	  }
	  else {
	    print "<TR><TD COLSPAN=7 BGCOLOR=\"\#DDDDDD\"><STRONG>Chromosome $chr (Bin $real_bin_number, $start - $end)</STRONG></TD></TR>";
	  }
	}
	
	if($bin_data[$chr][$b]) {
	  my @tmp = split /,/,$bin_data[$chr][$b];
	  
	  my $m = 0;

	MARKER_BIN_LOOP:
	  # foreach marker in this bin
	  my $bin_selected  = 0;
	  for ($m = 0; $m <= $#tmp; $m++) {
	   
	    my $diff = abs($strain1_alleles{ $map_data{$tmp[$m]}{obj_key} } - $strain2_alleles{ $map_data{$tmp[$m]}{obj_key} } );
	    
	    my $selected = ""; # the checked/unchecked status of this marker
	    my $cell_color = "#FFFFFF";
	    my $f_color= "#000000";
	    # if difference inside bp range, color cell
	    if($diff >= $bp_lo && $diff <= $bp_hi) {
	      $cell_color = "#BBFFDD";

	      # if we havent selected a marker in this bin already
	      if($bin_selected == 0) {
		$bin_selected = 1;
		$selected = "CHECKED";
	      }

	    }
	    # if its outside the range, check to see if we display it at all
	    # if $bp_range_display = 1, only show markers in the bp range
	    elsif ($bp_range_display) {
	      next MARKER_BIN_LOOP;
	    }

	    if ($map_data{$tmp[$m]}{lod} == 0) { # framework marker
	      $f_color = "blue";
	    }
	    elsif ($map_data{$tmp[$m]}{lod} > 2) { # unique placement
	      $f_color = "green";
	    }
	    
	    my $rname = "-NA-"; # in case there is no rname available
	  
	    if($output_format eq "html") {
	      print <<"EOF";
	      <TR>
		<TD><A HREF="$SSLP_RGD_ID_URL$tmp[$m]"><STRONG>$map_data{$tmp[$m]}{name}</STRONG></a></TD>
		<TD>$map_data{$tmp[$m]}{abs_dist}</TD>
		<TD><FONT COLOR="$f_color">$map_data{$tmp[$m]}{lod}</FONT></TD>
		<TD ALIGN="CENTER">$strain1_alleles{ $map_data{$tmp[$m]}{obj_key} }</TD>
		<TD ALIGN="CENTER">$strain2_alleles{ $map_data{$tmp[$m]}{obj_key} }</TD>
		<TD AlIGN="CENTER" BGCOLOR="$cell_color">$diff</TD>
		<TD><INPUT TYPE="CHECKBOX" NAME="marker_$marker_tally" $selected>
		<INPUT TYPE="HIDDEN" NAME="info_$marker_tally" VALUE="$map_data{$tmp[$m]}{name},$strain1_alleles{ $map_data{$tmp[$m]}{obj_key}},$strain2_alleles{ $map_data{$tmp[$m]}{obj_key}},$diff,$map_data{$tmp[$m]}{chr},$map_data{$tmp[$m]}{abs_dist},$map_data{$tmp[$m]}{lod},$tmp[$m]">
		</TD>
		</TR>
EOF
  
  
}
	    elsif ($output_format eq "xml") {
	      
	      print "
<marker type=\"$map_data{$tmp[$m]}{fp}\" rgd_id=\"$map_data{$tmp[$m]}{rgd_id}\">
  <marker_name>$map_data{$tmp[$m]}{name}</marker_name>
  <distance>$map_data{$tmp[$m]}{abs_dist}</distance>
  <lod>$map_data{$tmp[$m]}{lod}</lod>
  <size_strain1>$strain1_alleles{ $map_data{$tmp[$m]}{obj_key}}</size_strain1>
  <size_strain2>$strain2_alleles{ $map_data{$tmp[$m]}{obj_key}}</size_strain2>
  <difference>$diff</difference>
</marker>
"	   
	    }
	    else {
	      
	      # why is this here??
	      my $lod = abs($map_data{$tmp[$m]}{lod});
	    
	      print "$chr,$real_bin_number,$map_data{$tmp[$m]}{name},$map_data{$tmp[$m]}{abs_dist},$map_data{$tmp[$m]}{lod},$strain1_alleles{ $map_data{$tmp[$m]}{obj_key}},$strain2_alleles{ $map_data{$tmp[$m]}{obj_key}},$diff\n";
	    }

	    # increase the running total of markers
	    $marker_tally++
	  }
	  
	}
  #    }
      
    }
    if($output_format eq "xml") {
      print "</chromosome>\n";
    }
  }
  if ($output_format eq "html") {
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"num_markers\" VALUE=\"$marker_tally\">";
  }  
}



# sort the markers by their cM distance
sub by_cM {
    $markers{$a}[1] cmp $markers{$b}[1]
	or
	    $markers{$a}[2] <=> $markers{$b}[2];
}

sub by_chr_cM {
    my @info1 = split /,/,$markers{$a};
    my @info2 = split /,/,$markers{$b};

    $info1[1] <=> $info2[1];
}


sub get_map_data_from_file {

  my ($hash_ref,$map_key) = @_;

  my $flat_file = "map_id_" . $map_key . "_data.csv";

  open (IN, $map_data_path . $flat_file) || die "Cant open flatfile: $flat_file $!\n";

 MARKER_LOOP:
  while (<IN>) {
    chomp;
    my ($rgd_id, $obj_type,$obj_key,$name,$map_key,$chr,$absdist,$fp,$lod) = split',',$_;

    next MARKER_LOOP if $obj_type == 2; # Dont want EST s

    $hash_ref->{$rgd_id}{obj_type} = $obj_type;
    $hash_ref->{$rgd_id}{obj_key}  = $obj_key;
    $hash_ref->{$rgd_id}{name}     = $name;
    $hash_ref->{$rgd_id}{map_key}  = $map_key;
    $hash_ref->{$rgd_id}{chr}      = $chr;
    $hash_ref->{$rgd_id}{abs_dist}  = $absdist;
    $hash_ref->{$rgd_id}{fp}       = $fp;
    $hash_ref->{$rgd_id}{lod}      = $lod;

  }
  
  return 1;

} # end of get_map_data_from_file


##############
#
# get_map_names_from_rgd 
#
# Read in the basic map information from RGD to make the initial web page
# with appropriate maps
#
##############

sub get_map_names_from_rgd {

    # get the map strain information
    my $sql = <<"SQL";
    select map_key, map_name, map_version, map_description
    from maps
SQL
    
    my $sth = $db->{dbh}->prepare($sql) || &HTML_Error("$DBI::errstr \n");
    $sth->execute || &HTML_Error("$DBI::errstr \n");

    my $map_count = 0;
    my @row = ();

  MAP:
    while(my ($key,$name,$version,$description) = $sth->fetchrow_array) {
	$map_info{$key}{name} = $name;
	$map_info{$key}{version} = $version;
	$map_info{$key}{description} = $description;

    }

    $sth->finish || die "$DBI::errstr\n";
}

##############
#
# get_sslp_assay_names_from_rgd 
#
# Get sslp_assay name for a given RGD_ID
#
##############

sub get_sslp_assay_names_from_rgd {

  my $rgd_id = shift(@_);
  
  # get the map strain information
  my $sql = <<"SQL";
    select alias_value from aliases where alias_type_name_lc = 'sslp_assay_name' 
    and RGD_ID = ?
SQL
  
  my $sth = $db->{dbh}->prepare($sql) || &HTML_Error("$DBI::errstr \n");
  $sth->execute($rgd_id) || &HTML_Error("$DBI::errstr \n");
  
  my @row = ();
  
  my $results = "";
  
  while(my $alias = $sth->fetchrow_array) {
    
    $results .= "\U$alias ";
  }
  
  $sth->finish || die "$DBI::errstr\n";

  return $results;
}

##############
#
# get_strain_ids_from_rgd
#
# Read in the map strain name and id into %strain_names, keyed by name
#
##############

sub get_strain_ids_from_rgd {

  my ($name_ref, $id_ref) = @_;

  # get the map strain name and id into %strain_names, keyed by name
  my $sql = <<"SQL";
    select STRAIN_SYMBOL, STRAIN_KEY
    from STRAINS
SQL
    
  my $sth = $db->{dbh}->prepare($sql) || die ("$DBI::errstr \n");
  $sth->execute || die ("$DBI::errstr \n");
  
  my @row = ();
  
 SIZE:
  while(@row = $sth->fetchrow_array) {
    if($row[1]) {
      $name_ref->{$row[0]} = $row[1];
      $id_ref->{$row[1]} = $row[0];
      # print "Strain: $row[0], ID: $strain_names{$row[0]}.  Read $row[0] $row[1]\n";
    }
  }
  
  $sth->finish || die "$DBI::errstr\n";

}


##############
#
# get_strain_allele_sizes_from_rgd
#
# Read in the allele sizes for a give strain into a hash, passed by ref from
# the calling function (keyed by strain_key)
#
##############

sub get_strain_allele_sizes_from_rgd {

    my ($strain,$hash_ref) = @_;

    # get the map strain information
    my $sql = <<"SQL";
    select SSLP_KEY, SIZE1
    from SSLPS_ALLELES
    where STRAIN_KEY = $strain
SQL
    
    my $sth = $db->{dbh}->prepare($sql) || die ("$DBI::errstr \n");
    $sth->execute || die ("$DBI::errstr \n");

    my @row = ();

  SIZE:
    while(@row = $sth->fetchrow_array) {
	if($row[1]) {
	    $hash_ref->{$row[0]} = $row[1];
	    # print "Allele_key:$row[0] \t $row[1]\n>";
	}
    }

    $sth->finish || die "$DBI::errstr\n";
}






# returns a color scheme based on the LOD score of the marker on the genetic map

sub get_color {

    my $marker = shift @_;
    my $color = "#000000";

    my $lod = abs($markers{$marker}[4]); # make it positive

    if($lod == 0) {
	#framework marker
	$color = "#0000FF";
    }
    elsif ($lod >= 2) {
	$color = "#449944";
    }

    #otherwise we'll use black for lower confidence placements.
    return $color;
}

############
# 
# Output an HTML page with error information
#
############

sub HTML_Error {

    # read in the error message passed to the subroutine
    my $error_message = shift(@_) || "An unknown error occured - Yikes";

    # print out HTML page letting the new user know an error occured

    print "Content-type: text/html\n\n";

    print <<"EOF";
<HTML><HEAD><TITLE>$script_name.cgi error</TITLE></HEAD<
<BODY BGCOLOR="#FFFFFF">
<BR>
<H1>An error was detected:</H1>

<STRONG>$error_message</STRONG>

<HR>
Return to the <A HREF="$baseURL/GENOMESCANNER/" target="_self">Genome Scanner</A>
</BODY></HTML>
EOF

    # stop the execution of the script here
    exit;
}



__END__

##############################
# SPARE SUBROUTINES FOLLOW!
##############################
	    
