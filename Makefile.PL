use ExtUtils::MakeMaker;
BEGIN {
  if( not $^O =~/cygwin/i ) {
	die "Sorry, you cannot build this module on a non-Cygwin Perl.\n";
  }
}


# Subject to change -- but with with present EU::MM don't know WHAT
# this does anyway!
my $funct =  [ qw{
  XS_Filesys__CygwinPaths_cygwin_conv_to_full_posix_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_full_win32_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_posix_path
  XS_Filesys__CygwinPaths_cygwin_conv_to_win32_path
  } ];

my %stdatt = (
    'NAME'		=> 'Filesys::CygwinPaths',
    'VERSION_FROM'	=> 'CygwinPaths.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'CygwinPaths.pm',
       AUTHOR     => 'Soren Andersen <somian@pobox.com>') : ()),
    'INC'		=> '-I.',
	'XS'        => { 'path_protocol.xs' => 'path_protocol.c' },
	'TYPEMAPS'  => [ 'Cygwin.typemap' ],
	'H'         => [ 'path_protocol.h'],
	'OBJECT'    => 'path_protocol.o',
	'FUNCLIST'  => $funct,
	'OPTIMIZE'  => '-O2 -g -Wundef',
	'LD'        => 'gcc -shared',
	'CCDLFLAGS' => '',
#	'CCFLAGS'   => '-DPERL_USE_SAFE_PUTENV -fno-strict-aliasing',
    'dist'      => { COMPRESS => gzip, SUFFIX => '.gz'},
);
WriteMakefile( %stdatt );

