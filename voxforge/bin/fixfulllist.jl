###############################################################################
#
#    Copyright (C) 2015  VoxForge
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################


function fixfulllist(fulllist )
  seen=Dict{String, Int32}()
  fulllist_arr=open(readlines, fulllist) # automatically closes file handle

  fulllist_fh=open(fulllist,"w")

  for phoneln=fulllist_arr
    phone=chomp(phoneln)
    if ! haskey(seen,phone) # remove duplicate monophone/triphone names
      seen[phone]=1
      write(fulllist_fh,phone * "\n")
    end
  end

  close(fulllist_fh)
end

# if called from command line
if length(ARGS) > 0 
  if ! isfile(ARGS[1])
    error("can't find fulllist file: $ARGS[1]")
  end
  if length(ARGS) > 1
    error("fixfulllist: too many arguments for call from command line")
  end

  fixfulllist(ARGS[1] )
end


