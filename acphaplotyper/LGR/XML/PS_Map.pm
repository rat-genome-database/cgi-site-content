#!/usr/bin/perl
#########################
#
# LGR::XML::PS_Map.pm - A perl 5 module to create PostScript maps from XML data
#
# (c) Simon Twigger, Medical College of Wisconsin, 1999.
#     simont@mcw.edu
#
#########################





#########################
#
#   Notes
#
#########################
#  
# 
#
# 
# 
#
#########################





#########################
#
#   Bugs/To Do List
#
#########################
#  
#
# 
# 
#
#########################


package LGR::XML::PS_Map;

require 5.003;
require Exporter;

use strict; # to keep me honest
use Carp;   # to make error reporting a bit easier
use vars qw($VERSION @ISA);
use PostScript::Basic;

# Shawn Wallace's PostScript modules
#use PostScript::Document;
#use PostScript::TextBlock;
#use PostScript::Metrics;

$VERSION = "0.2";
@ISA = qw(Exporter);

@SUBCLASS::ISA = qw(PS_Map);

#my @ACP_STRAINS = ("common","ACI","AVN","BB(DP)","BB(DR)","BC/CPBU","BDIX","BDVII","BN/CUBLX","BN/SSN","BP","BUF","COP","DA","DRY","FHH","F344","GH","GK","IS/KYO","LH","LE","LEW","LOU/C","LN","M520","MHS","MNR","MNRA","MNS","MR","NEDH","NP","ODU","OKA","OM","P","PVG","SD","SHR","SR/JR","SHRSP","SS/JR","WAG","WF","WIST","WKY","WN","WTC");
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

my %SCALE_FACTORS = (
		     rh => 1750,
		     genetic => 170,
		     physical =>  270000000,
		   );

# the tick mark distance in cM (genetic) or cR (RH)
my %SCALE_LEGEND = (
		    rh => 100,
		    genetic => 10,
		    physical =>  10000000,
		   );

my $DEBUG = 0;

my $TIME = scalar localtime();
my $GHOSTSCRIPT = "/usr/local/bin/gs";
my $doc = ""; # will hold the XML::DOM Object from the calling script
my @selected_strains = (); # holds an array of selected strains for display
my $color_numbers = 1; # yn color numbers in Strain identity % table
my %identity = (); # will hold the inter strain identity data
my @identity_rank = ();

my %homology = (); # will hold the inter strain homology data
my @homology_rank = ();

my %DOC = (); # will hold any attributes I pick up along the way to avoid using the DOM all the time *slow*
my $ps = "";

my @BINS = (); # a hash containing marker details for each bin
my %MARKERS = (); # hash containing marker details as they are read in
my %max_percent = (); # HoH of maximum homology scores for each strain v strain comparison

my $bin_count = 0;
my $color_scheme = "";	

##############
# PostScript page definitions and size info
##############

my $y_max = 730;
my $y_min = 72; # one inch from the bottom, leave room for footer/legend
my $x_min = 36; # half inch from the LHS
my $x_max = 576; # half inch from the RHS

my $box_start = 170; # x coordinate of the start of the boxes
my $lh = 8; # the line height for each row of data

my $box_h = $lh; # height and width of boxes same as line height
my $box_w = $lh;
my $x_lhs = $box_start - 50;
my $x_rhs = $box_start - 7;
my $bar_h = int($lh/2); # half the line height

my $red = "";
my $blue = "";
my $green = "";
my $white = "";
my $black = "";
my $grey = "";
my $orange = "";
my $whyte = "";


my %color = ();
my %phs_col = ();
my @phs_col_array = ();
my @phs_col_titles_array = ();

my @af = ();

my @id_f = ();

my @primary_curve_array = ();
my @secondary_curve_array = ();

#############
#
# The constructor method
#
#############

sub new {
  my ($class,%args) = @_;
  my $self =  {
	 _show_size => $args{show_size} || "no",	 
	};
  
  bless $self,$class;
  $self->_intitialize();
  return $self;
}


#############
# Basic initialization subroutine
#############

sub _intitialize {

  # set up the PostScript::Basic object here.
  $ps = new PostScript::Basic;
  $red = $ps->ps_colorAllocate(1,0,0);            # either use values from 0 - 1
  $blue = $ps->ps_colorAllocate(0,0,255);         # or from 0 - 255
  $green = $ps->ps_colorAllocate(0.2,1,0.2);
  # $white = $ps->ps_colorAllocate(255,255,255);
  $white = $ps->ps_colorAllocate(0,0,0);
  $black = $ps->ps_colorAllocate(0,0,0);
  $grey = $ps->ps_colorAllocate(0.8,0.8,0.8);
  $orange = $ps->ps_colorAllocate(200,200,0);
  $whyte = $ps->ps_colorAllocate(255,255,255);

  $color{red} = $ps->ps_colorAllocate(1,0,0);   
  $color{blue} = $ps->ps_colorAllocate(0,0,255);         # or from 0 - 255
  $color{green} = $ps->ps_colorAllocate(0.3,1,0.3);
  $color{white} = $ps->ps_colorAllocate(255,255,255);
  $color{black} = $ps->ps_colorAllocate(0,0,0);
  $color{grey} = $ps->ps_colorAllocate(0.8,0.8,0.8);
  $color{orange} = $ps->ps_colorAllocate(200,200,0);
  $color{yellow} = $ps->ps_colorAllocate(255,255,0);
  $color{purple} = $ps->ps_colorAllocate(200,0,255);
  
  $phs_col{"20_plus"} =  $ps->ps_colorAllocate(255,30,255);
  $phs_col{'18_plus'} =  $ps->ps_colorAllocate(250,2,3);
  $phs_col{'16_plus'} =  $ps->ps_colorAllocate(255,85,21);
  $phs_col{'14_plus'} =  $ps->ps_colorAllocate(255,200,20);
  $phs_col{'12_plus'} =  $ps->ps_colorAllocate(255,255,30);
  $phs_col{'10_plus'} =  $ps->ps_colorAllocate(217,236,50);
  $phs_col{'8_plus'} =  $ps->ps_colorAllocate(125,130,50);
  $phs_col{'6_plus'} =  $ps->ps_colorAllocate(50,90,0);
  $phs_col{'4_plus'} =  $ps->ps_colorAllocate(21,50,5);
  $phs_col{'2_plus'} =  $ps->ps_colorAllocate(0,0,0,);
  $phs_col{'zero'} =  $ps->ps_colorAllocate(0,0,0);
  $phs_col{"2_minus"} =  $ps->ps_colorAllocate(0,0,0);
  $phs_col{'4_minus'} =  $ps->ps_colorAllocate(0,65,30);
  $phs_col{'6_minus'} =  $ps->ps_colorAllocate(10,130,90);
  $phs_col{'8_minus'} =  $ps->ps_colorAllocate(60,220,160);
  $phs_col{'10_minus'} =  $ps->ps_colorAllocate(150,255,200);
  $phs_col{'12_minus'} =  $ps->ps_colorAllocate(170,255,250);
  $phs_col{'14_minus'} =  $ps->ps_colorAllocate(110,250,230);
  $phs_col{'16_minus'} =  $ps->ps_colorAllocate(60,160,255);
  $phs_col{'18_minus'} =  $ps->ps_colorAllocate(30,60,255);
  $phs_col{'20_minus'} =  $ps->ps_colorAllocate(110,110,255);
  
 @phs_col_array = (
  $phs_col{"20_plus"} ,
  $phs_col{'18_plus'} ,
  $phs_col{'16_plus'},
  $phs_col{'14_plus'},
  $phs_col{'12_plus'},
  $phs_col{'10_plus'},
  $phs_col{'8_plus'},
  $phs_col{'6_plus'},
  $phs_col{'4_plus'},
  $phs_col{'2_plus'},
  $phs_col{'zero'},
  $phs_col{"2_minus"} ,
  $phs_col{'4_minus'} ,
  $phs_col{'6_minus'},
  $phs_col{'8_minus'},
  $phs_col{'10_minus'},
  $phs_col{'12_minus'},
  $phs_col{'14_minus'},
  $phs_col{'16_minus'},
  $phs_col{'18_minus'},
  $phs_col{'20_minus'},
 );	

	@phs_col_titles_array = ("20+",'18+' ,
  '16+',
  '14+',
  '12+',
  '10+',
  '8+',
  '6+',
  '4+',
  '2+',
  '0',
  "-2" ,
  '-4' ,
  '-6',
  '-8',
  '-10',
  '-12',
  '-14',
  '-16',
  '-18',
  '-20',
 );	

  # allele_frequency colors
  $af[0] = $ps->ps_colorAllocate(153,0,102);
  $af[1] = $ps->ps_colorAllocate(204,0,51);
  $af[2] = $ps->ps_colorAllocate(255,51,0);
  $af[3] = $ps->ps_colorAllocate(255,153,0);
  $af[4] = $ps->ps_colorAllocate(255,204,0);
  $af[5] = $ps->ps_colorAllocate(1,1,0);

  $id_f[0] = $ps->ps_colorAllocate(27, 5, 67);
  $id_f[1] = $ps->ps_colorAllocate(0,0,0);
  $id_f[2] = $ps->ps_colorAllocate(40, 40, 200);
  $id_f[3] = $ps->ps_colorAllocate(80, 164, 212);
  $id_f[4] = $ps->ps_colorAllocate(169, 236, 161);
  $id_f[5] = $ps->ps_colorAllocate(255, 255, 178);
  
  $DOC{primary_strain}{name} = "z"; # dummy value
  $DOC{primary_strain}{color} = "blue";
  
  $DOC{secondary_strain}{name} = "off"; # dummy value
  $DOC{secondary_strain}{color} = "red";
  $DOC{no_match}{color} = "black";
  $DOC{no_primary}{color} = "grey";

  $DOC{display}{order} = 0;
  $DOC{display}{color_scheme} = "normal";	 

  return;
}



#############
#
# Pass in the XML::DOM object we will be working in
#
#############

sub set_XML_doc {
  
  my $me = shift @_;
  $doc = shift @_;
  return 1;

}

#############
#
# Pass in the selected rat strains
#
#############

sub set_selected_strains {
  
  my $me = shift @_;
  @selected_strains = @_;
  # push(@selected_strains,"common");
  return 1;

}

#############
#
# Set the desired color scheme
#
#############

sub set_primary_color {
  my ($me,$color) =  @_;
  $DOC{primary_strain}{color} = $color;
  return 1;
}

sub set_secondary_color {
  my ($me,$color) =  @_;
  $DOC{secondary_strain}{color} = $color;
  return 1;
}


sub set_display_ordering {
  my ($me,$yn) =  @_;
  $DOC{display}{order} = $yn;
  return 1;
}

sub set_color_scheme {
  my ($me,$scheme) =  @_;
  
  warn "Set_color_scheme = $scheme called\n";
  $DOC{display}{color_scheme} = $scheme;
  return 1;
}

#############
#
# create_map() is the main function that processes the XML file and 
# constructs the postscript code which it then returns to the calling
# script for display
#
#############

sub create_map {
  
  my $me = shift @_;
  my $postscript = "";
  my $y_coord = 0;

  $ps->ps_start;
  
  $ps->ps_set_justify("left");

  $ps->ps_string(20,36,730,"ACP Haplotyper Results",$black);
  $ps->ps_string(12,36,710,"RGD ACP Haplotyper (c) Simon Twigger, 1999-2004");
  # $ps->pdf_link(36,710,200,722,"http://rgd.mcw.edu/ACPHAPLOTYPER/",1);

  # Parameters are printed and parameter data read into $DOC{}{}
  $y_coord = &print_parameters(650); # must go before calculate_stats 
  @ACP_STRAINS = @selected_strains;



  &acp_array_to_hash;

	&debug("\tCalculating stats\n");
  # Stats are calculated
  &calculate_stats;


	&debug("\tCalculating homology\n");
  # Homology Data calculated
  if($DOC{display}{homology_yn} eq "Yes") {
    &calculate_homology;
  }

  # sort strain data by percentage or by homology data, if selected
  if($DOC{display}{order} eq "by_percentage") {
    @ACP_STRAINS = sort by_percentage @selected_strains;
  }
  elsif ( ($DOC{display}{order} eq "by_homology")  && ($DOC{display}{homology_yn} eq "Yes") ) {
    @ACP_STRAINS = sort by_homology @selected_strains;
  }

  	&debug("\tAdd new page to document\n");
  #########
  # New Page, draw stats/percentage data
  #########
  
  $ps->ps_add_page;
  $y_coord = &print_stats(730,"NUMBER");
  $y_coord = &print_stats($y_coord,"COLOR");
  &print_footer("title",$x_min);


  #########
  # New Page, draw homology data if selected
  #########

  if ($DOC{display}{homology_yn} eq "Yes") {
    $ps->ps_add_page;
    $y_coord = &print_homology(730,"NUMBER");
    $y_coord = &print_homology($y_coord,"COLOR");
    &print_footer("title",$x_min);
  }


  #########
  # New Page, draw main data display, if selected
  #########

  # only display the table data if they ask for it.
  if($DOC{display}{table_yn} eq "No") {
    # page break here
    $ps->ps_add_page;
    
    &print_data($me);


    #########
    # New Page, draw scaled idiograms
    #########
    
   #  $ps->ps_add_page;

    #########
    # Draw the idiograms of the chromosome displaying allele frequency
    # and percent primary (and %secondary data along the chromosome
    # drawn to scale.
    #########
    
    # $y_coord = &print_idiograms(730,$y_min);

  }

  # finish off the image and print to STDOUT
  return $ps->ps_finish;
  
}


#############
#
# acp_array_to_hash - store a list of selected strains in the $DOC hash to reference in calculate_stats subroutine
#
#############

sub acp_array_to_hash {

  my $c = 0;

  for $c (0 .. $#ACP_STRAINS) {
    $DOC{inc_strain}{$ACP_STRAINS[$c]} = 1;
  }

}


#############
#
# print_data - Output of the actual tabular data for each marker
#
#############

sub print_data {

  my $self = shift @_;

  my $y_cursor = 710;
  
  # print table header here

  # select all the marker elements in the document
  my $marker_nodes = $doc->getElementsByTagName("marker");
  my $m = $marker_nodes->getLength;

  # Print the page's header information first
  &print_header;

	&debug("\tprint data page\n");


 NODE:
  for (my $i = 0; $i < $m; $i++) {
    my $node = $marker_nodes->item($i);
    my $lod = $node->getElementsByTagName("lod")->item(0)->getFirstChild->getData;

    # Only print markers which have allele size data
    if($node->getElementsByTagName("no_acp_data")->getLength) {
      next NODE; # has no ACP data, ignore it
    }
    elsif( ($lod != 0) && ($lod < $DOC{lod_threshold}{value}) )  {
      next NODE; # LOD score too low
    }
    else {
      $y_cursor = &print_marker($y_cursor, $node, $i, $self);
      
      if($y_cursor <= $y_min) {

	&print_curves($color{$DOC{primary_strain}{color}},\@primary_curve_array);
	if($DOC{secondary_strain}{name} ne "off") {
	  &print_curves($color{$DOC{secondary_strain}{color}},\@secondary_curve_array);
	}
	
	&print_footer("data",$x_min);

	# page break here
	$ps->ps_add_page;

	&print_header;
	# reset the x-cursor value to the top of the next page
	$y_cursor = 710;
      }

    }
     
  }

  # finish off the page here
  &print_curves($color{$DOC{primary_strain}{color}},\@primary_curve_array);
  if($DOC{secondary_strain}{name} ne "off") {
    &print_curves($color{$DOC{secondary_strain}{color}},\@secondary_curve_array);
  }
  
  &print_footer("data",$x_min);

}


#############
#
# print_curves - uses bezier curves to show the strain % identity graph
#
#############

sub print_curves {

  # get the array in from the arguments
  my ($color,$array_ref) = @_;

  # go through the curves array, drawing the curves as described by the
  # points in the array
  # $ps->ps_show_control_points(1);

  # get a copy of the linewidth
  my $linewidth = $ps->ps_get_linewidth;

  $ps->ps_set_linewidth(1);

  # start off in top corner
  my $x1 = shift @{$array_ref} || 0;
  my $y1 = shift @{$array_ref} || 0;

  my $start_x = $x_lhs;
  my $start_y = $y1+$bar_h;

  # draw in the first curve
  $ps->ps_bezier($x_lhs,$y1+$bar_h,$x_lhs,$y1,$x1,$y1+$bar_h,$x1,$y1,$color);

  my $c = 0;
  for ($c = 0; $c <= $#{$array_ref}; $c+=2 ) {

    my $x2 = $array_ref->[$c];
    my $y2 = $array_ref->[$c+1];

    # draw curve from x1,y1 to x2,y2
    $ps->ps_bezier($x1,$y1, $x1,$y1-$bar_h ,$x2,$y2+$bar_h, $x2,$y2, $color);
    

    # swap around x1 and y1
    $x1 = $x2;
    $y1 = $y2;
  }

  # draw the end of the curve
  $ps->ps_bezier($x1,$y1,$x1,$y1-$bar_h, $x_lhs,$y1+$bar_h,$x_lhs,$y1-$bar_h, $color );

  $ps->ps_line($x_lhs,$y1-$bar_h,$start_x,$start_y,$black);

  # reset the curve array
  @{$array_ref} = ();

  # reset the linewidth again
  $ps->ps_set_linewidth($linewidth);
}



#############
#
# print_header Print the table header, strain names, etc.
#
#############

sub print_header {

 
  

  $ps->ps_string(6,$x_min,$y_max,"MARKER",$black); 
  $ps->ps_string(6,$x_min+40,$y_max,"LOD",$black);
  $ps->ps_string(6,$x_min+55,$y_max,"Dist",$black);

  $ps->ps_string(6,$x_min+55,$y_max,"Dist",$black);

  my @tmp_headers = ("Freq",@ACP_STRAINS);

  my $name = "";
  my $x_val = $box_start+(int($box_w/2));
  my $y_val = $y_max;

  for ($name = 0; $name <= $#tmp_headers; $name++) {
    
     if( ($tmp_headers[$name] eq $DOC{secondary_strain}{name}) ||
	($tmp_headers[$name] eq $DOC{primary_strain}{name} )) {
       $x_val += 2;
     }
     
    #rotate the coords through 45 degrees, print the name, rotate back
    $ps->ps_gsave;
    $ps->ps_translate($x_val,$y_val);
    $ps->ps_ori_rotate(45);

    if($tmp_headers[$name] eq $DOC{primary_strain}{name}) {
      $ps->ps_string(5,0,0,$tmp_headers[$name],$color{ $DOC{primary_strain}{color}} );
    }
    elsif($tmp_headers[$name] eq $DOC{secondary_strain}{name} ) {
      $ps->ps_string(5,0,0,$tmp_headers[$name],$color{$DOC{secondary_strain}{color}});
    }
    else {
      $ps->ps_string(5,0,0,$tmp_headers[$name],$black);
    }
    
     $ps->ps_grestore;
     
     if( ($tmp_headers[$name] eq $DOC{secondary_strain}{name}) ||
	($tmp_headers[$name] eq $DOC{primary_strain}{name} )) {
       $x_val += 2;
     }
     
     $x_val += $box_w;
  }

}

#############
#
# print_footer Print the table footer, strain names, etc.
#
#############

sub print_footer {

  my ($page_type,$x) = @_;

  my $y = $y_min -10;

  $ps->ps_string(6,$x,$y,"ACP Haplotyper analysis of Chr: $DOC{chromosome}{number} at $TIME",$black);
  $ps->ps_string(6,$x,$y-$lh,"Primary Strain:",$black);
  $ps->ps_rstring(6,6,0,"$DOC{primary_strain}{name}",$color{$DOC{primary_strain}{color}});

  if($DOC{secondary_strain}{name} ne "off") {
    $ps->ps_rstring(6,10,0,"Secondary Strain:",$black);
    $ps->ps_rstring(6,6,0,"$DOC{secondary_strain}{name}",$color{$DOC{secondary_strain}{color}});

  }

  $ps->ps_string(6,$x,$y-(2*$lh),"LOD Threshold: $DOC{lod_threshold}{value}, BP Range: $DOC{bp_range}{value}",$black);


  if($page_type eq "title") {

    # print Statistics range information

    $x += 230; # move into the middle somewhere
    $ps->ps_string(6,$x,$y-(2*$lh),"Strain ID % Scale:",$black);
    
    my @freq_ranges = ("0","<20%","20-40%","40-60%","60-80%",">80%");
    my $x_val = 350;
    my $x_inc = (int($box_w/2));
    my $y_val = $y-(2*$lh);
    my $c = 0;
    
    for ($c = 1; $c <= $#freq_ranges; $c++) {
      
      $ps->ps_gsave;
      $ps->ps_translate($x_val+$x_inc,$y_val+$box_h);
      $ps->ps_ori_rotate(45);
      
      $ps->ps_string(5,0,0,$freq_ranges[$c],$black );
      
      $ps->ps_grestore;
      
      $ps->ps_rectangle($x_val,$y_val-2,$x_val+$box_w,$y_val+$box_h-2,$id_f[$c],$white);
      
      $x_val += $box_w;
    }

  }
  elsif ($page_type eq "data") {

    # print allele frequency range information
    $x += 250; # move into the middle somewhere

	my $title_start = $x;
	
    $ps->ps_string(6,$title_start,$y-(2*$lh),"Allele Frequency Scale:",$black);
    
    my @freq_ranges = ("0","1-3","4-6","7-9","10-12","13+");
    my $x_val = 400;
    my $x_inc = (int($box_w/2));
    my $y_val = $y-(2*$lh);
    my $c = 0;
    
    for ($c = 0; $c <= $#freq_ranges; $c++) {
      
      $ps->ps_gsave;
      $ps->ps_translate($x_val+$x_inc,$y_val+$box_h);
      $ps->ps_ori_rotate(45);

      $ps->ps_string(5,0,0," ",$black ); # empty string - gsave issues cropping up, font size wrong.
      $ps->ps_string(5,0,0,$freq_ranges[$c],$black );
      
      $ps->ps_grestore;
      
      $ps->ps_rectangle($x_val,$y_val-2,$x_val+$box_w,$y_val+$box_h-2,$af[$c],$white);
      
      $x_val += $box_w;
    }
    
     if($DOC{display}{color_scheme} eq "red_blue") {
 		
 		# Print red_blue coloring scheme out as well.
    
    $x_val = 400;
	$y_val = $y-(5*$lh);
	$ps->ps_string(6,$title_start,$y_val,"Allele bp difference:",$black);
	
	my $bp_start = 20;
	my $bp_finish = -20;
	my $bp = $bp_start;
	
	for (my $cc = $bp_start; $cc >= $bp_finish; $cc-=2) {
	  
	  $ps->ps_gsave;
	  $ps->ps_translate($x_val+$x_inc,$y_val+$box_h);
	  $ps->ps_ori_rotate(45);

	  $ps->ps_string(5,0,0," ",$black ); # empty string - gsave issues cropping up, font size wrong.
	  $ps->ps_string(5,0,0,$cc,$black );
	  
	  $ps->ps_grestore;
	  my $color = &red_blue_color($cc);
	  $ps->ps_rectangle($x_val,$y_val-2,$x_val+$box_w,$y_val+$box_h-2,$color,$grey);
	  
	  $x_val += $box_w;
	}
 		
	 }
	 elsif ($DOC{display}{color_scheme} eq "phys_prof") {
    # Print physiological coloring scheme out as well.
    
    $x_val = 400;
    $y_val = $y-(5*$lh);
    $ps->ps_string(6,$title_start,$y_val,"Allele bp difference:",$black);
    
    for (my $cc = 0; $cc <= $#phs_col_array; $cc++) {
      
      $ps->ps_gsave;
      $ps->ps_translate($x_val+$x_inc,$y_val+$box_h);
      $ps->ps_ori_rotate(45);

      $ps->ps_string(5,0,0," ",$black ); # empty string - gsave issues cropping up, font size wrong.
      $ps->ps_string(5,0,0,$phs_col_titles_array[$cc],$black );
      
      $ps->ps_grestore;
      
      $ps->ps_rectangle($x_val,$y_val-2,$x_val+$box_w,$y_val+$box_h-2,$phs_col_array[$cc],$white);
      
      $x_val += $box_w;
    }
    }
  }
  

}

#############
#
# print_marker - Print a line of marker data
#
#############

sub print_marker {

  my ($y, $node, $order,$self) = @_;


  # need to extract the data from the node
  my $name = $node->getElementsByTagName("name")->item(0)->getFirstChild->getData;
  my $lod = $node->getElementsByTagName("lod")->item(0)->getFirstChild->getData;
  my $dist = $node->getElementsByTagName("abs_distance")->item(0)->getFirstChild->getData;

	&debug("\tprint marker row: $name\n");

  # keep track of the marker order so the map and the other listings are the same.
  $MARKERS{$name}{order} = $order+1;

  # round it up to 2d.p.
  $dist = (int($dist *100) )/100;

	&debug("\tpget f_p node\n");
  my $f_or_p = $node->getElementsByTagName("f_or_p")->item(0)->getFirstChild->getData;
  $MARKERS{$name}{f_or_p} = $f_or_p || 'p';

	&debug("\t switch based on f_p node\n");

  if($f_or_p eq "f") {
    # framework marker in blue
    $ps->ps_string(6,$x_min,$y,"\u$name",$blue); # Upper case the first letter using \u
  }
  else {
    $ps->ps_string(6,$x_min,$y,"\u$name",$black); # Upper case the first letter using \u
  }
  
  $ps->ps_string(6,$x_min+40,$y,"$lod",$black); # Upper case the first letter using \u
  $ps->ps_string(6,$x_min+55,$y,"$dist",$black); # Upper case the first letter using \u

  # Now loop around each strain's data, getting the size information and then 
  # we can calculate statistics and color schemes for display, etc.

  my %allele_size = (); # will be keyed by strain name, value = allele size in bp.

  my $allele_size_list = $node->getElementsByTagName("allele_size");
  my $allele_count = 0;
    
  # go through each allele size and sum up the data
  for ($allele_count = 0; $allele_count < $allele_size_list->getLength; $allele_count++) {
    my $allele_node = $allele_size_list->item($allele_count);
    my $strain_name = $allele_node->getAttribute("strain");
    my $size = $allele_node->getFirstChild->getData;
    
    $allele_size{$strain_name} = $size;

  }

	&debug("\tprint histogram: $name\n");


  #################
  # Primary/Secondary Histogram
  #################

  # use 100pt for the bars to keep the maths easy
  # start relative to where the boxes are starting
  $x_lhs = $box_start - 50;
  $x_rhs = $box_start - 7;
  $bar_h = int($lh/2); # half the line height


	# Need to scale to 43, not to 50
  my $primary_len = int( (($identity{$name}{primary_strain}/($#ACP_STRAINS+1))*100)*0.43);
  my $secondary_len = int( (($identity{$name}{secondary_strain}/($#ACP_STRAINS+1))*100)*0.43);
  
  my $bp_range = $DOC{bp_range}{value};

  my $primary_size  = $allele_size{$DOC{primary_strain}{name}} || 0;
  my $secondary_size  = $allele_size{$DOC{secondary_strain}{name}} || 0;

  # push(@primary_curve_array,$x_lhs+$primary_len,$y+$bar_h);
  
  # push(@secondary_curve_array,$x_lhs+$secondary_len,$y+$bar_h);

  if($DOC{secondary_strain}{name} ne "off") {

    # if 1ary and 2ary sizes are the same +/- bp_range, 
    if( abs($primary_size - $secondary_size) <= $bp_range ) {
      push(@primary_curve_array,$x_lhs+$primary_len,$y+$bar_h);
      push(@secondary_curve_array,$x_lhs,$y+$bar_h);

      # store the length details in the marker array
      $MARKERS{$name}{primary_len} = $primary_len;
      $MARKERS{$name}{secondary_len} = 0;

      # both same size, so draw primary bar only, $lh tall
      # $ps->ps_rectangle($x_lhs,$y,$x_lhs+$primary_len,$y+$lh,$color{$DOC{primary_strain}{color}},$white);

      # add the curve's apex coordinates to the curve_array
      # push(@curve_array,$x_lhs+$primary_len,$y+$bar_h);
  
      #$ps->ps_bezier($x_lhs,$y+$lh,$x_lhs,$y+$bar_h,$x_lhs+$primary_len,$y+$lh,$x_lhs+$primary_len,$y+$bar_h,$color{$DOC{primary_strain}{color}});
      #$ps->ps_bezier($x_lhs+$primary_len,$y+$bar_h,$x_lhs+$primary_len,$y,$x_lhs,$y+$bar_h,$x_lhs,$y,$color{$DOC{primary_strain}{color}});

    }
    else {
      push(@primary_curve_array,$x_lhs+$primary_len,$y+$bar_h);
      push(@secondary_curve_array,$x_lhs+$secondary_len,$y+$bar_h);
      
      # store the length details in the marker array
      $MARKERS{$name}{primary_len} = $primary_len;
      $MARKERS{$name}{secondary_len} = $secondary_len;
      # draw primary bar separately
      #$ps->ps_rectangle($x_lhs,$y,$x_lhs+$primary_len,$y+$bar_h,$color{$DOC{primary_strain}{color}},$white);
       
      # draw secondary bar seperately
      #$ps->ps_rectangle($x_rhs,$y+$lh,$x_rhs-$secondary_len,$y+$bar_h,$color{$DOC{secondary_strain}{color}},$white);
      #$ps->ps_rectangle($x_lhs,$y+$lh,$x_lhs+$secondary_len,$y+$bar_h,$color{$DOC{secondary_strain}{color}},$white);
    }
  }
  else {
    
    push(@primary_curve_array,$x_lhs+$primary_len,$y+$bar_h);
    # push(@primary_curve_array,$primary_len,$y+$bar_h);
    # store the length details in the marker array
    $MARKERS{$name}{primary_len} = $primary_len;
    $MARKERS{$name}{secondary_len} = 0;
    
    # draw primary bar only, $lh tall
    #$ps->ps_rectangle($x_lhs,$y,$x_lhs+$primary_len,$y+$lh,$color{$DOC{primary_strain}{color}},$white);
  }

  #################
  # ALLELE FREQUENCY BOXES
  #################
  
  &debug("\tprint allele frequency boxes: $name\n");
  
  my $x = $box_start;
  my $strain_count = 0;
  
  # tmp_y is to center the boxes on the text of the marker names, etc.
  my $tmp_y = $y; #+( int($lh/2));
  # First have to print the Allele Frequency Box, color coded
  my $common_allele_node_l = $node->getElementsByTagName("common_allele_data");
  my $num_unique_alleles = $common_allele_node_l->item(0)->getAttribute("num_unique_alleles");
  
  # there is only one common_allele_node
  $MARKERS{$name}{common_size}= $common_allele_node_l->item(0)->getAttribute("size");
  $MARKERS{$name}{num_unique_alleles}  = $num_unique_alleles;


  if($num_unique_alleles > 13 ) {
    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$af[5],$white);
  }
  elsif($num_unique_alleles > 9 ) {
    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$af[4],$white);
  }
  elsif($num_unique_alleles > 6 ) {
    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$af[3],$white);
  }
  elsif($num_unique_alleles > 3 ) {
    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$af[2],$white);
  }
  elsif($num_unique_alleles > 1 ) {
    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$af[1],$white);
  }
  else {
    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$af[0],$white);
  }
  $x += $box_w;
  
  
  #################
  # Common Size Boxes
  #################

  


  
  #################
  # STRAIN SIZE BOXES
  #################

  # ACP_STRAINS = selected_strains sorted by_percentage at this point
 
 my $box_color = $white;
 if($DOC{display}{color_scheme} eq "red_blue") {
 	$box_color = $whyte;
 }	
 
 STRAIN:
  for($strain_count = 0; $strain_count <= $#ACP_STRAINS; $strain_count++) {
    
  
    if( ($ACP_STRAINS[$strain_count] eq $DOC{secondary_strain}{name}) ||
	($ACP_STRAINS[$strain_count] eq $DOC{primary_strain}{name} )) {
      $x += 2;
    }

    # warn "Checking $ACP_STRAINS[$strain_count] \n";

    # if we've got data for this allele size
    if(defined $allele_size{$ACP_STRAINS[$strain_count]}) {
      
      # if the primary strain has data for this size
      if(defined $allele_size{ $DOC{primary_strain}{name}} ) {
      
      ###
      #
      # Red Blue color scheme
      #
      ###
      
      if($DOC{display}{color_scheme} eq "red_blue") {
      	$box_color = $grey;
      	my $diff = $allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}};
      	
    	if( $diff > 0) {
    		my $red_color = &red_blue_color($diff);
			$ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$red_color,$box_color);
		}
		elsif ($diff < 0) {
    		my $blue_color = &red_blue_color($diff);
			$ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$blue_color,$box_color);
		}
		elsif ($diff == 0) {
			$ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$color{"white"},$box_color);
		}
		else {  
		  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$green,$box_color);
		}
      }
      
      ###
      #
      # Physiological Profiling-like color sheme section
      #
      ###
      
      elsif($DOC{display}{color_scheme} eq "phys_prof") {
      
      if( $allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 20) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'20_plus'},$box_color);
	}
	elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 18) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'18_plus'},$box_color);
	}
	elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 16) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'16_plus'},$box_color);
	}
	elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 14) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'14_plus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 12) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'12_plus'},$box_color);
	}
      
      elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 10) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'10_plus'},$box_color);
	}
      
      elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 8) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'8_plus'},$box_color);
	}
      
      elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 6) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'6_plus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 4) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'4_plus'},$box_color);
	}
     
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > 2) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'2_plus'},$box_color);
	}
      elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} == 0) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'zero'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -2) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'2_minus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -4) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'4_minus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -6) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'6_minus'},$box_color);
	}
	 elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -8) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'8_minus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -10) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'10_minus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -12) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'12_minus'},$box_color);
	}
      elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -14) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'14_minus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -16) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'16_minus'},$box_color);
	}
     elsif ($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{primary_strain}{name}} > -18) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'18_minus'},$box_color);
	}
      else {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$phs_col{'20_minus'},$box_color);
	}
      
      }
      
      ##
      #
      # Normal coloring scheme with primary and secondary colors
      #
      ## 
      else {
      

	# if this size matches the primary size, color red
	if( abs($allele_size{$ACP_STRAINS[$strain_count]}- $allele_size{ $DOC{primary_strain}{name}} ) <= $bp_range) {
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$color{$DOC{primary_strain}{color}},$box_color);
	}
	# if doesnt match 1ary, and we have 2ndary defined
	elsif(defined $allele_size{ $DOC{secondary_strain}{name}} ) {
	
	  # if matches 2ndary, color blue
	  if( abs($allele_size{$ACP_STRAINS[$strain_count]} - $allele_size{ $DOC{secondary_strain}{name}} ) <= $bp_range) {
	    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$color{$DOC{secondary_strain}{color}},$box_color);
	  }
	  else {
	  # otherwise doesnt match anything, color grey
	    $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$color{$DOC{no_match}{color}},$box_color);
	  }
	}
	else {
	  # otherwise no primary match, no secondary defined, so color grey
	  $ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$color{$DOC{no_match}{color}},$box_color);
	}
	}
      }
      else {
    	#otherwise no primary data to compare to so color grey
		$ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$color{$DOC{no_primary}{color}},$box_color);
      }

      # Show the allele size in white if requested
      if($self->{_show_size} eq "yes") {
	$ps->ps_string(3,$x+2,$y+2,"$allele_size{$ACP_STRAINS[$strain_count]}",$color{"white"});
      }
      }
    else {
      #otherwise no data for this point, leave white, put black X in place to show no date
      	$ps->ps_rectangle($x,$tmp_y,$x+$box_w,$tmp_y+$box_h,$box_color);
      	$ps->ps_string(6,$x+2,$y+2,"X",$grey);
    }

    # increase the gap around the 1ary and 2ary boxes so they stand out a bit
    if( ($ACP_STRAINS[$strain_count] eq $DOC{secondary_strain}{name}) ||
	($ACP_STRAINS[$strain_count] eq $DOC{primary_strain}{name} )) {
      $x += 2;
    }
    
    $x += $box_w;
    
  }
  


  ###########
  # Increment x cursor and check for new page
  ###########

  $y -= $lh;

  

  return $y;
}

#########################
#
# returns red_blue color for a given bp size difference
#
#########################

sub red_blue_color {

	my $bp_diff = shift @_;
	my $color = $whyte; # default value to white color
	
	if($bp_diff > 0) {
		my $red_number = 255 - $bp_diff*10;
    	if($red_number < 0 ) { $red_number = 0; }
   	 	$color = $ps->ps_colorAllocate(255,$red_number,$red_number);
	}
	elsif ($bp_diff < 0) {
		my $blue_number = 255 - (-$bp_diff*10);
    	if($blue_number < 0 ) { $blue_number = 0; }
   	 	$color = $ps->ps_colorAllocate($blue_number,$blue_number,255);
	}
	else {
		$color = $whyte;
	}
	
	return $color;	

}


############
#
# print_idiograms
#
###########

sub print_idiograms { # Start of print_idiograms()

  my ($top_y,$bot_y) = @_;

  my $map_length = $DOC{map}{end_distance} - $DOC{map}{start_distance};

  my $allele_start = 100;
  my $percent_start = 350;
  my $max_percent = 75; 
  my $percent_middle = $percent_start + $max_percent;

  my $max_freq = 20; # maximum number of alleles
  my $max_ident = 150; # 100% identity = $max points
 

  # scale the distance out over the whole page for the moment.
  # might want to equalize this so different chromosome diagrams are to
  # scale between themselves.

  my $inc =  ($top_y - $bot_y) / $SCALE_FACTORS{$DOC{map}{type}}; # assume max length of 170cM (Need to fix for RH maps btw)

  my $m = "";
  my $y_dist = 0;


  foreach $m (sort by_distance keys %MARKERS) {

    # draw a line, length proportional to the # of unique alleles

    $y_dist = $top_y - ($MARKERS{$m}{dist} - $DOC{map}{start_distance}) * $inc;
    my $allele_color = $af[0];
    
    if($MARKERS{$m}{num_unique_alleles} > 13 ) {
      $allele_color = $af[5]
    }
    elsif($MARKERS{$m}{num_unique_alleles} > 9 ) {
      $allele_color = $af[4]
    }
    elsif($MARKERS{$m}{num_unique_alleles} > 6 ) {
      $allele_color = $af[3]
    }
    elsif($MARKERS{$m}{num_unique_alleles} > 3 ) {
      $allele_color = $af[2]
    }
    elsif($MARKERS{$m}{num_unique_alleles} > 1 ) {
      $allele_color = $af[1]
    }
   

    $ps->ps_line($allele_start, $y_dist, $allele_start+( $MARKERS{$m}{num_unique_alleles}/$max_freq*$max_ident), $y_dist, $allele_color);

    # print the primary bar
    $ps->ps_line($percent_middle, $y_dist, $percent_middle+( ($MARKERS{$m}{primary_len}*2/100)* $max_percent), $y_dist, $color{$DOC{primary_strain}{color}});

    if($DOC{secondary_strain}{name} ne "off") {
      $ps->ps_line($percent_middle, $y_dist, $percent_middle-( ($MARKERS{$m}{secondary_len}*2/100)* $max_percent), $y_dist, $color{$DOC{secondary_strain}{color}});
    }


  } # end of foreach $m marker loop

  # draw baselines for both graphs
  $ps->ps_set_linewidth(2);
  $ps->ps_set_linecap(1);
  $ps->ps_line($allele_start, $top_y, $allele_start, $y_dist, $black);
  $ps->ps_line($percent_start, $top_y, $percent_start, $y_dist, $black);
 
  # draw horizontal scales for both graphs

  $ps->ps_line($allele_start, $top_y, $allele_start + $max_ident, $top_y, $black);
  $ps->ps_line($percent_start, $top_y, $percent_start + $max_ident, $top_y, $black);

  # draw 50 % and 100% lines for both graphs

  $ps->ps_set_linewidth(0.5);
  $ps->ps_line($percent_start + ($max_ident/2), $top_y, $percent_start + ($max_ident/2), $y_dist, $black);
  $ps->ps_line($allele_start + ($max_ident/2), $top_y, $allele_start + ($max_ident/2), $y_dist, $black);

  $ps->ps_line($percent_start + $max_ident, $top_y, $percent_start + $max_ident, $y_dist, $black);
  $ps->ps_line($allele_start + $max_ident, $top_y, $allele_start + $max_ident, $y_dist, $black);
 
  $ps->ps_string(6,$allele_start, $top_y+2, "0 Alleles", $black);
  $ps->ps_string(6,$allele_start +($max_ident/2) , $top_y+2, ($max_freq/2), $black);
  $ps->ps_string(6,$allele_start + $max_ident, $top_y+2, $max_freq, $black);

  $ps->ps_string(6,$percent_start, $top_y+2, "100 %", $black);
  $ps->ps_string(6,$percent_start +($max_ident/2) , $top_y+2, "0 %", $black);
  $ps->ps_string(6,$percent_start + $max_ident, $top_y+2, "100 %", $black);

  # put a scale on the lines
  
  my $y_tick = $top_y;

  my $tick_length = 7;
  my $counter = 0;

 

  for ($y_tick = $top_y, $counter = 0; $y_tick >= $y_dist; $y_tick -= $inc *  $SCALE_LEGEND{$DOC{map}{type}}, $counter++) {
    $ps->ps_line($allele_start, $y_tick, $allele_start - $tick_length, $y_tick, $black);
    $ps->ps_line($percent_start, $y_tick, $percent_start - $tick_length, $y_tick, $black);

    

	warn "Maptype: $DOC{map}{type}\n";

    my $label = $DOC{map}{start_distance} + ($counter * $SCALE_LEGEND{$DOC{map}{type}} );

    $ps->ps_string(6,$allele_start - $tick_length-20, $y_tick, $label, $black);
    $ps->ps_string(6,$percent_start - $tick_length-20, $y_tick, $label, $black);

  }

  # add in the footer information with the allele color codes, etc.
  &print_footer("data",$x_min);

} # end of print_idiograms()









##########################################################
##########################################################
#
#               SORTING SUBROUTINES
#
##########################################################
##########################################################       

#############
#
# by_percentage - sorts the selected strain array based on the identity percentage.
#
#############

sub by_percentage {
  $identity{$DOC{primary_strain}{name}}{$b} <=> $identity{$DOC{primary_strain}{name}}{$a};
}


#############
#
# by_homology - sorts the selected strain array based on the homology score.
#
#############

sub by_homology {
  $homology{$DOC{primary_strain}{name}}{$b} <=> $homology{$DOC{primary_strain}{name}}{$a};
}


#############
#
# by_distance - sort markers by their distance along the map
#
############

sub by_distance {
  $MARKERS{$a}{dist} <=> $MARKERS{$b}{dist};
}


#############
#
# by_order - sorts the selected markers by order
#
#############

sub by_order {
  $MARKERS{$a}{order} <=> $MARKERS{b}{order};
}


##########################################################
##########################################################
#
#               CALCULATING SUBROUTINES
#
##########################################################
##########################################################    


#############
#
# calculate_stats - Analyse the marker data before display to get % numbers, etc.
#
#############

sub calculate_stats {

  &debug("Calculate Stats called\n");

  my %str_identity = ();

  # select all the marker elements in the document
  my $marker_nodes = $doc->getElementsByTagName("marker");
  my $m = $marker_nodes->getLength;
  
  $DOC{map}{start_distance} = 50000; # Very large number!
  $DOC{map}{end_distance} = 0; # very small number
  

 NODE1:
  for (my $i = 0; $i < $m; $i++) { # foreach marker node
    my $node = $marker_nodes->item($i);
    
    my $lod = $node->getElementsByTagName("lod")->item(0)->getFirstChild->getData;

    # Only print markers which have allele size data
    if($node->getElementsByTagName("no_acp_data")->getLength) {
      next NODE1; # has no ACP data, ignore it
    }
    elsif( ($lod != 0) && ($lod < $DOC{lod_threshold}{value}) )  {
      next NODE1; # LOD score too low
    }
    else {

      # increment the count of number of markers
      $identity{"total_num_markers"}++;

     &debug("Next Marker $identity{total_num_markers}\n");
     
      
      my $marker_name = $node->getElementsByTagName("name")->item(0)->getFirstChild->getData;
      my $distance = $node->getElementsByTagName("abs_distance")->item(0)->getFirstChild->getData;
      my $f_or_p = $node->getElementsByTagName("f_or_p")->item(0)->getFirstChild->getData;
 
      $identity{$marker_name}{primary_strain} = 0; # initialize the values
      $identity{$marker_name}{secondary_strain} = 0;

      $MARKERS{$marker_name}{lod} = $lod;
      $MARKERS{$marker_name}{dist} = $distance;
      $MARKERS{$marker_name}{f_or_p} = $f_or_p || 'p';


      # Keep track of the start and finish distances on the map

      if($distance < $DOC{map}{start_distance}) {
	$DOC{map}{start_distance} = $distance;
      }
      elsif ($distance > $DOC{map}{end_distance} ) {
	$DOC{map}{end_distance} = $distance;
      }


      # go through each marker's ACP data and compare the size to the 
      # primary and secondary strains' values to come up with a crude
      # percentage identity score
      # taking into account the bp_range of course $DOC{bp_range}{value}

      my $allele_size_list = $node->getElementsByTagName("allele_size");
      my $allele_count = 0;
    
      my %sizes = ();

      # go through each allele size and sum up the data
    ALLELE_LOOP:
      for ($allele_count = 0; $allele_count < $allele_size_list->getLength; $allele_count++) {
      
     
	my $allele_node = $allele_size_list->item($allele_count);
	my $str_name = $allele_node->getAttribute("strain");
	my $size = $allele_node->getFirstChild->getData;

	# need to ignore values which arent from the strains of interest
	if(!defined $DOC{inc_strain}{$str_name}) {
	  next ALLELE_LOOP;
	}
	
	# store the marker's allele size, keyed by strain name
	$MARKERS{$marker_name}{$str_name} = $size;

	# if this strain name is the primary strain increase the count of markers with 
	# primary and secondary datapoints

	$identity{$str_name}{total_markers}++;

	if($str_name eq $DOC{primary_strain}{name}) {
	  $identity{total_primary_markers}++;
	}
	elsif($str_name eq $DOC{secondary_strain}{name}) {
	  $identity{total_secondary_markers}++
	}

	$sizes{$str_name} = $size;

	&debug("$str_name: $size\n");
      }

      my $name = "";
      my $bp_range = $DOC{bp_range}{value};
      
      # iterate through strains, checking each against each other
      my $s = 0;
      
      # for each selected strain, get the allele size
      &debug("Strain loop\n");
    STRAIN1:
      for ($s = 0; $s <= $#selected_strains; $s++) {
	
	if(!defined $sizes{$selected_strains[$s]} ) {
	  next STRAIN1;
	}
	
	# if this strain's data is the same as the primary strains data
	# increase this marker's identity score for primary
	if (defined $sizes{$DOC{primary_strain}{name}} ) {
	  if( abs($sizes{$selected_strains[$s]} - $sizes{$DOC{primary_strain}{name}}) <= $bp_range ) {
	    $identity{$marker_name}{primary_strain}++;
	  }
	}
	else {
	  $identity{$marker_name}{primary_strain} = 0;
	}
	# if we have a secondary strain size for this marker, check that too.
	if (defined $sizes{$DOC{secondary_strain}{name}} ) {
	  if( abs($sizes{$selected_strains[$s]} - $sizes{$DOC{secondary_strain}{name}}) <= $bp_range ) {
	    $identity{$marker_name}{secondary_strain}++;
	  }
	}
	else {
	  $identity{$marker_name}{secondary_strain} = 0;
	}
	
	# and compare it to every other selected strain
	my $t = 0;
      STRAIN2:
	for($t = 0; $t <= $#selected_strains; $t++) {
	  
	  if(!defined $sizes{$selected_strains[$t]} ) {

	    # to ensure this gets defined at some point or other.
	    if(!defined $str_identity{$selected_strains[$s]}{$selected_strains[$t]}) {
	      $str_identity{$selected_strains[$s]}{$selected_strains[$t]} = 0;
	    }

	    next STRAIN2;
	  }	  
	  if( abs($sizes{$selected_strains[$s]} - $sizes{$selected_strains[$t] }) <= $bp_range ) {	    
	    $str_identity{$selected_strains[$s]}{$selected_strains[$t]}++;
	  }
	}
      }
      #}
      
    }
    
  }

  # should have all the identity scores in %identity at this point
  # convert to percentages

  my $nom = "";

  foreach $nom (keys %str_identity) {
    
    my $n2 = "";
    foreach $n2 (keys %str_identity) {
      # $identity{$nom}{$n2} = int($str_identity{$nom}{$n2}/$identity{$n2}{total_markers}*100) || 0;
    
    }
  }
  
  # now for a check, lets print this stuff out!
  my $g = 0;
  for ($g = 0; $g <= $#selected_strains; $g++) {
    #print "$selected_strains[$g]:";

    my $k = 0;
    for ($k = 0; $k <= $#selected_strains; $k++) {

      if( (defined $str_identity{$selected_strains[$g]}{$selected_strains[$k]}) && (defined $identity{$selected_strains[$k]}{total_markers}) ) {
	$identity{$selected_strains[$g]}{$selected_strains[$k]} = (int( $str_identity{$selected_strains[$g]}{$selected_strains[$k]}/$identity{$selected_strains[$k]}{total_markers}*100)) || 0;
      }
      else {
	$identity{$selected_strains[$g]}{$selected_strains[$k]} = 0;
      }
    }
    
    #print "\n";
    
  }

  # exit;

} # end of calculate stats


#############
#
# calculate_homology
#
############

sub calculate_homology {

  &debug("Calculating Homology\n");

  # First divide the genetic map into bins
  # the for each strain vs each other, go through each bin
  # and calculate the homology in that bin, add the bin score
  # to the total strain v strain homology score to get the final values...

  # only the markers with data and with LOD > threshold are in %MARKERS
  my $m = "";
  my $bin_counter = 0;
  my $bin_start = 0;
  my $bin_end = 0;
  my $first_marker = 1;
  my $next_bin_start = 0;

  foreach $m (sort by_distance keys %MARKERS) {

    # for the very first time around, initialize the start and end distances
    # relative to the first distance on the map

    # first bin is half a bin plus a whole bin to ensure top is counted
    # twice, as other areas of the chromosome are.
    if($first_marker) {
      $bin_start = $MARKERS{$m}{dist};
      $next_bin_start = $bin_start; # + $DOC{homology}{slide_inc};
      $bin_end = $bin_start + $DOC{homology}{slide_inc};
      $first_marker = 0;
    }

    # if this would be in the next bin, add it to the next bin's list
    if($MARKERS{$m}{dist} >= $next_bin_start) {
      push @{ $BINS[$bin_counter+1] }, "$m";
      &debug( "\t also in $bin_counter+1 $m $MARKERS{$m}{dist} \n");
    }

    if($MARKERS{$m}{dist} >= $bin_end) {
      $bin_counter++; # increment bin counter

      # if this marker is outside of this bin, and the next one ($bin_start + $slide_inc =  end of next bin),
      # start the next bin at this marker
      if( $MARKERS{$m}{dist} >= $bin_end  + $DOC{homology}{slide_inc}) {
	$bin_start = $MARKERS{$m}{dist}
      }
      else {
	$bin_start = $next_bin_start;
      }
      $bin_end =  $bin_start + $DOC{homology}{window_size};
      $next_bin_start = $bin_start + $DOC{homology}{slide_inc};
    }

    # add this marker name to the list for this bin
    push @{ $BINS[$bin_counter] }, "$m";

    &debug( "Bin $bin_counter $m $MARKERS{$m}{dist} \n");

  }

  # Now have the markers parcelled off into bins,
  # compare each strain's allele size vs each others for each bin
  # and calculate a grand homology score... :)

  my $s1 = 0;

 STRAIN_1:
  for ($s1 = 0; $s1 <= $#ACP_STRAINS; $s1++) {

    # &debug("$ACP_STRAINS[$s1]:\n");

    my $s2 = 0;
  STRAIN_2:
    for ($s2 =0; $s2 <= $#ACP_STRAINS; $s2++) {

      # &debug( "\t$ACP_STRAINS[$s2]:\n");

      # go round each bin comparing the strain sizes
      my $bin = 0;
    BINS:
      for ($bin = 0; $bin <= $#BINS; $bin++) {

	# &debug("Bin $bin of $#BINS has $#{$BINS[$bin]} markers \n");

	# initialise this array first.
	if(!defined $homology{$ACP_STRAINS[$s1]}{$ACP_STRAINS[$s2]}) {
	  $homology{$ACP_STRAINS[$s1]}{$ACP_STRAINS[$s2]} = "0.00001";
	}
	if(!defined $max_percent{$ACP_STRAINS[$s1]}{$ACP_STRAINS[$s2]}) {
	  $max_percent{$ACP_STRAINS[$s1]}{$ACP_STRAINS[$s2]} = "0.00001";
	}

	# base marker score = 1/number of markers in bin
	my $score = 1/ ($#{ $BINS[$bin] } +1);

	# now for each marker in the bin, check the two sizes
	my $bin_marker = 0;
      BIN_MARKER:
	for ($bin_marker = 0; $bin_marker <= $#{ $BINS[$bin] }; $bin_marker++) {

	  my $m_lod = 4;

	  if( $MARKERS{ $BINS[$bin][$bin_marker] }{lod} > 0) {
	    $m_lod = $MARKERS{ $BINS[$bin][$bin_marker] }{lod};
	  }
	  else {
	    if( $MARKERS{ $BINS[$bin][$bin_marker] }{f_or_p} =~ /p/i) {
	      $m_lod = 3;
	    }
	  }

	  # if the 1st strain has no data for this marker, ignore it
	  if(!defined $MARKERS{ $BINS[$bin][$bin_marker] }{$ACP_STRAINS[$s1]} ) {
	    next BIN_MARKER;
	  }
	  
	  # keep track of the maximum possible score for each strain comparison
	  # by putting this tally here we assume 100% will be when strain 2 has data for all of strain 1's markers
	  # if strain 2 is missing some of strain 1's markers, that will lower the max percentage technically achievable.
	  $max_percent{$ACP_STRAINS[$s1]}{$ACP_STRAINS[$s2]} += int( 100* ($score * $m_lod) );


	  # if the 2nd strain has no data for this marker, ignore it
	  if(!defined $MARKERS{ $BINS[$bin][$bin_marker] }{$ACP_STRAINS[$s2]} ) {
	    next BIN_MARKER;
	  }

	  # both have values, so compare them
	  if ( abs($MARKERS{ $BINS[$bin][$bin_marker] }{$ACP_STRAINS[$s1]} - $MARKERS{ $BINS[$bin][$bin_marker] }{$ACP_STRAINS[$s2]}) <= $DOC{bp_range}{value} ) {

	    # Basic score = $score * marker_lod
	   $homology{$ACP_STRAINS[$s1]}{$ACP_STRAINS[$s2]}  += int( 100* ($score * $m_lod) );
	  }

	} # end of bin marker loop

      } # end of inner bin loop

    } # $s2 inner loop

  } # $s1 outer loop

}






##########################################################
##########################################################
#
#               PRINTING STATS & PARAMETER SUBROUTINES
#
##########################################################
##########################################################    

#############
#
# print_stats - Output of the statistical analysis of the data
#
#############

sub print_stats {

  my ($y,$format) = @_; # the initial y coordinate - where to start from

  # Print percentages, number of alleles, number of markers, etc, etc.
  # put in a line and a heading
  $ps->ps_set_linewidth(2);
  $ps->ps_line(36,$y,350,$y);
  if($format eq "NUMBER") {
    $ps->ps_string(12,36,($y-15),"Strain % Identities over displayed region");
  }
  else {
    $ps->ps_string(12,36,($y-15),"% Identity chromogram over displayed region");
  }
  
  if($DOC{flank1}{distance}) {
    $ps->ps_rstring(12,3,0,"[from $DOC{flank1}{distance}");
  }
  else {
    $ps->ps_rstring(12,3,0,"[from 0.0");
  }
  if($DOC{flank2}{distance}) {
    $ps->ps_rstring(12,3,0,"to $DOC{flank2}{distance}]");
  }
  else {
    $ps->ps_rstring(12,3,0,"to the end]");
  }
  
  $ps->ps_set_linewidth(1);
  $ps->ps_line(36,$y-21,350,$y-21);
  
  my $table_top_y = $y-60;
  my $line_inc = 5;

  my $fs = (0.7 * $line_inc);

  my $half_num_strains = int($#ACP_STRAINS/2);
  my $cc = 0;
  my $row_count = 0;

  my $col1 = 36;
  my $tab =  $line_inc;
  my $col2 = $col1+30;
  
  $ps->ps_string($fs,36,36," "); # dummy string to reset the font size - kludge!
  # print the strain names on top
  for ($cc = 0; $cc <= $#ACP_STRAINS; $cc++) {
    $ps->ps_gsave;
    $ps->ps_translate($col2+($cc * $tab)+($tab/2),$table_top_y+5);
    $ps->ps_ori_rotate(45);
    
    # print the strain names in the appropriate colors
    if($ACP_STRAINS[$cc] eq $DOC{primary_strain}{name}) {
     $ps->ps_string($fs,0,0,"$ACP_STRAINS[$cc]",$color{$DOC{primary_strain}{color}});      
    }
    elsif ($ACP_STRAINS[$cc] eq $DOC{secondary_strain}{name}) {
     $ps->ps_string($fs,0,0,"$ACP_STRAINS[$cc]",$color{$DOC{secondary_strain}{color}});     
    }
    else {
      $ps->ps_string($fs,0,0,"$ACP_STRAINS[$cc]",$black );
    }
    $ps->ps_grestore; 
  }

  $ps->ps_set_font_size($fs);

  my $c = 0;
  
 STRAIN_LOOP:
  for ($c = 0; $c <= $#ACP_STRAINS; $c++) {
    # print the strain names in the appropriate colors
    
    if($ACP_STRAINS[$c] eq $DOC{primary_strain}{name}) {
      $ps->ps_string($fs,$col1,$table_top_y,"$ACP_STRAINS[$c]",$color{$DOC{primary_strain}{color}});      
    }
    elsif ($ACP_STRAINS[$c] eq $DOC{secondary_strain}{name}) {
      $ps->ps_string($fs,$col1,$table_top_y,"$ACP_STRAINS[$c]",$color{$DOC{secondary_strain}{color}});     
    }
    else {
      $ps->ps_string($fs,$col1,$table_top_y,"$ACP_STRAINS[$c]",$black);
    }
    
    my $d = 0;
    my $start_flag = 0; # only gets set to 1 when we've passed the 100% value so we only print top half of table


  DATA_LOOP:
    for ($d = 0; $d <= $#ACP_STRAINS; $d++) {
      
    
     my $c_x = 2; # the offset to center the circles
      
     if($identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} >= 100) {
       $fs = 0.5 * $line_inc;
      }
     else {
       $fs = 0.7 * $line_inc;
     }

     if( $format eq "COLOR" ) {
       
       my $cula = $id_f[1];
       
       # had to reverse the order here to get the same values as the top half of
       # the table $ACP_STRAINS[$d]}{$ACP_STRAINS[$c] instead of $ACP_STRAINS[$c]}{$ACP_STRAINS[$d]

       if($identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} >= 80) {
	 $cula = $id_f[5];
       }
       elsif ($identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} >= 60){
	 $cula = $id_f[4];
       }
       elsif ($identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} >= 40){
	 $cula = $id_f[3];
       }
	elsif ($identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} >= 20){
	  $cula = $id_f[2];
	}
       
       
       $ps->ps_rectangle($col2+($d * $tab)-1,$table_top_y-1, $col2+($d * $tab)+$tab-1,$table_top_y+$tab-1, $cula,$white);
       # debug with the text values
       # $ps->ps_string($fs,$col2+($d * $tab),$table_top_y,"$identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]}",$white);
       next DATA_LOOP;
     }
     
     
     my $col = $black;
   
     if($color_numbers) {
        $ps->ps_string($fs,$col2+($d * $tab),$table_top_y,"$identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} ",$col);
     }
     else {
        $ps->ps_string($fs,$col2+($d * $tab),$table_top_y,"$identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]}",$black);
      }
     
    }
    
    $table_top_y -= $line_inc;
    $row_count++;
  }

  # if($format eq "NUMBER") {
# 
#     # order strains by identity to Primary Strain
#     my @tmp_identity_rank = sort by_percentage @ACP_STRAINS;
#     
#     my %identity_rank_hash = ();
#     
#     my $i = 0;
#     
#     for ($i = 0; $i <= $#tmp_identity_rank; $i++) {
#       $identity_rank_hash{$tmp_identity_rank[$i]} = $i;
#     }
#     
#     my $stats = "$DOC{chromosome}{number},$DOC{lod_threshold}{value},$DOC{homology}{window_size},$DOC{homology}{slide_inc}";
#     my $rank_string =  "$DOC{primary_strain}{name} identity rank: ";
#     my $score_string = "$DOC{primary_strain}{name} identity score: ";
#     
#     for ($i = 0; $i <= $#ACP_STRAINS; $i++) {
#       $rank_string .= ($identity_rank_hash{$ACP_STRAINS[$i]}+1) . ", ";
#       $score_string .= $identity{$DOC{primary_strain}{name}}{$ACP_STRAINS[$i]} . ", ";
#     }
#     
#     
#     $ps->ps_string($fs,36,$table_top_y-(2*$line_inc),"$stats,$rank_string",$black);
#     $ps->ps_string($fs,36,$table_top_y-(3*$line_inc),"$stats,$score_string",$black);
#   }
  
  return $table_top_y - (5*$line_inc);

}




#############
#
# print_homology - Output of the homolgy analysis of the data
#
#############

sub print_homology { # print_homology

  my ($y,$format) = @_; # the initial y coordinate - where to start from

  # Print percentages, number of alleles, number of markers, etc, etc.
  # put in a line and a heading
  $ps->ps_set_linewidth(2);
  $ps->ps_line(36,$y,350,$y);
  if($format eq "NUMBER") {
    $ps->ps_string(12,36,($y-15),"Strain Homology Scores over displayed region");
  }
  else {
     $ps->ps_string(12,36,($y-15),"Homology chromogram over displayed region");
   }
  if($DOC{flank1}{distance}) {
    $ps->ps_rstring(12,3,0,"[from $DOC{flank1}{distance}");
  }
  else {
    $ps->ps_rstring(12,3,0,"[from 0.0");
  }
  if($DOC{flank2}{distance}) {
    $ps->ps_rstring(12,3,0,"to $DOC{flank2}{distance}]");
  }
  else {
     $ps->ps_rstring(12,3,0,"to the end]");
   }
    
  $ps->ps_set_linewidth(1);
  $ps->ps_line(36,$y-21,350,$y-21);
  
  my $table_top_y = $y-60;
  my $line_inc = 5;
  
  my $fs = (0.7 * $line_inc);

  my $half_num_strains = int($#ACP_STRAINS/2);
  my $cc = 0;
  my $row_count = 0;

  my $col1 = 36;
  my $tab =  $line_inc;
  my $col2 = $col1+30;
    
  $ps->ps_string($fs,36,36," "); # dummy string to reset the font size - kludge!

  # print the strain names on top
  for ($cc = 0; $cc <= $#ACP_STRAINS; $cc++) {
    $ps->ps_gsave;
    $ps->ps_translate($col2+($cc * $tab)+($tab/2),$table_top_y+5);
    $ps->ps_ori_rotate(45);
    
    # print the strain names in the appropriate colors
    if($ACP_STRAINS[$cc] eq $DOC{primary_strain}{name}) {
     $ps->ps_string($fs,0,0,"$ACP_STRAINS[$cc]",$color{$DOC{primary_strain}{color}});      
    }
    elsif ($ACP_STRAINS[$cc] eq $DOC{secondary_strain}{name}) {
     $ps->ps_string($fs,0,0,"$ACP_STRAINS[$cc]",$color{$DOC{secondary_strain}{color}});     
    }
    else {
      $ps->ps_string($fs,0,0,"$ACP_STRAINS[$cc]",$black );
    }
    $ps->ps_grestore; 
  }

  $ps->ps_set_font_size($fs);

  my $c = 0;
  
 STRAIN_LOOP:
  for ($c = 0; $c <= $#ACP_STRAINS; $c++) {
    # print the strain names in the appropriate colors
    
    # warn "STRAIN_LOOP: $ACP_STRAINS[$c]\n";

    if($ACP_STRAINS[$c] eq $DOC{primary_strain}{name}) {
      $ps->ps_string($fs,$col1,$table_top_y,"$ACP_STRAINS[$c]",$color{$DOC{primary_strain}{color}});      
    }
    elsif ($ACP_STRAINS[$c] eq $DOC{secondary_strain}{name}) {
      $ps->ps_string($fs,$col1,$table_top_y,"$ACP_STRAINS[$c]",$color{$DOC{secondary_strain}{color}});     
    }
    else {
      $ps->ps_string($fs,$col1,$table_top_y,"$ACP_STRAINS[$c]",$black);
    }
    
    my $d = 0;
    my $start_flag = 0; # only gets set to 1 when we've passed the 100% value so we only print top half of table


  DATA_LOOP:
    for ($d = 0; $d <= $#ACP_STRAINS; $d++) {
      
    
     my $c_x = 2; # the offset to center the circles
      
     if($identity{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} >= 100) {
       $fs = 0.5 * $line_inc;
      }
     else {
       $fs = 0.7 * $line_inc;
     }
     
     if( $format eq "COLOR" ) {
       
       my $cula = $id_f[1];
       my $percent  = 0;

       if($DOC{display}{homology_yn} eq "Yes") {
	 $percent = int($homology{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} / $max_percent{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} *100);
       }
       # had to reverse the order here to get the same values as the top half of
       # the table $ACP_STRAINS[$d]}{$ACP_STRAINS[$c] instead of $ACP_STRAINS[$c]}{$ACP_STRAINS[$d]

       if($percent >= 80) {
	 $cula = $id_f[5];
       }
       elsif ($percent >= 60){
	 $cula = $id_f[4];
       }
       elsif ($percent >= 40){
	 $cula = $id_f[3];
       }
	elsif ($percent >= 20){
	  $cula = $id_f[2];
	}
       
       
       $ps->ps_rectangle($col2+($d * $tab)-1,$table_top_y-1, $col2+($d * $tab)+$tab-1,$table_top_y+$tab-1, $cula,$white);
       # debug with the text values
       # $ps->ps_string($fs,$col2+($d * $tab),$table_top_y,"$percent",$whyte);
       next DATA_LOOP;
     }
     
     
     my $col = $black;
     my $percent = 0;

     if($DOC{display}{homology_yn} eq "Yes") {
       $percent = int($homology{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} / $max_percent{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]} *100);

       if($percent > 100) {
	 $percent = "$homology{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]}:$max_percent{$ACP_STRAINS[$c]}{$ACP_STRAINS[$d]}";
       }
     }

     if($color_numbers) {
        $ps->ps_string($fs,$col2+($d * $tab),$table_top_y,"$percent",$col);

     }
     else {
        $ps->ps_string($fs,$col2+($d * $tab),$table_top_y,"$percent",$black);
      }
     
    }
    
    $table_top_y -= $line_inc;
    $row_count++;
  }
  # if($format eq "NUMBER") {
#     # order strains by homology to Primary Strain
#     my @tmp_homology_rank = sort by_homology @ACP_STRAINS;
#     
#     my %homology_rank_hash = ();
#     
#     my $i = 0;
#     
#     for ($i = 0; $i <= $#tmp_homology_rank; $i++) {
#       $homology_rank_hash{$tmp_homology_rank[$i]} = $i;
#     }
#     
#     my $stats = "$DOC{chromosome}{number},$DOC{lod_threshold}{value},$DOC{homology}{window_size},$DOC{homology}{slide_inc}";
#     
#     my $rank_string = "$DOC{homology}{window_size}"."_$DOC{homology}{slide_inc}"."_rank,";
#     my $score_string = "$DOC{homology}{window_size}"."_$DOC{homology}{slide_inc}". "_score,";
#     
#     for ($i = 0; $i <= $#ACP_STRAINS; $i++) {
#       $rank_string .= ($homology_rank_hash{$ACP_STRAINS[$i]}+1) . ", ";
#       my $percent = int($homology{$DOC{primary_strain}{name}}{$ACP_STRAINS[$i]} / $max_percent{$DOC{primary_strain}{name}}{$ACP_STRAINS[$i]} *100);
#       
#       $score_string .=  $percent . ", ";
#     }
#     
#   
#     $ps->ps_string($fs,36,$table_top_y-(2*$line_inc),"$stats,$rank_string",$black);
#     $ps->ps_string($fs,36,$table_top_y-(3*$line_inc),"$stats,$score_string",$black);
#   }

   return $table_top_y - (5*$line_inc);
  
}



#############
#
# print_parameters - Output of the selected parameters from the web form, contained in the 
# <parameter> element of the XML document
#
#############

sub print_parameters {

  my $y = shift(@_); # the initial x coordinate - where to start from

  # put in a line and a heading
  $ps->ps_set_linewidth(2);
  $ps->ps_line(36,$y,350,$y);
  $ps->ps_string(12,36,($y-15),"Parameter Data");
  $ps->ps_set_linewidth(1);
  $ps->ps_line(36,$y-21,350,$y-21);

  my $table_top_y = $y-40;
  my $line_inc = 10;

  my $param_node = $doc->getElementsByTagName("parameters");

  my $param_count = 0;
  my $total_parameters = $param_node->getLength;

  # print "Total # parameters = $total_parameters \n";

  my @parameters = (
		    "chromosome:number",
		    "map:type",
		    "map:name",
		    "flank1:distance",
		    "flank2:distance",
		    "primary_strain:name",
		    "secondary_strain:name",
		    "lod_threshold:value",
		    "bp_range:value",
		    "display:table_yn",
		    "display:data_yn",
		    "display:font_size",
		    "display:homology_yn",
		    "display:order",
		    "display:color_scheme",
		    "homology:window_size",
		    "homology:slide_inc",
		    );

  


  for($param_count = 0; $param_count <= $#parameters; $param_count++) {

    my ($tag,$attribute) = split /:/,$parameters[$param_count];

    my $p_node = $doc->getElementsByTagName($tag);

    if(defined $p_node->item(0)) {
      my $p_att = $p_node->item(0)->getAttribute($attribute);
      
      if($attribute =~ /_yn$/) {
	if( $p_att eq "1") {
	  $p_att = "Yes";
	}
	else {
	  $p_att = "No";
	}
      }
      
      # store this data in the DOC hash for later
      $DOC{$tag}{$attribute} = $p_att;
      
      $ps->ps_string(10,36,$table_top_y,"$tag");
      $ps->ps_string(10,160,$table_top_y,"$attribute = $p_att");
      
      $table_top_y -= $line_inc;
    }
  }
  $ps->ps_line(36,$table_top_y-5,350,$table_top_y-5);

  # return the last position of the x coordinate
  return $table_top_y-5;
}









#############
#
# Simple test routing to convert the XML node to a printable version
#
#############

sub XML_toString {

  my ($me,$node) = @_;
  
  return $node->toString;
  # return 1;

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


# Have to return 1 at the end of the module
1;

__END__

 
	#########################
	if (defined $sizes{$DOC{primary_strain}{name} } ) {
	  
	  if( abs($sizes{$name} - $sizes{$DOC{primary_strain}{name} }) <= $bp_range ) {
	    $identity{$marker_name}{primary_strain}++;
	    $str_identity{$name}{primary_strain}++;
	  }
	}

	# if we have a defined secondary strain, then increment the 2ndary strain identity score too
	if (defined $sizes{$DOC{secondary_strain}{name}} ) {
	  
	  if( abs($sizes{$name} - $sizes{$DOC{secondary_strain}{name} }) <= $bp_range ) {
	    $str_identity{$name}{secondary_strain}++;
	    $identity{$marker_name}{secondary_strain}++;
	  }
	}



  # print "Setting $nom primary % to $identity{$nom}{primary_strain} \n";
      
      # if we are checking secondary strain data also, calculate % here
      #if($DOC{secondary_strain}{name} !~ /off/i) {
#	$identity{$nom}{$n2} = int($str_identity{$nom}{secondary_strain}/$identity{total_secondary_markers}*100);
      #}
      #else {
#	$identity{$nom}{secondary_strain} = 0;
      #}
