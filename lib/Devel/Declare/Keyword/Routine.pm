package Devel::Declare::Keyword::Routine;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw/Proto Ident/;

sub Proto {
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

sub Ident {
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
