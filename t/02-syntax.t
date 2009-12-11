use Test::More qw/no_plan/;
use Keyword;
use Data::Dumper;
ok 1;

keyword method (ident?, proto?, thing, block) {
	ok 1;
}

parse thing ($parser) {
	ok 1;
	ok 1 if !defined $parser;
}

action thing ($match) {
	ok 1;
	ok 1 if !defined $match;
}

parse_thing();

ok 1;

