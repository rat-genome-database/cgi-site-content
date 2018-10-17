#This program is for cgi config file
#return basedir

sub BaseDir
{
    $rgdHome="http://fuxi.ifrc.mcw.edu";
    $baseURL="http://fuxi.ifrc.mcw.edu";
    $baseCGI="http://rgd.mcw.edu/tools/common";
    $base="/rgd/TOOLS/common";
    $rhmap="/rgd/TOOLS/rhmap/";
    return($baseURL,$baseCGI, $base,$rhmap);
}
1;      #standard output

sub htmltop
{
    my($title)=@_;
    print "Content-Type: text/html\n\n";
    print <<PRT;
<html> 
<head>
<title>$title</title>
</head>
<body bgcolor=white> 
<center>
<p><h3>$title</h3>
<a href="$rgdHome">RGD Home</a> |
<a href="http://goliath.ifrc.mcw.edu/">IFRC Home</a> |
<a href="$baseURL">Rat RH Home</a> |
<a href="$baseCGI/rh_placement.cgi">Map Server</a>
<hr>
</center>
<p>
PRT
}
1;

sub htmlbottom
{
    print "</body></html>"; 
}
1;

##################################################
#   HEADER
##################################################

sub RGDHeader

{
   my ($TITLE)=@_;
  print "Content-type:text/html  \n\n";
  
  print<<RGDHEADER; 
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=iso-8859-1">
<meta name="generator" content="Adobe GoLive 4">
<title>$TITLE</title>
<meta name='keywords' content="$KEYWORDS">
<meta name='description' content="$DESCRIPTION">
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
<a href="ftp://rgd.mcw.edu/pub/"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">FTP</font></a> | 
<a href="$baseURL/ABOUT/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">About</font></a> | 
<a href="$baseURL/CONTACTS/index.html"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">Contacts</font></a> |
<a href="http://goliath.ifrc.mcw.edu/RCF/"><font color="white" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">RCF</font></a>
   </div>
   </td>
</tr>\n
</table>
RGDHEADER
}

##########################################################
#   PAGEHEADER
##########################################################

sub ToolHeader
{
 my ($TITLE,$TOOL,$DIR)=@_;
  print<<__PAGEHEADER__;
<table border="0" cellspacing="0" width="650" cellpadding="5">
<tr align=right>
  <td width="100%" valign="top">
  <a href='$baseURL'><font face="Arial" size="2"><strong>RGD</strong></font></a> > 
  <a href='$baseURL/TOOLS/'><font face="Arial" size="2"><strong>TOOLS</strong></font></a>
__PAGEHEADER__
   if($DIR){
     print " > <a href=\"$baseURL/TOOLS/$DIR/\"><font face=Arial size=2><strong>$TOOL</strong></font></a> > <font face=Arial size=2>$TITLE</strong></font>";
   }else{
     print " > <font face=Arial size=2>$TOOL</strong></font>";
   }
   print<<__PAGEHEADER__;
      </td>
  </tr>
  <tr><td>
  <small><b>Version: $VERSION</b></small>
  </td>
</tr>
</table>  
__PAGEHEADER__
}

##########################################################
#   RGD FOOTER
##########################################################
sub RGDFooter
{
print<<__FOOTEREND__;

  <TABLE width=550 cellspacing='0' cellpadding='5'>
    <tr><td>
    <hr>
    <p class='footer'><a href='http://brc.mcw.edu/'>Bioinformatics Research Center &copy; 1999</a>
    <br><b>Last Updated</b>: $UPDATED
    </td>
  </table>
</HTML>

__FOOTEREND__
}
