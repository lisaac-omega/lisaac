#include <stdlib.h>
extern void print_integer(long n);
extern int print_string(char *str);
//extern
typedef struct ___CONTEXT_struct _____CONTEXT;
struct ___CONTEXT_struct {
  unsigned long code; 
  _____CONTEXT *back; 
};
extern _____CONTEXT *top_context; 
extern char *trace[];

void lisaac_stack_print(long step)
{ _____CONTEXT *next;              
  int j;	
  next = top_context;
  j = 0;
  print_string("================ TOP ==(BUG VERSION)===\n"); 
  while ((j < 20) && (next != (void *)0)) {                
    print_string("Line #");                
    print_integer(next->code >> 17);         
    print_string(" Column #");             
    print_integer((next->code >> 9) & 0xFF); 
    print_string(" in ");                  
    print_string(trace[next->code & 0x1FF]); 
    print_string(".\n");                  
    next = next -> back;
    j++;
  };                                         
  print_string("\n============== BOTTOM ==(BUG VERSION)===\n"); 
  //if (j > 10) exit(0);
  top_context = (void *)0;                   
}                                            
