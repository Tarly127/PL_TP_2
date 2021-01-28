run : prog in/ex.caderno
	cat in/ex.caderno | ./prog

prog : y.tab.o lex.yy.o
	gcc -o prog y.tab.o lex.yy.o -ll

y.tab.o : y.tab.c
	gcc -c y.tab.c

lex.yy.o : lex.yy.c y.tab.h
	gcc -c lex.yy.c

y.tab.c y.tab.h : cad_anot.y
	yacc -d cad_anot.y

lex.yy.c : cad_anot.l y.tab.h
	flex cad_anot.l

ex.caderno :
	cd in/
	wget https://natura.di.uminho.pt/~jj/pl-20/TP2/ontologic-wiki/ex.caderno
	cd ..

clean:
	rm -f lex.yy.* y.tab.* prog *.html out/*.html
	clear
