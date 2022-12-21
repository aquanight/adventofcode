#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my @stacks;

while (<>) {
	chomp;
	my $tok;
	m/^[\s\d]+$/ and last; # Footer line: stop reading stacks
	for (my $stkno = 0; (4*$stkno) < length; ++$stkno) {
		pos($_) = 4 * $stkno;
		if (($tok) = /\G\[(.)\](?: |$)/) {
			unshift $stacks[$stkno]->@*, $tok;
		}
		else {
			die unless /\G   (?: |$)/;
		}
	}
}

(scalar(<>) =~ m/^$/) or die "Missing separator";

while (<>) {
	chomp;
	my ($amt, $from, $to);
	(($amt, $from, $to) = /^move (\d+) from (\d+) to (\d+)$/) or die "Input error";
	--$from;
	--$to;
	push $stacks[$to]->@*, splice($stacks[$from]->@*, -$amt);
}

my $result = join "", map { $_->[-1] } @stacks;

say $result;
