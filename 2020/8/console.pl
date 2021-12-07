#!/usr/bin/perl
use v5.30;
use warnings;

my @ops;

our $acc;
our $pc;

our @jmps;
our @nops;
our $save = 1;

sub op_acc { $acc += shift; ++$pc; }

sub op_jmp { push @jmps, $pc if $save; $pc += shift; }

sub op_nop { push @nops, $pc if $save; ++$pc; }

while (<>) {
	chomp;
	my ($inst, $arg) = /^(\w+) ([+-]\d+)$/;
	my $op = main->can("op_$inst")//die "undefined opcode: $_";
	push @ops, [ $op, $arg, 0 ];
}

# Return value:
# PC-of-loop, ACC
# PC-of-loop is undef if we don't loop.
sub execute {
	local $acc = 0;
	local $pc = 0;
	for (@ops) { $_->[2] = 0; }
	# Now to run
	while (1) {
		my $op = $ops[$pc]//return (undef, $acc);
		$op->[2] and return ($pc, $acc);;
		$op->[2] = 1;
		$op->[0]->($op->[1]);
	}

}

($pc, $acc) = execute;

if (defined($pc)) {
	say "Loop encountered at PC $pc";
}
else {
	say "Terminated normally";
}
say "ACC: $acc";

$save = 0;

for my $jmp (@jmps) {
	say "Trying jmp at $jmp";
	local $ops[$jmp]->[0] = \&op_nop;
	($pc, $acc) = execute;
	next if defined $pc;
	say "Fixed jump at $jmp";
	say "ACC: $acc";
	last;
}
