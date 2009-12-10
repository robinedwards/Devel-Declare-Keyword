use Test::More qw/no_plan/;
use Keyword;
use Data::Dumper;
ok 1;

keyword method (ident?, proto?, thing, block) {
	warn Dumper $ident;
	warn Dumper $proto;
	warn Dumper $thing;
	warn Dumper $block;
};


ok 1;

