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

function mkclscript(monophones0, tree_hed)
  hmmlist=open(tree_hed,"a"); 

  monophones0_arr=open(readlines, monophones0) 
  for i=2:4
    for phoneln=monophones0_arr
      phone=chomp(phoneln)
      write(hmmlist,"TB 350 \"ST_$phone\_$i\_\" {(\"$phone\",\"*-$phone\+*\",\"$phone\+*\",\"*-$phone\").state[$i]}\n") 
    end
  end

  close(hmmlist)
end

# if called from command line
if length(ARGS) > 0 
  if ! isfile(ARGS[1])
    error("can't find monophones0 file: $ARGS[1]")
  end
  if ! isfile(ARGS[2])
    error("can't find tree.hed file: $ARGS[2]")
  end
  if length(ARGS) > 2
    error("mkclscript: too many arguments for call from command line")
  end

  mkclscript(ARGS[1], ARGS[2] )
end


