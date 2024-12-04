#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @lines = <>;

chomp for @lines;

my $xmas = 0;

for my $ln (1 .. $#lines - 1) {
	local $_ = $lines[$ln];
	while (/A/g) {
		my $x = pos() - 1;
		next if ($x - 1) < 0 || ($x + 1) >= length $lines[$ln - 1] || ($x + 1) >= length $lines[$ln + 1];
		print STDERR "A at $x,$ln";
		my @chrs = (
			substr($lines[$ln - 1], $x - 1, 1),
			substr($lines[$ln - 1], $x + 1, 1),
			substr($lines[$ln + 1], $x - 1, 1),
			substr($lines[$ln + 1], $x + 1, 1),
		);
		print STDERR " $chrs[0] $chrs[1] $chrs[2] $chrs[3]\n";
		next unless (grep /M/, @chrs) == 2;
		next unless (grep /S/, @chrs) == 2;
		# Rotate to put an M at the top left
		until ($chrs[0] eq 'M') {
			(@chrs[0, 1, 2, 3]) = (@chrs[1, 3, 0, 2]);
		}
		if ($chrs[1] eq 'M' || $chrs[2] eq 'M') {
			say STDERR "X-MAS at $x,$ln";
			++$xmas;
		}
	}
}

say $xmas;
