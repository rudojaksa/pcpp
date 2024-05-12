# include sx.pl
{

# return the file mode by the suffix of filename: pl, py or c
my sub getbysx {
  return "pl" if $_[0] eq "pl";
  return "py" if $_[0] eq "py";
  return "c"  if $_[0] eq "c++";
  return "c"  if $_[0] eq "c"; }

# return the mode by the filename, or return the default perl mode
our sub getmode {
  my $sx = sx $_[0];
  my $mode = getbysx $sx;
     $mode = "pl" if not $mode;
  return $mode }

# auto-identify the mode of a list of files by the first identifiable
# file suffix, or return the default perl mode
our sub firstmode {
  my $mode;
  for(@{$_[0]}) {
    $mode = getbysx sx $_;
    last if $mode }
  $mode = "pl" if not $mode;
  return $mode }

# return the comment identifier string by the mode: # or //
our sub getsy {
  return "//" if $_[0] eq "c";
  return "#" }

} # R.Jaksa 2024 GPLv3
