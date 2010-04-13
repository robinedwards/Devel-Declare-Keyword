package Devel::Declare::Keyword;
use 5.008000;
use strict;
use warnings;
use Carp;
use Devel::Declare;
use B::Hooks::EndOfScope;
use Data::Dumper;
use Devel::Declare::Keyword::Context;
use Devel::Declare::Keyword::Parser;
use Devel::Declare::Keyword::Routine qw/Proto Ident/;

our $VERSION = '0.04';
our $KW_MODULE = caller;
our $DEBUG = 0;

#setup parser for keyword syntax
sub import {
	$DEBUG = 1 if $_[1] and $_[1] =~ /debug/i;

	Devel::Declare->setup_for(
		$KW_MODULE,
		{	keyword => { const => \&keyword_parser },
			parse => { const => \&parse_parser },
			action => { const => \&action_parser }
		}
	);

	no strict 'refs';
	*{$KW_MODULE.'::keyword'} = sub (&) { 
		$Devel::Declare::Keyword::__keyword_block = shift; 
	};
	*{$KW_MODULE.'::parse'} = sub (&) { };
	*{$KW_MODULE.'::action'} = sub (&) { };

	strict->import;
	warnings->import;
}

#parses keyword signature
sub keyword_parser {
	my $ctx = Devel::Declare::Keyword::Context->new(@_);
	$ctx->next_token;
	$ctx->skip_ws;

	#strip out the name of new keyword
	my $keyword = Ident($ctx) or
	confess "expecting identifier for keyword near:\n".$ctx->line;

	$ctx->skip_ws;

	#extract the prototype
	my $proto = Proto($ctx)	or
	confess "expecting prototype for keyword at:\n".$ctx->line;

	my $b = 1 if $proto =~ /block/i;
	my $parser = Devel::Declare::Keyword::Parser->new({proto=>$proto, 
			module=>$KW_MODULE, block=>$b, keyword=>$keyword});

	no strict 'refs';
	*{$KW_MODULE."::import"} = mk_import($parser->build, $keyword, $b);

	$ctx->skip_ws;
	my $l = $ctx->line;
	
	substr($l, $ctx->offset+1, 0) = $parser->unfold_proto_code;
	$ctx->line($l);

	#install shadow for keyword routine
	$ctx->shadow($ctx->package."::".$keyword);
}

# parses the parse keyword
sub parse_parser {
	my $ctx = Devel::Declare::Keyword::Context->new(@_);
	$ctx->next_token;
	$ctx->skip_ws;

	#strip out the name of parse routine
	my $name = Ident($ctx) or
	confess "expecting identifier for parse near:\n".$ctx->line;

	$ctx->skip_ws;
	my $proto = Proto($ctx)	or
	confess "expecting prototype for parse at:\n".$ctx->line;

	$ctx->skip_ws;
	my $l = $ctx->line;
	my $code =  "BEGIN { Devel::Declare::Keyword::eos()}; my ($proto) = \@_;";

	substr($l, $ctx->offset+1, 0) = $code;
	$ctx->line($l);

	$ctx->shadow("$KW_MODULE\::parse", sub (&) { 
		no strict 'refs';
		*{$KW_MODULE."::parse_$name"} =  shift; 
	});
}

# parses the action keyword
sub action_parser {
	my $ctx = Devel::Declare::Keyword::Context->new(@_);
	$ctx->next_token;
	$ctx->skip_ws;

	#strip out the name of action
	my $name = Ident($ctx) or
	confess "expecting identifier for action near:\n".$ctx->line;

	$ctx->skip_ws;
	my $proto = Proto($ctx) or
	confess "expecting prototype for action at:\n".$ctx->line;

	$ctx->skip_ws;
	my $l = $ctx->line;
	my $code =  "BEGIN { Devel::Declare::Keyword::eos()}; my ($proto) = \@_;";

	substr($l, $ctx->offset+1, 0) = $code;
	$ctx->line($l);

	$ctx->shadow("$KW_MODULE\::action", sub (&) { 
		no strict 'refs';
		*{$KW_MODULE."::action_$name"} =  shift; 
	});
}

sub eos {
	on_scope_end {
		my $ctx = Devel::Declare::Keyword::Context->new;
		my $l = $ctx->line;
		my $loffset = $ctx->line_offset;
		substr($l, $loffset, 0) = ';';
		$ctx->line($l);
	};
}



# build import routine for new keyword module
sub mk_import {
	my ($parser, $keyword, $block) = @_;

	return sub {
		my $module_user = caller();
		# module_user is the user of your Keyword based module
		Devel::Declare->setup_for(
			$module_user,
			{ $keyword => { const => $parser } }
		);

		# setup prototype for there keyword into modules namespace
		no strict 'refs';

		if ($block) {
			*{$module_user."::$keyword"} = sub (&) { 
				no strict 'refs';
				my $name =  ${$module_user."::__block_name"};
				*{$name} = shift; #store block 
				${$module_user."::__block_name"} = undef;
			};
		}
		else {
			no strict 'refs';
			*{$module_user."::$keyword"} = sub { 
				&$Devel::Declare::Keyword::__keyword_block(@Devel::Declare::Keyword::__keyword_block_arg); 
			};
		}
	};
}


1;
__END__

=head1 NAME 

Devel::Declare::Keyword - an easy way to declare keyword with custom parsers

=cut

=head1 SYNOPSIS

	keyword method (Maybe[Ident] $ident, Maybe[Proto] $proto, Block $block) {
		$block->name($ident);
		$block->inject_begin($proto);
		$block->inject_after("warn 'post block inject ok';");
		$block->terminate;
	}


	action Proto ($proto) {
		$proto =~ s/\s//g;
		$proto = "\$self,$proto" if length($proto);
		return " my ($proto) = \@_; ";
	}

	# return method name
	action Ident ($ident) { 
		return $ident; 
	}
	1;
	 
	use Method;

	method add ($a, $b, $c) { 
		return $a+$b+$c;
	}

=cut

=head1 USAGE 

Each identifier in a keywords prototype represents a parse routine and its associated action.

=cut;

=head2 Parse routines

There are three built-in parse routines:

 Ident - matches an identifier 
 Proto - matches anything surrounded by parenthese
 Block - matches the start of a block

Its possible to write your own with the following syntax:

 parse UpperIdent($ctx) {
    if (my $len = $ctx->scan_word(1)) {
        my $l = $ctx->line;
        my $ident = substr($l, $ctx->offset, $len);
        substr($l, $ctx->offset, $len) = '';
        $ctx->line($l);
        return $ident if $ident =~ /^[A-Z]+$/;
    }	
 }

=head3 Blocks

A block is different from a standard parser routine as it returns an object.

This object contains several routines for injecting code into the block:

 $block->name($identifier);
 $block->code("some(); code();"); # no newlines please
 $block->terminate; # adds semicolon

=cut

=head2 Actions

Actions get passed whatever the associated routine returns.

Typically used to return injectable perl code.

=cut

=head1 CODE

git push p5sagit@git.shadowcat.co.uk:Devel-Declare-Keyword.git

=head1 AUTHOR

Robin Edwards  <robin.ge@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Robin Edwards

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
