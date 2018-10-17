#!/usr/bin/perl

#####################################################################################
# File Name:	strainSubmit.cgi													#
# Usage:		this tool will sent	message for users								#
# Author:		Henry Fan															#
# Date:			05/22/2003															#
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;
use MIME::Lite;
use CGI qw(:standard);
use strict;

my $form = new CGI;
my $html = RGD::HTML->new();

# get form parameters on contact information
my $authorLName = $form->param('authorLName');    
my $authorFName = $form->param('authorFName');
my $authorMName = $form->param('authorMName');
my $authorEmail = $form->param('authorEmail');
my $authorOrganization = $form->param('authorOrganization');
my $authorAddress = $form->param('authorAddress');
my $authorCity = $form->param('authorCity');
my $authorState = $form->param('authorState');
my $authorPostalCode = $form->param('authorPostalCode');
my $authorCountry = $form->param('authorCountry');    
my $authorPhone = $form->param('authorPhone');
my $authorFax = $form->param('authorFax');
my $userLname = $form->param('userLname');
my $userFname = $form->param('userFname');
my $userMname = $form->param('userMname');
my $userEmail = $form->param('userEmail');
my $count=$form->param('count');
my $action=$form->param('action');

# get form parameters on strain information

my @code=undef;
my @strain=undef;
my @subStrain=undef;
my @fullName=undef;
my @strainType=undef;
my @geneticMarker=undef;
my @strainColor=undef;
my @generation=undef;
my @strainOrigin=undef;
my @reproduction=undef;
my @characterics=undef;
my @disease=undef;
my @anatomy=undef;
my @infection=undef;
my @immunology=undef;
my @biochemistry=undef;
my @chemical=undef;
my @chromosome=undef;
my @market1=undef;
my @market2=undef;
my @noteType=undef;
my @geneRgdID=undef;
my @geneSymbol=undef;
my @SSLPRgdID=undef;
my @SSLPSymbol=undef;
my @QTLRgdID=undef;
my @QTLSymbol=undef;
my @strainSource=undef;

for(my $j=0; $j<$count; $j++) {
	my $code = $form->param("code$j"); 
	my $strain = $form->param("strain$j");
	my $subStrain = $form->param("subStrain$j");
	my $fullName = $form->param("fullName$j");
	my $strainType = $form->param("strainType$j");
	my $geneticMarker = $form->param("geneticMarker$j");
	my $strainColor  = $form->param("strainColor$j");
	my $generation = $form->param("generation$j");
	my $strainOrigin = $form->param("strainOrigin$j");
	my $reproduction = $form->param("reproduction$j");    
	my $characterics = $form->param("characterics$j");
	my $disease = $form->param("disease$j");
	my $anatomy = $form->param("anatomy$j");
	my $infection = $form->param("infection$j");
	my $immunology  = $form->param("immunology$j");
	my $biochemistry = $form->param("biochemistry$j");    
	my $chemical = $form->param("chemical$j");
	my $chromosome = $form->param("chromosome$j");
	my $market1 = $form->param("market1$j");
	my $market2 = $form->param("market2$j");
	my $noteType = $form->param("noteType$j");
	my $geneRgdID  = $form->param("geneRgdID$j");
	my $geneSymbol = $form->param("geneSymbol$j");
	my $SSLPRgdID = $form->param("SSLPRgdID$j");
	my $SSLPSymbol = $form->param("SSLPSymbol$j");    
	my $QTLRgdID = $form->param("QTLRgdID$j");
	my $QTLSymbol = $form->param("QTLSymbol$j");
	my $strainSource = $form->param("strainSource$j");
	push (@code, $code);
	push (@strain, $strain);
	push (@subStrain, $subStrain);
	push (@fullName, $fullName);
	push (@strainType, $strainType);
	push (@geneticMarker, $geneticMarker);
	push (@strainColor, $strainColor);
	push (@generation, $generation);
	push (@strainOrigin, $strainOrigin);
	push (@reproduction, $reproduction);
	push (@characterics, $characterics);
	push (@disease, $disease);
	push (@anatomy, $anatomy);
	push (@infection, $infection);
	push (@immunology, $immunology);
	push (@biochemistry, $biochemistry);
	push (@chemical, $chemical);
	push (@chromosome, $chromosome);
	push (@market1, $market1);
	push (@market2, $market2);
	push (@noteType, $noteType);
	push (@geneRgdID, $geneRgdID);
	push (@geneSymbol, $geneSymbol);
	push (@SSLPRgdID, $SSLPRgdID);
	push (@SSLPSymbol, $SSLPSymbol);
	push (@QTLRgdID, $QTLRgdID);
	push (@QTLSymbol, $QTLSymbol);
	push (@strainSource, $strainSource);
}
shift (@code);
shift (@strain);
shift (@subStrain);
shift (@fullName);
shift (@strainType);
shift (@geneticMarker);
shift (@strainColor);
shift (@generation);
shift (@strainOrigin);
shift (@reproduction);
shift (@characterics);
shift (@disease);
shift (@anatomy);
shift (@infection);
shift (@immunology);
shift (@biochemistry);
shift (@chemical);
shift (@chromosome);
shift (@market1);
shift (@market2);
shift (@noteType);
shift (@geneRgdID);
shift (@geneSymbol);
shift (@SSLPRgdID);
shift (@SSLPSymbol);
shift (@QTLRgdID);
shift (@QTLSymbol);
shift (@strainSource);

my $rootPath=$html->get_dataPATH; 
my $filePath=$rootPath."/strains/";
my $fileName="submitData_".$userFname."_".$userLname.".txt";
my $file=$filePath.$fileName;

$html->html_head;
$html->tool_start;

if($action eq "send"){
	&display_message_sent;
	&write_data;
	&send_mail;
}
if($action eq "leave"){
	&display_message_leave;

}

$html->tool_end;
$html->html_foot;


#########################################################################
# write_data: write the parameters from form into a text file			#
#########################################################################
sub write_data{

	my $title="Laboratory_code\tStrain\tSubstrain\tFull_name\tStrain_type\tGenetic_Markers\tstrain_color\t";
	   $title.="Inbred_Generations\tstrainOrigin\treproduction\tcharacterics\tdisease\tanatomy\t";
       $title.="infection\timmunology\tbiochemistry\tchemical\tchromosome\tmarket1\tmarket2\tnoteType\t";
       $title.="geneRgdID\tgeneSymbol\tSSLPRgdID\tSSLPSymbol\tQTLRgdID\tQTLSymbol\tstrainSource\t\n";

	my $data=undef;

	open (OUT,">$file")|| die "can not open the data file:$!\n";

	print OUT $title;
	for(my $i=0; $i<=$#strain; $i++) {

		if($strainType[$i] eq "related inbred"){
			$strainType[$i]="related_inbred";
		}
		if($strainType[$i] eq "recombinant inbred"){
			$strainType[$i]="recombinant_inbred";
		}
		if($strainType[$i] eq "segregating inbred"){
			$strainType[$i]="segregating_inbred";
		}

		$data=$code[$i]."\t".$strain[$i]."\t".$subStrain[$i]."\t".$fullName[$i]."\t".$strainType[$i]."\t".$geneticMarker[$i]."\t".$strainColor[$i]."\t";
		$data.=$generation[$i]."\t".$strainOrigin[$i]."\t".$reproduction[$i]."\t".$characterics[$i]."\t".$disease[$i]."\t".$anatomy[$i]."\t";
		$data.=$infection[$i]."\t".$immunology[$i]."\t".$biochemistry[$i]."\t".$chemical[$i]."\t".$chromosome[$i]."\t".$market1[$i]."\t".$market2[$i]."\t";
		$data.=$noteType[$i]."\t".$geneRgdID[$i]."\t".$geneSymbol[$i]."\t".$SSLPRgdID[$i]."\t".$SSLPSymbol[$i]."\t".$QTLRgdID[$i]."\t".$QTLSymbol[$i]."\t".$strainSource[$i]."\t\n"; 
		
		print OUT $data;
		$data="";
	}

	close(OUT);

}

#########################################################################
# send_mail: send an e-mail notification to curator after				#
#			 the new data file is generated								#
#########################################################################
sub send_mail{

	my $mailMessage ="<HTML><BODY><P>Dear RGD Curator:<br><br>";
	   $mailMessage.="<P>I submit a strain data file in the attachment and the contact information is as below:<br><br>";
       $mailMessage.="<p><b>Author Name:			 ".$authorFName."\t".$authorLName."<br>";
       $mailMessage.="Author Email Address:  ".$authorEmail."<br>";
       $mailMessage.="Author Organization:   ".$authorOrganization."<br>";
       $mailMessage.="Author Address:        ".$authorAddress."\t".$authorCity."\t".$authorState."\t".$authorPostalCode."<br>";
       $mailMessage.="Author Phone:          ".$authorPhone."<br>";
       $mailMessage.="Author Fax:            ".$authorFax."<br>";
       $mailMessage.="User Name:             ".$userFname."\t".$userLname."<br>";
       $mailMessage.="User Email Address:    ".$userEmail."<br>";
       $mailMessage.="</b></P></BODY></HTML>";

    my $msg = MIME::Lite->new(
                 From    =>$userEmail,
                 To      =>'cfan@mcw.edu',
                 Cc      =>'cfan@mcw.edu',
                 Subject =>'Strain Submit Form',
                 Type    =>'text/html',
				 Data    =>$mailMessage
                );

    $msg->attach(Type     =>'TEXT',
                 Path     =>$file,
                 Filename =>$fileName,
				 #Data     =>'test'
                 ); 

    $msg->send; 
}

#########################################################################
#display_message_sent: display message for users		
#########################################################################
sub display_message_sent{

	my $message="Your strain submit data have been sumbitted to RGD curators. Thanks for your time.";
	print "<table border='0' width='100%' align='center'>";
	print "<tr><td><b><font size='6' color='black'><CENTER>Strain Submission Form</CENTER></font></b></td></tr>";
	print "</table>";
	print "<p><center><font size=\"4\" color=\"blue\"><br><br><br>$message<br></center></font>";

}

#########################################################################
#display_message_leave: display message for users		
#########################################################################
sub display_message_leave{

	my $message="Your strain submit data have NOT been sumbitted to RGD curators. You are welcomed next time.";
	print "<table border='0' width='100%' align='center'>";
	print "<tr><td><b><font size='6' color='black'><CENTER>Strain Submission Form</CENTER></font></b></td></tr>";
	print "</table>";
	print "<p><center><font size=\"4\" color=\"blue\"><br><br><br>$message<br></center></font>";	
}

########################################### end script ###################