#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

my $and = 0;
my $or = 0;

my %mem;

while (<>) {
	chomp;
	if (my ($mask) = /^mask = ([X10]+)/) {
		printf "INP mask: %036s\n", $mask;
		$and = 0;
		$or = 0;
		for my $ix (0 .. (length($mask) - 1)) {
			my $chr = substr($mask, $ix, 1);
			#print $chr;
			$and <<= 1;
			$or <<= 1;
			if ($chr eq 'X') {
				$and |= 0x1;
			}
			elsif ($chr eq '1') {
				$and |= 0x1;
				$or |= 0x1;
			}
			elsif ($chr eq '0') {
			}
			#printf "%0b %0b\n", $and, $or;
		}
		#print "\n";
		printf "AND mask: %036b\n", $and;
		printf "OR  mask: %036b\n", $or;
	}
	elsif (my ($pos, $value) = /^mem\[(\d+)\] = (\d+)/) {
		$value &= $and;
		$value |= $or;
		$mem{$pos} = $value;
	}
}

use List::Util ();

my $sum = List::Util::sum values %mem;

say "Total: $sum";
