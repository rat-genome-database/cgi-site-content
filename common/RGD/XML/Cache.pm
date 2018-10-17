#!/usr/bin/perl 


####################################
#
# RGD::XML::Cache.pm
#
# Copyright (c) 1999 Simon Twigger, Medical College of Wisconsin,
#
# Basic cache object saving data as pages of XML
# Autodeletes old cache files older than a particular time (see delete_old_files() )
#
####################################


####################################
#
# v0.1     5/27/01
#
#
#
#
#
#
####################################

package RGD::XML::Cache;

$VERSION = 0.1; # put it here before strict.

use strict;
use Carp;
use RGD::XML::Writer;
use RGD::_Initializable;
@RGD::XML::Cache::ISA = qw ( RGD::_Initializable );

# Caching module that writes XML Cache files as pages of records each containing
# _page_length lines
# 
# Calling script passes in a 2D hash keyed by object and then object attribute name
# eg $hash{gene_Rgd_id}{symbol} = "atp1a1"
# Each primary object is then an entry in the XML file with attributes set by the key/value
# pairs.
#
#
# Need writing functions to write the original XML cache files
# and reading functions to read/return the appropriate file and page
#
# original search script passes file name as Process ID (PID) of CGI script, eg. 1234
# each page consists of NUM_LINES and if total number of lines is greater than NUM_LINES
# we need to create more than one page (file) called PID.NUM_LINES.x where x is the page number
#
# Reading function is passed the filename PID.NUM_LINES.x, x-1 or x+1 depending on which
# page the user wants to access, this file is read in and returned as an original hash to the
# calling script which then has to work out how to display the results. Could also pass XML text
# or a reference to an XML object for the calling script to work with...
#

my %chrom_num = (
		 1 => 1,2 => 2,
		 3 => 3,4 => 4,
		 5 => 5,6 => 6,
		 7 => 7,8 => 8,
		 9 => 9,10 => 10,
		 11 => 11,12 => 12,
		 13 => 13,14 => 14,
		 15 => 15,16 => 16,
		 17 => 17,18 => 18,
		 19 => 19,20 => 20,
		 21 => 21,22=> 22,
		 X => 23, Y => 24,
		 UN => 40,
		);

# Which fields require a numerical sort routine
my %sort_types = (
		  lod => "number",
		 );


####################################
#
# new()
#
# Constructor method
#
#####################################

sub _init {
  my ($class, %arg) = @_;
  $class->{_base_url}       = $arg{base_url} ;
  $class->{_cache_dir}      = $arg{cache_directory} ;
  $class->{_cache_file}     = $arg{cache_file}             || "default";
  $class->{_caller}         = $arg{script_name}            || "none_specified";
  $class->{_caller_dir}     = $arg{script_dir};
  $class->{_caller_version} = $arg{script_version}     || "0.00";
  $class->{_page_length}    = $arg{page_length}        || 25; # default number of lines per page
  $class->{_order_field}    = $arg{order_field} || "symbol";
  $class->{_params}         = $arg{parameters};
  $class->{_object}         = $arg{object} || "unspecified"; # allow object type to control thing such as SSLP sorting
  
  # use XML::DOM::Parser;
  $class->{parser} = new XML::DOM::Parser;
  my $xml = "<rgd_cache></rgd_cache>"; # create the initial XML doc element - kludge
  $class->{doc}    = $class->{parser}->parse($xml);

  $class->{writer} = RGD::XML::Writer->new(
					   doc_ref => \$class->{doc},
					  ) ;

  # Set the attributes for the dataset as a whole
  $class->{doc}->getDocumentElement->setAttribute("page_length",$class->{_page_length});
  $class->{doc}->getDocumentElement->setAttribute("script_name",$class->{_caller});
  $class->{doc}->getDocumentElement->setAttribute("script_version",$class->{_caller_version});
  $class->{doc}->getDocumentElement->setAttribute("creation_date", scalar localtime);

  $class->delete_old_files; # clear out old copies of the cache files;
}


# Simple public accessor functions to get logging directory and file
sub get_cache_dir { $_[0]->{_cache_dir} }
sub get_cache_file { $_[0]->{_cache_file} }

# Private accessor fuctions
sub _get_caller { $_[0]->{_caller} }
sub _get_caller_v { $_[0]->{_caller_version} }





####################################
#
# create_cache_file - makes the XML document from the passed Hash ref.
#
#####################################

sub create_cache_file {

  my ($self,$hash_ref) = @_;

  my $page_number = 1; # First page of the cache
  my $row_number = 0; # Count of rows on the page

  
  my $num_hits = keys %{$hash_ref};
  my $total_pages = int($num_hits / $self->{_page_length}); # deals with whole numbers of pages
  if($num_hits % $self->{_page_length}) { $total_pages += 1;} # adds one page for the remaining part of a page

  # create first page
  my $page_el = $self->{writer}->create_element(
						name => "cache_page",
						atts =>{
							number => "$page_number",
							total_pages => "$total_pages",
							page_length => $self->{_page_length},
							number_of_hits => $num_hits,
							file_name => $self->{_cache_file},
							script_name =>  $self->{_caller},
						       },		    
						parent => \$self->{doc}->getDocumentElement,
					       );

  my $param_el = $self->{writer}->create_element(
						 name => "parameters",
						);
  #####
  # For each parameter in the form write it into the XML file for later retrieval as required
  #####
  foreach my $p (sort keys %{$self->{_params}}) {
    
    # warn "$p -> $self->{_params}->{$p} \n";
    my $par_el = $self->{writer}->create_element(
						 name => "$p",
						 text => $self->{_params}->{$p} || "null",		    
						 parent => \$param_el,
						);
  }

  # add a parameter element to first cache_page
  $page_el->appendChild($param_el);

  ######
  # foreach element of the cache, add a new row element to the page, order by db ordering
  #####
 
 
  # Customized sort routine to cope with chromosomes, sslps, numbers and text needing to be sorted differently
  foreach my $obj (sort  {
    
    # If its a numerical sort, sort by number, then by symbol name
    if(($self->{_order_field} eq "chromosome") && ($self->{_object} ne "sslps") ) {
      $chrom_num{ $hash_ref->{$a}->{$self->{_order_field}} } <=> $chrom_num{ $hash_ref->{$b}->{$self->{_order_field}} }
      or
	lc($hash_ref->{$a}->{symbol}) cmp lc($hash_ref->{$b}->{symbol});
    }
    elsif(($self->{_order_field} eq "chromosome") && ($self->{_object} eq "sslps") ) {
      
      $chrom_num{ $hash_ref->{$a}->{$self->{_order_field}} } <=> $chrom_num{ $hash_ref->{$b}->{$self->{_order_field}} }
      or
	&sslp_name_sort($hash_ref->{$a}->{symbol},$hash_ref->{$b}->{symbol});
	
    }
    elsif($self->{_object} eq "sslps") {
       &sslp_name_sort($hash_ref->{$a}->{symbol},$hash_ref->{$b}->{symbol});
    }
    # If its a numerical sort (check contents of field)
    elsif($sort_types{$self->{_order_field}} eq "number") {
      $hash_ref->{$a}->{$self->{_order_field}} <=> $hash_ref->{$b}->{$self->{_order_field}};
    }
    # Text sort can just sort by field
    else {
      lc($hash_ref->{$a}->{$self->{_order_field}}) cmp lc($hash_ref->{$b}->{$self->{_order_field}});
    }
    
  }
		   keys %{$hash_ref}) {
    
    
    # If we have more than a page's worth of rows, go to the next page
    if(($row_number % $self->{_page_length} == 0) && ($row_number)) {
      # should now have the Data in XML format, now write to disk
      # one page's worth
      # Add in some navigation links so we know if there are previous or subsequent pages
      my $prev_el = $self->{writer}->create_element(
						    name => "previous",
						    atts => {
							     page => $page_number-1,
							    },		    
						    parent => \$page_el,
						   );
      my $next_el = $self->{writer}->create_element(
						    name => "next",
						    atts => {
							     page => $page_number+1,
							    },		    
						    parent => \$page_el,
						   );
      
      # add a parameter element to each cache_page
      $page_el->insertBefore($param_el,$prev_el);
      $self->write_cache_file($page_el,$page_number);

      $page_number++;
      
      $page_el = $self->{writer}->create_element(
						 name => "cache_page",
						 atts => {
							  number => "$page_number",
							  total_pages => "$total_pages",
							  page_length => $self->{_page_length},
							  number_of_hits => $num_hits,
							  file_name => $self->{_cache_file},
							 },		    
						 parent => \$self->{doc}->getDocumentElement,
						);
    }
    
    my $row_el = $self->{writer}->create_element(
						 name => "row",
						 atts => {
						   number => "$row_number",
						 },		    
						 parent => \$page_el,
						);
    #####
    # For each attribute for the object, write an element
    #####
    foreach my $att (sort keys %{$hash_ref->{$obj}}) {
      
      # warn "$att -> $hash_ref->{$obj}{$att} \n";
      my $att_el = $self->{writer}->create_element(
						   name => "$att",
						   text => $hash_ref->{$obj}{$att} || "",		    
						   parent => \$row_el,
						  );
    }
    
    
    $row_number++; # increase row count

  } # end of object loop

  
  # Add in some navigation links for the final page so we know
  # there are previous pages but no subsequent ones
  my $prev_el = $self->{writer}->create_element(
						name => "previous",
						atts => {
							 page => $page_number-1,
							},		    
						parent => \$page_el,
					       );
   my $next_el = $self->{writer}->create_element(
						 name => "next",
						 atts => {
							  page => 0,
							 },		    
						 parent => \$page_el,
						);
  # add a parameter element to final cache_page
  $page_el->insertBefore($param_el,$prev_el);
  # write any remaining pages to the cache
  $self->write_cache_file($page_el,$page_number);

  my @page_list = $self->{doc}->getElementsByTagName("cache_page");
  
  return $page_list[0]; # return the first
}

#####
#
# sslp_name_sort - sort SSLP names in a more sensible fashion
#
#####

sub sslp_name_sort {

  my ($n1,$n2) = @_;
  
  # If both symbols are D21rat1 type names, 
  if( ($n1 =~ /^d(\d+|x|y)\D+\d+/i) && ($n2 =~ /^d(\d+|x|y)\D+\d+/i) ) {
    
    # sort by chromosome then by name then by number
    $n1 =~ /^d(\d+|x|y)(\D+)(\d+)/i;
    my $n1_chr = $1;
    my $n1_org = $2;
    my $n1_num = $3;
    
    $n2 =~ /^d(\d+|x|y)(\D+)(\d+)/i;
    my $n2_chr = $1;
    my $n2_org = $2;
    my $n2_num = $3;
    
     $chrom_num{$n1_chr} <=> $chrom_num{$n2_chr}
    or $n1_org cmp $n2_org
      or $n1_num <=> $n2_num;
  }
  else {
     $n1 cmp $n2;
  }
  
}


####################################
#
# retrieve_cache_file
#
#####################################

sub retrieve_cache_file {

  my ($self, $file) = @_;

  # read in the cache XML file, convert to XML, return to the calling script as a <cache_page> element
  # add on appropriate path info infront of the file name
  my $cache_file = scalar $self->get_cache_dir() . "/" .$file;


  warn "Looking for $cache_file \n";
  if(-e $cache_file) { 

    $self->{doc} = $self->{parser}->parsefile($cache_file);
    
    # warn "Retrieving info from $cache_file\n";
    
    my @row_list = $self->{doc}->getElementsByTagName("row");
    # warn " FOund $#row_list rows in the cache file\n";
    return $self->{doc}; # should only be one page here...
  }
  else {
    return 0; # no file exits, tell script to rerun search or warn user
  }

}


####################################
#
# write_cache_file
#
#####################################

sub write_cache_file {
  
  my ($self,$el,$page) = @_;
  
  # First need to open cache file
  my $cachefile = scalar $self->get_cache_dir() . "/" . scalar $self->get_cache_file() . ".$page.cache";
 
  warn "Writing cache file: $cachefile\n";
  open (CACHE, ">$cachefile") or croak "Cant open log file to write: $!";
  
  # lock the file for our exclusive use
  flock(CACHE,2);
  
  # in case someone appended while we were waiting
  # reset the end of file pointer to correct value
  seek (CACHE, 0, 2);

  # $self->{doc}->printToFileHandle(\*CACHE);
  $el->printToFileHandle(\*CACHE);

  # remove the exclusive lock on the cache file
  flock(LOG, 8);

  close LOG;

  return 1;
}

##########
#
# delete_old_files - script to remove out-dated cache files automatically
#
##########


sub delete_old_files {

  my $self = shift(@_);

  my $LIFETIME = 0.3; # Lifetime of files in hours.
  my $LIFE_DAYS = 1/(24/$LIFETIME); # Lifetime in days for -M switch
  
  my @directories = ("$self->{_cache_dir}"); # directories to  check for deleteable files
  
  my %extensions  = (
		     "cache" => 'DEL',		     
		    ); # extensions to delete
  
  
  # foreach directory, check the files, delete those that are older than $LIFETIME
  
  open LOG, ">>$self->{_cache_dir}/reaper_log" or die "Cant open reaper log: $!\n";
  
  $^T = time; # reset script time setting to zero...
  
  for my $dir (0 .. $#directories) {
    
    opendir (DIR, $directories[$dir]) or die "Cant open directory $directories[$dir]: 
$!\n";
    
    my @allfiles =  map "$directories[$dir]/$_",readdir DIR;
    closedir DIR;
    
    for my $file (0 .. $#allfiles) {
      
      $allfiles[$file] =~ /\.(\w+)$/;
      my $suffix = $1 || "None";
      
      chomp $allfiles[$file];
      
      #print LOG "File $allfiles[$file]: age " . -M $allfiles[$file] . "\n";;
      
      if ($extensions{$suffix}) {
	# print LOG "\n.. examining $allfiles[$file]\n";
	print LOG "\n\tDeleting $allfiles[$file]\n" if (-M $allfiles[$file] > $LIFE_DAYS);
	unlink $allfiles[$file]  if (-M $allfiles[$file] > $LIFE_DAYS);
      }
      else {
	# print LOG "Not deleting $suffix: $allfiles[$file]\n";
      }
    }
    
  }
  
  close LOG;
  
}

##########
#
# create_html_navbar - returns HTML code for navigation buttons
#
##########


sub create_html_navbar {

  my ($self,%args) = @_;
  
  my $nav_html = "";
  my $script_url = $self->{_caller_dir} . $self->{_caller};

  warn "Script URL: $script_url\n";

  #####
  # Navigation links to next and previous pages if appropriate
  #####	
  if($args{total_hits} > $self->{_page_length}) {
    $nav_html .= "<table align=\"center\"><TR>";
    if($args{prev}) {
      
      $nav_html .= "<TD><A href=\"$script_url?cache=$self->{_cache_file}.$args{prev}.cache\"><img border=\"0\" src=\"$self->{_base_url}/common/images/left_active.gif\" alt=\"Previous Page\"></a></TD>"
    }
    else {
      $nav_html .= "<TD><img src=\"$self->{_base_url}/common/images/left_inactive.gif\" alt=\"Previous Page\"></TD>"
    }
    
    
    ##
    ## Put a GOOGLE like page listing to allow users to jump around as desired
    ##
    
    my $MAX_PAGES = $args{max_pages} || 20; # most number of pages listed on one screen
    
    my $FIRST = int($args{current} - ($MAX_PAGES/2));
    if($FIRST < 1) {$FIRST = 1; }
    my $LAST = $args{current} + ($MAX_PAGES/2)-1;
    if ($LAST > $args{total_pages}) { $LAST = $args{total_pages}; }
    
    
    for (my $pg=$FIRST; $pg <= $LAST; $pg++) {
      if($pg == $args{current}) {
	$nav_html .= "<td><font color=\"red\">$pg</FONT></td>";
      }
      else {
	$nav_html .= "<td><A href=\"$script_url?cache=$self->{_cache_file}.$pg.cache\">$pg</A></td>";
      }
    }
    
    
    if($args{next}) {
      
      $nav_html .= "<TD><A href=\"$script_url?cache=$self->{_cache_file}.$args{next}.cache\"><img border=\"0\" src=\"$self->{_base_url}/common/images/right_active.gif\" alt=\"Next Page\"></a></TD>"
    }
    else {
      # $nav_html .= "<TD>Next</TD>";
      $nav_html .= "<TD><img src=\"$self->{_base_url}/common/images/right_inactive.gif\" alt=\"Next Page\"></TD>"
    }
    $nav_html .= "</TR></table>\n";
    
  }
  
  return $nav_html
}


# return 1 at the end of the module
1;
