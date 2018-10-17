#!/usr/local/bin/perl

#use lib "/rgd/tools/common";
#use RGD::XML::Cache;

#my $cache = RGD::XML::Cache->new(
#                                 base_url    => $baseURL,
#				 page_length => 10,
#				 cache_directory => "/tmp/",
#				 cache_file => $pid . ".$num_hits",
#				 script_dir => "/tmp/",
#				 script_name => "george",
#				 script_version => "1",
#				 order_field => 'asc',
#				 parameters => \%ARGV, # get the CGI form parameter list as a hash
#				);

print "Content-type: text/html\n\n";
print "<h2>Environment Variables:</h2> <br>\n";
foreach ( keys %ENV ) { 
	$key = $_;
	print "$key : " . $ENV{$key} . "<br>\n";
}
print "DONE<br>";
