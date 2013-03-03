sqlparser
=========

a sql parser



## compile

	make

## use
	cat test/test.sql
	select trim("aaa"), a,b,c, count(*), sum(*), sum(d), avg(z), curdate(), curtime() from tab b limit 2;

	./format test/test.sql


