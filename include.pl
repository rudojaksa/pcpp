{ # ------------------------------------ RESOLVE INCLUDE DIRECTIVES AND ASSEMBLE FULL OUTPUT

# verbose printout of includes, globals: $L1, $L2, $level, $how
my sub report {
  my $path=$_[1];
  my $c1=$_[0];	# filename color
     $c1=$CG_ if $c1 eq $CC_ and defined $path and $path eq $file;
  my $c2=$c1;	# path color
     $c2=$CG_ if $c1 ne $CK_ and $c1 ne $CM_ and defined $path;
  my $sp = "  " x ($level-1);

  if($VERBOSE or $LIST==1) {
    my $p = "include";
       $p = "   load" if $how eq "direct";
       $p = "   skip" if $c1 eq $CK_;
       $p = "missing" if $c1 eq $CR_;
    my $h = $how;
       $h = 0 if $how eq "missing" or $how eq "direct";
    my $s = "$CK_$SY$CD_ $CK_$p$CD_ $sp$c1$file$CD_";
       $s.= " $CK_$h$CD_" if $h;
       $s.= " $c2$path$CD_" if defined $path and $path ne $file;
    eprint "$s\n" }

  if($LIST and $c1 ne $CK_ and $how ne "missing" and $level>=1) {
    if   ($LIST==3) { print "$sp$path\n" }
    elsif($LIST==2) { print "$sp$file\n" if $level==1 }
    elsif($LIST==4) { print "$sp$file\n" }}}

# ------------------------------------------------------------------------------------- MAIN

# line by line add a file to the output, parse #include directives
our sub addfile {
  local	 $file=$_[0];
  my	 $rdir=$_[1]; # current relative subdir
  local	$level=$_[2]; # recursion level
  my   $indent=$_[3]; # requested additional indentation space for includes
  my	   $ok=0;     # 1=alreadyincluded 2=speculativepath 3=filefound
  my	 $path;	      # full path (to be found)
  local	  $how;	      # verbose: how was the path found

  $level=0 if not defined $level;		# start level zero
  $indent="" if not defined $indent;

  # look for file in CWD using direct path if no recursion yet
  if(not $level) {
    $path = $file;				# try direct explicit path
    if(inar \@INCLUDED,$path) { $ok=1 }		# skip already included
    elsif(-f $path) { $ok=3 }
    $how = "direct" if $ok }

  # look for file using explicit path relative to the parent-file dir
  if(not $ok) {
    $path = "$rdir/$file";			# try path relative to parent
    if(inar \@INCLUDED,$path) { $ok=1 }		# already included
    elsif(-f $path) { $ok=3 }
    $how = "from $rdir" if $ok }

  # look for file using explicit path relative to current working directory (in recursion)
  if(not $ok) {
    $path = "$file";				# try path relative to CWD
    if(inar \@INCLUDED,$path) { $ok=1 }		# already included
    elsif(-f $path) { $ok=3 }
    $how = "from cwd" if $ok }

  # look for file recursively (by filename)
  if(not $ok) {
    my $fn=$file; $fn=~s/^.*\/// if $fn=~/\//;	# strip the explicit dir
    my $dir; for(@DIRS) {			# loop through dirs
      $dir = $_;
      $path = "$dir/$fn";			# try path relative to every dir
      $ok=1 and last if inar \@INCLUDED,$path;	# already included
      $ok=3 and last if inar $FF{$dir},$fn }	# found => proceed
    $how = "found" if $ok;

    # speculative
    if($ok==3 and $fn ne $file) {		# if file contained dirname
      my $fd = quotemeta "/".dirname($file);	# directory part of the include name
      $ok=2 if not $dir =~ /$fd$/ }		# is speculative
    $how = "guess" if $ok==2 }

  # otherwise missing
  if(not $ok) {
    $path = $file;				# orig name, needed for deplist
    $how = "missing" }

  # verbose/list
  if   ($ok==1) { report $CK_,beautify($path) }	# redundant, double include
  elsif($ok==2) { report $CM_,beautify($path) }	# speculative
  elsif($ok==3) { report $CC_,beautify($path) }	# OK
  else          { report $CR_,$file }		# not found

  # deps (show also nonexistent files, to allow to be generated)
  $DEPLIST.=beautify($path)." " if $DEPS;

  return if $ok==0;				# file not found
  return if $ok==1; # file already included (TODO: accept if requested, but avoid recursion)
  push @INCLUDED,$path;				# register file
  $rdir = dirname $path if $ok;	# save for the explicit path lookup in next recursion

  # important: filename regexes
  my $IN1 = qr/^\h*\"([^\"]+)\"/;		# quoted include
  my $IN2;					# unquoted include
     $IN2 = qr/^\h*([\/a-zA-Z0-9\._-]+\.pl)/ if $MODE eq "pl";
     $IN2 = qr/^\h*([\/a-zA-Z0-9\._-]+\.py)/ if $MODE eq "py";
     $IN2 = qr/^\h*([\/a-zA-Z0-9\._-]+\.h)/  if $MODE eq "c";

  my @output; # the output line-by-line

  # watermark for new file, at the included-file indentation level
  if(not $NOWATERMARK and $level) {
    my $ind=$indent; $ind="" if $NOIND;
    push @output,"$SY:SEP\n";
    push @output,"$ind$SY included \"$file\"\n" } # TODO: also comment

  # read cuurent file and recursively resolve include directives
  for my $line (split /\n/,`cat $path`) {			# <- we read files here!
    if($line =~ /^(\h*)$SYQ\h*include\h+(.*?)$/) {		# identify include line
      my $ind=$1; my $s=$2; my $OK=0;      
      while($s=~s/$IN1// or $s=~s/$IN2//) {			# parse it
	push @output,addfile($1,$rdir,$level+1,$ind); $OK=1 }	# recurse inside
      next if $OK }						# go for the next line
    if($indent and not $NOIND and not $line=~/^\h*$/) { $line="$indent$line" }	# indentation
    push @output,"$line\n"; }					# <- add regular lines here!

  # watermark footer
  if(not $NOWATERMARK and$level) {
    my $ind=$indent; $ind="" if $NOIND;
    push @output,"$ind$SY end \"$file\"\n";
    push @output,"$SY:SEP\n" }

  return @output; }

} # ---------------------------------------------------------------- R.Jaksa 2023,2024 GPLv3
