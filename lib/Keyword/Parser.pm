package Keyword::Parser;
use strict;
use warnings;
use Carp;
use Keyword::Declare;

our %BUILTIN = (
	proto => 'Keyword::Parse::Proto::parse_proto',
	ident => 'Keyword::Parse::Ident::parse_ident',
	block => 'Keyword::Parse::Block::new',
);

sub new {
	my ($class, $self) = @_;
	$self->{proto} or croak 'no proto provided';
	$self->{module} or croak 'no module provided';
	bless($self,$class);	
}

sub build {
	my $self = shift;
	$self->_build_ident_list;
	$self->_lookup_routines;
	$self->declare(Keyword::Declare->new);
	
	return sub {
		my @arg;
		$self->declare->next_token;
		$self->declare->skip_ws;

		#call each parse routine and action
		for my $pa (@{$self->{plist}}) {
			push @arg, $self->exec($pa);	
		}

		&{$Keyword::__keyword_block}(@arg);
	};
}

sub declare {
	my ($self, $d) = @_;
	$self->{declare} = $d if $d;
	return $self->{declare};
}

#executes a parse routine and its action
sub exec {
	my ($self, $pa) = @_;
	my $match = &{$pa->{parse}}($self->declare); 
	$self->declare->skip_ws;
	croak "failed to parse $pa->{name}" unless $match or $pa->{opt};
	return &{$pa->{action}}($match);
}

sub _build_ident_list {
	my $self = shift;
	$self->{proto} =~ s/\s//g;
	my @i = split /\,/, $self->{proto};
	for my $ident (@i){
		$ident =~ /^[a-z]{1}\w+[\?]?$/i or 
		croak "bad identifier '$ident' in prototype.";
		my $opt;
		$ident =~ s/\?//g and $opt = 1 if $ident =~ /\?$/;
		push @{$self->{plist}}, {name=>lc($ident),optional=>$opt};
	}
}

sub _lookup_routines {
	my $self = shift;
	for my $p (@{$self->{plist}}) {
		$p->{parse} = $self->_find_parse_sub($p->{name});
		$p->{action} = $self->_find_action_sub($p->{name});
	}
}

sub _find_parse_sub {
	my ($self, $ident) = @_;
	no strict 'refs';
	if (exists $BUILTIN{$ident}) {
		return \&{$BUILTIN{$ident}};
	}
	else {
		#	"$self->{module}"->can("parse_$ident");
		return \&{$self->{module}."::parse_$ident"};
	}
}

sub _find_action_sub {
	my ($self, $ident) = @_;
	no strict 'refs';
	if($ident eq 'block') {
		return sub {@_};
	}
	else {
		return \&{$self->{module}."::action_$ident"};
	}
}
