package File::Searcher::Similars;

# {{{ POD, Intro:

# @Author: Tong SUN, (c)2001, all right reserved
# @Version: $Date: 2002/09/16 22:55:09 $ $Revision: 1.10 $
# @HomeURL: http://xpt.sourceforge.net/

=head1 NAME

File::Searcher::Similars - Similar files locator

=head1 SYNOPSIS

  use File::Searcher::Similars;

  File::Searcher::Similars->init(0, \@ARGV);
  similarity_check_name();

Similar-sized and similar-named files are picked as suspicious candidates of
duplicated files.

=head1 DESCRIPTION

What descirbes it better than a actual output. Sample suspicious duplicated
files:

  ## =========
          1574 PopupTest.java          /home/tong/.../examples/chap10
          1561 CardLayoutTest.java     /home/tong/.../examples/chap1
          1570 PopupButtonFrame.class  /home/tong/.../examples/chap6

  ## =========
         22984 BinderyHelloWorld.jpg  /home/tong/...
         17509 MacHelloWorld.gif      /home/tong/...

The first column is the size of the file, 2nd the name, and 3rd the path. The
motto for the listing is that, I would rather my program overkills (wrongly
picking out suspicious ones) than neglects something that would cause me
otherwise years to notice.

By default, File::Searcher::Similars(3) assumes that similar files within the
B<same folder> are OK. Hence you will not get duplicate warnings for generated
files (like .o, .class or .aux, and .dvi files) or other file series. 

Once you are sure that there are no duplications between folders and want
File::Searcher::Similars(3) to scoop further, specify the first parameter as
1. This is very good to eliminate similar mp3 files within the same folder, or
downloaded files from big sites where different packaging methods are used,
e.g.:

  ## =========
         66138 jdc-src.tar.gz  .../ftp.ora.com/published/oreilly/java/javadc
        147904 jdc-src.zip     .../ftp.ora.com/published/oreilly/java/javadc

=cut

# }}}


# {{{ global declaration:

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
&similarity_check_name	
);

# ============================================================== &us ===
# ............................................................. Uses ...

# -- global modules
use strict;			# !
use integer;			# !

use Getopt::Long;
use File::Basename;
use Text::Soundex;

# -- local modules

# -- global variables
use vars qw($progname $VERSION $verbose $debugging);

# ============================================================== &cs ===
# ................................................. Constant setting ...
#
$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);


# ============================================================== &gv ===
# .................................................. Global Varibles ...
#
use vars qw(@filequeue @fileInfo %sdxCnt %wrdLst);

sub dbg_show {};

# @fileInfo: List of the following list:
my ($N_dName, $N_fName, $N_fSize, $N_fSdxl, ) = (0..9);

my $fc_level=0;

# }}}


# Preloaded methods go here.

# ############################################################## &ss ###
# ................................................ Subroutions start ...

# =========================================================== &s-sub ===
# S -  File::Searcher::Similars->init($fc_level, \@ARGV);
# D -  initialize file comparing level and dir queue
# 
# T -  
sub init ($\@) {
    (my $mname, $fc_level, my $init_dirs) = @_;
    #warn "] $fc_level, $init_dirs\n";

    @filequeue = (@filequeue, map { [$_, ''] } @$init_dirs);
    process_files();

    dbg_show(100,"\@fileInfo", @fileInfo);
    dbg_show(100,"%sdxCnt", %sdxCnt);
    dbg_show(100,"%wrdLst", %wrdLst);
}    

# =========================================================== &s-sub ===
# D -  Process given dir recursively
# N -  BFS is more memory friendly than DFS
# 
# T -  $dir="/home/tong/tmp"
sub process_dir {
    my($dir) = @_;
    #warn "] processing dir '$dir'...\n";

    opendir(DIR,$dir) || die "File::Searcher::Similars error: Can't open $dir";
    my @filenames = readdir(DIR);
    closedir(DIR);

    # record the dirname/fname pair to queue
    @filequeue = (@filequeue, map { [$dir, $_] } @filenames);
    dbg_show(100,"filequeue", @filequeue)
}

# =========================================================== &s-sub ===
# I -  Input: global array @filequeue
#      Input parameters: None
# 
sub process_files {
    my($dir, $qf) = ();
    #warn "] inside process_files...\n";

    while ($qf = shift @filequeue) {
	($dir, $_) = ($qf->[0], $qf->[1]);
	#warn "] inside process_files loop, $dir, $_, ...\n";
        next if /^..?$/;
        my $name = "$dir/$_";
	#warn "] processing file '$name'.\n";
	if (-d $name) {
	    # a directory, process it recursively.
	    process_dir($name);
	}
	else {
	    process_file($dir, $_);
	}
    }
}


# =========================================================== &s-sub ===
# S -  process_file($dirname, $fname), process file $fname under $dirname
# D -  Process one file and update global vars
# U -  
#
# I -  Input parameters:
#	$dirname: dir name string
#	$fname:	 file name string
# O -  Global vars get updated
# T -  

sub process_file {
    my ($dn, $fn) = @_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,@rest) =
	stat("$dn/$fn");
    my $fSdxl = [ get_soundex($fn) ]; # file soundex list
    push @fileInfo, [ $dn, $fn, $size, $fSdxl, ];

    dbg_show(100,"fileInfo",@fileInfo);
    map { $sdxCnt{$_}++ } @$fSdxl;
}

# =========================================================== &s-sub ===
# S -  get_soundex($fname), get soundex for file $fname
# D -  Return a list of soundex of each individual word in file name
# U -  $aref = [ get_soundex($fname) ];
#
# I -  Input parameters:
#	$fname:	 file name string
# O -  sorted anonymous soundex array w/ duplications removed
# T -  @out = get_soundex 'Java_RMI - _Remote_Method_Invocation_ch03.tgz';
#      @out = get_soundex 'ASuchKindOfFile.tgz';

sub get_soundex {
    my ($fn) = @_;
    # split to individual words, and
    # weed out empty lines and less-than-3-letter words (e.g. ch12)
    my @out = grep tr/a-zA-Z// >=3, split /[^0-9a-z]/i, $fn;
    # discards file extension
    pop @out;
    # if it is single word, try further decompose SuchKindOfWord
    @out = grep tr/a-zA-Z// >=3, $out[0] =~ /[A-Z][^A-Z]*/g
	if (@out == 1);
    #warn "] get_soundex: @out\n";
    return () unless @out;

    # change word to soundex, record soundex/word in global hash
    map {
	my $sdx = soundex($_);
	$wrdLst{$sdx}{$_}++;
	s/^.*$/$sdx/} @out;
    dbg_show(100,"wrdLst",%wrdLst);
    # weed out duplicates
    my %saw;
    undef %saw;
    @out = grep(!$saw{$_}++, @out);
    
    return sort @out;
}


# =========================================================== &s-sub ===
# S -  similarity_check_name: similarity check on glabal array @fileInfo
# U -  similarity_check_name();
#
# I -  Input parameters: None
# O -  similar files printed on stdout

sub similarity_check_name {

    # get a ordered (by soundex count) multi-soundex file Info array
    my @fileInfos = 
	sort { $#{$a->[$N_fSdxl]} cmp $#{$b->[$N_fSdxl]} } 
        grep { $#{$_->[$N_fSdxl]} >= 1 } @fileInfo;
    dbg_show(1,"\@fileInfos", @fileInfos);

    my @saw = (0) x ($#fileInfos+1);
    foreach my $ii (0..$#fileInfos) {
	#warn "] ii=$ii\n";
	my @similar = (); 
	my $fnl=0;		# 0 is good enough since file at [ii] is 
				# shorter in name than  the one at [jj]
	dbg_show(100,"\@fileInfos", $fileInfos[$ii]);
	push @similar, [$ii, $ii, $fileInfos[$ii]->[$N_fSize] ];
	foreach my $jj (($ii+1) ..$#fileInfos) {
	    #warn "] jj=$jj\n";
	    # don't care about same dir files?
	    next 
		if (!$fc_level && $fileInfos[$jj]->[$N_fSize] 
		    == $fileInfos[$jj]->[$N_fSize]) ;
	    my $file_diff = file_diff(\@fileInfos, $ii, $jj);
	    if ($file_diff >= 50) {
		push @similar, [$ii, $jj, $fileInfos[$jj]->[$N_fSize] ];
		$fnl= length($fileInfos[$jj]->[$N_fName]) if
		    $fnl < length($fileInfos[$jj]->[$N_fName]);
	    }
	}
	dbg_show(1,"\@similar", @similar);
	# output unvisited potential similars by each row, order by fSize 
	@similar = grep {!$saw[$_->[1]]}
	  sort { $a->[2] <=> $b->[2] } @similar;
	next unless @similar>1;
	print "\n## =========\n";
	foreach my $similar (@similar) {
	    print file_info(\@fileInfos, $similar->[1], $fnl). "\n";
	    $saw[$similar->[1]]++;
	}
    }
}

# =========================================================== &s-sub ===
sub file_info ($$$) {
    my ($fileInfos, $ndx, $fnl) = @_;
    return sprintf("%12d %-*s  %s", $fileInfos->[$ndx]->[$N_fSize], 
		   $fnl, $fileInfos->[$ndx]->[$N_fName],
		   "$fileInfos->[$ndx]->[$N_dName]");
}

# =========================================================== &s-sub ===
# S -  file_diff: determind how difference two files are by name & size
# U -  file_diff($fileInfos, $ndx1, $ndx2);
#
# I -  $fileInfos:	reference to @fileInfos
#	$ndx1, $ndx2:	index to the two file in @fileInfos
# O -  100%: files are identical
#	 0%: no similarity at all
sub file_diff ($$$) {
    my ($fileInfos, $ndx1, $ndx2) = @_;

    # find intersection in two soudex array
    my %count = ();
    foreach my $element 
	(@{$fileInfos->[$ndx1]->[$N_fSdxl]},
	 @{$fileInfos->[$ndx2]->[$N_fSdxl]}) { $count{$element}++ }
    # since there is no duplication in each of file soudex
    my $intersection = 
	grep $count{$_} > 1, keys %count;
    # return normal(\delta soudex) * ( 1 - normal(\delta fSize) /2)
    # so the smaller the return value is, the similar the two files are
    $intersection = 
	($intersection  *100 / @{$fileInfos->[$ndx1]->[$N_fSdxl]} );
    dbg_show(100,"intersection", $intersection, $ndx1, $ndx2);
    my $dfSize = abs($fileInfos->[$ndx1]->[$N_fSize] -
		     $fileInfos->[$ndx2]->[$N_fSize]) *100 / 
		($fileInfos->[$ndx1]->[$N_fSize] + 1);
    $dfSize = $dfSize >= 100 ? 100 : $dfSize;
    return $intersection * (100 - $dfSize/2) /100;
}


1;
__END__


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
