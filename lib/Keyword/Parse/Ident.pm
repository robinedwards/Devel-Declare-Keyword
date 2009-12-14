package Keyword::Parse::Ident;

sub parse_ident {
	my $parser = shift;
	if (my $len = $parser->scan_word(1)) {
		my $l = $parser->line;
		my $ident = substr($l, $parser->offset, $len);
		substr($l, $parser->offset, $len) = '';
		$parser->line($l);
		return $ident if $ident =~ /^[a-z]{1}\w+$/i;
	}
}

1;
