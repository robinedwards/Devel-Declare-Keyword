package Keyword::Parse::Block;
use strict;
use warnings;

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

#add end of scope hook
#inject code
sub begin {
	my ($self, $code) = @_;

	my $l = $self->{parser}->line;
	substr($l, $self->{parser}->offset+1, 0) = $code;
	$self->{parser}->skip_ws;
	$self->{parser}->line($l);
}

sub name {
	my ($self, $name) = @_;
	no strict 'refs';
	$self->{parser}->shadow($name);
}

sub terminate {
	my $self = shift
		# remove need for semi colon
		#*{$module_user."::inject_scope"} = sub {
		#		on_scope_end {
		#			my $l = $parser->line;
		#			my $loffset = $parser->line_offset;
		#			substr($l, $loffset, 0) = ';';
		#			$parser->line($l);
		#	};
		#}
}

1;
