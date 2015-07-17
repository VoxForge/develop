#VoxForge How-to

This how-to describes the creation of an acoustic model for the [Julius](http://julius.osdn.jp/en_index.php) 
Decoder using the [HTK](http://htk.eng.cam.ac.uk) toolkit.  It follows the approach used by the tutorial 
in the [HTK book](http://http://htk.eng.cam.ac.uk/docs/docs.shtml), but uses a script to automate most of the steps.

See [VoxForge](http://www.voxforge.org) website for details:
  [Linux](http://www.voxforge.org/home/dev/acousticmodels/linux/create/htkjulius/how-to) 
  [Windows](http://www.voxforge.org/home/dev/acousticmodels/windows/create/htkjulius/how-to) 

#run Julius

To run Julius whith a sample configuration:

  $cd voxforge/auto
  $julius -input mic -C sample.jconf 

#Julius grammar
The enclosed sample grammar files are for demonstration purposes only.  They 
allow the Julius speech recognition engine to recognize the following type of
sentences (and many more):

 * CALL STEVE YOUNG
 * DIAL FIVE SEVEN EIGHT TWO
 * DIAL THREE ZERO 
 * DIAL TWO TWO FOUR FOUR NINE ZERO SEVEN SEVEN 
 * PHONE JOE YOUNG JOHNSTON JOHNSTON JOHNSTON STEVE STEVE STEVE JOE 
 * CALL BOB JORDAN
 * CALL STEVE
 * CALL STEVE JOHNSTON
 * PHONE STEVE 
 * DIAL OH OH FOUR FIVE SIX 

Basically, the grammar is designed to recognize any combination of the numbers 
1 through 9, ZERO and OH.  You must precede numbers with the word 'DIAL' - as
in "dial 1 2 3".  

It is also set up to recognize any combination of the following names: STEVE, 
YOUNG, BOB, JOHNSTON, JOHN, JORDAN, and JOE.  You must precede the names with
the words "PHONE" or "CALL" - as in "phone steve young" or "call johnston".

#adding words to Julius grammar
##words already in VoxForge dictionary
You can add any word from the VoxForge dictionary (lexicon/VoxForgeDict.txt) to your
sample.voca file and recompile the Julius grammar using the included mkdfa.jl
script (Julia).
  $ cd auto
  $ julia ../bin/mkdfa.jl sample

##words not in VoxForge dictionary
If you want to use words that are not included in this dictionary, you may need 
to recompile the acoustic model with audio that uses the words you want to add.  
The [VoxForge how-to or tutorial](http://www.voxforge.org/home/dev) can walk you the steps required to do this.

  

##more grammar information
For help with Julius grammar syntax see 
 * [VoxForge tutorial step 1](http://www.voxforge.org/home/dev/acousticmodels/linux/create/htkjulius/tutorial/data-prep/step-1)
    
  - or -
  
 * [Julius grammar tutorial on the Julius web site](http://julius.sourceforge.jp/en_index.php?q=en_grammar.html)

#we need more speech
Remember, your recognition quality will be only as good as the Acoustic Model you use, 
and we need many more speech submisisons to continuously improve the VoxForge Acoustic
Models.  So please take the time to submit some speech to [VoxForge](www.voxforge.org).

thank you,

VoxForge.
