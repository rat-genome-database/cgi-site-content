#!/usr/bin/perl
#########################################################
#  file name:run_place_markers.pl
#  author: JIAN LU
#  date: 3-22-1999
#  to run place_markers.pl at background and send email
#  once the process is done.
#  modified: 6-22-1999 removed the loop for checking process
#            6-28-1999 fixed sendmail bug by using Sendmail.pm
#            7-20-1999 switch to sys mail
#            5-16-2000, JL use RGD::HTML  model
########################################################
#use Mail::Sendmail;
use lib '/rgd/tools/common';
use RGD::HTML;

#DP 1-28-04
use Getopt::Std;
getopts('u:s:l:v:'); # command options

#my $user_id= shift(@ARGV);
my $user_id= $opt_u;
#my $section= shift(@ARGV);
my $section= $opt_s;
#my $lod_cutoff= shift(@ARGV);
my $lod_cutoff= $opt_l;
#my $rhmap_version= shift(@ARGV);
my $version= $opt_v;

my $rgd = RGD::HTML->new;
my $baseURL=$rgd->get_baseURL;
my $baseCGI=$rgd->get_baseCGI;
my $wwwPATH=$rgd->get_wwwPATH;
my $toolPATH=$rgd->get_toolPATH;

my $user_home="$toolPATH/rhmapserver/data/user_data/$user_id";
my $user_subdir="$user_home/$section";
my $data_filename="rhdata\.dat";

my $raw_data="$user_subdir/rhdata.raw";
my $input="$user_subdir/rhdata.dat";
my $output="$user_subdir/result.txt";

# starting time of process
my $start=time();
########################################
# print "process strats at $start\n";
#`/opt/rhmap/bin/place_markers.pl -p PLACEMENT -l $lod_cutoff <$input >$output 2>&1`;#DP 1-15-04
my $output_test="$user_subdir/test.txt";
open (OUT, ">$output_test");
print OUT "user id:$user_id, section:$section, lod_cutoff:$lod_cutoff, rhmap_version:$version,\n"; 
print OUT "/rgd/scripts/rhmap/bin/place_markers.pl -p $version -l $lod_cutoff <$input >$output 2>&1\n";
close (OUT);
`/rgd/scripts/rhmap/bin/place_markers.pl -p $version -l $lod_cutoff <$input >$output 2>&1`;
# ending time of process
my $end=time();

# print "process ends at $end\n";
use integer;
my $process_time=$end-$start;

####################################
# generate report
if(-e $output){
    &Get_Chrom($output);
    &Split_File_to_Chrom($output);
    &Check_Placement($output);
    &Generate_Report;
}
#########################################################
# Send_Mail
&Send_Mail;

#########################################################
# process_runtime
&process_runtime;

########################################################
#  Send_Mail
########################################################
sub Send_Mail{
  my ($sec, $min, $hour, $mday, $mon, $year)=localtime(time);
  $mon=$mon+1;
  $year = 1900 + $year;
  if($mon < 10){
    $mon="0$mon";
  }
  
  if($mday < 10){
    $mday="0$mday";
  }
  my $today="$mon/$mday/$year";

  my $summary="$user_subdir/report";
  open(SUM,$summary);
  @summary=<SUM>;
  close(SUM);
  
# send mail to user when the process is done
#    %mail = (To      => $user_id,
#	     From    => 'RH Mapping Server<rgd.data@mcw.edu>',
#	     Subject => 'RH placement map',
#	     Message => "Dear user,
#Bcc: rgd.developers\@mcw.edu
  open (MAIL, "|/usr/ucb/mail -n -t") or print "cannot open mail pipe\n";
  print MAIL <<RESULT;
From: RH Map Server <rgd.data\@mcw.edu>
Subject: RH placement map
To: $user_id

Thank you for using the rat RH map server. 
The process took the server computing time $process_time seconds.

Here is the summary report:

@summary

To find more details and placement maps, go to

$baseURL$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&version=$version

Some browsers do not properly activate the entire URL above (due to
the insertion of a linefeed).  To insure access to your results 
make sure that the ENTIRE URL is copied into the browser "site" textbox.

Please note:
Your results will be kept for ONLY 3 days after $today, 
then deleted automatically. You may also delete all results at any time  
through our on-line system (use the URL above).

If you have any question, please feel free to contact us.

Bioinformatics Research Center
Medical College of Wisconsin
414-456-7500
RESULT
    close(MAIL);

#
#	     );
#    sendmail(%mail) or die $Mail::Sendmail::error;
# send mail to tell the process done

#   my $time=`date`;
#   open (MAIL, "|/usr/ucb/mail -n -t") or print "cannot open mail pipe\n";
#   print MAIL <<RESULT;
#From: RH Map Server<rgd.data\@mcw.edu>
#Subject: Done RH mapping process
#To: Jian Lu<jianlu\@mcw.edu>

#The RH mapping process is from:

#user_id: $user_id
#section: $section
#rundate: $time
#Computing time(sec): $process_time

#and result was sent to user <$user_id>. 
#You may check it online at
#$baseCGI/rhmap_placement.cgi?user_id=$user_id&section=$section&version=$version   

#RESULT
#  close(MAIL);
}

##########################################################
#  Get_Chrom 
#########################################################
sub Get_Chrom{
  my ($file)=@_;
  open(FILE,$file);
  
  my $i=0;
  while(my $line=<FILE>){
    $line=~ /Chromosome\s(\w+)$/;
    if($1){
      $chrom{$1}=$1;
    }
    #	if($line =~ /\cL/){last}
  }
  close(FILE);
  $i=0;
  foreach $_ (keys(%chrom)){
    if($_ =~ /[xX]/){ $_=21;}
    $chrom[$i]=$_;
    $i++;
  }
  &numerically;
  @chrom=sort numerically (@chrom);
  #    print "@chrom\n";
}
#############
sub numerically {$a<=>$b;}
##########################################################
#   Split_File_to_Chrom
#########################################################
sub Split_File_to_Chrom{
  my ($file)=@_;
  my $i=0; 
  my $count_place=0;  
  #    my $count_frame=0;
  foreach $chrom (@chrom){
    $chr_count=0;
    if($chrom <10){
      $chr_file="CHR0$chrom\.dat";
      $chr_file_txt="CHR0$chrom\.txt";
    }else{
      $chr_file="CHR$chrom\.dat";
      $chr_file_txt="CHR$chrom\.txt";
    }
    #	print "\nwriting to $chr_file\n";
    open(CHR, ">$user_subdir/$chr_file");
    open(TXT, ">$user_subdir/$chr_file_txt");
    open(FILE,$file);
    my $begin="N";
    while(my $line=<FILE>){
      $line=~ /\bPlacement Data Relative to Framework for Chromosome\b\s(\w+)$/;
      $chr=$1;
      
      if($line =~ /^\bName\b/){ #match ASII control character like ^L
	$begin="Y";
	$CHR=$chr;
      }
      
      if($begin eq "Y"){
	if($CHR =~ /[xX]/){ $CHR=21;}
	($name,$string1,$string2,$string3)=split(/\s+/,$line,4);
	$string3=~ s/\D//g;
	if($name =~ /\w+/ && $CHR == $chrom && $string3 =~ /^\d+/){
	  chomp $line;
	  if($string2 =~ /[P]/){
	    $place_name[$count_place]=$name;
	    print CHR "$line\n";
	    print TXT "$line\n";
	    $count_place++;
	    $chr_count++;
	  }elsif($string2 =~ /[F]/){
	    #			$framework_name[$count_frame]=$name;
	    print TXT "$line\n";
	    $count_frame++;
	    $chr_count++;
	  }
	  #     print "$CHR:neme $count_link =$name,vector=$string3\n" 
	}
      }
    }
    close(FILE);
    close(CHR);
    close(TXT);
    #	print "$chr_count on chrom $chrom: placed=$count_place, framework=$count_frame\n";
  }
  $count_link=$count_place+$count_frame;
  #    print "placed markers: $count_link=$count_place+$count_frame\n";
}
##########################################################
#   Check_Placement
#########################################################
sub Check_Placement{
  my ($file)=@_;
  my $Y=0; 
  my $N=0;
  my $M=0;
  my $total=0;
  open (LK,">$user_subdir/link.txt");
  open (NL,">$user_subdir/nolink.txt");
  open (ML,">$user_subdir/multilink.txt");
  open(FILE,$file);
  my $begin="N";
  
  while($line=<FILE>){
    chomp $line;
    $line=~ /\bPlacement Data Relative to Framework for Chromosome\b\s(\w+)$/;
    $chr=$1;
    if($chr =~ /\d+/ || $chr =~ /X/){
      $CHR=$chr;
    }
    if($line =~ /^\bName\b/){
      $begin="Y";
    }
    
    ($name,$string1,$string2,$string3)=split(/\s+/,$line,4);
    $name=~ s/\s+//g;
    $string3=~ s/\s+//g; 
    if($name =~ /\w+/ && $name ne ""){
      if($string3 =~ /^\d+/){
	if($string2 =~ /P/){
	  print LK "$line\t$CHR\n";
	  $Y++;
	  $total++;
	}
      }elsif($string1 eq "No"){
	print NL "$line\n";
	$N++;
	$total++;
      }elsif($string1 eq "Multiple"){
	my $LINK="F";
	foreach $_ (@place_name){
	  if($_ eq "$name"){
	    $LINK="T";
	    #			print "found $name in both link and multilink\n";
	    last;
	  }
	}
	if($LINK eq "F"){
	  print ML "$line at lod $lod_cutoff\n";
	  $M++;
	  $total++;
	}
      }
    }
  }
  close(FILE);
  close(LK);
  close(NL);
  close(ML);
  #    print "\nPlaced $Y + Multilink $M + Nonplaced  $N = $total\n";
}
##########################################################
#   Generate_Report
#########################################################
sub Generate_Report{
  open (RAW,$raw_data) || die "$rawfile doesnt exist\n";
  my @raw=<RAW>;
  close(RAW);
  my $count_raw=@raw;
  
  my $nolink="$user_subdir/nolink.txt";
  open (NO,"$nolink") || die "$nolink doesnt exist\n";
  my @nolink=<NO>;
  close(NO);
  my $count_nolink=@nolink;
  
  my $link="$user_subdir/link.txt"; 
  open (LK,"$link") || die "$link doesnt exist\n";
  my @link=<LK>;
  close(LK);
  my $count_link=@link; 
  
  my $mlink="$user_subdir/multilink.txt"; 
  open (ML,"$mlink") || die "$mlink doesnt exist\n";
  my @mlink=<ML>;
  close(ML);
  my $count_mlink=@mlink;
  
  my $summary="$user_subdir/report";
  my $time=`date`;
  chomp $time;
  open (SUM,">$summary");
  print SUM "\n         Summary Report (LOD: $lod_cutoff)\n";
  print SUM "           Framework Version: $version\n";
  print SUM "===============================================\n";
  print SUM "Markers in data set: $count_raw\n";
  print SUM "Markers in data set that are      placed: $count_link\n";
  print SUM "Markers in data set that are not  placed: $count_nolink\n";
  print SUM "Markers in data set that are multilinked: $count_mlink\n\n";
  print SUM "PLACED ON     NUMBERS OF\n";
  print SUM " CHROM          MARKER\n";
  print SUM "----------------------------\n";
  #print SUM "$baseURL/$baseCGI/rhmapserver/rhmap_placement.cgi?user_id=$user_id&section=$section&version=$version\n";
  
  my $total_chr=0;
  
  foreach $chrom (@chrom){
    my $count=0;
    #if($chrom <10){
    #  $chr_file="CHR0$chrom\.dat";   
    #  print SUM "  0$chrom\t\t";
    #}else{
    #  $chr_file="CHR$chrom\.dat";
    #  if($chrom ==21){
    #	print SUM "  X\t\t";
    #  }else{
    #	print SUM "  $chrom\t\t";
    #  }
    #}
    #open(CHR, "$user_subdir/$chr_file");
    #@line=<CHR>;
    #close(CHR);
    #$count=@line;
    ########################
    foreach my $link (@link){
       if($chrom == 21){
          $count++ if($link =~ /ChrX/);
       }else{
          $count++ if($link =~ /$chrom\D/);
       }
    }
    foreach my $mlink (@mlink){
       if($chrom == 21){
          $count++ if($mlink =~ /ChrX/);
       }else{
          $count++ if($mlink =~ /$chrom\D/);
       }
    }
    if($chrom ==21){
    	print SUM "  X \t\t ";
    }else{
    	print SUM "  $chrom\t\t";
    }
    ########################
    $total_chr +=$count;
    print SUM "$count\n";
  }
  print SUM "----------------------------\n";
  print SUM "TOTAL \t\t$total_chr\n";
  print SUM "===============================================\n";
  print SUM "$time\n";
  close(SUM);
}

sub process_runtime{
  open(TXT,"$toolPATH/rhmapserver/data/logs/process_runtime.txt");
  my $header=<TXT>;
  my @line=<TXT>;
  close(TXT);
  
  &numerically;
  @line=sort numerically (@line);
  
  open(NEW,">$toolPATH/rhmapserver/data/logs/process_runtime.txt");
  flock(NEW,2);
  print NEW "$header";
  $new="T";
  foreach $line (@line){
    $line =~ s/\s+//g;
    @data=split(/,/,$line);
    if($data[0] eq "$count_raw"){
      if($process_time < $data[1]){
	$data[3]=($data[3]+$data[1])/2; # ave runtime
	$data[1]=$process_time;  # min runtime
      }elsif($process_time >$data[2]){
	$data[3]=($data[3]+$data[2])/2; # ave runtime
	$data[2]=$process_time;  # max runtime
      }else{
	$data[3]=($data[3]+$process_time)/2; # ave runtime
      }    
      $data[4]++;
      my $new_line=join(',',@data);
      print NEW "$new_line\n";
      $new="F";
    }else{
      print NEW "$line\n";
    }
  }
  
  if($new eq "T"){
    my $new_line="$count_raw,$process_time,$process_time,$process_time,1";
    print NEW "$new_line\n";
  }
  close(NEW);
}
