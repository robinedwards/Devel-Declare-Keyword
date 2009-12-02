package Foobar;
use strict;
use warnings;
use lib 'examples/';
use DevelDeclareExample;

sub new {
	my ($class,) = @_;
	my $self = {};
	bless($self, $class); 
	return $self;
}

method amethod ($a, $b) {
	return ($a + $b);
}


1;

use Test::More qw/no_plan/;

my $t = new Foobar;

ok(defined $t);
$t->amethod(1,2);
