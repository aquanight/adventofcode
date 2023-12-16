#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;

my $width;

while (<>) {
	chomp;
	/^[\.\#\|\-\/\\]+$/ or die "Input error ($_)";
	push @map, $_;
	$width //= length;
}

# Visited will contain a bitfield ( 0 = right, 1 = down, 2 = left, 3 = up )
# That way we detect loops.
my @visited;

my @beams;

push @beams, [ 0, 0, 1, 0 ];

# A beam is represented as a 4-item array: [ x, y, dx, dy ]
# Each cmd_ sub takes a beam and return one or more beams representing what happens to it.

sub pfx { my $len = @beams; $len > 50 and $len = 50;  return " " x (@beams); }

sub cmd_off_grid ($beam) { return (); }

sub cmd_none ($beam) {
	my \($x, $y, $dx, $dy) = \($beam->@[0, 1, 2, 3]);
	$x += $dx;
	$y += $dy;
	return $beam;
}

sub cmd_mirror_up ($beam) {
	my \($x, $y, $dx, $dy) = \($beam->@[0, 1, 2, 3]);
	say STDERR pfx, "Reflect up at ($x, $y)";
	($dx, $dy) = (-$dy, -$dx);
	$x += $dx;
	$y += $dy;
	return $beam;
}

sub cmd_mirror_dn ($beam) {
	my \($x, $y, $dx, $dy) = \($beam->@[0, 1, 2, 3]);
	say STDERR pfx, "Reflect down at ($x, $y)";
	($dx, $dy) = ($dy, $dx);
	$x += $dx;
	$y += $dy;
	return $beam;
}

sub cmd_split_vert ($beam) {
	my \($x, $y, $dx, $dy) = \($beam->@[0, 1, 2, 3]);
	if ($dy != 0) {
		$x += $dx;
		$y += $dy;
		return $beam;
	}
	else {
		say STDERR pfx, "V-Splitting at ($x, $y)";
		return [ $x, ($y - 1), 0, -1 ], [ $x, ($y + 1), 0, 1 ];
	}
}

sub cmd_split_horz ($beam) {
	my \($x, $y, $dx, $dy) = \($beam->@[0, 1, 2, 3]);
	if ($dx != 0) {
		$x += $dx;
		$y += $dy;
		return $beam;
	}
	else {
		say STDERR pfx, "H-Splitting at ($x, $y)";
		return [ ($x - 1), $y, -1, 0 ], [ ($x + 1), $y, 1, 0 ];
	}
}

say STDERR $_ for @map;

my %cmds = (
	'.' => \&cmd_none,
	'/' => \&cmd_mirror_up,
	'\\' => \&cmd_mirror_dn,
	'|' => \&cmd_split_vert,
	'-' => \&cmd_split_horz,
);

while (@beams) {
	my $beam = shift @beams;
	my ($x, $y, $dx, $dy) = @$beam;
	if ($x < 0 || $x >= $width || $y < 0 || $y > $#map) {
		say STDERR pfx, "Off grid at ($x, $y)";
		push @beams, cmd_off_grid($beam);
		next;
	}
	$visited[$y]->[$x] //= 0;
	my $bit = 0;
	$dx > 0 and $bit |= 1;
	$dx < 0 and $bit |= 4;
	$dy < 0 and $bit |= 2;
	$dy > 0 and $bit |= 8;
	if (($visited[$y]->[$x] & $bit) == $bit) {
		say STDERR "Loop detected at ($x, $y)";
		next;
	}
	$visited[$y]->[$x] |= $bit;
	my $chr = substr($map[$y], $x, 1);
	my $cmd = $cmds{$chr};
	defined $cmd or die "Uh oh";
	push @beams, $cmd->($beam);
}

say STDERR join("\n", map { join "", map { $_ ? '#' : '.' } @$_ } @visited);

use List::Util ();

my $ct = List::Util::sum0 map { map { $_ ? 1 : 0 } @$_ } @visited;

say $ct;
