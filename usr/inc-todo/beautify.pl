# beautify the path
# for now just remove the leading "./"
sub beautify { my $p=$_[0]; $p=~s/^\.\///; return $p }
