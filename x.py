import commands, json                                                                                       
z = commands.getoutput("./index_json test/rds-sql1.sql")  
d = json.loads(z)
#print d

""" 
        {xxxx-1:[col1,col2], xxxx-2:[col1, col3],...}

    {
        xxxx:[(col1, col2), (col1, col3)]
        ....
    }
"""
tableColumn = {}

m =  d["ins"]
for table in m:
    t = table.split("###")[0]
    s = set(m[table])

    if tableColumn.has_key(t):
        l = tableColumn[t].append(s)
    else:
        l = []
        l.append(s)
        tableColumn[t] = l

for n in tableColumn:
    print n, tableColumn[n]
