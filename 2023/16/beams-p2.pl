#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

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

my @beams;

# One big change from part 1 is that the @visited array is now part of each beam.
# However, every beam that splits from a previous beam shares the same visited array: so every beam that comes from the same start position shares the same visited array.
# Like before, the array is used to detect loops, and also determine the energized count.

for my $x (0 .. ($width - 1)) {
	push @beams => [ $x, 0, 0, 1, [] ];
	push @beams => [ $x, $#map, 0, -1, [] ];
}
for my $y (0 .. $#map) {
	push @beams => [ 0, $y, 1, 0, [] ];
	push @beams => [ ($width - 1), $y, -1, 0, [] ];
}

# A beam is represented as a 4-item array: [ x, y, dx, dy ]
# Each cmd_ sub takes a beam and return one or more beams representing what happens to it.

sub pfx { my $len = @beams; $len > 50 and $len = 50;  return " " x (@beams); }

my $best = 0;

sub cmd_off_grid ($beam) {
	# Once a beam goes off-screen, count its tile visits and update the score if better.
	my \($x, $y, $dx, $dy, $v) = \($beam->@[0, 1, 2, 3, 4]);
	my $ct = List::Util::sum0 map { map { $_ ? 1 : 0 } @$_ } @$v;
	if ($ct > $best) {
		say STDERR "New best: $ct";
		#say STDERR join("\n", map { join "", map { $_ ? '#' : '.' } @$_ } @$v);
		$best = $ct;
	}
	return ();
}

sub cmd_none ($beam) {
	my \($x, $y, $dx, $dy, $v) = \($beam->@[0, 1, 2, 3, 4]);
	$x += $dx;
	$y += $dy;
	return $beam;
}

sub cmd_mirror_up ($beam) {
	my \($x, $y, $dx, $dy, $v) = \($beam->@[0, 1, 2, 3, 4]);
	($dx, $dy) = (-$dy, -$dx);
	$x += $dx;
	$y += $dy;
	return $beam;
}

sub cmd_mirror_dn ($beam) {
	my \($x, $y, $dx, $dy, $v) = \($beam->@[0, 1, 2, 3, 4]);
	($dx, $dy) = ($dy, $dx);
	$x += $dx;
	$y += $dy;
	return $beam;
}

sub cmd_split_vert ($beam) {
	my \($x, $y, $dx, $dy, $v) = \($beam->@[0, 1, 2, 3, 4]);
	if ($dy != 0) {
		$x += $dx;
		$y += $dy;
		return $beam;
	}
	else {
		return [ $x, ($y - 1), 0, -1, $v ], [ $x, ($y + 1), 0, 1, $v ];
	}
}

sub cmd_split_horz ($beam) {
	my \($x, $y, $dx, $dy, $v) = \($beam->@[0, 1, 2, 3, 4]);
	if ($dx != 0) {
		$x += $dx;
		$y += $dy;
		return $beam;
	}
	else {
		return [ ($x - 1), $y, -1, 0, $v ], [ ($x + 1), $y, 1, 0, $v ];
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
	my ($x, $y, $dx, $dy, $v) = @$beam;
	if ($x < 0 || $x >= $width || $y < 0 || $y > $#map) {
		push @beams, cmd_off_grid($beam);
		next;
	}
	$v->[$y]->[$x] //= 0;
	my $bit = 0;
	$dx > 0 and $bit |= 1;
	$dx < 0 and $bit |= 4;
	$dy < 0 and $bit |= 2;
	$dy > 0 and $bit |= 8;
	if (($v->[$y]->[$x] & $bit) == $bit) {
		push @beams, cmd_off_grid($beam);
		next;
	}
	$v->[$y]->[$x] |= $bit;
	my $chr = substr($map[$y], $x, 1);
	my $cmd = $cmds{$chr};
	defined $cmd or die "Uh oh";
	push @beams, $cmd->($beam);
}

say $best;
