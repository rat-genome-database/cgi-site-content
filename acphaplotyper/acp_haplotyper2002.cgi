#!/usr/bin/perl -w

################
#
# acp_haplotyper2002.cgi (c) Simon Twigger 1999-2002
#
# reads ACP data file and compares allele sizes between two or more strains to create
# a 'haplotype' indicating where conservation of allele sizes has bene maintained
# between the two strains. Output will be as a PS->PDF file using Ghostscript
#
################
#
# This version will generate XML to describe the haplotype results
# and the XML will then get passed on to a third tier to convert
# the XML into the desired output format 
#
###############


use FileHandle;
use CGI;
use XML_RGD; # handles the db I/O routines
use LGR::XML::PS_Map;
use XML::DOM;
use lib "/rgd/tools/common";
use RGD::HTML;
use strict;



my %S_D = (
		      'ACI' =>  "ACI",
		      'AVN' => "AVN/Orl",
		      'BB(DP)' =>"BB/DP",
		      'BB(DR)' => "BB/DR",
		      'BC/CPBU' => "BC/Cpbu",
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
		      'IS/KYO'   =>   "IS/Kyo",
		      'LH'   =>   "LH/Mav",
		      'LE'   =>       "LE/Mol",
		      'LEW'   =>      "LEW/Pit",
		      'LOU/C'   =>     "LOU/CHan",
		      'LN'   =>     "LN/Mav",
		      'M520'   =>     "M520/N",
		      'MHS'   =>     "MHS/Gib",
		      'MNR'   =>     "MNR/N",
		      'MNRA'   =>     "MNRA/N",
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
		      'SR/JR'   =>      "SR/Jr",
		      'SHRSP'   =>      "SHRSP/Riv",
		      'SS/JR'   =>      "SS/Jr",
		      'WAG'   =>     "WAG/RijKyo",
		      'WF'   =>      "WF/Pit",
		      'WIST'   =>     "WIST/Nhg",
		      'WKY'   =>     "WKY/OlaHsd",
		      'WN'   =>     "WN/N",
		      'WTC'   =>     "WTC/Kyo",
		     );

my @ACP_STRAINS = (
		   "common",$S_D{"ACI"},$S_D{"AVN"},$S_D{"BB(DP)"},$S_D{"BB(DR)"},$S_D{"BC/CPBU"},$S_D{"BDIX"},$S_D{"BDVII"},$S_D{"BN/CUBLX"},$S_D{"BN/SSN"},$S_D{"BP"},$S_D{"BUF"},$S_D{"COP"},$S_D{"DA"},$S_D{"DRY"},$S_D{"FHH"},$S_D{"F344"},$S_D{"GH"},$S_D{"GK"},$S_D{"IS/KYO"},$S_D{"LH"},$S_D{"LE"},$S_D{"LEW"},$S_D{"LOU/C"},$S_D{"LN"},$S_D{"M520"},$S_D{"MHS"},$S_D{"MNR"},$S_D{"MNRA"},$S_D{"MNS"},$S_D{"MR"},$S_D{"NEDH"},$S_D{"NP"},$S_D{"ODU"},$S_D{"OKA"},$S_D{"OM"},$S_D{"P"},$S_D{"PVG"},$S_D{"SD"},$S_D{"SHR"},$S_D{"SR/JR"},$S_D{"SHRSP"},$S_D{"SS/JR"},$S_D{"WAG"},$S_D{"WF"},$S_D{"WIST"},$S_D{"WKY"},$S_D{"WN"},$S_D{"WTC"}
		  );

my @HYPERTENSION_ORDER = (
			  $S_D{"SHR"},$S_D{"SHRSP"},$S_D{"SS/JR"},$S_D{"MHS"},$S_D{"FHH"},$S_D{"LH"},$S_D{"GH"},$S_D{"WKY"},$S_D{"BN/SSN"},$S_D{"BN/CUBLX"},$S_D{"SR/JR"},$S_D{"MNS"},$S_D{"ACI"},$S_D{"LN"},$S_D{"LEW"},$S_D{"AVN"},$S_D{"BB(DP)"},$S_D{"BB(DR)"},$S_D{"BC/CPBU"},$S_D{"BDIX"},$S_D{"BDVII"},$S_D{"BP"},$S_D{"BUF"},$S_D{"COP"},$S_D{"DA"},$S_D{"DRY"},$S_D{"F344"},$S_D{"GK"},$S_D{"IS/KYO"},$S_D{"LE"},$S_D{"LOU/C"},$S_D{"M520"},$S_D{"MNR"},$S_D{"MNRA"},$S_D{"MR"},$S_D{"NEDH"},$S_D{"NP"},$S_D{"ODU"},$S_D{"OKA"},$S_D{"OM"},$S_D{"P"},$S_D{"PVG"},$S_D{"SD"},$S_D{"WAG"},$S_D{"WF"},$S_D{"WIST"},$S_D{"WN"},$S_D{"WTC"},"common",
			 );
my @DIABETES_ORDER = (
		      $S_D{"BB(DP)"},$S_D{"GK"},$S_D{"BB(DR)"},$S_D{"OKA"},$S_D{"LE"},$S_D{"ODU"},$S_D{"ACI"},$S_D{"AVN"},$S_D{"BC/CPBU"},$S_D{"BDIX"},$S_D{"BDVII"},$S_D{"BN/CUBLX"},$S_D{"BN/SSN"},$S_D{"BP"},$S_D{"BUF"},$S_D{"COP"},$S_D{"DA"},$S_D{"DRY"},$S_D{"FHH"},$S_D{"F344"},$S_D{"GH"},$S_D{"IS/KYO"},$S_D{"LH"},$S_D{"LEW"},$S_D{"LOU/C"},$S_D{"LN"},$S_D{"M520"},$S_D{"MHS"},$S_D{"MNR"},$S_D{"MNRA"},$S_D{"MNS"},$S_D{"MR"},$S_D{"NEDH"},$S_D{"NP"},$S_D{"OM"},$S_D{"P"},$S_D{"PVG"},$S_D{"SD"},$S_D{"SHR"},$S_D{"SR/JR"},$S_D{"SHRSP"},$S_D{"SS/JR"},$S_D{"WAG"},$S_D{"WF"},$S_D{"WIST"},$S_D{"WKY"},$S_D{"WN"},$S_D{"WTC"},"common",
		     );

my @RF_ORDER = (
		$S_D{"FHH"},$S_D{"GK"},$S_D{"BN/CUBLX"},$S_D{"BN/SSN"},$S_D{"SS/JR"},$S_D{"MNS"},$S_D{"GH"},$S_D{"BB(DP)"},$S_D{"ACI"},$S_D{"SHR"},$S_D{"MHS"},$S_D{"AVN"},$S_D{"BB(DR)"},$S_D{"BC/CPBU"},$S_D{"BDIX"},$S_D{"BDVII"},$S_D{"BP"},$S_D{"BUF"},$S_D{"COP"},$S_D{"DA"},$S_D{"DRY"},$S_D{"F344"},$S_D{"IS/KYO"},$S_D{"LH"},$S_D{"LE"},$S_D{"LEW"},$S_D{"LOU/C"},$S_D{"LN"},$S_D{"M520"},$S_D{"MNR"},$S_D{"MNRA"},$S_D{"MR"},$S_D{"NEDH"},$S_D{"NP"},$S_D{"ODU"},$S_D{"OKA"},$S_D{"OM"},$S_D{"P"},$S_D{"PVG"},$S_D{"SD"},$S_D{"SR/JR"},$S_D{"SHRSP"},$S_D{"WAG"},$S_D{"WF"},$S_D{"WIST"},$S_D{"WKY"},$S_D{"WN"},$S_D{"WTC"},"common",
	       );
	       
my $rgd_html = RGD::HTML->new(
			 title      => "RGD ACP Haplotyper",
			 version    => "1.1",
			 link_dir  => "ACPHAPLOTYPER",
			 category  => "tools",
			);
			

my $baseURL="";
my $baseCGI="/tools";
my $wwwPATH=$rgd_html->get_wwwPATH;   # /rgd_home/rgd/WWW
my $toolPATH=$rgd_html->get_toolPATH; # /rgd_home/rgd/TOOLS

my $parser = new XML::DOM::Parser;
my $rgd = new XML_RGD;
my $form = new CGI;
my $ps = PostScript::Basic->new();

my $SCRIPT_NAME = "PS_acp_haplotyper";
my $GHOSTSCRIPT = "/usr/bin/gs";

# start importing the variables from the HTML Form.
my $DEBUG = $form->param("debug") || 1; # remember to set to 0 from web page!

# print HTML head
$rgd_html->html_head;

# tool start here
$rgd_html->tool_start;

if($form->param("load_action") eq "finish") {
 

  print "<H2>ACP Haplotyper Results</H2>";
  print "<P>Your results are being processed and the completed output file will be emailed to you.\n";
  print "<P>If you wish to run further analyses you can <a href=\"/ACPHAPLOTYPER\">return to ACP Haplotyper</a>\n";

  # tool page end here
  $rgd_html->tool_end;
  
  # print HTML foot
  $rgd_html->html_foot;
  exit;
}

# hard code in the map information - should get this from RGD really..
my %MAP_INFO = (
		2 => {
		      name => "SHR x BN, v7",
		      type => "genetic",
		     },
		1  => {
		      name => "FHH x ACI, v7",
		      type => "genetic",
		     },
		3  => {
		      name => "MCW RH v2.1",
		      type => "rh",
		     },
		5  => {
		      name => "MCW RH v3.2",
		      type => "rh",
		     },
		6  => {
		      name => "MCW RH v3.4",
		      type => "rh",
		     },
		7  => {
		      name => "MCW Genomic Annotations, vs build 3.1",
		      type => "physical",
		     },	
	       );


# initialized the basic parameters for the data retrieval and display
my $rgd_map_id = $form->param("rgd_map_id") || 2;
my $map_type = $MAP_INFO{$rgd_map_id}{type} || "genetic";
my $map_name = $MAP_INFO{$rgd_map_id}{name} || "No Name";

my $chromosome_num = $form->param('chromosome_num') || 19;
my $flank1 = $form->param('flank1') || 0;
my $flank2 = $form->param('flank2') || 0;
my $flank1_distance = -1;
my $flank2_distance = -1;

my $user_email = $form->param('email');
my $color_scheme = $form->param('color_scheme') || "normal";

my @selected_strains = $form->param('strains');

# if they selected all strains
if(!$form->param('strains') || $form->param('strains') =~ /all/) {
  @selected_strains = @ACP_STRAINS;
}
elsif ($form->param('strains') =~ /hypertension/) {
  @selected_strains = @HYPERTENSION_ORDER;
}
elsif ($form->param('strains') =~ /diabetes/) {
   @selected_strains = @DIABETES_ORDER;
}
else {
  #warn "Strains: @selected_strains\n";
  # Update the strain symbols
  for my $st (0 .. $#selected_strains) {
    $selected_strains[$st] = $S_D{$selected_strains[$st]};  
  }
}

my $primary_strain = $S_D{$form->param("primary_strain")} || $S_D{"SHR"};
my $primary_color = $form->param("primary_color") || "blue";

my $secondary_strain = $S_D{$form->param("secondary_strain")} || $S_D{"FHH"};
my $secondary_color = $form->param("secondary_color") || "red";

my $lod_threshold = $form->param("lod_threshold") || 0.0;
my $output_format = $form->param("output_format") || "pdf"; # what format the output is going to end up as
my $bp_range = $form->param("bp_range") || 0;
my $image_only = $form->param("image_only") || 0;
my $font_size = $form->param("font_size") || "twelve";
my $no_table = $form->param("no_table") || "table_haplotype";
my $sort_by_similarity = $form->param("sort_by_similarity") || 0; # default to off - no sort, alphabetical order.

my $homology_yn =  $form->param("homology_yn") || "no"; # default to doing the homology calculations
my $window_size = $form->param("window_size") || 10;
my $slide_increment = $form->param("slide_inc") || 5;

if($slide_increment > $window_size) {
  &HTML_Error("The Slide Increment must be less than the Window size or you will lose data!");
}


my $LOG = "/tmp/acp_haplotyper.log";

open (LOG,">$LOG") or &HTML_Error("Unable to write to log file: $!");
my $date = scalar localtime();
my $remote_address = $ENV{'REMOTE_ADDR'};
my $remote_host = $ENV{'REMOTE_HOST'};
my $referer = $ENV{'HTTP_REFERER'};
my $browser = $ENV{'HTTP_USER_AGENT'};

my $doc = "";


print LOG <<"EO_LOG";
\n$date
  \tRemote_address:\t$remote_address
  \tRemote_host:\t$remote_host
  \tReferer Page:\t$referer
  \tBrowser_used:\t$browser
EO_LOG

close LOG;

#########################################
# GLOBAL VARIABLES HOLDING MARKER DATA  #
#########################################

my %markers = (); # will hold the marker data as a hash of hashes

# Fork a new process here to output a message
use Errno qw(EAGAIN);

FORK: {

  if(my $pid = fork) {
    
    &debug("Forking the redirect script\n");
  
    # redirect the page to a new copy of this script.
    print "<p>Processing ACP Haplotyper request...\n";
 
    print <<__JS__;
  <SCRIPT LANGUAGE="JavaScript"><!--
window.location.href = '/tools/acphaplotyper/acp_haplotyper2002.cgi?load_action=finish';
//--></SCRIPT>
__JS__
 
  
}
  elsif (defined $pid) {

    wait;

    # check that the flank markers are in the selected genetic map
    # otherwise there isnt much point in continuing at the moment.
    &debug("Checking flanking markers with &check_flank()");
    &check_flank;
    
    
    # get data from database and store in %markers
    &debug("Getting map_marker_data from rgd for $chromosome_num, map ID: $rgd_map_id");
    
    $rgd->set_XML_OUT_FLAG(1); # turn on XML output from XML_RGD.pm
    
    my $xml = ""; # try passing by reference to speed things up.
    
    
    $rgd->get_map_marker_data_from_rgd($rgd_map_id,$chromosome_num,\%markers,$flank1_distance,$flank2_distance, \$xml);
    &debug("Got Data from RGD, parsing doc");
    
    # warn "$xml\n";
    
    $doc = $parser->parse($xml);
    &debug("Done..");
    
    # Now we have the document read into the XML::Parser module we can calculate some statistics on
    # it and enter theses values into the document structure
    
    &debug("Processing Marker data");
    &process_markers;
    &debug("Done.");
    
    &debug("Adding Parameter info to doc");
    &process_parameters;
    &debug("Done.");
    
    # now we've assembled the document, display it according to the
    # desired output format.
    &display_xml_data($output_format);
    
  }
  elsif($! == EAGAIN) {
    sleep 5;
    redo FORK;
  }
  else {
    # wierd fork error
    &HTML_Error("Cant fork: $!\n");
  }
}

exit;






################################################
# 
# Subroutines follow from here on
#
################################################

############
# 
# display_xml_data
#
# Pass on the XML data to routines designed to present the document in
# the appropriate format.
#
# It would be nice once XSL comes in with perl to use XSL here but
# for now we'll have to do it the old fashioned way.
#
#
############

sub display_xml_data {

  my $output_format = shift @_;

  if ($output_format eq "xml") {
    &output_xml;
  }
  elsif ($output_format eq "html") {
    &output_html;
  }
  elsif ($output_format eq "pdf") {
    &output_pdf;
  }
  else {
    &HTML_Error("Unknown Output Format: $output_format");
  }
}


############
# 
# output_xml_data - send out XML data with appropriate style sheets for XML enabled 
# browsers, currently IE5 only (September 1999)
#
############

sub output_xml {

  my $xml_out = "<?xml version=\"1.0\" encoding=\"UTF-16\" ?>";
  
  # based on the desired output format, we should attach the appropriate
  # XLS stylesheet here: to make HTML table, with/without figures, CSV file, etc.


  &debug("Emailing XML format to user\n");
  my $file_name = $$ . "_acp_tmp.xml";

  open (XML, ">$file_name") or die "Cant open XML to print: $!\n";
  print XML"<?xml version=\"1.0\" encoding=\"UTF-16\" ?>\n";
  print XML $doc->toString;
  close (XML);

  &mail($file_name,"text/xml");
  # unlink($file_name);
  &debug("End of xml_out\n");
}


############
# 
# output_pdf - 
#
############

sub output_pdf {

  &debug("Making new PS_Map object\n");
  my $ps = new LGR::XML::PS_Map(
				show_size => $form->param("image_only") || "yes",
				small_font_size => 3, # allele size text size, 4 is too large...
			       );
  # unbuffered output
  # $| = 1;
  
  #print "Done\n";

  # initialize some stuff in the XML haplotype drawing module
  $ps->set_XML_doc($doc);
  $ps->set_selected_strains(@selected_strains);

  # set the selected color schemes
  $ps->set_primary_color($primary_color);
  # $ps->set_display_ordering($sort_by_similarity);

  if($secondary_color !~ /off/){
    $ps->set_secondary_color($secondary_color);
  }

  # Set global color scheme for visual haplotypes
  &debug("Setting color scheme to $color_scheme\n");
  $ps->set_color_scheme($color_scheme);

  # $ps->XML_toString($doc);

  &debug("Calling create map\n");
  my $postscript = $ps->create_map;
  &debug("Done.\nOutput message to screen\n");

  use FileHandle;
  STDOUT->autoflush(1);

  &debug("Done.\nPiping to Ghostscript...\n");
  
# open a pipe to ghostscript
# -sDEVICE = pdfwrite 
# -sOutputFile=-  means GS writes to STDOUT
# -q suppresses any informational messages from GS
# - indicates GS will read postscript from STDIN
# 2>/dev/null pipes any error messages to a null device
  
  my $pdf_file = "/tmp/" . $$ . "_acp_out.pdf";
  
  open (PS, ">$pdf_file") or die "Cant write postcript to output: $!";
  print PS $postscript;
  close PS;

  open (GS, "|$GHOSTSCRIPT -sDEVICE=pdfwrite -sOutputFile=$pdf_file -q - ");

  # send the postscript to GS which should then send the PDF doc to stdout
  print GS $postscript;

  close GS;

  # Mail the file to the user

  &mail($pdf_file,"application/pdf");
  
  # now want to unlink the pdf file.
  #warn "pdf=$pdf_file\n";
  #system "unlink $pdf_file";
  &debug("Done.");
  # &HTML_Error("PDF file created and emailed to $user_email.\n");

}

############
# 
# mail()
#
# Emails the output file as an attachment to the user
#
############

sub mail {

  my ($file,$mime_type) = @_;

  use MIME::Entity;
  warn "Mailing to $user_email\n";

  my $top = MIME::Entity->build(
				Type => "multipart/mixed",
				From => "curation\@rgd.mcw.edu",
				To => "$user_email",
				Subject => "ACP Haplotyper Result",
			       );

  my $message = <<"EOF";

Attached to this email is the output from RGD ACP Haplotyper
http://rgd.mcw.edu/ACPHAPLOTYPER

Output Parameters:
----------------------------------
Chromosome: $chromosome_num
Primary Strain:  $primary_strain
Secondary Strain: $secondary_strain

LOD Threshold: $lod_threshold
BP Range: $bp_range
Sort: $sort_by_similarity

EOF

  $top->attach( Data => $message,);

  $top->attach (
		Path => "$file",
		Type => "$mime_type",
		Encoding => "base64",
	       );

  

  open (MAIL, "| /usr/lib/sendmail -t -oi -oem") or die "Cant open pipe to sendmail: $!\n";
  $top->print(\*MAIL);
  close MAIL;

  # close the filehandle

}


############
# 
# process_parameters
#
# Include the various parameters that the user entered on the 
# original web page
#
############

sub process_parameters {
  
  # Need to add in the following parameters
  #
  # <parameters>
  #   <chromosome number="">
  #   <flank1 distance="" name="">
  #   <flank2 distance="" name="">
  #   <primary_strain name="">
  #   <secondary_strain name="">
  #   <lod_threshold value="">
  #   <bp_range value="">
  #   <display table_yn="" data_yn="" font_size="" >
  #   <sort option="">
  # </parameters>


  my $parameter_element = $doc->createElement("parameters");

  my $map_element = $doc->createElement("map");
  $map_element->setAttribute("type",$map_type);
 $map_element->setAttribute("name",$map_name);
  $parameter_element->appendChild($map_element);

  my $chromosome_element = $doc->createElement("chromosome");
  $chromosome_element->setAttribute("number",$chromosome_num);
  $parameter_element->appendChild($chromosome_element);

  if($flank1) {
    my $flank1_element = $doc->createElement("flank1");
    $flank1_element->setAttribute("distance",$flank1_distance);
    $parameter_element->appendChild($flank1_element);
  }
  if($flank2) {
    my $flank2_element = $doc->createElement("flank2");
    $flank2_element->setAttribute("distance",$flank2_distance);
    $parameter_element->appendChild($flank2_element);
  }

  my $primary_strain_element = $doc->createElement("primary_strain");
  $primary_strain_element->setAttribute("name",$primary_strain);
  $parameter_element->appendChild($primary_strain_element);

  if($secondary_color !~ /off/) {
    my $secondary_strain_element = $doc->createElement("secondary_strain");
    $secondary_strain_element->setAttribute("name",$secondary_strain);
    $parameter_element->appendChild($secondary_strain_element);
  }
  
  my $lod_threshold_element = $doc->createElement("lod_threshold");
  $lod_threshold_element->setAttribute("value",$lod_threshold);
  $parameter_element->appendChild($lod_threshold_element);

  my $bp_range_element = $doc->createElement("bp_range");
  $bp_range_element->setAttribute("value",$bp_range);
  $parameter_element->appendChild($bp_range_element);
  
  warn "Setting attribute no_table =  $no_table\n";	
  
  my $display_element = $doc->createElement("display");
  $display_element->setAttribute("table",$no_table);
  $display_element->setAttribute("image_yn",$image_only);
  $display_element->setAttribute("font_size",$font_size);
  $display_element->setAttribute("homology_yn",$homology_yn);
  $display_element->setAttribute("order",$sort_by_similarity);
  $display_element->setAttribute("color_scheme",$color_scheme);
  $parameter_element->appendChild($display_element);

  my $homology_element =  $doc->createElement("homology");
  $homology_element->setAttribute("window_size",$window_size);
  $homology_element->setAttribute("slide_inc",$slide_increment);
  $parameter_element->appendChild($homology_element);


  # add this node on to the end of the document
  $doc->getDocumentElement->appendChild($parameter_element);

}






############
# 
# process_markers
#
# Goes through all the markers in the retrieved data and calculates..stuff.
#
############

sub process_markers {
  # all the markers in the map
  my $marker_nodes = $doc->getElementsByTagName("marker");
  my $m = $marker_nodes->getLength;
  
  for (my $i = 0; $i < $m; $i++) {
    my $node = $marker_nodes->item($i);
    
    # pass the marker node to the subroutine
    # to calculate the allele frequency data and insert
    # the calculated data back into the document tree
    &calculate_oldest_allele($node);
    
    my $name_node = $node->getElementsByTagName("name");
    
    my $n = $name_node->getLength;
    
    for (my $ii = 0; $ii < $n; $ii++) {
      my $nnode = $name_node->item($ii);
      
      my $nnode_children = $nnode->getChildNodes;
      
      # print $nnode->getFirstChild->getData . "\n";
      
      #print "This node has " . $nnode_children->getLength . " children \n";
      my $j = 0;
      for $j (0 .. $nnode_children->getLength) {
	
	if ($nnode_children->item($j)) {
	  #print $nnode_children->item($j)->getData . "\n";
	  #print $nnode_children->item($j)->toString . "\n";
	  #print $nnode_children->item($j)->getNodeType . "\n";
	}
	
      }
    }
    
  }
  
}





############
# 
# calculate_oldest_allele
#
# Iterates over the markers in the list and if they have allele_size data, 
# calculates the most frequent allele size and frequency
#
############

sub calculate_oldest_allele {

  my $m_node = shift @_;

  
  # check to see if it has a <no_acp_data/> element, if so, move on
  my $no_allele_node = $m_node->getElementsByTagName("no_acp_data");
  if($no_allele_node->getLength) {
    # print "\n\n" . $m_node->toString . " has " .$no_allele_node->getLength  . "nodes \n";
    return; # end subroutine, this is currently obsolescent here...
  }
  else {
    # this marker has allele size data
    # get a node_list of all the allele_size elements

    my $allele_size_list = $m_node->getElementsByTagName("allele_size");
    my %sizes = (); # holds the hash of allele size frequencies, reset here
    my $most_frequent_allele_freq = 0;
    my $most_frequent_allele_size = 0;
    my $allele_count = 0;
    
    # go through each allele size and sum up the data
    for ($allele_count = 0; $allele_count < $allele_size_list->getLength; $allele_count++) {
      
     
      my $allele_node = $allele_size_list->item($allele_count);
      my $size = $allele_node->getFirstChild->getData;

      # increase the count for this allele size by one
      $sizes{$size} += 1;
      
      if( $sizes{ $size } >  $most_frequent_allele_freq ) {
	 $most_frequent_allele_freq =  $sizes{ $size };
	 $most_frequent_allele_size =  $size;
      }

    }
    my @allele_sizes = keys %sizes;
    my $number_of_alleles = $#allele_sizes+1;

   
    # now create a new element in this marker node for the allele frequency and size
    my $common_allele_data_element = $doc->createElement("common_allele_data");
    $common_allele_data_element->setAttribute("size",$most_frequent_allele_size);
    $common_allele_data_element->setAttribute("frequency",$most_frequent_allele_freq);
    $common_allele_data_element->setAttribute("total_allele_num",$allele_size_list->getLength);
    $common_allele_data_element->setAttribute("num_unique_alleles",$number_of_alleles);
    
    # add this node to the marker node.
    $m_node->appendChild($common_allele_data_element);


    # create a new common strain element for the allele size data
    my $common_strain_element = $doc->createElement("allele_size");
    $common_strain_element->setAttribute("strain","common");

    # make a new text node
    my $common_strain_size = $doc->createTextNode($most_frequent_allele_size);
    # append text node to allele_size element
    $common_strain_element->appendChild($common_strain_size);

    # append the element to the main allele_size list node
    $m_node->appendChild($common_strain_element);

    
  }
  
}


############
# 
# check_flank markers & distances  -go to the 
#
############

sub check_flank {
  &debug("\tcheck_flank():");
  if($flank1) {
    
    if($flank1 =~ /^\d+\.?\d*$/) {
      # its just a straight distance
      $flank1_distance = $flank1;
    }
    else {
      # its probably a marker name
      my @data = &check_marker_data($flank1);
      # check_marker_data returns -1 if there is no marker data in the db
      if($data[0] < 0) {
	&HTML_Error("Flanking Marker 1: $flank1 not found in the selected map for Chr $chromosome_num");
      }
      else {
	# update flank1_distance as this is the value we use in the SQL query
	$flank1_distance = $data[0];
      }
    }
  }
  if($flank2) {
    
    if($flank2 =~ /^\d+\.?\d*$/) {
      # its just a straight distance
      $flank2_distance = $flank2;
    }
    else {
      # its a marker name
      my @data = &check_marker_data($flank2);
      if($data[0] < 0) {
	&HTML_Error("Flanking Marker 2: $flank2 not found in the selected map for Chr $chromosome_num");
      }
      else {
	# update flank2_distance as this is the value we use in the SQL query
	$flank2_distance = $data[0]; # the distance
      }
    }
  }

  &debug("\tend of check_flank()");
}


############
# 
# check_marker_data() looks in RGD to see if a given marker (name) is present in
# the selected map - otherwise things might not work too well!
#
############

sub check_marker_data {
  
  my $marker = shift(@_);

  my @data = $rgd->get_a_markers_map_data_from_rgd($marker,$rgd_map_id,$chromosome_num);
  
  # distance might be zero so go by first value which is map_id
  if(!$data[0]) {
    # not in the database so return -1, not zero
    return -1;
  }
  else {
    return $data[1]; # pass back the distance to the calling function
  }

}

############
# 
# Output an debug message if debugging messages are turned on
#
############

sub debug {
  my $message = shift @_;
  my $date = scalar localtime();

  if ($DEBUG) {
    warn "[$$] $date: $message \n";
  }

}


############
# 
# Output an HTML page with error information
#
############

sub HTML_Error {

    # read in the error message passed to the subroutine
    my $error_message = shift(@_) || "You've found an undocumented feature of this software:";
 

    # print out HTML page letting the new user know an error occured

    print "Content-type: text/html\n\n";

    print <<"EOF";
<HTML><HEAD><TITLE>PostScript ACP_HAPLOTYPER Message</TITLE></HEAD<
<BODY BGCOLOR="#FFFFFF">
<BR>
<H1>PostScript ACP_HAPLOTYPER Message</H1>

<STRONG>$error_message</STRONG>

<P>Use the <STRONG>BACK</STRONG> button on your Browser to return to the previous screen if you need to amend your parameters</P>

<HR>
Questions and Comments to <a href="RGD Team">/contact/index.shtml</a>
</BODY></HTML>
EOF

    # stop the execution of the script here
    exit;
}

############
# 
# Output an HTML page with error information
#
############

sub HTML_Message {

    # read in the error message passed to the subroutine
    my $error_message = shift(@_) || "You've found an undocumented feature of this software:";
 

    # print out HTML page letting the new user know an error occured

    print "Content-type: text/html\n\n";

    print <<"EOF";
<HTML><HEAD><TITLE>PostScript ACP_HAPLOTYPER Message</TITLE></HEAD<
<BODY BGCOLOR="#FFFFFF">
<BR>
<H1>PostScript ACP_HAPLOTYPER Message</H1>

<STRONG>$error_message</STRONG>

<P>Use the <STRONG>BACK</STRONG> button on your Browser to return to the previous screen if you need to amend your parameters</P>

<HR>
Questions and Comments to <a href="RGD Team">/contact/index.shtml</a>
</BODY></HTML>
EOF

    # stop the execution of the script here
    return;
}


__END__
