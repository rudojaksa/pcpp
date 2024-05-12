{ # FIND LIST OF DIRS WITH INCLUDABLE PERL/C FILES

# check if filename is includable pl/py/c file
# according to the MODE and suffix
my sub isinc {
  return 1 if not defined $MODE;
  return 1 if $MODE eq "pl" and sx($_[0]) eq "pl";
  return 1 if $MODE eq "py" and sx($_[0]) eq "py";
  return 1 if $MODE eq "c"  and sx($_[0]) eq "h";
  return 0 }

# getsubdirs "."; looks for all dirs with .pl/.h files in "."
# fills-up @DIRS and %FF,%NF
our sub getsubdirs {
  my $dir = $_[0];
  my @all; opendir(DIR,$dir); @all=readdir(DIR); closedir(DIR);
  my @ff; for(@all) { push @ff,$_ if isinc $_ }		# save .pl/.c filenames
  if(@ff) { push @DIRS,$dir; $NF{$dir}=@ff; $FF{$dir}=\@ff } # save if nonempty
  for(@all) {
    next if /^\./;					# skip hidden dirs
    my $path = "$dir/$_";
    next if inar \@EXCL,$path;				# skip excluded dirs
    getsubdirs($path) if -d $path; }}

# SORT SEARCH DIRS TO PUT BETTER UP
# 1st compare by number of slashes - to look in current directory first
# 2nd compare by number of .pl/.c files in dir - just speculative speedup
my sub subcompare {
  my $ca = $a=~tr/\///;	# count of / in $a
  my $cb = $b=~tr/\///; # in $b
  if   ($ca<$cb) { return -1 }
  elsif($ca>$cb) { return 1 }
  else {
    if   ($NF{$a}>$NF{$b}) { return -1 }
    elsif($NF{$a}<$NF{$b}) { return 1 }
  else { return 0 }}}

# re-sort DIRS
our sub resort {
  @DIRS=();
  push @DIRS,$_ for sort subcompare keys %NF }

} # R.Jaksa 2024 GPLv3
