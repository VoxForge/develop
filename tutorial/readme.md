#VoxForge Tutorial

This tutorial describes the creation of an acoustic model for the [Julius](http://julius.osdn.jp/en_index.php) 
Decoder using the [HTK](http://htk.eng.cam.ac.uk) toolkit.  It follows the approach used by the tutorial 
in the [HTK book](http://http://htk.eng.cam.ac.uk/docs/docs.shtml).

See [VoxForge](http://www.voxforge.org) website for details:

  * [Linux](http://www.voxforge.org/home/dev/acousticmodels/linux/create/htkjulius/tutorial) 
  * [Windows](http://www.voxforge.org/home/dev/acousticmodels/windows/create/htkjulius/tutorial) 

#run Julius

To run Julius with the Julius sample configuration:

  $ cd tutorial
  $ julius -input mic -C sample.jconf 

#Julius grammar
The enclosed sample grammar files are for demonstration purposes only.  They 
allow the Julius speech recognition engine to recognize the following type of
sentences:

 * CALL STEVE 
 * DIAL FIVE
 * DIAL THREE 
 * DIAL TWO 
 * PHONE YOUNG 
 * PHONE STEVE
 * DIAL NINE 

Basically, the grammar is designed to recognize any of of the numbers 
1 through 9, ZERO and OH.  You must precede numbers with the word 'DIAL' - as
in "dial 1 2 3". 

It is also set up to recognize one of the names STEVE or YOUNG.  
You must precede the name with the words "PHONE" or "CALL" - as in "phone steve" 
or "call young".

#Adding words to Julius grammar
###words already in VoxForge dictionary
You can add any word from the VoxForge dictionary (lexicon/VoxForgeDict.txt) to your
sample.voca file and recompile the Julius grammar using the included mkdfa.jl
script [Julia](http://julialang.org/):

  $ cd tutorial
  $ julia ../bin/mkdfa.jl sample

###words not in VoxForge dictionary
If you want to use words that are not included in this dictionary, you may be able to 
just add the word (with its pronunciation phones) to the VoxForgeDict.txt.  If you
get errors with respect to missing triphones, you will likely need to recompile the
acoustic model with audio that uses the words you want to add.  
The [VoxForge how-to or tutorial](http://www.voxforge.org/home/dev) can walk you the steps required to do this.


###More grammar information
For help with Julius grammar syntax see 
 * [VoxForge tutorial step 1](http://www.voxforge.org/home/dev/acousticmodels/linux/create/htkjulius/tutorial/data-prep/step-1)
    
  -or-
  
 * [Julius grammar tutorial on the Julius web site](http://julius.sourceforge.jp/en_index.php?q=en_grammar.html)

#VoxForge needs your speech
Remember, your recognition quality will be only as good as the Acoustic Model you use, 
and we need many more speech submisisons to continuously improve the VoxForge Acoustic
Models.  So please take the time to submit some speech to [VoxForge](http://www.voxforge.org).

thank you,

the VoxForge team.
