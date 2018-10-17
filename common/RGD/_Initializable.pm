package RGD::_Initializable;
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

  my $self = bless {}, ref($class) || $class;
  $self->_init(%arg);
  return $self;

}

# return 1 at the end of the module
1;

__END__

=head1 NAME: RGD::_Initializable

=head1 SYNOPSIS:

Version 0.1

  The RGD::_Initializable module acts as the 
  RGD module controller.  This subroutine includes the 
  new() subroutine which creates the appropriate rgd_subclass.

  The RGD::_Initializable module was created to coordinate a 
  future split of the RGD module into a variety of submodules which 
  shared similar naming conventions.  

  In the future, you will be able to say:

    $references = RGD::REFERENCES->new(%args); 
  
  With this statement, the _Initializable module will allow 
  the REFERENCES module to inherit the subroutines of the Base 
  RGD::DB module.  It allows for full object-oriented
  development in the future.

=head1 CHANGES:

  11/26/99 v0.1 Simon Twigger - Module creation.

=head1 USAGE:

=head2 CONSTRUCTOR:

=head3 new()

  Constructor for the RGD modules.  

B<Requires:>
  
  %arg -- a hash of keyed values

B<Returns:>

  A reference to an initialized RGD::OBJECT.

B<Usage:>

  RGD::DB->new();                                

=head2 PUBLIC METHODS:

  none

=head2 PRIVATE METHODS:

  none

=head2 DESTRUCTOR:

  none

=head1 CONTACT

  Questions about this module can be directed 
  to Nathan Pedretti, pedretti@mcw.edu.

  Copyright (c) 2000
  Bioinformatics Research Center http://brc.mcw.edu/
  Medical College of Wisconsin
