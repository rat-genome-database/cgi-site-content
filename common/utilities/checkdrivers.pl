#!usr/bin/perl
#
#  Lists all data sources and installed drivers
#

use DBI;
##Probe DBI for the installed drivers
my @drivers = DBI->available_drivers();

die "No drivers found!\n" unless @drivers; # should never happen

### Iterate through the drivers and list the data sources for each one
foreach my $driver ( @drivers ) {
   print "Driver $driver\n";
   my @dataSources = DBI->data_sources( $driver );
   foreach my $dataSource ( @dataSources ) {
      print "\tData Source is $dataSource\n";  
   }
}
exit;