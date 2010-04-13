package Foobar;
use strict;
use warnings;
use lib 'examples/';
use Methods;

our $CALLS;

method add ($a, $b, $c) { 
	return $a+$b+$c;
}

1;

use Test::More qw/no_plan/;
use Data::Dumper;


my $r = Foobar->add(1,2,3);
ok($r = 6);
ok($Foobar::CALLS == 1, 'post block hooks work!');

ok 1;
