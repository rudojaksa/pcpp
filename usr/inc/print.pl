# print.pl generated from libpl-0.1/src/print.pl 2024-08-29
{

# stderr prints, 'e' for error, allows the "grep print" to find it
our sub eprint  { print  STDERR @_ }
our sub eprintf { printf STDERR @_ }

}
