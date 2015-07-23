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

/** 
 * <EN>
 * @brief  Process a recognition result (best string)
 *
 * This function will be called each time after recognition of an
 * utterance is finished.  The best recognition result for the
 * utterance will be passed to this function, as a string in which
 * words are separated by white space.  When the recognition was failed
 * or rejected, string will be NULL.
 *
 * On short-pause segmentation mode or GMM/Decoder-VAD mode, where
 * an input utterance may be segmented into pieces, this funtion will be
 * called for each segment.  On multi decoding, the best hypothesis among
 * all the recognition instance will be given.
 * 
 * @param result_str [in] recognition result, words separated by whitespace,
 * or NULL on failure
 * 
 * </EN>
 * 
 */
// to compile: clear && gcc -shared    result.c   -o result.jpi -fPIC
// to run: clear && ./julius -input mic -C voxshell.jconf -plugindir plugin -quiet

void result_best_str(char *result_str)
{
  pid_t pid; // process id
  if (result_str == NULL) {
    printf("[null result]\n");
  } else {
    pid = fork();
    if (pid < 0) {
      perror("fork error");
      exit(EXIT_FAILURE);
    }
    if(pid > 0) // parent
    {
      wait(NULL);
    } 
    else // child
    {
      child(result_str);
    }
  }
}

void child(char *result)
{
  int status;
  int i;
  int token_idx;
  int nxt_token_start; // starts after "sentence1: <s> COMP "
  char *tokens[100]; // array of pointers to strings (char arrays)
                    // - exec wants command in this format

  token_idx=0;
  i=8; // skip "<s> APP "
  nxt_token_start=i;
  while ( result[i] != '<' && result[i] != '\0' ) // stops before "</s>"
  {
    if (result[i] == ' ' || result[i] == '\t') // split tokens based on space or tab
    {
      tokens[token_idx]=&(result[nxt_token_start]); // point to start of token
      result[i]='\0'; // terminate token inside result string

      i++;
      while ( result[i] == ' ' || result[i] == '\t' ) 
      {      
        i++; // skip spaces or tabs, if any
      }
      token_idx++;
      nxt_token_start=i;
    }
   
    i++;
  }
  tokens[token_idx]='\0';

  // debug
  for (i=0; i<token_idx; i++)
  {
    printf("tokens: %d [%s]\n", i, tokens[i]); 
  }

  
  status = execvp(tokens[0], tokens); 
  if (status < 0)
  {
    printf("Warning: can't find command: [%s]\n", tokens[0]);
    exit(EXIT_FAILURE);
  }
}


