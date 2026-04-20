variable resultado
0 resultado !
variable n
0 n !
: main
7 n !
1 resultado !
begin n @ 1 >  while 
resultado @ n @ * resultado !
n @ 1 - n !
repeat
resultado @ . 
;
