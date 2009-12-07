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
	*{$KW_MODULE.'::keyword'} = sub (&) {};

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
	my $new_parser = rule_to_parser($rule,$name);

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

#converts prototype to a list of rules and actions to be invoked by the parser
sub proto_to_rule {
	my $proto = shift;
	$proto =~ s/\s+//g;

	my @rules;

	for my $rule (split /\,/, $proto){
		$rule =~ /^[a-z]{1}\w+[\?]?$/i or  die "bad identifier '$rule' for rule in prototype.";
		
		#flag as optional should it be postfixed with a '?'
		my $opt;
		$rule =~ s/\?//g and $opt = 1 if $rule =~ /\?$/;

		#TODO should check for local rule, if not attempt to load one

		#append to list of rules matching builtin rules
		no strict 'refs';
		switch($rule) {
			case 'identifier' { 
				push @rules, 
					{name=>$rule, rule=>\&{'Keyword::Rules::identifier'}, 	
					action=>\&{$KW_MODULE."::action_$rule"},  
						opt=>$opt, builtin=>1}
				}	
			case 'prototype' { 
				push @rules, 
					{name=>$rule, rule=>\&{'Keyword::Rules::prototype'},
						action=>\&{$KW_MODULE."::action_$rule"},  
						opt=>$opt, builtin=>1}
				}
				#TODO check this code exists
			else { push @rules, {name=>$rule, rule=>\&{$KW_MODULE."::rule_$rule"}, 
					action=>\&{$KW_MODULE."::action_$rule"},  
					opt=>$opt}; }; 
		}
	}

	return \@rules
}

sub rule_to_parser {
	my ($rule,$keyword) = @_;
	return sub {
		my $parser = new Keyword::Parser;
		$parser->next_token; # skip keyword
		$parser->skip_ws;

		my $result;

		#call each rule
		for my $r (@$rule) {
			my $match = &{$r->{rule}}($parser); # call rule
			$parser->skip_ws;
			die "failed to match rule $r->{name}" unless $match or $r->{opt};
			my $code = &{$r->{action}}($match); # call action
		}

		my $name = $parser->package."::$keyword";

		#setup shadow sub
		my $shadow = sub (&) { 
			no strict 'refs';
			*{$name} = shift; 
		};
		Devel::Declare::shadow_sub($name, $shadow);
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

		# setup prototype for there keyword into modules namespace
		no strict 'refs';
		*{$module_user."::$keyword"} = sub (&) {};

		# remove need for semi colon
		*{$KW_MODULE."::inject_scope"} = sub {
				on_scope_end {
					my $l = $parser->line;
					my $loffset = $parser->line_offset;
					substr($l, $loffset, 0) = ';';
					$parser->line($l);
			};
		}
	};
}

#inject into block
sub inject_if_block {
	my ($parser, $code) = @_;
	$parser->skip_ws;
	my $l = $parser->line;
	if (substr($l, $parser->offset, 1) eq '{') {
		substr($l, $parser->offset+1, 0) = $code;
		$parser->line($l);
	}
	else {
		die "expecting a block";
	}
}

1;
