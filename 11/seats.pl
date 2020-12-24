#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';
use feature qw/refaliasing declared_refs/;

chomp(my @input = <>);

# . = space, L = open seat, # = used seat, X = seat changing from open to used, Q = seat changing from used to open

my $changed = 0;

sub showmap { for my $line (@input) { say $line; } }

sub find_seat {
	my $row = shift;
	my $col = shift;
	my $dr = shift;
	my $dc = shift;
	if ($dr == 0 && $dc == 0) { return '.' };
	$row += $dr;
	$col += $dc;
	while (1) {
		if ($row < 0 || $row > $#input) { return '.'; }
		my $line = $input[$row];
		if ($col < 0 || $col >= length($line)) { return '.'; }
		my $chr = substr($line, $col, 1);
		if ($chr ne '.') { return $chr; }
		$row += $dr;
		$col += $dc;
	}
}

sub run_step {

	$changed = 0;

	for my $row (0 .. $#input) {
		my $line = $input[$row];
		for my $col (0 .. length($line) - 1) {
			my $adj = 0;
			my $current = substr($line, $col, 1);
			if ($current eq '.') { next; }

			#for my $r ($row - 1, $row, $row + 1) {
			#	if ($r < 0 || $r > $#input) { next; }
			#	my $l = $input[$r];
			#	for my $c ($col - 1, $col, $col + 1) {
			#		if ($r == $row && $c == $col) { next; }
			#		if ($c < 0 || $c >= length $l) { next; }
			#		if (substr($l, $c, 1) =~ m/[#Q]/) { ++$adj; }
			#	}
			#}
			for my $dr (-1, 0, 1) {
				for my $dc (-1, 0, 1) {
					if (find_seat($row, $col, $dr, $dc) =~ m/[#Q]/) { ++$adj; }
				}
			}
			#say "At R$row C$col found $adj";
			if ($current eq 'L' && $adj == 0) {
				substr($line, $col, 1) = 'X';
				$changed = 1;
			}
			elsif ($current eq '#' && $adj >= 5) {
				substr($line, $col, 1) = 'Q';
				$changed = 1;
			}
		}
		$input[$row] = $line;
	}

	#say "~~~";

	#showmap;

	for my $line (@input) { $line =~ tr/XQ/#L/; }
}

my $runcount = 0;

showmap;

do
{
	run_step;
	say "---";
	showmap;
	++$runcount;
	#die "stop" if $runcount > 1;
} while ($changed);

say "Steady state after $runcount cycles";

my $seatCount = 0;

for my $line (@input) {
	$seatCount += () = ($line =~ m/#/g);
}

say "Seats used: $seatCount";
