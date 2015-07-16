#!/usr/bin/perl
####################################################################
###
### script name : fixfullist.pl
### version: 1.0
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2005.04.10
### Command: perl ./fixfullist.pl
###    
### Copyright (C) 2005 Ken MacLean
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

use strict;
my ($line, $label, $filein, $fileout, %seen);
if (@ARGV != 2) {
  print "usage: $0 filein fileout\n\n"; 
  exit (0);
}
# read in command line arguments
($filein, $fileout) = @ARGV;

open (FILEIN,"$filein") || die ("Unable to open $filein for reading");
open (FILEOUT,">$fileout") || die ("Unable to open $fileout for writing");

%seen = ();
while ($line = <FILEIN>) {
  chomp ($line);
  unless ($seen{$line}) { # remove duplicate triphone names
  	 $seen{$line} = 1;
  	   print (FILEOUT "$line\n");
  }
}
close(FILEOUT);
