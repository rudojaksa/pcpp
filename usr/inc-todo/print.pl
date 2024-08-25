# stderr prints, 'e' for error, allows the "grep print" to find it
sub eprint  { print  STDERR @_ }
sub eprintf { printf STDERR @_ }
