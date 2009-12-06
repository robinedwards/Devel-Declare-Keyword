package Keyword;
use strict;
use warnings;
use Switch;
use Devel::Declare;
use B::Hooks::EndOfScope;
use Data::Dumper;
use Keyword::Parser;

our $VERSION = '0.01';

our $KW_MODULE = caller;

#setup parser for keyword syntax
sub import {
	Devel::Declare->setup_for(
		$KW_MODULE,
		{ keyword => { const => \&sig_parser } }
	);
	no strict 'refs';
	*{$KW_MODULE.'::keyword'} = sub (&) { &{$KW_MODULE."::import"} = mk_import(@_); };

	strict->import;
	warnings->import;
}

#parses keyword signature
sub sig_parser {
	my $parser = new Keyword::Parser;
	$parser->next_token;
	$parser->skip_ws;

	#strip out the name of new keyword
	my $name;
	if (my $len = $parser->scan_word(1)) {
		my $l = $parser->line; 
		$name = substr($l, $parser->offset, $len);
		substr($l, $parser->offset, $len) = '';
		$parser->line($l);
	} else {
		die "expecting identifier for keyword near:\n".$parser->line;
	}

	$parser->skip_ws;

	#extract the prototype
	my $proto;
	my $l = $parser->line;
	if (substr($l, $parser->offset, 1) eq '(') {
		my $length = $parser->scan_string;
		$proto = $parser->scanned;
		substr($l, $parser->offset, $length) = '';
		$parser->line($l);
	} else {
		die "expecting prototype for keyword at:\n".$parser->line;
	}

	#produce list of executable rules from prototype
	my $rule = proto_to_rule($proto);

	#produce sub that executes these rules
	my $new_parser = rule_to_parser($rule);

	#construct shadow sub
	my $shadow = sub (&) { 
		my $block = shift;

		no strict 'refs';
		#install new keyword module import routine
		*{$KW_MODULE."::import"} = mk_import($name, $new_parser);

		#install new keyword sub
		*{$KW_MODULE."::$name"} = sub { &$block(); }; 
	};

	#install shadow for keyword routine
	Devel::Declare::shadow_sub($parser->package."::keyword", $shadow);
}

#converts prototype to a list of rules to be invoked by the parserparser
sub proto_to_rule {
	my $proto = shift;
	$proto =~ s/\s+//g;

	my @rules;

	for my $rule (split /\,/, $proto){
		$rule =~ /^[a-z]{1}\w+[\?]?$/i or  die "bad identifier '$rule' for rule in prototype.";
		
		#flag as optional should it be postfixed with a '?'
		my $opt;
		$rule =~ s/\?//g and $opt = 1 if $rule =~ /\?$/;

		#append to list of rules matching builtin rules
		no strict 'refs';
		switch($rule) {
			case 'identifier' { 
				push @rules, 
					{name=>$rule, rule=>\&{'Keyword::Rule::Identifier::parse'},opt=>$opt, builtin=>1}
				}	
			case 'prototype' { 
				push @rules, 
					{name=>$rule, rule=>\&{'Keyword::Rule::Prototype::parse'},opt=>$opt, builtin=>1}
				}
				#TODO check this code exists
			else { push @rules, {name=>$rule, rule=>\&{$KW_MODULE."::$rule"},opt=>$opt}; }; 
		}
	}

	return \@rules
}

sub rule_to_parser {
	my $rule = shift;
	return sub {
		my $parser = new Keyword::Parser;
		$parser->next_token; # skip keyword
		$parser->skip_ws;

		my $result;

		for my $r (@$rule) {
			my $match = &{$r->{rule}}($parser);
			$parser->skip_ws;
			die "failed to match rule $r->{name}" unless $match or $r->{opt};
		}

	};
}

# build import routine for new keyword module
sub mk_import {
	my ($keyword, $parser) = @_;

	return sub {
		# module_user is the user of your Keyword based module
		my $module_user = caller();
		Devel::Declare->setup_for(
			$module_user,
			{ $keyword => { const => $parser } }
		);

		#setup prototype for there keyword into modules namespace
		no strict 'refs';
		*{$module_user."::$keyword"} = sub (&) {};

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

# Constructs a parser for the new keyword
=cut
sub mk_parser {
	my ($name, $rule) = @_;


		#skip keyword

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
=cut
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
