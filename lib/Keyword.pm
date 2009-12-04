package Keyword;
use strict;
use warnings;
use Devel::Declare;
use B::Hooks::EndOfScope;
use Data::Dumper;

our $VERSION = '0.01';

our $KW_MODULE = caller;

our $OFFSET;
our $DECLARATOR;

=head1 Stuff for parsing keyword syntax
=cut

sub import {
	my $class = shift;
	
	Devel::Declare->setup_for(
		$KW_MODULE,
		{ keyword => { const => \&keyword_parser } }
	);
	no strict 'refs';
	*{$KW_MODULE.'::keyword'} = sub (&) { &{$KW_MODULE."::import"} = mk_import(@_); };

	strict->import;
	warnings->import;
}

sub keyword_parser {
	local ($DECLARATOR, $OFFSET) = @_;

	#skip keyword
	$OFFSET += Devel::Declare::toke_move_past_token($OFFSET);

	#skip ws
	$OFFSET += Devel::Declare::toke_skipspace($OFFSET);


	#strip out the name of new keyword
	my $name;

	if (my $len = Devel::Declare::toke_scan_word($OFFSET, 1)) {
		my $linestr = Devel::Declare::get_linestr();
		$name = substr($linestr, $OFFSET, $len);
		substr($linestr, $OFFSET, $len) = '';
		Devel::Declare::set_linestr($linestr);
	} else {
		my $line = Devel::Declare::get_linestr;
		die "expecting identifier for keyword near:\n\t$line";
	}

	#skip ws
	$OFFSET += Devel::Declare::toke_skipspace($OFFSET);

	#extract the prototype
	my $proto;
	my $linestr = Devel::Declare::get_linestr();
	if (substr($linestr, $OFFSET, 1) eq '(') {
		my $length = Devel::Declare::toke_scan_str($OFFSET);
		$proto = Devel::Declare::get_lex_stuff();
		Devel::Declare::clear_lex_stuff();
		$linestr = Devel::Declare::get_linestr();
		substr($linestr, $OFFSET, $length) = '';
		Devel::Declare::set_linestr($linestr);
	} else {
		die "expecting prototype for keyword at:\n\t$linestr";
	}

	#produce rules from prototype
	my $rule = proto_to_rule($proto);

	my $fullname = $name =~ /::/ ? $name : 
		join('::', Devel::Declare::get_curstash_name(), $name); 

	shadow_keyword(sub (&) { 
			my $block = shift; 
			
			no strict 'refs'; 
			#install import routine
			*{$KW_MODULE."::import"} = mk_import($name, $rule);
			
			*{$fullname} = sub { 
				#call main block
				&$block();
				}; 
			});
}

sub shadow_keyword {
	my $pack = Devel::Declare::get_curstash_name;
	Devel::Declare::shadow_sub("${pack}::${DECLARATOR}", $_[0]);
}

#converts prototype to a list of rules to be called by parser
sub proto_to_rule {
	my $proto = shift;
	$proto =~ s/\s+//g;
	my @rule;

	for my $ident (split /\,/, $proto){
		die "parsing prototype failed, bad identifier '$ident'"  unless $ident =~ /^[a-z]{1}\w+[\?]?$/i;

		#TODO check if code is defined
		# then
		# check if it matches built-in rule
		# then provide ref to right bit of code.

		if ($ident =~ /\?$/) { # optional match
			$ident =~ s/\?//g;
			push @rule, { code=>"$KW_MODULE\::$ident", optional=>1};
		}
		else { # essential match
			push @rule, { code=>"$KW_MODULE\::$ident"};
		}
	}

	return \@rule;
}

=head1 Internals used by new keywords
=cut

=head2 mk_import
Constructs an import for subroutine for the new keyword
=cut

sub mk_import {
	my ($keyword, $rule) = @_;
	return sub {
		#modcaller is the user of *your* Keyword based module
		my $modcaller = caller();
		my $class = shift;
		Devel::Declare->setup_for(
			$modcaller,
			{ $keyword => { const => mk_parser($keyword, $rule) } }
		);
		*{$modcaller."::$keyword"} = sub (&) {};

		# create scope inject sub
		#	*{$KW_MODULE."::inject_scope"} = sub {
		#		on_scope_end {
		#			my $linestr = get_line;
		#			my $loffset = get_line_offset;
		#			substr($linestr, $loffset, 0) = ';';
		#			set_line($linestr);
		#	};
		#}
	};
}

=head2 mk_parser
Constructs a parser for the new keyword
=cut

sub mk_parser {
	my ($name, $rule) = @_;

	return sub {
		(${$KW_MODULE."::DECL"}, ${$KW_MODULE."::OFFSET"}) = @_;

		#skip keyword
		my $OFFSET = Devel::Declare::toke_move_past_token($OFFSET);

		my @matched;

		#execute each rule
#		for my $r (@$rule) {
			#push @matched, \*{"$r->{code}"}();
#		}

		my $code = " BEGIN { $KW_MODULE\::inject_scope() }; ";

		#inject block
		inject_block($code); 

		if (defined $name) {
			$name = join('::', Devel::Declare::get_curstash_name() , $name)
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
	Devel::Declare::shadow_sub(Devel::Declare::get_curstash_name()."::".${$KW_MODULE."::DECL"}, $sub);
}

#inject into block
sub inject_block {
	my $inject = shift;
	${$KW_MODULE."::OFFSET"} += Devel::Declare::toke_skipspace(${$KW_MODULE."::OFFSET"});
	my $linestr = Devel::Declare::get_linestr;
	if (substr($linestr, ${$KW_MODULE."::OFFSET"}, 1) eq '{') {
		substr($linestr, ${$KW_MODULE."::OFFSET"}+1, 0) = $inject;
		Devel::Declare::set_linestr($linestr);
	}
}

1;
