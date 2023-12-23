#!/usr/bin/perl

use v5.36;
use warnings FATAL => 'all';
use experimental qw/signatures refaliasing declared_refs/;

use constant true => !0;
use constant false => !1;

use Carp ();
use List::Util ();

my @bricks;

my $id = "A";

while (<>) {
	chomp;
	my ($p1, $p2) = split /~/;
	my ($x1, $y1, $z1) = split /,/, $p1;
	my ($x2, $y2, $z2) = split /,/, $p2;
	(($x1 == $x2) + ($y1 == $y2) + ($z1 == $z2)) >= 2 or die "Input error ($_)";
	my $brick;
	if ($x1 != $x2) {
		$brick = {
			x => ($x1 < $x2 ? $x1 : $x2),
			y => $y1,
			z => $z1,
			type => 'x',
			len => 1 + abs($x1 - $x2)
		};
	}
	elsif ($y1 != $y2) {
		$brick = {
			x => $x1,
			y => ($y1 < $y2 ? $y1 : $y2),
			z => $z1,
			type => 'y',
			len => 1 + abs($y1 - $y2)
		};
	}
	elsif ($z1 != $z2) {
		$brick = {
			x => $x1,
			y => $y1,
			z => ($z1 < $z2 ? $z1 : $z2),
			type => 'z',
			len => 1 + abs($z1 - $z2)
		};
	}
	else {
		$brick = {
			x => $x1,
			y => $y1,
			z => $z1,
			type => 'z',
			len => 1
		};
	}
	$brick->{id} = $id++;
	$brick->{supports} = [];
	$brick->{supported_by} = [];
	printf STDERR "Parsed brick: id=%s, x=%d, y=%d, z=%d, type=%s, len=%d\n", $brick->@{qw/id x y z type len/} ;
	push @bricks, $brick;
}

# Returns true if brick1 is supporting brick2
sub supports ($b1, $b2) {
	my $required_z;
	if ($b1->{type} eq 'z') {
		$required_z = $b1->{z} + $b1->{len};
	}
	else {
		$required_z = $b1->{z} + 1;
	}
	if ($b2->{z} != $required_z) {
		return 0;
	}
	my $x1 = $b1->{x};
	my $x2 = $b2->{x};
	my $y1 = $b1->{y};
	my $y2 = $b2->{y};
	
	my $x1s = ($b1->{type} eq 'x' ? $b1->{len} : 1);
	my $x2s = ($b2->{type} eq 'x' ? $b2->{len} : 1);
	my $y1s = ($b1->{type} eq 'y' ? $b1->{len} : 1);
	my $y2s = ($b2->{type} eq 'y' ? $b2->{len} : 1);

	if ($x1 < $x2) {
		return false unless ($x2 - $x1) < $x1s;
	}
	if ($x2 < $x1) {
		return false unless ($x1 - $x2) < $x2s;
	}
	if ($y1 < $y2) {
		return false unless ($y2 - $y1) < $y1s;
	}
	if ($y2 < $y1) {
		return false unless ($y1 - $y2) < $y2s;
	}
	return true;
}

# Creates a mapping of which bricks are holding up which others.
BRICK: for my $b1 (@bricks) {
	for my $b2 (@bricks) {
		next if $b1 == $b2;
		if (supports($b2, $b1)) {
			push $b2->{supports}->@*, $b1;
			push $b1->{supported_by}->@*, $b2;
		}
	}
}

sub brick_fall ($brick) {
	return if $brick->{supported_by}->@*;
	return if $brick->{z} < 2;
	while ($brick->{supports}->@*) {
		my $b2 = shift $brick->{supports}->@*;
		$b2->{supported_by}->@* = grep { $_ != $brick } $b2->{supported_by}->@*;
	}
	$brick->{z}--;
	for my $b (@bricks) {
		next if $brick == $b;
		if (supports($b, $brick)) {
			push $brick->{supported_by}->@*, $b;
			push $b->{supports}->@*, $brick;
		}
	}
}

say STDERR "Dropping bricks";
while (defined(my $brick = List::Util::first { $_->{supported_by}->@* == 0 && $_->{z} > 1 } @bricks)) {
	printf STDERR "Brick %s falling\n", $brick->{id};
	until ($brick->{supported_by}->@* || $brick->{z} < 2) {
		brick_fall($brick);
	}
}

say STDERR "Initial supporting map:";
for my $brick (@bricks) {
	my @y = $brick->{supported_by}->@*;
	if (@y) {
		printf STDERR "Brick [%s] held up by: %s\n", $brick->{id}, join(", ", map { $_->{id} } @y);
	}
	else {
		if ($brick->{z} == 1) {
			printf STDERR "Brick [%s] is on the ground\n", $brick->{id};
		}
		else {
			die "Shouldn't happen now";
		}
	}
}

sub fall_ct ($brick) {
	# Determines how many bricks will fall if $brick were deleted, or if it were to fall as well.
	exists $brick->{fall_count} and return $brick->{fall_count}; # Has already been calculated for this brick.
	# Avoid being recursive:
	my @pending = ($brick);
	my $result;
	while (@pending) {
		my $b = $pending[-1];
		my @supp = $b->{supports}; # What bricks does this one hold up.
		# If any supported brick has another support, it won't fall, so remove it from the list.
		@supp = grep { $_->{supported_by}->@* == 1 } @supp;
		
	}
}

sub fall_count ($brick) {
	# If this brick is zapped, find out how many other bricks will fall.
	my %falling;
	$falling{$brick->{id}} = 1;
	my @supp = $brick->{supports}->@*;
	while (@supp) {
		my $supp = shift @supp;
		if (List::Util::any { !$falling{$_->{id}} } $supp->{supported_by}->@*) {
			# Supported by a brick that isn't falling, so this one doesn't fall.
			next;
		}
		$falling{$supp->{id}} = 1;
		push @supp, $supp->{supports}->@*;
	}
	return (scalar keys %falling) - 1;
}

# Now go through all the bricks and find their fall count - which is how many OTHER bricks would fall if that brick were to be deleted or if it were to fall.
my $sum = 0;
for my $brick (@bricks) {
	my $ct = fall_count($brick);
	printf "Brick [%s] will drop %d others\n", $brick->{id}, $ct;
	$sum += $ct;
}
say $sum;

__END__
my $ct = 0;
BRICK: for my $brick (@bricks) {
	for my $b2 ($brick->{supports}->@*) {
		if ($b2->{supported_by}->@* < 2) {
			#printf STDERR "Brick [%s] not safe to zap (only brick holding up [%s])\n", $brick->{id}, $b2->{id};
			next BRICK;
		}
	}
	printf STDERR "Brick [%s] is safe to zap", $brick->{id};
	if ($brick->{supports}->@* == 0) {
		say STDERR " - topmost brick";
	}
	else {
		printf STDERR " despite holding: %s\n", join(", ", (map { $_->{id} } $brick->{supports}->@*));
	}
	++$ct;
}

say $ct;
