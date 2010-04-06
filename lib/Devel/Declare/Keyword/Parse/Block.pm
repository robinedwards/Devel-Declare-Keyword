package Keyword::Parse::Block;
use strict;
use warnings;
use B::Hooks::EndOfScope;
use Data::Dumper;

# doesnt actualy 'parse' a block, just detects the start.

sub new {
	my ($parser) = @_;
	my $self = bless({parser=>$parser}, __PACKAGE__);
	return $self if $self->match;
}

sub match {
	my ($self) = @_;
	my $l = $self->{parser}->line;
	if (substr($l, $self->{parser}->offset, 1) eq '{') {
		return 1;
	}
}

sub inject_before {
	my ($self,$code) = @_;
}

sub code { inject_begin(@_); };

# inject code into start of block
sub inject_begin {
	my ($self, $code) = @_;

	$code =~ s/\n/\ /g;

	$self->{eos} =$self->{parser}->package."::_".
		$self->{name}."_inject_scope";

	#add end of scope hook
	$code = " BEGIN { $self->{eos}()}; $code";

	no strict 'refs';
	*{$self->{eos}} = sub {};

	my $l = $self->{parser}->line;
	substr($l, $self->{parser}->offset+1, 0) = $code;
	$self->{parser}->skip_ws;
	#added end of scope hook
	$self->{parser}->line($l);
}

# injects code after the end of the block
sub inject_after {
	my ($self, $code) = @_;
	$code =~ s/\n/\ /g;
	$self->{inject_after} = $code;

}

sub name {
	my ($self, $name) = @_;
	no strict 'refs';
	$name = $self->{parser}->package."::$name" if $name;
	$self->{name} = $name;
	return $self->{parser}->shadow($name);
}

sub execute {
	my ($self) = @_;
}

# set end of scope code
# !! B:H:EOS won't allow you to inject code into the block
sub terminate {
	my ($self) = @_;
	no strict 'refs';
	no warnings 'redefine';
	*{$self->{eos}} = sub {
		on_scope_end {
			my $l = $self->{parser}->line;
			my $loffset = $self->{parser}->line_offset;
			substr($l, $loffset, 0) = '; '.
			($self->{inject_after}?$self->{inject_after}:"");
			$self->{parser}->line($l);
		};
	};
}

1;
