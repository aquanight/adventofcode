#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %walls;

my $xw = 0;
my $yw = 0;

my ($sx, $sy);
my ($ex, $ey);

while (<>) {
	chomp;
	$xw = length if $xw < length;
	while (/#/g) {
		my $x = $-[0];
		$walls{"$x,$yw"} = 1;
	}
	pos() = 0;
	if (/S/) {
		$sx = $-[0];
		$sy = $yw;
	}
	pos() = 0;
	if (/E/) {
		$ex = $-[0];
		$ey = $yw;
	}
	++$yw;
}

my $end_score;

my %seen; # key: x,y => [ score ] (same indexes as direction)

my @dirs = (
	[1, 0], # east
	[0, 1], # south
	[-1, 0],# west
	[0, -1],# north
);

my @steps; # x, y, dir, score, @path

@steps = [ $sx, $sy, 0, 0, $sx, $sy ];

my @end_paths;

while (@steps) {
	my ($x, $y, $dir, $score, @path) = shift(@steps)->@*;
	next if (defined $seen{"$x,$y"}[$dir] && $seen{"$x,$y"}[$dir] < $score);
	next if defined $end_score && $end_score < $score;
	$seen{"$x,$y"}[$dir] = $score;
	if ($x == $ex && $y == $ey) {
		if (!defined($end_score) || $end_score > $score) {
			@end_paths = [ @path ];
			$end_score = $score;
		}
		else {
			push @end_paths, [ @path ];
		}
	}
	my ($dx, $dy) = $dirs[$dir]->@*;
	my $nx = $x + $dx;
	my $ny = $y + $dy;
	unless ($walls{"$nx,$ny"}) {
		push @steps, [ $nx, $ny, $dir, $score + 1, @path, $nx, $ny ];
	}
	for my $rotate (-1, 1, 2) {
		my $nd = ($dir + $rotate) % 4;
		my $rx = $x + $dirs[$nd][0];
		my $ry = $y + $dirs[$nd][1];
		next if $walls{"$rx,$ry"};
		push @steps, [ $rx, $ry, $nd, $score + 1 + abs($rotate) * 1000, @path, $rx, $ry ];
	}
}

my %path_tiles;

for my $path (@end_paths) {
	while (@$path) {
		my $x = shift @$path;
		my $y = shift @$path;
		$path_tiles{"$x,$y"} = 1;
	}
}

for my $y ( 0 .. ( $yw - 1 ) ) {
	for my $x ( 0 .. ($xw - 1) ) {
		if ($walls{"$x,$y"}) { print STDERR '#';  }
		elsif ($path_tiles{"$x,$y"}) { print STDERR 'O'; }
		else { print STDERR '.'; }
	}
	print STDERR "\n";
}

say scalar keys %path_tiles;
