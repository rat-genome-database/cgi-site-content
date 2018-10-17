#!/usr/bin/perl

#####################################################################################
# File Name:	strainDataInput.cgi													#
# Usage:		this tool will display the stain data form for user input			#
# Author:		Henry Fan															#
# Date:			05/21/2003															#
#####################################################################################
use lib "/rgd/tools/common";
use RGD::HTML;
use CGI qw(:standard);
use strict;

my $form = new CGI;
my $html = RGD::HTML->new();

# get form parameters
my $authorLName = $form->param('authorLName');    
my $authorFName = $form->param('authorFName');
my $authorMName = $form->param('authorMName');
my $authorEmail = $form->param('authorEmail');
my $authorOrganization = $form->param('authorOrganization');
my $authorAddress = $form->param('authorAddress');
my $authorCity  = $form->param('authorCity');
my $authorState = $form->param('authorState');
my $authorPostalCode = $form->param('authorPostalCode');
my $authorCountry = $form->param('authorCountry');    
my $authorPhone = $form->param('authorPhone');
my $authorFax = $form->param('authorFax');
my $userLname = $form->param('userLname');
my $userFname = $form->param('userFname');
my $userMname = $form->param('userMname');
my $userEmail = $form->param('userEmail');
my $count = $form->param('count');

$html->html_head;
$html->tool_start;

print "<HTML><HEAD><TITLE> Public Strains data submit </TITLE></HEAD>";

print "<BODY>";
print "<table border='0' width='80%' align='center'><tr><td>";

print "<table border='0' width='100%' align='center'>";
print "<tr><td><b><font size='6' color='black'><CENTER>Strain Submission Form</CENTER></font></b></td></tr>";
print "</table>";

print <<__FORM__;  
 <form method=POST action="strainConfirmation.cgi" name="" onSubmit="return verify(this)">  
__FORM__

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

if($count>1){
	print "<p><font size=2><center>You have $count strains to be entered in this page.</center><font></P>";
}

my @code=undef;

for(my $j=1; $j<=$count; $j++){
		print "<table border='0' width='100%' align='center'>";
		print "<tr><td colspan=2>&nbsp;</td></tr>";
		if($count>1){
			print "<tr><td colspan=2 bgcolor='#cccccc'><font color='black'><center>Data for Strain Entry &nbsp;$j</font><font size=2>&nbsp;&nbsp;(The fields with <font color=red>*</font>cannot be empty)</center></font></td></tr>";
		}
		else{
			print "<tr><td colspan=2 bgcolor='#cccccc'><font color='black'><center>Data for Strain Entry</font><font size=2>&nbsp;&nbsp;(The fields with <font color=red>*</font>cannot be empty)</center></font></td></tr>";
		}
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('strain_code')>ILAR laboratory code </a>(desirable)</td><td><INPUT type='text' name='code' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('strain')>Strain</a><font color=red>*</font></td><td><INPUT type='text' name='strain' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('sub_strain')>Substrain</a></td><td><INPUT type='text' name='subStrain' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('full_name')>Full name </a></td><td><INPUT type='text' name='fullName' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('strain_type')>Strain type</a></td><td>";
		print "<SELECT NAME='strainType' SIZE='1'>";
		print "<OPTION SELECTED>inbred";
		print "<OPTION>related inbred ";
		print "<OPTION>recombinant inbred ";
		print "<OPTION>coisogenic";
		print "<OPTION>congenic";
		print "<OPTION>consomic";
		print "<OPTION>segregating inbred";
		print "<OPTION>conplastic"; 
		print "<OPTION>outbred";
		print "<OPTION>mutant";
		print "<OPTION>transgenic"; 
		print "</SELECT>";
		print "</td></tr>";
		print "<tr><td width='80%' valign='top'><a href=javascript:help('genetic_marker')>Genetic Markers </a></td><td>";
		print "<SELECT NAME='geneticMarker' SIZE='1'>";
		print "<OPTION SELECTED>Agouti";
		print "<OPTION>Non-agouti";
		print "<OPTION>Non-hooded";
		print "<OPTION>Hooded";
		print "<OPTION>Irish-hooding";
		print "<OPTION>Non-pink-eyed";
		print "<OPTION>Pink-eyed-dilute";
		print "</SELECT>";
		print "</td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('strain_color')>Strain color </a></td><td>";
		print "<SELECT NAME='strainColor' SIZE='1'>";
		print "<OPTION SELECTED>Agouti";
		print "<OPTION>brown";
		print "<OPTION>albino";
		print "<OPTION>dilute";
		print "<OPTION>yellow";
		print "<OPTION>fawn";
		print "<OPTION>hooded";
		print "<OPTION>white";
		print "<OPTION>microphthalmie-blanc";
		print "<OPTION>Pink-eyed-yellow";
		print "<OPTION>red-eyed-yellow";
		print "<OPTION>silver";
		print "<OPTION>sand";
		print "<OPTION>spotted-lethal";
		print "<OPTION>white-belly";
		print "</SELECT>";
		print "</td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('inbred_gen')>Inbred Generations # </a></td><td><INPUT type='text' name='generation' size=30, maxlength=200><td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('strain_origin')>Strain Origin </a></td><td><TEXTAREA NAME='strainOrigin' ROWS=4 COLS=30></TEXTAREA></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('reproduction')>Reproduction </a></td><td><TEXTAREA NAME='reproduction' ROWS=4 COLS=30></TEXTAREA></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('general_char')>General Characteristics </a></td><td><TEXTAREA NAME='characterics' ROWS=4 COLS=30></TEXTAREA></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('lifespan')>Lifespan and Spontaneous Disease </a></td><td><TEXTAREA NAME='disease' ROWS=4 COLS=30></TEXTAREA></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('anatomy')>Anatomy </a></td><td><TEXTAREA NAME='anatomy' ROWS=4 COLS=30></TEXTAREA></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('infection')>Infection </a></td><td><TEXTAREA NAME='infection' ROWS=4 COLS=30></TEXTAREA></td></tr> ";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('immunology')>Immunology </a></td><td><TEXTAREA NAME='immunology' ROWS=4 COLS=30></TEXTAREA></td></tr>"; 
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('physiology')>Physiology and Biochemistry  </a></td><td><TEXTAREA NAME='biochemistry' ROWS=4 COLS=30></TEXTAREA></td></tr> ";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('drug')>Drugs and Chemicals  </a></td><td><TEXTAREA NAME='chemical' ROWS=4 COLS=30></TEXTAREA></td></tr>"; 
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('altered')>Chromosome Altered</a></td><td><INPUT type='text' name='chromosome' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('marker1')>Flank Marker 1 </a></td><td><INPUT type='text' name='market1' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('marker2')>Flank Marker 2 </a></td><td><INPUT type='text' name='market2' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('note')>Notes Type </a></td><td><INPUT type='text' name='noteType' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('gene_rgd_id')>GENE RGD ID</a></td><td><INPUT type='text' name='geneRgdID' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('gene_symbol')>GENE Symbol </a></td><td><INPUT type='text' name='geneSymbol' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('sslp_rgd_id')>SSLP RGD ID</a></td><td><INPUT type='text' name='SSLPRgdID' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('sslp_symbol')>SSLP Symbol </a></td><td><INPUT type='text' name='SSLPSymbol' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('qtl_rgd_id')>QTL RGD ID</a></td><td><INPUT type='text' name='QTLRgdID' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('qtl_symbol')>QTL Symbol</a></td><td><INPUT type='text' name='QTLSymbol' size=30, maxlength=200></td></tr>";
		print "<tr><td width='80%' valign='top'> <a href=javascript:help('source')>Source of Strain</a><font color=red>*</font></td><td><INPUT type='text' name='strainSource' size=30, maxlength=200></td></tr>";
		print "</table>";
}#end for loop

print "<br><br><p><center><INPUT type=submit value=\"Send Form\">&nbsp;&nbsp;&nbsp;<INPUT type=reset value=\"Clear Form\"></center></p>";

print "</form>";

print "</td></tr></table>";
print "</BODY>";
print "</HTML>";

$html->tool_end;
$html->html_foot;

print <<__JS__;
  
  <script language='JavaScript'>

	function verify(field){
		var message;
		var need_field="";
		var display_name;

		for(var i=0; i<field.length; i++){
		
			var e=field.elements[i];
			if(e.name=="strain"){
				display_name="Strain";
			}
			if(e.name=="strainSource"){
				display_name="Source of Strain";
			}

			if((e.name=="strain")||(e.name=="strainSource")){
				if((e.value==null)||(e.value=="")||isblank(e.value)){
					need_field += "\n          " + display_name;
				}
			} 
		}
	  
		if(need_field){
			message="The form can not be submitted because the following fields must be filled in:\n\n"	+ need_field+"\n";
			alert(message);
			return false;
		}
	}

	function isblank(s){
		for(var i=0; i<s.length; i++){
			var c=s.charAt(i);
			if((c !=' ')&&(c !='\n')&&(c !='\t')) return false;
		}
		
		return false;	
	}

  </script>

 <script language='JavaScript'>

	function help(anchor) {
		top.strainhelp=open("/strains/strainSubmitHelp.html#"+anchor,"helpwindow","scrollbars=yes,toolbar=no,directories=no,menubar=no,status=no,resizable=yes,width=400, height=200");
		top.strainhelp.focus();
	}


  </script>
  
__JS__

