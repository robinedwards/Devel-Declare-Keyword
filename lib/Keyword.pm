package Keyword;
use 5.010000;
use strict;
use warnings;
no strict 'refs';
use Devel::Declare;
use B::Hooks::EndOfScope;
use Exporter 'import';
use Data::Dumper;

our $VERSION = '0.01';
our @EXPORT = qw/keyword next_token skip_space
		scan_word scan_string set_line get_line get_lex get_line_offset get_package/;

our $MODULE = caller();


=head1 api?

keyword $yourkeyword => ( 
				name => ( parse => sub {}, action => sub {}),
				proto => ( parse => sub {}, action => sub {}),
				block => ( parse => sub {}, action => sub {}, end_of_scope => sub {}),
				);

=cut

=head1 EXPORTED Utility Functions
=cut

#next token
sub next_token () {
	${$MODULE."::OFFSET"} += Devel::Declare::toke_move_past_token(${$MODULE."::OFFSET"});
}

#skip space
sub skip_space () {
	${$MODULE."::OFFSET"} += Devel::Declare::toke_skipspace(${$MODULE."::OFFSET"});
}

#scan word
sub scan_word ($) {
	return Devel::Declare::toke_scan_word(${$MODULE."::OFFSET"}, shift);
}

#scan string eg "blah blsah " or q( some string )
sub scan_string () {
	return Devel::Declare::toke_scan_str(${$MODULE."::OFFSET"});
}

#get lex
sub get_lex () {
	my $stream = Devel::Declare::get_lex_stuff();
	Devel::Declare::clear_lex_stuff();
	return $stream;
}

#get line
sub get_line () {
	return Devel::Declare::get_linestr;
}

#set line
sub set_line ($){
	Devel::Declare::set_linestr(shift());
}

# get package - returns name of package being compiled 
sub get_package (){
	return Devel::Declare::get_curstash_name;
}

sub get_line_offset (){
	return Devel::Declare::get_linestr_offset;
}

=head1 declarator
=cut

sub keyword (%) {
	my ($keyword,$param) = @_;
	*{$MODULE."::import"} = mk_import($keyword, $param);
};

#construct import sub;
sub mk_import {
	my ($keyword, $param) = @_;
	return sub {
		#modcaller is the user of *your* Keyword based module
		my $modcaller = caller();
		my $class = shift;
		Devel::Declare->setup_for(
			$modcaller,
			{ $keyword => { const => mk_parser($keyword,$param) } }
		);
		*{$modcaller."::$keyword"} = sub (&) {};
	};
}

#construct parser subroutine
sub mk_parser {
	my ($keyword, $param) = @_;

	return sub {
		(${$MODULE."::DECL"}, ${$MODULE."::OFFSET"}) = @_;

		#skip keyword
		next_token;
		
		#match name	
		skip_space;
		my $name = &{$param->{name}{parse}}();

		#match proto
		skip_space;
		my $proto = &{$param->{proto}{parse}}();
		my $code = &{$param->{proto}{action}}($proto);

		#add eos hook and create sub;
		if(exists $param->{proto}{eos}) {
			$code = " BEGIN { $MODULE\::_$keyword\_inject_scope() };\n".$code;
			no warnings;
			*{$MODULE."::_$keyword\_inject_scope"} = sub {
				on_scope_end {
					&{$param->{proto}{eos}}();
				};
			};
			use warnings;
		}

		#inject block
		inject_block($code); 

		if (defined $name) {
			$name = join('::', get_package, $name)
			unless ($name =~ /::/);
			shadow(sub (&) { no strict 'refs'; *{$name} = shift; });
		} else {
			shadow(sub (&) { shift });
		}
	};
}

#shadow
sub shadow {
	my $sub = shift;
	Devel::Declare::shadow_sub(get_package."::".${$MODULE."::DECL"}, $sub);
}

#inject into block
sub inject_block {
	my $inject = shift;
	skip_space;
	my $linestr = get_line;
	if (substr($linestr, ${$MODULE."::OFFSET"}, 1) eq '{') {
		substr($linestr, ${$MODULE."::OFFSET"}+1, 0) = $inject;
		set_line($linestr);
	}
}

1;
