package Keyword::Declare;
use strict;
use warnings;
use Carp;
use Devel::Declare;
use Data::Dumper;

#TODO organise high level and low level methods
#TODO possible import strip_names_and_args

=head1 NAME

Keyword::Declare - simple oo interface to Devel::Declare

=cut

=head1 SYNOPSIS

 my $kd = new Keyword::Declare;
 print $kd->line;

=cut


sub new {
	my ($class) = @_;
	my $self->{offset} = $_[2] || 0;
	$self->{declarator} = $_[1];
	bless($self,$class);	
}

=head1 METHODS

=head2 offset

for setting and retrieving the offset

=cut

sub offset {
	my ($self, $offset) = @_;
	$self->{offset} = $offset if $offset;
	return $self->{offset};
}

sub declarator {
	my $self = shift;
	return $self->{declarator}
}

=head2 inc_offset

increments the current offset

 $kd->inc_offset; # by one
 $kd->inc_offset(23);

=cut

sub inc_offset {
	my ($self, $offset) = @_;
	if($offset) {
		$self->{offset} += $offset;
	}
	else {
		$self->{offset}++;
	}
	return $self->{offset};
}

=head2 next_token

skips to the next token

=cut

sub next_token {
	my ($self) = @_;
	$self->{offset} += Devel::Declare::toke_move_past_token($self->offset);
}

=head2 skip_token

skips a token matching 

=cut

sub skip_token {
	my ($self, $token) = @_;;
	my $len = $self->scan_word(0);
	confess "Couldn't find token '$token'" unless $len;

	my $l = $self->line;
	my $match = substr($l, $self->offset, $len);
	confess "Expected declarator '$token', got '${match}'"
	unless $match eq $token;
	$self->inc_offset($len);
	return $match;
}


=head2 strip_token

strips a token 

=cut

sub strip_token {
	my ($self) = @_;;
	my $len = $self->scan_word(0);
	confess "Couldn't find a token." unless $len;
	my $l = $self->line;
	my $match = substr($l, $self->offset, $len) = '';
	$self->inc_offset($len);
	return $match;
}

=head2 strip_ident

strips an identifier

=cut

sub strip_ident {
	my $self = shift;
	if (my $len = Devel::Declare::toke_scan_ident( $self->offset )) {
		my $l = $self->line;
		my $ident = substr($l, $self->offset, $len);
		substr($l, $self->offset, $len) = '';
		$self->line($l);
		return $ident;
	}
}

=head2 strip_to_char

#strip out everything until a certain char is matched

=cut

sub strip_to_char {
	my ($self, $char) = @_;
	my $str = "";
	while ($str !~ /$char/) {
		my $l = $self->line;
		$str .= substr($l, $self->offset, 1);
		substr($l, $self->offset, 1) = '';
		$self->line($l);
	}
	return $str;
}

=head2 terminate

inject a semi colon

=cut

sub terminate {
	my ($self) = shift;
	my $l = $self->line;
	substr($l, $self->offset, 1) = ';';
	$self->line($l);
}

=head2 skip_ws

skip past white space

=cut

sub skip_ws {
	my ($self) = @_;
	$self->{offset} += 	Devel::Declare::toke_skipspace($self->offset);
}

=head2 scan_word

scan in a word, see also scanned

=cut

sub scan_word {
	my ($self, $n) = @_;
	return Devel::Declare::toke_scan_word($self->offset, $n);
}

=head2 scan_ident

scan in a ident, see also scanned

=cut

sub scan_ident {
	my ($self, $n) = @_;
	return Devel::Declare::toke_scan_ident($self->offset, $n);
}

=head2 scan_string

scan a quoted string, see also scanned

=cut

sub scan_string {
	my ($self) = @_;
	return Devel::Declare::toke_scan_str($self->offset);
}

=head2 scanned

returns whatever the parser has scanned

=cut

sub scanned {
	my ($self) = @_;
	my $stream = Devel::Declare::get_lex_stuff();
	Devel::Declare::clear_lex_stuff();
	return $stream;
}


=head2 line

get or set the current line

=cut

sub line {
	my ($self, $line) = @_;
	Devel::Declare::set_linestr($line) if $line;
	return Devel::Declare::get_linestr;
}

=head2 package

returns name of package being compiled 

=cut

sub package {
	return Devel::Declare::get_curstash_name;
}

=head2 line_offset

get or set the current lines offset

=cut

sub line_offset {
	my ($self, $os) = @_;
	Devel::Declare::set_linestr_offset($os) if $os;
	return Devel::Declare::get_linestr_offset;
}

=head2 shadow

sets up a shadow subroutine, optionally takes a sub ref as the shadow

 $declare->shadow('Some::Thing::do_something', \&somecoderef)

=cut

sub shadow {
	my ($self, $name, $sub) = @_;

	#set name as global for import;
	no strict 'refs'; 

	${$self->package."::__block_name"} = $name;

	unless ($sub) {
		if($name) {
			$sub = sub (&) {
				*{$name} = shift;
			};
		}
		else {
			$sub = sub (&) { shift; };
		}
	}

	Devel::Declare::shadow_sub($name, $sub);
}

=head1 CODE

http://github.com/robinedwards/Keyword

git@github.com:robinedwards/Keyword.git

=head1 AUTHOR

Robin Edwards  <robin.ge@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Robin Edwards

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

1;
