#include "../syscalls.h";
#define array2 [17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1];
sys array.dynamic.new 17,%B;
sys array.getBody %B,%A;
inc %A;
sys mem.copy &array2, %A, 17;
dec %A;
write 17,%A;
sys array.slice %B,5,9,%A;
sys sys.printNum %A;
sys sys.printAscii 10;
sys array.splice %B,5,9,%A;
sys sys.printNum %B;
bp;
exit;