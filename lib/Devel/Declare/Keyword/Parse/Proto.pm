package Devel::Declare::Keyword::Parse::Proto;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw/parse_proto/;

sub parse_proto {
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

1;
