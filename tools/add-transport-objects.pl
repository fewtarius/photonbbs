#!/usr/bin/perl
# add-transport-objects.pl - Add Boat and Horse objects to PhotonMUD objects.dat
# Run this script once to add transportation objects.

use strict;
use warnings;

# Find config
my $home = "/opt/photonbbs";
$home = "." unless -d "$home/data";

my $objects_file = "$home/data/photonmud/objects.dat";
die "Cannot find objects.dat at $objects_file\n" unless -e $objects_file;

# Determine record length
my $fsize = -s $objects_file;
my $reclen;
for my $rl (260, 270, 256, 264, 280) {
    if ($fsize % $rl == 0) {
        $reclen = $rl;
        last;
    }
}
$reclen //= 270;  # fallback

my $num_records = $fsize / $reclen;
print "objects.dat: $fsize bytes, record length $reclen, $num_records records\n";

# Check if Boat and Horse already exist
open(my $fh, "<:raw", $objects_file) or die "Cannot read $objects_file: $!";
my @existing_names;
for my $n (1..$num_records) {
    read($fh, my $buf, $reclen);
    my $name = substr($buf, 0, 30);
    $name =~ s/[\0 ]+$//;
    push @existing_names, $name;
}
close($fh);

my %existing = map { lc($_) => 1 } @existing_names;
print "Existing objects: " . scalar(@existing_names) . "\n";

# Build a template record filled with zeros
sub make_object_record {
    my (%f) = @_;
    my $buf = "\0" x $reclen;

    # Pack fields at their offsets
    # name (30), shortname (30), roomlink f (4), invisible s (2), jailtrap s (2),
    # doorlock s (2), destination s (2), permanent s (2), hidden s (2), closed s (2),
    # keyed s (2), relocks s (2), longdesc (80), [6 x s<2 time fields], lightroom s(2),
    # lighttime s(2), shortdesc (80), ... teleport f(4), trap s(2)
    my $name = $f{name} // "Unknown";
    my $short = $f{shortname} // uc(substr($name,0,10));
    my $ldesc = $f{longdesc} // "An object sits here.";
    my $sdesc = $f{shortdesc} // "A $name is here.";

    substr($buf, 0, 30) = sprintf("%-30s", $name);
    substr($buf, 30, 30) = sprintf("%-30s", $short);
    substr($buf, 82, 80) = sprintf("%-80s", substr($ldesc,0,80));
    substr($buf, 174, 80) = sprintf("%-80s", substr($sdesc,0,80));
    # permanent = 1 if specified
    my $permanent = $f{permanent} // 0;
    substr($buf, 72, 2) = pack("s<", $permanent);

    return $buf;
}

my @to_add;

unless ($existing{lc("Boat")}) {
    push @to_add, make_object_record(
        name      => "Boat",
        shortname => "BOAT",
        longdesc  => "A sturdy wooden rowboat sits here, ready for use on the water.",
        shortdesc => "A boat is moored here.",
        permanent => 1,
    );
    print "Adding: Boat\n";
} else {
    print "Already exists: Boat\n";
}

unless ($existing{lc("Horse")}) {
    push @to_add, make_object_record(
        name      => "Horse",
        shortname => "HORSE",
        longdesc  => "A strong horse stands here, saddled and ready to ride.",
        shortdesc => "A horse is stabled here.",
        permanent => 1,
    );
    print "Adding: Horse\n";
} else {
    print "Already exists: Horse\n";
}

if (@to_add) {
    # Backup first
    my $backup = $objects_file . ".bak." . time();
    system("cp", $objects_file, $backup);
    print "Backup: $backup\n";

    open(my $out, ">>:raw", $objects_file) or die "Cannot write $objects_file: $!";
    for my $rec (@to_add) {
        print $out $rec;
    }
    close($out);

    my $new_size = -s $objects_file;
    my $new_count = $new_size / $reclen;
    print "Done. New size: $new_size bytes, $new_count records\n";
} else {
    print "Nothing to add.\n";
}
