#! /usr/bin/env perl
# -*- perl -*- 

# ============================================================== &us ===
# ............................................................. Uses ...

# -- global modules
use strict;			# !
use integer;			# !

use Getopt::Long;
use File::Searcher::Similars;

# ============================================================== &gv ===
# .................................................. Global Varibles ...
#
my $fc_level=0;

# == Brief Usage Explaining

die <<"!W/!SUBS!" unless @ARGV;

similars.pl - Similar files locator

Usage:
 similars.pl [--level=1] [dirs...]

!W/!SUBS!

# == Command Line Parameter Handling

GetOptions(
    "level:i"	=> \$fc_level,
    ) || die;

File::Searcher::Similars->init($fc_level, \@ARGV);
similarity_check_name();

# {{{ POD:

# @Author: Tong SUN, (c)2001, all right reserved
# @Version: $Date: 2002/09/16 22:55:09 $ $Revision: 1.2 $
# @HomeURL: http://xpt.sourceforge.net/

=head1 NAME

similars - Similar files locator

=head1 SYNOPSIS

  [perl -S] similars.pl [--level=1] [dirs...]

Similar-sized and similar-named files are picked as suspicious candidates of
duplicated files.

=head1 DESCRIPTION

What descirbes it better than a sample output:

  ## =========
          1574 PopupTest.java          /home/tong/.../examples/chap10
          1561 CardLayoutTest.java     /home/tong/.../examples/chap1
          1570 PopupButtonFrame.class  /home/tong/.../examples/chap6

  ## =========
         22984 BinderyHelloWorld.jpg  /home/tong/...
         17509 MacHelloWorld.gif      /home/tong/...

The motto is, I would rather my program overkills (wrongly picking out
suspicious ones) than neglects something that would cause me otherwise years
to notice.

By default, similars.pl assumes that similar files within the B<same folder>
are OK. Hence you will not get duplicate warnings for generated files (like
.o, .class or .aux, and .dvi files) or other file series. Once you are sure
that there are no duplications between different folders and want similars.pl
to scoop further, specify the --level=1 command line switch. This is very good
to eliminate similar mp3 files within the same folder, or downloaded files
from big sites where different packaging methods are used, e.g.:

  ## =========
         66138 jdc-src.tar.gz  .../ftp.ora.com/published/oreilly/java/javadc
        147904 jdc-src.zip     .../ftp.ora.com/published/oreilly/java/javadc

=head1 AUTHOR

 @Author:  SUN, Tong <suntong at users sourceforge net>
 @HomeURL: http://xpt.sourceforge.net/

=head1 SEE ALSO

File::Compare(3), File::Find::Duplicates(3)

perl(1). 

=head1 COPYRIGHT

Copyright (c) 1997-2001 Tong SUN. All rights reserved.

Distribute freely, but please include the author's info & copyright,
the file's version & url with the distribution.

Support free software movement! Please send you comments, suggestions, bug
reports, patches to the author from the xpt project home URL. They are
warmly welcome. Thank you for using the tools from the xpt project.

=head1 TODO

=cut

# }}}

