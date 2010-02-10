package Foobar;
use strict;
use warnings;
use lib 'examples/';
use Methods;

method add ($a, $b, $c) { 
	return $a+$b+$c;
}


1;

use Test::More qw/no_plan/;
use Data::Dumper;

ok (Foobar->add(1,2,3)==6);

ok 1;
