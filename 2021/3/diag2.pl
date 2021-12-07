#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $bitcount;

my @bits;

our @data;

while (<>) {
	chomp;
	/^[01]+$/ or die "Invalid input";
	push @data, oct("0b$_");
	my @lb = split //, $_;

	if (scalar @bits) {
		(@lb * 2) == scalar @bits or die "Inconsistent input";
		while (my ($i, $v) = each @lb) {
			$bits[$i * 2 + !!$v]++;
		}
	}
	else {
		@bits = map { $_ ? (0, 1) : (1, 0) } @lb;
		$bitcount = $#lb;
	}
}

my $gamma = 0;
my $epsilon = 0;
while (@bits) {
	my ($_0, $_1) = splice @bits, 0, 2;
	if ($_1 > $_0) { $gamma |= 1; }
	else { $epsilon |= 1; }
	$gamma <<= 1;
	$epsilon <<= 1;
}

$gamma >>= 1;
$epsilon >>= 1;

my $pow = $gamma * $epsilon;

say "Gamma is $gamma, Epsilon $epsilon, Power rate $pow";

my ($o2, $co2);

{
	local @data = @data;

	for my $bit (reverse 0 .. $bitcount) {
		last if @data < 2;
		my $check = 1 << $bit;
		my $ones = grep { $_ & $check } @data;
		if ($ones*2 >= @data) {
			# 54% or more have a 1 bit
			@data = grep { $_ & $check } @data;
		}
		else {
			@data = grep { !($_ & $check) } @data;
		}
	}

	say "O2 generator is " . ($o2 = shift @data);
}


{
	local @data = @data;

	for my $bit (reverse 0 .. $bitcount) {
		last if @data < 2;
		my $check = 1 << $bit;
		my $ones = grep { $_ & $check } @data;
		if ($ones*2 >= @data) {
			# 54% or more have a 1 bit
			@data = grep { !($_ & $check) } @data;
		}
		else {
			@data = grep { $_ & $check } @data;
		}
	}

	say "CO2 scrubber is " . ($co2 = shift @data);
}

say "Product: " . ($o2 * $co2);
