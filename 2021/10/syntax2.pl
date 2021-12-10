#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my @scores;

my %score = (
	')' => 1,
	']' => 2,
	'}' => 3,
	'>' => 4,
);

while (<>) {
	chomp;
	my $orig = $_;
	# Remove valid chunks
	while (s/(\(\))|(\[\])|(\<\>)|(\{\})//g) { }
	# Look for corruption
	if (/([\[\{\<]\))|([\(\{\<]\])|([\(\[\<]\})|([\(\[\{]\>)/) {
		next;
	}
	my $close = (reverse $_) =~ tr/([{</)]}>/r;
	my $val = 0;
	for my $ch (split //, $close) {
		$val = ($val * 5) + $score{$ch};
	}
	if ($val > 0) {
		say STDERR "Incomplete line $orig, closed with $close, score $val";
		push @scores, $val;
	}
}

@scores = sort {$a <=> $b} @scores;

my $score = @scores[$#scores / 2];

say "Total score: $score";
