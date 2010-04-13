package Devel::Declare::Keyword::Routine;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw/Proto Ident/;

sub Proto {
	my $ctx = shift;
	my $l = $ctx->line;
	if (substr($l, $ctx->offset, 1) eq '(') {
		my $length = $ctx->scan_string;
		my $proto = $ctx->scanned;
		$l = $ctx->line;
		substr($l, $ctx->offset, $length) = '';
		$ctx->line($l);
		return $proto;
	}
}

sub Ident {
	my $ctx = shift;
	if (my $len = $ctx->scan_word(1)) {
		my $l = $ctx->line;
		my $ident = substr($l, $ctx->offset, $len);
		substr($l, $ctx->offset, $len) = '';
		$ctx->line($l);
		return $ident if $ident =~ /^[a-z]{1}\w+$/i;
	}
}

1;
