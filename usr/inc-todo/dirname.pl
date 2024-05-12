# return the dirname from the path
# ccc/aaa/bbb  -> ccc/aaa
# ccc/aaa/bbb/ -> ccc/aaa
sub dirname { my $p=$_[0]; $p=~s/\/*$//; $p=~s/\/[^\/]*$//; return $p }
