for i in `ls test/test*.sql`
do
	echo "-------------$i-------------------"
	cat $i
	echo "----------------------------------"
	./format $i
done 
