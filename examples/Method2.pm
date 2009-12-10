package Method2;
use lib 'lib/';
use Keyword;
use Data::Dumper;

keyword method (ident?, proto?, block) {
	warn "method params: ".Dumper @_;
#	$block->begin("warn 'hello from me';");
	$block->name($ident);
};

sub action_ident {
	return @_;
}

sub action_proto {
	return @_;
}

1;
