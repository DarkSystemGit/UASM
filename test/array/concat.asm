#include "../syscalls.h";
#define array2 [17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1];
#define insertArr [5,636362,0x12345];
sys array.new 3,%C;
sys array.dynamic.new 17,%B;
sys array.getBody %B,%A;
inc %A;
sys mem.copy &array2, %A, 17;
dec %A;
write 17,%A;
sys array.data %C,%A;
sys mem.copy &insertArr, %A, 3;
dec %A;
write 3,%A;
sys array.print %B;
sys array.print %C;
sys array.concat %B,%C;
sys array.print %B;
exit;