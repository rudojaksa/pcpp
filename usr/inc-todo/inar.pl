# inar \@a,$s; checks whether the string $s is in an array @a
sub inar { for(@{$_[0]}) { return 1 if $_ eq $_[1] } return 0 }

# delar \@a,$s; removes 1st instance of the string $s from an array @a, i.e. set it to empty ""
sub delar { for(@{$_[0]}) { $_="" if $_ eq $_[1] }}

# return the length of array without empty "" elements
sub lenar { my $i=0; for(@{$_[0]}) { $i++ if $_ ne "" } return $i }
