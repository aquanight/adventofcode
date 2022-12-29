#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();
use List::Util ();

my sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %elves;

sub key ($x, $y) { "$x,$y" }
sub coord ($key) { my ($x, $y) = $key =~ m/^(-?\d+),(-?\d+)$/ or Carp::confess "WTF"; return ($x, $y); }

while (<>) {
	chomp;
	/^[.#]+/ or die "Input error.";
	my $y = $. - 1;
	while (/#/g) {
		my $x = $-[0];
		$elves{key($x, $y)} = 1;
	}
}

sub should_move($x, $y) {
	assert defined($x);
	assert defined($y);
	return List::Util::any { $_ } @elves{key($x - 1, $y - 1), key($x - 1, $y), key($x - 1, $y + 1), key($x, $y - 1), key($x, $y + 1), key($x + 1, $y - 1), key($x + 1, $y), key($x + 1, $y + 1)};
}

sub try_south ($x, $y) {
	for (-1 .. 1) {
		if ($elves{key($x + $_, $y + 1)}) { return undef; }
	}
	return key($x, $y + 1);
}

sub try_west ($x, $y) {
	for (-1 .. 1) {
		if ($elves{key($x - 1, $y + $_)}) { return undef; }
	}
	return key($x - 1, $y);
}

sub try_north ($x, $y) {
	for (-1 .. 1) {
		if ($elves{key($x + $_, $y - 1)}) { return undef; }
	}
	return key($x, $y - 1);
}

sub try_east ($x, $y) {
	for (-1 .. 1) {
		if ($elves{key($x + 1, $y + $_)}) { return undef; }
	}
	return key($x + 1, $y);
}

use constant TURNS => 10;

my @order = (\&try_north, \&try_south, \&try_west, \&try_east);

my $turn = 0;

while ($turn++ < TURNS) {
	my @elves = keys %elves;
	my %step;
	my %trymove;
	for my $elf (@elves) {
		my ($x, $y) = coord($elf);
		if (should_move($x, $y)) {
			my $move = List::Util::first { defined } map {$_->($x, $y) } @order;
			if (defined($move)) {
				push $trymove{$move}->@*, $elf;
				next;
			}
			say STDERR "[T$turn] Elf at $elf is surrounded?";
		}
		$step{$elf} = 1;
	}
	for my $try (keys %trymove) {
		my @prop = $trymove{$try}->@*;
		if (@prop == 1) {
			$step{$try} = 1;
		}
		else {
			$_ = 1 for @step{@prop};
		}
	}
	assert (scalar(@elves) == scalar(keys %step));
	%elves = %step;
	push @order, shift(@order);
}

my @elfcoord = map { [ coord($_) ] } keys %elves;

my $min_x = List::Util::min map { $_->[0] } @elfcoord;
my $max_x = List::Util::max map { $_->[0] } @elfcoord;
my $min_y = List::Util::min map { $_->[1] } @elfcoord;
my $max_y = List::Util::max map { $_->[1] } @elfcoord;

say STDERR "Bounding box is x = $min_x .. $max_x, y = $min_y .. $max_y";

my $area = (1 + ($max_x - $min_x)) * (1 + ($max_y - $min_y));

my $score = $area - scalar(@elfcoord);

say $score;
