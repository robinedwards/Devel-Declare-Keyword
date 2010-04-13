package SQL;
use lib 'lib/';
use Devel::Declare::Keyword;
use DBI;
use Carp;
use Data::Dumper;

our $DBH;

keyword SELECT (sql $sql) {
	confess "no database connection set" unless $DBH;
	return $DBH->selectrow_hashref($sql);
}

parse sql($kd) {
	my $sql = $kd->strip_to_char(';');
	$kd->terminate;
	return $sql;
}

action sql ($sql) { 
	return "SELECT $sql"; 
}

sub CONNECT {
	$DBH = DBI->connect(@_);
};

1;
