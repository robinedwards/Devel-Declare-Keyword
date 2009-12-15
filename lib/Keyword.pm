package Keyword;
use strict;
use warnings;
use Devel::Declare;
use B::Hooks::EndOfScope;
use Data::Dumper;
use Keyword::Declare;
use Keyword::Parser;
use Keyword::Parse::Block;
use Keyword::Parse::Proto;
use Keyword::Parse::Ident;

our $VERSION = '0.03';
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
		$Keyword::__keyword_block = shift; 
	};
	*{$KW_MODULE.'::parse'} = sub (&) { };
	*{$KW_MODULE.'::action'} = sub (&) { };

	strict->import;
	warnings->import;
}

#parses keyword signature
sub keyword_parser {
	my $kd = Keyword::Declare->new;
	$kd->next_token;
	$kd->skip_ws;

	#strip out the name of new keyword
	my $keyword = Keyword::Parse::Ident::parse_ident($kd) or
	die "expecting identifier for keyword near:\n".$kd->line;

	$kd->skip_ws;

	#extract the prototype
	my $proto = Keyword::Parse::Proto::parse_proto($kd)	or
	die "expecting prototype for keyword at:\n".$kd->line;

	my $parser = Keyword::Parser->new({proto=>$proto, module=>$KW_MODULE});

	no strict 'refs';
	*{$KW_MODULE."::import"} = mk_import($parser->build, $keyword);

	$kd->skip_ws;
	my $l = $kd->line;
	my $code =  "BEGIN { Keyword::eos()}; ".kw_proto_to_code($proto);
	substr($l, $kd->offset+1, 0) = $code;
	$kd->line($l);

	#install shadow for keyword routine
	$kd->shadow($kd->package."::".$keyword);
}

# parses the parse keyword
sub parse_parser {
	my $parser = Keyword::Declare->new;
	$parser->next_token;
	$parser->skip_ws;

	#strip out the name of parse routine
	my $name = Keyword::Parse::Ident::parse_ident($parser) or
	die "expecting identifier for parse near:\n".$parser->line;

	$parser->skip_ws;
	my $proto = Keyword::Parse::Proto::parse_proto($parser)	or
	die "expecting prototype for parse at:\n".$parser->line;

	$parser->skip_ws;
	my $l = $parser->line;
	my $code =  "BEGIN { Keyword::eos()}; my ($proto) = \@_;";

	substr($l, $parser->offset+1, 0) = $code;
	$parser->line($l);

	$parser->shadow("$KW_MODULE\::parse", sub (&) { 
		no strict 'refs';
		*{$KW_MODULE."::parse_$name"} =  shift; 
	});
}

# parses the action keyword
sub action_parser {
	my $parser = Keyword::Declare->new;
	$parser->next_token;
	$parser->skip_ws;

	#strip out the name of action
	my $name = Keyword::Parse::Ident::parse_ident($parser) or
	die "expecting identifier for action near:\n".$parser->line;

	$parser->skip_ws;
	my $proto = Keyword::Parse::Proto::parse_proto($parser)	or
	die "expecting prototype for action at:\n".$parser->line;

	$parser->skip_ws;
	my $l = $parser->line;
	my $code =  "BEGIN { Keyword::eos()}; my ($proto) = \@_;";

	substr($l, $parser->offset+1, 0) = $code;
	$parser->line($l);

	$parser->shadow("$KW_MODULE\::action", sub (&) { 
		no strict 'refs';
		*{$KW_MODULE."::action_$name"} =  shift; 
	});
}

sub eos {
	on_scope_end {
		my $parser = new Keyword::Declare;
		my $l = $parser->line;
		my $loffset = $parser->line_offset;
		substr($l, $loffset, 0) = ';';
		$parser->line($l);
	};
}

sub kw_proto_to_code {
	my ($proto) = @_;
	my $inject = " my (";

	$proto =~ s/\?//g;
	$proto =~ s/\s//g;
	$proto =~ s/\,/\,\$/g;
	$proto = "\$".$proto if length $proto;
	$inject .= $proto.') = @_; ';

	return $inject;
}

sub debug { warn "DEBUG: @_\n" if $DEBUG; }


# build import routine for new keyword module
sub mk_import {
	my ($pb, $keyword) = @_;

	return sub {
		my $module_user = caller();
		# module_user is the user of your Keyword based module
		Devel::Declare->setup_for(
			$module_user,
			{ $keyword => { const => $pb } }
		);

		# setup prototype for there keyword into modules namespace
		no strict 'refs';
		*{$module_user."::$keyword"} = sub (&) { 
			no strict 'refs';
			my $name =  ${$module_user."::__block_name"};
			*{$name} = shift; #store block 
			${$module_user."::__block_name"} = undef;
		};
	};
}


1;
__END__

=head1 NAME 

Keyword - an easy way to declare keyword with custom parsers

=cut

=head1 SYNOPSIS

 package Method;
 use Keyword 'debug';

 keyword method (ident?, proto?, block) {
   	 $block->name($ident); # assign the block to subroutine
	 $block->inject_begin($proto); # inject proto code
	 $block->inject_after("warn '$ident() finished';");
	 $block->terminate; # add semi colon
 }


 # converts proto str to code
 action proto ($proto) {
 	 $proto =~ s/\s//g;
	 $proto = "\$self,$proto" if length($proto);
	 return " my ($proto) = \@_; ";
 }

 # return method name
 action ident ($ident) { 
	 return $ident; 
 }

 1;
 
 # some other code
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

 ident - matches an identifier 
 proto - matches anything surrounded by parenthese
 block - matches the start of a block

Its possible to write your own with the following syntax:

 parse identifier($parser) {
    if (my $len = $parser->scan_word(1)) {
        my $l = $parser->line;
        my $ident = substr($l, $parser->offset, $len);
        substr($l, $parser->offset, $len) = '';
        $parser->line($l);
        return $ident if $ident =~ /^[a-z]{1}\w+$/i;
    }	
 }

=head3 Blocks

A block is different from a standard parse routine as it returns an object.

This object contains several routines for injecting code into the block:

 $block->name($identifier);
 $block->code("some(); code();"); # no newlines please
 $block->terminate; # adds semicolon

=cut

=head2 Actions

Actions get passed whatever the associated parse routine 'matches'.

There job is to convert whatever is matched to injectable perl code.

=cut

=head1 CODE

http://github.com/robinedwards/Keyword

git@github.com:robinedwards/Keyword.git

=head1 AUTHOR

Robin Edwards  <robin.ge@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 the Keyword L</AUTHOR>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.




