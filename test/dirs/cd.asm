#define cddir "./testdir";
#define original "./../";
#include "./../syscalls.h";
sys sys.cd &cddir;
sys 11,30;
sys 2,30;
sys sys.cd &original;
exit;
