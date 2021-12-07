#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

my $or = 0;
my @float = ();

my %mem;

sub putfloat {
	my $addr = 0+shift;
	my $value = shift;
	my $float = shift;

	if (defined $float) {
		putfloat($addr, $value, @_);
		putfloat(($addr ^ $float), $value, @_);
	}
	else {
		say "Setting $addr to $value";
		$mem{$addr} = $value;
	}
}

while (<>) {
	chomp;
	if (my ($mask) = /^mask = ([X10]+)/) {
		printf "INP mask: %036s\n", $mask;
		my $float = 0;
		@float = ();
		$or = 0;
		for my $ix (0 .. (length($mask) - 1)) {
			my $chr = substr($mask, $ix, 1);
			#print $chr;
			$float <<= 1;
			$or <<= 1;
			if ($chr eq 'X') {
				$float |= 0x1;
				push @float, (1 << (35 - $ix));
			}
			elsif ($chr eq '1') {
				$or |= 0x1;
			}
			elsif ($chr eq '0') {
			}
			#printf "%0b %0b\n", $and, $or;
		}
		#print "\n";
		printf "FLT mask: %036b\n", $float;
		printf "OR  mask: %036b\n", $or;
	}
	elsif (my ($pos, $value) = /^mem\[(\d+)\] = (\d+)/) {
		printf "Address : %036b\n", $pos;
		$pos |= $or;
		putfloat $pos, $value, @float;
	}
}

use List::Util ();

my $sum = List::Util::sum values %mem;

say "Total: $sum";
