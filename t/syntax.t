use Test::More qw/no_plan/;
use Devel::Declare::Keyword;
use Data::Dumper;
ok 1;

keyword method (Maybe[Ident] $ident, Maybe[Proto] $xd, Thing $p, Block $b) {
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
action_thing();

ok 1;

