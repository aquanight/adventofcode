#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;
my $width;

while (<>) {
	chomp;
	/^[\.\#O]+$/ or die "Input error";
	push @map, $_;
	$width //= length;
}

# Tilting
my $load = 0;

my @open;
$_ = @map for @open[0 .. ($width - 1)];

for my $y (0 .. $#map) {
	my $next = $#map - $y;
	for my $ix (0 .. ($width - 1)) {
		my $cmd = substr($map[$y], $ix, 1);
		if ($cmd eq '#') {
			$open[$ix] = $next;
		}
		elsif ($cmd eq 'O') {
			$load += $open[$ix];
			$open[$ix]--;
		}
	}
}

say $load;
