#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

my $horiz = 0;
my $depth = 0;

sub dir_forward ($steps) { $horiz += $steps; }
sub dir_down ($steps) { $depth += $steps; }
sub dir_up ($steps) { $depth -= $steps; }

while (<>) {
	my ($dir, $steps) = /^(\w+) (\d+)/ or die "Line $_ invalid";
	
	my $op = main->can("dir_$dir") or die "Unknown direction $dir";
	$op->($steps);
}

my $prod = $horiz * $depth;

say "At $horiz forward and $depth down : product $prod";
