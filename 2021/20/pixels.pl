#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my %pixel = (
	'.' => 0,
	'#' => 1,
);

my @map;

{
	chomp(my $map = <>);
	length $map == 512 or die "Invalid pixel map";

	@map = @pixel{ split //, $map };
}

my $xwide;
my @img;
my $inf = 0; # Whether "infinite" pixels are light or dark.

sub getpx ($x, $y) {
	if ($y < 0 || $y > $#img) { return $inf; }
	my $l = $img[$y];
	if ($x < 0 || $x > $#$l) { return $inf; }
	return $l->[$x];
}

sub step {
	my @out;
	my $newxw = $xwide + 2;
	for my $x (-1 .. $xwide) {
		for my $y (-1 .. @img) {
			use integer;
			my $ix = (
				getpx($x - 1, $y - 1) << 8 |
				getpx($x    , $y - 1) << 7 |
				getpx($x + 1, $y - 1) << 6 |
				getpx($x - 1, $y    ) << 5 |
				getpx($x    , $y    ) << 4 |
				getpx($x + 1, $y    ) << 3 |
				getpx($x - 1, $y + 1) << 2 |
				getpx($x    , $y + 1) << 1 |
				getpx($x + 1, $y + 1)
			);
			$out[$y + 1][$x + 1] = $map[$ix];
		}
	}
	@img = @out;
	$xwide = $newxw;
	$inf = ($inf ? $map[0x1FF] : $map[0]);

	if (0) {
		say STDERR "After step:";
		for my $l (@img) {
			say STDERR map { $_ ? '#' : '.' } @$l;
		}
	}
}

while (<>) {
	chomp;
	length or next; # Skip blank lines.
	my @line = @pixel{ split // };
	if (defined $xwide) {
		die "Invalid input" unless @line == $xwide;
	}
	else {
		$xwide = @line;
	}
	push @img, \@line;
}

step;
step;

die "Result is infinite" if $inf;

my $ct = grep { $_ } map { @$_ } @img;

say "Number of light pixels after 2 steps: $ct";

my $more = 48;
while ($more--) {
	step;
}

die "Result is infinite" if $inf;

$ct = grep { $_ } map { @$_ } @img;

say "Number of light pixels after 50 steps: $ct";
