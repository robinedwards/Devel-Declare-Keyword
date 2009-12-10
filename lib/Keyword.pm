package Keyword;
use strict;
use warnings;
use Switch;
use Devel::Declare;
use B::Hooks::EndOfScope;
use Data::Dumper;
use Keyword::Parser;
use Keyword::Parse::Ident;
use Keyword::Parse::Proto;
use Keyword::Parse::Block;

our $VERSION = '0.01';
our $KW_MODULE = caller;

#setup parser for keyword syntax
sub import {
	Devel::Declare->setup_for(
		$KW_MODULE,
		{ keyword => { const => \&sig_parser } }
	);
	no strict 'refs';
	*{$KW_MODULE.'::keyword'} = sub (&) { 
		no strict 'refs';
		$Keyword::__keyword_block = shift; 
	};

	strict->import;
	warnings->import;
}

#parses keyword signature
sub sig_parser {
	my $parser = Keyword::Parser->new;
	$parser->next_token;
	$parser->skip_ws;

	#strip out the name of new keyword
	my $keyword = Keyword::Parse::Ident::match($parser) or
	die "expecting identifier for keyword near:\n".$parser->line;

	$parser->skip_ws;

	#extract the prototype
	my $proto = Keyword::Parse::Proto::match($parser)	or
	die "expecting prototype for keyword at:\n".$parser->line;

	#produce list of parse routines and there actions from prototype
	my $plist = proto_to_parselist($proto);

	#produce sub that executes these routines
	my $psub = mk_parser($plist,$keyword);

	no strict 'refs';
	*{$KW_MODULE."::import"} = mk_import($psub, $keyword);

	$parser->skip_ws;
	my $l = $parser->line;
	substr($l, $parser->offset+1, 0) = proto_to_code($proto);
	$parser->line($l);

	#construct shadow sub
	my $shadow = sub (&) { no strict 'refs';  *{$KW_MODULE."::$keyword"} = shift }; 

	#install shadow for keyword routine
	$parser->shadow($keyword, $shadow);
}

sub proto_to_code {
	my ($proto) = @_;
	my $inject = " my (";

	$proto =~ s/\?//g;
	$proto =~ s/\s//g;
	$proto =~ s/\,/\,\$/g;
	$proto = "\$".$proto if length $proto;
	$inject .= $proto.') = @_; ';

	return $inject;
}


#converts prototype to a list of parse and action subs
sub proto_to_parselist {
	my $proto = shift;
	$proto =~ s/\s+//g; #
	
	my @pa;

	for my $ident (split /\,/, $proto){
		$ident =~ /^[a-z]{1}\w+[\?]?$/i or  
			die "bad identifier '$ident' in prototype.";
		
		#foptional if ident postfixed with a '?'
		my $opt;
		$ident =~ s/\?//g and $opt = 1 if $ident =~ /\?$/;


		# I should NOT be prefix subs with action_ / rule_
		switch($ident) {
			no strict 'refs';

			#builtin
			case 'ident' { 
				push @pa, 
					{name=>$ident, parse=>\&{'Keyword::Parse::Ident::match'}, 	
					action=>\&{$KW_MODULE."::action_ident"},  
						opt=>$opt, builtin=>1}
				}	

			case 'proto' { 
				push @pa, 
					{name=>$ident, parse=>\&{'Keyword::Parse::Proto::match'},
						action=>\&{$KW_MODULE."::action_proto"},  
						opt=>$opt, builtin=>1}
				}

			case 'block' { 
				push @pa, 
					{name=>$ident, parse=>\&{'Keyword::Parse::Block::new'},
						action=>sub{return @_},  #returns block object
						opt=>$opt, builtin=>1}
				}

			#custom parse routine
			else { 
				push @pa, 
					{name=>$ident, parse=>\&{$KW_MODULE."::parse_$ident"}, 
						action=>\&{$KW_MODULE."::action_$ident"},  
						opt=>$opt}; 
				}; 
		}
	}

	return \@pa;
}

sub mk_parser {
	my ($plist,$keyword) = @_;
	return sub {
		my $parser = Keyword::Parser->new;
		$parser->next_token; # skip keyword
		$parser->skip_ws;
		my @arg;

		#call each parse routine and action
		for my $r (@$plist) {
			#TODO: add evals
			my $match = &{$r->{parse}}($parser); 
			$parser->skip_ws;
			die "failed to match parse action  $r->{name}" unless $match or $r->{opt};
			push @arg, &{$r->{action}}($match);
		}

		&{$Keyword::__keyword_block}(@arg);
	};
}

# build import routine for new keyword module
sub mk_import {
	my ($pb, $keyword) = @_;

	return sub {
		# module_user is the user of your Keyword based module
		my $module_user = caller();
		Devel::Declare->setup_for(
			$module_user,
			{ $keyword => { const => $pb } }
		);

		# setup prototype for there keyword into modules namespace
		no strict 'refs';
		*{$module_user."::$keyword"} = sub (&) {};
	};
}


1;
