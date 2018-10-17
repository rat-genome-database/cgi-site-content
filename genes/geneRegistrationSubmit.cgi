#!/usr/bin/perl

#####################################################################################
# File Name:geneRegistrationSubmit.cgi													#
# Usage:		this tool will write the submitting data in a data file and sent	#
#				mail notification to curator										#
# Author:		Henry Fan, Pete Bazeley															#
# Date:			12/5/2003															#
#####################################################################################
use lib "/rgd/tools/common";
use lib "/rgd/tools/common/RGD";
use RGD::HTML;
use MIME::Lite;		
use CGI qw(:standard);
use strict;

my $form = new CGI;
my $rgd = RGD::HTML->new();
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
my $userEmail  = $form->param('userEmail');
my $action=$form->param('action');


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

my $title="Author Last Name\nAuthor First Name\nAuthor Middle Name\nAuthor Email Address\nAuthor Organization\nAuthor Address\nAuthor City\n";
   $title.="Author State\nAuthor Post Code\nAuthor Country\nAuthor Phone\nAuthor Fax\nUser Last Name\nUser First Name\nUser Middle Name\n";
   $title.="User Email Address\nGene Symbol\nGene Name\nGenBank Accession ID\nGene Type\nGene Description\nMap Position\nIlar Code\n";
   $title.="Related strains, QTLS, markers\nReference Pubmed ID\nComments\n";


my $data=$authorLName."\n".$authorFName."\n".$authorMName."\n".$authorEmail."\n".$authorOrganization."\n".$authorAddress."\n".$authorCity."\n";
   $data.=$authorState."\n".$authorPostalCode."\n".$authorCountry."\n".$authorPhone."\n".$authorFax."\n".$userLname."\n".$userFname."\n".$userMname."\n";
   $data.=$userEmail."\n".$gene_symbol."\n".$gene_name."\n".$acc_number."\n".$gene_type."\n".$gene_description."\n".$map_position."\n";
   $data.=$ilar_code."\n".$related_types."\n".$reference."\n".$comments."\n";

my $dataForMail="Author Name:\t".$authorFName." ".$authorLName."\nAuthor Email Address:\t".$authorEmail."\nAuthor Organization:\t".$authorOrganization."\nAuthor Address:\t".$authorAddress." ".$authorCity." ".$authorState." ".$authorPostalCode." ".$authorCountry." "."\nAuthor Phone:\t".$authorPhone."\nAuthor Fax:\t".$authorFax."\nUser Name:\t".$userFname." ".$userLname."\nUser Email Address:\t".$userEmail."\nGene Symbol:\t".$gene_symbol."\nGene Name:\t".$gene_name."\nGenBank Accession ID:\t".$acc_number."\nGene Type:\t".$gene_type."\nGene Description:\t".$gene_description."\nMap Position:\t".$map_position."\nIlar Code:\t".$ilar_code."\nRelated strains, QTLs, markers:\t".$related_types."\nReference PubMed ID:\t".$reference."\nComments:\t".$comments;


my $rootPath=$html->get_dataPATH; 
my $filePath=$rootPath."/genes/";
my $fileName="registrationData_".$userFname."_".$userLname.".txt";
my $file=$filePath.$fileName;

my $mailSubject="Gene Registration Form";
my $mailMessage= "<HTML><BODY>Dear RGD Curators:<br><P> A new gene registration information has been generated.<br><br>";
       $mailMessage.="Author Name:			 ".$authorFName."\t".$authorLName."<br>";
       $mailMessage.="Author Email Address:  ".$authorEmail."<br>";
       $mailMessage.="Author Organization:   ".$authorOrganization."<br>";
       $mailMessage.="Author Address:        ".$authorAddress."\t".$authorCity."\t".$authorState."\t".$authorPostalCode."<br>";
       $mailMessage.="Author Phone:          ".$authorPhone."<br>";
       $mailMessage.="Author Fax:            ".$authorFax."<br>";
       $mailMessage.="User Name:             ".$userFname."\t".$userLname."<br>";
       $mailMessage.="User Email Address:    ".$userEmail."<br>";
	   $mailMessage.="Status:				 ".$public."<br>";
       $mailMessage.="</P></font></BODY></HTML>";

my $fromAddress=$userEmail;
my $toAddress="rgd.data\@mcw.edu";

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
	open (OUT,">$file")|| die "can not open the data file:$!\n";
	print OUT $dataForMail;	
	close(OUT);
}

#########################################################################
# send_mail: send an e-mail notification to curator after				#
#			 the new data file is generated								#
#########################################################################
sub send_mail{
    #my ($mailSubject, $mailMessage, $fromAddress, $toAddress) = @_;
    #system ("echo \"$mailMessage\" | mailx -s \"$mailSubject\" -r $fromAddress $toAddress");

    my $msg = MIME::Lite->new(
                 From    =>$fromAddress,
                 To      =>$toAddress,
                 Cc      =>'rgd.user@gmail.com',
                 Subject =>$mailSubject,
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
# display_message_sent: 							#
#########################################################################
sub display_message_sent{

	my $displayMessage=undef;

	if($public eq "nonPublic"){
		$displayMessage="Your registration data has been submitted to RGD curators and your data will not go to the public. Thanks.";
	}
	else{
		$displayMessage="Your registration data has been submitted to RGD curators, Thanks";
	}

	print "<p><font size=\"4\" color=\"blue\"><br><br><br>$displayMessage.<br></font>";

}

#########################################################################
# display_message_leave: 							#
#########################################################################
sub display_message_leave{

	my $message="Your gene registration data have NOT been sumbitted to RGD curators. You are welcomed next time.";
	print "<p><center><font size=\"4\" color=\"blue\"><br><br><br>$message<br></center></font>";	
}

############################################################### end script ##################################################################
