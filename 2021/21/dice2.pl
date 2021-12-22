#!/usr/bin/perl

use v5.32;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use integer;

my ($p1pos) = (<> =~ m/^Player 1 starting position: (\d+)$/);
my ($p2pos) = (<> =~ m/^Player 2 starting position: (\d+)$/);

defined($p1pos) && defined($p2pos) or die "Invalid input";

my %d = ();

for my $x ( 1 .. 3 ) {
	for my $y ( 1 .. 3 ) {
		for my $z ( 1 .. 3 ) {
			my $r = $x + $y + $z;
			$d{$r}++;
		}
	}
}

my $p1wins = 0;
my $p2wins = 0;

# The hash keys a given score:position state with the number of occurences of it.
my %state = ("$p1pos:0:$p2pos:0" => 1);

my $turncount = 0;

while (keys %state) {
	my $is_p2 = !1;
	my %result = ();
	for my $state (keys %state) {
		my ($p1p, $p1s, $p2p, $p2s) = split /:/, $state;
		my \$pos = $is_p2 ? \$p2p : \$p1p;
		my \$score = $is_p2 ? \$p2s : \$p1s;
		my \$win = $is_p2 ? \$p2wins : \$p1wins;
		my $ct = $state{$state};
		for my $p1r (keys %d) {
			my $p1rct = $d{$p1r};
			my $p1newpos = ((($p1p - 1) + $p1r) % 10) + 1;
			my $p1newscr = $p1s + $p1newpos;
			# If this is a winning result, add it to P1 wins and move on.
			if ($p1newscr >= 21) {
				$p1wins += ($p1rct * $ct);
				next;
			}
			for my $p2r (keys %d) {
				my $p2rct = $p1rct * $d{$p2r};
				my $p2newpos = ((($p2p - 1) + $p2r) % 10) + 1;
				my $p2newscr = $p2s + $p2newpos;
				if ($p2newscr >= 21) {
					$p2wins += ($p2rct * $ct);
					next;
				}
				# Otherwise add the incomplete state to the next cycle.
				my $newkey = "$p1newpos:$p1newscr:$p2newpos:$p2newscr";
				$result{$newkey} += $p2rct * $ct;
			}
		}
	}
	%state = %result;
}

say STDERR "Finished after $turncount turns";
say STDERR "Player 1 win count: $p1wins";
say STDERR "Player 2 win count: $p2wins";


