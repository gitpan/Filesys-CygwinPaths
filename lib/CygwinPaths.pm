package Filesys::CygwinPaths;

use 5.006;
use strict;
use warnings;

BEGIN {
  use Carp qw{verbose};
  if( not $^O =~/cygwin/i ) {
	Carp::croak "You are trying to use this module with a Perl that appears to not ".
	     "be Cygwin perl. This is most inadvisable. -- ";
  }
}

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Filesys::CygwinPaths ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( vetted_path
     fullposixpath posixpath fullwin32path win32path )
  ]  );

our @EXPORT = ( qw{ PATHS_protocol vetted_path } );
our @EXPORT_OK = ( qw{fullposixpath posixpath fullwin32path win32path},
                   '$PATHS_PROTOCOL');
use vars qw( $VERSION $PATHS_PROTOCOL );

=head1 NAME

Filesys::CygwinPaths - Perl extension to get various conversions of path specifications
in the Cygwin port of Perl.

=cut

my $discard=length <<'=head1 VERSION';

=pod

=head1 VERSION

$VERSION = '0.02' ;

=cut

=cut

bootstrap Filesys::CygwinPaths $VERSION;

sub MAX_PATH {
  return 260 - 1; # how it is defined in sys/params.h
}


=head1 SYNOPSIS

    use Filesys::CygwinPaths;
    PATHS_protocol('cyg_win32');
	my $HOME = $ENV{'HOME'};

    my @pics_to_ogle = glob("$HOME/mypics/*.jpg");
	foreach my $pic (@pics_to_ogle) {
	   system('C:/Applications/IrfanView/iview32',
	        vetted_path($pic), '/bf /pos=(0,0) /one', "/title=$pic")
         or die "No fun today!";
    }
	system('C:/Applications/IrfanView/iview32', '/killmesoftly');
	
   OR

    use Filesys::CygwinPaths ':all';
	my $windows_groks_this = fullwin32path("$ENV{HOME}");
	my $posix_style = fullposixpath($ENV{'USERPROFILE'});
	if(posixpath($windows_groks_this) ne $posix_style) {
	   print "You don't keep your bash HOME in your NT Profile dir, huh?\n";
    }

=cut

sub vetted_path {
  my $returnpath;
  my $inpath = shift;
  if(not defined $PATHS_PROTOCOL) {
	Carp::carp 'You ought to set $PATHS_PROTOCOL'.
	 ' before calling this subroutine!'.
	 "\nDefaulting to 'cyg_mixed' style. -- ";
	 &PATHS_protocol();
  }

  $returnpath =
   $PATHS_PROTOCOL eq 'cyg_mixed'?
      do{ ($returnpath = win32path($inpath)) =~s@\\@/@g; }
  :$PATHS_PROTOCOL eq 'cyg_posix'?
      posixpath($inpath)
  :$PATHS_PROTOCOL eq 'cyg_win32'?
      win32path($inpath)
  : '' # should never happen.
  ; # end psuedo case / switch statement

   $returnpath;
}


sub PATHS_protocol {
  my $selfobj ; # OO-ready
  if(ref $_[0]) {
	$selfobj = shift;
  }
  if(not $_[0] and not defined $PATHS_PROTOCOL) {
	$PATHS_PROTOCOL = q[cyg_mixed];
  } elsif(defined $_[0]) {
	  my $arg = shift @_;
	  $arg eq 'cyg_mixed'?
		 do{ $PATHS_PROTOCOL = $arg; }
	: $arg eq 'cyg_posix'?
	     do{ $PATHS_PROTOCOL = $arg; }
	: $arg eq 'cyg_win32'?
	     do{ $PATHS_PROTOCOL = $arg; }
	:
      do{ Carp::croak "Invalid PATHS_PROTOCOL name: \"$arg\" -- "; }
	; # end psuedo case / switch statement.
  }
  $selfobj->{'PATHS_PROTOCOL'} = $PATHS_PROTOCOL if defined($selfobj); 
  return $PATHS_PROTOCOL;	
}


#-----------------------------------------------------------------#
#                                                                 #
#       CALL THE ACTUAL XS INTERFACE C FUNCTIONS                  #
#                                                                 #
#-----------------------------------------------------------------#


sub fullposixpath {
  my ($input, $retval, $output);
  $input = shift;
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_full_posix_path($input);
}


sub fullwin32path {
  my ($input, $retval, $output);
  $input = shift;
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_full_win32_path($input);
}


sub posixpath {
  my ($input, $retval, $output);
  $input = shift;
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_posix_path($input);
}


sub win32path {
  my ($input, $retval, $output);
  $input = shift;
  if( $input eq '') {
	Carp::carp "No path argument supplied! -- ";
	return '';
  }
  $output = cygwin_conv_to_win32_path($input);
}

1;
__END__

=head1 DESCRIPTION

B<Filesys::CygwinPaths> is a B<Cygwin-specific> module created to ease the
author's occasional pique over the little quirks that come up with using Perl
on Cygwin. The subroutines it exports allow various kinds of path
conversions to be made in a fairly concise, simple, procedural manner. At
the present time the module does not have an OO interface but one might be
added in the future. The module can be used according to two diffent
approaches, which are outlined below.

Note: Hopefully it is evident that the module can be neither built nor used
on any platform besides Perl built for Cygwin, and there would be no reason
to want to do so.

=head2 Usage Styles

Two slightly different ways of using B<Filesys::CygwinPaths> are available. The
first, and recommended, way is to tell Perl once and for all (for the
duration of your script) what I<protocol> you need to use in conversing
with, say external non-Cygwin applications. To do this, say something like:

S<<    C<<use Filesys::CygwinPaths;>> >>
S<<    C<<PATHS_protocol( 'cyg_mixed' );>> >>
S<<    C<<my $own_name = vetted_path($0);>> >>
S<<    C<<print "I am $own_name, how are you today?\n";>> >>

And that will set the I<protocol> to C<cyg_mixed> for the duration of the
script. The 3 recognized settings for C<PATHS_protocol()> are:

S<<       C<<cyg_mixed>> ( like: F<<C:/foobar/sugarplum/fairy.txt>> ) >>
S<<       C<<cyg_win32>> ( like: F<<C:\foobar\sugarplum\fairy.txt>> ) >>
S<<       C<<cyg_posix>> ( like: F<</cygdrive/c/sugarplum/fairy.txt>> ) >>

Alternatively you might prefer the more specific and elaborate full set of
subroutines to be made available to you (C<:all>). These can be called by
name to get the specific translation protocol you desire. Listed below.

=over 4

=item vetted_path($path_in)

make any translations necessary to transform the path argument according to the setting of the global (B<Filesysy::CygwinPaths>) variable C<PATHS_PROTOCOL>. If this variable is not already set when C<vetted_path()> is called, it will set to the default of C<cyg_mixed> and complain a little at you. Set the script-wide protocol you desire for C<vetted_path()> to use by

	(a) setting PATHS_PROTOCOL directly in your script

(not B<my>, it is a variable in the B<Filesys::CygwinPaths> namespace which
is imported by default, it must therefore not be a lexical in your script or
will have no effect).

    (b) calling the subroutine C<PATHS_protocol> with the desired value.


=item PATHS_protocol(<style>)

set or query the current I<protocol> under which C<vetted_path> will
return a path spec.


=item posixpath($path_in)

return the POSIX-style path spec (filename) for the given argument. If the
argument is a relative path, returns a relative path.


=item win32path($path_in)

return the Win32 (Microsoft Windows standard) style path spec for the given
argument. If the argument is a relative path, returns a relative path.


=item fullposixpath($path_in)

return the fully-qualified (absolute) path spec (filename) for the given
argument, in POSIX-style.


=item fullwin32path($path_in)

return the fully-qualified path spec in Windows style.

=back


=head2 Notes on the XS programming (C interface)

TODO.

=item *

Another way to do the call to the xs interface would have been, maybe:

 sub conv_to_win32_path {
   my $in= shift(@_);
   my $out= "\0" x PATH_MAX();
   cygwin_conv_to_win 32_path($in,$out);
   return $out;
 }

=back

=head1 BUGS

Perl does not know how to interpret the C<~/> shell abbreviation for the
login user's HOME directory (it is B<bash> or another POSIX-y shell that
does this); therefore do not use C<~/> in args to any of the functions. Use
$ENV{HOME} instead.


=head1 SEE ALSO

L<File::Spec>, L<File::Spec::Unix>, L<File::Basename>, L<File::PathConvert>,
L<Env>.

=head1 CREDITS

Tye McQueen for his XSeedingly generous help with the C interface work for
this module. ;-)

Kazuko Andersen for her patience and for bringing food so I could finish
working on this module ;-).

=head1 AUTHOR

Soren (Michael) Andersen (CPAN id SOMIAN), <somian@pobox.com>.


=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2002 by Soren Andersen.
This program is free software; you can redistribute it and/or
modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
MA 02139, USA.


=cut

