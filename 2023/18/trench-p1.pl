#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @map;

$map[0][0] = 1;

my $x = 0;
my $y = 0;

package Commands {

	sub cmd_U {
		if ($y == 0) {
			unshift @map, [];
		}
		else {
			--$y;
		}
	}
	
	sub cmd_D {
		++$y;
	}
	
	sub cmd_L {
		if ($x == 0) {
			unshift @$_, 0 for @map;
		}
		else {
			--$x;
		}
	}
	
	sub cmd_R {
		++$x;
	}
}

while (<>) {
	my ($cmd, $steps, $clr) = /^([UDLR]) +(\d+) +\((\#[0-9a-f]{6})\)$/;
	defined $cmd or die "Input error";
	my $cmdproc = Commands->can("cmd_$cmd");
	defined $cmdproc or die "Uh oh";
	while ($steps > 0) {
		--$steps;
		$cmdproc->();
		$map[$y][$x] = $cmd;
	}
}

use List::Util ();
sub count_trench {
	return List::Util::sum0 map { map { $_ ? 1 : 0 } @$_ } @map;	
}

my $ct = count_trench;
say STDERR "Initial trench is $ct blocks";

my $width = List::Util::max map { scalar @$_ } @map;

# Now must flood-fill the interior

# We need to find a seed point that is inside the polygon. We do this by a non-zero winding number test:
my $ffx;
my $ffy;

while (1) {
	$ffx = int rand $width;
	$ffy = int rand scalar @map;
	next if $map[$ffy][$ffx]; # Border, try again.
	my $wind = 0;
	for my $tx (reverse 0 .. ($ffx - 1)) {
		next unless defined $map[$ffy][$tx];
		my $t = $map[$ffy][$tx];
		if ($t eq 'U') { ++$wind; }
		elsif ($t eq 'D') { --$wind; }
	}
	# Inside if the winding number is not zero.
	last if $wind;
}

say STDERR "Seed point found: ($ffx, $ffy)";

# Now flood fill:
my @fill = ($ffx, $ffy);

while (@fill) {
	my $fx = shift @fill;
	my $fy = shift @fill;
	next if $map[$fy][$fx];
	$map[$fy][$fx] = '#';
	push @fill, $fx, ($fy - 1) if $fy > 0;
	push @fill, $fx, ($fy + 1) if $fy < $#map;
	push @fill, ($fx - 1), $fy if $fx > 0;
	push @fill, ($fx + 1), $fy if $fx < ($width - 1);
}

$ct = count_trench;
say STDERR "Filled trench is $ct blocks";

say $ct;
