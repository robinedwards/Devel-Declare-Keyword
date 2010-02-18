package SQL;
use lib 'lib/';
use Keyword qw/debug/;
use Carp;
use Data::Dumper;

our $DBH;

keyword if (if) {
}

parse if ($kd) {
	my $stmt = $kd->strip_to_char('{');
#	$kd->terminate;

	my ($exp)  =~ /if\s+(.+)\s*{/;

	$kd->line("if ($exp) {");

	return $exp;
}

action sql ($exp) { 
	return $exp;
}


1;
