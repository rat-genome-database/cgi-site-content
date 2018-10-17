#!/usr/bin/perl
use lib "/rgd/tools/common";

use RGD::DB;
use RGD::HTML;
use Data::Dumper;
#use RGD::GO;
use CGI qw(:standard);
use strict;
use File::Path;

my $VERSION = 1.1; # New version 1.1 9/8/00
my $form = new CGI;

my $id      = $form->param('id')  || 2018; #die "No ID value was provided\n";

my $html = RGD::HTML->new(
                          title => "RGD Array Report",
                          doc_title  => "",
                          link_dir   => "genes",
                          category  => "data",
                         );

$html->html_head;
$html->tool_start;


if ($id =~ m/^\d+$/) {
}else {
   print "ERROR: id field must be numeric";
   exit 0;
}


my $db = RGD::DB->new();


# remove any RGD: tag from the start of the ID
$id =~ s/RGD://;

print  "<HR>\n";
print '<link rel="stylesheet" type="text/css" href="/common/style/rgd_styles.css">';
print "<p><table>\n";
my %gene_info = &get_gene_name_symbol($id);
my $species = &get_species($id);
  print  "<tr valign=\"top\"><td class=\"subsectionTitle\">Gene:</td><td colspan='3'>";
  print  "<table cellspacing=\"0\" width=\"100%\">";
  print "<tr ><td class=\"objectSymbol\" colspan='2'> $gene_info{gene_symbol} ( $species ) </td></tr>";
  print  "<tr ><td class=\"objectName\" colspan='2'>$gene_info{full_name}&nbsp;<a href=/tools/genes/genes_view.cgi?id=$id>(back to gene page...) </a></td></tr>";
  print "</table></td></tr>";

  my %aliases = $db->get_rgd_id_alias($id);
  my $alias_other = "";
  my $alias_symbol_name = "";

  if ($aliases{$id}) {
    foreach my $key (keys %{ $aliases{$id}}) {
      if(($aliases{$id}{$key}{alias_type_name_lc} eq "old_gene_symbol" )|| ($aliases{$id}{$key}{alias_type_name_lc} eq "old_gene_name" )) {
        $alias_symbol_name .= "$aliases{$id}{$key}{alias_value}; "; #DP 7-16-02
      }
      elsif($aliases{$id}{$key}{alias_type_name_lc} =~ m/array_id/ ) {
      }
      else {
        $alias_other .= "$aliases{$id}{$key}{alias_value}; ";#DP 7-16-02
      }
    }
   chop     $alias_symbol_name;  #DP 7-16-02
   chop     $alias_other;    #DP 7-16-02
  }
  if($alias_symbol_name || $alias_other ) {
      print "<tr valign=\"top\"><td class=\"subsectionTitle\">Synonyms:</td><td class=\"synonymRow\" colspan='3'>";
      print "$alias_symbol_name"."</td></tr>" ;#dp 9-23-03
  }
  print "<tr valign=\"top\"><td class=\"subsectionTitle\">Array IDs:</td>";
my %arrays = &get_array($id);
  if(%arrays) {
     my %arrays_temp=(); 
     print "<td>ProbeSetID</td><td class=\"arrayRow\">ChipType</td><td>Source</td></tr>";
     foreach my $manufacturer (keys %arrays) {
       print "<tr valign=\"top\"><td class=\"subsectionTitle\">$manufacturer:</td></tr>";
       %arrays_temp=%{$arrays{$manufacturer}};
       
       foreach my $probeset_id (keys %arrays_temp) {
           my $length = $#{$arrays{$manufacturer}{$probeset_id}};
           print  "<tr valign=\"top\"><td></td><td class=\"arrayRow\">$probeset_id</td><td>";
           print join( ",", @{$arrays{$manufacturer}{$probeset_id}}) ;
           print "<td>";
           my $bool_ensembl=0; 
           my $bool_affymetrix=0; 
           foreach( @{$arrays{$manufacturer}{$probeset_id}} ) { 
             if($manufacturer =~ m/Affymetrix/){ 
               if( $_ =~ m/affy/) {
                if($bool_ensembl==0){ 
                  print "Ensembl&nbsp;";
                  $bool_ensembl=1;
                }    
               }
               else { 
                if($bool_affymetrix==0){ 
                  print "Affymetrix&nbsp;";    
                  $bool_affymetrix=1;
                }    
               }
             }
             if(($manufacturer =~ m/Codelink/) || ($manufacturer =~ m/Agilent/)){  
                  print "Ensembl";    
             }
           }
           print "</td></tr>";
       } 
     }
  }

print "</table></p></HR>";

sub get_gene_name_symbol {
  my $id = shift @_;
  my %results = ();
  my $sql = "select g.full_name,g.gene_symbol from genes g where g.rgd_id=$id"; 
   my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute() or die "Can't execute statement: $DBI::errstr";

  my ($name,$symbol)  =  $sth->fetchrow_array() ;
  $results{full_name}=$name; 
  $results{gene_symbol}=$symbol; 
  return %results; 
}

sub get_species {
  my $id = shift @_;
  my $result = "";
  my $sql = "select r.species_type_key from rgd_ids r where r.rgd_id=$id and r.object_key=1"; 
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute() or die "Can't execute statement: $DBI::errstr";

  my $species_type_key  =  $sth->fetchrow_array() ;
  if($species_type_key == 1){
    $result = "Homo sapiens";
  } 
  elsif($species_type_key == 2){
    $result = "Mus musculus";
  } 
  elsif($species_type_key == 3){
    $result = "Rattus norvegicus";
  } 
  return $result; 
}

sub get_array {
  my $id = shift @_;
  my %results = ();
  my $sql = "select a.alias_type_name_lc,a.alias_value from aliases a where a.rgd_id=$id and a.alias_type_name_lc like 'array_id%'"; 
  my $sth = $db->{dbh}->prepare($sql) or die "Can't Prepare statement: $DBI::errstr";
  $sth->execute() or die "Can't execute statement: $DBI::errstr";

  my @alias_typearr=(); 
  while (my ($alias_type,$alias_value)  =  $sth->fetchrow_array() ) {
    $alias_type =~ s/array_id_//; 
    if ($alias_type =~ m/Affymetrix/) {
      $alias_type =~ s/_Affymetrix//; 
      push @{ $results{Affymetrix}{$alias_value} }, $alias_type;
    }
    elsif ($alias_type =~ m/Ensembl/) {
      $alias_type =~ s/_Ensembl//; 
     if ($alias_type =~ m/^affy/)  {
      push @{ $results{Affymetrix}{$alias_value} }, $alias_type;
     }
     if ($alias_type =~ m/^agilent/) {
       push @{ $results{Agilent}{$alias_value} }, $alias_type;
     }
     if ($alias_type =~ m/^codelink/) {
       push @{ $results{Codelink}{$alias_value} }, $alias_type;
     }
    }
  }
  return %results;
}

$html->tool_end;
$html->html_foot;
exit 0;


