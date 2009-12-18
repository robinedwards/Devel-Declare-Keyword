package Keyword::Declare;
use strict;
use warnings;
use Carp;
use Devel::Declare;

# maybe subclass Devel::Declare::Context::Simple?

sub new {
	my ($class, $self) = @_;
	$self = {} unless $self;
	no strict 'refs';
	$self->{offset} = \${caller()."::_PARSER_OFFSET"};
	${$self->{offset}} = 0;
	bless($self,__PACKAGE__);	
}

sub offset {
	my ($self, $offset) = @_;
	${$self->{offset}} = $offset if $offset;
	return ${$self->{offset}};
}

sub inc_offset {
	my ($self, $offset) = @_;
	if($offset) {
		${$self->{offset}} += $offset;
	}
	else {
		${$self->{offset}}++;
	}
	return ${$self->{offset}};
}
sub next_token {
	my ($self) = @_;
	${$self->{offset}} += Devel::Declare::toke_move_past_token($self->offset);
}

sub skip_to {
	my ($self, $name) = @_;
	my $toke = "";
	while ($toke ne $name) {
		my $len = $self->scan_word(1);
		my $l = $self->line;
		$toke = substr($l, $self->offset, $len);
		$self->offset($len + $self->offset);
		$self->inc_offset;
		confess "couldn't find '$name' on this line" if $toke and $toke =~ /\n/;
	}
	return $toke;
}

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

sub terminate {
	my ($self) = shift;
	my $l = $self->line;
	substr($l, $self->offset, 1) = ';';
	$self->line($l);
}

sub skip_ws {
	my ($self) = @_;
	${$self->{offset}} += 	Devel::Declare::toke_skipspace($self->offset);
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
	my ($self, $os) = @_;
	 Devel::Declare::set_linestr_offset($os) if $os;
	return Devel::Declare::get_linestr_offset;
}

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

1;
