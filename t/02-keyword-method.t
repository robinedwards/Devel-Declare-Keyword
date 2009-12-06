package Foobar;
use strict;
use warnings;
use lib 'examples/';
use Method2;

method name ($a, $b, $c) {
	warn "hello";
};


1;

use Test::More qw/no_plan/;
use Data::Dumper;
ok 1;
