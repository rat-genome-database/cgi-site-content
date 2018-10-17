#!/usr/bin/perl

#########################################################
#  file name:maps_view.cgi
#            marker query is using rgd_query table
#  author: JIAN LU
#  date: 5-26-2000
#  modified : 
#  12/14/02, fixed bug for map marker query. JL
########################################################
use lib '/rgd/tools/common';
use lib '/rgd/tools/common/RGD'; #DP 10-30-03
use RGD::HTML;
use RGD::DB;
require "cgi-lib.pl";

&ReadParse(*in);

my $id=$in{'id'};              # map RGD_ID
$id =~ s/\D//g;             # in case of using RGD accession#
my $mk_id=$in{'mk_id'};        # marker RGD_ID
$mk_id =~ s/\D//g;
my $marker = $in{'marker'};
my $map_unit = $in{'map_unit'};   
my $chr=$in{'chr'};            # chromosome on the map
my $interval=$in{'interval'};  # for showing map interval markers
my $bin=$in{'bin'};    # for showing specific marker up and down info
my $hilite=$in{'hilite'};      # for showing hight light marker parsed from 
my $map_key=$in{'map_key'};    # for showing each map on integrated map 

my ($map_version,$map_unit);
my $TABLE_WIDTH=600;

# to customize the title, version and tool_dir
my $rgd = RGD::HTML->new(
			 title      => "Rat Genome Database: Maps",
			 link_dir   => "maps",
			 category   => "data",
			);
my $baseURL=$rgd->get_baseURL;   # http://rgd.mcw.edu
my $baseCGI=$rgd->get_baseCGI;   # http://rgd.mcw.edu/tools
my $wwwPATH=$rgd->get_wwwPATH;   # /rgd/WWW
my $toolPATH=$rgd->get_toolPATH; # /rgd/TOOLS
my $dataPATH=$rgd->get_dataPATH; # /rgd/DATA

my $db = RGD::DB->new();

# print HTML head
$rgd->html_head;
# tool start here
$rgd->tool_start;

if($id){
  if($chr){
    my $chrom_sign=undef;
    if($chr == 21){
      $chrom_sign="X";
    }else{
      $chrom_sign=$chr;
    }
    print "<h2>Map Report: Chromosome $chrom_sign</h2>";
    &display_chromsome_map;
  }else{
    print "<h2>Map Report: Summary</h2>";
    print "<p>This tool allows you to retrieve data on \n
individual chromosome maps. Click on the chromosome number \n
to retrieve the Chromosome Map Report, which includes a view \n
of selected markers on the chromosome and marked intervals.  \n";
    &display_map_summary;
  }
}else{
  print "<h2>Map Report</h2>\n";

  print "<p>This tool allows you to retrieve data on several 
types of genetic and RH maps.  The Map Report includes information 
on map length, number of framework and placement markers and 
links to individual chromosome map\n";

  &display_summary;
}

# tool page end here
$rgd->tool_end;
# print HTML foot
$rgd->html_foot;
##########################################################
#   END
#########################################################
exit;

##########################################
# display summaries
##########################################
sub display_summary{
  my $sql = "select MAP_KEY,RGD_ID,MAP_NAME,MAP_VERSION from MAPS where MAP_NAME !='Other Maps'";
  my ($n,@result)= $db->query_Data(4,$sql);
  my(%maps,@rgd_ids);

  foreach my $r (@result){
    my($key,$rgd_id,$map_name,$version)=split(/\:\:/,$r);
    $maps{$rgd_id}->{'key'}=$key;
    $maps{$rgd_id}->{'name'}=$map_name;
    $maps{$rgd_id}->{'version'}=$version;
    $maps{$rgd_id}->{'count'}=$result;
    push(@rgd_ids,$rgd_id);
  }

#  my %rgd_refs = (); # %hash1
#  my %ref_data = (); # %hash2

#  $db->get_rgd_id_refs(\%rgd_refs, \%ref_data, @rgd_ids);

  print <<_TAB_;
<p><table border=0 width=$TABLE_WIDTH>
   <tr align=center>
       <td>Map Name</td>
       <td>Version</td>
       <td>Unique Markers</td>
   </tr>\n
   <tr align=center><td colspan=4><hr></td></tr>\n
_TAB_
  # count unique markers for every map
  $sql = "select distinct RGD_ID from maps_data where MAP_KEY<99";
  my ($m,@total)= $db->query_Data(1,$sql);
  my $count_rh_genetic=@total;

  foreach my $rgd_id (sort keys (%maps)){
    my $key=$maps{$rgd_id}->{'key'};
    # count markers for each map
    my $sql = "select count(MAPS_DATA_KEY) from maps_data where MAP_KEY=$key";
    my ($n,$count)= $db->query_Data(1,$sql);
    
    print "<tr align=center>";
    my $map_name=$maps{$rgd_id}->{'name'};
    $map_name=~ s/ /&nbsp\;/g;
    print "<td align=left><a href=\"$baseCGI/maps/maps_view.cgi?id=$rgd_id\">$map_name</td>";
    print "<td valign=top>$maps{$rgd_id}->{'version'}</td><td valign=top>";
    if($maps{$rgd_id}->{'name'} =~ /RH x Genetic/){
      print "$count_rh_genetic";
    }else{
      print "$count";
    }

    print"</td></tr>\n";
    print "<tr align=center><td colspan=4><hr></td></tr>\n";
  }
  print "</table>\n<p><a href=\"$baseURL\">Back to RGD Home</a>";
}

##########################################
# display_map_summary
#########################################
sub display_map_summary{
  my $sql="select MAP_NAME from MAPS 
           where RGD_ID=$id and MAP_NAME !='Other Maps'";   
  my ($n,$map_name)= $db->query_Data(1,$sql);

  if($map_name){
    if($map_name =~ /RH x Genetic/){  
      &show_integrated_map;       # display integrated map
    }else {                               
      &show_rh_genetic_map;       # display RH or genetic map
    }
  }else{
    &display_summary;
  }
}

# show_rh_genetic_map
##########################################
sub show_rh_genetic_map{
  my(%count_markers,%max_position,%count_framework,%count_placement);
  my $sql="select CHROMOSOME,F_OR_P,ABS_POSITION,
                  M.MAP_NAME,M.MAP_UNIT
           from MAPS_DATA D,MAPS M
           where D.MAP_KEY=M.MAP_KEY and M.RGD_ID=$id
           order by CHROMOSOME,ABS_POSITION";
  my ($n,@result)= $db->query_Data(6,$sql);
  my ($map_name,$map_unit);
  foreach my $i (@result){
    my($chr,$f_p,$abs_p,$name,$unit)=split(/\:\:/,$i);
    $chr=uc($chr);
    $map_name=$name if($name);
    $map_unit=$unit if($unit);
    $count_markers{$chr}++;
    # count rh and genetic map length
    $max_position{$chr}=$abs_p if($abs_p);
    
    # count rh and genetic map framework markers
    $count_framework{$chr}++ if($f_p =~ /F/);
    
    # count rh and genetic map placement markers
    $count_placement{$chr}++ if($f_p =~ /P/);
    
  }
  
  print <<EOF;
<table border=0>
<tr align=center><td colspan=5>
      <h3>$map_name</h3>
    </td></tr>
<tr>
  <td align=right class=label>Chr.</td>
  <td align=right class=label>Map length($map_unit)</td>
  <td align=right class=label>Framework</td>
  <td align=right class=label>Placement</td>
  <td align=right class=label># markers</td>
</tr>
<tr><td colspan=5><hr></td></tr>\n
EOF
  my $total_markers=0;
  my $total_framework=0;
  my $total_placement=0;

  foreach my $key (1 .. 21){
    my $chrom_sign=$key;
    if($key == 21){
      $chrom_sign="X";
    }
    $total_markers=$total_markers+$count_markers{$key};
    $total_framework=$total_framework+$count_framework{$key};
    $total_placement=$total_placement+$count_placement{$key};
    print <<EOF;
<tr>
  <td align=right><a href=\"$baseCGI/maps/maps_view.cgi?id=$id&chr=$key\">$chrom_sign</a></td>
  <td align=right>$max_position{$key}</td>
  <td align=right>$count_framework{$key}</td>
  <td align=right>$count_placement{$key}</td>
  <td align=right>$count_markers{$key}</td>
</tr>\n
EOF
  }
  print <<EOF;
<tr>
<td colspan=5><hr></td></tr>
<tr>
  <td align=right class=label>TOTAL</td>
  <td align=right class=label>&nbsp;</td>
  <td align=right class=label>$total_framework</td>
  <td align=right class=label>$total_placement</td>
  <td align=right class=label>$total_markers</td>
</tr>
</table>\n
EOF
}

# show_integrated_map
##########################################
sub show_integrated_map{
  #my @group=(1000,1001,1002); # FHH=1000,SHR=1001,RH=1002
  my @group=(1000,1001,1002,724580); # FHH=1000,SHR=1001,RH=1002, RH 3.4=724580
  my(%count,%maps);
  
  foreach my $g (@group){
    my $sql="select D.CHROMOSOME,M.MAP_NAME,M.MAP_UNIT
             from MAPS_DATA D,MAPS M
             where D.MAP_KEY=M.MAP_KEY and M.RGD_ID=$g";
    my ($n,@result)= $db->query_Data(3,$sql);
    
    foreach my $i (@result){
      my($chr,$name,$unit)=split(/\:\:/,$i);
      $chr=uc($chr);
      $maps{$name}=$unit;
      # count markers
      $count{$name}->{$chr}++;
    }
  }
  
  
  
  print <<EOF;
<table border=0 cellpadding=4 cellspacing=0>
<tr align=center><td colspan=4>
  <h3>Integrated Map</h3></td></tr>\n
<tr>
<td align=right class=label>Chr.</td>
EOF
  foreach my $key (keys (%maps)){
    print "<td class=label align=right>$key ($maps{$key})</td>";
  }
  print "</tr>\n";
  
  my %total={};
  
  foreach my $chr (1 .. 21){
    my $chrom_sign=$chr;
    if($chr == 21){
      $chrom_sign="X";
    }
    
    print <<EOF;
<tr>
  <td align=right class=label><a href=\"$baseCGI/maps/maps_view.cgi?id=$id&chr=$chr\">$chrom_sign</a></td>
EOF
    foreach my $key (keys (%maps)){
      print "<td align=right>$count{$key}->{$chr}</td>";
      $total{$key} =$total{$key}+$count{$key}->{$chr};
    }
    print "</tr>\n";
  }
  print <<EOF;
<tr>
  <td colspan=4><hr></td></tr>
<tr>
  <td align=right class=label>TOTAL</td>
EOF
  foreach my $key (keys (%maps)){
    print "<td class=label align=right>$total{$key}</td>";
  }
  print "</tr>\n";
  print "</table>\n";
}

# show_other_map
##########################################
sub show_other_map{
  my $sql="select D.CHROMOSOME,M.MAP_NAME,D.FISH_BAND
           from MAPS_DATA D,MAPS M
           where D.MAP_KEY=M.MAP_KEY and M.RGD_ID=$id";
  my ($n,@result)= $db->query_Data(3,$sql);
  
  my(%count_chr,%count_band,$map_name);
 
  foreach my $i (@result){
    my($chr,$name,$band)=split(/\:\:/,$i);
    $map_name=$name if($name);
    # count chr
    $chr=uc($chr);
    $count_chr{$chr}++ if($chr);
    
    # count bands
    $count_band{$chr}++ if($band);
  }
  
  print <<EOF;
<table border=0 width=$TABLE_WIDTH>
<tr align=center><td colspan=3>
<h3>$map_name</h3></td></tr>
<tr align=right>
<td width=100>Chromosome</td>
<td width=100>Gene mapped</td>
<td width=100>Band</td>
</tr>\n
EOF
  my $total_chr=0;
  my $total_band=0;

  foreach my $key (1 .. 21,Y){
    my $chrom_sign=$key;
    if($key == 21){
      $chrom_sign="X";
    }
    $total_chr=$total_chr+$count_chr{$key};
    $total_band=$total_band+$count_band{$key};
  
    print <<EOF;
<tr align=right>
<td><a href=\"$baseCGI/maps/maps_view.cgi?id=$id&chr=$key\">$chrom_sign</a></td>
<td>$count_chr{$key}</td>
<td>$count_band{$key}</td>
</tr>\n
EOF
  }
  print <<EOF;
<tr align=center>
<td colspan=5><hr></td></tr>
<tr align=right>
<td>TOTAL</td>
<td>$total_band
</td>
<td>$total_band
</tr>
</table>\n
EOF
}

##########################################
# display_chromsome_map
#########################################
sub display_chromsome_map{

  my $sql="select MAP_KEY, MAP_NAME,MAP_UNIT from MAPS where RGD_ID=$id";
 
  my ($n,@maps)= $db->query_Data(3,$sql);
  my @map=split(/\:\:/,$maps[0]);
  my $map_dir=$map[1];
  my $query_map_key=$map_key || $map[0];
  $map_unit=$map[2];
  $map_dir=~ s/ /_/g;
  $map_dir=uc($map_dir);


  my $chrom=$chr;
  if($chrom <10){
    $chrom="0$chrom";
  }

  my $html_file="$wwwPATH/maps/images/$map_dir/$map_dir\_$chrom\.htm";
  my $img_file ="$baseURL/maps/images/$map_dir/$map_dir\_$chrom\.gif";
  my $pdf_file ="$baseURL/maps/images/$map_dir/$map_dir\_$chrom\.pdf";
  my $phy_map="$baseURL/maps/images/PHYSICAL_MAP/PHYSICAL_MAP_$chrom\.gif";


  if(-e $html_file){
     open(HTML,"$html_file");
     my @lines=<HTML>;
     close(HTML);
     my $local_bin = $bin || "10";  

     print <<EOF;
<p><p>
<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr><td colspan=2>
A limited number of markers are displayed.  
Clicking on an individual marker will generate a
report for that marker.  
Clicking on an interval will generate
a list of markers located within that interval.
</td></tr>
EOF
    if($id != 1006){
     print <<EOF;
<tr><FORM method=post action="$baseCGI/maps/maps_view.cgi">
 <TD colspan=2>Marker Name/Aliases:
<input type=text name=marker size=10 value="$marker">
Bin interval
<input type=text name=bin size=3 value=$local_bin>
<input type=submit value="Find Map Location">
</TD>
<input type=hidden name=map_key value=$query_map_key>
<input type=hidden name=map_unit value=$map_unit>
<input type=hidden name=id value=$id>
<input type=hidden name=chr value=$chr>
  </FORM>
</tr>\n
EOF
   }
   print <<EOF;
<tr><td colspan=2>&nbsp;</td></tr>
<tr><td valign=top>&nbsp;<p>&nbsp;<br>
EOF

  foreach my $line (@lines){
    # added by JL to display maps
    $line =~ s/\$baseCGI/$baseCGI/;
    $line =~ s/\$baseURL/$baseURL/;
    print "$line";
  }
  print "</td><td align=left valign=top>";
  
  if($interval){
    #print "<p> display map interval markers between two markers";
    &display_map_intervals;
  }elsif($bin){
    # display map interval markers between bin size
    
    &display_map_bins;
  }else{
    print "<p><img src=\"$phy_map\" border=0>";
  }
  print <<_TXT_;
</td></tr>
<tr><td colspan=2><p><b>Note</b>: <br>Red markers are framework, black markers are placement.
</td>
</tr></table>\n
_TXT_

  }else{
    print "<p><img src=\"$phy_map\" border=0>";
  }
}

##########################################
# display_map_intervals
# for this detail query, use map flat file
# under  /rgd/DATA/maps/dbflatfiles
#  map_id_1_data.csv: FHH x ACI
#  map_id_2_data.csv: SHRSP x BN
#  map_id_3_data.csv: RH Map
#########################################
sub display_map_intervals{
  my ($mk_id_1,$mk_id_2)=split(/-/,$interval);
  
  my (@data,@sort_data,$pos_1,$pos_2,$start_pos,$end_pos,$start_id,$end_id);
  if($map_key >3){  # integrated map
    # no map display
  }else{ 
    my $db_file="$dataPATH/maps/dbflatfiles/map_id_$map_key\_data.csv";
    open(DB,"$db_file");
    @data=<DB>;
    close(DB);
  }
 
  foreach my $i (@data){
    chomp $i;
    my @lines=split (/,/,$i);
    my $id=$lines[0];
    my $chrom=$lines[5];
    my $abs=$lines[6];
    if($chr eq "$chrom"){
      if($id eq "$mk_id_1"){
	$pos_1=$abs;
      }
      if($id eq "$mk_id_2"){
	$pos_2=$abs;
      }
      push(@sort_data,"$lines[6],$i");
    }
  }

  my @sorted_data= sort numerically (@sort_data); # sorted by abs position
 
  if($pos_1=~ /\d+/ && $pos_2 =~ /\d+/){
    # verify the interval markers are right order
    if($pos_1 < $pos_2){
      $start_id=$mk_id_1;
      $start_pos=$pos_1;
      $end_id=$mk_id_2;
      $end_pos=$pos_2;
    }else{
      $start_id=$mk_id_2;
      $start_pos=$pos_2;
      $end_id=$mk_id_1;
      $end_pos=$pos_1;
    }
    
    # get interval map data
    if($id == 1006){
     
      &show_linked_markers($start_id,$end_id,@sorted_data); 
    }else{
      &show_interval_markers($start_id,$end_id,@sorted_data); 
    }
  }
}

sub display_map_bins{
  my (@data,$pos_1,$pos_2,$pos_range_min,$pos_range_max,$mk,$k,@ids);
  
  if($marker){
    my $kw=lc($marker);
    $kw=~ s/\s+//g;
    
    my $sql = "select distinct RGD_ID from rgd_query ";

    if($kw =~ /\*/){
      $kw =~ s/\*/%/g;
      $sql .= "where keyword_lc like '$kw'";
      
    }else{
      $sql .= "where KEYWORD_LC='$kw'";
    }
    
    ($k,@ids)= $db->query_Data(1,$sql);
    
  }
  
  if($k ==1){
    $mk_id = $ids[0];
  }
 

  my %object_name = ( sslps => "RGD_NAME",
		      genes => "GENE_SYMBOL",
		    );
 
  if($mk_id){
    my $min_position =0;
    
    my $sql = "select ABS_POSITION from maps_data
                where map_key=$map_key and chromosome='$chr'
                  and RGD_ID =$mk_id";
    
    my ($n,$position)= $db->query_Data(1,$sql);

    if($position ne ""){
      my $sql = "select max(ABS_POSITION) from maps_data
                  where map_key=$map_key and chromosome='$chr'";
      my ($m,$max_position)= $db->query_Data(1,$sql);
  
      if($position > 1000){
	$bin = 20;
      }
      
      $pos_range_min=$position-$bin;
      $pos_range_max=$position+$bin;
      
      if($pos_range_min < $min_position){
	$pos_1 = $min_position;
      }else{
	$pos_1 = $pos_range_min;
      }
      
      if($pos_range_max > $max_position){
	$pos_2 = $max_position;
      }else{
	$pos_2 = $pos_range_max;
      }
      
      
    SQL:

      $sql = "select RGD_ID,ABS_POSITION,F_OR_P,LOD from maps_data 
               where map_key=$map_key and chromosome='$chr' ";
      if($pos_1 < $pos_2){
        $sql .= " and ABS_POSITION between $pos_1 and $pos_2 order by ABS_POSITION";
      }else{
	$sql .= " and ABS_POSITION = $position";
      }
  
      my ($r,@result)= $db->query_Data(4,$sql);
      
      if(!$r){
	$pos_2 = $pos_2 + 10;

	goto SQL;
      }else{
	foreach my $line (@result){
	  my @tmp=split(/\:\:/,$line);
	  my $object = $db->checkObject($tmp[0]);
	  my $symbol = $object_name{$object};
	  my $sql="select $symbol from $object
                  where RGD_ID=$tmp[0]";
	  my ($s,$name) = $db->query_Data(1,$sql);
	  if($tmp[0] eq "$mk_id"){
	    $mk=$name;
	  }
	 
	  push(@data,"$tmp[0],$name,$tmp[1],$tmp[2],$tmp[3]");
	}
      }
      
      &show_bin_markers($mk,$position,@data);
    }else{
      &show_bin_markers($marker,$position,@data);
    }
  }else{
    if($k>1){
      my @names=();
      foreach my $line (@ids){
	 
	my $object = $db->checkObject($line);
	my $symbol = $object_name{$object};
	my $sql="select $symbol from $object
                  where RGD_ID=$line";
	my ($s,$name) = $db->query_Data(1,$sql);
	push (@names,"$line,$name");
      }
      &show_bin_markers($marker,$position,@names);
    }else{
      &show_bin_markers($marker,$position,@data);
    }
  }
}

sub numerically {$a<=>$b;}


# get interval map data
##################################################
sub show_bin_markers{
  my($mk,$position,@data)=@_;
  
  my $count=@data;
  if($chr == 21){
    $chrom=X;
  }else{
    $chrom=$chr;
  }
 
  if($position ne ""){ # accept 0 value
    
    print <<_TAB_;
<p>
<table border=0>
<tr align=center><td colspan=6><h3>Chromosome $chrom</h3></td></tr>
<tr><td colspan=6>The marker <b>$mk</b>\'s map position: $position $map_unit<br>
Within the postion interval $position +/-$bin, there are $count markers.</td></tr>\n
<tr align=center><td colspan=6><hr></td></tr>\n
<tr align=center>
<td></td>
<td>Marker</td>
<td>Related gene</td>
<td>Position</td><td>F\/P</td><td>LOD</td></tr>\n
_TAB_
    foreach my $d (@data){
      
      my @lines=split (/,/,$d);
      my $gene = &find_gene($lines[0]);
      print "<tr align=right>";
      print "<td>";
      if($mk_id eq "$lines[0]"){
	print "<font color=red><b>>></b></font>";
      }
      print "</td><td  align=left><a href=\"$baseCGI/query/query.cgi?id=$lines[0]\">$lines[1]</a></td>";
      if($gene){
	print "<td  align=left>";
	my @g = split(/,/,$gene);
	foreach my $g (@g){
	  my @tmp=split(/\:\:/,$g);
	  print "<a href=\"$baseCGI/query/query.cgi?id=$tmp[0]\">$tmp[1]</a><br>";
	}
	print "</td>";
      }else{
	print "<td></td>";
      }
      print "<td>$lines[2]</td><td>$lines[3]</td><td>$lines[4]</td></tr>\n";
    }
    print "</tr>\n<tr align=center><td colspan=6><hr></td></tr>\n";
    print "<tr><td colspan=4>Note: <br> F--framework<br> P--placement</td></tr>\n</table>\n";
  }else{
    my $num=@data;
    if($num){
      print <<_TAB_;
      <p>
 <table border=0>
<tr align=center><td colspan=5><h3>Chromosome $chrom</h3> 
Not map position found for <b>$mk</b><br>
There are total $num markers found. Try one of them below:
</td></tr>\n
<tr align=center><td colspan=5><hr></td></tr>\n
<tr><td>
_TAB_
  foreach my $d (@data){
    my @tmp=split(/,/,$d);
    print "<a href=\"$baseCGI/query/query.cgi?id=$tmp[0]\">$tmp[1]</a> ";
  }
      print "</td></tr>\n</table>\n";
    }else{
      print <<_TAB_;
<p>
<table border=0>
<tr align=center><td colspan=5><h3>Chromosome $chrom</h3> 
Not map position found for <b>$mk</b></td></tr>\n
<tr align=center><td colspan=5><hr></td></tr>\n
</table>\n
_TAB_
    }
  }
}
sub show_interval_markers{
  my($start_id,$end_id,@sorted_data)=@_;
  my (@interval,$flag,$chrom,$start_mk,$end_mk,$start_pos,$end_pos);
 
  
  foreach my $i (@sorted_data){
    my @lines=split (/,/,$i);
    my $id=$lines[1];

    if($id eq "$start_id"){
      $flag="S"; # start interval marker
      $start_mk=$lines[4];
      $start_pos=$lines[0];
 
    }
    if($id eq "$end_id"){
      $flag="E"; # end interval marker
      push(@interval,$i);
      $end_mk=$lines[4];
      $end_pos=$lines[0];
    }
    if($flag eq "S"){
      push(@interval,$i);
    }
  }
  my $count=@interval;
  if($chr == 21){
    $chrom=X;
  }else{
    $chrom=$chr;
  }
  print <<_TAB_;
<p>
<table border=0>
<tr align=center><td colspan=5><h3>Chromosome $chrom</h3> 
This interval contains $count markers.</td></tr>\n
<tr>
<td colspan=5>Starting <b>$start_mk</b> at $start_pos, Ending <b>$end_mk</b> 
   at $end_pos</td>
<tr align=center><td colspan=5><hr></td></tr>\n
<tr align=right>
<td align=center>Marker</td>
<td>Related gene</td>
<td>Position</td>
<td>F\/P</td>
<td>LOD</td></tr>\n
_TAB_
  foreach my $d (@interval){
    my @lines=split (/,/,$d);
    my $gene = &find_gene($lines[1]);
    if($hilite eq "$lines[1]"){
      print "<tr align=right bgcolor=white>";
    }else{
      print "<tr align=right>";
    }
    print "<td align=left><a href=\"$baseCGI/query/query.cgi?id=$lines[1]\">$lines[4]</a></td>";
    if($gene){
      print "<td  align=left>";
      my @g = split(/,/,$gene);
      foreach my $g (@g){
	my @tmp=split(/\:\:/,$g);
	print "<a href=\"$baseCGI/query/query.cgi?id=$tmp[0]\">$tmp[1]</a><br>";
      }
      print "</td>";
    }else{
      print "<td></td>";
    }
    print "<td>$lines[0]</td><td>$lines[8]</td><td>$lines[9]</td><td>$lines[10]</td></tr>\n";
  }
  print "</tr>\n<tr align=center><td colspan=5><hr></td></tr>\n";
  print "<tr><td colspan=4>Note: <br> F--framework<br> P--placement</td></tr>\n</table>\n";
}
# show_linked_markers
##################################################
sub show_linked_markers{
  my($start_id,$end_id,@sorted_data)=@_;
  my (@interval,$flag,$chrom,$start_mk,$end_mk,$start_pos,$end_pos);
 
  my (%data_1,%data_2,%data_3);
  
  my @maps=('rgd','FHH_X_ACI','SHRSP_X_BN','RH_MAP');
 
  if($map_key == 1 || $map_key == 2){
    my $db_file3="$dataPATH/maps/dbflatfiles/map_id_3_data.csv";
    open(DB,"$db_file3");
    while(<DB>){
      chomp;
      my @lines=split /,/;
      $data_3{$lines[0]}->{'name'}=$lines[3];
      $data_3{$lines[0]}->{'chrom'}=$lines[5];
      $data_3{$lines[0]}->{'pos'}=$lines[6];
    }
    close(DB);
  }elsif($map_key == 3){
    my $db_file1="$dataPATH/maps/dbflatfiles/map_id_1_data.csv";
    open(DB,"$db_file1");
    while(<DB>){
      chomp;
      my @lines=split /,/;
      $data_1{$lines[0]}->{'name'}=$lines[3];
      $data_1{$lines[0]}->{'chrom'}=$lines[5];
      $data_1{$lines[0]}->{'pos'}=$lines[6];
    }
    close(DB);
    
    my $db_file2="$dataPATH/maps/dbflatfiles/map_id_2_data.csv";
    open(DB,"$db_file2");
    while(<DB>){
      chomp;
      my @lines=split /,/;
      $data_2{$lines[0]}->{'name'}=$lines[3];
      $data_2{$lines[0]}->{'chrom'}=$lines[5];
      $data_2{$lines[0]}->{'pos'}=$lines[6];
    }
    close(DB);
  }
  
  foreach my $i (@sorted_data){
    my @lines=split (/,/,$i);
    my $id=$lines[1];
    
    if($id eq "$start_id"){
      $flag="S"; # start interval marker
      $start_mk=$lines[4];
      $start_pos=$lines[0];
    }
    if($id eq "$end_id"){
      $flag="E"; # end interval marker
      push(@interval,$i);
      $end_mk=$lines[4];
      $end_pos=$lines[0];
    }
    if($flag eq "S"){
      push(@interval,$i);
    }
  }
  my $count=@interval;
  if($chr == 21){
    $chrom=X;
  }else{
    $chrom=$chr;
  }
  
  print <<_TAB_;
<p>
<table border=0>
_TAB_

  if($map_key == 1 || $map_key == 2){
   
    $maps[$map_key]=~ s/\_/\&nbsp\;/g;
    $maps[3]=~ s/\_/\&nbsp\;/g;

    print <<_TAB_;
<tr align=center>
<td colspan=4><h3>Chromosome $chrom</h3></td></tr>\n
<tr align=center>
<td colspan=4><hr></td></tr>\n
<tr align=center>
<td>&nbsp</td><td>&nbsp</td><td>[&nbsp;<b>$maps[$map_key]</b>&nbsp;]</td>
<td>[ <b>$maps[3]</b> ]</td></tr>\n
<tr align=center>
<td>Marker</td>
<td>Related gene</td>
<td align=center>Position</td>
<td>Position</td>
</tr>\n
<tr align=center><td colspan=4><hr></td></tr>\n
_TAB_
    my $mapped=undef;
    foreach my $d (@interval){
      my @lines=split (/,/,$d);
      
      if($data_3{$lines[1]}->{'name'}){
	my $gene = &find_gene($lines[1]);
	$mapped=1;
	print "<tr align=right>";
	print "<td align=left><a href=\"$baseCGI/query/query.cgi?id=$lines[1]\">$lines[4]</a></td>";
	if($gene){
	  print "<td  align=left>";
	  my @g = split(/,/,$gene);
	  foreach my $g (@g){
	    my @tmp=split(/\:\:/,$g);
	    print "<a href=\"$baseCGI/query/query.cgi?id=$tmp[0]\">$tmp[1]</a><br>";
	  }
	  print "</td>";
	}else{
	  print "<td></td>";
	}
	print "<td>$lines[0]</td><td>$data_3{$lines[1]}->{'pos'}</td></tr>";
      }

    }
    if($mapped){
      print "</tr>\n<tr align=center><td colspan=4><hr></td></tr>\n";
    }else{
      print "<tr><td colspan=4>";
      print "There is no marker at this interval on the $maps[$map_key] 
             map that is also mapped on the $maps[3].</td></tr>\n";      
    }
  }else{
    my $map_name=$maps[$map_key];
    $map_name=~ s/\_/\&nbsp\;/g;
    $maps[1]=~ s/\_/\&nbsp\;/g;
    $maps[2]=~ s/\_/\&nbsp\;/g;
    print <<_TAB_;
<tr align=center>
  <td colspan=5><h3>Chromosome $chrom</h3></td></tr>\n
<tr align=center>
  <td colspan=5>(Only cross-linked markers shown here)</td></tr>\n
<tr align=center>
  <td colspan=5><hr></td></tr>\n
<tr align=center>
  <td>Marker</td>
  <td>Related gene</td>
  <td>[&nbsp;<b>$maps[1]</b>&nbsp;]</td>
  <td>[&nbsp;<b>$map_name</b>&nbsp;]</td>
  <td>[&nbsp;<b>$maps[2]</b>&nbsp;]</td></tr>\n
<tr align=center><td colspan=5><hr></td></tr>\n
_TAB_
     my ($mapped);
     foreach my $d (@interval){
       my @lines=split (/,/,$d);
       
       if($data_1{$lines[1]}->{'name'} || $data_2{$lines[1]}->{'name'}){
	 my $gene = &find_gene($lines[1]);
	 $mapped=1;
	 print "<tr align=right>";
	 print "<td align=left><a href=\"$baseCGI/query/query.cgi?id=$lines[1]\">$lines[4]</a></td>";
	 if($gene){
	   print "<td  align=left>";
	   my @g = split(/,/,$gene);
	   foreach my $g (@g){
	     my @tmp=split(/\:\:/,$g);
	     print "<a href=\"$baseCGI/query/query.cgi?id=$tmp[0]\">$tmp[1]</a><br>";
	   }
	   print "</td>";
	 }else{
	   print "<td></td>";
	 }
	 print "<td>$data_1{$lines[1]}->{'pos'}</td><td>$lines[0]</td>";
	 print "<td>$data_2{$lines[1]}->{'pos'}</td></tr>\n";
       }
     }
    if($mapped){
      print "</tr>\n<tr align=center><td colspan=4><hr></td></tr>\n";
    }else{
      print "<tr><td colspan=3>";
      print "There is no marker at this interval on the $maps[$map_key] map that is also
             mapped on the $maps[3].</td></tr>";      
    }
  }
  print "</table>\n";
}

sub find_gene{
  my ($sslp_id)=@_;
  my $gene_symbol=undef;
  
  my $sql = "select GENE_KEY from rgd_gene_sslp R, SSLPS S
              where S.rgd_id=$sslp_id and S.SSLP_KEY=R.SSLP_KEY";
    my ($r,@keys)= $db->query_Data(1,$sql);
  
  if($r){
    foreach my $k (@keys){
      
      my $sql = "select RGD_ID, GENE_SYMBOL from genes
                  where GENE_KEY=$k";
      my ($s,$symbol)= $db->query_Data(2,$sql);
            $gene_symbol .= "$symbol,";
    }
    chop $gene_symbol;
  }
  return $gene_symbol;
}
