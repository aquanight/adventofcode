#!/usr/bin/perl
use v5.30;
use warnings;

my $pos = 0;

use constant RIGHT => 1;
use constant DOWN => 2;

my $tree = 0;

my $line = 9;

while (<>) {
	chomp;
	++$line;
	if ($line >= DOWN) {
		$line = 0;
		my $ix = $pos % length($_);
		my $chr = substr($_, $ix, 1);
		print "$_ ";
		if ($chr eq '#') {
			++$tree;
			substr($_, $ix, 1) = 'X';
		}
		else {
			substr($_, $ix, 1) = 'O';
		}
		say $_;
		$pos += RIGHT;
	}
	else {
		say "$_ $_";
	}
}

say "Trees: $tree";
