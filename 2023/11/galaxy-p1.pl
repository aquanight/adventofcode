#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @galaxies;

my @expand_x;
my $expand_y = 0;

my $width;

while (<>) {
	/^[\.#]+$/ or die "Input error";
	unless (defined $width) {
		$width = length;
		$_ = 1 for @expand_x[0 .. ($width - 1)];
	}
	my $y = ($. - 1) + $expand_y;
	my $any = 0;
	while (/#/g) {
		$any = 1;
		my $x = $-[0];
		$expand_x[$x] = 0;
		push @galaxies, [ $x, $y ];
	}
	unless ($any) { ++$expand_y; }
}

# y-expansion could be done during input read, now do x-expansion
for my $ex (reverse keys @expand_x) {
	$expand_x[$ex] or next;
	for my $gal (@galaxies) {
		next if $gal->[0] < $ex;
		$gal->[0]++;
	}
}

my $sum = 0;
my $ix = 0;

while (@galaxies) {
	++$ix;
	my $st = shift @galaxies;
	my ($x1, $y1) = @$st;
	my $ix2 = $ix;
	for my $og (@galaxies) {
		++$ix2;
		my ($x2, $y2) = @$og;
		my $dist = abs($x1 - $x2) + abs($y1 - $y2);
		$sum += $dist;
	}
}

say $sum;
