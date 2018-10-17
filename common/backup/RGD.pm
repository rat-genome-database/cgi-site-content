#########################
#
# RGD.pm - A perl 5 module to connect to RGD
#
# (c) Simon Twigger, Medical College of Wisconsin, 1999.
#     simont@mcw.edu
#
#########################



#########################
#
#   Notes
#
#########################
#  
# 
#
# 
# 
#
#########################



#########################
#
#   Bugs/To Do List
#
#########################
#  
# RGD.pm
# 
# 
#
#########################


package RGD;

require 5.003;
use Exporter ();

# use strict; # to keep me honest
use Carp;   # to make error reporting a bit easier
use vars qw($VERSION @ISA @EXPORT);

$VERSION = "0.2";
@ISA = qw(Exporter);
@EXPORT = qw(
	     htmltop
             htmlbottom
	     $RGD_HOME
	     $BASE_URL
	     $BASE_CGI
	     $BASE
	     $RHMAP
	     $DB_DRIVER
	     $USER
	     $PASS
	     $SID
	     );

#my $RGD_HOME ="http://goliath.ifrc.mcw.edu/RGD_DEMO";
#my $BASE_URL ="http://legba.ifrc.mcw.edu/RGD_DE";

### Since moved to ares, the URL is changed.  modified by Wei Wang
$BASE_URL = "http://rgd.mcw.edu";
$BASE_CGI ="http://rgd.mcw.edu/rgd-bin";
$BASE = "/rgd";



my $RHMAP = "/project/rhmap";
$ENV{"ORACLE_HOME"} = "/rsch_oracle/home/roracle/product/8.1.5";
$DB_DRIVER = 'dbi:Oracle';
$USER = 'rgd_owner';
$PASS = 'rgd_2000';
$SID  = 'rgd';


#############
#
# The constructor method
#
#############

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}



###################################################
#
# Output the header of HTML added by Wei Wang
#
###################################################
sub htmltop
{
  my ($TITLE)=@_;
  print "Content-type:text/html  \n\n";
  
  print<<RGDHEADER; 
<html
<head>
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
<meta name="generator" content="Adobe GoLive 4">
<title>$TITLE</title>
<meta name='keywords' content="$KEYWORDS">
<meta name='description' content="$DESCRIPTION">
<BASE url='$baseURL/'>
</head>

<body bgcolor="white" text="black" link="#666699" vlink="gray" alink="#666699">
<table border="0" cellspacing="0" width="650" cellpadding="5">
<tr>
  <td width="100%" bgcolor="#686899" valign="top">
  <div align="right">
   <a href="$baseURL/index.html"><img name="Nrgdlogosmall_01_01" src="$baseURL/IMAGES/rdg_logo.gif" border="0" width="84" height="78" align="left"></a>
<font face="Arial" size="6" color="white">
<strong>RAT GENOME DATABASE</strong></font><br>
<p><a href="$baseURL/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">Home</font></a> | 
<a href="$baseURL/TOOLS/QUERY/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">Query</font></a> | 
<a href="$baseURL/TOOLS/MAPPING/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">Mapping</font></a> |&nbsp;
<a href="$baseURL/TOOLS/SEQUENCE/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">Sequence</font></a> | 
<a href="ftp://legba.ifrc.mcw.edu/pub/"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">FTP</font></a> | 
<a href="$baseURL/ABOUT/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">About</font></a> | 
<a href="$baseURL/CONTACTS/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">Contacts</font></a> |
<a href="http://goliath.ifrc.mcw.edu/RCF/"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">RCF</font></a>
   </div>
   </td>
</tr>
<tr>
<td width="100%">
<div align="right">
 <a href="$baseURL/index.html" target="_parent"><font face="Arial" size="2"><strong>RGD</strong></font></a><font face="Arial" size="2"><strong>&nbsp;&gt;&nbsp;<a href="$baseURL/TOOLS/index.html">TOOLS</a>&nbsp;&gt; <a href="$baseURL/TOOLS/QUERY/index.html">QUERY&nbsp;TOOLS</a></strong></font></div>
                                        </td>

</tr>
<tr>
<td><h1><font face="Arial">$TITLE</font></h1></td>
</tr>
</table>
RGDHEADER
}


############
# 
# Output an HTML page with error information
#
############

sub HTML_Error {

    # read in the error message passed to the subroutine
    my $error_message = shift(@_) || "An unknown error occured - Yikes";
    my $script = shift(@_) || "CGI Error: ";

    # print out HTML page letting the new user know an error occured

    print "Content-type: text/html\n\n";

    print <<"EOF";
<HTML><HEAD><TITLE>$script error</TITLE></HEAD<
<BODY BGCOLOR="#FFFFFF">
<BR>
<H1>An error occured whilst processing your request:</H1>

<STRONG>$error_message</STRONG>

<HR>
Return to the <A HREF="$BASE_CGI/search.cgi">RGD Search Tools Page</A>
</BODY></HTML>
EOF

    # stop the execution of the script here
    exit;
}


#######################################################
#
# Output the bottom of HTML   added by Wei Wang
#
######################################################

sub htmlbottom
{
    print "</body></html>"; 
}


#######################################################
# 
# Output the opening HTML data with RGD header and L&F
#
#######################################################

sub rgd_htmltop { #rgd_htmltop method open

  my %defaults = (
		  title=>"RGD Tool",
		  title_url => "",
		  version=>"1.0",
		  author=>"help\@rgd.mcw.edu",
		  keywords=>"rgd,rat,genome,database",
		  first_page=>1,
		  help_title=>"Main Help Page",
		  help_url=>"http://rgd.mcw.edu/TOOLS/help.html"
		  
		 );

  my $me = shift(@_); # remove the obj reference first
  my %args = (%defaults,@_); # convert argument list to a hash, defaults overwritten by any new values
  
  my $url = "http://www.rgd.mcw.edu";

  print "Content-Type: text/html\n\n";
  print <<"PRT";
<html> 
<head>
<BASE Target=_parent>
<meta name="keywords" content="$args{keywords}">
<meta name="author" content="$args{author}">
<title>$args{title}</title>

<style>
    <!-- define the generic RGD styles here, should really 
         inherit from an external stylesheet
    -->
    
    <!--
    BODY: {font-family: arial,helvetica,sans-serif;
           background: white; }

   
    H1,H2,H3,H4,H5,H6 {font-family: arial,helvetica,sans-serif; }

    P, TD,UL,LI {font-family: arial,helvetica,sans-serif;
	    }
    
    P:header {font-size: medium;} 
    A:link {color: #666699;}
    A:active {color: gray; }
    A:visited {color: #666699; }
    -->

</style>

</head>

<body BGCOLOR="white">
<table width="650">

<tr>
<td width="100%" bgcolor="#686899" valign="top">
<div align="right">
<a href="../../index.html"><img name="Nrgdlogosmall_01_01" src="$url/IMAGES/rdg_logo.gif" border="0" width="84" height="78" align="left"></a><font color="white" size="6"><STRONG>RAT GENOME DATABASE</STRONG></font><br>
<p><a href="http://rgd.mcw.edu/index.html"><font color="white">Home</font></a> |&nbsp;<font color="white">Query</font> |&nbsp;<a href="$url/TOOLS/MAPPING/index.html"><font color="white" >Mapping</font></a> |&nbsp;<a href="$url/TOOLS/SEQUENCE/index.html"><font color="white" >Sequence</font></a> | <a href="ftp://legba.ifrc.mcw.edu/pub/"><font color="white">FTP</font></a> |&nbsp;<a href="$url/ABOUT/index.html"><font color="white" >About</font></a> |&nbsp;<a href="$url/CONTACTS/index.html"><font color="white" >Contacts</font></a> |&nbsp;<a href="http://goliath.ifrc.mcw.edu/RCF/"><font color="white" >RCF</font></a></div>
					</td>
				</tr>
				<tr>
					<td width="100%">
						<div align="right">
							<a href="$url/index.html" target="_parent"><font face="Arial" size="2"><strong>RGD</strong></font></a><font face="Arial" size="2"><strong>&nbsp;&gt;&nbsp;<a href="$url/TOOLS/index.html">TOOLS</a>&nbsp;&gt; <a href="$url/TOOLS/QUERY/">QUERY&nbsp;TOOLS</a></strong>&nbsp;&gt;
PRT

if($args{title_url}) {
print " <a href=\"$args{title_url}\">$args{title}</a>";
}
else {
print " $args{title}";
}

print <<"PRT";
</font> </div></td>
</tr>
<tr>
<td>
<p>
<h1>$args{title}</h1>
PRT

# if its the first page, add in the usual version and help info
if($args{first_page} == 1) {
print <<"PRT";
<p class=header><strong>Version: $args{version}</strong></p>
<p class=header><strong>For Help see: <a href="$args{help_url}">$args{help_title}</a></strong>
<p>
<hr>
PRT
}
    
  }

#######################################################
# 
# Output the end of the HTML page
#
#######################################################

sub rgd_htmlbottom {
   print "</td></tr></table></body></html>"; 
}



1;
