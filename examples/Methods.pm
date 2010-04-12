package Methods;
use lib 'lib/';
use Devel::Declare::Keyword qw/debug/;
use Data::Dumper;

keyword method (Maybe[ident] $ident, Maybe[proto] $proto, block $block) {
	$block->name($ident);
	$block->inject_begin($proto);
	$block->inject_after("warn 'post block inject ok';");
	$block->terminate;
}


action proto ($proto) {
	$proto =~ s/\s//g;
	$proto = "\$self,$proto" if length($proto);
	return " my ($proto) = \@_; ";
}

# return method name
action ident ($ident) { 
	return $ident; 
}


1;
