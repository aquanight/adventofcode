#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @reports;

while (<>) {
	chomp;
	my (@levels) = split / +/, $_;
	push @reports, \@levels;
}

my $safe = 0;

for my \@report (@reports) {
	local $" = ", ";
	print STDERR "Report: @report\n";
	my @diffs;

	for my $ix (1 .. $#report) {
		$diffs[$ix - 1] = $report[$ix] - $report[$ix - 1];
	}

	print STDERR "Diffs: @diffs\n";

	@diffs = sort { $a <=> $b } @diffs;
	
	if (grep { !$_ } @diffs) {
		print STDERR "Unsafe: contains a zero diff\n";
		next;
	}

	if ($diffs[0] * $diffs[-1] < 0) {
		print STDERR "Unsafe: has both increasing and decreasing steps\n";
		next;
	}

	if ($diffs[0] < -3 || $diffs[-1] > 3) {
		print STDERR "Unsafe: too fast increase or decrease\n";
		next;
	}

	print STDERR "Safe.\n";
	++$safe;
}

say $safe;
