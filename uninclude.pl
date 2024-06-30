# include .built.uninclude.pl .version.pl

$HELP=<<EOF;

NAME
    uninclude - remove included parts from pcpp generated files

USAGE
    uninclude [OPTIONS] file

DESCRIPTION
    Removes all included parts from a pcpp generated file.  Depends
    on pcpp watermarking.  Can return back the #include statements,
    but they are flattened to a single level direct includes.

OPTIONS
    -h  This help.
    -v  Verbose.
    -l  Just list all includes, indentation by the include level.
   -ni  Don't return back #include statements.

VERSION
    $PACKAGE-$VERSION$SUBVERSION CK($AUTHOR) CK(built $BUILT)

EOF

# ------------------------------------------------------------------------------------- ARGV
# include colors.pl inar.pl print.pl helpman.pl mode.pl
# TODO: uninclude only specified file

for(@ARGV) { if($_ eq "-h")  { printhelp $HELP; exit 0 }}
for(@ARGV) { if($_ eq "-v")  { $VERBOSE=1; $_=""; last }}
for(@ARGV) { if($_ eq "-l")  { $LIST=1; $_=""; last }}
for(@ARGV) { if($_ eq "-ni") { $NOINC=1; $_=""; last }}

# input file
for(@ARGV) { $FILE=$_ and last if $_ ne "" and -f $_ }

# no input file
if(not $FILE) { pr "No input file specified.\n"; exit(1) }

# ------------------------------------------------------------------------------------- MAIN

our $MODE = getmode $FILE; # input file mode: pl, py or c
our $SY = getsy $MODE;	   # comment identifier
our $SYQ = quotemeta $SY;

# read the file
my @included;				# at-current-line list of original files we are inc.
my @body = split /\n/,`cat $FILE`;	# full text

# remove includes - replace included content with :DEL tags
for my $i (0..$#body) {
  my $file="";	# active for include directive line only, included filename
  my $end=0;	# whether we are on the end directive

  # start of included section
  if($body[$i] =~ /^\h*$SYQ\h*included\h+\"([^\"]+)\"/) {
    push @included,$1; $file=$1;
    my $n = lenar \@included,$1;
    my $sp = "  " x (lenar(\@included,$1)-1);
    if($VERBOSE) { pr "${CK_}# uninclude$CD_ $sp$CC_$file$CD_\n" }
    if($LIST) { print "$sp$file\n" }}

  # end of section
  if($body[$i] =~ /^\h*$SYQ\h*end\h+\"([^\"]+)\"/) {
    delar \@included,$1; $end=1; }

  # return the #include directive
  my $n = lenar \@included,$1;
  if($file ne "") {
    if($NOINC) { $body[$i] = "$SY:DEL" }
    else       { $body[$i] = "$SY include \"$file\"" }}

  # remove the line, or not
  elsif($n>0 or $end) {
    $body[$i] = "$SY:DEL" }}

# skip the rest in the list mode
exit if $LIST;

# remove :DEL lines and accompanying empty lines
my @output; my $i=0;
while($i<=$#body) {
  if($body[$i]=~/^$SYQ:DEL/) {
    push @output,"" if $body[$i-1]!~/^\h*$/; # add empty line if not already there
    $i++ while $body[$i]=~/^$SYQ:DEL/ or $body[$i]=~/^\h*$/ } # skip DELs
  push @output,$body[$i++] }

# put together multiple #include
for my $i (0..$#output) {
  $output[$i+1]="$SY:DEL" if $output[$i]   =~ /^$SYQ include \"/ and
                             $output[$i+1] =~ /^\h*$/ and
                             $output[$i+2] =~ /^$SYQ include \"/ }

# TODO: group consecutive includes
# TODO: do quoting according to original (needs pcpp update)

# assembly of the final body string
my $out;
for my $i (0..$#output) {
  if($output[$i] =~ /^$SYQ:DEL/) { next }
  $out .= "$output[$i]\n" }

# emit the output
print $out;

# ----------------------------------------------------------------------- R.Jaksa 2024 GPLv3
