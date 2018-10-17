package RGD::Curation::Submit;
use RGD::Curation;
use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(RGD::Curation);
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '0.01';

#-----------------------------------------------------------
=head1 NAME

RGD::Curation::Submit - Perl extension for data submission 

=head1 SYNOPSIS

  use RGD::Curation::Submit;

=head1 DESCRIPTION

This object is used to RGD data submission.

=head1 AUTHOR

Jian Lu, Email jianlu@mcw.edu

=head1 SEE ALSO

perl(1).

=cut
#----------------------------------------------------------

################################################
#
################################################
sub new {
  my ($class, %arg)  = @_;
  bless {
 	 _data_output  => $arg{outputPATH}   ||"/rgd_home/rgd/TOOLS/curation/submit/pipeline"
 	},$class ;
}

###############################################
#
###############################################
sub get_outputPATH{ 
  return  $_[0]->{_data_output};
}

#----------------------------------------------------------
=head2 object_template 

 Title   : object_template 
 Usage   : $obj->object_template($val)
 Function: to get RGD object template values
 Example :
 Returns : an array containing all attribute names of template
 Args    : $val(required)


=cut
#----------------------------------------------------------

#######################################################
# delete column "MAP_DATA_NOTES".  
# Merge it in Notes column, also create mapping_details date type.
######################################################
sub object_template {
  my ($self,$obj)=@_;
  my @header = undef;

  if($obj eq "GENES"){ # genes template header
    @header = ("SUBMIT_ID", 
		"GENE_RGD_ID",
		"GENE_SYMBOL",
		"FULL_NAME",
		"PRODUCT",
		"FUNCTION",
		"GENE_DESCRIPTION",
		"GENE_NOTES",
		"REF_RGD_ID",
		"CLONE_SEQ_RGD_ID",
		"SEQ_NOTES",       
		"CLONE_NAME",
		"CLONE_SEQUENCE",
		"PRIMER_SEQ_RGD_ID",
		"PRIMER_NAME",
		"FORWARD_SEQ",
		"REVERSE_SEQ",
		"RN_ID",
		"SWISSPROT_ID",
		"NCBI_ID",
		"PUBMED_ID",
		"RHDB_ID",
		"RATMAP_ID",
		"MEDLINE_ID",
		"MGD_ID", 
		"GENBANK_NUCLEOTIDE",
		"GENBANK_PROTEIN",
		"LOCUSLINK_ID",
		"UNIGENE_ID",
		"ALIAS_VALUE",
		"ALIAS_TYPES",
		"ALIAS_NOTES",
		"STRAIN_SYMBOL",
		"STRAIN_RGD_ID",
		"CHROMOSOME",
		"LOD",
		"BAND_TYPE",
		"FISH_BAND",
		"RELATED_GENE_RGD_ID",
		"RELATED_GENE_SYMBOL",
		"GENE_VARIATION_TYPE",
		"GENE_VARIATION_NOTES",
		"NOTES",
		"NOTES_TYPE",
		"HUMAN_HOMOLOG_RGD_ID",
		"HUMAN_HOMOLOG_SYMBOL",
		"HUMAN_HOMOLOG_NAME",
		"HUMAN_CHROMOSOME",
		"MOUSE_HOMOLOG_RGD_ID",
		"MOUSE_HOMOLOG_SYMBOL",
		"MOUSE_HOMOLOG_NAME",
		"MOUSE_CHROMOSOME",
		"SSLP_RGD_ID",
		"SSLP_NAME",
		"QTL_RGD_ID",
		"QTL_SYMBOL",
		"DATASET_REF_RGD_ID",
		"TIGR_ID");
  }
  elsif($obj eq "QTLS") {

     @header = ("SUBMIT_ID",              
		"QTL_RGD_ID",             
		"QTL_SYMBOL",             
		"QTL_NAME",               
		"PEAK_OFFSET",            
		"CHROMOSOME",             
		"LOD",                    
		"P_VALUE",                
		"VARIANCE",               
		"QTL_NOTES",              
		"FLANK_1_RGD_ID",         
		"FLANK_2_RGD_ID",         
		"PEAK_RGD_ID",            
		"INHERITANCE_TYPE",       
		"REF_RGD_ID",             
		"DATASET_REF_RGD_ID",     
		"SEQUENCE_RGD_ID",        
		"PRIMER_SEQ_RGD_ID",      
		"RN_ID",                  
		"SWISSPROT_ID",           
		"NCBI_ID",                
		"PUBMED_ID",              
		"RHDB_ID",               
		"RATMAP_ID",              
		"MEDLINE_ID",             
		"GENBANK_NUCLEOTIDE",     
		"GENBANK_PROTEIN",        
		"LOCUSLINK_ID",           
		"UNIGENE_ID",             
		"ALIAS_VALUE",            
		"ALIAS_TYPES",            
		"ALIAS_NOTES",            
		"STRAIN_SYMBOL",          
		"STRAIN_RGD_ID",          
		"GENE_RGD_ID",            
		"GENE_SYMBOL",            
		"NOTES",                  
		"NOTES_TYPE",             
		"CROSS_PAIRS",            
		"CROSS",                  
		"RELATED_QTLS",           
		"TRAIT_RGD_ID",           
		"TRAIT_NAME",             
		"SUB_TRAIT_NAME",         
		"TRAIT_DESC",             
		"MAP_NAME",               
		"MAP_RGD_ID"             
    )
  }
	elsif($obj eq "STRAINS") {
		 @header = ("SUBMIT_ID",
		"STRAIN_RGD_ID",
		"STRAIN_SYMBOL",
		"FULL_NAME",
		"STRAIN",
		"SUBSTRAIN",
		"STRAIN_TYPE_NAME",
		"GENETICS",
		"INBRED_GEN",
		"ORIGIN",
		"COLOR",
		"CHARACTERISTICS",
		"REPRODUCTION",
		"BEHAVIOR",
		"LIFE_DISEASE",
		"ANATOMY",
		"INFECTION",
		"IMMUNOLOGY",
		"PHYS_BIOCHEM",
		"DRGS_CHEMS",
		"CHR_ALTERED",
		"SOURCE",
		"NOTES",
		"NOTES_TYPE",
		"GENE_RGD_ID",
		"GENE_SYMBOL",
		"SSLP_RGD_ID",
		"SSLP_SYMBOL",
		"QTL_RGD_ID",
		"QTL_SYMBOL",
		"ALIAS_VALUE",
		"ALIAS_TYPES",
		"NOTE_REF_ID",
		"DATASET_REF_RGD_ID",
		"STRAIN_NOTES",
		"RN_ID",
		"SWISSPROT_ID",
		"NCBI_ID",
		"PUBMED_ID",
		"RHDB_ID",
		"RATMAP_ID",
		"MEDLINE_ID",
		"MGD_ID",
		"GENBANK_NUCLEOTIDE",
		"GENBANK_PROTEIN",
		"LOCUSLINK_ID",
		"UNIGENE_ID",
		"MAP_RGD_ID",
		"MAP_NAME",
		"ALIAS_NOTES",
		"CLONE_SEQ_RGD_ID",
		"CLONE_NAME",
		"REF_RGD_ID"		 
	 );
	 }
  return @header;
}

 #######################################################

