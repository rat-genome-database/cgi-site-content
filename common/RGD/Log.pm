#!/usr/bin/perl


####################################
#
# RGD::Log.pm
#
# Copyright (c) 1999 Simon Twigger, Medical College of Wisconsin,
#
# Basic logging object, output saved as XML
#
####################################


####################################
#
# v0.1     11/26/99
#
#
#
#
#
#
####################################

package RGD::Log;
$VERSION = 0.1; # put it here before strict.

use strict;
use Carp;


####################################
#
# new()
#
# Constructor method
#
#####################################

sub new {
  my ($class, %arg) = @_;

  bless {
         _log_dir => $arg{log_directory} || "/rgd/logs",
         _log_file => $arg{log_file} || "default.log",
         _caller => $arg{script_name} || "none_specified",
         _caller_version => $arg{script_version} || "0.00",
        }, $class;
}


# Simple public accessor functions to get logging directory and file
sub get_log_dir { $_[0]->{_log_dir} }
sub get_log_file { $_[0]->{_log_file} }

# Private accessor fuctions
sub _get_caller { $_[0]->{_caller} }
sub _get_caller_v { $_[0]->{_caller_version} }



####################################
#
# open_log_file
#
# Opens log file, gets a lock, returns filehandle
#
#####################################

sub open_log_file {

  my $self = shift(@_);
  
  # First need to open log file
  my $logfile = scalar $self->get_log_dir() . "/" . scalar $self->get_log_file() ;
  
  open (LOG, ">>$logfile.log") or croak "Cant open log file to write: $logfile.log $!";
  
  # lock the file for our exclusive use
  flock(LOG,2);
  
  # in case someone appended while we were waiting
  # reset the end of file pointer to correct value
  seek (LOG, 0, 2);

  return *LOG;

}


####################################
#
# close_log_file
#
# removes exclusive lock and closes filehandle
#
#####################################

sub close_log_file {

  my $self = shift @_;
  *LOG = shift @_;

  # remove the exclusive lock on the log file
  flock(LOG, 8);

  close LOG;

  return 1;
}




####################################
#
# add_entry
#
# Add a new usage entry to the log file
#
#####################################


sub add_entry {
  
  my %defaults = (
                  input_parameters => (),
                  output_parameters => (),
                  remote_address => $ENV{'REMOTE_ADDR'} || "NA",
                  remote_host => $ENV{'REMOTE_HOST'}|| "NA",
                  referer => $ENV{'HTTP_REFERER'}|| "NA",
                  browser =>  $ENV{'HTTP_USER_AGENT'}|| "NA",
                  date => scalar localtime(),
                  );

  my $self = shift(@_);
  my %args = (%defaults,@_);

   *LOG = $self->open_log_file();

  #############################
  # Start the XML record with script and user information
  #############################

  # print LOG "</LOG.pm Entry>\n";
  print LOG "<log_entry date=\"$args{date}\">\n";
  print LOG "\t</script name=\"" . $self->_get_caller(). "\" version=\"" . $self->_get_caller_v() . "\">\n";
  print LOG "\t</user_info remote_address=\"$args{remote_address}\" remote_host=\"$args{remote_host}\">\n";
  print LOG "\t</referer url=\"$args{referer}\">\n";


  #############################
  # add in the input parameters
  #############################

  print LOG "\t<input_parameters>\n";
  
  # loop around all the parameters outputing the key/value pairs
  foreach my $in_param (keys %{ $args{input_parameters}} ) {    
    print LOG "\t\t</parameter name=\"$in_param\" value=\"" . $args{input_parameters}{$in_param} . "\">\n";
  }
  print LOG "\t</input_parameters>\n";



  #############################
  # add in the output parameters
  #############################

  print LOG "\t<output_parameters>\n";

  # loop around all the parameters outputing the key/value pairs
  foreach my $out_param (keys %{ $args{output_parameters}} ) {    
    print LOG "\t\t</parameter name=\"$out_param\" value=\"" . $args{output_parameters}{$out_param} . "\">\n";
  }

  print LOG "\t</output_parameters>\n";



  #############################
  # finish the XML entry
  #############################
  print LOG "</log_entry>\n";

 
  $self->close_log_file(*LOG) || croak "Cant close logfile: $!\n";

}

# return 1 at the end of the module
1;

__END__

=head1 NAME: RGD::Log

=head1 SYNOPSIS:

The RGD::Log module allows all RGD tools to 
write error and useage logs in a common XML 
format.  In the future, these logs can be parsed 
to diagnose common problems.

=head1 CHANGES:

  06/06 -- Nathan Pedretti added documentation for useage and 
           modules.

=head1 USEAGE:

At the top of your perl program, include the following line:

  use RGD::Log;
  
This follows the standard syntax for 'using' any perl module.

=head2 CONSTRUCTOR:

=head3 sub new();

Before you use any of the routines listed in the methods 
section of this document, you must construct a log object as follows:

  my $LOG = RGD::Log->new( 
              log_directory => '/rgd/LOGS/views/',
              log_file => 'default',
              script_name => 'none_specified',
              script_version => '0.00',
            );

B<Requires:>

While perl will not require you to specify any of the 
variables listed above, if you are coding for the 
Bioinformatics Research Center, you must specify at 
least the following:

  log_directory : /rgd/LOGS/toolname or /rgd/LOGS/contentarea(s)
  log_file : script writing the log file prefixed with:
              error_ : for error logs
             useage_ : useage logs

B<Returns:>

Returns the reference to a RGD::Log object which can 
then be used throughout your script to log information.
            
=head2 METHODS:

=head3 sub get_log_dir ();

The subroutine B<get_log_dir> does not require any 
parameters.  It returns the log directory as specified 
in the constructor method.

B<Requires:>

No parameters specified.

B<Returns:>

  log directory with ending "/" 

B<Useage:>

=head3 sub get_log_file ();

The subroutine B<get_log_file> does not require any 
parameters.  It returns the log file name--without the .log 
suffix--as specified in the constructor method.

B<Requires:>

No parameters specified.

B<Returns:>

  log file name b<without> .log suffix.

B<Useage:>

=head3 sub add_entry();

The subroutine B<add_entry()> adds a log 
entry to the file specified in the constructor routine.

   $LOG->add_entry(
		   input_parameters => {
		               name1 => value_pairs1
		               name2 => value_pairs2
		               ...
				       },
		   output_parameters => {
		               name1 => value_pairs1
		               name2 => value_pairs2
		               ...
					},
		  );

B<Requires:>

You are not required to pass any name\value pair 
to the subroutine, but this doesn't make much sense.  
Pass important variables, form field values, etc as 
input_parameters, and results of those actions as output parameters. 

You can pass any number of name\value pairs in each catagory.

B<Returns:>

No data returned.

=head3 PRIVATE SUBROUTINES

These subroutine are not for public use, but are 
listed for documentation completeness.

  sub open_log_file ();
  sub close_log_file ();  

=head2 DESTRUCTOR:

Currently, there is no destructor routine 

=head1 CONTACT:

Contact Simon Twigger (simont@mcw.edu) to report bugs or suggest modifications.

Copyright (c) 2000, Bioinformatics Research Center
Medical College of Wisconsin

