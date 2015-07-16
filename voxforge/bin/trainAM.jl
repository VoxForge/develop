###############################################################################
#    This program trains HTK acoustic models for use with the Julius speech 
#    recognition engine
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

require("../bin/prompts2wlist.jl")
require("../bin/prompts2mlf.jl")
require("../bin/mktrihed.jl")
require("../bin/mkclscript.jl")
require("../bin/fixfulllist.jl")

function htkinit() 
  if isdir("./acoustic_model_files")
    rm("./acoustic_model_files"; recursive=true)
  end
  mkdir("./acoustic_model_files")
  if isdir("./interim_files")
    rm("./interim_files"; recursive=true)
  end
  mkdir("./interim_files")
  for d=0:15
    mkdir("./interim_files/hmm$d")
  end
  if isdir("./logs")
    rm("./logs"; recursive=true)
  end
  mkdir("./logs")
end

function confirm_lexicon() 
  if isfile("../lexicon/VoxForgeDict.txt")
    println("Found VoxForgeDict.txt")
  else
    println("Error: VoxForgeDict.txt not found!")
  end
end

   
function make_monophones0() 
  monophones1_arr=open(readlines, "./interim_files/monophones1","r"); 
  monophones0_fh=open("./interim_files/monophones0","w"); 
  for m=monophones1_arr
    if chomp(m) != "sp"
      write(monophones0_fh,m)
    end
  end
  close(monophones0_fh);
end

function make_trainscp()
  mlf=open("./interim_files/train.scp","w"); 

  codetrain_arr=open(readlines, "codetrain.scp")
  for lineln=codetrain_arr
    line=chomp(lineln)
    line_array=split(line,r"\s+"); 
    filename=pop!(line_array) 
    print(mlf, filename * "\n")
  end

  close(mlf)
end

function make_hmmdefs ()
  hmmdefs=open("./interim_files/hmm0/hmmdefs","a")

  protoall=open(readlines, "./interim_files/hmm0/proto","r")
  proto=protoall[5:31]
  monophones0=open(readlines, "./interim_files/monophones0","r")
  for m=monophones0
    c=chomp(m)
    write(hmmdefs,"~h \"$c\"\n")
    write(hmmdefs,proto)
  end

  close(hmmdefs)
end

function make_macros()
  macros_fh=open("./interim_files/hmm0/macros","w");

  proto_arr=open(readlines, "./interim_files/hmm0/proto")
  for i=1:3
    write(macros_fh,proto_arr[i])
  end
  vFloors_arr=open(readlines, "./interim_files/hmm0/vFloors")
  write(macros_fh,vFloors_arr)

  close(macros_fh)
end

function make_hmm4 ()
  sp_model=fill("",100)

  silstart=false
  silend=false
  function select_sil(line)
    if ismatch(r"^~h \"sil\"", line)
      silstart=true
    elseif silstart && ismatch(r"^~h", line)
      silend=true
    end
    if silstart && ! silend
      remove_uneeded_states(line)
    end
  end

  stateskip=false
  stateend=false
  function remove_uneeded_states(line)
    if ismatch(r"<STATE> 2", line)
      stateskip=true
    elseif stateskip && ismatch(r"<STATE> 3", line)
      stateskip=false     
    elseif ismatch(r"<STATE> 4", line)
      stateskip=true  
    elseif stateskip && ismatch(r"<TRANSP> 5", line)
      stateskip=false     
    end
    if ! stateskip
      modify_states(line)
    end
  end

  done=false
  function modify_states(line)
    if ismatch(r"~h \"sil\"\n", line)
      push!(sp_model,"~h \"sp\"\n\n") 
    elseif ismatch(r"<NUMSTATES> 5\n", line)
      push!(sp_model,"<NUMSTATES> 3\n") 
    elseif ismatch(r"<STATE> 3\n", line)
      push!(sp_model,"<STATE> 2\n") 
    elseif ismatch(r"<TRANSP> 5\n", line)
      push!(sp_model,"<TRANSP> 3\n") 
      push!(sp_model,"0.0 1.0 0.0\n") 
      push!(sp_model,"0.0 0.9 0.1\n") 
      push!(sp_model,"0.0 0.0 0.0\n") 
      push!(sp_model,"<ENDHMM>\n") 
      done=true
    elseif !done
      push!(sp_model,line) 
    end
  end

  # copy sil model into sp_model array
  hmm4_arr=open(readlines, "./interim_files/hmm4/hmmdefs") 
  for line=hmm4_arr
    select_sil(line)
  end

  hmm=open("./interim_files/hmm4/hmmdefs","a") 
  for line=sp_model # ignores undefined entries
    write(hmm,line)
  end    
  close(hmm)
end

function make_dict1() 
  dict=open(readlines, "./interim_files/dict")  # automatically closes file handle

  dict1=open("./interim_files/dict1","w") 
  for line=dict
    write(dict1,line)
  end   
  write(dict1,"silence  []  sil\n") 
  close(dict1)
end

function mktrihed() 
  monophones1_arr=open(readlines, "./interim_files/monophones1")  # automatically closes file handle

  hed=open("./interim_files/mktri.hed","w") 
  write(hed, "CL ./interim_files/triphones1\n")
  for phoneln=monophones1_arr
    phone=chomp(phoneln)
    if length(phone)>0
      write(hed,"TI T_$phone {(*-$phone+*,$phone+*,*-$phone).transP}\n")
    end
  end
  close(hed)
end

function append_to_file(fromfile, tofile)
  tofile=open(tofile,"a")

  fromfile_arr=open(readlines, fromfile)  # automatically closes file handle
  for line=fromfile_arr
    write(tofile,line)
  end

  close(tofile)
end

function complete_tree_hed(tree_hed)
  hmmlist=open(tree_hed,"a"); 

  write(hmmlist," \n"); 
  write(hmmlist,"TR 1\n");     
  write(hmmlist," \n"); 
  write(hmmlist,"AU \"./interim_files/fulllist\" \n"); 
  write(hmmlist,"CO \"./interim_files/tiedlist\" \n"); 
  write(hmmlist," \n"); 
  write(hmmlist,"ST \"./interim_files/trees\"  \n"); 

  close(hmmlist)
end

########################################################################
# Main 
########################################################################
println("init")
  htkinit()

println("Step 1 - Task Grammar")
  println("already completed manually")

println("Step 2 - Pronunciation Dictionnary")
  prompts2wlist("prompts.txt","./interim_files/wlist" )
  confirm_lexicon()
  out=readall(`HDMan -A -D -T 1 -m -w ./interim_files/wlist -e ./input_files -n ./interim_files/monophones1 -i -l logs/Step2_HDMan_log ./interim_files/dict ../lexicon/VoxForgeDict.txt`)
  f=open("./logs/Step2_HDMan.log","w"); write(f,out); close(f)
  make_monophones0()
  println("***Please review the following HDMan output***:")
  hdman=open(readlines, "logs/Step2_HDMan_log")
  for line=hdman
    print(line)
  end

println("Step 3 - Recording the Data")
  println("already completed manually")

println("Step 4 - Creating Transcription Files")
  prompts2mlf("prompts.txt", "interim_files/words.mlf")
  out=readall(`HLEd -A -D -T 1 -l '*' -d ./interim_files/dict -i ./interim_files/phones0.mlf ./input_files/mkphones0.led ./interim_files/words.mlf`)
  f=open("logs/Step4_HLEd_phones0.log","w"); write(f,out); close(f)
  out=readall(`HLEd -A -D -T 1 -l '*' -d ./interim_files/dict -i ./interim_files/phones1.mlf ./input_files/mkphones1.led ./interim_files/words.mlf`)
  f=open("logs/Step4_HLEd_phones1.log","w"); write(f,out); close(f)

println("Step 5 - Coding the (Audio) Data")
  out=readall(`HCopy -A -D -T 1 -C ./input_files/wav_config -S codetrain.scp`)
  f=open("logs/Step5_HCopy.log","w"); write(f,out); close(f)
 
println("Step 6 - Creating Monophones")
  make_trainscp()
  println("making hmm0\n")
  run(`HCompV -A -D -T 1 -C ./input_files/config -f 0.01 -m -S ./interim_files/train.scp -M ./interim_files/hmm0 input_files/proto`)
  f=open("logs/Step6_HCompV_hmm0.log","w"); write(f,out); close(f)
  make_hmmdefs()
  make_macros()
  for cur=1:3
    println("making hmm$cur")
    prev=cur-1;
    out=readall(`HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/phones0.mlf -t 250.0 150.0 1000.0 -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/monophones0`)
    f=open("logs/Step6_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

println("Step 7 - Fixing the Silence Model")
  run(`cp ./interim_files/hmm3/. ./interim_files/hmm4 -R`)
  println("making hmm4")
  make_hmm4()
  println("making hmm5")
  out=readall(`HHEd -A -D -T 1 -H ./interim_files/hmm4/macros -H ./interim_files/hmm4/hmmdefs -M ./interim_files/hmm5 ./input_files/sil.hed ./interim_files/monophones1`)
  f=open("logs/Step7_HHEd_hmm5.log","w"); write(f,out); close(f)
  for cur=6:7
    println("making hmm$cur")
    prev=cur-1;
    out=readall(`HERest -A -D -T 1 -C ./input_files/config  -I ./interim_files/phones1.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/monophones1`)
    f=open("logs/Step7_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

println("Step 8 - Realigning the Training Data")
  make_dict1()
  println("realign hmm7")
  out=readall(`HVite -A -D -T 1 -l '*' -o SWT -b silence -C ./input_files/config -H ./interim_files/hmm7/macros -H ./interim_files/hmm7/hmmdefs -i ./interim_files/aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I ./interim_files/words.mlf -S ./interim_files/train.scp ./interim_files/dict1 ./interim_files/monophones1`)
  f=open("logs/Step8_HVite.log","w"); write(f,out); close(f)
  println("***Please review the following HVite output***:")
  hvite_log=open(readlines, "logs/Step8_HVite.log","r")  # automatically closes file handle
  for line=hvite_log
    print(line)
  end   
  for cur=8:9
    println("making hmm$cur")
    prev=cur-1;
    out=readall(`HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/aligned.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/monophones1`)
    f=open("logs/Step8_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

println("Step 9 - Making Triphones from Monophones")
  println("making triphones")
  out=readall(`HLEd -A -D -T 1 -n ./interim_files/triphones1 -l '*' -i ./interim_files/wintri.mlf ./input_files/mktri.led ./interim_files/aligned.mlf`)
  f=open("logs/Step9_HLed.log","w"); write(f,out); close(f)
  mktrihed("./interim_files/monophones1", "./interim_files/triphones1", "./interim_files/mktri.hed")
  println("making hmm10")
  out=readall(`HHEd -A -D -T 1 -H ./interim_files/hmm9/macros -H ./interim_files/hmm9/hmmdefs -M ./interim_files/hmm10 ./interim_files/mktri.hed ./interim_files/monophones1`)
  f=open("logs/Step9_HHEd_hmm10.log","w"); write(f,out); close(f)
  println("making hmm11")
  out=readall(`HERest  -A -D -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm10/macros -H ./interim_files/hmm10/hmmdefs -M ./interim_files/hmm11 ./interim_files/triphones1`)
  f=open("logs/Step9_HERest_hmm11.log","w"); write(f,out); close(f)
  println("making hmm12")
  out=readall(`HERest  -A -D -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm11/macros -H ./interim_files/hmm11/hmmdefs -M ./interim_files/hmm12 ./interim_files/triphones1`)
  f=open("logs/Step9_HERest_hmm12.log","w"); write(f,out); close(f)

println("Step 10 - Making Tied-State Triphones")
  out=readall(`HDMan -A -D -T 1 -b sp -n ./interim_files/fulllist -g ./input_files/global.ded -l logs/Step10_HDMan.flog ./interim_files/dict-tri ../lexicon/VoxForgeDict.txt`)
  f=open("logs/Step10_HDMan.log","w"); write(f,out); close(f)
  append_to_file("./interim_files/triphones1", "./interim_files/fulllist")
  fixfulllist("./interim_files/fulllist", "./interim_files/fulllist")
  cp("./input_files/tree1.hed", "./interim_files/tree.hed")
  mkclscript( "./interim_files/monophones0", "./interim_files/tree.hed")
  complete_tree_hed("./interim_files/tree.hed")
  println("making hmm13")
  out=readall(`HHEd -A -D -T 1 -H ./interim_files/hmm12/macros -H ./interim_files/hmm12/hmmdefs -M ./interim_files/hmm13 ./interim_files/tree.hed ./interim_files/triphones1`)
  f=open("logs/Step10_HHed_hmm13.log","w"); write(f,out); close(f)
  for cur=14:15
    println("making hmm$cur")
    prev=cur-1;
    out=readall(`HERest -A -D -T 1 -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/tiedlist`)
    f=open("logs/Step10_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

  cp("./interim_files/hmm15/hmmdefs", "acoustic_model_files/hmmdefs")
  cp("./interim_files/tiedlist", "acoustic_model_files/tiedlist")
