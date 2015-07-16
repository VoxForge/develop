#!/bin/sh
####################################################################
###
### script name: HTK_Compile_Model.sh
### modified by: Ken MacLean
### email: contact@voxforge.org
### Date: 2006.02.24
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

htk_init () {
	rm -rf ./interim_files
	mkdir ./interim_files
	cd ./interim_files
	mkdir hmm0 hmm1 hmm2 hmm3 hmm4 hmm5 hmm6 hmm7 hmm8 hmm9 hmm10
	mkdir hmm11 hmm12 hmm13 hmm14 hmm15 mfcc
	cd ..
	return 0
}

make_lexicon () {
	if [ -f "../../lexicon/VoxForgeDict" ]; then
		echo "Found VoxForgeDict"
	else
		echo "Error!! ../../lexicon/VoxForgeDict not found!"
		return 1
	fi
	return 0
}

make_wlist_label_file () {
	perl ../../HTK_scripts/prompts2wlist ../prompts ./interim_files/wlist

    echo 'SENT-END' >> ./interim_files/wlist 
	echo 'SENT-START' >> ./interim_files/wlist
	perl ../scripts/perlsort.pl  ./interim_files/wlist ./interim_files/wlist1
	uniq ./interim_files/wlist1 ./interim_files/wlist
    rm ./interim_files/wlist1
	return 0
}

make_monophones0 () {
	for STR in `cat ./interim_files/monophones1`; # monophones1 = monophones0 less "sp" phone
	do 
		if [ "${STR}" != "sp" ]; then 
			echo ${STR} >> ./interim_files/monophones0; 
		fi; 
	done;
	return 0
}

make_wordsmlf () {
	perl ../../HTK_scripts/prompts2mlf ./interim_files/words.mlf ../prompts
	return 0
}

make_trainscp () {
	perl create_trainscp.pl ../codetrain.scp ./interim_files/train.scp 
	return 0
}

make_hmmdefs () {
	for WORD in `cat ./interim_files/monophones0`
	do 
		tail -n 28  ./interim_files/hmm0/proto | sed s/~h\ \"proto\"/~h\ \"$WORD\"/g >> ./interim_files/hmm0/hmmdefs
	done                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
	return 0
}

make_macros () {
	head -n 3 ./interim_files/hmm0/proto > ./interim_files/hmm0/macros
	cat ./interim_files/hmm0/vFloors >> ./interim_files/hmm0/macros
	return 0
}

make_hmm4 () {
    LINE="start"
    NUM=1

	rm -rf ./interim_files/hmm4/hmmdefs.tmp1
	rm -rf ./interim_files/hmm4/hmmdefs.tmp2
	
    while [ `echo ${LINE} | awk '{ print $1 }'` != "" ];
    do
		LINE=`cat -n ./interim_files/hmm4/hmmdefs | grep ^[[:space:]]*${NUM}[[:space:]] | sed s/^[[:space:]]*[[:digit:]]*//g`
		if [ `echo ${LINE} | awk '{ print $2 }'` = "\"sil\"" ]; then
            while [ `echo ${LINE} | awk '{ print $1 }'` != "<ENDHMM>" ];
            do
                echo ${LINE} >> ./interim_files/hmm4/hmmdefs.tmp1
                echo ${LINE} >> ./interim_files/hmm4/hmmdefs.tmp2
				print_process ${NUM}
				let "NUM += 1"
				LINE=`cat -n ./interim_files/hmm4/hmmdefs | grep ^[[:space:]]*${NUM}[[:space:]] | sed s/^[[:space:]]*[[:digit:]]*//g`
			done
			
			echo ${LINE} >> ./interim_files/hmm4/hmmdefs.tmp1

			NUM2=1
			while [ ${NUM2} != "28" ];
			do
				LINE2=`cat -n ./interim_files/hmm4/hmmdefs.tmp2 | grep ^[[:space:]]*${NUM2}[[:space:]] \
				| sed s/^[[:space:]]*[[:digit:]]*//g`

			   case ${NUM2} in
					1 ) 
						echo ${LINE2} | sed s/~h\ \"sil\"/~h\ \"sp\"/g >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					2 ) 
						echo ${LINE2} >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					3 ) 
						echo ${LINE2} | sed s/5/3/g >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					10 ) 
						echo ${LINE2} | sed s/3/2/g >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					11 | 12 | 13 | 14 | 15)
						echo ${LINE2} >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					22 )
						echo ${LINE2} | sed s/5/3/g >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					24 ) 
						echo "0.000000e+000 1.000000e+000 0.000000e+000" >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					25 ) 
						echo "0.000000e+000 0.900000e+000 0.100000e+000" >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
					26 ) 
						echo "0.000000e+000 0.000000e+000 0.000000e+000" >> ./interim_files/hmm4/hmmdefs.tmp1
						;;
				esac
				let "NUM2 += 1"
			done
        fi
		echo ${LINE} >> ./interim_files/hmm4/hmmdefs.tmp1
		print_process ${NUM}
		let "NUM += 1"
	done
	mv -f ./interim_files/hmm4/hmmdefs.tmp1 ./interim_files/hmm4/hmmdefs
	return 0
} 

make_dict1 () {
	cat ./interim_files/dict > ./interim_files/dict1
	echo "silence  []  sil" >> ./interim_files/dict1
	return 0
}

make_mktrihed () {
	if [ -f "../../HTK_scripts/maketrihed" ]; then
		perl ../../HTK_scripts/maketrihed ./interim_files/monophones1 ./interim_files/triphones1
		mv mktri.hed ./interim_files/
	else
		echo "Error!! ../../HTK_scripts/maketrihed not found!"
		return 1
	fi
	return 0
}

make_treehed () {
	cat ./input_files/tree1.hed > ./interim_files/tree.hed
    perl ../../HTK_scripts/mkclscript TB 350 ./interim_files/monophones0 >> ./interim_files/tree.hed
    echo ' ' >> ./interim_files/tree.hed	     
    echo 'TR 1' >> ./interim_files/tree.hed
    echo ' ' >> ./interim_files/tree.hed
    echo 'AU "./interim_files/fulllist" ' >> ./interim_files/tree.hed
    echo 'CO "./interim_files/tiedlist" ' >> ./interim_files/tree.hed
    echo ' ' >> ./interim_files/tree.hed
    echo 'ST "./interim_files/trees" ' >> ./interim_files/tree.hed
	return 0
}

make_fulllist () {
	cat ./interim_files/fulllist > ./interim_files/fulllist-original
	cat ./interim_files/triphones1 >> ./interim_files/fulllist
	perl fixfulllist.pl ./interim_files/fulllist ./interim_files/fulllist1
	cat ./interim_files/fulllist1 > ./interim_files/fulllist
	rm ./interim_files/fulllist1
	return 0
}

print_heading () {
	if [ $? = "0" ]; then
		echo
		echo -e "\t$1"
		NUM=1
		while [ ${NUM} -lt 32 ];
		do
			echo -n "=="
			let "NUM += 1"
		done
		echo
	else
		exit 1
	fi
	return 0
}

########################################################################
#	Main 
########################################################################
print_heading "init"
	htk_init

print_heading "Step 1 - Task Grammar"
	echo -e 'already completed manually\n'

print_heading "Step 2 - Pronunciation Dictionnary"
	make_wlist_label_file
	make_lexicon
    HDMan -A -D -T 1 -m -w ./interim_files/wlist -e ./input_files -n ./interim_files/monophones1 -i -l logs/Step2_HDMan_log ./interim_files/dict ../../lexicon/VoxForgeDict > logs/Step2_HDMan.log
	make_monophones0
	echo -e '***Please review the following HDMan output***:\n'
	cat logs/Step2_HDMan_log
	
print_heading "Step 3 - Recording the Data"
	echo -e 'already completed manually\n'

print_heading "Step 4 - Creating Transcription Files"
	make_wordsmlf
	HLEd -A -D -T 1 -l '*' -d ./interim_files/dict -i ./interim_files/phones0.mlf ./input_files/mkphones0.led ./interim_files/words.mlf > logs/Step4_HLEd_phones0.log
	HLEd -A -D -T 1 -l '*' -d ./interim_files/dict -i ./interim_files/phones1.mlf ./input_files/mkphones1.led ./interim_files/words.mlf > logs/Step4_HLEd_phones1.log

print_heading "Step 5 - Coding the (Audio) Data"	
	HCopy -A -D -T 1 -C ./input_files/wav_config -S ../codetrain.scp > logs/Step5_HCopy.log
	
print_heading "Step 6 - Creating Monophones"
    make_trainscp
    echo -e 'making hmm0\n'
	HCompV -A -D -T 1 -C ./input_files/config -f 0.01 -m -S ./interim_files/train.scp -M ./interim_files/hmm0 input_files/proto > logs/Step6_HCompV_hmm0.log
	make_hmmdefs
	make_macros
	echo -e 'making hmm1\n'
	HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/phones0.mlf -t 250.0 150.0 1000.0 -S ./interim_files/train.scp -H ./interim_files/hmm0/macros -H ./interim_files/hmm0/hmmdefs -M ./interim_files/hmm1 ./interim_files/monophones0 > logs/Step6_HERest_hmm1.log
	echo -e 'making hmm2\n'
	HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/phones0.mlf -t 250.0 150.0 1000.0 -S ./interim_files/train.scp -H ./interim_files/hmm1/macros -H ./interim_files/hmm1/hmmdefs -M ./interim_files/hmm2 ./interim_files/monophones0 > logs/Step6_HERest_hmm2.log
	echo -e 'making hmm3\n'
	HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/phones0.mlf -t 250.0 150.0 1000.0 -S ./interim_files/train.scp -H ./interim_files/hmm2/macros -H ./interim_files/hmm2/hmmdefs -M ./interim_files/hmm3 ./interim_files/monophones0 > logs/Step6_HERest_hmm3.log

print_heading "Step 7 - Fixing the Silence Model"
	cp ./interim_files/hmm3/. ./interim_files/hmm4 -R
	echo -e 'making hmm4\n'
	make_hmm4 2> /dev/null
	echo -e 'making hmm5\n'
	HHEd -A -D -T 1 -H ./interim_files/hmm4/macros -H ./interim_files/hmm4/hmmdefs -M ./interim_files/hmm5 ./input_files/sil.hed ./interim_files/monophones1 > logs/Step7_HHEd_hmm5.log
	echo -e 'making hmm6\n'
	HERest -A -D -T 1 -C ./input_files/config  -I ./interim_files/phones1.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm5/macros -H ./interim_files/hmm5/hmmdefs -M ./interim_files/hmm6 ./interim_files/monophones1 > logs/Step7_HERest_hmm6.log
	echo -e 'making hmm7\n'
	HERest -A -D -T 1 -C ./input_files/config  -I ./interim_files/phones1.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm6/macros -H ./interim_files/hmm6/hmmdefs -M ./interim_files/hmm7 ./interim_files/monophones1 > logs/Step7_HERest_hmm7.log

print_heading "Step 8 - Realigning the Training Data"
	make_dict1
	echo -e 'realign hmm7\n'
	HVite -A -D -T 1 -l '*' -o SWT -b silence -C ./input_files/config -H ./interim_files/hmm7/macros -H ./interim_files/hmm7/hmmdefs -i ./interim_files/aligned.mlf -m -t 250.0 150.0 1000.0 -y lab -a -I ./interim_files/words.mlf -S ./interim_files/train.scp ./interim_files/dict1 ./interim_files/monophones1 > logs/Step8_HVite.log
	echo -e '***Please review the following HVite output***:\n'
	cat logs/Step8_HVite.log
	echo -e 'making hmm8\n'
	HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/aligned.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm7/macros -H ./interim_files/hmm7/hmmdefs -M ./interim_files/hmm8 ./interim_files/monophones1 > logs/Step8_HERest_hmm8.log
	echo -e 'making hmm9\n'
	HERest -A -D -T 1 -C ./input_files/config -I ./interim_files/aligned.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm8/macros -H ./interim_files/hmm8/hmmdefs -M ./interim_files/hmm9 ./interim_files/monophones1 > logs/Step8_HERest_hmm9.log

print_heading "Step 9 - Making Triphones from Monophones"
	echo -e 'making triphones\n'	
	HLEd -A -D -T 1 -n ./interim_files/triphones1 -l '*' -i ./interim_files/wintri.mlf ./input_files/mktri.led ./interim_files/aligned.mlf > logs/Step9_HLed.log
	make_mktrihed
	echo -e 'making hmm10\n'
	HHEd -A -D -T 1 -H ./interim_files/hmm9/macros -H ./interim_files/hmm9/hmmdefs -M ./interim_files/hmm10 ./interim_files/mktri.hed ./interim_files/monophones1 > logs/hmm10_HHEd.log
	echo -e 'making hmm11\n'
	HERest  -A -D -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -S ./interim_files/train.scp -H ./interim_files/hmm10/macros -H ./interim_files/hmm10/hmmdefs -M ./interim_files/hmm11 ./interim_files/triphones1 > logs/Step9_HERest_hmm10.log
	echo -e 'making hmm12\n'
	HERest  -A -D -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm11/macros -H ./interim_files/hmm11/hmmdefs -M ./interim_files/hmm12 ./interim_files/triphones1 > logs/Step9_HERest_hmm11.log

print_heading "Step 10 - Making Tied-State Triphones"
	HDMan -A -D -T 1 -b sp -n ./interim_files/fulllist -g ./input_files/global.ded -l logs/Step10_HDMan.flog ./interim_files/dict-tri ../../lexicon/VoxForgeDict > logs/Step10_HDMan.log
	make_fulllist  
	make_treehed
	echo -e 'making hmm13\n'
	HHEd -A -D -T 1 -H ./interim_files/hmm12/macros -H ./interim_files/hmm12/hmmdefs -M ./interim_files/hmm13 ./interim_files/tree.hed ./interim_files/triphones1 > logs/Step10_HHed_hmm13.log
	echo -e 'making hmm14\n'
	HERest -A -D -T 1 -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm13/macros -H ./interim_files/hmm13/hmmdefs -M ./interim_files/hmm14 ./interim_files/tiedlist > logs/Step10_HERest_hmm14.log
	echo -e 'making hmm15\n'
	HERest -A -D -T 1 -T 1 -C ./input_files/config -I ./interim_files/wintri.mlf -t 250.0 150.0 3000.0 -s ./interim_files/stats -S ./interim_files/train.scp -H ./interim_files/hmm14/macros -H ./interim_files/hmm14/hmmdefs -M ./interim_files/hmm15 ./interim_files/tiedlist > logs/Step11_HERest_hmm15.log
	rm -rf ../acoustic_model_files
        mkdir ../acoustic_model_files
	cp ./interim_files/hmm15/hmmdefs ../acoustic_model_files
	cp ./interim_files/tiedlist ../acoustic_model_files
	
print_heading "***completed***"
