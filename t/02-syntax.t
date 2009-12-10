use Test::More qw/no_plan/;
use Keyword;
use Data::Dumper;
ok 1;

keyword method (ident?, proto?, somethingelse) {
	warn Dumper @_;
};


ok 1;

