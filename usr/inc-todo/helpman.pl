# helpman-0.2 (c) R.Jaksa 2015,2019, GPLv3
# built: ~/prj/libraries/helpman/helpman.pl
# installed: /map/helpman/pl/helpman.pl
# require "colors.pl"

# include "colors.pl"

{

our ($PKGBUILT,$PKGMSG,$SUBVERSION);

our sub printhelp {
  my $help = shift;
  my $colors = "CWRDKGM";

  my $L = "\#\#\>";	# private  left brace
  my $R = "\<\#\#";	# private right brace
  my %STR;		# private substitutions content strings
  my $id = 0;		# last ID
  sub SBS { return "$L$_[0]$R"; } # return complete private substitution identifier

  # skip commented-out lines
  $help =~ s/(\n\#.*)*\n/\n/g;

  # add version/copyright section
#  my $built = " $CK_($PKGBUILT)$CD_" if $SUBVERSION ne "none";
#  $help .= "VERSION\n";
#  $help .= "    $PKGMSG$built\n\n";

  # escapes
  $help =~ s/\\\)/SBS "brc2"/eg;	# escaped bracket

  ### PARSER ###

  # CC(text)
  my $RE1 = qr/(\((([^()]|(?-3))*)\))/x; # () group, $1=withparens, $2=without
  $STR{$id++}=$4 while $help =~ s/([^A-Z0-9])(C[$colors])$RE1/$1.SBS("c$2$id")/e;

  # options lists
  $STR{$id++}=$2 while $help =~ s/(\n[ ]*)(-[a-zA-Z0-9]+(\[?[ =][A-Z]{2,}(x[A-Z]{2,})?\]?)?)([ \t])/$1.SBS("op$id").$5/e;

  # bracketed uppercase words
  $STR{$id++}="$1$2" while $help =~ s/\[([+-])?([A-Z]+)\]/SBS "br$id"/e;

  # plain uppercase words, like sections headers
  $STR{$id++}=$2 while $help =~ s/(\n|[ \t])(([A-Z_\/-]+[ ]?){4,})/$1.SBS("pl$id")/e;

  ### PROCESSOR ###

  # re-substitute
  $help =~ s/${L}pl([0-9]+)$R/$CC_$STR{$1}$CD_/g;
  $help =~ s/${L}op([0-9]+)$R/$CC_$STR{$1}$CD_/g;
  $help =~ s/${L}br([0-9]+)$R/\[$CC_$STR{$1}$CD_\]/g;

  # CC(text)
  my %cc; $cc{$_} = ${"C".$_."_"} for split //,$colors;
  $help =~ s/${L}cC([$colors])([0-9]+)$R/$cc{$1}$STR{$2}$CD_/g;

  # escapes
  $help =~ s/${L}brc2$R/)/g;

  ### POSTPROCESSOR ###

  # star bullets
  $help =~ s/\n    \* /\n    $CC_\*$CD_ /g;

  print $help; }

}

