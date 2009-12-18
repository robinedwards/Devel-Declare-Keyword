use Test::More qw/no_plan/;
use strict;
use warnings;
use lib 'examples/';
use SQL;
use Data::Dumper;

ok 1;

SQL::CONNECT("dbi:Pg:dbname=humus;host=localhost;port=5432");

my $r = SELECT * FROM TRACK;

diag Dumper $r;
#ok ($r);

ok 1;
