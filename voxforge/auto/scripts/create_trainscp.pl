#!/usr/bin/perl
####################################################################
###
### script name : create_trainscp.pl
### version: 1.0
### created by: Ken MacLean
### mail: contact@voxforge.org
### Date: 2005.01.14
### Command: perl ./create_trainscp.pl
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

my ($prompts, $fileout, $line, $filename, @filename, @line_array, @word_list);

# check usage
if (@ARGV != 2) {
  print "usage: $0 prompts wordlist\n\n"; 
  exit (0);
}

# read in command line arguments
($prompts, $fileout) = @ARGV;

# open files
open (PROMPTS,"$prompts") || die ("Unable to open prompts $prompts file for reading");
open (FILEOUT,">$fileout") || die ("Unable to open word list $fileout file for writing");

# process each prompt one at a time
while ($line = <PROMPTS>) {
  chomp ($line);
  @line_array=split(/\s+/, $line); # take a line, break words seperated by spaces into an individual array element
  $filename = pop (@line_array);  # get mfc path and filename 
  print (FILEOUT "$filename\n"); # output to file
}

close(WLIST);
close(PROMPTS);
