#! /usr/bin/perl -w

use strict;
use File::Basename;

sub quit
{
    my $ret = shift;

    print "Press ENTER to continue.\n";
    my $key;
    read(STDIN, $key, 1);
    exit $ret;
}

sub copyPics
{
    my $link = shift;

    my @pics = `ls /home/reid/$link/DCIM/*/*.[jJ][pP][gG]`;
    
    my $res = 0;
    
    foreach my $pic (@pics)
    {
        chomp $pic;
    
        my $i = 0;
        my $target = "";
        do {
            $target = "/home/reid/pictures/" . $i . "-" . basename($pic);
            $i += 1;
            if (-e "$target") { print "Found\n" }
        } while (-e "$target");

        $res = system("cp -v $pic $target");
        if ($res > 0)
        {
            print "ERROR copying $pic to laptop.\n";
            quit(1);
        }
        
        my $sourceMd5 = `md5sum $pic | cut -d ' ' -f 1`;
        chomp $sourceMd5;
        my $targetMd5 = `md5sum $target | cut -d ' ' -f 1`;
        chomp $targetMd5;
    
        if ($sourceMd5 ne $targetMd5)
        {
            print "ERROR: Copied picture does not match picture on memory card, please try again\n";
            print "$pic: $sourceMd5\n";
            print "$target: $targetMd5\n";
            quit(2);
        }
    
        $res = system("rm -f $pic");
        if ($res > 0)
        {
            print "ERROR removing $pic from memory card.\n";
            quit(3);
        }
    }
}

copyPics('sdcard');
#copyPics('camcorderHDD');
#copyPics('camcorderSD');

my $res = system('cd /home/reid/pictures && ./grouppics.pl');
if ($res > 0)
{
    print "ERROR grouping pictures.\n";
    quit(4);
}

print "SUCCESS\n";
quit(0);
