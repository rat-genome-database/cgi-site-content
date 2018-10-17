#!/usr/bin/perl

use strict;
use vars qw($opt_i);
use Getopt::Std; # pass command line options into script
use CGI;

my $annotationFile = "all_locations.txt";
open(ANNOT, $annotationFile) or die "Cant open $annotationFile: $!\n";
my %annotations = ();

# read all the annotations into memory, then check the list of ids
while(<ANNOT>) {
	chomp;
	my @map_data = split(/\t/, $_);

	$annotations{$map_data[0]}{'symbol'} = $map_data[1];
	$annotations{$map_data[0]}{'type'} = $map_data[2];
	$annotations{$map_data[0]}{'chromosome'} = $map_data[3];
	$annotations{$map_data[0]}{'start'} = $map_data[4];
	$annotations{$map_data[0]}{'end'} = $map_data[5];

}
close ANNOT;


my $form = CGI->new;

my $id_string = $form->param("dbIds");# || "61928__2275__70226__61376__61379__621066__634340__70160__61906__70163__62024__70179__3181__"; # default to RGD ID for A2m

warn "Got $id_string from CGI\n";
warn "Searching for genomic locations for: $id_string\n";

my $annotationXML = "<?xml version='1.0' standalone='yes'?><genome>";


my $link;
my @ids = split(/\_\_/,$id_string);

for my $i (0 .. $#ids)  {
	warn "Checking $ids[$i]\n";

	if($annotations{$ids[$i]}{'symbol'} ne undef) {

		# To link to RGD for QTL and GENE chift clicks within the Flash Gviewer
		$annotationXML .= "<feature><chromosome>$annotations{$ids[$i]}{'chromosome'}</chromosome><start>$annotations{$ids[$i]}{'start'}</start><end>$annotations{$ids[$i]}{'end'}</end><type>$annotations{$ids[$i]}{'type'}</type><label>$annotations{$ids[$i]}{'symbol'}</label><link>/generalSearch/RgdSearch.jsp?quickSearch=1%26searchKeyword=$ids[$i]</link></feature>";
		# To link to PGA use the following 2 lines and comment out the one above
		#$link  = 'http://pga.mcw.edu/pga2-bin/summary_stat_list.cgi?atm=NMX%26diet=HS%26gender=M%26pheno=BASE_MAP_NE%7cbaseline%20MAP%20for%20NE%20dose-response%20relationship%20%28mmHg%29%26protocol=RENAL_A%26vtype=MEAN%26strain=BN,SS,FHH,LEW,CDF,CDIGS,GH,SHR,SPRD,WKY%2a%2a1';

		#$annotationXML .= "<feature><chromosome>$annotations{$ids[$i]}{'chromosome'}</chromosome><start>$annotations{$ids[$i]}{'start'}</start><end>$annotations{$ids[$i]}{'end'}</end><type>$annotations{$ids[$i]}{'type'}</type><label>$annotations{$ids[$i]}{'symbol'}</label><link>$link</link></feature>";

	}
}


$annotationXML .= "</genome>";


###replaced avbove '&' to '%26'


print "Content-type: text/plain\n\n";
# print "<html><body>\n";

print $annotationXML;

# print "</body></html>";

exit;

