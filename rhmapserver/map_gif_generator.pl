#!/usr/bin/perl

#########################################################
#  file name:map_gif_generator.cgi
#  author: JIAN LU
#  date: 4-5-1999
# show   map in gif format
# last modified 2-2-2000
#               5-18-2000 use RGD::HTMP module
########################################################
use lib '/rgd/tools/common';
use RGD::HTML;
use GD;

my $rgd = RGD::HTML->new(); #DP 11-20-03
my $toolPATH=$rgd->get_toolPATH; # /rgd/TOOLS

#######################################################
# parsing values
#######################################################
my $user_id=shift(@ARGV);
my $section=shift(@ARGV);
my $chrom=shift(@ARGV);
my $ver=shift(@ARGV);    ######### passed version

# for rh placement user data
my $user_dir="$toolPATH/rhmapserver/data/user_data/$user_id/$section";
my $user_data="$user_dir/rhdata\.dat";
my $file_txt="$user_dir/result\.txt";
my $file_gif="$user_dir/CHR$chrom\.gif";
# Y scale division
$y_div=10;
# marker interval
$marker_interval=14;

if($user_id){
#from placement file
    &Load_Placement_File;
    &Draw_Map_Image;
}else{
    print "<p>Not found.";
}

###########################################################
# Load_Placement_File
###########################################################
sub Load_Placement_File{
  #get framework version
  ###############################
  #open(FR,"framework_version");
  #$ver=<FR>;
  #close(FR);
  ###############################
  $ver=~ s/\s+//g;
  $version="Framework version v.$ver";
  
  $cross="";
  $map_name="RH Placement Map";
  $map_lod="";
  $map_unit="cR";
  
  my $i=0;
  my $k=0;
  my $index=0;
  
  open(FILE,$file_txt);
  while($line=<FILE>){
    if($line =~ /\cL/){ #match ASII control character like ^L
      $begin="Y";
      $index=0;
    }
    $line=~ /\bPlacement Data Relative to Framework for Chromosome\b\s(\w+)$/;
    $chr=$1;
    if($begin eq "Y"){
      if($chrom ==21){ $chrom="ChrX";}   ########"X";}
      if($index > 4 && $chr eq "$chrom"){
	@map=split(/\s+/,$line);
	$map[0]=~ s/\s+//g;
	$map[1]=~ s/\s+//g;
	$map[2]=~ s/\W//g;
	$map[2]=~ s/\d//g;
	$dname[$i]=$map[0];
	$relative_position[$i]=$map[1];
	$f_or_p[$i]=$map[2];
		$i++;
      }
      $index++;
    }
  }
  close(FILE);
  
  $count_mk=@dname;
  
  $marker_height=$count_mk * $marker_interval;
  $bar_height=$marker_height * 3/4;
  
  $i=0;
  
  my $first_pos=0; 
  my $next_pos=0;
  foreach $_ (@relative_position){
    if(!$i){
      push (@position,$first_pos);
    }else{
      push (@position,$next_pos);
    }
    $next_pos += $relative_position[$i];
    $i++;
  }
  #if($next_pos != 0){  #######
  $max_position=$next_pos;
  #}else{       ###############
  #   $max_position=1; ########
  #}###########################
  pop(@relative_position); #remove the last value of array
  use integer;
  $bar_rate=$bar_height/$max_position;
  # bar division
  $bar_division=$bar_height/$y_div;
  #print "@dname\n";
  #print "marker_height=$marker_height,bar_height=$bar_height,bar_rate=$bar_rate,bar_division=$bar_division\n";
  #print "max_position=$max_position \n";
  #print "@relative_position \n";
  #print "@position \n";
  return(@dname,$marker_height,$bar_height,$bar_rate,$bar_division,@relative_position,@position,$max_position);
}
###########################################################
# Draw_Map_Image
###########################################################
sub Draw_Map_Image
{   
##############################################
#  image parameters
##############################################
# Y top edge
    my $Y_top_edge=70;
# Y bottom edge
    my $Y_bottom_edge=70;
# image scale range
    my $X_SCALE=300;
    my $Y_SCALE=$Y_top_edge + $marker_height + $Y_bottom_edge;
# title postion
    my $X_TITLE=50;
    my $Y_TITLE=$Y_top_edge-50;
    my $Y_version=$Y_TITLE+20;
    my $Y_SUBTITLE=$Y_TITLE+40;
# position of marker name
    my $marker_x=150;
    my $marker_y1=$Y_top_edge+10;
    my $marker_y2=$marker_y1; #for loop initial value
    my $unit_y=$marker_y1-5;
# bar parameters
    my $bar_x_start=48;
    my $bar_y_start=$Y_top_edge + $marker_height/8;
    my $bar_x_end=52;
    my $bar_y_end=$bar_y_start + $bar_height;
# bar scale parameters
    my $bar_x_scale1=$bar_x_start-4;
    my $bar_x_scale2=$bar_x_start;
    my $bar_y_scale1=$bar_y_start;
    my $bar_y_scale2=$bar_y_start+2;
# position of value y position is same as $marker_y2
    my $position_x=$marker_x+40;
#decide the length of scale on the bar
    ($integ,$dig)=split(/\./,$max_position);
    $integ=~ s/\D//g;
    $dig_length=length($integ);
    if($dig_length<=2){$x_minus=20;}
    if($dig_length ==3){$x_minus=25;}
    if($dig_length ==4){$x_minus=30;}
    if($dig_length ==5){$x_minus=35;}
    my $bar_x_value=$bar_x_start-$x_minus;
    my $bar_y_value=$bar_y_start-5;
    my $value_line_x=$bar_x_end+4;
    my $connect_line_x1=$value_line_x+5;
# time stamp
    my $X_time=48;
    my $Y_time=$Y_SCALE-25;
    
    $im = new GD::Image($X_SCALE,$Y_SCALE);
##############################################
#  color difination
##############################################
# allocate white
    $white = $im->colorAllocate(255, 255, 255);
# allocate black
    $black = $im->colorAllocate(0, 0, 0);
# allocate red
    $red = $im->colorAllocate(255, 0, 0);
# allocate green
    $green = $im->colorAllocate(0,255,0);
# allocate yellow
    $yellow = $im->colorAllocate(255,250,205);
# allocate orange
    $orange = $im->colorAllocate(250,113,0);
# allocate blue
    $blue = $im->colorAllocate(0,0,255);
    
    #open(GIF,"bluevert.gif");  ############################
    #print "open bluevert.gif \n";
    #$bar = newFromGif GD::Image(GIF);
    #print "newFromGif \n";
    #close GIF;
    #print "close bluevert.gif \n";
    #$im->setBrush($bar);      ############################
#draw title
    if($map_lod){$lod="LOD=$map_lod";}
    $im->string(gdGiantFont,$X_TITLE,$Y_TITLE,"$map_name $cross",$red);
    $im->string(gdMediumBoldFont,$X_TITLE,$Y_version,"$version",$black);
    $im->string(gdMediumBoldFont,$X_TITLE,$Y_SUBTITLE,"CHROMOSOME $chrom $lod",$black);
#draw bar
    $im->rectangle($bar_x_start,$bar_y_start,$bar_x_end,$bar_y_end,$red);
    $im->filledRectangle($bar_x_start,$bar_y_start,$bar_x_end,$bar_y_end,$red);
#draw bar division   
    use integer;

    foreach $_ (0 ..10)
    {
	$scale_value=$_ * $max_position/$y_div;
	$im->rectangle($bar_x_scale1,$bar_y_scale1,$bar_x_scale2,$bar_y_scale2,$black);
	$im->filledRectangle($bar_x_scale1,$bar_y_scale1,$bar_x_scale2,$bar_y_scale2,$black);
	$im->string(gdSmallFont,$bar_x_value,$bar_y_value,"$scale_value",$black);
	$bar_y_scale1 += $bar_division;
	$bar_y_scale2 += $bar_division;
	$bar_y_value += $bar_division;
    }
#draw map unit
    $im->string(gdMediumBoldFont,$position_x,$unit_y,"       $map_unit",$black);
#draw names,positions,lines 
    my $m=0; 
    foreach $_ (@dname)
    {
#draw marker line in the front of marker name	
	$marker_line_x=$marker_x-6;
	$marker_line_y=$marker_y2+$marker_interval/2;
	$im->line($marker_line_x,$marker_line_y,$marker_line_x,$marker_line_y,gdBrushed);
#draw position line on the bar
	$value_line_y=$bar_y_start+$position[$m]*$bar_division*10/$max_position;
	$im->line($value_line_x,$value_line_y,$value_line_x,$value_line_y,gdBrushed);
#draw connected line
	$connect_line_x2=$marker_line_x-6;
        $im->line($connect_line_x1,$value_line_y,$connect_line_x2,$marker_line_y,$black);
#draw marker name
	if($f_or_p[$m] eq "P")
	{
	    $im->string(gdMediumBoldFont,$marker_x,$marker_y2,"$_",$black);
	}else
	{
	    $im->string(gdSmallFont,$marker_x,$marker_y2,"$_",$black);
	}
#draw the position value
	$position_y=$marker_y2+$marker_interval/2;
	if($relative_position[$m] =~ /\d/){
	    $im->string(gdSmallFont,$position_x,$position_y,"-----[ $relative_position[$m]",$black);
	}
	$marker_y2 +=$marker_interval;
	$m++;
    }
    $time=localtime();
#write date
    $im->string(gdSmallFont,$X_time,$Y_time,"$time",$black);
# make the background transparent and interlaced
    $im->transparent($white);
    $im->interlaced('true');
    binmode STDOUT;
# Convert the image to GIF and print it on standard output
#    print $im->gif;

# print img to file
    $gif_data = $im->gif;
    open (DISPLAY,">$file_gif") || die;
    binmode DISPLAY;
    print DISPLAY $gif_data;
    close DISPLAY;
}
