package Methods;
use lib 'lib/';
use Keyword;
use Data::Dumper;

keyword method (ident?, proto?, block) {
	$block->begin("warn 'hello from Methods';");
	$block->name($ident);
};

sub action_ident {
	return @_;
}

sub action_proto {
	return @_;
}

1;
