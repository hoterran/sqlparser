select a.id, b.id, c.name from a, b where id = name group by xxx, zzz, ddd having count(*) > 1 order by a desc,b asc ,c desc limit 1;
