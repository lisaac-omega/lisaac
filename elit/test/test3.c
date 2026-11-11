
#include <stdio.h>

unsigned char txt[] = "˙";

int main()
{ 
printf("Self: %x \n,",((unsigned short *)txt)[0]);
return 0;
}