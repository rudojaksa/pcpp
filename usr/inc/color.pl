# color.pl generated from libpl-0.1/src/color.pl 2024-08-27
{ # TERMINAL COLORS

our $CR_="\033[31m"; # color red
our $CG_="\033[32m"; # color green
our $CM_="\033[35m"; # color magenta
our $CC_="\033[36m"; # color cyan
our $CW_="\033[37m"; # color white
our $CK_="\033[90m"; # color black
our $CD_="\033[0m";  # color default

# return length of string without escape sequences
our sub esclen {
  my $s = shift;
  $s =~ s/\033\[[0-9]+m//g;
  return length $s; }

} # R.Jaksa 2003,2024 GPLv3
