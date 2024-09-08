# path.pl generated from libpl-0.1/src/path.pl 2024-08-29
{ # FILESYSTEM PATHS ROUTINES

# return the dirname from the path
# ccc/aaa/bbb  -> ccc/aaa
# ccc/aaa/bbb/ -> ccc/aaa
sub dirname { my $p=$_[0]; $p=~s/\/*$//; $p=~s/\/[^\/]*$//; return $p }

# return file suffix
sub sx { my $s=$_[0]; $s=~s/^.*\.//; return $s }

# beautify($path,$cwd)
our sub beautify {
  my $qcwd = quotemeta $_[1];								# CWD
  my $p1=$_[1]; $p1=~s/\/*$//; $p1=~s/[^\/]*$//; $p1=~s/\/*$//; my $qp1 = quotemeta $p1;# parent
  my $p2=$p1; $p2=~s/\/*$//; $p2=~s/[^\/]*$//; $p2=~s/\/*$//; my $qp2 = quotemeta $p2;	# grandparent
  my $qh = quotemeta $ENV{HOME};							# home
  my $p = $_[0];

  $p =~ s/^$qcwd\/// if $qcwd;		# /abc/def/ghi -> ghi if cwd=/abc/def
  $p =~ s/^$qp1\//..\// if $qp1;	# /abc/def/ghi -> ../ghi if cwd=/abc/def/xyz
  $p =~ s/^$qp2\//..\/..\// if $qp2;	# /abc/def/ghi -> ../../ghi if cwd=/abc/def/xyz/ijk
  $p =~ s/^$qh\//~\// if $qh;		# /home/abc/xyz -> ~/xyz

  $p =~ s/^\.\///;			# remove the leading "./"

  return $p }

# just remove the leading "./" from the path
sub undot { my $p=$_[0]; $p=~s/^\.\///; return $p }

} # R.Jaksa 2024 GPLv3
