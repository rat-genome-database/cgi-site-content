#!/usr/bin/perl

#####################################################################################
# File Name:qtlRegistrationSubmit.cgi												#
# Usage:		this tool will write the submitting data in a data file and sent	#
#				mail notification to curator										#
# Author:		Henry Fan, Pete Bazeley												#
# Date:			04/16/2003															#
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

my $qtl_symbol = $form->param('qtl_symbol');
my $qtl_name = $form->param('qtl_name');
my $trait = $form->param('trait');
my $subtrait = $form->param('subtrait');
my $trait_description = $form->param('trait_description');
my $strains_crossed_1 = $form->param('strains_crossed_1');
my $strains_crossed_2 = $form->param('strains_crossed_2');
my $chromosome = $form->param('chromosome');
my $lod_score = $form->param('lod_score');
my $peak_marker = $form->param('peak_marker');
my $peak_marker_type = $form->param('peak_marker_type');
my $flank_1 = $form->param('flank_1');
my $flank_1_type = $form->param('flank_1_type');
my $flank_2 = $form->param('flank_2');
my $flank_2_type = $form->param('flank_2_type');
my $candidate_gene = $form->param('candidate_gene');
my $reference = $form->param('reference');
my $comments = $form->param('comments');
 

my $public=$form->param('public');

my $title="Author Last Name\tAuthor First Name\tAuthor Middle Name\tAuthor Email Address\tAuthor Organization\tAuthor Address\tAuthor City\t";
   $title.="Author State\tAuthor Post Code\tAuthor Country\tAuthor Phone\tAuthor Fax\tUser Last Name\tUser First Name\tUser Middle Name\t";
   $title.="User Email Address\tQTL Symbol\tQTL Name\tTrait\tSubtrait\tTrait Description\tStrains Crossed\tChromosome\tLOD Score\tPeak Marker\t";
   $title.="Flanking Marker 1\tFlanking Marker 2\tCandidate Gene\tReference PubMed ID\tComments\t\n";

my $data=$authorLName."\t".$authorFName."\t".$authorMName."\t".$authorEmail."\t".$authorOrganization."\t".$authorAddress."\t".$authorCity."\t";
   $data.=$authorState."\t".$authorPostalCode."\t".$authorCountry."\t".$authorPhone."\t".$authorFax."\t".$userLname."\t".$userFname."\t".$userMname."\t";
   $data.=$userEmail."\t".$qtl_symbol."\t".$qtl_name."\t".$trait."\t".$subtrait."\t".$trait_description."\t".$strains_crossed_1.", ".$strains_crossed_2."\t";
   $data.=$chromosome."\t".$lod_score."\t".$peak_marker.", ".$peak_marker_type."\t".$flank_1.", ".$flank_1_type."\t".$flank_2.", ".$flank_2_type."\t";
   $data.=$candidate_gene."\t".$reference."\t".$comments."\t\n";

my $dataForMail="Author Name:\t".$authorFName." ".$authorLName."\nAuthor Email Address:\t".$authorEmail."\nAuthor Organization:\t".$authorOrganization."\nAuthor Address:\t".$authorAddress." ".$authorCity." ".$authorState." ".$authorPostalCode." ".$authorCountry." "."\nAuthor Phone:\t".$authorPhone."\nAuthor Fax:\t".$authorFax."\nUser Name:P\t".$userFname." ".$userLname."\nUser Email Address:\t".$userEmail."\nQTL Symbol:\t".$qtl_symbol."\nQTL Name:\t".$qtl_name."\nTrait:\t".$trait."\nSubtrait:\t".$subtrait."\nTrait Description:\t".$trait_description."\nStrains Crossed:\t".$strains_crossed_1." ".$strains_crossed_2."\nChromosome:\t".$chromosome."\nLOD Score:\t".$lod_score."\nPeak Marker:\t".$peak_marker.", ".$peak_marker_type."\nFlanking Marker 1:\t".$flank_1.", ".$flank_1_type."\nFlanking Marker 2:\t".$flank_2.", ".$flank_2_type."\nCandidate Gene:\t".$candidate_gene."\nReference PubMed ID:\t".$reference."\nComments:\t".$comments;

my $rootPath=$html->get_dataPATH; 
my $filePath=$rootPath."/qtls/";
my $fileName="registrationData_".$userFname."_".$userLname.".txt";
my $file=$filePath.$fileName;

my $mailSubject="QTL Registration Form";
my $mailMessage= "<HTML><BODY>Dear RGD Curators:<br><P> A new QTL registration information has been generated.<br><br>";
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

# basic validation (protection against simple spams RGD was hit)
if( $authorOrganization ne ""  &&  $authorPhone ne ""  &&  $authorOrganization eq $authorPhone ) {
	# organization cannot be the same as phone !!!
 	$action = "leave";
 	 
 	&write_data;
 	 
 	# send copy of spam email to person in charge
	my $msg = MIME::Lite->new(
		From    =>$fromAddress,
	 	To      =>$toAddress="rgd.developers\@mcw.edu",
	 	Subject =>"***SPAM DETECTED***".$mailSubject,
	 	Type    =>'text/html',
	 	Data    =>$mailMessage
	);
	$msg->attach(Type     =>'TEXT',
		Path     =>$file,
	 	Filename =>$fileName,
	);
	$msg->send;
}

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

#####################################################
# display_message_sent: 							#
#####################################################
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

#####################################################
# display_message_sent: 							#
#####################################################
sub display_message_leave{

	my $message="Your strain registration data has NOT been sumbitted to RGD curators. You are welcomed next time.";
	print "<p><center><font size=\"4\" color=\"blue\"><br><br><br>$message<br></center></font>";	
}

########################################################## end script ###
