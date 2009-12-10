package DDExample;
use strict;
use warnings;
use Devel::Declare;
use B::Hooks::EndOfScope;

# created by following the Devel::Declare example
# used as reference when hacking Keyword.pm

sub import {
	my $class = shift;
	my $caller = caller;

	Devel::Declare->setup_for(
		$caller,
		{ method => { const => \&parser } }
	);
	no strict 'refs';
	*{$caller.'::method'} = sub (&) {};
}

our ($Declarator, $Offset);

sub parser {
	local ($Declarator, $Offset) = @_;
	skip_declarator();          # step past 'method'
	my $name = strip_name();    # strip out the name 'foo', if present
	my $proto = strip_proto();  # strip out the prototype '($arg1, $arg2)', if present
	my $inject = make_proto_unwrap($proto);
	if (defined $name) {
		$inject = scope_injector_call().$inject;
	}
	inject_if_block($inject);
	if (defined $name) {
		$name = join('::', Devel::Declare::get_curstash_name(), $name)
		unless ($name =~ /::/);
		shadow(sub (&) { no strict 'refs';  *{$name} = shift; });
	} else {
		shadow(sub (&) { shift });
	}
}


sub skip_declarator {
	$Offset += Devel::Declare::toke_move_past_token($Offset);
}


sub strip_name {
	skipspace();
	if (my $len = Devel::Declare::toke_scan_word($Offset, 1)) {
		my $linestr = Devel::Declare::get_linestr();
		my $name = substr($linestr, $Offset, $len);
		substr($linestr, $Offset, $len) = '';
		Devel::Declare::set_linestr($linestr);
		return $name;
	}
	return;
}

sub skipspace {
	$Offset += Devel::Declare::toke_skipspace($Offset);
}


sub strip_proto {
	skipspace;

	my $linestr = Devel::Declare::get_linestr();
	if (substr($linestr, $Offset, 1) eq '(') {
		my $length = Devel::Declare::toke_scan_str($Offset);
		my $proto = Devel::Declare::get_lex_stuff();
		Devel::Declare::clear_lex_stuff();
		$linestr = Devel::Declare::get_linestr();
		substr($linestr, $Offset, $length) = '';
		Devel::Declare::set_linestr($linestr);
		return $proto;
	}
	return;
}

sub make_proto_unwrap {
	my ($proto) = @_;
	my $inject = 'my ($self';
	if (defined $proto) {
		$inject .= ", $proto" if length($proto);
		$inject .= ') = @_; ';
	} else {
		$inject .= ') = shift;';
	}
	return $inject;
}

sub inject_if_block {
	my $inject = shift;
	skipspace;
	my $linestr = Devel::Declare::get_linestr;
	if (substr($linestr, $Offset, 1) eq '{') {
		substr($linestr, $Offset+1, 0) = $inject;
		Devel::Declare::set_linestr($linestr);
	}
}

sub inject_scope {
	on_scope_end {#
		my $linestr = Devel::Declare::get_linestr;
		my $offset = Devel::Declare::get_linestr_offset;
		substr($linestr, $offset, 0) = ';';
		Devel::Declare::set_linestr($linestr);
	};
}


sub scope_injector_call {
	return ' BEGIN { DDExample::inject_scope() }; ';
}

sub shadow {
	my $pack = Devel::Declare::get_curstash_name;
	Devel::Declare::shadow_sub("${pack}::${Declarator}", $_[0]);
}

1;
