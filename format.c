#include <assert.h>
#include "adlist.h"
#include "lex.h"
#include "sql.tab.h"
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

extern Stmt *curStmt;

void stmt(Stmt *st, int indent);

#define zprintf(x,y...) my_zprintf(indent,x,##y)

void my_zprintf(int indent, char *s, ...);

void print_expr_item(Item *i, int indent) {
	if (!i) 
		{ zprintf("NULL");} 
	else {
		if ((i->token1 == NAME) && (i->token2 == 0)) { 
			if (i->prefix && i->name && i->alias) 
				zprintf("%s.%s AS %s", i->prefix, i->name, i->alias);
			else if (i->prefix && i->name) 
				zprintf("%s.%s", i->prefix, i->name);
			else if (i->name)
				zprintf("%s", i->name);
			else {
				assert(NULL);	
			}

		} else if ((i->token1 == USERVAR) && (i->token2 == 0)) { 
			zprintf("%s", i->name); 
		} else if ((i->token1 == STRING) && (i->token2 == 0)) { 
			if (i->alias) 
				zprintf("%s.%s", i->alias, i->name); 
			else  
				zprintf("%s", i->name); 
		} else if ((i->token1 == INTNUM) && (i->token2 == 0)) { 
			zprintf("%d", i->intNum); 
		} else if ((i->token1 == APPROXNUM) && (i->token2 == 0)) { 
			zprintf("%f", i->doubleNum); 
		} else if ((i->token1 == BOOL) && (i->token2 == 0)) { 
			zprintf("%d", i->intNum); 
		} else if ((i->token1 > FSTART) && (i->token1 < FEND)) {
			zprintf("func ("); 
			if (i->right) 
				print_expr_item(i->right, indent);
			if (i->name)
				zprintf("%s", i->name); 
				
			zprintf(")"); 
		}
	}
}

void print_expr_stmt(Item *i, int indent) {
	if (!i) 
		{ zprintf("NULL");}
	else {
		if ((i->token1 == ANDOP) && (i->token2 == 0)) {
			zprintf("(\n");
			print_expr_stmt(i->left, indent + 1);
			printf("\n");
			zprintf(")\n");
			zprintf("AND\n");
			zprintf("(\n");
			print_expr_stmt(i->right, indent + 1);
			printf("\n");
			zprintf(")"); 
		} else if ((i->token1 == OR) && (i->token2 == 0)) { 
			zprintf("(\n");
			print_expr_stmt(i->left, indent + 1);
			printf("\n");
			zprintf(")\n");
			zprintf("OR\n");
			zprintf("(\n");
			print_expr_stmt(i->right, indent + 1);
			printf("\n");
			zprintf(")"); 
		} else if ((i->token1 == COMPARISON) && (i->token2 == 0)) {
			print_expr_item(i->left, indent);
			printf(" = ");
			print_expr_item(i->right, 0);
		} else if ((i->token1 == IN) && (i->token2 == SELECT)) {
			print_expr_item(i->left, indent);
			printf("\n");
			zprintf("IN (\n ");
			Stmt *ir = i->right;
			stmt(ir, indent + 1);
			zprintf(")");
		}
	} 
}	

void my_zprintf(int indent, char *s, ...) {
	va_list ap;
	va_start(ap, s);

	int i = 0;
	for (; i < indent * 4; i++) {
		fprintf(stdout, " ");
	}
	vfprintf(stdout, s, ap);
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
		//zprintf("--COLUMNS(%d) \n", listLength(stmt->select_expr_list));
		iter = listGetIterator(stmt->select_expr_list, AL_START_HEAD); 
		
		Item* i;
		while ((node = listNext(iter)) != NULL) {
			i = (Item*)listNodeValue(node);
			//zprintf("\t");
			print_expr_item(i, indent);
			zprintf("\n");
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
		zprintf("SET(%d) => \n", listLength(stmt->updateSetList));
		iter = listGetIterator(stmt->updateSetList, AL_START_HEAD);
		while ((node = listNext(iter)) != NULL) {
			Item *i = (Item*)listNodeValue(node);
			//zprintf("\t");
			print_expr_stmt(i, indent);
			zprintf("\n");
		}
		
		listReleaseIterator(iter);
		//listRelease(stmt->updateSetList);
	}
}

void group(Stmt *stmt, int indent) {
	listIter *iter, *auxIter;
	listNode *node, *auxNode;

	if (stmt->groupList && listLength(stmt->groupList)) {
		/* print group */
		iter = listGetIterator(stmt->groupList, AL_START_HEAD);

		zprintf("GROUPBY\n");
        indent++;
		//zprintf("GROUP(%d) => \n", listLength(stmt->groupList));
		while ((node = listNext(iter)) != NULL) {
			Item *i = listNodeValue(node);
			print_expr_item(i, indent);
			zprintf(",");
		}
		zprintf("\n");
		
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
		zprintf("ORDER\n");
        indent++;
		//zprintf("order(%d) => \n", listLength(stmt->orderList));
		while ((node = listNext(iter)) != NULL) {
			Item *i = listNodeValue(node);
			print_expr_item(i, indent);
			zprintf(",");
		}
		
		listReleaseIterator(iter);
		//listRelease(stmt->orderList);
	}
}

void limit(Stmt *stmt, int indent) {
	listIter *iter, *auxIter;
	listNode *node, *auxNode;

	if (stmt->limitList && listLength(stmt->limitList)) {	
		zprintf("LIMIT\n");
        indent++;
		//zprintf("limit(%d) => \n", listLength(stmt->limitList));
		iter = listGetIterator(stmt->limitList, AL_START_HEAD); 
		while ((node = listNext(iter)) != NULL) {
			Item *i = listNodeValue(node);
			print_expr_item(i, indent);
			zprintf(",");
		}
		zprintf("\n");
		
		listReleaseIterator(iter);
		//listRelease(stmt->limitList);
	}
}

void set(Stmt *stmt, int indent) {
	listIter *iter, *auxIter;
	listNode *node, *auxNode;

	if (stmt->setList && listLength(stmt->setList)) {
		iter = listGetIterator(stmt->setList, AL_START_HEAD);

		//zprintf("set(%d) => \n", listLength(stmt->setList));
		while ((node = listNext(iter)) != NULL) {
			Item *i = listNodeValue(node);
			//zprintf("\t");
			print_expr_stmt(i, indent);
			zprintf("\n");
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
		zprintf("WHERE\n");
        indent++;
		//zprintf("where(%d) => \n", listLength(stmt->whereList));
		iter = listGetIterator(stmt->whereList, AL_START_HEAD); 

		while ((node = listNext(iter)) != NULL) {
			Item *i = listNodeValue(node);
			if ((i->token1 == COMPARISON) && (i->token2 == 0)) {
				//zprintf("\t");
				print_expr_stmt(i, indent);
				zprintf("\n");
			} else if ((i->token1 == ANDOP) && (i->token2 == 0)) {
				//zprintf("\t");
				print_expr_stmt(i, indent);
				zprintf("\n");
			} else if ((i->token1 == OR) && (i->token2 == 0)) {
				//zprintf("\t");
				print_expr_stmt(i, indent);
				zprintf("\n");
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

		Table *t;
		zprintf("FROM\n");
		indent++;
		//zprintf("--TABLE(%d) => \n", listLength(st->joinList));
		while ((node = listNext(iter)) != NULL) {
			t = (Table*)listNodeValue(node);
			if (t->sub) {
				zprintf("(\n");
				stmt(t->sub, indent + 1);
				zprintf(") AS %s", t->alias);
			} else if (t->alias)
				zprintf("%s AS %s", t->name, t->alias);
			else
				zprintf("%s", t->name);

			zprintf("\n");
		}
		
		listReleaseIterator(iter);
		//listRelease(stmt->joinList);
	}
}

void stmtInit(Stmt *stmt) {
	stmt->joinList = listCreate();
	stmt->groupList = listCreate();
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
			zprintf("SELECT\n");
			selectColumn(stmt, indent + 1);
			table(stmt, indent);
			where(stmt, indent);
			group(stmt, indent);
			orderby(stmt, indent);
			limit(stmt, indent);
			break;
		case SQLCOM_SET_OPTION:
			zprintf("SET\n");
			set(stmt, indent + 1);
			break;
		case SQLCOM_UPDATE:
			zprintf("UPDATE\n");
			table(stmt, indent);
			updateColumn(stmt, indent + 1);
			where(stmt, indent);
			limit(stmt, indent);
			break;
		case SQLCOM_DELETE:
			zprintf("DELETE\n");
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
