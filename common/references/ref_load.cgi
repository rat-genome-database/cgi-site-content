#!/usr/bin/perl

################
#
# perl script to load pubmed refs into RGD from a file
#
#
################

use lib "/rgd/TOOLS/common/";
use strict;
use Loadrefs;


my $INPUT = shift @ARGV; #input file

my $load_obj = Loadrefs->new();

print "$INPUT\n";

open (IN, "$INPUT") || die "Cant open file to read in: $!\n";


my $data = "";
while (<IN>) {
  $data .= $_;
}


$load_obj->load_refs($data);


exit;
