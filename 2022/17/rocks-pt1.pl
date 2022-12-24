#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

use List::Util ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

chomp(my $jet = <>);

my %dx = ('>' => 1, '<' => -1);

my @jets = @dx{split //, $jet};

my $grid = "";

use constant LIMIT => 0b0_1111111;

use constant LEFT_STOP  => 0b0_1000000;
use constant RIGHT_STOP => 0b0_0000001;

sub mkstr { join "", map { chr } @_; }

# patterns are initialized for starting position
my @patterns = (
	mkstr(0b0_0011110), # Horizontal line
	mkstr(0b0_0001000, 0b0_0011100, 0b0_0001000), # plus
	mkstr(0b0_0011100, 0b0_0000100, 0b0_0000100), # backward L
	mkstr(0b0_0010000, 0b0_0010000, 0b0_0010000, 0b0_0010000), # vertical line
	mkstr(0b0_0011000, 0b0_0011000), # box
);

# Specialized string shifts for our use case. We assume no bit will spill out of bounds, and will return undef if it could happen.
sub str_sh_lf ($str) {
	my $new = "\0" x length($str);
	for (my $ix = 0; $ix < length($str); ++$ix) {
		my $ch = ord(substr($str, $ix, 1));
		if ($ch & LEFT_STOP) { return undef; }
		$ch <<= 1;
		substr($new, $ix, 1, chr($ch));
	}
	return $new;
}

sub str_sh_rt ($str) {
	my $new = "\0" x length($str);
	for (my $ix = 0; $ix < length($str); ++$ix) {
		my $ch = ord(substr($str, $ix, 1));
		if ($ch & RIGHT_STOP) { return undef; }
		$ch >>= 1;
		substr($new, $ix, 1, chr($ch));
	}
	return $new;
}

assert(str_sh_lf("\x04\x07") eq "\x08\x0E");
assert(str_sh_rt("\x08\x0E") eq "\x04\x07");

use constant ROCK_COUNT => 2022;

my $rocks = 0;

sub dumpfield ($str, $pfx = "") {
	for my $ix (1 .. length($str)) {
		my $chr = substr($str, length($str) - $ix, 1);
		my $row = sprintf "%07b", ord($chr);
		$row =~ s/0/./g;
		$row =~ s/1/#/g;
		say STDERR "$pfx|$row|";
	}
	say STDERR "";
}

while ($rocks < ROCK_COUNT) {
	my $rock = $patterns[$rocks++ % scalar(@patterns)];

	$rock = ("\0" x (3 + length($grid))) . $rock;

	MOVE: while (1) {
		if ($rocks < 3) {
			dumpfield($grid |. $rock, "> ");
		}
		my $dx = shift @jets;
		push @jets, $dx;
		my $shifted;
		if ($dx < 0) {
			$shifted = str_sh_lf $rock;
		}
		else {
			$shifted = str_sh_rt $rock;
		}
		if (defined($shifted) && ($shifted &. $grid) =~ m/\A\0*\z/) {
			$rock = $shifted;
		}
		# now can we move down?
		if ($rock =~ m/\A[^\0]/) {
			$grid = $grid |. $rock;
			last MOVE;
		}
		my $down = substr($rock, 1);
		if (($down &. $grid) =~ m/\A\0*\z/) {
			$rock = $down;
		}
		else {
			$grid = $grid |. $rock;
			last MOVE;
		}
	}

	if ($rocks < 11) {
		dumpfield $grid;
	}
}

$grid =~ s/\0*\z//;

my $score = length $grid;

say $score;
