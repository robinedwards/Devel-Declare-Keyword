use Test::More qw/no_plan/;
use Keyword;
use Data::Dumper;
ok 1;

keyword method (ident?, proto?, thing, block) {
	ok 1;
}

parse thing ($parser) {
	warn Dumper $parser;
}

ok 1;

