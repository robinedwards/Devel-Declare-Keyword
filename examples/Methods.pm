package Methods;
use lib 'lib/';
use Keyword;
use Data::Dumper;

keyword method (ident?, proto?, block) {
	$block->name($ident);
	$block->code("warn 'hello from Methods';");
	$block->terminate;
}

sub action_ident {
	return @_;
}

sub action_proto {
	return @_;
}

1;
