package Methods;
use lib 'lib/';
use Devel::Declare::Keyword;
use Data::Dumper;

keyword method (Maybe[Ident] $ident, Maybe[Proto] $proto, Block $block) {
	$block->name($ident);
	$block->inject_begin($proto);
	$block->inject_after("\$CALLS++;");
	$block->terminate;
}


action Proto ($proto) {
	$proto =~ s/\s//g;
	$proto = "\$self,$proto" if length($proto);
	return " my ($proto) = \@_; ";
}

# return method name
action Ident ($ident) { 
	return $ident; 
}


1;
