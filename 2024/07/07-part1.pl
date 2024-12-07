#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use integer;

use Carp ();

my $score = 0;

while (<>) {
	chomp;
	/^(\d+):\s+([\d\s]+)/ or die "Input error";
	my $tval = $1 + 0;
	my $src = $2;
	my @src = split / +/, $src;
	say STDERR "Processing line: Target $tval, Source: @src";
	my @paths = shift @src;
	while (@src) {
		my $nx = shift @src;
		my @newpath;
		for my $path (@paths) {
			my $add = $path + $nx;
			my $mul = $path * $nx;
			$add <= $tval and push @newpath, $add;
			$mul <= $tval and push @newpath, $mul;
		}
		\@paths = \@newpath;
	}
	say STDERR "\tFinal Paths: @paths";
	if (grep { $_ == $tval } @paths) {
		$score += $tval;
	}
}

say $score;
