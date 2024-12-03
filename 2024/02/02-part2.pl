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

sub is_safe (@report) {
	my @diffs;

	for my $ix (1 .. $#report) {
		$diffs[$ix - 1] = $report[$ix] - $report[$ix - 1];
	}
	@diffs = sort { $a <=> $b } @diffs;
	
	if (grep { !$_ } @diffs) {
		return !!0;
	}

	if ($diffs[0] * $diffs[-1] < 0) {
		return !!0;
	}

	if ($diffs[0] < -3 || $diffs[-1] > 3) {
		return !!0;
	}

	return !!1;
	
}

REPORT: for my \@report (@reports) {
	local $" = ", ";

	print STDERR "Report: @report\n";

	if (is_safe(@report)) {
		print STDERR "Safe without alteration\n";
		++$safe;
		next;
	}

	for my $ix (0 .. $#report) {
		my @partial = @report;
		splice @partial, $ix, 1;
		if (is_safe(@partial)) {
			print STDERR "Safe by removing #$ix\n";
			++$safe;
			next REPORT;
		}
	}

	print STDERR "Not safe\n";
}

say $safe;
