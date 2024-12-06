#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my %rules;

my $score = 0;

while (<>) {
	chomp;
	if (/^(\d+)\|(\d+)$/) {
		print STDERR "Ordering rule: $1 before $2\n";
		$rules{$1}{$2} = 1;
		$rules{$2}{$1} = 0;
	}
	elsif (/^\s*$/) {
		next;
	}
	else {
		my @update = split /,/;
		my $sc = 1;
		for my $ix (0 .. $#update) {
			my $vx = $update[$ix];
			for my $iy ( ($ix + 1) .. $#update ) {
				my $vy = $update[$iy];
				$sc *= ($rules{$vx}{$vy} // 1);
				last if $sc == 0;
			}
			last if $sc == 0;
		}
		if ($sc) {
			print STDERR "Correct order: @update\n";
			die if scalar(@update) % 2 == 0;
			my $mid = $update[$#update / 2];
			$score += $mid;
		}
		else {
			print STDERR "Incorrect order: @update\n";
		}
	}
}

say $score;
