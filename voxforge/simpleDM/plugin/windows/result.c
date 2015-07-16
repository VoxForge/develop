/**
 * @file   result.c
 * 
 * <EN>
 * @brief  Plugin to process recognition result
 * </EN>
 * 
 * 
 * @author Akinobu Lee
 * @date   Fri Aug 22 15:17:59 2008
 * 
 * $Revision: 1.1 $
 * 
 */

/**
 * Required for a file
 *   - get_plugin_info()
 *
 * Optional for a file
 *   - initialize()
 * 
 */
/**
 * Result processing function
 * 
 *   - result_str()
 *   
 */

/***************************************************************************/

#include <stdio.h>
#include <string.h>
// !!!!!!
#include <sys/types.h> 
#include <unistd.h> 
#include <stdlib.h> 
#include <stdbool.h>
#include <process.h>
#include <errno.h>
void child(char *result_str);
// !!!!!!

#define PLUGIN_TITLE "plugin for Julius"

/** 
 * <EN>
 * @brief  Initialization at loading time (optional)
 * 
 * If defined, this will be called just before this plugin is loaded to Julius.
 * if this returns -1, the whole functions in this file will not be loaded.
 *
 * This function is OPTIONAL.
 * </EN>
 * <JA>
 * @brief  ÆÉ€ß¹þ€ß»þ€ÎœéŽü²œ¡ÊÇ€°Õ¡Ë
 *
 * µ¯Æ°»þ¡€Julius €¬€³€Î¥×¥é¥°¥€¥ó€òÆÉ€ß¹þ€àºÝ€ËºÇœé€ËžÆ€Ð€ì€ë¡¥
 * -1 €òÊÖ€¹€È¡€€³€Î¥×¥é¥°¥€¥óÁŽÂÎ€¬ÆÉ€ß¹þ€Þ€ì€Ê€¯€Ê€ë¡¥
 * ŒÂ¹Ô²ÄÇœÀ­€Î¥Á¥§¥Ã¥¯€Ë»È€š€ë¡¥
 *
 * </JA>
 * 
 * 
 * @return 0 on success, -1 on failure.
 * 
 */
int
initialize()
{
  return 0;
}

/** 
 * <EN>
 * @brief  Get information of this plugin (required)
 *
 * This function should return informations of this plugin file.
 * The required info will be specified by opcode:
 *  - 0: return description string of this file into buf
 *
 * This will be called just after Julius find this file and after
 * initialize().
 *
 * @param opcode [in] requested operation code
 * @param buf [out] buffer to store the return string
 * @param buflen [in] maximum length of buf
 *
 * @return 0 on success, -1 on failure.  On failure, Julius will ignore this
 * plugin.
 * 
 * </EN>
 * 
 */
int
get_plugin_info(int opcode, char *buf, int buflen)
{
  switch(opcode) {
  case 0:
    /* plugin description string */
    strncpy(buf, PLUGIN_TITLE, buflen);
    break;
  }

  return 0;
}

// windows:
// to compile for Windows (from Cygwin terminal): i686-w64-mingw32-gcc -shared -o result.jpi result.c
// bin\julius.exe -input mic -C voxshell.jconf -gramlist grammars_windows.txt
// c:> assoc .pl=Perl
// C:> ftype Perl="C:\cygwin\bin\perl.exe" "%1" %*
// linux:
// to run: clear && ./julius -input mic -C voxshell.jconf -plugindir plugin -quiet
void result_best_str(char *result_str)
{
printf("result %s\n", result_str); 
  pid_t pid; // process id
  if (result_str == NULL) {
    printf("[null result]\n");
  } else {
      child(result_str);
  }
}

// Note: this function modified the result string
// while parsing it replaces spaces with string endings ('\0')
void child(char *result)
{
  int status; // return variable from executing spawnv command
  int i; // loop counter
  int arg_idx; // argument index counter
  char *command; // actual command to run in child process
  char *argv[100]; // array of pointers to strings (char arrays)

  // process command
  i=9; // skip [<s> COM "] // skip first set of double quotes
  command=&(result[i]);  // point to start of command
  while ( result[i] != '"' ) i++; // looking next set of double quotes indicating end of command
  result[i++]='\0'; // replace double quotes null string ending

  // process arguments
  // (from: https://msdn.microsoft.com/en-us/library/7zt1y878.aspx)
  // The argument argv[0] (i.e. argv) is usually a pointer to a path in real 
  // mode or to the program name in protected mode.
  // Note: putting command name in argv[0] will execute the command twice???
  // nice one Windows...
  argv[0]="child";  // used an as identifier, not used as an argument

  // (from: https://msdn.microsoft.com/en-us/library/7zt1y878.aspx)
  // argv[1] through argv[n] are pointers to the character strings forming the 
  // new argument list.
  arg_idx=1;
  while ( !(result[i] == ' ' && result[i+1] == '<' && result[i+2] == '/') )
  {
    if (result[i] == ' ' || result[i] == '\t') // split argv based on space or tab
    {
      result[i]='\0'; // terminate argumet inside result string
      i++; // move to next char
      while ( result[i] == ' ' || result[i] == '\t' ) i++; // skip any more spaces or tabs
      argv[arg_idx++]=&(result[i]); // point to start of next token
    }

    i++;
  }
  result[i]='\0';
  // (from: https://msdn.microsoft.com/en-us/library/7zt1y878.aspx)
  // The argument argv[n +1] must be a NULL pointer to mark the end of the 
  // argument list.
  argv[arg_idx]=NULL;

  // debug
  printf("command: [%s]; \narg_idx = %d\n", command, arg_idx); 
  for (i=0; i<arg_idx; i++)
  {
    printf("argv: %d [%s]\n", i, argv[i]); 
  }

  //status = _execvp(command, argv);  // will not compile with mingw
  //status = system(command); // blocks until user terminates child
                              // takes a string and passes it to shell...
  //popen(command,"r"); // takes a string and passes it to shell...
  _spawnv(P_NOWAIT, (const char *) command, (const char * const*) argv);  

  if (status < 0)
  {
    printf("Warning: can't find command: %d\n"), status;

    printf("command:[%s]\n", command);
    for (i=0; i<arg_idx; i++)
    {
      printf("argv: %d [%s]\n", i, argv[i]);
    }
    exit(EXIT_FAILURE);
  }
}


