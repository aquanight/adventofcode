#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $score;

my %score = (
	PAREN => 3,
	BRACKET => 57,
	BRACE => 1197,
	ANGLE => 25137,
);

while (<>) {
	chomp;
	my $orig = $_;
	# Remove valid chunks
	while (s/(\(\))|(\[\])|(\<\>)|(\{\})//g) { }
	# Look for corruption
	if (/([\[\{\<]\)(*MARK:PAREN))|([\(\{\<]\](*MARK:BRACKET))|([\(\[\<]\}(*MARK:BRACE))|([\(\[\{]\>(*MARK:ANGLE))/) {
		say STDERR "Found illegal line '$orig': Bad chunk is $&";
		$score += $score{our $REGMARK};
	}
}

say "Total score: $score";
