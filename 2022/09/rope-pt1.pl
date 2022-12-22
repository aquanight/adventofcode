#!/usr/bin/perl

use v5.34;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use Carp ();

sub assert { shift or Carp::confess "ASSERT FAIL"; }

my %visit = ("0,0" => 1);

my $h_xpos = 0;
my $h_ypos = 0;
my $t_xpos = 0;
my $t_ypos = 0;

sub tail_good {
	# Tail should never get more than 1 move away from the head
	assert abs($h_xpos - $t_xpos) <= 2 && abs($h_ypos - $t_ypos) <= 2;
	return abs($h_xpos - $t_xpos) <= 1 && abs($h_ypos - $t_ypos) <= 1;
}

sub adjust_tail {
	# Since this MUST be called after every HEAD movement, we should never have to move the tail more than once.
	if (tail_good) { return; }
	my $dx;
	my $dy;
	# Move the tail toward the head on each axes where it needs to.
	$dx = $h_xpos <=> $t_xpos;
	$dy = $h_ypos <=> $t_ypos;
	$t_xpos += $dx;
	$t_ypos += $dy;
	if ($dx != 0 || $dy != 0) {
		say STDERR "Tail: ($t_xpos, $t_ypos)";
	}
	$visit{sprintf("%s,%s",$t_xpos,$t_ypos)} = 1;
	assert tail_good;
}

sub move_R { $h_xpos += 1; say STDERR "Head: ($h_xpos, $h_ypos)"; adjust_tail; }
sub move_L { $h_xpos -= 1; say STDERR "Head: ($h_xpos, $h_ypos)"; adjust_tail; }
sub move_U { $h_ypos += 1; say STDERR "Head: ($h_xpos, $h_ypos)"; adjust_tail; }
sub move_D { $h_ypos -= 1; say STDERR "Head: ($h_xpos, $h_ypos)"; adjust_tail; }

my $score = 0;

while (<>) {
	chomp;
	my ($cmd, $ct);
	($cmd, $ct) = /^([ULDR]) (\d+)$/ or die "Input problem: [$_]";
	my $proc = main->can("move_$cmd")//die "Unknown direction [$_]";
	while ($ct-- > 0) {
		$proc->();
	}
}

for (sort keys %visit) {
	say STDERR "Visited: $_";
}

$score = keys %visit;

say $score;
