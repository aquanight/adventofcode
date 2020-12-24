#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';

use Carp ();

# Keys are in X:Y:Z format
# Value is 0 = inactive unchanged, 1 = active unchanged, 2 = inactive changing to active, 3 = active changing to inactive
my %state;

sub is_active {
	my ($x, $y, $z, $w) = @_;
	return ($state{"$x:$y:$z:$w"}//0) & 0x01;
}

sub count_active_neighbors {
	my ($x, $y, $z, $w) = @_;
	Carp::confess "Something's wrong" unless defined $x && defined $y && defined $z && defined $w;
	my $ct = 0;
	for my $dx (-1, 0, 1) {
		for my $dy (-1, 0, 1) {
			for my $dz (-1, 0, 1) {
				for my $dw (-1, 0, 1) {
					if ($dx == 0 && $dy == 0 && $dz == 0 && $dw == 0) { next; }
					++$ct if is_active $x + $dx, $y + $dy, $z + $dz, $w + $dw;
				}
			}
		}
	}
	return $ct;
}

sub autovivify {
	my ($x, $y, $z, $w) = @_;
	$state{"$x:$y:$z:$w"} //= 0;
}

sub make_active {
	my ($x, $y, $z, $w) = @_;
	for my $dx (-1, 0, 1) {
		for my $dy (-1, 0, 1) {
			for my $dz (-1, 0, 1) {
				for my $dw (-1, 0, 1) {
					autovivify $x + $dx, $y + $dy, $z + $dz, $w + $dw;
				}
			}
		}
	}
	if ($state{"$x:$y:$z:$w"} == 1) { return; }
	$state{"$x:$y:$z:$w"} = 2;
}

sub make_inactive {
	my ($x, $y, $z, $w) = @_;
	for my $dx (-1, 0, 1) {
		for my $dy (-1, 0, 1) {
			for my $dz (-1, 0, 1) {
				for my $dw (-1, 0, 1) {
					autovivify $x + $dx, $y + $dy, $z + $dz, $w + $dw;
				}
			}
		}
	}
	if ($state{"$x:$y:$z:$w"} == 0) { return; }
	$state{"$x:$y:$z:$w"} = 3;
}

sub update_range {
	my $value = shift;
	unless (defined $_[0] && $_[0] < $value) {
		$_[0] = $value;
	}
	unless (defined $_[1] && $_[1] > $value) {
		$_[1] = $value;
	}
}

sub active_range {
	my ($xlo, $xhi, $ylo, $yhi, $zlo, $zhi, $wlo, $whi);
	for my $cell (keys %state) {
		next unless $state{$cell};
		my ($x, $y, $z, $w) = split /:/, $cell;
		update_range $x, $xlo, $xhi;
		update_range $y, $ylo, $yhi;
		update_range $z, $zlo, $zhi;
		update_range $w, $wlo, $whi;
	}
	return ($xlo, $xhi, $ylo, $yhi, $zlo, $zhi, $wlo, $whi);
}

sub step {
	for my $pos (keys %state) {
		my ($x, $y, $z, $w) = split /:/, $pos;
		my $ct = count_active_neighbors $x, $y, $z, $w;
		if (is_active $x, $y, $z, $w) {
			unless ($ct == 2 || $ct == 3) {
				make_inactive $x, $y, $z, $w;
			}
		}
		else {
			if ($ct == 3) {
				make_active $x, $y, $z, $w;
			}
		}
	}

	for (values %state) {
		if ($_ == 2) { $_ = 1; }
		if ($_ == 3) { $_ = 0; }
	}
}

sub printout {
	my ($xlo, $xhi, $ylo, $yhi, $zlo, $zhi, $wlo, $whi) = active_range;

	use Data::Dumper ();

	#print Data::Dumper->Dump([\%state]);

	for my $z ($zlo .. $zhi) {
		for my $w ($wlo .. $whi) {
			say "z=$z, w=$w";
			for my $y ($ylo .. $yhi) {
				for my $x ($xlo .. $xhi) {
					print (is_active($x, $y, $z, $w) ? '#' : '.');
				}
				print "\n";
			}
		}
	}
}

my $count = shift @ARGV;

my $yin = 0;

say "Initial state:";

while (<>) {
	chomp;
	say "$_";
	my @items = split //, $_;
	for my $xin (keys @items) {
		if ($items[$xin] eq '#') {
			make_active $xin, $yin, 0, 0;
		}
		else {
			make_inactive $xin, $yin, 0, 0;
		}
	}
	++$yin;
}
for (values %state) {
	if ($_ == 2) { $_ = 1; }
	if ($_ == 3) { $_ = 0; }
}

printout;

while ($count > 0) {
	step;
	say "---";
	printout;
	--$count;
}

printf "# active cells: %d\n", scalar grep { $_ == 1 } values %state;
