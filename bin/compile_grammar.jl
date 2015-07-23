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

function reverse_grammar(rgramfile,gramfile)
  rgramfile_fh=open(rgramfile,"w")

  gramfile_arr=open(readlines, gramfile) # automatically closes file handle 
  n=0
  for lineln=gramfile_arr
    if ! ismatch(r"^[\n|\r]", lineln)
      line=replace(chomp(lineln), r"#.*", "") # remove line endings & comments
      (left, right)=split(line,r"\:")
      category_arr=split(right,r"\s")
      reverse_category_arr=reverse(category_arr)

      write(rgramfile_fh, left * ":")
      write(rgramfile_fh, join(reverse_category_arr," ")  )
      if ismatch(r"\r$", lineln) # windows line ending
        write(rgramfile_fh, "\n\r")
      else
        write(rgramfile_fh, "\n")

      end
      n=n+1
    end
  end

  close(rgramfile_fh)
  println("$gramfile has $n rules")
  println("---")
end

function make_category_voca(vocafile,termfile,tmpvocafile)
  tmpvocafile_fh=open(tmpvocafile,"w")
  termfile_fh=open(termfile,"w")

  vocafile_arr=open(readlines, vocafile) # automatically closes file handle 
  n1=0
  n2=0
  termid=0
  for lineln=vocafile_arr
    if ismatch(r"\r$", lineln)
      lineend="\r\n" # windows line ending
    else
      lineend="\n" # unix/linux line ending
    end
    line=replace(chomp(lineln), r"#.*", "") # remove line endings & comments

    m=match(r"^%[ \t]*([A-Za-z0-9_]*)", line)
    if m == nothing
      n2=n2+1
    else
      found=m.captures[1] 

      write(tmpvocafile_fh, "\#$found$(lineend)")
      write(termfile_fh, "$termid\t$found$(lineend)")

      termid=termid+1
      n1=n1+1
    end
  end

  close(tmpvocafile_fh)
  close(termfile_fh)
  println("$vocafile has $n1 categories and $n2 words")
  println("generated: $termfile")
  println("---")
end

function voca2dict(vocafile, dictfile)
  dictfile_fh=open(dictfile,"w")

  vocafile_arr=open(readlines, vocafile) # automatically closes file handle 
  newid=-1
  for lineln=vocafile_arr
    if ismatch(r"\r$", lineln)
      lineend="\r\n" # windows line ending
    else
      lineend="\n" # unix/linux line ending
    end

    line=replace(chomp(lineln), r"#.*", "") # remove line endings & comments
    if ismatch(r"^[\s\t]*$", line) # skip blank lines
      continue
    end

    if ismatch(r"^%", line)
      newid=newid+1
    else
      line_arr=split(line,r"[\s\t]+")
      name=shift!(line_arr)
      write(dictfile_fh, "$(newid)\t[$(name)]\t$(join(line_arr," "))$(lineend)")
    end
  end

  close(dictfile_fh)

  println("generated: $dictfile")
end

function vfvoca2dict(vocafile,dic,dictfile)
  dic_hash=Dict{String,String}()
  dic_arr=open(readlines, dic) # automatically closes file handle 
  for lineln=dic_arr
    line=replace(chomp(lineln), r"#.*", "") # remove line endings & comments
    line_arr=split(line,r"[\s\t]+")
    uniq_word=shift!(line_arr)
    return_word=shift!(line_arr)
    phones=join(line_arr," ")
    dic_hash[uniq_word]=phones
  end
  dic_hash["<s>"]="sil"
  dic_hash["</s>"]="sil"

  dictfile_fh=open(dictfile,"w")

  vocafile_arr=open(readlines, vocafile) # automatically closes file handle 
  newid=-1
  for lineln=vocafile_arr
    if ismatch(r"\r$", lineln)
      lineend="\r\n" # windows line ending
    else
      lineend="\n" # unix/linux line ending
    end

    line=replace(chomp(lineln), r"#.*", "") # remove line endings & comments
    if ismatch(r"^[\s\t]*$", line) # skip blank lines
      continue
    end

    if ismatch(r"^%", line)
      newid=newid+1
    elseif ismatch(r"\<s\>", line) # get a bounds error if search for <s> or </s>
      write(dictfile_fh, "$(newid)\t[<s>] sil\n")
    elseif ismatch(r"\<\/s\>", line) # get a bounds error if search for <s> or </s>
      write(dictfile_fh, "$(newid)\t[</s>] sil\n")
    else
      line_array=split(line,r"[\s\t]+")
      name=shift!(line_array)
      command=join(line_array," ")
      write(dictfile_fh, "$(newid)\t$command $(dic_hash[name])\n")
    end
  end

  close(dictfile_fh)

  println("generated: $dictfile")
end

function main ()
  mkfa= @windows ? "mkfa.exe" : "mkfa"
  dfa_minimize= @windows ? "dfa_minimize.exe" : "dfa_minimize"

  grammar_prefix=ARGS[1] 
  grammar_folder=ARGS[1] 
  if ! isfile(grammar_prefix * ".grammar")
    error("can't find gramfile file: $(grammar_folder)/$(grammar_prefix).grammar")
  end
  if ! isfile(grammar_prefix * ".voca")
    error("can't find voca file: $(grammar_prefix).voca")
  end
  if length(ARGS) > 1
    error("mkdfa: too many arguments for call from command line")
  end

  #workingfolder=dirname(ARGS[1]) # debug
  workingfolder=mktempdir()
  grammar_prefix=ARGS[1] # includes path

  rgramfile= "$(workingfolder)/g$(getpid()).grammar"
  gramfile="$(grammar_prefix).grammar"
  vocafile=grammar_prefix * ".voca"
  termfile=grammar_prefix * ".term"
  tmpvocafile="$(workingfolder)/g$(getpid()).voca"
  dfafile=grammar_prefix * ".dfa"
  dictfile="$(grammar_prefix).dict"
  headerfile="$(workingfolder)/g$(getpid()).h"

  # voxforge updates
  reverse_grammar(rgramfile,gramfile)
  vocafile="$(grammar_prefix).voca"
  dic="../lexicon/VoxForgeDict.txt"
  dicfile="$(grammar_prefix).dict"
  make_category_voca(vocafile,termfile,tmpvocafile)
  println("dir $(pwd())")
  run(`$mkfa -e1 -fg $rgramfile -fv $tmpvocafile -fo $(dfafile).tmp -fh $headerfile`)
  run(`$dfa_minimize $(dfafile).tmp -o $dfafile`)

  vfvoca2dict(vocafile,dic,dicfile)

  rm("$(dfafile).tmp")
  rm(rgramfile)
  rm(tmpvocafile)
  rm(headerfile)

end

# called from command line
if length(ARGS) > 0 
  main()
end
