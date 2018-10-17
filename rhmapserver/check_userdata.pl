#!/usr/bin/perl
#########################################################
#  file name:check_userdata.pl
#  author: JIAN LU
#  date: 5-5-1999
#  check user data to delete them if date exceeds some days.
#  This code will be run under crontab 
#  modified by JL, added RGD::HTML
########################################################
use lib '/rgd/tools/common';
use RGD::HTML;

my $rgd = RGD::HTML->new;
my $toolPATH=$rgd->get_toolPATH; # /rgd/TOOLS
my $wwwPATH=$rgd->get_wwwPATH;   # /rgd/WWW

my $LIMIT_DAY=3;
#my $DIR=shift(@ARGV) || die "No specified dir\n";
my $dir="$toolPATH/rhmapserver/data";
my $report="$dir/logs/rhmapserver_usage.rpt";

my @users=`ls $dir/submission`;

open(RP,">$report");
my $time=`/usr/bin/date`;
print RP "        RH Map Server Usage  Report\n";
print RP "==================================================\n";
print RP "  ACCESS  PROCESSED DATA   USER\n";
print RP "--------------------------------------------------\n";
my $count_users=0;
my $count_total_data=0;


foreach my $u (@users){
  chomp $u;
  my $count_access=0;
  my $count_data=0;
  open(FILE,"$dir/submission/$u");      
  while(my $line=<FILE>){
    if($line =~ /\/\//){
      $count_access++;
    }else{
      $count_data++;
      $count_total_data++;
    }
  }
  close(FILE);
  $count_users++;
	      
  printf RP "%5d ",$count_access;
  printf RP "%10d ",$count_data;
  print RP "        $u\n";	 
  print  "$u\t$count_access\t$count_data\n";
}
print RP "--------------------------------------------------\n";
print RP "  Total Users     Total Proccessed Data \n";
print RP "      $count_users             $count_total_data\n";
print RP "==================================================\n";
print RP "$time";
close(RP);

# remove user data if time is over 3 days
$today=time();
use DirHandle;


foreach my $d (@users){
  chomp $d;
  my $user_dir="$dir/user_data/$d";
  my $d2 = new DirHandle "$user_dir/";

  if (defined $d2){
    while (defined($_2 = $d2->read)){ 
      if($_2 eq "." || $_2 eq ".." || $_2 eq "$d" || $_2 =~ /zip/ || $_2 =~ /tar/) {
      }else {
	my $user_date=$_2;
	$user_date=~ s/\D//g;
	
	my $day=substr(($today-$user_date)/(24*3600),0,1);
	my $data_dir="$user_dir/$user_date  ";
#	print "data_dir $user_dir ";
	if($day >= $LIMIT_DAY){
#	  print "remove $day\n";
	  #remove file dir
	  `/usr/bin/rm -rf $data_dir`;
	  
	  my $zfile="$user_dir/RH_$user_date\.zip";
	  my $tfile="$user_dir/RH_$user_date\.tar";
	  my $link="$wwwPATH/RHMAPSERVER/download/$d";
	  if(-e $zfile){
	    `/usr/bin/rm -rf $zfile $tfile $link`;
	  } 
	}else{
#	  print "$day\n";
	}
      }  
    }
  }
}

