package Keyword::Parser;
use strict;
use warnings;
use Devel::Declare;

sub new {
	my ($class, $self) = @_;
	$self = {} unless $self;
	no strict 'refs';
	$self->{offset} = \${caller()."::_PARSER_OFFSET"};
	${$self->{offset}} ||= 0;
	bless($self,__PACKAGE__);	
}

sub offset {
	my ($self, $offset) = @_;
	${$self->{offset}} = $offset if $offset;
	return ${$self->{offset}};
}

sub next_token {
	my ($self) = @_;
	${$self->{offset}} += Devel::Declare::toke_move_past_token($self->offset);
}

sub skip_ws {
	my ($self) = @_;
	${$self->{offset}} += Devel::Declare::toke_skipspace($self->offset);
}

sub scan_word {
	my ($self, $n) = @_;
	return Devel::Declare::toke_scan_word($self->offset, $n);
}

#scan string eg "blah blsah " or q( some string )
sub scan_string {
	my ($self) = @_;
	return Devel::Declare::toke_scan_str($self->offset);
}

#returns whatevers been scanned
sub scanned {
	my ($self) = @_;
	my $stream = Devel::Declare::get_lex_stuff();
	Devel::Declare::clear_lex_stuff();
	return $stream;
}

#set line
sub line {
	my ($self, $line) = @_;
	Devel::Declare::set_linestr($line) if $line;
	return Devel::Declare::get_linestr;
}

# package - returns name of package being compiled 
sub package {
	return Devel::Declare::get_curstash_name;
}

sub line_offset {
	return Devel::Declare::get_linestr_offset;
}

1;
