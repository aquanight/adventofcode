#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';
no warnings 'experimental';
use feature qw/refaliasing declared_refs/;

use List::Util qw/min max/;

my $input = shift @ARGV; # Directly from command line, rather than input file.

my $moves = 0 + (shift @ARGV);

my @cups = map { 0+$_ } split //, $input;

my $lowest = min @cups;
my $highest = max @cups;

while ($moves--) {
	#print join "", @cups;

	my $current = shift @cups;
	#say "Current: $current";
	
	#print " [$current]";

	my @three = splice @cups, 0, 3;

	#printf "[%s]", join ",", @three;

	my $dest = $current;
	my $dstix;
	until (defined $dstix) {
		--$dest;
		if ($dest < $lowest) { $dest = $highest; }
		$dstix = List::Util::first { $cups[$_] == $dest } 0 .. $#cups;
	}
	#print "[$dest] ";
	#say "Want $dest at $dstix";

	splice @cups, $dstix + 1, 0, @three;

	push @cups, $current;

	#say join "", @cups;
}

my $oneix = List::Util::first { $cups[$_] == 1 } 0 .. $#cups;

unshift @cups, splice(@cups, $oneix);

say join "", @cups;
