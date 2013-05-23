#include <assert.h>
#include "adlist.h"
#include "sql.h"
#include "sql.tab.h"
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

typedef struct Tab {
    char *alias;
    char *name;
    list *columns;
} Tab;

extern Stmt *curStmt;

void stmt(Stmt *st, int indent);

void loop_expr_item(Item *i, list *tabs) {
    listNode *node;
    Tab *tab;

    if (!i) 
        { return; } 
    else {
        if ((i->token1 == NAME) && (i->token2 == 0)) { 
            if (i->prefix) {
                node = listSearchKey(tabs, i->prefix);
                if (!node) {
                    printf("need prefix\n");
                    return ;
                }
                tab = listNodeValue(node);
                if(!listSearchKey(tab->columns, i->name)) {
                    listAddNodeTail(tab->columns, i->name);
                }
            } else {
                printf("need prefix\n");
            }
            /*
                only use function
            if (i->right) {
                zprintf(0, ",");
                loop_expr_item(i->right, 0);
            }
            */

        } else if ((i->token1 == USERVAR) && (i->token2 == 0)) { 
            return ;
        } else if ((i->token1 == STRING) && (i->token2 == 0)) { 
            return ;
        } else if ((i->token1 == INTNUM) && (i->token2 == 0)) { 
            return ;
        } else if ((i->token1 == APPROXNUM) && (i->token2 == 0)) { 
            return ;
        } else if ((i->token1 == BOOL) && (i->token2 == 0)) { 
            return ;
        } else if ((i->token1 > FSTART) && (i->token1 < FEND)) {
            return ;
        } else if ((i->token1 == ADD_OP)
            || (i->token1 == SUB_OP)
            || (i->token1 == DIV_OP)
            || (i->token1 == MUL_OP)
        ) {
            return ;
        } else {
            assert(NULL); 
        }
    }
}

void loop_expr_stmt(Item *i, list *tabs) {
    if (!i) 
        { return ;}
    else {
        if ((i->token1 == ANDOP) && (i->token2 == 0)) {
            loop_expr_stmt(i->left, tabs);
            loop_expr_stmt(i->right, tabs);
        } else if ((i->token1 == OR) && (i->token2 == 0)) { 
            loop_expr_stmt(i->left, tabs);
            loop_expr_stmt(i->right, tabs);
        } else if ((i->token1 == COMPARISON)) {
            loop_expr_item(i->left, tabs);
            loop_expr_item(i->right, tabs);
        } else if ((i->token1 == NULLX)) {
            return;
            /* skip */
        } else if ((i->token1 == IN) && (i->token2 == SELECT)) {
            return;
            /* skip select */
        } else if ((i->token1 == IN) && (i->token2 == 0)) {
            return;
            /* in (1, 2, 3) */
        } else if ((i->token1 == LIKE) || (i->token1 == REGEXP)
        ) {
            return;
            /* skip */
        } else {
           assert(NULL); 
        }
    } 
}    
/*
    create index Table_IndexName1_IndexName2_ind 
    on Table(indexName1, indexName2);
*/
void generateIndex(char *table, list *columns) {
    listIter *iter;
    listNode *node;
    char s[128] = {};

    if (columns && listLength(columns)) {
        iter = listGetIterator(columns, AL_START_HEAD); 
        snprintf(s, sizeof(s), "create index index_%s", table);
        while ((node = listNext(iter)) != NULL) {
            /* column */
            char *c = listNodeValue(node);
            snprintf(s + strlen(s), sizeof(s), "_%s", c);
        }

        listReleaseIterator(iter);
        snprintf(s + strlen(s), sizeof(s), " on %s(", table);

        iter = listGetIterator(columns, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            /* column */
            char *c = listNodeValue(node);
            snprintf(s + strlen(s), sizeof(s), "%s", c);
            if (listNextNode(iter))
                snprintf(s + strlen(s), sizeof(s), "%s", ", ");
        }

        listReleaseIterator(iter);
        snprintf(s + strlen(s), sizeof(s), "%s", ");");
    }
    printf("%s\n", s);
};

/*
 *    tab1 t, tab2  -> t tab2
 */

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
int columnMatch(void *ptr, void *key) {
    char *user = (char*)key;
    char *column = (char*) ptr;
    if (0 == strcmp(user, column))
        return 1;
    else 
        return 0;
}

int tabMatch(void *ptr, void *key) {
    char *user = (char*)key;
    Tab *listValue = (Tab*)ptr;
    if (0 == strcmp(user, listValue->alias))
        return 1;
    else 
        return 0;
}

list *generateTable(Stmt *st) {
    
    listIter *iter;
    listNode *node;
    Table *t;

    list *tabs = listCreate();
    tabs->match = tabMatch;

    if (st->joinList && listLength(st->joinList)) {
        iter = listGetIterator(st->joinList, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            t = (Table*)listNodeValue(node);
    
            Tab *tab = calloc(1, sizeof(*tab));
            tab->columns = listCreate(); 
            tab->columns->match = columnMatch;
            /* alias and name */
            if (t->alias) {
                tab->alias = strdup(t->alias);
                tab->name = strdup(t->name);
            } else
                tab->name = strdup(t->name);

            listAddNodeTail(tabs, tab);
        }
    }
    return tabs;
}

/*
 *   base where generate a lists
 *   must a.id (current without meta-information)
 */

void generateColumn(Stmt *st, list *tabs) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;
    list *tab;

    if (st->whereList && listLength(st->whereList)) {    
        iter = listGetIterator(st->whereList, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            loop_expr_stmt(i, tabs);
        }
        
        listReleaseIterator(iter);
    }
}

int main(int ac, char **av)
{
    extern FILE *yyin;

    if( ac > 1 && !strcmp(av[1], "-d")) {
         ac--; av++;
    }

    if( ac > 1 && (yyin = fopen(av[1], "r")) == NULL) {
        perror(av[1]);
        exit(1);
    }

    if(yyparse()) {
        printf("SQL parse failed\n");
        return 1;
    }

    Stmt *st = curStmt;
    list *tabs = generateTable(st);
    generateColumn(st, tabs);

    listIter *iter;
    listNode *node;

    if (tabs && listLength(tabs)) {
        iter = listGetIterator(tabs, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            Tab *t = listNodeValue(node);
            generateIndex(t->name, t->columns);
        }
        
        listReleaseIterator(iter);
    }

    return 0;
} 
