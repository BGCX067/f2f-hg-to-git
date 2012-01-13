/*********************************************************************
* Copyright (c) 2003, Impulse Accelerated Technologies, Inc.
* All Rights Reserved.
*
* co_process.c: Functions for creating and executing processes.
*
* $Id: co_process.c,v 1.1 2009/02/02 22:51:33 mei.xu Exp $
*
*********************************************************************/

#include "co.h"

#include <malloc.h>
#include <stdarg.h>
#include <string.h>

co_process firstProcess;
co_process tailProcess = NULL;

co_process co_process_create(char * name, co_function run, int argc, ...)
{
	va_list ap;
	void ** args;
	int i;
	co_process theProcess;
	
	theProcess = malloc(sizeof(co_process_t));
	if (theProcess == NULL) {
	  printf("malloc failed!");
	  return(NULL);
	}
	theProcess->name = strdup(name);
	theProcess->run = run;
	theProcess->next = NULL;

	va_start(ap, argc);
 	args = (void **) malloc(sizeof(void*)*argc);
	if (args == NULL) {
	  printf("malloc failed!");
	  return(NULL);
	}
	for ( i = 0; i < argc; i++ ) {
		args[i] = va_arg(ap, void *);	
	}
	va_end(ap);
	
	theProcess->argc = argc;
	theProcess->args = args;

	if (tailProcess!=NULL)
 		tailProcess->next = theProcess;
	else
		firstProcess = theProcess;
	
	tailProcess = theProcess;

	return theProcess;
}

void co_execute(co_architecture arch)
{
	co_process theProcess;

	for (theProcess = firstProcess; theProcess != NULL ; theProcess=theProcess->next) {
	    switch (theProcess->argc) {
  		case 0:
    	    (theProcess->run)();
    	    break;
  		case 1:
    	    (theProcess->run)(theProcess->args[0]);
    		break;
  		case 2:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1]);
    		break;
  		case 3:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2]);
    		break;
  		case 4:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3]);
    		break;
  		case 5:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4]);
    		break;
  		case 6:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5]);
    		break;
  		case 7:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6]);
    		break;
  		case 8:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7]);
    		break;
  		case 9:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8]);
    		break;
  		case 10:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9]);
    		break;
  		case 11:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9],theProcess->args[10]);
    		break;
  		case 12:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9],theProcess->args[10],theProcess->args[11]);
    		break;
  		case 13:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9],theProcess->args[10],theProcess->args[11],
							  theProcess->args[12]);
    		break;
  		case 14:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9],theProcess->args[10],theProcess->args[11],
							  theProcess->args[12],theProcess->args[13]);
    		break;
  		case 15:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9],theProcess->args[10],theProcess->args[11],
							  theProcess->args[12],theProcess->args[13],theProcess->args[14]);
    		break;
  		case 16:
    		(theProcess->run)(theProcess->args[0],theProcess->args[1],theProcess->args[2],theProcess->args[3],
							  theProcess->args[4],theProcess->args[5],theProcess->args[6],theProcess->args[7],
							  theProcess->args[8],theProcess->args[9],theProcess->args[10],theProcess->args[11],
							  theProcess->args[12],theProcess->args[13],theProcess->args[14],theProcess->args[15]);
    		break;
		}
    }
}
