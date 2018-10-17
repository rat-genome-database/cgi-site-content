#!/usr/bin/perl

#####################################################################################
# File Name:	qtlRegistrationConfirmation.cgi									#
# Usage:		this tool will display the data for user to confirm					#
# Author:		Henry Fan, Pete Bazeley															#
# Date:			05/21/2003															#
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;
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

my $qtl_symbol=$form->param('qtl_symbol');
my $qtl_name=$form->param('qtl_name');
my $trait=$form->param('trait');
my $subtrait=$form->param('subtrait');
my $trait_description=$form->param('trait_description');
my $strains_crossed_1=$form->param('strains_crossed_1');
my $strains_crossed_2=$form->param('strains_crossed_2');
my $chromosome=$form->param('chromosome');
my $lod_score=$form->param('lod_score');
my $peak_marker=$form->param('peak_marker');
my $peak_marker_type=$form->param('peak_marker_type');
my $flank_1=$form->param('flank_1');
my $flank_1_type=$form->param('flank_1_type');
my $flank_2=$form->param('flank_2');
my $flank_2_type=$form->param('flank_2_type');
my $candidate_gene=$form->param('candidate_gene');
my $reference=$form->param('reference');
my $comments=$form->param('comments');

my $public=$form->param('public');

$html->html_head;
$html->tool_start;

print "<HTML><HEAD><TITLE> Public QTL data submit </TITLE></HEAD>";
print "<BODY>";
print "<form method=POST action=qtlRegistrationSubmit.cgi>";
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
print "<input type=hidden name=public value='$public'>";

print "<input type=hidden name=qtl_symbol value='$qtl_symbol'>";
print "<input type=hidden name=qtl_name value='$qtl_name'>";
print "<input type=hidden name=trait value='$trait'>";
print "<input type=hidden name=subtrait value='$subtrait'>";
print "<input type=hidden name=trait_description value='$trait_description'>";
print "<input type=hidden name=strains_crossed_1 value='$strains_crossed_1'>";
print "<input type=hidden name=strains_crossed_2 value='$strains_crossed_2'>";
print "<input type=hidden name=chromosome value='$reference'>";
print "<input type=hidden name=lod_score value='$lod_score'>";
print "<input type=hidden name=peak_marker value='$peak_marker'>";
print "<input type=hidden name=peak_marker_type value='$peak_marker_type'>";
print "<input type=hidden name=flank_1 value='$flank_1'>";
print "<input type=hidden name=flank_2 value='$flank_2'>";
print "<input type=hidden name=flank_1_type value='$flank_1_type'>";
print "<input type=hidden name=flank_2_type value='$flank_2_type'>";
print "<input type=hidden name=candidate_gene value='$candidate_gene'>";
print "<input type=hidden name=reference value='$reference'>";
print "<input type=hidden name=comments value='$comments'>";

print "<p><center><font size=3 color=black><B><font size=6 color='black'>QTL Registration Form</font><br></B></font></center>";
print "<p>Here is the information you want to submitted for your confirmation. Please press the sent button if you want to submit or press the leave if you don't.<br><br>";

#table
my $width1="25%";

print "<table border='1' width='700'>";
print "<tr><td colspan=2 bgcolor='#cccccc'><center><font color='black' size=3>Contact Information</font></center></td></tr>";
print "<tr><td width='$width1'>The name of the PI</td><td>$authorFName &nbsp; $authorMName &nbsp; $authorLName</td></tr>";
print "<tr><td width='$width1'>E-mail address of the PI</td><td>$authorEmail</td></tr>";
print "<tr><td width='$width1'>Institute/Organization</td><td>$authorOrganization</td></tr>";
print "<tr><td width='$width1'>Address</td><td>$authorAddress &nbsp;$authorCity &nbsp;$authorState &nbsp;$authorPostalCode $authorCountry</td></tr>";
print "<tr><td width='$width1'>Telephone number</td><td>$authorPhone</td></tr>";
print "<tr><td width='$width1'>Fax number</td><td>$authorFax</td></tr>";
print "<tr><td width='$width1'>The name of the submitter</td><td>$userFname &nbsp; $userMname &nbsp; $userLname</td></tr>";
print "<tr><td width='$width1'>E-mail address of the submitter</td><td>$userEmail</td></tr>";
print "<tr><td colspan=2 bgcolor='#cccccc'><center>QTL Information</center></td></tr>";

print "<tr><td width='$width1'>QTL Symbol</td><td>$qtl_symbol</td></tr>";
print "<tr><td width='$width1'>QTL Name</td><td>$qtl_name</td></tr>";
print "<tr><td width='$width1'>Trait</td><td>$trait</td></tr>";
print "<tr><td width='$width1'>Subtrait</td><td>$subtrait</td></tr>";
print "<tr><td width='$width1'>Trait Description</td><td>$trait_description</td></tr>";
print "<tr><td width='$width1'>Strains Crossed</td><td>$strains_crossed_1, $strains_crossed_2</td></tr>";
print "<tr><td width='$width1'>Chromosome</td><td>$chromosome</td></tr>";
print "<tr><td width='$width1'>LOD Score</td><td>$lod_score</td></tr>";
print "<tr><td width='$width1'>Peak Marker</td><td>$peak_marker, $peak_marker_type</td></tr>";
print "<tr><td width='$width1'>Flanking Marker 1</td><td>$flank_1, $flank_1_type</td></tr>";
print "<tr><td width='$width1'>Flanking Marker 2</td><td>$flank_2, $flank_2_type</td></tr>";
print "<tr><td width='$width1'>Candidate Gene</td><td>$candidate_gene</td></tr>";
print "<tr><td width='$width1'>Reference PubMed ID</td><td>$reference</td></tr>";
print "<tr><td width='$width1'>Comments</td><td>$comments</td></tr>";
print "</table><br>";


#button table
print "<table>";
print "<tr><td>&nbsp;</td></tr>";
print "<tr><td align='left'><center><INPUT type=submit name=action value=send>&nbsp;&nbsp;&nbsp;<INPUT type=submit  name=action value=leave></center><td></td></td></tr>";
print "</table>";
print "</form>";
print "<p><font size=2>Once you submit this completed form, the RGD_ID for this QTL will be e-mailed to you! Thank you.";
print "</BODY>";
print "</HTML>";

$html->tool_end;
$html->html_foot;

##########################################################################################################################
