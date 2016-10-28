#! /usr/bin/perl -w

use strict;

my $dir = ".";

my %months = (
    '00' => 'Smarch',
    '01' => 'January',
    '02' => 'February',
    '03' => 'March',
    '04' => 'April',
    '05' => 'May',
    '06' => 'June',
    '07' => 'July',
    '08' => 'August',
    '09' => 'September',
    '10' => 'October',
    '11' => 'November',
    '12' => 'December',
);

my @pics = `ls --quoting-style=c $dir/*.[jJ][pP][gG]`;

foreach my $pic (@pics)
{
    chomp $pic;

    my @exif = `exif $pic`;
    foreach my $line (@exif)
    {
        chomp $line;

        if ($line =~ /^Date and Time \(Ori.*\|(\d\d\d\d):(\d\d):(\d\d)\s(\d\d):(\d\d):(\d\d).*$/)
        {
            my $picDir = "$dir/$1/$2-$months{$2}";
            system("mkdir -p $picDir");

            my $picPrefix = "$1.$2.$3-$4.$5.$6";

            my $i = 0;
            my $newPic = "";
            do {
                $newPic = "$picPrefix-$i.jpg";
                $i += 1;
            } while (-f "$picDir/$newPic");

            print "mv $pic $picDir/$newPic\n";
            system("mv $pic $picDir/$newPic");
        }
    }
}
