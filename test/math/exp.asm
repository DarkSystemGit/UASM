#include "../syscalls.h";
#include "numberprinter.asm";
#define number 25;
#define str1 "Starting Number: ";
#define str2 "Number Squared: ";
#define str3 "Sqrt: ";
#define str4 "Cube Root: ";
#define str5 "Log of number: ";
push &str1;
push number;
call print;
push &str2;
sys math.pow number,2,%F;
push %F;
call print;
push &str3;
sys math.sqrt number,%F;
push %F;
call print;
push &str4;
sys math.cbrt number,%F;
push %F;
call print;
push &str5;
sys math.log number,%F;
push %F;
call print;