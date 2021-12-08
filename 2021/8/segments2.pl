#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $easyct = 0;

sub overlap ($x, $y) {
	join "", $x =~ m/[\Q$y\E]/g;
}

sub subtract ($x, $y) {
	$x =~ s/[\Q$y\E]//gr;
}

my $sum = 0;

while (<>) {
	my ($segments, $output) = /^([abcdefg ]+)\|\s*([abcdefg ]+)$/ or die "Input error";
	my @seg = split / +/, $segments;
	my @out = split / +/, $output;

	$_ = join "", sort split // for @seg;
	$_ = join "", sort split // for @out;

	# Start with the easy ones: which signal is '1' '4' '7' or '8'
	my ($one) = grep { length $_ == 2 } @seg;
	my ($four) = grep { length $_ == 4 } @seg;
	my ($seven) = grep { length $_ == 3 } @seg;
	my ($eight) = grep { length $_ == 7 } @seg;

	# '0' '6' and '9' are the only ones that have 6 segments, and of them '6' is the only one with an "off" segment that appears in '1'
	my ($six) = grep { length $_ == 6 && length(overlap $_, $one) == 1 } @seg;
	say "Found six as $six (one is $one)";
	# The common segment between '6' and '1' is the F segment
	my $F = overlap $six, $one;
	length $F == 1 or die "Bad F segment $F";
	# The overlap of '9' and '4' is just '4', while '0' is missing the D segment but '9' is not.
	# Also make sure '0' and '9' have all of '1' in them.
	my ($zero) = grep { length $_ == 6 && length(overlap $_, $four) == 3 && length(overlap $_, $one) == 2 } @seg;
	my ($nine) = grep { length $_ == 6 && length(overlap $_, $four) == 4 && length(overlap $_, $one) == 2 } @seg;

	# '0' minus '9' identifies the E segment, while '9' minus '0' identifies the D segment
	my $E = subtract($zero, $nine);
	length $E == 1 or die "Bad E segment $E";
	my $D = subtract($nine, $zero);
	length $D == 1 or die "Bad D segment $D";

	# What's left? 2, 3, and 5...
	# '2' has an E segment but 3 and 5 do not.
	my ($two) = grep { length $_ == 5 and $_ =~ /$E/ } @seg;
	# 3 overlapped with 1 is all of 1, but 5 is missing the C segment. Also 5 should not have an E segment
	my ($five) = grep { length $_ == 5 and length(overlap $_, $one) == 1 && $_ !~ /$E/ } @seg;
	my ($three) = grep { length $_ == 5 and length(overlap $_, $one) == 2 } @seg;

	my %map = ( $one => 1, $two => 2, $three => 3, $four => 4, $five => 5, $six => 6, $seven => 7, $eight => 8, $nine => 9, $zero => 0 );

	say "Key: " . join " ", %map;

	say "Decoding @out";

	my $value = 0 + (join "", map { $map{$_} } @out);
	say "Decoded $value";
	$sum += $value;
}

say "Count of 1/4/7/8: $easyct";

say "Total: $sum";
