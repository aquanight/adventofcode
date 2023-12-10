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

my @grid;
$grid[$sty][$stx] = "|-F7JL";

my @paths;

{
	my \$scmd = \$grid[$sty][$stx];
	# Create starting states.
	if ($sty > 0 && substr($map[$sty - 1], $stx, 1) =~ /[\|F7]/) {
		# North end connected
		$scmd =~ s/[\-F7]//g;
		push @paths, [ $stx, $sty - 1 ];
	}
	if ($sty < $#map && substr($map[$sty + 1], $stx, 1) =~ /[\|JL]/) {
		# South end connected
		$scmd =~ s/[\-JL]//g;
		push @paths, [ $stx, $sty + 1 ];
	}
	if ($stx > 0 && substr($map[$sty], $stx - 1, 1) =~ /[\-FL]/) {
		# West end connected
		$scmd =~ s/[\|FL]//g;
		push @paths, [ $stx - 1, $sty ];
	}
	if ($stx < (length($map[$sty]) - 1) && substr($map[$sty], $stx + 1, 1) =~ /[\-J7]/) {
		# East end connected
		$scmd =~ s/[\|J7]//g;
		push @paths, [ $stx + 1, $sty ];
	}
	die "Ugh" unless length($scmd) == 1;
}

my $step = 0;
while (1) {
	++$step;
	my @next;
	for my $path (@paths) {
		my ($px, $py) = @$path;
		next if defined $grid[$py][$px];
		die "Fell off" if ($py < 0 || $py > $#map);
		die "Fell off" if ($px < 0 || $px >= length($map[$py]));
		my $cmd = substr($map[$py], $px, 1);
		$grid[$py][$px] = $cmd;
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

for my $y ( 0 .. $#map ) {
	for my $x ( 0 .. (length($map[$y]) - 1)) {
		my \$pt = \$grid[$y][$x];
		next if defined $pt;
		$pt = ".";
		next unless $x > 0;
		my $ctup = 0;
		my $ctdn = 0;
		for my $rx ( 0 .. ($x - 1) ) {
			my $cmd = $grid[$y][$rx];
			my $cmdup = ".";
			my $cmddn = ".";
			if ($y > 0) { $cmdup = $grid[$y - 1][$rx]; }
			if ($y < $#map) { $cmddn = $grid[$y + 1][$rx]; }
			if ($cmd =~ /[\|JL]/ && $cmdup =~ /[\|F7]/) {
				++$ctup;
			}
			if ($cmd =~ /[\|F7]/ && $cmddn =~ /[\|JL]/) {
				++$ctdn;
			}
		}
		die "Something's wrong" unless $ctup == 0 || $ctdn == 0 || (($ctup ^ $ctdn) & 1) == 0;
		next unless ($ctup|$ctdn) & 1;
		$pt = "x";
	}
	$_ //= '.' for $grid[$y]->@[0 .. (length($map[$y]) - 1)];
}

print STDERR join "\n", (map { join "", @$_ } @grid), "";

my $ct = (() = (join("\n" => map { join "", @$_ } @grid) =~ /x/g));

say $ct;
