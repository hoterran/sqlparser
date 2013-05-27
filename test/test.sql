select trim("aaa"), a,b,c, count(1), sum(*), sum(d), 
--test
substr(b.c, 1,2),
avg(z), curdate(), curtime() from tab b limit 2;

