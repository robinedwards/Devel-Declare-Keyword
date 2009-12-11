package Methods;
use lib 'lib/';
use Keyword;
use Data::Dumper;

keyword method (ident?, proto?, block) {
	$block->name($ident);
	$block->code($proto);
	$block->terminate;
}

sub action_ident { shift; } # return method name

sub action_proto {
	my $proto = shift;
	$proto =~ s/\s//g;
	$proto = "\$self,$proto" if length($proto);
	return " my ($proto) = \@_; ";
}

1;
