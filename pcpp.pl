# include .version.pl .pcpp.built.pl

$HELP=<<EOF;

NAME
    pcpp - simple Perl/Python/C/C++ preprocessor

USAGE
    pcpp [OPTIONS] file file ...

DESCRIPTION
    Simple Perl/Python/C/C++ preprocessor for in-comment directives.
    * process include directives,
    * removes triple-comments.

OPTIONS
     -h  This help.
     -v  Verbose, CC(-vv) for more verbose.
 -e DIR  Exclude directory from a search, multiple -e possible.
    -nt  No triple comments removal.
    -nw  No watermarking of included parts (by #included).
    -ni  No indentation propagation.

     -l  List all files to be used, without producing actual output.
    -ln  Plain list of files to be included, CC(-l1/lp) for level1 or paths.
 -d TGT  Generate dependencies list for Makefile for the TGT target.
    -dd  Print a list of dependencies (input file plus included ones).

INCLUDE DIRECTIVE
    Only lines with the CW("include") directive are recognized.
    Whitespace after the hash is optional, quotes optional.
    Whitespace before the hash is used to indent the included content.

    Include files can be defined by the filename, by the path, or by
    a partial incomplete path.  The path resolving procedure is:

    1. look for direct path from CWD if in top-level file,
    2. look for relative path from file to which we include,
    3. look for CWD-relative path,
    4. find filename recursively in the depth order from CWD,
    5. strip directory part from include and serch by filename.
    
    Double includes are avoided.  Missing includes are ignored.
    Any text after include files is a comment.

    CW(# include "abc.pl")     # Perl, Python
    CW(// include "abc.h")     // C, C++
    CW(#include abc.pl xyz.pl) # multiple files in one include possible
    CW(## include abc.pl)      # not an include due to two hashes
    CW(  # include abc.pl)     # indented include of abc.pl
    CW(# include "abc.pl" # comment)
    CW(# include abc.pl xyz.pl comment)

TRIPLE COMMENTS
    Triple comments are removed, together with preceding empty lines.
    All other comments are propagated to the output.

    CW(### this line will be removed from the Perl/Python code by pcpp)
    CW(/// this line will be removed from the C/C++ code by pcpp)
    CW(#### but this will be kept)

EXAMPLES
    CW(pcpp -v pcpp.pl > pcpp)
    CW(pcpp -d pcpp pcpp.pl > .pcpp.d)

VERSION
    $PACKAGE-$VERSION$SUBVERSION CK($AUTHOR) CK(built $BUILT)

EOF

# ------------------------------------------------------------------------------------- ARGV
# include verbose.pl color.pl array.pl path.pl print.pl printhelp.pl

for(@ARGV) { if($_ eq "-h")  { printhelp $HELP; exit 0 }}
for(@ARGV) { if($_ eq "-v")  { $VERBOSE=1; $_=""; last }}
for(@ARGV) { if($_ eq "-vv") { $VERBOSE=2; $_=""; last }}
for(@ARGV) { if($_ eq "-nt") { $NOTRIPLE=1; $_=""; last }}
for(@ARGV) { if($_ eq "-nw") { $NOWATERMARK=1; $_=""; last }}
for(@ARGV) { if($_ eq "-ni") { $NOIND=1; $_=""; last }}
for(@ARGV) { if($_ eq "-l")  { $LIST=1; $_=""; last }}
for(@ARGV) { if($_ eq "-l1") { $LIST=2; $_=""; last }}
for(@ARGV) { if($_ eq "-lp") { $LIST=3; $_=""; last }}
for(@ARGV) { if($_ eq "-ln") { $LIST=4; $_=""; last }}
for(@ARGV) { if($_ eq "-dd") { $DEPS=1; $_=""; last }}

# dependencies-list target
our $DEPS;
for(my $i=0;$i<$#ARGV;$i++) {
  next if $ARGV[$i] ne "-d";
  $DEPS=$ARGV[$i+1]; $ARGV[$i]=$ARGV[$i+1]="" }

# list of dirs to be excluded
our @EXCL;
for(my $i=0;$i<$#ARGV;$i++) {
  next if $ARGV[$i] ne "-e" or not -d $ARGV[$i+1];
  push @EXCL,$ARGV[$i+1]; $ARGV[$i]=$ARGV[$i+1]="" }

# prepend "./" if needed
for(@EXCL) { $_="./$_" if not /^\.\// and not /^\// }
if($VERBOSE) { eprint "${CK_}# exclude$CD_ $CR_$_$CD_\n" for @EXCL }

# input files
our @FILES; # list of files to be processed
for(@ARGV) { push @FILES,$_ if $_ ne "" }

# -------------------------------------------- GET LIST OF DIRS WITH INCLUDABLE PERL/C FILES
our @DIRS; # recursive list of all local dirs
our %FF;   # per-directory list of all perl/c files
our %NF;   # number of files in each dir

# include mode.pl
our $MODE = firstmode \@FILES;	# input file mode (by 1st file): pl, py or c
our $SY = getsy $MODE;		# comment identifier
our $SYQ = quotemeta $SY;

# include scandirs.pl
getsubdirs ".";	# fill-up DIRS, FF and NF
resort();	# re-sort DIRS

if($VERBOSE>1) {
  my $l = $L1+3;
  for my $d (@DIRS) {
    eprintf "$CK_#  search $CG_%-${l}s$CD_",$d;
    eprint " $CK_$_$CD_" for @{$FF{$d}};
    eprint "\n" }}

# ------------------------------------------------------------------------- PROCESS INCLUDES
# include include.pl

# auxiliary output buffer, as the include recursion would break simple print to stdout,
# we print to the @output buffer instead, then at the end print it to the stdout
my @output;

# TODO: header with timestamp and list of inputs
# TODO: #! interpreter identifier

# for dependencies list
our $DEPLIST;

# add each argv file to the output
push @output,addfile($_) for @FILES;

# skip the rest in the list mode
exit if $LIST;

# print deps
print "$DEPLIST\n" and exit if $DEPS==1;
print "$DEPS: $DEPLIST\n" and exit if $DEPS;

# remove tripled comments
if(not $NOTRIPLE) {
  for my $i (0..$#output) {
    if(($MODE eq "c" and $output[$i]=~/^\h*\/\/\/[^\/]/) or $output[$i]=~/^\h*\#\#\#[^\#]/) {
      $output[$i] = "$SY:DEL $output[$i]";
      my $j=$i-1; while($j>=0 and $output[$j]=~/^\h*$/) {
	$output[$j--] = "$SY:DEL\n" }}}}

# multiple :SEP tags
for my $i (0..$#output-1) {
  $output[$i]="$SY:DEL\n" if $output[$i]=~/^$SYQ:SEP/ and $output[$i+1]=~/^$SYQ:SEP/ }

# surviving :SEP tags, skip if previous/next line is empty, otherwise add new empty line
for my $i (0..$#output) {
  next if not $output[$i] =~ /^$SYQ:SEP/;
  if($i>0 and $output[$i-1] =~ /^\h*$/) { $output[$i] = "$SY:DEL\n" }
  elsif($i<$#output and $output[$i+1] =~ /^\h*$/) { $output[$i] = "$SY:DEL\n" }
  else { $output[$i] = "\n" }}

# :DEL tags and assembly of the final output string
my $out;
for my $i (0..$#output) {
  if($output[$i] =~ /^$SYQ:DEL/) { next }
  $out .= $output[$i] }

# emit the output
print $out;

# ------------------------------------------------------------------ R.Jaksa 2000,2024 GPLv3
