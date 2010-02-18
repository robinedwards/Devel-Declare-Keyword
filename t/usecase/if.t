use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'examples/';
use Perl6If;
use Data::Dumper;

ok 1;

if 1 {
	ok 1 ;
}
else {
	nok 1;
}

ok 1;
