#include <assert.h>
#include "adlist.h"
#include "sql.h"
#include "sql.tab.h"
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

extern Stmt *stmtArray[100];
extern int indexArray;    

typedef struct Tab {
    char *name;
    char *alias;
    char *db;
    list *columns; // This table's columns
} Tab;

extern Stmt *curStmt;

void stmt(Stmt *st, int indent);

int loop_expr_item(Item *i, list *tabs) {
    listNode *node;
    Tab *tab;
    listIter *iter = NULL;

    if (!i) 
        { return 0; } 
    else {
        if (!i->name)
            return 0;

        if (0 == strcmp("?", i->name))
            return 0;

        if ((i->token1 == NAME) && (i->token2 == 0)) { 
            if (listLength(tabs) == 1) {
                iter = listGetIterator(tabs, AL_START_HEAD);                
                node = listNext(iter);
                tab = listNodeValue(node);
                //printf("%s\n", i->name);
                if(!listSearchKey(tab->columns, i->name)) {
                    listAddNodeTail(tab->columns, i->name);
                    return 1;
                }
            } else {
                if (i->prefix) {
                    node = listSearchKey(tabs, i->prefix);
                    if (!node) {
                        //printf("need prefix\n");
                        return 0;
                    }
                    tab = listNodeValue(node);
                    //printf("%s\n", i->name);
                    if(!listSearchKey(tab->columns, i->name)) {
                        listAddNodeTail(tab->columns, i->name);
                        return 1;
                    }
                } else {
                    //printf("need prefix\n");
                }
            }
            /*
                only use function
            if (i->right) {
                zprintf(0, ",");
                loop_expr_item(i->right, 0);
            }
            */

        } else if ((i->token1 == USERVAR) && (i->token2 == 0)) { 
            return 0;
        } else if ((i->token1 == STRING) && (i->token2 == 0)) { 
            return 0;
        } else if ((i->token1 == INTNUM) && (i->token2 == 0)) { 
            return 0;
        } else if ((i->token1 == APPROXNUM) && (i->token2 == 0)) { 
            return ;
        } else if ((i->token1 == BOOL) && (i->token2 == 0)) { 
            return 0;
        } else if ((i->token1 > FSTART) && (i->token1 < FEND)) {
            return 0;
        } else if ((i->token1 == ADD_OP)
            || (i->token1 == SUB_OP)
            || (i->token1 == DIV_OP)
            || (i->token1 == MUL_OP)
        ) {
            return 0;
        } else {
            assert(NULL); 
        }
    }
}

int loop_expr_stmt(Item *i, list *tabs) {
    int flags = 0;
    if (!i) 
        { return 0;}
    else {
        if ((i->token1 == ANDOP) && (i->token2 == 0)) {
            flags = loop_expr_stmt(i->left, tabs);
            flags += loop_expr_stmt(i->right, tabs);
            return flags;
        } else if ((i->token1 == OR) && (i->token2 == 0)) { 
            flags = loop_expr_stmt(i->left, tabs);
            flags += loop_expr_stmt(i->right, tabs);
            return flags;
        } else if ((i->token1 == COMPARISON)) {
            flags = loop_expr_item(i->left, tabs);
            flags += loop_expr_item(i->right, tabs);
            return flags;
        } else if ((i->token1 == NULLX)) {
            return 0;
            /* skip */
        } else if ((i->token1 == NAME)) {
            return 0;
            /* skip */
        } else if ((i->token1 == IN) && (i->token2 == SELECT)) {
            return 0;
            /* skip select */
        } else if ((i->token1 == IN) && (i->token2 == 0)) {
            return loop_expr_item(i->left, tabs);
        } else if ((i->token1 == NOT) && (i->token2 == IN)) {
            return 0;
        } else if ((i->token1 == LIKE) || (i->token1 == REGEXP)) {
            return 0;
        } else if ((i->token1 > FSTART) && (i->token1 < FEND)) {
            return 0;
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
void generateJson(char *db, char *table, list *columns, int i) {
    listIter *iter;
    listNode *node;
    char s[1000] = {};

    if (columns && listLength(columns)) {
        if (db)
            snprintf(s + strlen(s), sizeof(s), "\"%s.%s###%d\":[", db, table, i);
        else
            snprintf(s + strlen(s), sizeof(s), "\"%s\"###%d:[", table, i);

        iter = listGetIterator(columns, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            /* column */
            char *c = listNodeValue(node);
            snprintf(s + strlen(s), sizeof(s), "\"%s\"", c);

            if (listNextNode(node))
                snprintf(s + strlen(s), sizeof(s), "%s", ", ");
            else
                snprintf(s + strlen(s), sizeof(s), "%s", "]");
        }

        listReleaseIterator(iter);
        printf("%s", s);
    }
};

/*
 *    tab1 t, tab2  -> t tab2
 */

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
            if (t->alias)
                tab->alias = strdup(t->alias);

            if (t->db)
                tab->db = strdup(t->db);

            if (t->name) 
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

int generateColumn(Stmt *st, list *tabs) {
    listIter *iter, *auxIter;
    listNode *node, *auxNode;
    list *tab;

    int flag = 0;
    int c = 0;
    if (st->whereList && listLength(st->whereList)) {    
        iter = listGetIterator(st->whereList, AL_START_HEAD); 
        while ((node = listNext(iter)) != NULL) {
            Item *i = listNodeValue(node);
            c = loop_expr_stmt(i, tabs);
            if (c != 0)
                flag = 1;
        }
        
        listReleaseIterator(iter);
    }
    return flag;
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

    int comma = 0, comma2 = 0;
    printf("%s", "{\"ins\":{");
    for (i = 0; i < indexArray; i++) {
        Stmt *st = stmtArray[i];
        if (st) {
            if ((st->sql_command == SQLCOM_SELECT)
            || (st->sql_command == SQLCOM_DELETE)
            || (st->sql_command = SQLCOM_UPDATE)) {
                //stmt(st, 0); 
                //printf("=========================================================\n");

                list *tabs = generateTable(st);
                if (generateColumn(st, tabs)) {
                    // has data print
                    if (comma == 1)
                        printf("%s", ",   ");
                    comma = 1;
                    
                }

                listIter *iter;
                listNode *node;

                if (tabs && listLength(tabs)) {
                    iter = listGetIterator(tabs, AL_START_HEAD); 
                    comma2 = 0;
                    while ((node = listNext(iter)) != NULL) {
                        Tab *t = listNodeValue(node);
                        if (listLength(t->columns)) {
                            if (comma2 == 1)
                                printf("%s", ",");
                            comma2 = 1;
                            generateJson(t->db, t->name, t->columns, i);
                        }
                    }
                    
                    listReleaseIterator(iter);
                }
                //printf("=========================================================\n");
            }
        } else {
            printf("SQL parse failed\n");
        }
    } 
    printf("%s", "}}");

    return 0;
} 
