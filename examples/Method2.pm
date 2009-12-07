package Method2;
use lib 'lib/';
use Keyword;
use Data::Dumper;

keyword method (ident?, proto?) {
	warn "hello";
};

sub rule_ident {
	my $parser = shift;
	if (my $len = $parser->scan_word(1)) {
		my $l = $parser->line;
		my $ident = substr($l, $parser->offset, $len);
		substr($l, $parser->offset, $len) = '';
		$parser->line($l);
		return $ident;
	}
}

sub action_ident {
	my $match = shift;
}

sub rule_proto {
	my $parser = shift;
	my $l = $parser->line;
	if (substr($l, $parser->offset, 1) eq '(') {
		my $length = $parser->scan_string;
		my $proto = $parser->scanned;
		$l = $parser->line;
		substr($l, $parser->offset, $length) = '';
		$parser->line($l);
		return $proto;
	}
}

sub action_proto {
	my $match = shift;
}

1;
