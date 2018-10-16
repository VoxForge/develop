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

if VERSION < v"1.0"  
   @warn("the VoxForge scripts require version 1.0 and above")
end


include("../bin/prompts2wlist.jl")
include("../bin/prompts2mlf.jl")
include("../bin/mktrihed.jl")
include("../bin/mkclscript.jl")
include("../bin/fixfulllist.jl")

function htkinit() 
  if isdir("./acoustic_model")
    rm("./acoustic_model"; recursive=true)
  end
  mkdir("./acoustic_model")
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
      write(monophones0_fh,"$m\n")
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

function make_hmmdefs()
  hmmdefs=open("./interim_files/hmm0/hmmdefs","a")

  protoall=open(readlines, "./interim_files/hmm0/proto","r")
  proto=protoall[5:31]
  monophones0=open(readlines, "./interim_files/monophones0","r")
  for m=monophones0
    c=chomp(m)
    write(hmmdefs,"~h \"$c\"\n")
    #write(hmmdefs,proto)
    for line=proto
      write(hmmdefs,"$line\n")
    end
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
  #write(macros_fh,vFloors_arr)
  for line=vFloors_arr
    write(macros_fh,"$line\n")
  end
  close(macros_fh)
end

function make_hmm4()
  sp_model=fill("",100)
  silstart=false
  silend=false
  function select_sil(line)
    if occursin(r"^~h \"sil\"", line)
      silstart=true
    elseif silstart && occursin(r"^~h", line)
      silend=true
    end
    if silstart && ! silend
      remove_uneeded_states(line)
    end
  end

  stateskip=false
  stateend=false
  function remove_uneeded_states(line)
    if occursin(r"<STATE> 2", line)
      stateskip=true
    elseif stateskip && occursin(r"<STATE> 3", line)
      stateskip=false     
    elseif occursin(r"<STATE> 4", line)
      stateskip=true  
    elseif stateskip && occursin(r"<TRANSP> 5", line)
      stateskip=false     
    end
    if ! stateskip
      modify_states(line)
    end
  end

  done=false
  function modify_states(line)
    if occursin(r"~h \"sil\"", line)
      push!(sp_model,"~h \"sp\"") 
    elseif occursin(r"<NUMSTATES> 5", line)
      push!(sp_model,"<NUMSTATES> 3") 
    elseif occursin(r"<STATE> 3", line)
      push!(sp_model,"<STATE> 2") 
    elseif occursin(r"<TRANSP> 5", line)
      push!(sp_model,"<TRANSP> 3") 
      push!(sp_model,"0.0 1.0 0.0") 
      push!(sp_model,"0.0 0.9 0.1") 
      push!(sp_model,"0.0 0.0 0.0") 
      push!(sp_model,"<ENDHMM>") 
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
  for line=sp_model
      if ! isempty(line) # 100 element array that fills up from end to beginning - empty in front
        write(hmm,"$line\n")
      end
  end    
  close(hmm)
end

function make_dict1() 
  dict=open(readlines, "./interim_files/dict")  # automatically closes file handle

  dict1=open("./interim_files/dict1","w") 
  for line=dict
    write(dict1,"$line\n")
  end
  # TODO silence not in alpha order in dict1
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
  global out=read(`HDMan -A -D -T 1 -m -w ./interim_files/wlist -e ./input_files -n ./interim_files/monophones1 -i -l logs/Step2_HDMan_log ./interim_files/dict ../lexicon/VoxForgeDict.txt`, String)
  global f=open("./logs/Step2_HDMan.log","w"); write(f,out); close(f)
  make_monophones0()
  println("***Please review the following HDMan output***:")
  hdman=open(readlines, "logs/Step2_HDMan_log")
  for line=hdman
    print("$(line)\n")
  end

println("Step 3 - Recording the Data")
  println("already completed manually")

println("Step 4 - Creating Transcription Files")
  prompts2mlf("prompts.txt", "interim_files/words.mlf")
  out=read(`HLEd -A -D -T 1 -l '*' -d ./interim_files/dict -i ./interim_files/phones0.mlf ./input_files/mkphones0.led ./interim_files/words.mlf`, String)
  f=open("logs/Step4_HLEd_phones0.log","w"); write(f,out); close(f)
  out=read(`HLEd -A -D -T 1 -l '*' -d ./interim_files/dict -i ./interim_files/phones1.mlf ./input_files/mkphones1.led ./interim_files/words.mlf`, String)
  f=open("logs/Step4_HLEd_phones1.log","w"); write(f,out); close(f)

println("Step 5 - Coding the (Audio) Data")
  out=read(`HCopy -A -D -T 1 -C ./input_files/wav_config -S codetrain.scp`, String)
  f=open("logs/Step5_HCopy.log","w"); write(f,out); close(f)

println("Step 6 - Creating Monophones")
  make_trainscp()
  println("making hmm0")
  out=read(`HCompV -A -D -T 1 -C ./input_files/config -f 0.01 -m -S ./interim_files/train.scp -M ./interim_files/hmm0 input_files/proto`)
  f=open("logs/Step6_HCompV_hmm0.log","w"); write(f,out); close(f)
  make_hmmdefs()
  make_macros()
  for cur=1:3
    println("making hmm$cur")
    prev=cur-1;
    out=read(`HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/phones0.mlf -t 250.0 150.0 1000.0 -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/monophones0`, String)
    f=open("logs/Step6_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

println("Step 7 - Fixing the Silence Model")
  run(`cp ./interim_files/hmm3/. ./interim_files/hmm4 -R`)
  println("making hmm4")
  make_hmm4()
  println("making hmm5")
  out=read(`HHEd -A -D -T 1 -H ./interim_files/hmm4/macros -H ./interim_files/hmm4/hmmdefs -M ./interim_files/hmm5 ./input_files/sil.hed ./interim_files/monophones1`, String)
  f=open("logs/Step7_HHEd_hmm5.log","w"); write(f,out); close(f)
  for cur=6:7
    println("making hmm$cur")
    prev=cur-1;
    out=read(`HERest -A -D -T 1 -C ./input_files/config  -I ./interim_files/phones1.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/monophones1`, String)
    f=open("logs/Step7_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

println("Step 8 - Realigning the Training Data")
  make_dict1()
  println("realign hmm7")
  out=read(`HVite -A -D -T 1 -l '*' -o SWT -b silence -C ./input_files/config -H ./interim_files/hmm7/macros -H ./interim_files/hmm7/hmmdefs -i ./interim_files/aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I ./interim_files/words.mlf -S ./interim_files/train.scp ./interim_files/dict1 ./interim_files/monophones1`, String)
  f=open("logs/Step8_HVite.log","w"); write(f,out); close(f)
  println("***Please review the following HVite output***:")
  hvite_log=open(readlines, "logs/Step8_HVite.log","r")  # automatically closes file handle
  for line=hvite_log
    println(line)
  end   
  for cur=8:9
    println("making hmm$cur")
    prev=cur-1;
    out=read(`HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/aligned.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/monophones1`, String)
    f=open("logs/Step8_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

println("Step 9 - Making Triphones from Monophones")
  println("making triphones")
  out=read(`HLEd -A -D -T 1 -n ./interim_files/triphones1 -l '*' -i ./interim_files/wintri.mlf ./input_files/mktri.led ./interim_files/aligned.mlf`, String)
  f=open("logs/Step9_HLed.log","w"); write(f,out); close(f)
  mktrihed("./interim_files/monophones1", "./interim_files/triphones1", "./interim_files/mktri.hed")
  println("making hmm10")
  out=read(`HHEd -A -D -T 1 -H ./interim_files/hmm9/macros -H ./interim_files/hmm9/hmmdefs -M ./interim_files/hmm10 ./interim_files/mktri.hed ./interim_files/monophones1`, String)
  f=open("logs/Step9_HHEd_hmm10.log","w"); write(f,out); close(f)
  println("making hmm11")
  out=read(`HERest  -A -D -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm10/macros -H ./interim_files/hmm10/hmmdefs -M ./interim_files/hmm11 ./interim_files/triphones1`, String)
  f=open("logs/Step9_HERest_hmm11.log","w"); write(f,out); close(f)
  println("making hmm12")
  out=read(`HERest  -A -D -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm11/macros -H ./interim_files/hmm11/hmmdefs -M ./interim_files/hmm12 ./interim_files/triphones1`, String)
  f=open("logs/Step9_HERest_hmm12.log","w"); write(f,out); close(f)

println("Step 10 - Making Tied-State Triphones")
  out=read(`HDMan -A -D -T 1 -b sp -n ./interim_files/fulllist -g ./input_files/maketriphones.ded -l logs/Step10_HDMan.flog ./interim_files/dict-tri ../lexicon/VoxForgeDict.txt`, String)
  f=open("logs/Step10_HDMan.log","w"); write(f,out); close(f)
  fixfulllist("./interim_files/fulllist", "./interim_files/monophones0", "./interim_files/fulllist")
  cp("./input_files/tree1.hed", "./interim_files/tree.hed")
  mkclscript( "./interim_files/monophones0", "./interim_files/tree.hed", "./interim_files/")
  println("making hmm13")
  out=read(`HHEd -A -D -T 1 -H ./interim_files/hmm12/macros -H ./interim_files/hmm12/hmmdefs -M ./interim_files/hmm13 ./interim_files/tree.hed ./interim_files/triphones1`, String)
  f=open("logs/Step10_HHed_hmm13.log","w"); write(f,out); close(f)
  for cur=14:15
    println("making hmm$cur")
    prev=cur-1;
    out=read(`HERest -A -D -T 1 -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm$prev/macros -H ./interim_files/hmm$prev/hmmdefs -M ./interim_files/hmm$cur ./interim_files/tiedlist`, String)
    f=open("logs/Step10_HERest_hmm$cur.log","w"); write(f,out); close(f)
  end

  cp("./interim_files/hmm15/hmmdefs", "acoustic_model/hmmdefs")
  cp("./interim_files/tiedlist", "acoustic_model/tiedlist")
