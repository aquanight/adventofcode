#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized';
no warnings 'experimental';
use feature qw/refaliasing declared_refs/;

use List::Util qw/min max/;

my $input = shift @ARGV; # Directly from command line, rather than input file.

my $moves = shift @ARGV // 10_000_000;

# key: cup -> value: next cup
my %cups;

my $first = undef;
my $last;

my @cups = split //, $input;
my $lowest = min @cups;
my $highest = max @cups;

for my $cup (@cups) {
	if (defined $first) {
		$cups{$last} = $cup;
		$cups{$cup} = $first;
		$last = $cup;
	}
	else {
		$first = $cup;
		$cups{$cup} = $cup;
		$last = $cup;
	}
}

for my $cup (($highest + 1) .. 1_000_000) {
	$cups{$last} = $cup;
	$cups{$cup} = $first;
	$last = $cup;
}

my $current = shift @cups;

sub show_ten_after_one {

	my @first_ten = 1;
	while (scalar @first_ten < 10) {
		my $x = pop @first_ten;
		push @first_ten, $x, $cups{$x};
	}

	printf "[%s]\n", join ",", @first_ten;

}

while ($moves--) {
	print STDERR "\e[1K$moves\r" if ($moves % 100_000 == 0);
	#print "[$current] ";
	#show_ten_after_one;
	my @pick;
	while (scalar(@pick) < 3) {
		my $next = $cups{$current};
		$cups{$current} = $cups{$next};
		$cups{$next} = undef;
		push @pick, $next;
	}
	
	my $dest = $current - 1;
	until (defined $cups{$dest}) {
		--$dest;
		if ($dest < $lowest) { $dest = 1_000_000; }
	}
	
	#insert the picked items after this point
	my $after = $cups{$dest};
	$cups{$dest} = $pick[0];
	$cups{$pick[0]} = $pick[1];
	$cups{$pick[1]} = $pick[2];
	$cups{$pick[2]} = $after;

	$current = $cups{$current};
}

show_ten_after_one;

my $x = $cups{1};
my $y = $cups{$x};

my $prod = $x * $y;

say "Product: $prod";
