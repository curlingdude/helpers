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

sub renameVid
{
	my $dir = shift;
	my $vid = shift;

	my $vidDir = '';
	my $newVid = '';

	my @stat = `stat -c %y $vid`;
    foreach my $line (@stat)
    {
        chomp $line;

        if ($line =~ /^(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d).*$/)
        {
            $vidDir = "$dir/$1";
            system("mkdir -p $vidDir");

	    	my $vidName = "$1.$2.$3-$4.$5.$6.m2ts";

            my $i = 1;
	    	$newVid = $vidName;
            while (-f "$vidDir/$newVid")
            {
                $newVid = $vidName;
                $newVid =~ s/^(.*)\.m2ts$/$1-$i.m2ts/g;
                $i += 1;
            }
        }
    }
	return "$vidDir/$newVid";
}

sub rmVid
{
	my $vid = shift;

	my $res = system("rm -f $vid");
    if ($res > 0)
    {
        print "ERROR removing $vid from camcorder.\n";
        quit(3);
    }
}

sub copyMOVs
{
    my $link = shift;
	
	my @vids = `ls /home/reid/$link/DCIM/*/*.[mM][oO][vV]`;

    my $res = 0;

    foreach my $vid (@vids)
    {
        chomp $vid;

        my $target = "/home/reid/camera/" . basename($vid);
        $res = system("cp -v $vid $target");
        if ($res > 0)
        {
            print "ERROR copying $vid to laptop.\n";
            quit(1);
        }

        my $sourceMd5 = `md5sum $vid | cut -d ' ' -f 1`;
        chomp $sourceMd5;
        my $targetMd5 = `md5sum $target | cut -d ' ' -f 1`;
        chomp $targetMd5;

        if ($sourceMd5 ne $targetMd5)
        {
            print "ERROR: Copied vidture does not match vidture on memory card, please try again\n";
            print "$vid: $sourceMd5\n";
            print "$target: $targetMd5\n";
            quit(2);
        }

        $res = system("rm -f $vid");
        if ($res > 0)
        {
            print "ERROR removing $vid from memory card.\n";
            quit(3);
        }
    }

}

sub copyMTSs
{
    my $link = shift;

    my $vidBaseDir = "/home/reid/$link/AVCHD/BDMV";
    my @vids = `ls $vidBaseDir/STREAM/*.MTS`;
    
    my $res = 0;
    
    foreach my $vid (@vids)
    {
        chomp $vid;
		
        my $target = renameVid('/home/reid/camcorder/input', $vid);
        $res = system("cp -av $vid $target");
        if ($res > 0)
        {
            print "ERROR copying $vid to $target.\n";
            quit(1);
        }
    
        my $sourceMd5 = `md5sum $vid | cut -d ' ' -f 1`;
        chomp $sourceMd5;
        my $targetMd5 = `md5sum $target | cut -d ' ' -f 1`;
        chomp $targetMd5;
    
        if ($sourceMd5 ne $targetMd5)
        {
            print "ERROR: Copied video does not match video on camcorder, please try again\n";
            print "$vid: $sourceMd5\n";
            print "$target: $targetMd5\n";
            quit(2);
        }

		rmVid($vid);

		my $cpiFile = basename($vid);
		$cpiFile =~ s/MTS$/CPI/g;
		rmVid("$vidBaseDir/CLIPINF/$cpiFile");

    }
}

copyMOVs('sdcard');
#copyMTSs('camcorderHDD');
#copyMTSs('camcorderSD');

my $res = system('cd /home/reid/camera && ./groupvids');
if ($res > 0)
{
    print "ERROR grouping camera videos.\n";
    quit(4);
}

print "SUCCESS\n";
quit(0);
