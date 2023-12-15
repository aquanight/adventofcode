#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

my @boxes;

$_ = [{}] for @boxes[0 .. 255];

while (<>) {
	chomp;
	for my $step (split /,/, $_) {
		my $hash = 0;
		my ($label, $cmd) = $step =~ /^(.*)(=\d+|-)$/;
		$label // die "Input error";
		for my $chr (split //, $label) {
			my $ord = ord $chr;
			$hash = (($hash + $ord) * 17) % 256;
		}
		say STDERR "$label to Box $hash";
		my \@box = $boxes[$hash];
		my \%box = $box[0];
		if ($cmd eq '-') {
			if (defined(my $ix = $box{$label})) {
				splice @box, $ix, 1;
				delete $box{$label};
				for my $v (values %box) { $v-- if $v > $ix; }
			}
		}
		else {
			my $focal = 0 + substr($cmd, 1);
			if (defined(my $ix = $box{$label})) {
				$box[$ix] = $focal;
			}
			else {
				push @box, $focal;
				$box{$label} = $#box;
			}
		}
	}
}

for my $box (keys @boxes) {
	print STDERR "Box $box : ";
	my @labels;
	for my $l (keys $boxes[$box]->[0]->%*) {
		my $ix = $boxes[$box]->[0]->{$l};
		$labels[$ix] = $l;
	}
	my $any = 0;
	for my $ix (1 .. $#labels) {
		printf STDERR "[ %s %d ]", $labels[$ix], $boxes[$box]->[$ix];
		$any = 1;
	}
	if ($any) {
		print STDERR "\n";
	}
	else {
		print STDERR "\r\e[K";
	}
}

my $sum = 0;

for my $box (keys @boxes) {
	for my $ix (1 .. $boxes[$box]->$#*) {
		my $focus = (1 + $box) * $ix * $boxes[$box]->[$ix];
		$sum += $focus;
	}
}

say $sum;
