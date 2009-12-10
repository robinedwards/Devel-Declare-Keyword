package Foobar;
use strict;
use warnings;
use lib 'examples';
use Methods;

method something ($a, $b, $c) { 
	return 1; 
};


1;

use Test::More qw/no_plan/;
use Data::Dumper;

ok (Foobar->something);

ok 1;
