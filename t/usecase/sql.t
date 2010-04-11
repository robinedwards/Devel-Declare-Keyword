use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'examples/';
use SQL;
use Data::Dumper;

ok (1, 'parsed ok');
SKIP: {
	skip "need to setup db", 2;
	ok(SQL::CONNECT("dbi:Pg:dbname=test;host=localhost;port=5432"));
	my $r = SELECT * FROM TRACK;
	diag Dumper $r;
	ok ($r);
};
