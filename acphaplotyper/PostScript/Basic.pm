
#########################
#
# PS.pm - A perl 5 module to simplify the creation of postscript
#         output from perl script.
#
# (c) Simon Twigger, Medical College of Wisconsin, 1999,2000
#     simont@mcw.edu
#
#########################





#########################
#
#   Notes
#
#########################
#  
# June 1999
# cschmitz: changed most of the variables from global variables to member variables
# cschmitz: disabled _check*; otherwise two successive calls to ps_string with the
#           same font size would produce outputs with different font sizes
#	    Christoph Schmitz <cschmitz@castor.uni-trier.de>
#
# Dec 1999
# simont:   Moved over to Christoph's version w. member variables
#           Added in add_page function
#           Fixed set_neg_y bug in ps_bezier that existed in v0.3
# 
# Dec 1999
# simont:   Added in translate and scale to add_page subroutine as suggested
#           by Fabio D'Alessi <cars@civ.bio.unipd.it>
#           Added \n to the ps_scale function postscript code.
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


package PostScript::Basic;

require 5.003;
require Exporter;

use strict;			# to keep me honest
use Carp;			# to make error reporting a bit easier
use vars qw($VERSION @ISA);

$VERSION = "0.4";
@ISA = qw(Exporter);

@SUBCLASS::ISA = qw(Basic);

my %JUSTIFY_CMDS = (
		    'left' => 'show',
		    'right' => 'right_show',
		    'center' => 'center_show',
		    'rightl' => 'right_list_show',
		   );

# width in points, of standard page sizes
my %PAGE_WIDTH = (
		  'letter' => 612,
		  'legal'  => 612,
		  'a4'     => 595,
		 );

# height in points, of standard page sizes
my %PAGE_HEIGHT = (
		   'letter' => 792,
		   'legal'  => 1008,
		   'a4'     => 841,
		  );

#############
#
# The constructor method
#
#############

sub new {
    my $class = shift;
    my $me = {
	      CURRENT_FONT          => "Helvetica",
	      CURRENT_COLOR         => "Black",
	      CURRENTSIZE           => 12,
	      CURRENT_LINE_WIDTH    => 1,
	      CURRENT_LINECAP       => 0, # default to butt cap
	      CURRENT_LINEJOIN      => 0, # default to mitered
	      CURRENT_DASH          => [],
	      CURRENT_USERPATH_ID   => 0,
	      CURRENT_COL_ID        => 0,
	      CURRENT_ORI_ROTATION  => 0,
	      SHOW_CONTROL_POINTS   => 0, # show bezier control handles for debugging
	      DEFINITIONS           => "",
	      DEFINED_COLORS        => {},
	      HEADER                => "",
	      SCALE                 => "1 1 scale",
	      TRANSLATE             => "0 0 translate",
	      PAPER_SIZE            => "letter", # default to US letter paper size
	      TEXT_JUSTIFICATION    => "left", # default to lefthand justified text
	      NEG_X                 => "", # set to 'neg' to invert all x values 
	      NEG_Y                 => "", # set to 'neg' to invert all y values
	      PS                    => "", # will hold the growing postscript text
	      TIME                  => scalar localtime(),
	      PAGES                 => 1,
	     };
    
    bless $me, $class;
    
    return $me;
}






##############
#
# General Public Accessor functions
#
##############

# define a color - put into $me->{DEFINITIONS} so that all definitions are at the top of the page.
sub ps_def_color {
    
    my($me,$col,$r,$g,$b) = @_;
    
    if($r > 1 || $g > 1 || $b > 1) {
	carp "RGB values must be between 0 and 1\n";
    }
    
    $me->{CURRENT_COL_ID}++;
    my $color = "color_$me->{CURRENT_COL_ID}";
    # %DEFINED_COLORS{"
    
    
    my @tmp = split /,/,"$r,$g,$b";
    
    $me->{DEFINED_COLORS}->{$color} = [ @tmp ];
    
    $me->{DEFINITIONS} .= "/$color \{ $r $g $b \} def \n";
    
    return $color;
    
}


# method added for future use and compatability with GD.pm
# accepts colors in range 0-1 or 0-255, converts 0-255 into 0-1 for use in PS documents.

sub ps_colorAllocate {
    
    my($me,$r,$g,$b) = @_;
    
    if($r > 1 || $g > 1 || $b > 1) {
	# assume we have RGB scaled to 255
	$r = $r/255;
	$g = $g/255;
	$b = $b/255;
    }
    
    if($r > 255 || $r < 0 || $g > 255 || $g < 0 || $b > 255 || $b < 0) {
	carp "RGB values must all be between 0 and 255, or between 0 and 1\n";
    }
    
    $me->{CURRENT_COL_ID}++;
    
    my $color = "color_$me->{CURRENT_COL_ID}";
    
    my @tmp = split /,/,"$r,$g,$b";
    
    $me->{DEFINED_COLORS}->{$color} = [ @tmp ];
    
    $me->{DEFINITIONS} .= "/$color \{ $r $g $b \} def \n";
    
    return $color;
    
}


sub ps_define {
    
    my($me,$thing,$param) = @_;
    
    $me->{DEFINITIONS} .= "/$thing $param def \n";
    
    return $thing;
    
}

############
## Get/Set current paper size

sub ps_set_paper_size {
    my ($me,$paper) = @_;
    if($PAGE_WIDTH{$paper}) {
	$me->{PAPER_SIZE} = $paper;
	return ($PAGE_WIDTH{$me->{PAPER_SIZE}},$PAGE_HEIGHT{$me->{PAPER_SIZE}});
    }
    else {
	carp "Invalid paper size $paper\n";
    }
    
}

# return the with and height in points in list context
sub ps_get_paper_size {
    my $me = shift;
    return ($PAGE_WIDTH{$me->{PAPER_SIZE}},$PAGE_HEIGHT{$me->{PAPER_SIZE}});
}



############
## Add a new page to the document

sub ps_add_page {
  my $me = shift;
  $me->{PS} .= "showpage\n";
  $me->{PAGES}++;
  $me->{PS} .= "% -- Page Break --\n";
  $me->{PS} .= "%%Page: $me->{PAGES}\n\n";

  $me->{PS} .= "$me->{TRANSLATE}\n";
  $me->{PS} .= "$me->{SCALE}\n";  

  return $me->{PAGES};
}




############
## Get/Set current font

sub ps_set_font_face {
    my ($me,$font) = @_;
    $me->_check_font($font, $me->{CURRENTSIZE});
    #$me->{PS} .= "\n /Times findfont 12 scalefont setfont \n"; 
}

sub ps_get_font_face {
    my $me = shift;
    return $me->{CURRENT_FONT};
}

############
## Get/Set current font size

sub ps_set_font_size {
    my($me,$size) = @_;
    $me->_check_font($me->{CURRENT_FONT}, $size);
}

sub ps_get_font_size {
    my $me = shift;
    return $me->{CURRENTSIZE};
}

# allow to set both font and size at the same time
sub ps_set_font {
    my($me,$font,$size) = @_;
    $me->_check_font($font, $size);
}

sub ps_get_font {
    my $me = shift;
    return ($me->{CURRENT_FONT},$me->{CURRENTSIZE});
}

############
## Get/Set current font justification

sub ps_set_justify {
    my($me,$just) = @_;
    
    if( ($just eq 'left') || ($just eq 'right') || ($just eq 'center') || ($just eq 'rightl')) {
	$me->{TEXT_JUSTIFICATION} = $just;
    }
    else {
	croak("Text justification can be either left, right or center, not $just.\n");
    }
    
}

sub ps_get_justify {
    my $me = shift;
    return $me->{TEXT_JUSTIFICATION};
}

############
## Get/Set current color

sub ps_set_color {
    my($me, $color) = @_;
    $me->{CURRENT_COLOR} = $color;
}

sub ps_get_color {
    my $me = shift;
    return $me->{CURRENT_COLOR};
}

############
## Get/Set linewidth

sub ps_set_linewidth {
    my($me, $width) = @_;
    if($width > 0) {
	$me->{CURRENT_LINE_WIDTH} = $width;
	$me->{PS} .= "$width setlinewidth\n";
    }
    else {
	carp "Linewidth must be greater than zero!\n";
    }
}

sub ps_get_linewidth {
    my $me = shift;
    return $me->{CURRENT_LINE_WIDTH};
}


############
## Get/Set linejoins - for the end caps of lines
## 0 = mitred join (default)
## 1 = round join
## 2 = beveled join

sub ps_set_linejoin {
    my($me, $join) = @_;
    if($join >= 0 && $join <=2) {
	$me->{CURRENT_LINEJOIN} = $join;
    }
    else {
	carp "Linejoin must be between 0 and 2!\n";
    }
}

sub ps_get_linejoin {
    my $me = shift;
    return $me->{CURRENT_LINEJOIN};
}

############
## Get/Set linecaps - for the end caps of lines
## 0 = butt cap (default)
## 1 = round cap
## 2 = beveled cap

sub ps_set_linecap {
    my($me, $cap) = @_;
    if($cap >= 0 && $cap <=2) {
	$me->{CURRENT_LINECAP} = $cap;
    }
    else {
	carp "Linecap must be between 0 and 2!\n";
    }
}

sub ps_get_linecap {
    my $me = shift;
    return $me->{CURRENT_LINECAP};
}




############
## Get/Set line dash settings


sub ps_set_dash {
    my($me, @dash) = @_;
    
    if($dash[0] == 0) {
	$me->{PS} .= "[] 0 setdash\n";
	@$me->{CURRENT_DASH} = @dash;
    }
    elsif($#dash >= 1) {
	@$me->{CURRENT_DASH} = @dash;
	$me->{PS} .= "[ @dash ] 0 setdash\n";
    }
    else {
	carp "Dashed lines must have at least two values, line length and dash length\n";
    }
}

sub ps_get_dash {
    my $me = shift;
    return @$me->{CURRENT_DASH};
}


sub ps_show_control_points{
    my($me,$state) = @_;
    $me->{SHOW_CONTROL_POINTS} = $state;
}


############
## Get/Set neg_y value

sub ps_set_neg_y {
    my ($me,$neg) = @_;
    if($neg == 1) {
	$me->{NEG_Y} = "neg";	# will reverse sign on all Y values
    }
    elsif ($neg == 0) {
	$me->{NEG_Y} = "";	# will leave y values as entered
    }
    else {
	croak("ps_set_neg_y values can be either 1 or 0, not $neg.\n");
    }
}

sub ps_get_neg_y {
    my $me = shift;
    if($me->{NEG_Y} eq "neg") {
	return 1;		# will reverse sign on all Y values
    }
    else {
	return 0;		# will leave y values as entered
    }
}


###########################################
# PRIVATE FUNCTIONS
###########################################



#########################
# check color detects if the newly specified color is different from
# the current_color. If so, it changes the color, otherwise no change
# is made. This is to reduce unnecessary color change lines in the file

sub _check_color {
    my $me = shift;
    
    my $col = shift(@_);
    
    
    if (!$me->{DEFINED_COLORS}->{$col}) {
	croak ("Color $col not defined in postscript document!\n");
    }
    
    #  if($col ne $me->{CURRENT_COLOR}) {
    $me->{CURRENT_COLOR} = $col;
    
    # change in PS document
    $me->{PS} .= "$col  setrgbcolor \n";
    #  }
}



########################
# check font detects if the newly specified font is different from
# the current_font. If so, it changes the font, otherwise no change
# is made. This is to reduce unnecessary font change lines in the file

sub _check_font {
    
    my($me,$font,$size) = @_;
    
    #  if( ($font ne $me->{CURRENT_FONT}) || ($size != $me->{CURRENTSIZE})) {
    
    $me->{CURRENT_FONT} = $font;
    $me->{CURRENTSIZE} = $size;
    
    # change in PS document
    $me->{PS} .= <<"EOPS";
/$me->{CURRENT_FONT} findfont    % change font face
$me->{CURRENTSIZE} scalefont    % change font size
setfont
EOPS
    
    #  }
    
}








####################################################
####################################################
#
#           PostScript Output functions
#
####################################################
####################################################



############
#
# ps_write is a generic method to enable any thing to be added to the
# postscript file -eg.  more advanced postscript code that goes beyond
# the limited command set presented here.

sub ps_write {
    
    my ($me, $text) = @_;
    
    $me->{PS} .= $text;
    
}


# basic graphics state save commands to allow users to screw around with
# the coordinate space and still get things back to normal later on!

sub ps_gsave {
    my $me = shift;
    $me->{PS} .= "\n gsave \n";
}

sub ps_grestore {
    my $me = shift;
    $me->{PS} .= "\n grestore \n";;
}



#############
#
# start() defines the header information for the postscript file
# this will get appended to the beginning of $me->{PS} when ps_finish()
# is called. Any definitions ( from $me->{DEFINITIONS}) will then be added
# in their correct place, at the start of the postscript file.

sub ps_start {
    my $me = shift;
    
    
    $me->{HEADER} = <<"EOPS";
%!PS-Adobe-3.0
%%BeginProlog

% This ensures that postscript devices such as printers, that do not implement the
% pdfmark operator can use the files containing that operator, the following
% PostScript code makes each marker a no-op if the PostScript interepreter
% processing the file does not implement the pdfmark operator.

/pdfmark where
    {pop} {userdict /pdfmark /cleartomark load put} ifelse

%%EndProlog


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  PostScript output created using PS.pm
%      (c) Simon Twigger, 1998, 1999. 
%  Medical College of Wisconsin, Milwaukee.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% function for center justfied text
    /center_show {
	dup
	stringwidth pop 2 div
        4 -1 roll exch sub
        3 -1 roll moveto
        show
	} def

% function for right hand justified text
    /right_show {
	dup
	stringwidth pop
	4 -1 roll exch sub
        3 -1 roll moveto
        show
	} def

% function for right hand justified lines of text
% prints text rh justified and dx dy relative to current point
% and moves the current point back to the start of the word
% 
    /right_list_show {
	dup            
	stringwidth pop
	    dup        % duplicate str width to use at the end
	    5 1 roll
            4 -1 roll
            exch sub
	    3 -1 roll
	rmoveto        % rmove to dx,dy
        show           % show str
	neg            % change sign on str width
	0 rmoveto      % rmove to new x,0 (move str width points left)
	} def



% set the basic font initially
/$me->{CURRENT_FONT} findfont
$me->{CURRENTSIZE} scalefont
setfont

EOPS
    
    
}


#############
#
# finish() ends the postscript and returns the final text to the calling 
# script.
#
#
#############

sub ps_finish {
    my $me = shift;
    
    #####
    # add in the header, global_translate, global_scale and any definitions
    ####
    
    $me->{PS} = "$me->{HEADER} \n $me->{TRANSLATE} \n $me->{SCALE} \n $me->{DEFINITIONS} \n $me->{PS}";
    
    
    # showpage ensures the postscript appears
    
    $me->{PS} .= "showpage\n";
    
    return $me->{PS};
    
}





###########
#
# TEXT display functions
#
##########


sub ps_string {
    
    my ($me,$font_size,$x,$y,$text,$color) = @_;
    
    # If color specified, change color, otherwise use existing color
    if($color) {
	$me->_check_color($color);
    }
    
    # Normally you would moveto the point, then show the text
    my $cmd = "moveto";
    
    # However, with right and center justification, moveto is done in the
    # subroutine, so remove moveto command
    if( $me->{TEXT_JUSTIFICATION} ne 'left') {
	$cmd = "";
    }
    
    # check to see if font info needs to change
    $me->_check_font($me->{CURRENT_FONT},$font_size);
    
    # use text justification setting to control what text display
    # command to use
    
    $me->{PS} .= <<"EOPS";
$x $y $me->{NEG_Y} $cmd
($text)  $JUSTIFY_CMDS{$me->{TEXT_JUSTIFICATION}}

EOPS
    
}

########################
#
# pdf_link_string()
# 
# Use in PDF documents to make a section of text into a hyperlink
#


sub pdf_link_string {
    
    my ($me,$font_size,$x,$y,$text,$color,$url) = @_;
    
    # If color specified, change color, otherwise use existing color
    if($color) {
	$me->_check_color($color);
    }
    
    # Normally you would moveto the point, then show the text
    my $cmd = "moveto";
    
    # However, with right and center justification, moveto is done in the
    # subroutine, so remove moveto command
    if( $me->{TEXT_JUSTIFICATION} ne 'left') {
	$cmd = "";
    }
    
    my $text_copy = $text;
    
    # my $str_length = $text_copy =~ s/[\s\S]//;
    my $x1 = $x - 1;
    my $y1 = $y + 1;
    my $x2 = $x + ($font_size * length($text))/1.5;
    my $y2 = $y - $font_size -3; # arbitrary length for the moment
    
    
    # check to see if font info needs to change
    $me->_check_font($me->{CURRENT_FONT},$font_size);
    
    # use text justification setting to control what text display
    # command to use
    
    $me->{PS} .= <<"EOPS";
$x  $y $me->{NEG_Y} $cmd
($text)  $JUSTIFY_CMDS{$me->{TEXT_JUSTIFICATION}}

[ /Rect [ $x1 -$y1 $x2 -$y2 ]
/Action << /Subtype /URI /URI ($url) >>
/Border [ 0 0 1 ]
/Color [ 0.7 0 0 ]
/Subtype /Link
/ANN
pdfmark

EOPS
    
}


##############
#
# insert a hyperlink into a PDF document like an HTML imagemap
# Currently only allows you to specify the width of the line, defaults to 0 - no line.
# You should be able to specify the color too but this wasnt working when I tried it using
# ghostscript 5.1 as the PS->PDF tool
#

sub pdf_link {
    
    my ($me,$x1,$y1,$x2,$y2,$url,$width,) = @_;
    
    # define the border as black by default
    my $r = 0;
    my $g = 1;
    my $b = 0;
    
    # border style
    my $bx = 0;			# horizontal corner radius
    my $by = 0;			# vertical corner radius
    my $c = 0;			# width
    
    
    # check we have the minimum set of parameters
    if(!$x1 || !$y1 || !$x2 || !$y2 || !$url) {
	croak "PS::pdf_link requires x1,y1,x2,y2,URL as parameters\n";
    }
    
    if($me->{NEG_Y}) {
	$y1 = -$y1;
	$y2 = -$y2;
    }
    
    
    if($width) {
	$c = $width;
    }
    
    
    
    
    $me->{PS} .= <<"EOPDF";
% insert pdfmark for hyperlink

[ /Rect [ $x1 $y1 $x2 $y2 ]
/Action << /Subtype /URI /URI ($url) >>
/Border [ $bx $by $c ]
/Subtype /Link
/ANN
pdfmark

EOPDF
    
    
}


########################
#
# insert a PDF comment - like a yellow postit note
#


sub pdf_note {
    
    my ($me,$x1,$y1,$x2,$y2,$text,$open) = @_;
    
    # default to close note unless specified as open
    if(!$open) {
	$open = "false";
    }
    else {
	$open = "true";
    }
    
    # check we have the minimum set of parameters
    if(!$x1 || !$y1 || !$x2 || !$y2 || !$text) {
	croak "PS::pdf_link requires x1,y1,x2,y2,text as minimum parameters\n";
    }
    
    # reverse the sign on the y coordinates if applicable
    if($me->{NEG_Y}) {
	$y1 = -$y1;
	$y2 = -$y2;
    }
    
    
    $me->{PS} .= <<"EOPDF";
% insert pdfmark for a note

[ /Rect [ $x1 $y1 $x2 $y2 ]
/Open $open
/Contents ($text)
/ANN
pdfmark

EOPDF
    
    
}


# Relative string - 
# draw string relative to current point

sub ps_rstring {
    
    my ($me,$font_size,$dx,$dy,$text,$color) = @_;
    
    # If color specified, change color, otherwise use existing color
    if($color) {
	$me->_check_color($color);
    }
    
    
    
    # check to see if font info needs to change
    $me->_check_font($me->{CURRENT_FONT},$font_size);
    
    # use text justification setting to control what text display
    # command to use
    
    if($me->{TEXT_JUSTIFICATION} eq 'rightl') {
	$me->{PS} .= <<"EOPS";
$dx $dy
($text) right_list_show

EOPS
    }
else {
    
    $me->{PS} .= <<"EOPS";
$dx $dy rmoveto
($text)  show           % display text

EOPS
}

}


###########
#
# Coordinate functions
#
##########



# Translate moves the origin at the very start of the PostScript drawing routines
# and affects the whole image, not just bits with gsave and grestore
sub ps_global_translate {
    
    my($me, $new_x, $new_y) = @_;
    
    $me->{TRANSLATE} = "$new_x $new_y translate";
    
}


# ps_translate is inserted where its called, and so can be used within gsave and grestore commands
# to manipulate the origin as desired.

sub ps_translate {
    
    my($me, $new_x, $new_y) = @_;
    
    $me->{PS} .= "$new_x $new_y $me->{NEG_Y} translate\n";
    
}

# ori-rotate rotates the origin
sub ps_ori_rotate {
    
    my($me, $degrees) = @_;
    $me->{CURRENT_ORI_ROTATION} += $degrees;
    $me->{PS} .= "$degrees rotate \n";
    
}

# ori_restore restores the origins rotation to normal the origin
sub ps_ori_restore { 
    my $me = shift;
    # invert the current rotation and rotate all the way back to zero.
    $me->{CURRENT_ORI_ROTATION} = -$me->{CURRENT_ORI_ROTATION};
    $me->{PS} .= "$me->{CURRENT_ORI_ROTATION} rotate \n";
    
}


# Translate moves the origin
sub ps_global_scale {
    
    my($me, $x, $y) = @_;
    
    $me->{SCALE} = "$x $y scale";
    
}

sub ps_scale {
    my($me, $x, $y) = @_;
    $me->{PS} .= "$x $y $me->{NEG_Y} scale\n";
    
}

###########
#
# Drawing functions
#
##########




sub ps_line {
    my ($me,$x1,$y1,$x2,$y2,$color) = @_;
    
    # If color specified, change color, otherwise use existing color
    if($color) {
	$me->_check_color($color);
    }
    
    
    $me->{PS} .= <<"EOPS";
% ps_line ($x1,$y1,$x2,$y2,$color)

$x1 $y1 $me->{NEG_Y} moveto       % move to first point of line
$x2 $y2 $me->{NEG_Y} lineto       % line from first to second point
$me->{CURRENT_LINEJOIN} setlinejoin
stroke               % color line
EOPS
}


sub ps_filledCircle {
    
    
    my ($me,$center_x,$center_y,$radius,$color) = @_;
    
    # If color specified, change color, otherwise use existing color
    if($color) {
	$me->_check_color($color);
    }
    
    $me->{PS} .= <<"EOPS";

$center_x $center_y $me->{NEG_Y} moveto

$center_x $center_y $me->{NEG_Y}
$radius 0 360 arc
closepath                % close path automatically
gsave
    $color setrgbcolor fill
grestore
EOPS
    
}

sub ps_arc {
    
    my ($me,$center_x,$center_y,$width,$height,$start_angle,$finish_angle,$fill_color,$stroke_color) = @_;
    
    my $scale_x = 1;
    my $scale_y = 1;
    my $base_length = $width;	# default value
    
    # to make circles or elipses, need to draw a circle scaled appropriately
    # based on the width and height measurements provided.
    
    
    if($width < $height) {
	$base_length = $width;
	$scale_x = 1;
	$scale_y = $height/$width;
    }
    # otherwise either the height is the smallest, or they are equal in length, either
    # way, use height
    else {
	$base_length = $height;
	$scale_y = 1;
	$scale_x = $width/$height;
    }
    
    $me->{PS} .= <<"EOFF";
newpath
gsave
$center_x $center_y $me->{NEG_Y} translate
$scale_x $scale_y scale

0 0 $base_length $start_angle $finish_angle arc
closepath
EOFF
    
    if($fill_color) {
	$me->{PS} .="gsave \n";
	
	# check and setrgbcolor
	$me->_check_color($fill_color);
	
	$me->{PS} .= <<"EOPS";
    fill
grestore

EOPS
    }
    
    if( $stroke_color ) {
	
	# check and setrgb color
	$me->_check_color($stroke_color);
	
	$me->{PS} .= <<"EOPS";

$me->{CURRENT_LINECAP} setlinecap
$me->{CURRENT_LINEJOIN} setlinejoin
$me->{CURRENT_LINE_WIDTH} setlinewidth
stroke

EOPS
    }
    
    $me->{PS} .= "grestore \n";
}


###
#
# This uses the PostScript Level 2 operators ustroke and ufill to stroke and fill
# the user defined path
#
###

sub ps_arc2 {
    
    my ($me,$center_x,$center_y,$width,$height,$start_angle,$finish_angle,$fill_color,$stroke_color) = @_;
    
    my $scale_x = 1;
    my $scale_y = 1;
    my $base_length = $width;	# default value
    
    # to make circles or elipses, need to draw a circle scaled appropriately
    # based on the width and height measurements provided.
    
    
    if($width < $height) {
	$base_length = $width;
	$scale_x = 1;
	$scale_y = $height/$width;
    }
    # otherwise either the height is the smallest, or they are equal in length, either
    # way, use height
    else {
	$base_length = $height;
	$scale_y = 1;
	$scale_x = $width/$height;
    }
    
    
    my $bb_2 = (2*$base_length);
    
    $me->{CURRENT_USERPATH_ID}++; # increase the CURRENT_USERPATH_ID number
    
    $me->{PS} .= <<"EOFF";

$scale_x $scale_y matrix scale      % get a scale matrix
matrix invertmatrix                 % compute inverse transform
/inverse exch def                   % define for later on

gsave

$center_x $center_y $me->{NEG_Y} translate
$scale_x $scale_y scale

/user_path_$me->{CURRENT_USERPATH_ID} {
% define the bounding box for the userpath

-$base_length -$bb_2 $base_length $bb_2 setbbox
0 0 $base_length $start_angle $finish_angle arc
% closepath
} def

EOFF
    
    
    if($fill_color) {
	
	# check and setrgbcolor
	$me->_check_color($fill_color);
	
	$me->{PS} .= <<"EOPS";
/user_path_$me->{CURRENT_USERPATH_ID} load ufill

EOPS
	
    }
    
    if( $stroke_color ) {
	
	# check and setrgbcolor
	$me->_check_color($stroke_color);
	
	$me->{PS} .= <<"EOPS";
    
$me->{CURRENT_LINECAP} setlinecap
$me->{CURRENT_LINEJOIN} setlinejoin
$me->{CURRENT_LINE_WIDTH} setlinewidth

/user_path_$me->{CURRENT_USERPATH_ID} load inverse ustroke

EOPS
    }
    
    $me->{PS} .= "grestore\n";
    $me->{PS} .= "1 1 scale\n";
}


sub ps_bezier {
    
    my ($me,$x0,$y0,$x1,$y1,$x2,$y2,$x3,$y3,$stroke_color) = @_;
    
    # check and setrgbcolor
    $me->_check_color($stroke_color);
    
    $me->{PS} .= <<"EOPS";
newpath
$x0 $y0 $me->{NEG_Y} moveto
$x1 $y1 $me->{NEG_Y} $x2 $y2 $me->{NEG_Y} $x3 $y3 $me->{NEG_Y} curveto
stroke
EOPS
    
    if($me->{SHOW_CONTROL_POINTS}) {
	
	my $temp_linewidth = &ps_get_linewidth();
	
	&ps_set_linewidth($me,1);
	&ps_line($me,$x0,$y0,$x1,$y1,$stroke_color);
	&ps_filledCircle($me,$x1,$y1,1,$stroke_color);
	
	&ps_line($me,$x3,$y3,$x2,$y2,$stroke_color);
	&ps_filledCircle($me,$x2,$y2,1,$stroke_color);
	
	# reset the linewidth
	&ps_set_linewidth($me,$temp_linewidth);
	
    }
    
}



###
# Uses PostScript Level 2 operators, rectstroke and rectfill
###

sub ps_rectangle2 {
    
    my ($me,$x1,$y1,$x2,$y2,$fill_color,$stroke_color) = @_;
    $me->{CURRENT_USERPATH_ID}++; # increase the CURRENT_USERPATH_ID number
    
    my $dx = $x2 - $x1;
    my $dy = $y2 - $y1;
    
    # create a new userpath definition
    $me->{PS} .= <<"EOPS";

/user_path_$me->{CURRENT_USERPATH_ID} {
$x1 $y1 $me->{NEG_Y} 
$dx $dy
} def
EOPS
    
    if($fill_color) {
	
	# check and setrgbcolor
	$me->_check_color($fill_color);
	
	$me->{PS} .= <<"EOPS";
user_path_$me->{CURRENT_USERPATH_ID} rectfill

EOPS
    }
    
    if( $stroke_color ) {
	
	# check and setrgbcolor
	$me->_check_color($stroke_color);
	
	$me->{PS} .= <<"EOPS";

$me->{CURRENT_LINECAP} setlinecap
$me->{CURRENT_LINEJOIN} setlinejoin
$me->{CURRENT_LINE_WIDTH} setlinewidth

user_path_$me->{CURRENT_USERPATH_ID}  rectstroke

EOPS
    }
    
}


# This is the PostScript version 1 friendly rectangle drawing routine
# calls ps_Rectangle to maintain backwards compatability with some
# of my old scripts...
sub ps_filledRectangle { 
    
    my ($me,$x1,$y1,$x2,$y2,$fill_color,$stroke_color) = @_;
    
    &ps_rectangle($me,$x1,$y1,$x2,$y2,$fill_color,$stroke_color);
    
}

# This is the PostScript version 1 friendly rectangle drawing routine
sub ps_rectangle { 
    
    my ($me,$x1,$y1,$x2,$y2,$fill_color,$stroke_color) = @_;
    
    $me->{PS} .= <<"EOPS";
newpath

$x1 $y1 $me->{NEG_Y} moveto       % move to first point of rectangle
$x2 $y1 $me->{NEG_Y} lineto       % line from first to second point
$x2 $y2 $me->{NEG_Y} lineto       % line from 2nd to 3rd
$x1 $y2 $me->{NEG_Y} lineto       % line from 3rd to 4th
closepath                % close path automatically
gsave
EOPS
    
    # check and setrgbcolor
    $me->_check_color($fill_color);
    $me->{PS} .= "fill \n grestore \n";
    
    if( $stroke_color ) {
	
	# check and setrgbcolor
	$me->_check_color($stroke_color);
	
	
	$me->{PS} .= <<"EOPS";
    $me->{CURRENT_LINEJOIN} setlinejoin
    $me->{CURRENT_LINECAP} setlinecap
    $me->{CURRENT_LINE_WIDTH} setlinewidth
    stroke
EOPS
    }
    
}

# I wanted to have the polygon methods ala GD.pm so we'll try writing a method to deal
# with the GD::polygon object first, and maybe rewrite the polygon object if it becomes
# strictly necessary....

sub ps_polygon {
    
    my ($me, $poly,$fill_color,$stroke_color) = @_;
    
    # how many points in the polygon
    my $num_points = $poly->length;
    my ($x0,$y0) = $poly->getPt(0);
    
    
    
    # loop around drawing each point on a path
    # first set up a new path and move to the first point.
  $me->{PS} .= <<"EOPS";
 newpath
 $x0 $y0 moveto
EOPS
  
  for(my $point = 1; $point < $num_points; $point++) {
    
    my ($x,$y) = $poly->getPt($point);
    $me->{PS} .= "$x $y $me->{NEG_Y} lineto \n";
  }
  
  $me->{PS} .= "closepath\n";
  
  if($fill_color) {
    
    $me->{PS} .= "gsave \n";
    
    # check and setrgbcolor
    $me->_check_color($fill_color);
    
    $me->{PS} .= "fill \n grestore ";
  }
  
  if( $stroke_color ) {
    # check and setrgbcolor
    $me->_check_color($stroke_color);
    
    $me->{PS} .= "stroke \n";
  }
  
}



# Have to return 1 at the end of the module
1;

__END__

