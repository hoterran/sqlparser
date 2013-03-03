#include <assert.h>
#include "adlist.h"
#include "lex.h"
#include "sql.tab.h"
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

char* tmp(int cmp) {
    if (cmp == 4)
        return "=";
    else if (cmp == 12)
        return "<=>";
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
    else
        assert(NULL);


}
extern Stmt *curStmt;

void stmt(Stmt *st, int indent);

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
		if ((i->token1 == NAME) && (i->token2 == 0)) { 
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

		} else if ((i->token1 == USERVAR) && (i->token2 == 0)) { 
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
			zprintf(indent,"func("); 
			if (i->right) {
				print_expr_item(i->right, 0);
            }
			if (i->name)
				zprintf(0,"%s", i->name); 
			zprintf(0,")"); 

            if (i->alias)
                zprintf(indent, " AS %s", i->alias);
		}
	}
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
		} else if ((i->token1 == IN) && (i->token2 == SELECT)) {
			print_expr_item(i->left, indent);
			printf("\n");
			zprintf(indent,"IN (\n ");
			Stmt *ir = i->right;
			stmt(ir, indent + 1);
			zprintf(indent,")");
		}
	} 
}	

/* 
 *	select_expr_list(list) =>
 *			select_expr, select_expr,...
 *	select_expr =>
 *			item(name, alias)
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
 *		item1,	item2, item3
 *	item1(=)
 *		item2(id)
 *		item3(4);
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
 *		item and
 *			item =
 *				item id
 *				item 4
 *			item = 
 *				item z
 *				item 3
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
			if ((i->token1 == COMPARISON)) {
				//zprintf(indent,"\t");
				print_expr_stmt(i, indent);
				zprintf(indent,"\n");
			} else if ((i->token1 == ANDOP) && (i->token2 == 0)) {
				//zprintf(indent,"\t");
				print_expr_stmt(i, indent);
				zprintf(indent,"\n");
			} else if ((i->token1 == OR) && (i->token2 == 0)) {
				//zprintf(indent,"\t");
				print_expr_stmt(i, indent);
				zprintf(indent,"\n");
			}
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

        if (st->sql_command != SQLCOM_UPDATE) {
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
			} else if (t->alias)
				zprintf(indent,"%s AS %s", t->name, t->alias);
			else
				zprintf(indent,"%s", t->name);

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
}

void stmt(Stmt *stmt, int indent) {
	listIter *iter, *auxIter;
	listNode *node, *auxNode;

	switch(stmt->sql_command) {
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

	if(!yyparse()) {
		printf("SQL parse worked\n");
		printf("================\n");
    } else
		printf("SQL parse failed\n");

	Stmt *st = curStmt;
	stmt(st, 0);

	return 0;
} 
