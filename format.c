#include <assert.h>
#include "adlist.h"
#include "sql.h"
#include "sql.tab.h"
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

#include "func.h"

char funcArray[FEND];

char* tmp(int cmp) {
    if (cmp == 4)
        return "=";
    else if (cmp == 12)
        return "!=";
    else if (cmp == 6)
        return ">=";
    else if (cmp == 2)
        return ">";
    else if (cmp == 5)
        return "<=";
    else if (cmp == 1)
        return "<";
    else if (cmp == 3)
        return "<>";
    else if (cmp == SUB_OP)
        return "-";
    else if (cmp == ADD_OP)
        return "+";
    else if (cmp == MUL_OP)
        return "*";
    else if (cmp == DIV_OP)
        return "/";
    else if (cmp == LIKE)
        return "LIKE";
    else if (cmp == REGEXP)
        return "REGEXP";
    else if (cmp == NOT) 
        return "NOT";
    else if (cmp == NULLX) 
        return "NULL";
    else if (cmp == ANDOP) 
        return "AND";
    else if (cmp == OR) 
        return "OR";
    else if (cmp == WHEN) 
        return "WHEN";
    else if (cmp == THEN) 
        return "THEN";
    else
        assert(NULL);
}
extern Stmt *stmtArray[100];
extern int indexArray;

void stmt(Stmt *st, int indent);
void print_list(list *l, int indent);
void print_list2 (list *l, int indent);

void zprintf(int indent, char *s, ...) {
    va_list ap;
    va_start(ap, s);

    int i = 0;
    for (; i < indent * 4; i++) {
        fprintf(stdout, " ");
    }
    vfprintf(stdout, s, ap);
}

void print_expr_item(Item *i, int indent) {
    if (!i) 
        { zprintf(indent,"NULL");} 
    else {
        if ((i->token1 == NAME)) { 
            if (i->token2 == GLOBAL)
                zprintf(indent,"GLOBAL ");
            else if (i->token2 == SESSION) 
                zprintf(indent,"SESSION ");
            
            if (i->prefix && i->name && i->alias)
                zprintf(indent,"%s.%s AS %s", i->prefix, i->name, i->alias);
            else if (i->prefix && i->name)
                zprintf(indent,"%s.%s", i->prefix, i->name);
            else if (i->alias && i->name)
                zprintf(indent, "%s AS %s", i->name, i->alias);
            else 
                zprintf(indent,"%s", i->name);

            if (i->right) {
                zprintf(0, ",");
                print_expr_item(i->right, 0);
            }

        } else if ((i->token1 == USERVAR)) { 
            if (i->token2 == GLOBAL)
                zprintf(indent,"GLOBAL ");
            else if (i->token2 == SESSION) 
                zprintf(indent,"SESSION ");
            zprintf(indent,"%s", i->name); 
        } else if ((i->token1 == STRING) && (i->token2 == 0)) { 
            if (i->prefix && i->name && i->alias)
                zprintf(indent,"%s.%s AS %s", i->prefix, i->name, i->alias);
            else if (i->prefix && i->name)
                zprintf(indent,"%s.%s", i->prefix, i->name);
            else if (i->alias && i->name)
                zprintf(indent, "%s AS %s", i->name, i->alias);
            else 
                zprintf(indent,"%s", i->name);

            if (i->right) {
                zprintf(0, ",");
                print_expr_item(i->right, 0);
            }
        } else if ((i->token1 == INTNUM) && (i->token2 == 0)) { 
            if (i->prefix && i->alias)
                zprintf(indent,"%s.%d AS %s", i->prefix, i->intNum, i->alias);
            else if (i->prefix)
                zprintf(indent,"%s.%d", i->prefix, i->intNum);
            else if (i->alias)
                zprintf(indent, "%d AS %s", i->intNum, i->alias);
            else 
                zprintf(indent,"%d", i->intNum);

            if (i->right) {
                zprintf(0, ",");
                print_expr_item(i->right, 0);
            }

        } else if ((i->token1 == APPROXNUM) && (i->token2 == 0)) { 
            if (i->prefix && i->alias)
                zprintf(indent,"%s.%f AS %s", i->prefix, i->doubleNum, i->alias);
            else if (i->prefix)
                zprintf(indent,"%s.%f", i->prefix, i->doubleNum);
            else if (i->alias)
                zprintf(indent, "%f AS %s", i->doubleNum, i->alias);
            else 
                zprintf(indent,"%f", i->doubleNum);

            if (i->right) {
                zprintf(0, ",");
                print_expr_item(i->right, 0);
            }
        } else if ((i->token1 == BOOL) && (i->token2 == 0)) { 
            zprintf(indent,"%d", i->intNum); 

            if (i->right) {
                zprintf(0, ",");
                print_expr_item(i->right, 0);
            }
        } else if ((i->token1 > FSTART) && (i->token1 < FEND)) {
            zprintf(indent, FUNCNAME(i->token1)); 
            zprintf(0,"("); 
            if (i->right) {
                print_list(i->right, 0);
            }
            if (i->name)
                zprintf(0,"%s", i->name); 
            zprintf(0,")"); 

            if (i->alias)
                zprintf(indent, " AS %s", i->alias);
        } else if ((i->token1 == ADD_OP)
            || (i->token1 == SUB_OP)
            || (i->token1 == DIV_OP)
            || (i->token1 == MUL_OP)
            || (i->token1 == ANDOP)
            || (i->token1 == OR)
        ) {
            print_expr_item(i->left, indent);
            if (i->token2)
                printf(" %s ", tmp(i->token2));
            printf(" %s ", tmp(i->token1));
            print_expr_item(i->right, 0);
        } else if ((i->token1 == COMPARISON)) {
            print_expr_item(i->left, indent);
            printf(" %s ", tmp(i->token2));
            print_expr_item(i->right, 0);
        } else if ((i->token1 == CASE)) {
            zprintf(indent, "CASE ");
            if (i->left) {
                print_expr_item(i->left, 0);
            } 
            if (i->next) {
                print_list2(i->next, 0);
            }
            if (i->right) {
                printf( " ELSE ");
                print_expr_item(i->right, 0);
            }
            printf(" END");
            if (i->alias)
                zprintf(0," AS %s", i->alias);

        } else if ((i->token1 == ELSE)) {
            printf(" %s ", tmp(i->token1));
            print_expr_item(i, 0);
        } else if ((i->token1 == WHEN)) {
            printf("%s ", tmp(i->token1));
            print_expr_item(i->left, 0);
        } else if ((i->token1 == THEN)) {
            printf(" %s ", tmp(i->token1));
            print_expr_item(i->left, 0);
        } else {
            printf("%d - %d", i->token1, i->token2); 
            assert(NULL); 
        }
    }
}

void print_list2 (list *l, int indent) {
    if (!l) return;
    if (listLength(l) == 0) return ;

    listIter *iter = NULL;
    listNode *node = NULL;
    //printf("-----%d", listLength(l));
    zprintf(indent, "");
    iter = listGetIterator(l, AL_START_HEAD); 
    while ((node = listNext(iter)) != NULL) {
        Item *i = listNodeValue(node);
        print_expr_item(i, 0);
    }
    listReleaseIterator(iter);
}

void print_list(list *l, int indent) {
    if (!l) return;
    if (listLength(l) == 0) return ;

    listIter *iter = NULL;
    listNode *node = NULL;
    //printf("-----%d", listLength(l));
    zprintf(indent, "");
    iter = listGetIterator(l, AL_START_HEAD); 
    while ((node = listNext(iter)) != NULL) {
        Item *i = listNodeValue(node);
        print_expr_item(i, 0);
        if (listNextNode(node))
            printf(", ");
            
    }
    listReleaseIterator(iter);
}

void print_expr_stmt(Item *i, int indent) {
    if (!i) 
        { zprintf(indent,"NULL");}
    else {
        if ((i->token1 == ANDOP) && (i->token2 == 0)) {
            zprintf(indent,"(\n");
            print_expr_stmt(i->left, indent + 1);
            printf("\n");
            zprintf(indent,")\n");
            zprintf(indent,"AND\n");
            zprintf(indent,"(\n");
            print_expr_stmt(i->right, indent + 1);
            printf("\n");
            zprintf(indent,")"); 
        } else if ((i->token1 == OR) && (i->token2 == 0)) { 
            zprintf(indent,"(\n");
            print_expr_stmt(i->left, indent + 1);
            printf("\n");
            zprintf(indent,")\n");
            zprintf(indent,"OR\n");
            zprintf(indent,"(\n");
            print_expr_stmt(i->right, indent + 1);
            printf("\n");
            zprintf(indent,")"); 
        } else if ((i->token1 == COMPARISON)) {
            print_expr_item(i->left, indent);
            printf(" %s ", tmp(i->token2));
            print_expr_item(i->right, 0);
        } else if ((i->token1 == NULLX)) {
            print_expr_item(i->left, indent);
            if (i->token2 == NOT) 
                printf(" IS NOT");
            else if (i->token2 == 0)
                printf(" IS ");
            else 
                printf(" %s ", tmp(i->token2));

            printf(" %s ", tmp(i->token1));
        } else if ((i->token1 == IN) && (i->token2 == SELECT)) {
            /* in ( select... ) */
            print_expr_item(i->left, indent);
            printf("\n");
            zprintf(indent,"IN (\n "); Stmt *ir = i->right; stmt(ir, indent + 1);
            zprintf(indent,")");
        } else if ((i->token1 == NOT) && (i->token2 == SELECT)) {
            /* in ( select... ) */
            print_expr_item(i->left, indent);
            printf("\n");
            zprintf(indent,"NOT IN (\n ");
            Stmt *ir = i->right;
            stmt(ir, indent + 1);
            zprintf(indent,")");
        } else if ((i->token1 == IN) && (i->token2 == 0)) {
            /* in (1, 2, 3) */
            print_expr_item(i->left, indent);
            printf("\n");
            zprintf(indent,"IN (\n ");
            list *ir = i->right;
            // list 
            print_list(ir, indent + 1);
            printf("\n");
            zprintf(indent,")");
        } else if ((i->token1 == NOT) && (i->token2 == IN)) {
            /* not in (1, 2, 3) */
            print_expr_item(i->left, indent);
            printf("\n");
            zprintf(indent,"NOT IN (\n ");
            list *ir = i->right;
            // list 
            print_list(ir, indent + 1);
            printf("\n");
            zprintf(indent,")");
        } else if ((i->token1 == LIKE) || (i->token1 == REGEXP)) {
            print_expr_item(i->left, indent);
            if (i->token2)
                printf(" %s ", tmp(i->token2));
            printf(" %s ", tmp(i->token1));
            print_expr_item(i->right, 0);
        } else if ((i->token1 == NAME) && (i->token2 == 0)) {
            /* 'where 1' stmt*/
            zprintf(indent,"%s", i->name);
        } else if ((i->token1 > FSTART) && (i->token1 < FEND)) {
            zprintf(indent, FUNCNAME(i->token1)); 
            zprintf(0,"("); 
            if (i->right) {
                print_list(i->right, 0);
            }
            if (i->name)
                zprintf(0,"%s", i->name); 
            zprintf(0,")"); 

            if (i->alias)
                zprintf(indent, " AS %s", i->alias);
        } else {
            printf("%d - %d", i->token1, i->token2); 
            assert(NULL); 
        }
    } 
}    

/* 
 *    select_expr_list(list) =>
 *            select_expr, select_expr,...
 *    select_expr =>
 *            item(name, alias)
*/
void selectColumn(Stmt* stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->select_expr_list && listLength(stmt->select_expr_list)) {
        //zprintf(indent,"--COLUMNS(%d) \n", listLength(stmt->select_expr_list));
        iter = listGetIterator(stmt->select_expr_list, AL_START_HEAD); 
        
        Item* i;
        while ((node = listNext(iter)) != NULL) {
            i = (Item*)listNodeValue(node);
            //zprintf(indent,"\t");
            print_expr_item(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->select_expr_list);
    }
}

/* updateSetList(list) set id = 4, name = "ddd"
 *        item1,    item2, item3
 *    item1(=)
 *        item2(id)
 *        item3(4);
 *  item(=)
 */
void updateColumn(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->updateSetList && listLength(stmt->updateSetList)) {
        //zprintf(indent,"SET(%d) => \n", listLength(stmt->updateSetList));
        zprintf(indent, "SET\n");
        indent++;
        iter = listGetIterator(stmt->updateSetList, AL_START_HEAD);
        while ((node = listNext(iter)) != NULL) {
            Item *i = (Item*)listNodeValue(node);
            //zprintf(indent,"\t");
            print_expr_stmt(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->updateSetList);
    }
}

void having(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->havingList && listLength(stmt->havingList)) {
        /* print group */
        iter = listGetIterator(stmt->havingList, AL_START_HEAD);

        zprintf(indent,"HAVING \n");
        indent++;
        //zprintf(indent,"GROUP(%d) => \n", listLength(stmt->groupList));
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            print_expr_stmt(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->groupList);
    }
}

void groupby(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->groupList && listLength(stmt->groupList)) {
        /* print group */
        iter = listGetIterator(stmt->groupList, AL_START_HEAD);

        zprintf(indent,"GROUPBY\n");
        indent++;
        //zprintf(indent,"GROUP(%d) => \n", listLength(stmt->groupList));
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            print_expr_item(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->groupList);
    }
}

void orderby(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->orderList && listLength(stmt->orderList)) {
        /* print order */
        iter = listGetIterator(stmt->orderList, AL_START_HEAD);
        zprintf(indent,"ORDER BY\n");
        indent++;
        //zprintf(indent,"order(%d) => \n", listLength(stmt->orderList));
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            print_expr_item(i, indent);
            if (i->isDesc == 1) {
                printf(" DESC"); 
            }
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->orderList);
    }
}

void insertColumn(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->insertList && listLength(stmt->insertList)) {
        /* print order */
        iter = listGetIterator(stmt->insertList, AL_START_HEAD);
        zprintf(indent,"(\n");
        indent++;
        //zprintf(indent,"order(%d) => \n", listLength(stmt->orderList));
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            print_expr_item(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        indent--;
        zprintf(indent, ")\n");
        
        listReleaseIterator(iter);
        //listRelease(stmt->orderList);
    }
}
    /*
        1.
            list (1,2), (3, 4)
                list (1,2)
                    item 1
                    item 2
                list (3, 4)
                    item 3
                    item 4
        2. select

    */
void valueColumn(Stmt *st, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (st->valueSelect) {
        stmt(st->valueSelect, indent); 
    };

    if (st->valueList && listLength(st->valueList)) {
        /* print order */
        iter = listGetIterator(st->valueList, AL_START_HEAD);
        zprintf(indent,"VALUES\n");
        indent++;
        //zprintf(indent,"order(%d) => \n", listLength(stmt->orderList));
        while ((node = listNext(iter)) != NULL) {
            list *l = listNodeValue(node);
            auxIter = listGetIterator(l, AL_START_HEAD);
            zprintf(indent, "(");
            while ((auxNode = listNext(auxIter)) != NULL) {
                Item *i = listNodeValue(auxNode);
                print_expr_item(i, 0);
                if (listNextNode(auxNode))
                    printf(",");
            }
            if (listNextNode(node))
                zprintf(0, "),\n");
        }
        zprintf(0, ")\n");
        
        listReleaseIterator(iter);
    }
}

void limit(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->limitList && listLength(stmt->limitList)) {    
        zprintf(indent,"LIMIT\n");
        indent++;
        //zprintf(indent,"limit(%d) => \n", listLength(stmt->limitList));
        iter = listGetIterator(stmt->limitList, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            print_expr_item(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->limitList);
    }
}

void set(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->setList && listLength(stmt->setList)) {
        iter = listGetIterator(stmt->setList, AL_START_HEAD);
        indent++;
        //zprintf(indent,"set(%d) => \n", listLength(stmt->setList));
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            //zprintf(indent,"\t");
            if (i->token1 == SETNAMES) {
                zprintf(indent, "NAMES ");           
                Item *i2 = listNodeValue(listNext(iter));
                zprintf(indent, "%s", i2->name);
                break;
            } else if (i->token1 == SETPASSWORD) {
                zprintf(indent, "PASSWORD = ");
                Item *i2 = listNodeValue(listNext(iter));
                print_expr_stmt(i2, indent);
                break;
            } else if (i->token1 == SETCHARACTER) {
                zprintf(indent, "CHARACTER SET ");           
                Item *i2 = listNodeValue(listNext(iter));
                zprintf(indent, "%s", i2->name);
                break;
            }

            if (i->token2 == GLOBAL)
                zprintf(indent,"GLOBAL ");
            else if (i->token2 == SESSION) 
                zprintf(indent,"SESSION ");

            print_expr_stmt(i, indent);
            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->setList);
    }
}

/*
 * whereList(id = 4 and z = 3)
 *        item and
 *            item =
 *                item id
 *                item 4
 *            item = 
 *                item z
 *                item 3
*/

void where(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (stmt->whereList && listLength(stmt->whereList)) {    
        zprintf(indent,"WHERE\n");
        indent++;
        //zprintf(indent,"where(%d) => \n", listLength(stmt->whereList));
        iter = listGetIterator(stmt->whereList, AL_START_HEAD); 

        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
                print_expr_stmt(i, indent);
                zprintf(indent,"\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->whereList);
    }
}

void table(Stmt *st, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    if (st->joinList && listLength(st->joinList)) {
        iter = listGetIterator(st->joinList, AL_START_HEAD);
        /* select and delete has FROM keyword */
        if ((st->sql_command == SQLCOM_SELECT) ||
            (st->sql_command == SQLCOM_DELETE)
            ) {
            zprintf(indent, "FROM\n");
        };
        indent++;

        Table *t;
        //zprintf(indent,"--TABLE(%d) => \n", listLength(st->joinList));
        while ((node = listNext(iter)) != NULL) {
            t = (Table*)listNodeValue(node);
            if (t->sub) {
                zprintf(indent,"(\n");
                stmt(t->sub, indent + 1);
                zprintf(indent,") AS %s", t->alias);
            } else if (t->alias) {
                if (t->db)
                    zprintf(indent,"%s.%s AS %s", t->db, t->name, t->alias);
                else
                    zprintf(indent,"%s AS %s",t->name, t->alias);
            }
            else {
                if (t->db)
                    zprintf(indent,"%s.%s", t->db, t->name);
                else
                    zprintf(indent,"%s", t->name);
            }

            if (listNextNode(node)) 
                printf(",\n");
            else
                printf("\n");
        }
        
        listReleaseIterator(iter);
        //listRelease(stmt->joinList);
    }
}

void stmtInit(Stmt *stmt) {
    stmt->joinList = listCreate();
    stmt->groupList = listCreate();
    stmt->havingList = listCreate();
    stmt->orderList = listCreate();
    stmt->limitList = listCreate();
    stmt->setList = listCreate();
    stmt->updateSetList = listCreate();
    stmt->select_expr_list = listCreate();
    stmt->whereList = listCreate();
    stmt->insertList = listCreate();
    stmt->valueList  = listCreate();
    stmt->usingList = listCreate();
}

void show (Stmt *st, int indent, char *s) {
    Item *i = st->show;
    if (i->token1 == GLOBAL)
        zprintf(indent,"GLOBAL ");
    else if (i->token1 == SESSION) 
        zprintf(indent,"SESSION ");

    if (i->name) {
        zprintf(indent,"%s LIKE %s;", s, i->name);
    } else {
        zprintf(indent,"%s ", s);
        where(st, indent);
        zprintf(indent,";");
    }
    zprintf(0, "\n");
}

void stmt(Stmt *stmt, int indent) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;

    switch(stmt->sql_command) {
        case SQLCOM_USE:
            zprintf(indent,"USE ");
            print_expr_item(stmt->use, 0);

            break;
        case SQLCOM_SHOW_VARIABLES:
            zprintf(indent,"SHOW ");
            show(stmt, 0, "VARIABLES ");

            break;
        case SQLCOM_SHOW_COLLATIONS:
            zprintf(indent,"SHOW ");
            show(stmt, 0, "COLLATIONS ");

            break;
        case SQLCOM_SHOW_TABLES:
            zprintf(indent,"DESC ");
            print_expr_item(stmt->desc, 0);
            break;

        case SQLCOM_SHOW_FIELDS:
            zprintf(indent,"DESC ");
            print_expr_item(stmt->desc, 0);
            break;

        case SQLCOM_SELECT:
            zprintf(indent,"SELECT\n");
            selectColumn(stmt, indent + 1);
            table(stmt, indent);
            where(stmt, indent);
            groupby(stmt, indent);
            having(stmt, indent);
            orderby(stmt, indent);
            limit(stmt, indent);
            break;
        case SQLCOM_SET_OPTION:
            zprintf(indent,"SET\n");
            set(stmt, indent);
            break;
        case SQLCOM_UPDATE:
            zprintf(indent,"UPDATE\n");
            table(stmt, indent);
            updateColumn(stmt, indent);
            where(stmt, indent);
            limit(stmt, indent);
            break;
        case SQLCOM_DELETE:
            zprintf(indent,"DELETE\n");
            table(stmt, indent);
            where(stmt, indent);
            limit(stmt, indent);
            break;
        case SQLCOM_INSERT:
            zprintf(indent,"INSERT INTO\n");
            table(stmt, indent);
            insertColumn(stmt, indent);
            valueColumn(stmt, indent);
            break;
        case SQLCOM_REPLACE:
            zprintf(indent,"REPLACE INTO\n");
            table(stmt, indent);
            insertColumn(stmt, indent);
            valueColumn(stmt, indent);
            break; 
        default:
            break;
    }
}

int main(int ac, char **av)
{
    extern FILE *yyin;

    if(ac > 1 && !strcmp(av[1], "-d")) {
         ac--; av++;
    }

    if(ac > 1 && (yyin = fopen(av[1], "r")) == NULL) {
        perror(av[1]);
        exit(1);
    }

    /* for big file */
    yypush_buffer_state(yy_create_buffer( yyin, 1000000));
    yyparse();

    convert();
    int i = 0, j = 0;
    for (i = 0; i < indexArray; i++) {
        if (stmtArray[i] == NULL)
            j++;
    }
    
    printf("<<<<<<  This file has %d sql, success %d, failure %d >>>>>\n", indexArray, indexArray-j, j);

    printf("\n-------------------------------------------------------------------------\n");
    for (i = 0; i < indexArray; i++) {
        Stmt *st = stmtArray[i];
        if (st) {
            stmt(st, 0); 
            printf("-------------------------------------------------------------------------\n");
        } else {
            printf("SQL parse failed\n");
        }
    }

    return 0;
} 
