package KeywordMethod;
use strict;
use warnings;
use Keyword;

our $OFFSET;

keyword method => {
		name=>{parse=>\&parse_name}, 
		proto=>{parse=>\&parse_proto, action=>\&proto_action, eos=>\&proto_eos}};

#parse method name
sub parse_name {
	if (my $len = scan_word(1)) {
		my $line = get_line;
		my $name = substr($line, $OFFSET, $len);
		substr($line, $OFFSET, $len) = '';
		set_line($line);
		return $name;
	}
}

#parse prototype
sub parse_proto {
	my $linestr = get_line;
	if (substr($linestr, $OFFSET, 1) eq '(') {
		#need to wrap the following stuff in Keyword:
		my $length = scan_string;
		my $proto = get_lex;
		$linestr = get_line;
		substr($linestr, $OFFSET, $length) = '';
		set_line($linestr);
		return $proto;
	}
	return;
}

#construct code for injection
sub proto_action {
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

sub proto_eos {
	my $linestr = get_line;
	my $loffset = get_line_offset;
	substr($linestr, $loffset, 0) = ';';
	set_line($linestr);
}

1;


