#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;

while (<>) {
	/^[-\|LJ7F\.S]+$/ or die "Input error";
	push @map, $_;
}

my $stx;
my $sty;
for my $y (keys @map) {
	next unless $map[$y] =~ /S/;
	$sty = $y;
	$stx = $-[0];
	last;
}

my %seen;
$seen{"$stx,$sty"} = 0; # Mark the start location as seen

my @paths;

# Create starting states.
if ($sty > 0 && substr($map[$sty - 1], $stx, 1) =~ /[\|F7]/) {
	# North end connected
	push @paths, [ $stx, $sty - 1 ];
}
if ($sty < $#map && substr($map[$sty + 1], $stx, 1) =~ /[\|JL]/) {
	# South end connected
	push @paths, [ $stx, $sty + 1 ];
}
if ($stx > 0 && substr($map[$sty], $stx - 1, 1) =~ /[\-FL]/) {
	# West end connected
	push @paths, [ $stx - 1, $sty ];
}
if ($stx < (length($map[$sty]) - 1) && substr($map[$sty], $stx + 1, 1) =~ /[\-J7]/) {
	# East end connected
	push @paths, [ $stx + 1, $sty ];
}

my $step = 0;
while (1) {
	++$step;
	my @next;
	for my $path (@paths) {
		my ($px, $py) = @$path;
		next if defined $seen{"$px,$py"};
		die "Fell off" if ($py < 0 || $py > $#map);
		die "Fell off" if ($px < 0 || $px >= length($map[$py]));
		$seen{"$px,$py"} = $step;
		my $cmd = substr($map[$py], $px, 1);
		if ($cmd =~ /[\|F7]/) {
			push @next, [ $px, $py + 1 ];
		}
		if ($cmd =~ /[\|JL]/) {
			push @next, [ $px, $py - 1 ];
		}
		if ($cmd =~ /[\-FL]/) {
			push @next, [ $px + 1, $py ];
		}
		if ($cmd =~ /[\-J7]/) {
			push @next, [ $px - 1, $py ];
		}
	}
	last unless @next;
	\@paths = \@next;
}

say STDERR "Finished after $step steps";

for my $pos (keys %seen) {
	say STDERR "$pos => $seen{$pos}";
}

my $max = (sort {$b <=> $a} values %seen)[0];

say $max;

