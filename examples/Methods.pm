package Methods;
use lib 'lib/';
use Keyword;
use Data::Dumper;

keyword method (ident?, proto?, block) {
	$block->name($ident);
	$block->inject_begin($proto);
	$block->inject_after("warn 'HELLO!';");
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
