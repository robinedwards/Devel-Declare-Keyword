package Devel::Declare::Keyword::Parser;
use strict;
use warnings;
use Carp;
use Devel::Declare::Keyword::Context;
use Data::Dumper;

our %BUILTIN = (
	proto => 'Devel::Declare::Keyword::Parse::Proto::parse_proto',
	ident => 'Devel::Declare::Keyword::Parse::Ident::parse_ident',
	block => 'Devel::Declare::Keyword::Parse::Block::new',
);

sub new {
	my ($class, $self) = @_;
	$self->{proto} or confess 'no proto provided';
	$self->{module} or confess 'no module provided';
	$self->{keyword} or confess 'no keyword provided';
	bless($self,$class);	
	$self->_parse_proto;
	return $self;
}

sub build {
	my $self = shift;
	$self->_lookup_routines;

	return sub {
		my $kd = Devel::Declare::Keyword::Context->new(@_);
		$kd->skip_token($kd->declarator);
		$kd->skip_ws;

		$self->declare($kd);

		my @arg;
		#call each parse routine and action
		for my $pa (@{$self->{plist}}) {
			push @arg, $self->exec($pa);	
		}

		# if it has a block execute keyword block at compile
		if($self->{block}) { 
			&{$Devel::Declare::Keyword::__keyword_block}(@arg);
		}
		else { # no block execute at runtime, save arg
			@Devel::Declare::Keyword::__keyword_block_arg = @arg;
		}
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
	confess "failed to parse $pa->{name}" unless $match or $pa->{opt};
	return &{$pa->{action}}($match);
}

sub unfold_proto_code {
	return $_[0]->{proto_code};
}

# parse prototype and return code
sub _parse_proto {
	my $self = shift;

	my @var;

	for my $item (split /,\s*/, $self->{proto}) {
		my ($rule,$ident) = split /\s+/, $item;
		my $opt;
		if ($rule =~ /^Maybe\[([a-zA-Z]{1}\w+)\]+$/) {
			$rule = $1;
			$opt = 1;
		}
		elsif($rule =~ /^([a-zA-Z]{1}\w+)$/) {
			$rule = $1;
		}
		else {
			confess "Error parsing keyword prototype near: '$item'";
		}

		confess "Bad identifier for scalar near: $item"
			unless $ident =~ /^\$[a-zA-Z]{1}\w+$/;

		push @var, $ident;
		push @{$self->{plist}}, {name=>$rule,optional=>$opt};
	}

	warn Dumper $self->{plist};

	$self->{proto_code} = 
		'BEGIN { Devel::Declare::Keyword::eos()};'
		. " my (".join(', ', @var).') = @_;';
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
