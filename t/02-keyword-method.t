package Foobar;
use strict;
use warnings;
use lib 'examples/';
use Method2;

method something ($a, $b, $c) { 
	warn "oooK"; 
};


1;

use Test::More qw/no_plan/;
use Data::Dumper;

Foobar->something;

ok 1;
