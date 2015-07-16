#! /usr/bin/perl
####################################################################
###
### script name : perlsort.pl
### version: 1.0
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2006.2.24
### Command: perl ./perlsort.pl [infile-prompts] [outfile-wlist]
###   
### Copyright (C) 2006 Ken MacLean
###
### This program is free software; you can redistribute it and/or
### modify it under the terms of the GNU General Public License
### as published by the Free Software Foundation; either version 2
### of the License, or (at your option) any later version.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
### GNU General Public License for more details.
###                                                              
####################################################################

if ($#ARGV != 1) {
 print "usage: inputfilename outputfilename\n";
 exit;
}
$inputfilename = $ARGV[0];
$outputfilename = $ARGV[1];
open(MYINPUTFILE, "<$inputfilename") or die ("need input file name"); # open for input
open(FD, ">$outputfilename") or die ("need output file name"); # open for output
print "sorting:";print $inputfilename; print " to:";print "$outputfilename \n";

my(@lines) = <MYINPUTFILE>;         # read file into list

@lines = sort(@lines);              # sort the list

my($line);
foreach $line (@lines)              # loop thru list
   {
    print FD "$line";  #print in sort order
   }
close(MYINPUTFILE);
close(FD);
