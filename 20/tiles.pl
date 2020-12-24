#!/usr/bin/perl
use v5.30;
use warnings 'all', FATAL => 'uninitialized', 'numeric';
no warnings 'recursion', 'experimental';

use feature qw/refaliasing declared_refs/;

use List::Util ();

my %tiles;

my $tilesize = undef;

my $current = undef;

while (<>) {
	chomp;
	next if ($_ eq "");
	if (my ($id) = /Tile (\d+):/) {
		$current = $id;
		next;
	}
	$tilesize //= length($_);
	push $tiles{$current}->{map}->@*, (split //, $_);
}

my @tiles = keys %tiles;

sub coord {
	my $x = shift;
	my $y = shift;
	return ($y * $tilesize) + $x;
}

# First we need to look at what border options we have.

sub update_borders {
	my $def = shift;
	my @map = $def->{map}->@*;
	$def->{borders} = {
		north => join("", @map[map { coord $_, 0 } 0 .. ($tilesize - 1)]),
		east => join("", @map[map { coord $tilesize - 1, $_ } 0 .. ($tilesize - 1)]),
		south => join("", @map[map { coord $_, $tilesize - 1 } 0 .. ($tilesize - 1)]),
		west => join("", @map[map { coord 0, $_ } 0 .. ($tilesize - 1)]),
	};
}

for my $tile (@tiles) {
	my $def = $tiles{$tile};

	update_borders $def;

	printf "%d [%s] [%s] [%s] [%s] [%s] [%s] [%s] [%s]\n", $tile, map { $_, scalar reverse($_) } $def->{borders}->@{qw/north east south west/};
}

sub dumpmap {
	my @map = @_;

	for my $ix (0 .. $#map) {
		if ($ix > 0 && $ix % $tilesize == 0) { print "\n"; }
		print $map[$ix];
	}
	print "\n---\n";
}

sub transform_tile {
	my $tile = shift;
	my $def = $tiles{$tile};
	my @tmat = @_;
	scalar @tmat == 4 or die;
	# Do not attempt to transform a tile that has been placed.
	exists $def->{x} and die;
	exists $def->{y} and die;
	my @oldmap = $def->{map}->@*;

	#dumpmap @oldmap;
	my @newmap;

	my $dx = 0;
	my $dy = 0;

	for my $x (0 .. ($tilesize - 1)) {
		for my $y (0 .. ($tilesize - 1)) {
			my $xp = ($tmat[0] * $x) + ($tmat[1] * $y) + $dx;
			my $yp = ($tmat[2] * $x) + ($tmat[3] * $y) + $dy;
			if ($xp < 0) { $dx -= $xp }
			if ($yp < 0) { $dy -= $yp }
		}
	}
	for my $x (0 .. ($tilesize - 1)) {
		for my $y (0 .. ($tilesize - 1)) {
			my $xp = ($tmat[0] * $x) + ($tmat[1] * $y) + $dx;
			my $yp = ($tmat[2] * $x) + ($tmat[3] * $y) + $dy;
			$newmap[coord($xp, $yp)] = $oldmap[coord($x, $y)];
		}
	}
	#dumpmap @newmap;

	$def->{map}->@* = @newmap;
	update_borders $def;
}

use constant ROTATE => (0, -1, 1, 0);
use constant VFLIP => (1, 0, 0, -1);
use constant HFLIP => (-1, 0, 0, 1);

my %assembled;

sub border_candidate {
	my $tile = shift;
	my $def = $tiles{$tile};
	my $other = shift;
	my $odef = $tiles{$other};
	my $border = shift;

	if ($def == $odef) { return "" };

	my @try = values $odef->{borders}->%*;

	return scalar(grep { $border eq $_ or $border eq scalar reverse($_) } @try) > 0;
}	

sub try_border {
	my $tile = shift;
	my $def = $tiles{$tile};
	my $border = shift;
	my $needed = shift;
	my $x = shift;
	my $y = shift;
	my @flip = @_;

	my $othertile = $assembled{"$x:$y"};
	if (defined $othertile) {
		my $otherdef = $tiles{$othertile};
		# Tile is already in place, so validate that this tile can be placed
		if ($def->{borders}->{$border} ne $otherdef->{borders}->{$needed}) {
			die "Validation fail for border '$border' neighbor $othertile";
		}
		return 1;
	}
	else {
		# Otherwise try to find a tile that can be placed here.
		my @cand = grep { border_candidate $tile, $_, $def->{borders}->{$border} } keys %tiles;
		if (@cand > 1) { die "Uh oh [@cand]"; }
		if (@cand < 1) { return; } # No candidates
		my ($other) = @cand;
		say "$tile -> $other for $border";
		my $odef = $tiles{$other};
		my $tries = 4;
		#printf "Need [%s], Have [%s]\n", $def->{borders}->{$border}, $odef->{borders}->{$needed};
		until ($def->{borders}->{$border} eq $odef->{borders}->{$needed} || $def->{borders}->{$border} eq scalar reverse $odef->{borders}->{$needed}) {
			transform_tile $other, ROTATE;
			#printf "Need [%s], Have [%s]\n", $def->{borders}->{$border}, $odef->{borders}->{$needed};
			--$tries or die;
		}
		if ($def->{borders}->{$border} eq scalar reverse $odef->{borders}->{$needed}) {
			transform_tile $other, @flip;
		}
		place_tile($other, $x, $y);
	}
}

sub place_tile {
	my $tile = shift;
	my $x = shift;
	my $y = shift;

	my $def = $tiles{$tile};

	exists $def->{x} and die;
	exists $def->{y} and die;

	exists $assembled{"$x:$y"} and die;

	say "Tile $tile placed at $x, $y";

	#dumpmap $def->{map}->@*;

	$def->{x} = $x;
	$def->{y} = $y;
	$assembled{"$x:$y"} = $tile;

	# Now evaluate each border and see if we can place an adjacent tile:
	try_border $tile, "north", "south", $x, $y - 1, HFLIP;
	try_border $tile, "south", "north", $x, $y + 1, HFLIP;
	try_border $tile, "east" , "west" , $x + 1, $y, VFLIP;
	try_border $tile, "west" , "east" , $x - 1, $y, VFLIP;
}

my ($first) = @tiles;

place_tile $first, 0, 0;

my $xlo = List::Util::min map { $_->{x} } values %tiles;
my $xhi = List::Util::max map { $_->{x} } values %tiles;
my $ylo = List::Util::min map { $_->{y} } values %tiles;
my $yhi = List::Util::max map { $_->{y} } values %tiles;

my $prod = $assembled{"$xlo:$ylo"} * $assembled{"$xlo:$yhi"} * $assembled{"$xhi:$ylo"} * $assembled{"$xhi:$yhi"};

say "Cornder ID Product: $prod";

my @fullmap;

for my $ty ($ylo .. $yhi) {
	for my $mapy (1 .. ($tilesize - 2)) {
		my $line = "";
		for my $tx ($xlo .. $xhi) {
			my $tile = $assembled{"$tx:$ty"};
			my $def = $tiles{$tile};
			my @map = $def->{map}->@*;
			my $segment = join "", @map[map { coord $_, $mapy } 1 .. ($tilesize - 2)];
			$line .= $segment;
		}
		push @fullmap, $line;
	}
}

sub transform_map {
	my @tmat = @_;

	my @oldmap = @fullmap;
	
	my $dx = 0;
	my $dy = 0;

	for my $x (0 .. (length($fullmap[0]) - 1)) {
		for my $y (0 .. $#fullmap) {
			my $xp = ($tmat[0] * $x) + ($tmat[1] * $y) + $dx;
			my $yp = ($tmat[2] * $x) + ($tmat[3] * $y) + $dy;
			if ($xp < 0) { $dx -= $xp }
			if ($yp < 0) { $dy -= $yp }
		}
	}
	for my $x (0 .. (length($fullmap[0]) - 1)) {
		for my $y (0 .. $#fullmap) {
			my $xp = ($tmat[0] * $x) + ($tmat[1] * $y) + $dx;
			my $yp = ($tmat[2] * $x) + ($tmat[3] * $y) + $dy;
			substr($fullmap[$yp], $xp, 1) = substr($oldmap[$y], $x, 1);
		}
	}
}



                  # 
#    ##    ##    ###
 #  #  #  #  #  #   

my @pattern = ([18], [0, 5, 6, 11, 12, 17, 18, 19], [1, 4, 7, 10, 13, 16]);

sub check_line_pattern {
	my $line = shift;
	my $startpos = shift;
	while (defined(my $index = shift)) {
		return "" if $startpos + $index >= length($line);
		return "" unless substr($line, $startpos + $index, 1) =~ /[#O]/; # Os mark where we've found a pattern previously.
	}
	return 1; # All positions match, so this line matches.
}

sub mark_line_pattern {
	my \$line = \$_[0];
	shift;
	my $startpos = shift;
	while (defined(my $index = shift)) {
		substr($line, $startpos + $index, 1) = "O";
	}
}

sub search_for_monsters {
	my $found = 0;
	for my $y (0 .. ($#fullmap - (1 + $#pattern))) {
		my \(@lines) = \(@fullmap[$y .. $y + $#pattern]);
		for my $startpos (grep { substr($lines[1], $_, 1) eq '#' } 0 .. (length($lines[1]) - 1)) {
			#say "Checking at $startpos : $y";
			next unless List::Util::all { check_line_pattern $lines[$_], $startpos, $pattern[$_]->@* } keys @pattern;
			mark_line_pattern $lines[$_], $startpos, $pattern[$_]->@* for keys @pattern;
			++$found;
		}
	}
	say "Found $found monsters";
	return $found > 0;
}

my @xfrm_tries = ([ ROTATE ], [ ROTATE ], [ ROTATE ], [ VFLIP ], [ ROTATE ], [ ROTATE ], [ ROTATE ]);

for my $line (@fullmap) {
	say $line;
}

until (search_for_monsters) {
	my $xfrm = shift @xfrm_tries // do { say "No monsters found"; exit 1; };
	transform_map @$xfrm;
	say "---";
	for my $line (@fullmap) {
		say $line;
	}
}

say "====";

for my $line (@fullmap) {
	say $line;
}

my $poundtiles = 0;

for my $line (@fullmap) {
	$poundtiles += () = ($line =~ m/#/g);
}

say "# tiles: $poundtiles";
