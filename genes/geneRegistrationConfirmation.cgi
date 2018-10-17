#!/usr/bin/perl

#####################################################################################
# File Name:	geneRegistrationConfirmation.cgi									#
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

my $gene_symbol=$form->param('gene_symbol');
my $gene_name=$form->param('gene_name');
my $acc_number=$form->param('acc_number');
my $gene_type=$form->param('gene_type');
my $gene_description=$form->param('gene_description');
my $map_position=$form->param('map_position');
my $ilar_code=$form->param('ilar_code');
my $related_types=$form->param('related_types');
my $reference=$form->param('reference');
my $comments=$form->param('comments');

my $public=$form->param('public');

$html->html_head;
$html->tool_start;

print "<HTML><HEAD><TITLE> Public Genes data submit </TITLE></HEAD>";
print "<BODY>";
print "<form method=POST action=geneRegistrationSubmit.cgi>";
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

print "<input type=hidden name=gene_symbol value='$gene_symbol'>";
print "<input type=hidden name=gene_name value='$gene_name'>";
print "<input type=hidden name=acc_number value='$acc_number'>";
print "<input type=hidden name=gene_type value='$gene_type'>";
print "<input type=hidden name=gene_description value='$gene_description'>";
print "<input type=hidden name=map_position value='$map_position'>";
print "<input type=hidden name=ilar_code value='$ilar_code'>";
print "<input type=hidden name=related_types value='$related_types'>";
print "<input type=hidden name=reference value='$reference'>";
print "<input type=hidden name=comments value='$comments'>";

print "<p><center><font size=3 color=black><B><font size=6 color='black'>Gene Registration Form</font><br></B></font></center>";
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
print "<tr><td colspan=2 bgcolor='#cccccc'><center>Gene Information</center></td></tr>";

print "<tr><td width='$width1'>Gene Symbol</td><td>$gene_symbol</td></tr>";
print "<tr><td width='$width1'>Gene Name</td><td>$gene_name</td></tr>";
print "<tr><td width='$width1'>GenBank Accession ID</td><td>$acc_number</td></tr>";
print "<tr><td width='$width1'>Gene Type</td><td>$gene_type</td></tr>";
print "<tr><td width='$width1'>Gene Description</td><td>$gene_description</td></tr>";
print "<tr><td width='$width1'>Map Position</td><td>$map_position</td></tr>";
print "<tr><td width='$width1'>ILAR Code</td><td>$ilar_code</td></tr>";
print "<tr><td width='$width1'>Related Types</td><td>$related_types</td></tr>";
print "<tr><td width='$width1'>Reference PubMed ID</td><td>$reference</td></tr>";
print "<tr><td width='$width1'>Comments</td><td>$comments</td></tr>";
print "</table><br>";


#button table
print "<table>";
print "<tr><td>&nbsp;</td></tr>";
print "<tr><td align='left'><center><INPUT type=submit name=action value=send>&nbsp;&nbsp;&nbsp;<INPUT type=submit  name=action value=leave></center><td></td></td></tr>";
print "</table>";
print "</form>";
print "<p><font size=2>Once you submit this completed form, the RGD_ID for this gene will be e-mailed to you! Thank you.";
print "</BODY>";
print "</HTML>";

$html->tool_end;
$html->html_foot;

##########################################################################################################################
