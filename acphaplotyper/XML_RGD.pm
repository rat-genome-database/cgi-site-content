#########################
#
# XML_RGD.pm - A perl 5 module to connect to RGD
#
# (c) Simon Twigger, Medical College of Wisconsin, 1999, 2002
#     simont@mcw.edu
#
#########################



#########################
#
#   Notes
#
#########################
#  
# 9/99 Converting to 3 tier model with RGD.pm handling db IO routines only
#      Moving towards XML output options
# 
# 2/02 Converting away from diretct database access to using flat files - faster!
#
#########################



#########################
#
#   Bugs/To Do List
#
#########################
#  
# Take out hard coded path information, inherit from HTML.pm
# 
# 
#
#########################


package XML_RGD;

require 5.003;
use Exporter ();
use lib '/rgd/tools/common';

# use strict; # to keep me honest
use Carp;   # to make error reporting a bit easier
use vars qw($VERSION @ISA @EXPORT);

use RGD::DB; #DP 11-03-04
use RGD::HTML;
use DBI;

my $dbh = RGD::DB->new(); #DP 11-03-04

$VERSION = "0.2";
@ISA = qw(Exporter);
@EXPORT = qw(
	     $RGD_HOME
	     $BASE_URL
	     $BASE_CGI
	     $BASE
	     $RHMAP
	     $DB_DRIVER
	     $USER
	     $PASS
	     $SID
	     );

my $html = RGD::HTML->new(
			 title     => "Rat Genome Database ACP Haplotyper",
			 doc_title => "ACP Haplotyper",
			 version   => 1,
			 tool_dir  => "haplotyper",
			);
			

my $BASE_URL = $html->get_baseURL;
my $RGD_HOME = "$BASE_URL/";
my $BASE_CGI = $html->get_baseCGI. "/acphaplotyper/";
my $BASE = "";
my $RHMAP = "/rhmapper/";

my $SSLPS_FILE = "SSLPS_ALLELES.txt"; # The file holding the allele sizes from RGD FTP site

my $XML_HEADER =  "<?xml version=\"1.0\" ?>\n"; # encoding=\"UTF-8\" ?>
my $XML_OUT_FLAG = 0; # 1 for XML output, 0 for normal
#my $dbh = (); # RGD::DB->new();


my $dataPath = $html->get_dataPATH;
my $map_data_path = $dataPath . "/maps/dbflatfiles/";
my $date = scalar localtime();
my $DEBUG = 1; # debug flag, set to 1 for messages to STDERR

#############
#
# The constructor method
#
#############

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize();
    return $self;
}

############
# 
# intitialize sets up the database connections
#
############

sub _initialize {

  # create the database connection
  #$dbh = DBI->connect("$DB_DRIVER:$SID",$USER,$PASS) || &HTML_Error("$DBI::errstr\n"); #DP 11-03-04

}

############
#
# set the XML output flag to determine the nature of the output from the functions
#
############

sub set_XML_OUT_FLAG {
  my ($me,$flag) = @_;

  if($flag == 0 || $flag == 1) {
    $XML_OUT_FLAG = $flag;
    return 1; # to indicate success
  }
  else {
    $XML_OUT_FLAG = 0; # default to no XML
    return 0; # to indicate failiure
  }
}



############
#
# get the current XML output flag value
#
############

sub get_XML_OUT_FLAG {
  return $XML_OUT_FLAG;
}
############
#
# get the current XML output flag value
#
############

sub xml_header {
  return $XML_HEADER;
}

############
# 
# Output an HTML page with error information
#
############

sub HTML_Error {

    # read in the error message passed to the subroutine
    my $error_message = shift(@_) || "An unknown error occured - Yikes";
    my $script = shift(@_) || "CGI Error: ";

    # print out HTML page letting the new user know an error occured

    print "Content-type: text/html\n\n";

    print <<"EOF";
<HTML><HEAD><TITLE>$script error</TITLE></HEAD<
<BODY BGCOLOR="#FFFFFF">
<BR>
<H1>An error occured whilst processing your request:</H1>

<STRONG>$error_message</STRONG>

<HR>
Return to the <A HREF="http://legba.ifrc.mcw.edu/rgd-bin/search.cgi">RGD Search Tools Page</A>
</BODY></HTML>
EOF

    # stop the execution of the script here
    exit;
}



##############
#
# get_map_names_from_rgd 
#
# Read in the basic map information from RGD to make the initial web page
# with appropriate maps
#
##############

sub get_map_names_from_rgd {

  # get a reference to an array so we can map the map_id (the array index)
  # to the map's name (stored in the array)

  my ($me,$map_array_ref) =  @_;


    # get the map strain information
    my $sql = <<"SQL";
    select MV.MAP_ID, MV.MAP_NAME,MI.MAP_VERSION,MV.STRAIN_NAME_1,MV.STRAIN_NAME_2 
    from MAP_STRAIN_V MV, MAP_INDEX MI
    where MV.MAP_ID = MI.MAP_ID
SQL
    
    my $sth = $dbh->prepare($sql) || &HTML_Error("$dbh->errstr \n");
    $sth->execute || &HTML_Error("$dbh->errstr \n");

    my $map_count = 0;
    my @row = ();
  my $xml_output = "";

  if($XML_OUT_FLAG) {
    # $xml_output = $XML_HEADER;
    $xml_output .= "<rgd_map_data>\n";
  }

  MAP:
  while(@row = $sth->fetchrow_array) {
    if($row[0]) {

      if($XML_OUT_FLAG) {
	$xml_output .= <<"End_of_XML";
<map_data>
<id>$row[0]</id>
<name>$row[1]</name>
<version>$row[2]</version>
End_of_XML

# if we have strain information, add it in here
  if($row[3]) {
    $xml_output .= "<strain>$row[3]</strain>\n";
  }
  if($row[4]) {
    $xml_output .= "<strain>$row[4]</strain>\n";
  }
	
# end map_data element
$xml_output .= "</map_data>\n";
	    
      }
      else {
	# set the array values so that the array index == the map_id value
	# and the map's name is stored in the array itself.
	print "reading $row[0], $row[1] \n";
	$map_array_ref->[$row[0]] = $row[1];
      }
    }
  }
  
  $sth->finish || die "$dbh->errstr\n";
  
  if($XML_OUT_FLAG) {
    $xml_output .= "</rgd_map_data>\n";
    return $xml_output; # return the XML stream to the calling function
  }
  
}


##############
#
# get_strain_ids_from_rgd
#
# Read in the map strain name and id into %strain_names, keyed by name
#
##############

sub get_strain_ids_from_rgd {

  my ($me,$strain_name_ref,$strain_id_ref) = @_;
  
  # get the map strain name and id into %strain_names, keyed by name
  my $sql = <<"SQL";
    select STRAIN_NAME, STRAIN_ID
    from STRAINS
    order by strain_id
SQL
  
  my $sth = $dbh->prepare($sql) || die ("$dbh->errstr \n");
  $sth->execute || die ("$dbh->errstr \n");
  
  my @row = ();
  my $xml_output = "";
  if($XML_OUT_FLAG) {
    # $xml_output = $XML_HEADER;
    $xml_output .= "<rgd_rat_strain_data>\n";
  }
 SIZE:
  while(@row = $sth->fetchrow_array) {
    if($row[1]) {
      
      if($XML_OUT_FLAG) {
	$xml_output .= "<strain_data>\n<id>$row[1]</id>\n<name>$row[0]</name>\n</strain_data>\n";
      }
      else {
	$strain_name_ref->{$row[0]} = $row[1];
	$strain_id_ref->{$row[1]} = $row[0];
	# print "Read $row[0] $row[1]<BR>";
      }
    }
  }
  
  $sth->finish || die "$dbh->errstr\n";
  
  if($XML_OUT_FLAG) {
    $xml_output .= "</rgd_rat_strain_data>\n";
    return $xml_output; # return the XML stream to the calling function
  }
}



##############
#
# get_strain_allele_sizes_from_rgd
#
# Read in the allele sizes for a give strain into a hash, passed by ref from
# the calling function (keyed by rgd_id
#
##############

sub get_strain_allele_sizes_from_rgd {

  my ($me,$strain,$marker_size_hash_ref) = @_;
  
  my $number = 10;

  # get the map strain information
  my $sql = <<"SQL";
    select RGD_ID, VALUE_1
    from MARKER_ALLELES
    where STRAIN_ID = $strain
    order by rgd_id
SQL
  
  my $sth = $dbh->prepare($sql) || die $dbh->errstr;
  $sth->execute || die $dbh->errstr;
  
  my @row = ();
  
  if($XML_OUT_FLAG) {
    # $xml_output = $XML_HEADER;
    $xml_output = "<rgd_allele_size_data strain_id=\"$strain\">\n";
  }
  
 SIZE:
  while(@row = $sth->fetchrow_array) {
    if($row[1]) {
      if($XML_OUT_FLAG) {
	$xml_output .= "<marker>\n<rgd_id>$row[0]</rgd_id>\n<size>$row[1]</size>\n</marker>\n";
      }
      else {
	$marker_size_hash_ref->{$row[0]} = $row[1];
	# print "Read $chrom @row<BR>";
      }
    }
  }
    
  $sth->finish || die "$dbh->errstr\n";
  
  if($XML_OUT_FLAG) {
    $xml_output .= "</rgd_allele_size_data>\n";
    return $xml_output; # return the XML stream to the calling function
  }
}



##############
#
# Get a single marker's data from RGD
#
##############

sub get_a_markers_map_data_from_rgd {

  my ($me,$marker,$map_id,$chrom) = @_;
  
  my $sql = <<"SQL";
  select MD.MAP_KEY,MD.ABS_POSITION,MD.F_OR_P,MD.LOD
    from MAPS_DATA MD
    where MD.MAP_KEY = $map_id
    and MD.CHROMOSOME = $chrom
    and MD.RGD_ID = (
select RGD_ID from SSLPS
where RGD_NAME = ? )
SQL

  my $sth = $dbh->prepare($sql) || die ("$dbh->errstr \n");
  $sth->execute($marker) || die ("$dbh->errstr \n");
  
  my @row = ();
  if(@row = $sth->fetchrow_array) {
    # marker is present in the map, return data
    return @row;
  }
  else {
    # not present, return 0
    return 0;
  }

}

##############
#
# get_map_marker_data_from_rgd
#
# Read in the map marker information from RGD
# Currently adapted to read from flat files to save time
#
##############

sub get_map_marker_data_from_rgd {
  
  
  my ($me,$map_id,$chrom,$markers_ref,$flank1_d,$flank2_d, $xml_ref) = @_;
  
  # print "Input: $map_id,$chrom,$markers_ref,$flank1_d,$flank2_d \n";


 # my $sql = <<"SQL";
#select MD.CHROMOSOME, MD.MAP_KEY, MD.ABS_POSITION,MD.BAND_TYPE,MD.F_OR_P,MD.LOD,MD.RGD_ID,S.RGD_NAME
#FROM MAPS_DATA MD, SSLPS S WHERE S.RGD_ID = MD.RGD_ID AND MD.MAP_KEY = $map_id
#SQL

  
  # open (ERR_LOG, ">err_RGD.pm.log") || die "Cant open error log: $!";
  
  my %r_name = ();
  my %d_name = ();
  my %other_name = ();
  my @marker_chrom = ();
  my @rgd_id_list = ();
  my %markers = ();
  
  &debug( "Getting map data from file:\n");
  my %map_data = ();
  &get_map_data_from_file(\%map_data,$map_id, $chrom,$flank1_d,$flank2_d);


  # Read map data into %map_data file, now have to load it into the
  # markers hash

 MAP:
  foreach my $id (sort {
    $map_data{$a}{chr} <=>  $map_data{$b}{chr} or
    $map_data{$a}{abs_dist} <=>  $map_data{$b}{abs_dist},

  }
		  keys %map_data) {


    if($map_data{$id}{name}) { 
      my $chrom = $map_data{$id}{chr} || "0";
      my $map_id = $map_data{$id}{map_key} || "0";
      my $pos = $map_data{$id}{abs_dist} || "0";
      my $units = 'cR';
      my $f_or_p = $map_data{$id}{fp} || 'F';
      my $lod = $map_data{$id}{lod} || "0";
      my $rgd_id = $id || 1;
      my $name = $map_data{$id}{name} || 'd1rat1';
      my $key = $map_data{$id}{obj_key} || '1000';
      
      if ($f_or_p eq '0') {
	$f_or_p = "0.0";
      }
      elsif (!$chrom || !$map_id || !$pos || !$units || !$f_or_p || !$lod || !$rgd_id || !$name) {
	# print ERR_LOG " @row \n";
	
	next MAP;
      }
      
      
      if($name =~ /^d(\d{1,2}|x)\w\w\w/i) { # match d names
	$d_name{$rgd_id} = $name;
	$markers{$rgd_id} = "$chrom,$map_id,$pos,$units,$f_or_p,$lod,$rgd_id,$key";

	push @{ $marker_chrom[$chrom] } ,"$name";
	push (@rgd_id_list,$rgd_id);
      }
      else {
	$other_name{$rgd_id} = $name;
      }
    }
  }
 
  &debug("$date: Assembling the XML file\n");
  $$xml_ref = "<rgd_map_raw_data chromosome=\"$chrom\">\n";
  
  my %allele_sizes = ();
  &get_sizes_from_file(\%allele_sizes);

  my $marker_count = 0;  
  for $marker_count (0 .. $#rgd_id_list) {
    
    
    

    local ($chr,$id,$pos,$units,$fp,$lod,$rgd,$key) = split /,/,$markers{$rgd_id_list[$marker_count]};
    
    my %alleles = ();
    
    # gets the allele sizes for a given rgd_id and puts them into %alleles
    # keyed by strain_name

    # warn "Getting allele info for $key\n";

    # need to pass in the sslp_key, to avoid a join

    # Direct access to database verrrry slow, rewrite to get from file
    # &get_markers_allele_sizes_from_rgd($me,$key,\%alleles);


    $$xml_ref .= <<"End_of_XML";
<marker>
  <name>$d_name{$rgd}</name>
  <abs_distance>$pos</abs_distance>
  <f_or_p>$fp</f_or_p>
  <lod>$lod</lod>
End_of_XML

    if($markers_ref) {
      # create the hash relating strain name to allele size {ACI} = 123bp
      # capitalize the first letter
      $markers_ref->{$d_name{$rgd}}{name} = "\u$d_name{$rgd}";
      $markers_ref->{$d_name{$rgd}}{abs_distance} = $pos;
      $markers_ref->{$d_name{$rgd}}{f_or_p} = $fp;
      $markers_ref->{$d_name{$rgd}}{lod} = $lod;
      
    }

    if(keys %{$allele_sizes{$rgd}}) {
      $markers_ref->{$d_name{$rgd}}{in_acp} = 1;
      foreach $strain_id (sort keys %{$allele_sizes{$rgd}}) {
	$$xml_ref .= "<allele_size strain=\"$strain_id\">$allele_sizes{$rgd}{$strain_id}</allele_size>\n";
	
	if($markers_ref) {
	  # create the hash relating strain name to allele size {ACI} = 123bp
	  $markers_ref->{$d_name{$rgd}}{$strain_id} = $alleles{$strain_id};
	}
	
      }
    }
    else {
      $markers_ref->{$d_name{$rgd}}{in_acp} = 0;
      $$xml_ref .= "  <no_acp_data/>\n";
    }
    

    $$xml_ref .= <<"End_of_XML";
</marker>
End_of_XML

  }
  
  $$xml_ref .= "</rgd_map_raw_data>\n";
  
  $date = scalar localtime();
  &debug("XML complete\n");

  # &debug("$$xml_ref\n");

  #if($XML_OUT_FLAG) {
  #  return $$xml_ref;
    
  #}
  
  return;
  
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


##############
#
# get_markers_allele_sizes_from_file
#
# Read in the allele sizes into a hash from a file
#
##############

sub get_sizes_from_file {

  my ($size_hash_ref,$marker_list_ref) = @_;


  &debug("OPening $SSLPS_FILE\n");
  open (SIZES,"$SSLPS_FILE") or &HTML_Error("Cant open file $SSLPS_FILE, $!\n");

  my %headers = ();

 SIZE_LOOP:
  while (<SIZES>) {

    chomp;
    my @data = split '\t',$_;
    
    # warn "Read in $data[1]\n";

    if($data[0] eq "SSLP_RGD_ID") { # this is the first line with column headers

      # load strain names into hash keyed by index value
      foreach my $strain (0 .. $#data) {
	$headers{$strain} = $data[$strain];
      }
      next SIZE_LOOP;
    }

    # Loop through each strain's size info, enter into hash keyed by RGD_ID and strain name
    foreach my $strain (0 .. $#data) {
      if($data[$strain]) {
	if($data[$strain] =~ /:/) {
	  ($data[$strain], my $trash) = split ':',1; # only take the first value for polymorphic strains
	}
	
	$size_hash_ref->{$data[0]}->{$headers{$strain}} = $data[$strain];
	
	# warn "$data[0] -> $headers{$strain} -> $data[$strain]\n";
      }
    }

  }
  
  &debug("Read in $SSLPS_FILE, continuing with script\n");

  # End of allele sizes file
  return;

}



##############
#
# get_markers_allele_sizes_from_rgd
#
# Read in the allele sizes for a given rgd_id into a hash, passed by ref from
# the calling function (keyed by strain name)
#
##############

sub get_markers_allele_sizes_from_rgd {

  my ($me,$key,$hash_ref) = @_;
  
  my $number = 10;

  # get all the 
  my $sql = <<"SQL";
    select ST.STRAIN_SYMBOL, A.SIZE1
    from SSLPS_ALLELES A, STRAINS ST
    where 
A.SSLP_KEY = $key
    and ST.STRAIN_KEY = A.STRAIN_KEY
SQL
  
  my $sth = $dbh->prepare($sql) || die $dbh->errstr;
  $sth->execute || die $dbh->errstr;
  
  my @row = ();
  my $data_hash = ();

 SIZE:
  while(@row = $sth->fetchrow_array) {
    if(!$#row) {
      return 0;
    }
    if($row[1]) {

      # for example:
      # $allele_size{'ACP'} = 123 bp
      $hash_ref->{$row[0]} = $row[1];
      
    }
  }
  
  $sth->finish || die "$dbh->errstr\n";
  return 1;

}


#sub get_allele_sizes_from_file {

#  my ($me, $key, $allele_ref) = @_;


#}



sub get_map_data_from_file {

  my ($hash_ref,$map_key, $chr,$flank1_d,$flank2_d) = @_;

  my $flat_file = "map_id_" . $map_key . "_data.csv";

  open (IN, $map_data_path . $flat_file) || die "Cant open flatfile: $flat_file $!\n";

  warn "$date: Reading $map_data_path . $flat_file ...";

 MARKER_LOOP:
  while (<IN>) {
    chomp;
    my ($rgd_id, $obj_type,$obj_key,$name,$map_key,$chrom,$absdist,$fp,$lod) = split',',$_;

    next MARKER_LOOP if $obj_type == 2; # Dont want EST s
    next MARKER_LOOP if $chrom ne $chr; # Dont want data from other chromosomes

    if($flank1_d > 0) {
      next MARKER_LOOP if $absdist < $flank1_d
    }
    if($flank2_d > 0) {
      next MARKER_LOOP if $absdist > $flank2_d
    }
    
    # warn "Read in $name\n";	
    
    $hash_ref->{$rgd_id}{obj_type} = $obj_type;
    $hash_ref->{$rgd_id}{obj_key}  = $obj_key;
    $hash_ref->{$rgd_id}{name}     = $name;
    $hash_ref->{$rgd_id}{map_key}  = $map_key;
    $hash_ref->{$rgd_id}{chr}      = $chrom;
    $hash_ref->{$rgd_id}{abs_dist}  = $absdist;
    $hash_ref->{$rgd_id}{fp}       = $fp || 'P';
    $hash_ref->{$rgd_id}{lod}      = $lod || '.';

  }
  
  warn "$date: Done\n";

  return 1;

} # end of get_map_data_from_file



1;


__END__

##############
#
# get_map_marker_data_from_rgd
#
# Read in the map marker information from RGD
#
##############

sub get_map_marker_data_from_rgd {

    my ($map_id,$dest_hash_ref,$m_chrom_ref,$dname_ref,$rname_ref) = @_;

    # get the marker information
    my $sql = <<"SQL";
    select MV.CHROMOSOME,MV.MAP_ID,MV.POSITION,MV.MAP_UNIT,MV.F_OR_P,MV.MARKER_LOD,MV.RGD_ID,ML.MARKER_NAME
    from MARKER_MAP_INFO_V MV, MARKER_LIBRARY ML
    where MV.RGD_ID = ML.RGD_ID
    and MV.MAP_ID = $map_id
SQL
    
    my $sth = $dbh->prepare($sql) || die ("$dbh->errstr \n");
    $sth->execute || die ("$dbh->errstr \n");

    my @row = ();

  MAP:
    while(@row = $sth->fetchrow_array) {
	if($row[7]) {
	    my ($chrom,$map_id,$pos,$units,$f_or_p,$lod,$rgd_id,$name) = @row;
	    
	    if($name =~ /^r\d\d\d/i) { # match r names
		$r_name_ref->{$rgd_id} = $name;
		next MAP;
	    }

	    if($name =~ /^d(\d{1,2}|x)\w\w\w/i) { # match d names
		$d_name_ref->{$rgd_id} = $name;
		$dest_hash_ref->{$name} = "$map_id,$pos,$units,$f_or_p,$lod,$rgd_id";
		push @{ $m_chrom_ref->[$chrom] } ,"$name";
	    }
	    else {
		$other_name{$rgd_id} = $name;
	    }
	}
    }

    $sth->finish || die "$dbh->errstr\n";
}



##############
#
# get_map_marker_data_from_rgd
#
# Read in the map marker information from RGD
#
##############

sub get_map_marker_data_from_rgd {
  
  
  my ($me,$map_id,$chrom,$markers_ref,$flank1_d,$flank2_d) = @_;
  
  # print "Input: $map_id,$chrom,$markers_ref,$flank1_d,$flank2_d \n";

 

 # my $sql = <<"SQL";
#select MD.CHROMOSOME, MD.MAP_KEY, MD.ABS_POSITION,MD.BAND_TYPE,MD.F_OR_P,MD.LOD,MD.RGD_ID,S.RGD_NAME
#FROM MAPS_DATA MD, SSLPS S WHERE S.RGD_ID = MD.RGD_ID AND MD.MAP_KEY = $map_id
#SQL

#  if($chrom > 0 && $chrom <= 23) {
#    $sql .= " and MD.CHROMOSOME = '19'";
#  }
  
#  if($flank1_d >= 0 && $flank2_d >= 0) {
#    if($flank1_d < $flank2_d) {
#      $sql .= " and MD.ABS_POSITION between $flank1_d and $flank2_d ";
#    }
#    else {
#      $sql .= " and MD.ABS_POSITION between $flank2_d and $flank1_d ";
#    }
#  }
#  elsif ($flank1_d >= 0) {
#    $sql .= " and MD.ABS_POSITION >= $flank1_d ";
#  }
#  elsif ($flank2_d >= 0) {
#    $sql .= " and MD.ABS_POSITION <= $flank2_d ";
#  }
#  $sql .= " order by MD.CHROMOSOME, MD.ABS_POSITION";
  
#  warn "SQL: $sql\n";
#  #exit;

#  my $sth = $dbh->prepare($sql) || die ("$DBI::errstr \n");
#  $sth->execute || die ("$DBI::errstr \n");
  
#  my @row = ();
  
  
  
  # open (ERR_LOG, ">err_RGD.pm.log") || die "Cant open error log: $!";
  
  my %r_name = ();
  my %d_name = ();
  my %other_name = ();
  my @marker_chrom = ();
  my @rgd_id_list = ();
  my %markers = ();
  
  my %map_data = ();
  &get_map_data_from_file(\%map_data,$map_id);


 MAP:
  while(@row = $sth->fetchrow_array) {

    if($row[7]) { 
      my $chrom = 0;
      my $map_id = 1000;
      my $pos = 1000;
      my $units = 'tP';
      my $f_or_p = 'F';
      my $lod = 100;
      my $rgd_id = 1;
      my $name = 'd1rat1';
      
      my $i = 0;
      for $i (0 .. $#row) {
	if(!$row[$i]) {
	  $row[$i] = "0.0";
	}
      }
      
      ($chrom,$map_id,$pos,$units,$f_or_p,$lod,$rgd_id,$name) = @row;
      
      if ($f_or_p eq '0') {
	$f_or_p = "0.0";
      }
      elsif (!$chrom || !$map_id || !$pos || !$units || !$f_or_p || !$lod || !$rgd_id || !$name) {
	# print ERR_LOG " @row \n";
	
	next MAP;
      }
      
      if($name =~ /^r\d\d\d/i) { # match r names
	$r_name{$rgd_id} = $name;
	next MAP;
      }
      
      
      
      if($name =~ /^d(\d{1,2}|x)\w\w\w/i) { # match d names
	$d_name{$rgd_id} = $name;
	$markers{$rgd_id} = "$chrom,$map_id,$pos,$units,$f_or_p,$lod,$rgd_id";

	push @{ $marker_chrom[$chrom] } ,"$name";
	push (@rgd_id_list,$rgd_id);
      }
      else {
	$other_name{$rgd_id} = $name;
      }
    }
  }
  
  $sth->finish || die "$dbh->errstr\n";
  
  # close ERR_LOG;
  
  
    
  $xml_output = "<rgd_map_raw_data chromosome=\"$chrom\">\n";
  
  my $marker_count = 0;
  
  for $marker_count (0 .. $#rgd_id_list) {
    
    
    

    local ($chr,$id,$pos,$units,$fp,$lod,$rgd) = split /,/,$markers{$rgd_id_list[$marker_count]};
    
    my %alleles = ();
    
    # gets the allele sizes for a given rgd_id and puts them into %alleles
    # keyed by strain_name
    &get_markers_allele_sizes_from_rgd($me,$rgd,\%alleles);
    


    $xml_output .= <<"End_of_XML";
<marker>
  <name>$d_name{$rgd}</name>
  <abs_distance>$pos</abs_distance>
  <f_or_p>$fp</f_or_p>
  <lod>$lod</lod>
End_of_XML

    if($markers_ref) {
      # create the hash relating strain name to allele size {ACI} = 123bp
      # capitalize the first letter
      $markers_ref->{$d_name{$rgd}}{name} = "\u$d_name{$rgd}";
      $markers_ref->{$d_name{$rgd}}{abs_distance} = $pos;
      $markers_ref->{$d_name{$rgd}}{f_or_p} = $fp;
      $markers_ref->{$d_name{$rgd}}{lod} = $lod;
      
    }

    if(keys %alleles) {
      $markers_ref->{$d_name{$rgd}}{in_acp} = 1;
      foreach $strain_id (sort keys %alleles) {
	$xml_output .= "<allele_size strain=\"$strain_id\">$alleles{$strain_id}</allele_size>\n";
	
	if($markers_ref) {
	  # create the hash relating strain name to allele size {ACI} = 123bp
	  $markers_ref->{$d_name{$rgd}}{$strain_id} = $alleles{$strain_id};
	}
	
      }
    }
    else {
      $markers_ref->{$d_name{$rgd}}{in_acp} = 0;
      $xml_output .= "  <no_acp_data/>\n";
    }
    

    $xml_output .= <<"End_of_XML";
</marker>
End_of_XML

  }
  
  $xml_output .= "</rgd_map_raw_data>\n";
  
  if($XML_OUT_FLAG) {
    return $xml_output;
    
  }
  
  
}
