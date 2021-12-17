#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use integer;

use List::Util ();

chomp(my $input = <>);

$input = pack("b*", unpack("B*", pack("H*", $input))); # Puts the bits into vec() order

say "Input length: " . (8 * length($input));

say "Input: " . unpack("b*", $input);

my $nextpos = 0;

sub read_bits ($n) {
	my $v = 0;
	$nextpos < 8*length($input) or die "ASSERT FAILED: BUFFER OVERRUN (Attempt to read bit $nextpos)";
	print STDERR "{$nextpos}Reading $n bits ... ";
	while ($n--) {
		$v = ($v << 1) | vec($input, $nextpos++, 1);
	}
	say STDERR "and received value $v";
	return $v;
}

my $versum = 0;

sub read_operator;

# @stack indicates the current operator depth.
# Each value is either a positive number indicating the number of packets that should be read, or the 1s-compliment of the bit position at which reading should stop.
my @stack = (1);

my @ops = (
	\&List::Util::sum0,	#0
	\&List::Util::product,	#1
	\&List::Util::min,	#2
	\&List::Util::max, 	#3
	undef,			#4
	sub ($x, $y) { 0 + ($x > $y); }, #5
	sub ($x, $y) { 0 + ($x < $y); }, #6
	sub ($x, $y) { 0 + ($x == $y);}, #7
);

my @opstack = ();

sub close_op {
	pop @stack;
	my @args;
	my $op = pop @opstack;
	while (defined $op && !(ref $op)) {
		unshift @args, $op;
		$op = pop @opstack;
	}
	say "Args: [ @args ]";
	if (ref $op) {
		my $r = $op->(@args);
		push @opstack, $r;
	}
	elsif (@args == 1) {
		push @opstack, @args;
	}
	else {
		die "Operator, operator, who's got the operator?!" ;
	}
}

while (@stack) {
	say STDERR "Stack: [ @stack ]";
	say STDERR "Op stack: [ @opstack ]";
	if ($stack[-1] > 0) {
		$stack[-1]--;
	}
	elsif ($stack[-1] == 0) {
		close_op;
		next;
	}
	elsif ($stack[-1] < 0 && $nextpos >= ~$stack[-1]) {
		close_op;
		next;
	}
	my $ver = read_bits 3;
	say STDERR "Packet version: $ver";
	$versum += $ver;
	my $type = read_bits 3;
	print STDERR "Packet type: $type";
	if ($type == 4) {
		my $val = 0;
		say STDERR " (literal)";
		my $segment;
		do {
			use integer;
			$segment = read_bits 5;
			$val = ($val << 4) | ($segment & 0b01111);
		} while ($segment & 0b10000);
		say STDERR "Literal value: $val";
		push @opstack, $val;
	}
	else {
		say STDERR " (operator)";
		my $lentype = read_bits 1;
		if ($lentype) {
			my $count = read_bits 11;
			say "Operator packet has $count subpackets";
			push @stack, $count;
		}
		else {
			my $len = read_bits(15);
			my $stop = $nextpos + $len;
			if ($stop >= 8*length($input)) {
				die "ASSERT FAIL: STOP BIT at $stop PAST END OF BUFFER";
			}
			say "Operator packet has $len bits of subpackets";
			push @stack, ~$stop;
		}
		push @opstack, $ops[$type];
	}
}

say "Sum of versions: $versum";

my $result = pop @opstack;

say "Result: $result";
