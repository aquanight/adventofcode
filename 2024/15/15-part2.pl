#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my $xw = 0;
my $yw = 0;

my %walls;
my %boxes;
my $robot;

while (<>) {
	chomp;
	last if /^\s*$/;
	$xw = 2 *  length if $xw < length;
	pos() = 0;
	while (/#/g) {
		my $x = $-[0] * 2;
		$walls{"$x,$yw"} = 1;
		++$x;
		$walls{"$x,$yw"} = 1;
	}
	pos() = 0;
	while (/O/g) {
		my $x = $-[0] * 2;
		$boxes{"$x,$yw"} = 1;
	}
	pos() = 0;
	if (/@/g) {
		my $x = $-[0] * 2;
		$robot = [ $x, $yw ];
	}
	++$yw;
}

my @moves;

my %dir = (
	'>' => [1, 0],
	'<' => [-1, 0],
	'v' => [0, 1],
	'^' => [0, -1],
);

sub print_grid {
	for my $y ( 0 .. ($yw - 1) ) {
		for my $x ( 0 .. ($xw - 1) ) {
			if ($walls{"$x,$y"}) { print STDERR "#"; next; }
			if ($boxes{"$x,$y"}) { print STDERR "["; next; }
			if ($boxes{($x - 1).",$y"}) { print STDERR "]"; next; }
			if ($robot->[0] == $x && $robot->[1] == $y) { print STDERR "@"; next; }
			print STDERR ".";
		}
		print STDERR "\n";
	}
}

while (<>) {
	chomp;
	MOVE: for my $move (split //) {
		#print_grid;
		say STDERR "Step: $move";
		#scalar <STDIN>;
		my (\$dx, \$dy) = \($dir{$move}->@*);
		
		my %moveboxes;
		my (\$rx, \$ry) = \($robot->@[0, 1]);
		my $nx = $rx + $dx;
		my $ny = $ry + $dy;
		my @check = [ $nx, $ny ];
		while (@check) {
			my ($cx, $cy) = shift(@check)->@*;
			say STDERR "Checking $cx,$cy";
			if ($walls{"$cx,$cy"}) {
				say STDERR "> Hit wall";
				next MOVE;
			}
			elsif ($boxes{"$cx,$cy"}) {
				$moveboxes{"$cx,$cy"} = [ $cx, $cy ];
				say STDERR "Moving box at $cx,$cy";
				if ($dy == 0) {
					push @check, [ $cx + ($dx * 2), $cy ];
				}
				else {
					push @check, [ $cx + $dx, $cy + $dy ];
					push @check, [ $cx + 1 + $dx, $cy + $dy ];
				}
			}
			elsif ($boxes{($cx - 1).",$cy"}) {
				--$cx;
				say STDERR "Moving box at $cx,$cy";
				$moveboxes{"$cx,$cy"} = [ $cx, $cy ];
				if ($dy == 0) {
					push @check, [ $cx + $dx, $cy ];
				}
				else {
					push @check, [ $cx + $dx, $cy + $dy ];
					push @check, [ $cx + 1 + $dx, $cy + $dy ];
				}
			}
		}
		# Move the boxes
		for my $box (values %moveboxes) {
			my ($bx, $by) = @$box;
			$boxes{"$bx,$by"}--;
			$bx += $dx;
			$by += $dy;
			$boxes{"$bx,$by"}++;
		}
		# Now move the robot
		$rx += $dx;
		$ry += $dy;
	}
}

my $score = 0;

for my $box (sort keys %boxes) {
	next unless $boxes{$box};
	my ($x, $y) = split /,/, $box;
	say STDERR "Box at $x,$y";
	$score += ($y * 100) + $x;
}

say $score;

