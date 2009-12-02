package Foobar;
use strict;
use warnings;
use lib 'examples/';
use KeywordMethod;
use Data::Dumper;

method oki () {
	return 1;
}

method plus ($a, $b) {
	warn "$a + $b";
	return $a + $b;
}

method new () {
	return bless({}, __PACKAGE__);
}

1;

use Test::More qw/no_plan/;
use Data::Dumper;
ok 1;

my $s = Foobar->new;
ok($s);
ok($s->oki);
ok(1);
ok($s->plus(1,2) == 3);
ok(1);
