# simpleDM

simpleDM is a very basic command and control dialog manager that uses the [Julius](http://julius.osdn.jp/en_index.php)
speech recognition engine and the acoustic models you created in the VoxForge Howto (or Tutorial).

# Try it out

Extract the github zip file to a directory, change directory to the simpleDM 
folder, and execute one of the following commands:

  Linux:

      $ cd simpleDM
      $ ../bin/julius -input mic -C simpleDM.jconf -gramlist grammars_linux -plugindir plugin/linux

  Windows:

      C:> bin\julius.exe -input mic -C simpleDM.jconf -gramlist grammars_windows.txt -plugindir plugin/windows

Note that we need many more speech submissions to create high quality free Acoustic 
Models.  Please take the time to submit some speech to [voxforge](http://www.voxforge.org) using the 
[VoxForge speech applet](http://www.voxforge.org/home/read).

thank you,

the VoxForge team.
