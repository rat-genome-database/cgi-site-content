#!/usr/bin/perl

#####################################################################################
# File Name:	strainConfirmation.cgi												#
# Usage:		this tool will display the stain data and conrtact data for user to #
#				confirm																#
# Author:		Henry Fan															#
# Date:			05/21/2003															#
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;
use CGI qw(:standard);
use strict;

my $form = new CGI;
my $html = RGD::HTML->new();
my $action=undef;

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

# get form parameters on strain information
my @code = $form->param('code');    
my @strain = $form->param('strain');
my @subStrain = $form->param('subStrain');
my @fullName = $form->param('fullName');
my @strainType = $form->param('strainType');
my @geneticMarker = $form->param('geneticMarker');
my @strainColor  = $form->param('strainColor');
my @generation = $form->param('generation');
my @strainOrigin = $form->param('strainOrigin');
my @reproduction = $form->param('reproduction');    
my @characterics = $form->param('characterics');
my @disease = $form->param('disease');
my @anatomy = $form->param('anatomy');
my @infection = $form->param('infection');
my @immunology  = $form->param('immunology');
my @biochemistry = $form->param('biochemistry');    
my @chemical = $form->param('chemical');
my @chromosome = $form->param('chromosome');
my @market1 = $form->param('market1');
my @market2 = $form->param('market2');
my @noteType = $form->param('noteType');
my @geneRgdID  = $form->param('geneRgdID');
my @geneSymbol = $form->param('geneSymbol');
my @SSLPRgdID = $form->param('SSLPRgdID');
my @SSLPSymbol = $form->param('SSLPSymbol');    
my @QTLRgdID = $form->param('QTLRgdID');
my @QTLSymbol = $form->param('QTLSymbol');
my @strainSource = $form->param('strainSource');

$html->html_head;
$html->tool_start;

print "<HTML><HEAD><TITLE> Public Strains data submit </TITLE></HEAD>";
print "<BODY>";
print "<table border='0' width='100%' align='center'>";
print "<tr><td><b><font size='6' color='black'><CENTER>Strain Submission Form</CENTER></font></b></td></tr>";
print "</table>";
print "<form method=POST action='strainSubmit.cgi'>";
print "<input type=hidden name=authorLName value='$authorLName'>";
print "<input type=hidden name=authorFName value='$authorFName'>";
print "<input type=hidden name=authorFName value='$authorMName'>";
print "<input type=hidden name=authorEmail value='$authorEmail'>";
print "<input type=hidden name=authorOrganization value='$authorOrganization'>";
print "<input type=hidden name=authorAddress value='$authorAddress'>";
print "<input type=hidden name=authorCity value='$authorCity'>";
print "<input type=hidden name=authorState value='$authorState'>";
print "<input type=hidden name=authorPostalCode value='$authorPostalCode'>";
print "<input type=hidden name=authorCountry value='$authorCountry'>";
print "<input type=hidden name=authorPhone value='$authorPhone'>";
print "<input type=hidden name=authorFax value='$authorFax'>";
print "<input type=hidden name=userLname value='$userLname'>";
print "<input type=hidden name=userFname value='$userFname'>";
print "<input type=hidden name=userMname value='$userMname'>";
print "<input type=hidden name=userEmail value='$userEmail'>";
print "<input type=hidden name=count value='$count'>";

for(my $j=0; $j<$count; $j++) {
	print "<input type=hidden name=code$j value='$code[$j]'>";
	print "<input type=hidden name=strain$j value='$strain[$j]'>";
	print "<input type=hidden name=subStrain$j value='$subStrain[$j]'>";
	print "<input type=hidden name=fullName$j value='$fullName[$j]'>";
	print "<input type=hidden name=strainType$j value='$strainType[$j]'>";
	print "<input type=hidden name=geneticMarker$j value='$geneticMarker[$j]'>";
	print "<input type=hidden name=strainColor$j value='$strainColor[$j]'>";
	print "<input type=hidden name=generation$j value='$generation[$j]'>";
	print "<input type=hidden name=strainOrigin$j value='$strainOrigin[$j]'>";
	print "<input type=hidden name=reproduction$j value='$reproduction[$j]'>";
	print "<input type=hidden name=characterics$j value='$characterics[$j]'>";
	print "<input type=hidden name=disease$j value='$disease[$j]'>";
	print "<input type=hidden name=anatomy$j value='$anatomy[$j]'>";
	print "<input type=hidden name=infection$j value='$infection[$j]'>";
	print "<input type=hidden name=immunology$j value='$immunology[$j]'>";
	print "<input type=hidden name=biochemistry$j value='$biochemistry[$j]'>";
	print "<input type=hidden name=chemical$j value='$chemical[$j]'>";
	print "<input type=hidden name=chromosome$j value='$chromosome[$j]'>";
	print "<input type=hidden name=market1$j value='$market1[$j]'>";
	print "<input type=hidden name=market2$j value='$market2[$j]'>";
	print "<input type=hidden name=noteType$j value='$noteType[$j]'>";
	print "<input type=hidden name=geneRgdID$j value='$geneRgdID[$j]'>";
	print "<input type=hidden name=geneSymbol$j value='$geneSymbol[$j]'>";
	print "<input type=hidden name=SSLPRgdID$j value='$SSLPRgdID[$j]'>";
	print "<input type=hidden name=SSLPSymbol$j value='$SSLPSymbol[$j]'>";
	print "<input type=hidden name=QTLRgdID$j value='$QTLRgdID[$j]'>";
	print "<input type=hidden name=QTLSymbol$j value='$QTLSymbol[$j]'>";
	print "<input type=hidden name=strainSource$j value='$strainSource[$j]'>";
}

print "<p><font size=2>Here is the information you want to submit for your confirmation, please click send button if you want to submit or click leave button if you don't.</font><br><br>";

#contact table
my $width1="25%";

print "<table border='1' width='700'>";
print "<tr><td colspan=2 bgcolor='#cccccc'><center>Contact Information</center></td></tr>";
print "<tr><td width='$width1'>The name of the PI</td><td>$authorFName &nbsp; $authorMName &nbsp; $authorLName</td></tr>";
print "<tr><td width='$width1'>E-mail address of the PI</td><td>$authorEmail</td></tr>";
print "<tr><td width='$width1'>Institute/Organization</td><td>$authorOrganization</td></tr>";
print "<tr><td width='$width1'>Address</td><td>$authorAddress &nbsp;$authorCity &nbsp;$authorState &nbsp;$authorPostalCode $authorCountry</td></tr>";
print "<tr><td width='$width1'>Telephone number</td><td>$authorPhone</td></tr>";
print "<tr><td width='$width1'>Fax number</td><td>$authorFax</td></tr>";
print "<tr><td width='$width1'>The name of the submitter</td><td>$userFname &nbsp; $userMname &nbsp; $userLname</td></tr>";
print "<tr><td width='$width1'>E-mail address of the submitter</td><td>$userEmail</td></tr>";
print "</table><br>";

#data table
print "<table border='1' width='700'>";

my $cn=$count+1;
my $width=75/$count."%";

print "<tr><td colspan=$cn bgcolor='#cccccc'><center>Strain Information</center></td></tr>";

print "<tr><td width='$width1'>code</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$code[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Strain</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$strain[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Substrain</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$subStrain[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Full name</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$fullName[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Strain type</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$strainType[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Genetic Markers</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$geneticMarker[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Strain color</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$strainColor[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Inbred Generations #</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$generation[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Strain Origin </td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$strainOrigin[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Reproduction</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$reproduction[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>General Characteristics</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$characterics[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Lifespan and Spontaneous Disease</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$disease[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Anatomy</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$anatomy[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Infection</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$infection[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Immunology</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$immunology[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Physiology and Biochemistry</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$biochemistry[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Drugs and Chemicals</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$chemical[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Chromosome Altered</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$chromosome[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Flank Marker 1</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$market1[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Flank Marker 2</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$market2[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Notes Type</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$noteType[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>GENE RGD ID</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$geneRgdID[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>GENE Symbol </td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$geneSymbol[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>SSLP RGD ID</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$SSLPRgdID[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>SSLP Symbol</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$SSLPSymbol[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>QTL RGD ID</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$QTLRgdID[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>QTL Symbol</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$QTLSymbol[$j]</td>";		
}
print "</tr>";

print "<tr><td width='$width1'>Source of Strain</td>";
for(my $j=0; $j<$count; $j++){
	print "<td width=$width>$strainSource[$j]</td>";		
}
print "</tr>";

print "</table>";
print "<p><center><INPUT type=submit name=action value=send>&nbsp;&nbsp;&nbsp;<INPUT type=submit  name=action value=leave></center>";
print "<P><font size=2 color='black'><center>Once you submit this completed form, the RGD_ID for this strain will be emailed to you! Thank you.</center></P></font>";
print "</form>";
print "</BODY>";
print "</HTML>";

$html->tool_end;
$html->html_foot;

##########################################################################################################################