%{
#include <assert.h>
#include "adlist.h"
#include "sql.h"
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>

Stmt *stmtArray[2000];
int indexArray = 0;
Stmt *curStmt = NULL;

void yyerror(char *s, ...);
void debug(char *s, ...);

/* for simple function */
#define NORMAL_FUNCTION(f) do {\
        debug ("CALL %s", #f);\
        Item *i = calloc(1, sizeof(*i));\
        i->right = (yyvsp[(3) - (4)].item);\
        i->token1 = f;\
        (yyval.item) = i;}\
        while(0)

#define NORMAL_FUNCTION_WILD(f) do {\
        debug ("CALL %s", #f);\
        Item *i = calloc(1, sizeof(*i));\
        i->name = strdup("*");\
        i->token1 = f;\
        (yyval.item) = i;}\
        while(0)

#define NORMAL_FUNCTION_NO_PARAM(f) do {\
        debug ("CALL %s", #f);\
        Item *i = calloc(1, sizeof(*i));\
        i->token1 = f;\
        (yyval.item) = i;}\
        while(0)

extern int yydebug = 1;

%}

%union {
    int intval;
    double floatval;
    char *strval;
    int subtok;
    list* listval;
    Item* item;
    Table* tableval;
    Stmt *stmt;
}
    
    /* names and literal values */

%token <listval> LIST
%token <strval> NAME
%token <strval> STRING
%token <intval> INTNUM
%token <intval> BOOL
%token <floatval> APPROXNUM

       /* user @abc names */

%token <strval> USERVAR

       /* operators and precedence levels */

%right ASSIGN
%left OR
%left XOR
%left ANDOP
%nonassoc IN IS LIKE REGEXP
%left NOT '!'
%left BETWEEN
%left <subtok> COMPARISON /* = <> < > <= >= <=> */
%left '|'
%left '&'
%left <subtok> SHIFT /* << >> */
%left '+' '-'
%left '*' '/' '%' MOD
%left '^'
%nonassoc UMINUS

    /* TODO sql/lex.h */
%token ADD
%token ALL
%token ALTER
%token ANALYZE
%token AND
%token ANY
%token AS
%token ASC
%token AUTO_INCREMENT
%token BEFORE
%token BETWEEN
%token BIGINT
%token BINARY
%token BIT
%token BLOB
%token BOTH
%token BY
%token CALL
%token CASCADE
%token CASE
%token CHANGE
%token CHAR
%token CHECK
%token COLLATE
%token COLUMN
%token COMMENT
%token CONDITION
%token CONSTRAINT
%token CONTINUE
%token CONVERT
%token CREATE
%token CROSS
%token CURRENT_DATE
%token CURRENT_TIME
%token CURRENT_TIMESTAMP
%token CURRENT_USER
%token CURSOR
%token DATABASE
%token DATABASES
%token DATE
%token DATETIME
%token DAY_HOUR
%token DAY_MICROSECOND
%token DAY_MINUTE
%token DAY_SECOND
%token DECIMAL
%token DECLARE
%token DEFAULT
%token DELAYED
%token DELETE
%token DESC
%token DESCRIBE
%token DETERMINISTIC
%token DISTINCT
%token DISTINCTROW
%token DIV
%token DOUBLE
%token DROP
%token DUAL
%token EACH
%token ELSE
%token ELSEIF
%token ENCLOSED
%token END
%token ENUM
%token ESCAPED
%token <subtok> EXISTS
%token EXIT
%token EXPLAIN
%token FETCH
%token FLOAT
%token FOR
%token FORCE
%token FOREIGN
%token FROM
%token FULLTEXT
%token GRANT
%token GROUP
%token HAVING
%token HIGH_PRIORITY
%token HOUR_MICROSECOND
%token HOUR_MINUTE
%token HOUR_SECOND
%token IF
%token IGNORE
%token IN
%token INDEX
%token INFILE
%token INNER
%token INOUT
%token INSENSITIVE
%token INSERT
%token INT
%token INTEGER
%token INTERVAL
%token INTO
%token ITERATE
%token JOIN
%token KEY
%token KEYS
%token KILL
%token LEADING
%token LEAVE
%token LEFT
%token LIKE
%token LIMIT
%token LINES
%token LOAD
%token LOCALTIME
%token LOCALTIMESTAMP
%token LOCK
%token LONG
%token LONGBLOB
%token LONGTEXT
%token LOOP
%token LOW_PRIORITY
%token MATCH
%token MEDIUMBLOB
%token MEDIUMINT
%token MEDIUMTEXT
%token MINUTE_MICROSECOND
%token MINUTE_SECOND
%token MOD
%token MODIFIES
%token NATURAL
%token NOT
%token NO_WRITE_TO_BINLOG
%token NULLX
%token NUMBER
%token ON
%token ONDUPLICATE
%token OPTIMIZE
%token OPTION
%token OPTIONALLY
%token OR
%token ORDER
%token OUT
%token OUTER
%token OUTFILE
%token PRECISION
%token PRIMARY
%token PROCEDURE
%token PURGE
%token QUICK
%token READ
%token READS
%token REAL
%token REFERENCES
%token REGEXP
%token RELEASE
%token RENAME
%token REPEAT
%token REPLACE
%token REQUIRE
%token RESTRICT
%token RETURN
%token REVOKE
%token RIGHT
%token ROLLUP
%token SCHEMA
%token SCHEMAS
%token SECOND_MICROSECOND
%token SELECT
%token SENSITIVE
%token SEPARATOR
%token SET
%token SHOW
%token SMALLINT
%token SOME
%token SONAME
%token SPATIAL
%token SPECIFIC
%token SQL
%token SQLEXCEPTION
%token SQLSTATE
%token SQLWARNING
%token SQL_BIG_RESULT
%token SQL_CALC_FOUND_ROWS
%token SQL_SMALL_RESULT
%token SSL
%token STARTING
%token STRAIGHT_JOIN
%token TABLE
%token TEMPORARY
%token TEXT
%token TERMINATED
%token THEN
%token TIME
%token TIMESTAMP
%token TINYBLOB
%token TINYINT
%token TINYTEXT
%token TO
%token TRAILING
%token TRIGGER
%token UNDO
%token UNION
%token UNIQUE
%token UNLOCK
%token UNSIGNED
%token UPDATE
%token USAGE
%token USE
%token USING
%token UTC_DATE
%token UTC_TIME
%token UTC_TIMESTAMP
%token VALUES
%token VARBINARY
%token VARCHAR
%token VARYING
%token WHEN
%token WHERE
%token WHILE
%token WITH
%token WRITE
%token XOR
%token YEAR
%token YEAR_MONTH
%token ZEROFILL

 /* functions with special syntax */

 /* sql/item_create.cc func_array */ 

%token FSTART

%token FABS
%token FACOS
%token FADDTIME
%token FAES_DECRYPT
%token FAES_ENCRYPT
%token FAREA
%token FASBINARY
%token FASIN
%token FASTEXT
%token FASWKB
%token FASWKT
%token FATAN
%token FATAN2
%token FASCII
%token FAVG
%token FADDDATE

%token FBENCHMARK
%token FBIN
%token FBIT_AND
%token FBIT_OR
%token FBIT_XOR
%token FBIT_COUNT
%token FBIT_LENGTH

%token FCAST
%token FCEILING
%token FCENTROID
%token FCHAR
%token FCHARACTER_LENGTH
%token FCOERCIBILITY
%token FCOMPRESS
%token FCONCAT
%token FCONCAT_WS
%token FCONNECTION_ID
%token FCONV
%token FCONVERT_TZ
%token FCOS
%token FCOT
%token FCRC32
%token FCROSSESS
%token FCOUNT
%token FCHARSET
%token FCOLLATION
%token FCURRENT_USER
%token FCURDATE
%token FCURRENT_DATE
%token FCURTIME
%token FCURTIME_TIME
%token FCURTIME_TIMESTAMP

%token FDATE
%token FDATEDIFF
%token FDATENAME
%token FDATEOFMONTH
%token FDATEOFWEEK
%token FDATEOFYEAR
%token FDATE_ADD
%token FDATE_SUB
%token FDATE_FORMAT
%token FDATABASE
%token FDEFAULT
%token FDECODE
%token FDEGREES
%token FDES_DECRYPT
%token FDES_ENCRYPT
%token FDIMENSION
%token FISJOINT

%token FELT
%token FENCODE
%token FENCRYPT
%token FENDPOINT
%token FENVELOPE
%token FEQUALS
%token FEXP
%token FEXPORT_SET
%token FEXTRACT;
%token FEXTERIORRING
%token FEXTRACTVALUE

%token FFIELD
%token FFIND_IN_SET
%token FFLOOR
%token FFORMAT
%token FFOUND_ROWS
%token FFROM_DAYS
%token FFROM_UNIXTIME

%token FGET_FORMAT
%token FGEOMCOLLFROMTEXT
%token FGEOMCOLLFROMWKB
%token FGEOMETRYCOLLECTIONFROMTEXT
%token FGEOMETRYCOLLECTIONFROMWKB
%token FGEOMETRYFROMTEXT
%token FGEOMETRYFROMWKB
%token FGEOMETRYN
%token FGEOMETRYTYPE
%token FGEOMFROMTEXT
%token FGEOMFROMWKB
%token FGET_LOCK
%token FGLENGTH
%token FGREATEST

%token FHEX
%token FHOUR

%token FINSERT
%token FINSTR
%token FIFNULL
%token FINET_ATON
%token FINET_NTOA
%token FINTERIORRINGN
%token FINTERSECTS
%token FISCLOSED
%token FISEMPTY
%token FISNULL
%token FISSIMPLE
%token FIS_FREE_LOCK
%token FIS_USED_LOCK

%token FLAST_DAY
%token FLAST_INSERT_ID
%token FLCASE
%token FLEFT
%token FLENGTH
%token FLINEFROMTEXT
%token FLINEFROMWKB
%token FLINESTRINGFROMTEXT
%token FLINESTRINGFROMWKB
%token FLN
%token FLOAD_FILE
%token FLOCATE
%token FLOG
%token FLOG10
%token FLOG2
%token FLOWER
%token FLPAD
%token FLTRIM
%token FLOCALTIME
%token FLOCALTIMESTAMP

%token FMAKEDATE
%token FMAKETIME
%token FMAKE_SET
%token FMASTER_POS_WAIT
%token FMBRCONTAINS
%token FMBRDISJOINT
%token FMBREQUAL
%token FMBRINTERSECTS
%token FMBROVERLAPS
%token FMBRTOUCHES
%token FMBRWITHIN
%token FMD5
%token FMLINEFROMTEXT
%token FMLINEFROMWKB
%token FMONTHNAME
%token FMPOINTFROMTEXT
%token FMPOINTFROMWKB
%token FMPOLYFROMTEXT
%token FMPOLYFROMWKB
%token FMULTILINESTRINGFROMTEXT
%token FMULTILINESTRINGFROMWKB
%token FMULTIPOINTFROMTEXT
%token FMULTIPOINTFROMWKB
%token FMULTIPOLYGONFROMTEXT
%token FMULTIPOLYGONFROMWKB

%token FMICROSECOND
%token FMINUTE
%token FMONTH

%token FGROUP_CONCAT
%token FMAX
%token FMID
%token FMIN
%token FMOD

%token FNOW
%token FNAME_CONST
%token FNULLIF
%token FNUMGEOMETRIES
%token FNUMINTERIORRINGS
%token FNUMPOINTS

%token FOCT
%token FOCTET_LENGTH
%token FORD
%token FOVERLAPS
%token FOLD_PASSWORD

%token FPERIOD_ADD
%token FPERIOD_DIFF
%token FPI
%token FPOSITION
%token FPASSWORD
%token FPOINTFROMTEXT
%token FPOINTFROMWKB
%token FPOINTN
%token FPOLYFROMTEXT
%token FPOLYFROMWKB
%token FPOLYGONFROMTEXT
%token FPOLYGONFROMWKB
%token FPOW
%token FPOWER

%token FQUARTER
%token FQUOTE

%token FRADIANS
%token FRAND
%token FROUND
%token FROW_COUNT
%token FREPEAT
%token FREPLACE
%token FREVERSE
%token FRIGHT
%token FRPAD
%token FRTRIM
%token FRELEASE_LOCK

%token FSEC_TO_TIME
%token FSEC_TO_DATE
%token FSHA
%token FSHA1
%token FSLEEP
%token FSCHEMA
%token FSOUNDEX
%token FSPACE
%token FSQRT
%token FSRID
%token FSTARTPOINT
%token FSTRCMP
%token FSTR_TO_DATE
%token FSECOND
%token FSUBTIME
%token FSIGN
%token FSIN
%token FSUBSTRING
%token FSUBSTRING_INDEX
%token FSESSION_USER
%token FSTD
%token FSTDDEV
%token FSTDDEV_POP
%token FSTDDEV_SAMP
%token FSUBDATE
%token FSUM
%token FSYSDATE
%token FSYSTEM_USER

%token FTAN
%token FTIMEDIFF
%token FTIME_FORMAT
%token FTIME_TO_SEC
%token FTRUNCATE
%token FTOUCHES
%token FTO_DAYS
%token FTRIM
%token FTIME
%token FTIMESTAMP
%token FTIMESTAMPADD
%token FTIMESTAMPDIFF

%token FVARIANCE
%token FVAR_POP
%token FVAR_SAMP

%token FUCASE
%token FUNCOMPRESS
%token FUNCOMPRESSED_LENGTH
%token FUNHEX
%token FUSER
%token FUNIX_TIMESTAMP
%token FUPDATEXML
%token FUPPER
%token FUUID
%token FUUID_SHORT
%token FVERSION
%token FUTC_DATE
%token FUTC_TIME
%token FUTC_TIMESTAMP
%token FWEEK
%token FWEEKDAY
%token FWEEKOFYEAR
%token FYEAR
%token FYEARWEEK

%token FX
%token FY

%token FEND

%token SUB_OP ADD_OP MUL_OP DIV_OP 
%token BITOR_OP BITXOR_OP BITAND_OP

%type <stmt> select_stmt
%type <stmt> table_subquery
%type <listval> val_list opt_val_list case_list
%type <item> expr select_expr 
%type <intval> select_opts select_expr_list 
%type <intval> groupby_list orderby_list opt_with_rollup opt_asc_desc
%type <intval> table_references opt_inner_cross opt_outer table_factor
%type <intval> left_or_right opt_left_or_right_outer column_list
%type <intval> index_list opt_for_join
%type <strval> opt_as_alias

%type <intval> delete_opts delete_list
%type <intval> insert_opts insert_vals insert_vals_list
%type <intval> insert_asgn_list opt_if_not_exists update_opts update_asgn_list
%type <intval> opt_temporary opt_length opt_binary opt_uz enum_list
%type <intval> column_atts data_type opt_ignore_replace create_col_list

%start stmt_list

%%

/* must ; end */

stmt_list: error  {
    /* TODO  free curStmt */
    curStmt = NULL;
    }
    | stmt ';' {
        stmtArray[indexArray] = curStmt;
        indexArray++;
        curStmt = NULL;
    }
    | stmt_list stmt ';' {
        stmtArray[indexArray] = curStmt;
        indexArray++;
        curStmt = NULL;
    }

    ;

   /* SELECT */

stmt: select_stmt { debug("STMT"); }
    ;

select_reduce_stmt: SELECT {
        Stmt *stmt = calloc(1, sizeof(*stmt));
        stmtInit(stmt);
        if (curStmt) {
            stmt->father = curStmt;
        }
        debug("select From %p to child %p", curStmt, stmt);
        curStmt = stmt;
    };


select_stmt: select_reduce_stmt select_opts select_expr_list { 
        curStmt->sql_command = SQLCOM_SELECT; 
    //    debug("SELECTNODATA %d %d", $2, $3);
        $$ = curStmt;
    }
    | select_reduce_stmt select_opts select_expr_list
    FROM table_references
    opt_where opt_groupby opt_having opt_orderby opt_limit
    opt_into_list { 
        curStmt->sql_command = SQLCOM_SELECT; 
    //    debug("SELECT %d %d %d", $2, $3, $5); 
        $$ = curStmt;
    }
    ;

opt_where: /* nil */ 
    | WHERE expr {
        debug("WHERE");
        listAddNodeTail(curStmt->whereList, $2);
    };
    /* -GROUPBY */
opt_groupby: /* nil */ 
    | GROUP BY groupby_list opt_with_rollup { 
        debug("GROUPBYLIST %d %d", $3, $4); 
    }
    ;

groupby_list: expr opt_asc_desc { 
        debug("GROUPBY1 %d",  $2); 
        $$ = 1;
        listAddNodeTail(curStmt->groupList, $1);
    }
    | groupby_list ',' expr opt_asc_desc { 
        debug("GROUPBY2 %d",  $4); 
        $$ = $1 + 1;
        listAddNodeTail(curStmt->groupList, $3);
    }
    ;

opt_asc_desc: /* nil */ { $$ = 0; }
   | ASC                { $$ = 0; }
   | DESC               { $$ = 1; }
    ;

opt_with_rollup: /* nil */  { $$ = 0; }
   | WITH ROLLUP  { $$ = 1; }
   ;

opt_having: /* nil */ | HAVING expr {
        debug("HAVING");
        listAddNodeTail(curStmt->havingList, $2); 
    };

    /* -ORDER */
opt_orderby: /* nil */ | ORDER BY orderby_list { 
        debug("ORDERBYLIST %d", $3); 
    };

orderby_list: expr opt_asc_desc { 
        debug("ORDERBY 1 %d",  $2); 
        $1->isDesc = $2;
        listAddNodeTail(curStmt->orderList, $1);
        $$ = 1;
    }
    | orderby_list ',' expr opt_asc_desc {
        debug("ORDERBY 2 %d",  $4); 
        $3->isDesc = $4;
        listAddNodeTail(curStmt->orderList, $3);    
        $$ = $1 + 1; 
    }
    ;

opt_limit: /* nil */ | LIMIT expr {
        debug("LIMIT 1"); 
        listAddNodeTail(curStmt->limitList, $2);
    }
    | LIMIT expr ',' expr             { 
        debug("LIMIT 2"); 
        listAddNodeTail(curStmt->limitList, $2);
        listAddNodeTail(curStmt->limitList, $4);
    }
    ;

opt_into_list: /* nil */ 
   | INTO column_list { debug("INTO %d", $2); }
   ;

    /* using, insert column, create */
column_list: NAME {
        debug("COLUMN %s", $1); 
        Item *i = calloc(1, sizeof(*i));
        i->name = strdup($1);
        i->token1 = NAME;
        if (curStmt->step == InsertColumnStep) {
            listAddNodeTail(curStmt->insertList, i); 
        } else if (curStmt->step == UsingStep) {
            listAddNodeTail(curStmt->usingList, i); 
        }

        free($1);
        $$ = 1; 
    }
    | column_list ',' NAME  {
        debug("COLUMN %s", $3);
        Item *i = calloc(1, sizeof(*i));
        i->name = strdup($3);
        i->token1 = NAME;
        if (curStmt->step == InsertColumnStep) {
            listAddNodeTail(curStmt->insertList, i); 
        } else if (curStmt->step == UsingStep) {
            listAddNodeTail(curStmt->usingList, i); 
        }

        free($3);
        $$ = $1 + 1;
    }
  ;

select_opts:                          { $$ = 0; }
| select_opts ALL                 { if($$ & 01) yyerror("duplicate ALL option"); $$ = $1 | 01; }
| select_opts DISTINCT            { if($$ & 02) yyerror("duplicate DISTINCT option"); $$ = $1 | 02; }
| select_opts DISTINCTROW         { if($$ & 04) yyerror("duplicate DISTINCTROW option"); $$ = $1 | 04; }
| select_opts HIGH_PRIORITY       { if($$ & 010) yyerror("duplicate HIGH_PRIORITY option"); $$ = $1 | 010; }
| select_opts STRAIGHT_JOIN       { if($$ & 020) yyerror("duplicate STRAIGHT_JOIN option"); $$ = $1 | 020; }
| select_opts SQL_SMALL_RESULT    { if($$ & 040) yyerror("duplicate SQL_SMALL_RESULT option"); $$ = $1 | 040; }
| select_opts SQL_BIG_RESULT      { if($$ & 0100) yyerror("duplicate SQL_BIG_RESULT option"); $$ = $1 | 0100; }
| select_opts SQL_CALC_FOUND_ROWS { if($$ & 0200) yyerror("duplicate SQL_CALC_FOUND_ROWS option"); $$ = $1 | 0200; }
    ;


select_expr_list: select_expr {
        debug("#####%p\n", $1);
        listAddNodeTail(curStmt->select_expr_list, $1);
        $$ = 1;
    }
    | select_expr_list ',' select_expr {
        debug("#####%p\n", $3);
        listAddNodeTail(curStmt->select_expr_list, $3);
        $$ = 1;
    }
    | '*' { debug("SELECT *");
        Item *i = calloc(1, sizeof(*i));
        i->name = strdup("*");
        i->token1 = NAME;
        listAddNodeTail(curStmt->select_expr_list, i);
        $$ = 1;
    }
    ;

select_expr: expr opt_as_alias  {
        debug("SIMPLE SELECT");
        if ($2) {
            $1->alias = strdup($2);
            free($2);
        }
        $$ = $1;
    }
    ;

table_references:    table_reference { $$ = 1; }
    | table_references ',' table_reference { $$ = $1 + 1; }
    ;

table_reference:  table_factor
    | join_table
    ;

table_factor:
    NAME opt_as_alias index_hint 
    { debug("TABLE %s", $1);
        Table *t = calloc(1, sizeof(*t));
        t->name = strdup($1);
        free($1);

        if ($2) {
            t->alias = strdup($2);
            free($2);
        }

        listAddNodeTail(curStmt->joinList, t);
    }

    | NAME '.' NAME opt_as_alias index_hint { 
        debug("TABLE %s.%s", $1, $3);
        Table *t = calloc(1, sizeof(*t));
        t->db = strdup($1);
        t->name = strdup($3);
        free($1);
        free($3);

        if ($4) {
            t->alias = strdup($4);
            free($4);
        }

        listAddNodeTail(curStmt->joinList, t);
    }
    | table_subquery opt_as NAME {
        debug("SUBQUERYAS %s", $3);
        Table *t = calloc(1, sizeof(*t)); 
        t->sub = $1;
        if ($3) {
            t->alias = strdup($3);
            free($3);
        }
        listAddNodeTail(curStmt->joinList, t);
    }
    | '(' table_references ')' { debug("TABLEREFERENCES %d", $2); }
    ;

opt_as: AS 
  | /* nil */
  ;

opt_as_alias: AS NAME { debug ("ALIAS %s", $2); $$=$2 }
  | NAME              { debug ("ALIAS %s", $1); $$=$1 }
  | /* nil */    {$$ = NULL}
  ;

join_table:
    table_reference opt_inner_cross JOIN table_factor opt_join_condition
                  { debug("JOIN %d", 0100+$2); }
  | table_reference STRAIGHT_JOIN table_factor
                  { debug("JOIN %d", 0200); }
  | table_reference STRAIGHT_JOIN table_factor ON expr
                  { debug("JOIN %d", 0200); }
  | table_reference left_or_right opt_outer JOIN table_factor join_condition
                  { debug("JOIN %d", 0300+$2+$3); }
  | table_reference NATURAL opt_left_or_right_outer JOIN table_factor
                  { debug("JOIN %d", 0400+$3); }
  ;

opt_inner_cross: /* nil */ { $$ = 0; }
    | INNER { $$ = 1; }
    | CROSS  { $$ = 2; }
    ;

opt_outer: /* nil */  { $$ = 0; }
    | OUTER {$$ = 4; }
    ;

left_or_right: LEFT { $$ = 1; }
    | RIGHT { $$ = 2; }
    ;

opt_left_or_right_outer: LEFT opt_outer { $$ = 1 + $2; }
    | RIGHT opt_outer  { $$ = 2 + $2; }
    | /* nil */ { $$ = 0; }
    ;

opt_join_condition: join_condition | /* nil */ ;

reduce_using: USING {
        curStmt->step = UsingStep;  
    }

join_condition:
    ON expr {
        debug("ONEXPR");
        listAddNodeTail(curStmt->whereList, $2); 
    }
    | reduce_using '(' column_list ')' { debug("USING %d", $3); }
    ;

index_hint:
     USE KEY opt_for_join '(' index_list ')'
                  { debug("INDEXHINT %d %d", $5, 010+$3); }
   | IGNORE KEY opt_for_join '(' index_list ')'
                  { debug("INDEXHINT %d %d", $5, 020+$3); }
   | FORCE KEY opt_for_join '(' index_list ')'
                  { debug("INDEXHINT %d %d", $5, 030+$3); }
   | /* nil */
   ;

opt_for_join: FOR JOIN { $$ = 1; }
   | /* nil */ { $$ = 0; }
   ;

index_list: NAME  { debug("INDEX %s", $1); free($1); $$ = 1; }
    | index_list ',' NAME { debug("INDEX %s", $3); free($3); $$ = $1 + 1; }
    ;

table_subquery: '(' select_stmt ')' { 
        debug("SUBQUERY From child %p to father %p", curStmt, curStmt->father); 
        curStmt = curStmt->father;
        $$ = $2;
    }
    ;

    /* statements: delete statement */
    /* -DELETE */
stmt: delete_stmt { debug("STMT"); }
    ;

delete_reduce_stmt: DELETE {
        Stmt *stmt = calloc(1, sizeof(*stmt));
        stmtInit(stmt);
        if (curStmt) {
            stmt->father = curStmt;
        }
        debug("delete From %p to child %p", curStmt, stmt);
        curStmt = stmt;
    }
    ;
delete_stmt: delete_reduce_stmt delete_opts FROM NAME
    opt_where opt_orderby opt_limit {
        debug("DELETEONE %d %s", $2, $4);
        Table *t = calloc(1, sizeof(*t));
        t->name = strdup($4);
        free($4);
        listAddNodeTail(curStmt->joinList, t);
        curStmt->sql_command = SQLCOM_DELETE;
    }
    ;

delete_opts: delete_opts LOW_PRIORITY { $$ = $1 + 01; }
   | delete_opts QUICK { $$ = $1 + 02; }
   | delete_opts IGNORE { $$ = $1 + 04; }
   | /* nil */ { $$ = 0; }
   ;

delete_stmt: delete_reduce_stmt delete_opts
    delete_list
    FROM table_references opt_where
    { debug("DELETEMULTI %d %d %d", $2, $3, $5); }

delete_list: NAME opt_dot_star { debug("TABLE %s", $1); free($1); $$ = 1; }
   | delete_list ',' NAME opt_dot_star
            { debug("TABLE %s", $3); free($3); $$ = $1 + 1; }
   ;

opt_dot_star: /* nil */ | '.' '*' ;

delete_stmt: delete_reduce_stmt delete_opts
    FROM delete_list
    USING table_references opt_where
    { debug("DELETEMULTI %d %d %d", $2, $4, $6); }
    ;

   /* statements: insert statement */

stmt: insert_stmt { debug("STMT"); }
    ;

insert_reduce_stmt: INSERT {
        Stmt *stmt = calloc(1, sizeof(*stmt));
        stmtInit(stmt);
        if (curStmt) {
            stmt->father = curStmt;
        }
        debug("insert From %p to child %p", curStmt, stmt);
        stmt->sql_command = SQLCOM_INSERT;
        stmt->step = InsertColumnStep;
        curStmt = stmt;
    };

    /* reduce */
insert_value_reduce_stmt: VALUES {
        curStmt->step = ValueColumnStep;
        curStmt->valueChildList = listCreate();
    };

    /* insert ... values() */
insert_stmt: insert_reduce_stmt insert_opts opt_into NAME
     opt_col_names
     insert_value_reduce_stmt insert_vals_list
     opt_ondupupdate {
        debug("INSERTVALS %d %d %s", $2, $7, $4); 
        Table *t = calloc(1, sizeof(*t));
        t->name = strdup($4);
        free($4);
        listAddNodeTail(curStmt->joinList, t);
    }
    ;

opt_ondupupdate: /* nil */
    | ONDUPLICATE KEY UPDATE insert_asgn_list { debug("DUPUPDATE %d", $4); }
    ;

insert_opts: /* nil */ { $$ = 0; }
   | insert_opts LOW_PRIORITY { $$ = $1 | 01 ; }
   | insert_opts DELAYED { $$ = $1 | 02 ; }
   | insert_opts HIGH_PRIORITY { $$ = $1 | 04 ; }
   | insert_opts IGNORE { $$ = $1 | 010 ; }
   ;

opt_into: INTO | /* nil */
   ;

        /* insert, replace */
opt_col_names: /* nil */
   | '(' column_list ')' { debug("INSERTCOLS %d", $2); }
   ;

insert_vals_list: '(' insert_vals ')' {
        debug("VALUES %d", $2); $$ = 1;
        listAddNodeTail(curStmt->valueList, curStmt->valueChildList);  
        curStmt->valueChildList = listCreate();
    }
    | insert_vals_list ',' '(' insert_vals ')' { 
        debug("VALUES %d", $4); $$ = $1 + 1; 
        listAddNodeTail(curStmt->valueList, curStmt->valueChildList);  
        curStmt->valueChildList = listCreate();
    };

insert_vals:
    expr {
        listAddNodeTail(curStmt->valueChildList, $1);
        $$ = 1;
    }
    | DEFAULT { debug("DEFAULT"); $$ = 1;}
    | insert_vals ',' expr {
        $$ = $1 + 1;
        listAddNodeTail(curStmt->valueChildList, $3);
    }
    | insert_vals ',' DEFAULT { debug("DEFAULT"); $$ = $1 + 1; }
    ;

    /* what is it? */
insert_stmt: insert_reduce_stmt insert_opts opt_into NAME
    SET insert_asgn_list
    opt_ondupupdate
    { debug("INSERTASGN %d %d %s", $2, $6, $4); free($4) }
    ;

    /* insert ... select */
insert_stmt: insert_reduce_stmt insert_opts opt_into NAME opt_col_names
    select_stmt
    opt_ondupupdate {
        debug("INSERTSELECT %d %s From child %p to father %p", $2, $4, curStmt, curStmt->father);
        Table *t = calloc(1, sizeof(*t));
        t->name = strdup($4);
        free($4);
        curStmt = curStmt->father;
        listAddNodeTail(curStmt->joinList, t);
        curStmt->valueSelect = $6;
    };

insert_asgn_list:
     NAME COMPARISON expr 
     { if ($2 != 4) yyerror("bad insert assignment to %s", $1);
       debug("ASSIGN %s", $1); free($1); $$ = 1; }
   | NAME COMPARISON DEFAULT
               { if ($2 != 4) yyerror("bad insert assignment to %s", $1);
                 debug("DEFAULT"); debug("ASSIGN %s", $1); free($1); $$ = 1; }
   | insert_asgn_list ',' NAME COMPARISON expr
               { if ($4 != 4) yyerror("bad insert assignment to %s", $1);
                 debug("ASSIGN %s", $3); free($3); $$ = $1 + 1; }
   | insert_asgn_list ',' NAME COMPARISON DEFAULT
               { if ($4 != 4) yyerror("bad insert assignment to %s", $1);
                 debug("DEFAULT"); debug("ASSIGN %s", $3); free($3); $$ = $1 + 1; }
   ;

   /** replace just like insert **/
stmt: replace_stmt { debug("STMT"); }
    ;

replace_reduce_stmt: REPLACE {
        Stmt *stmt = calloc(1, sizeof(*stmt));
        stmtInit(stmt);
        if (curStmt) {
            stmt->father = curStmt;
        }
        debug("replace From %p to child %p", curStmt, stmt);
        stmt->sql_command = SQLCOM_REPLACE;
        stmt->step = InsertColumnStep;
        curStmt = stmt;
    };
    /* reduce */
replace_value_reduce_stmt: VALUES {
        curStmt->step = ValueColumnStep;
        curStmt->valueChildList = listCreate();
    };

replace_stmt: replace_reduce_stmt insert_opts opt_into NAME
     opt_col_names
     replace_value_reduce_stmt insert_vals_list
     opt_ondupupdate {
        debug("REPLACEVALS %d %d %s", $2, $7, $4); 
        Table *t = calloc(1, sizeof(*t));
        t->name = strdup($4);
        free($4);
        listAddNodeTail(curStmt->joinList, t);
    };

replace_stmt: replace_reduce_stmt insert_opts opt_into NAME
    SET insert_asgn_list
    opt_ondupupdate
     { debug("REPLACEASGN %d %d %s", $2, $6, $4); free($4) }
   ;

replace_stmt: replace_reduce_stmt insert_opts opt_into NAME opt_col_names
    select_stmt
    opt_ondupupdate {
        debug("REPLACESELECT %d %s From child %p to father %p", $2, $4, curStmt, curStmt->father);
        Table *t = calloc(1, sizeof(*t));
        t->name = strdup($4);
        free($4);
        curStmt = curStmt->father;
        listAddNodeTail(curStmt->joinList, t);
        curStmt->valueSelect = $6;
    };

    /** -UPDATE **/
stmt: update_stmt { debug("STMT"); }
    ;

update_reduce_stmt: UPDATE {
        Stmt *stmt = calloc(1, sizeof(*stmt));
        stmtInit(stmt);
        if (curStmt) {
            stmt->father = curStmt;
        }
        debug("update From %p to child %p", curStmt, stmt);
        curStmt = stmt;
    }
    ;

update_stmt: update_reduce_stmt
    update_opts table_references
    SET update_asgn_list
    opt_where
    opt_orderby
    opt_limit { debug("UPDATE %d %d %d", $2, $3, $5); 
        curStmt->sql_command = SQLCOM_UPDATE;    
    }
    ;
    /*
    test_opts: 'z' {debug("hahaah");};
    */

update_opts: /* nil */ { debug("update_opts"); $$ = 0; }
   | insert_opts LOW_PRIORITY { $$ = $1 | 01 ; }
   | insert_opts IGNORE { $$ = $1 | 010 ; }
   ;

update_asgn_list:
    NAME COMPARISON expr { 
        if ($2 != 4) yyerror("bad insert assignment to %s", $1);
        debug("ASSIGN %s %d", $1, $3);

        Item *i = calloc(1, sizeof(*i));
        i->name = strdup($1);
        free($1);
        i->token1 = NAME;
        Item *c = calloc(1, sizeof(*c));
        c->token1 = COMPARISON;
        c->token2 = $2;
        c->left = i;
        c->right = $3;

        listAddNodeTail(curStmt->updateSetList, c); 
        $$ = 1;
    }
    | NAME '.' NAME COMPARISON expr { 
        if ($4 != 4) yyerror("bad insert assignment to %s", $1);
        debug("ASSIGN %s.%s", $1, $3); 
        Item *i = calloc(1, sizeof(*i));
        i->prefix = strdup($1);
        i->name = strdup($3);
        free($1);
        free($3);
        i->token1 = NAME;
        Item *c = calloc(1, sizeof(*c));
        c->token1 = COMPARISON;
        c->token2 = $4;
        c->left = i;
        c->right = $5;

        listAddNodeTail(curStmt->updateSetList, c); 
        $$ = 1; 
    }
    | update_asgn_list ',' NAME COMPARISON expr { 
        if ($4 != 4) yyerror("bad insert assignment to %s", $3);
        debug("ASSIGN %s.%s", $3); 
        Item *i = calloc(1, sizeof(*i));
        i->name = strdup($3);
        free($3);
        i->token1 = NAME;
        Item *c = calloc(1, sizeof(*c));
        c->token1 = COMPARISON;
        c->token2 = $4;
        c->left = i;
        c->right = $5;

        listAddNodeTail(curStmt->updateSetList, c); 
        $$ = $1 + 1;
    }
    | update_asgn_list ',' NAME '.' NAME COMPARISON expr { 
        if ($6 != 4) yyerror("bad insert assignment to %s.$s", $3, $5);
        debug("ASSIGN %s.%s", $3, $5); 
        Item *i = calloc(1, sizeof(*i));
        i->prefix = strdup($3);
        i->name = strdup($5);
        free($3);
        free($5);
        i->token1 = NAME;
        Item *c = calloc(1, sizeof(*c));
        c->token1 = COMPARISON;
        c->token2 = $6;
        c->left = i;
        c->right = $7;

        listAddNodeTail(curStmt->updateSetList, c); 
        $$ = $1 + 1;
    }
    ;

   /** create database **/

stmt: create_database_stmt { debug("STMT"); }
   ;

create_database_stmt: 
     CREATE DATABASE opt_if_not_exists NAME { debug("CREATEDATABASE %d %s", $3, $4); free($4); }
   | CREATE SCHEMA opt_if_not_exists NAME { debug("CREATEDATABASE %d %s", $3, $4); free($4); }
   ;

opt_if_not_exists:  /* nil */ { $$ = 0; }
   | IF EXISTS           { if(!$2)yyerror("IF EXISTS doesn't exist");
                        $$ = $2; /* NOT EXISTS hack */ }
   ;


   /** create table **/
stmt: create_table_stmt { debug("STMT"); }
   ;

create_table_stmt: CREATE opt_temporary TABLE opt_if_not_exists NAME
   '(' create_col_list ')' { debug("CREATE %d %d %d %s", $2, $4, $7, $5); free($5); }
   ;

create_table_stmt: CREATE opt_temporary TABLE opt_if_not_exists NAME '.' NAME
   '(' create_col_list ')' { debug("CREATE %d %d %d %s.%s", $2, $4, $9, $5, $7);
                          free($5); free($7); }
   ;

create_table_stmt: CREATE opt_temporary TABLE opt_if_not_exists NAME
   '(' create_col_list ')'
create_select_statement { debug("CREATESELECT %d %d %d %s", $2, $4, $7, $5); free($5); }
    ;

create_table_stmt: CREATE opt_temporary TABLE opt_if_not_exists NAME
   create_select_statement { debug("CREATESELECT %d %d 0 %s", $2, $4, $5); free($5); }
    ;

create_table_stmt: CREATE opt_temporary TABLE opt_if_not_exists NAME '.' NAME
   '(' create_col_list ')'
   create_select_statement  { debug("CREATESELECT %d %d 0 %s.%s", $2, $4, $5, $7);
                              free($5); free($7); }
    ;

create_table_stmt: CREATE opt_temporary TABLE opt_if_not_exists NAME '.' NAME
   create_select_statement { debug("CREATESELECT %d %d 0 %s.%s", $2, $4, $5, $7);
                          free($5); free($7); }
    ;

create_col_list: create_definition { $$ = 1; }
    | create_col_list ',' create_definition { $$ = $1 + 1; }
    ;

create_definition: { debug("STARTCOL"); } NAME data_type column_atts
                   { debug("COLUMNDEF %d %s", $3, $2); free($2); }

    | PRIMARY KEY '(' column_list ')'    { debug("PRIKEY %d", $4); }
    | KEY '(' column_list ')'            { debug("KEY %d", $3); }
    | INDEX '(' column_list ')'          { debug("KEY %d", $3); }
    | FULLTEXT INDEX '(' column_list ')' { debug("TEXTINDEX %d", $4); }
    | FULLTEXT KEY '(' column_list ')'   { debug("TEXTINDEX %d", $4); }
    ;

column_atts: /* nil */ { $$ = 0; }
    | column_atts NOT NULLX             { debug("ATTR NOTNULL"); $$ = $1 + 1; }
    | column_atts NULLX
    | column_atts DEFAULT STRING        { debug("ATTR DEFAULT STRING %s", $3); free($3); $$ = $1 + 1; }
    | column_atts DEFAULT INTNUM        { debug("ATTR DEFAULT NUMBER %d", $3); $$ = $1 + 1; }
    | column_atts DEFAULT APPROXNUM     { debug("ATTR DEFAULT FLOAT %g", $3); $$ = $1 + 1; }
    | column_atts DEFAULT BOOL          { debug("ATTR DEFAULT BOOL %d", $3); $$ = $1 + 1; }
    | column_atts AUTO_INCREMENT        { debug("ATTR AUTOINC"); $$ = $1 + 1; }
    | column_atts UNIQUE '(' column_list ')' { debug("ATTR UNIQUEKEY %d", $4); $$ = $1 + 1; }
    | column_atts UNIQUE KEY { debug("ATTR UNIQUEKEY"); $$ = $1 + 1; }
    | column_atts PRIMARY KEY { debug("ATTR PRIKEY"); $$ = $1 + 1; }
    | column_atts KEY { debug("ATTR PRIKEY"); $$ = $1 + 1; }
    | column_atts COMMENT STRING { debug("ATTR COMMENT %s", $3); free($3); $$ = $1 + 1; }
    ;

opt_length: /* nil */ { $$ = 0; }
   | '(' INTNUM ')' { $$ = $2; }
   | '(' INTNUM ',' INTNUM ')' { $$ = $2 + 1000*$4; }
   ;

opt_binary: /* nil */ { $$ = 0; }
   | BINARY { $$ = 4000; }
   ;

opt_uz: /* nil */ { $$ = 0; }
   | opt_uz UNSIGNED { $$ = $1 | 1000; }
   | opt_uz ZEROFILL { $$ = $1 | 2000; }
   ;

opt_csc: /* nil */
   | opt_csc CHAR SET STRING { debug("COLCHARSET %s", $4); free($4); }
   | opt_csc COLLATE STRING { debug("COLCOLLATE %s", $3); free($3); }
   ;

data_type:
     BIT opt_length { $$ = 10000 + $2; }
   | TINYINT opt_length opt_uz { $$ = 10000 + $2; }
   | SMALLINT opt_length opt_uz { $$ = 20000 + $2 + $3; }
   | MEDIUMINT opt_length opt_uz { $$ = 30000 + $2 + $3; }
   | INT opt_length opt_uz { $$ = 40000 + $2 + $3; }
   | INTEGER opt_length opt_uz { $$ = 50000 + $2 + $3; }
   | BIGINT opt_length opt_uz { $$ = 60000 + $2 + $3; }
   | REAL opt_length opt_uz { $$ = 70000 + $2 + $3; }
   | DOUBLE opt_length opt_uz { $$ = 80000 + $2 + $3; }
   | FLOAT opt_length opt_uz { $$ = 90000 + $2 + $3; }
   | DECIMAL opt_length opt_uz { $$ = 110000 + $2 + $3; }
   | DATE { $$ = 100001; }
   | TIME { $$ = 100002; }
   | TIMESTAMP { $$ = 100003; }
   | DATETIME { $$ = 100004; }
   | YEAR { $$ = 100005; }
   | CHAR opt_length opt_csc { $$ = 120000 + $2; }
   | VARCHAR '(' INTNUM ')' opt_csc { $$ = 130000 + $3; }
   | BINARY opt_length { $$ = 140000 + $2; }
   | VARBINARY '(' INTNUM ')' { $$ = 150000 + $3; }
   | TINYBLOB { $$ = 160001; }
   | BLOB { $$ = 160002; }
   | MEDIUMBLOB { $$ = 160003; }
   | LONGBLOB { $$ = 160004; }
   | TINYTEXT opt_binary opt_csc { $$ = 170000 + $2; }
   | TEXT opt_binary opt_csc { $$ = 171000 + $2; }
   | MEDIUMTEXT opt_binary opt_csc { $$ = 172000 + $2; }
   | LONGTEXT opt_binary opt_csc { $$ = 173000 + $2; }
   | ENUM '(' enum_list ')' opt_csc { $$ = 200000 + $3; }
   | SET '(' enum_list ')' opt_csc { $$ = 210000 + $3; }
   ;

enum_list: STRING { debug("ENUMVAL %s", $1); free($1); $$ = 1; }
   | enum_list ',' STRING { debug("ENUMVAL %s", $3); free($3); $$ = $1 + 1; }
   ;

create_select_statement: opt_ignore_replace opt_as select_stmt { debug("CREATESELECT %d", $1) }
   ;

opt_ignore_replace: /* nil */ { $$ = 0; }
   | IGNORE { $$ = 1; }
   | REPLACE { $$ = 2; }
   ;

opt_temporary:   /* nil */ { $$ = 0; }
   | TEMPORARY { $$ = 1;}
   ;

   /**** set user variables ****/

stmt: set_stmt { debug("STMT"); }
   ;

    /* -SET */
set_reduce_stmt: SET {
        Stmt *stmt = calloc(1, sizeof(*stmt));
        stmtInit(stmt);
        if (curStmt) {
            stmt->father = curStmt;
        }
        debug("set From %p to child %p", curStmt, stmt);
        curStmt = stmt;
    }
    ;
set_stmt: set_reduce_stmt set_list 
    { curStmt->sql_command = SQLCOM_SET_OPTION; }
    ;

set_list: set_expr | set_list ',' set_expr ;

set_expr:
    USERVAR COMPARISON expr { if ($2 != 4) yyerror("bad set to @%s", $1);
        debug("SET %s", $1); free($1); }
    | USERVAR ASSIGN expr { debug("SET %s", $1); free($1); }
    | NAME COMPARISON expr { debug ("SET %s", $1);
        Item *i = calloc(1, sizeof(*i));
        i->name = strdup($1);
        free($1);
        i->token1 = NAME;
        Item *c = calloc(1, sizeof(*c));
        c->token1 = COMPARISON;
        c->token2 = $2;
        c->left = i;
        c->right = $3;

        listAddNodeTail(curStmt->setList, c); 
    }
    ;

    /* -EXPR */

expr: NAME { debug("NAME %s", $1);
            Item *i = calloc(1, sizeof(Item));
            i->name = strdup($1);
            free($1);
            i->token1 = NAME;
            $$ = i;
        }
   | USERVAR { debug("USERVAR %s", $1);
            Item *i = calloc(1, sizeof(*i));
            i->name = strdup($1);
            free($1);
            i->token1 = USERVAR;
            $$ = i;
       }
   | NAME '.' NAME { debug("FIELDNAME %s.%s", $1, $3); 
            Item *i = calloc(1, sizeof(*i));
            i->prefix = strdup($1);
            i->name = strdup($3);
            free($1);
            free($3);
            i->token1 = NAME;
            $$ = i;
        }
   | STRING { debug("STRING %s", $1); 
            Item *i = calloc(1, sizeof(*i));
            i->name = strdup($1);
            free($1);
            i->token1 = STRING;
            $$ = i;
        }
   | INTNUM { debug("NUMBER %d", $1); 
            Item *i = calloc(1, sizeof(*i));
            i->intNum = $1;
            i->token1 = INTNUM;
            $$ = i;
        }
   | APPROXNUM { debug("FLOAT %g", $1); 
            Item *i = calloc(1, sizeof(*i));
            i->doubleNum = $1;
            i->token1 = APPROXNUM;
            $$ = i;
        }
   | BOOL { debug("BOOL %d", $1); 
            Item *i = calloc(1, sizeof(*i));
            i->intNum = $1;
            i->token1 = BOOL;
            $$ = i;
        }
   ;

expr: expr '+' expr { debug("ADD"); 
            Item *i = calloc(1, sizeof(*i));
            i->token1 = ADD_OP;
            i->left = $1;
            i->right = $3;
            $$ = i;
    }
   | expr '-' expr { debug("SUB"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = SUB_OP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr '*' expr { debug("MUL"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = MUL_OP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr '/' expr { debug("DIV"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = DIV_OP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr '%' expr { debug("MOD"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = MOD;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr MOD expr { debug("MOD"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = MOD;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | '-' expr %prec UMINUS { debug("NEG"); 
        /*TODO*/ 
        Item *i = calloc(1, sizeof(*i));
        i->left = $2;
        $$ = i;
   }
   | expr ANDOP expr { debug("AND"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = ANDOP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   } 
   | expr OR expr { debug("OR"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = OR;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr XOR expr { debug("XOR"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = XOR;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr COMPARISON expr { debug("CMP %d ", $2);
        Item *i = calloc(1, sizeof(*i));
        i->token1 = COMPARISON;
        i->token2 = $2;
        i->left = $1;
        i->right = $3;
        $$ = i;
    }
   | expr COMPARISON '(' select_stmt ')' { debug("CMPSELECT %d", $2); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = COMPARISON;
        i->token2 = $2;
        i->left = $1;
        i->next = $4;
        $$ = i;
   }
   | expr COMPARISON ANY '(' select_stmt ')' { debug("CMPANYSELECT %d", $2); }
   /* TODO */
   | expr COMPARISON SOME '(' select_stmt ')' { debug("CMPANYSELECT %d", $2); }
   | expr COMPARISON ALL '(' select_stmt ')' { debug("CMPALLSELECT %d", $2); }
   | expr '|' expr { debug("BITOR"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = BITOR_OP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr '&' expr { debug("BITAND");
        Item *i = calloc(1, sizeof(*i));
        i->token1 = BITAND_OP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr '^' expr { debug("BITXOR"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = BITXOR_OP;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | expr SHIFT expr { debug("SHIFT %s", $2==1?"left":"right"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = SHIFT;
        i->left = $1;
        i->right = $3;
        $$ = i;
   }
   | NOT expr { debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NOT;
        i->left = $2;
        $$ = i;
   }
   | '!' expr { debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NOT;
        i->left = $2;
        $$ = i;
   }
   | USERVAR ASSIGN expr { debug("ASSIGN @%s", $1); free($1); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = ASSIGN;
        i->name = strdup($1);
        i->right = $3;
        $$ = i;
   }
   | '(' expr ')' {
        $$ = $2; 
   }
   ;

expr:  expr IS NULLX     { debug("ISNULL"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NULLX;
        i->left = $1;
        $$ = i;
    }
   |   expr IS NOT NULLX { debug("ISNULL"); debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NULLX;
        i->token2 = NOT;
        i->left = $1;
        $$ = i;
   }
   | expr COMPARISON NULLX {
        debug(" = NULL or != NULL");
        if (($2 != 4) && ($2 != 12 )) yyerror("bad nullx to %d", $2);
        /* only = and != */
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NULLX;
        i->token2 = $2;
        i->left = $1;
        $$ = i;
   }
   |   expr IS BOOL      { debug("ISBOOL %d", $3); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = BOOL;
        i->left = $1;
        $$ = i;
   }
   |   expr IS NOT BOOL  { debug("ISBOOL %d", $4); debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NOT;
        i->token2 = BOOL;
        i->left = $1;
        $$ = i;
   }
   ;

expr: expr BETWEEN expr AND expr %prec BETWEEN { debug("BETWEEN"); 
        /* TODO */
        Item *i = calloc(1, sizeof(*i));
        i->token1 = BETWEEN;
        i->token2 = BOOL;
        i->left = $1;
        $$ = i;
    }
    ;

    /* (a, b, c)
        list(a, b,c)
    */    
val_list: expr {
        debug("val_list:expr1 %p %s %d %s", $1, $1->name, $1->token1);
        list *val_list = listCreate();
        listAddNodeHead(val_list, $1);
        $$ = val_list;
    }
    | expr ',' val_list {
        debug("val_list:expr2 %p %s", $1, $1->name); 
        listAddNodeHead($3, $1);
        $$ = $3;
    }
    ;

opt_val_list: /* nil */ { $$ = NULL; }
   | val_list
   ;

expr: expr IN '(' val_list ')'       { debug("ISIN %d", $4); 
        /* TODO */
        Item *i = calloc(1, sizeof(*i));
        i->token1 = IN;
        i->left = $1;
        i->right = $4;
        $$ = i;
    }
   | expr NOT IN '(' val_list ')'    { debug("ISIN %d", $5); debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NOT;
        i->token2 = IN;
        i->left = $1;
        i->right = $5;
        $$ = i;
   }
   | expr IN '(' select_stmt ')'     { 
        debug("INSELECT From child %p to father %p", curStmt, curStmt->father); 
        /* TODO difer with val_list */ 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = IN;
        i->token2 = SELECT;
        i->left = $1;
        i->right = $4;
        curStmt = curStmt->father;
        $$ = i;
   }
   | expr NOT IN '(' select_stmt ')' {
        debug("NOTINSELECT From child %p to father %p", curStmt, curStmt->father); 
        /* TODO difer with val_list */ 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = NOT;
        i->token1 = SELECT;
        i->left = $1;
        i->right = $5;
        curStmt = curStmt->father;
        $$ = i;
   }
   | EXISTS '(' select_stmt ')'      { debug("EXISTS"); if($1) debug("NOT"); 
        /* TODO difer with val_list */ 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = EXISTS;
        i->right = NULL;
        $$ = i;
   }
   ;

expr: NAME '(' opt_val_list ')' {
        debug("CALL %d %s", $3, $1); 
        Item *i = calloc(1, sizeof(*i));
        i->name = strdup($1);
        free($1);
        i->token1 = NAME;
        i->right = $3;
        $$ = i;
    }
    ;

  /* functions with special syntax */

expr: FABS '(' expr ')' { NORMAL_FUNCTION(FABS); }
    | FACOS '(' expr ')' { NORMAL_FUNCTION(FACOS); }
    | FADDTIME '(' expr ')' { NORMAL_FUNCTION(FADDTIME); }
    | FAES_DECRYPT '(' expr ')' { NORMAL_FUNCTION(FAES_DECRYPT); }
    | FAES_ENCRYPT '(' expr ')' { NORMAL_FUNCTION(FAES_ENCRYPT); }
    | FAREA '(' expr ')' { NORMAL_FUNCTION(FAREA); }
    | FASBINARY '(' expr ')' { NORMAL_FUNCTION(FASBINARY); }
    | FASIN '(' expr ')' { NORMAL_FUNCTION(FASIN); }
    | FASTEXT '(' expr ')' { NORMAL_FUNCTION(FASTEXT); }
    | FASWKB '(' expr ')' { NORMAL_FUNCTION(FASWKB); }
    | FASWKT '(' expr ')' { NORMAL_FUNCTION(FASWKT); }
    | FATAN '(' expr ')' { NORMAL_FUNCTION(FATAN); }
    | FATAN2 '(' expr ')' { NORMAL_FUNCTION(FATAN2); }
    | FASCII '(' expr ')' { NORMAL_FUNCTION(FASCII); }
    | FAVG '(' expr ')' { NORMAL_FUNCTION(FAVG); }
    | FADDDATE '(' expr ')' { NORMAL_FUNCTION(FADDDATE); }
    | FBENCHMARK '(' expr ')' { NORMAL_FUNCTION(FBENCHMARK); }
    | FBIN '(' expr ')' { NORMAL_FUNCTION(FBIN); }
    | FBIT_AND '(' expr ')' { NORMAL_FUNCTION(FBIT_AND); }
    | FBIT_OR '(' expr ')' { NORMAL_FUNCTION(FBIT_OR); }
    | FBIT_XOR '(' expr ')' { NORMAL_FUNCTION(FBIT_XOR); }
    | FBIT_COUNT '(' expr ')' { NORMAL_FUNCTION(FBIT_COUNT); }
    | FBIT_LENGTH '(' expr ')' { NORMAL_FUNCTION(FBIT_LENGTH); }
    | FCAST '(' expr ')' { NORMAL_FUNCTION(FCAST); }
    | FCEILING '(' expr ')' { NORMAL_FUNCTION(FCEILING); }
    | FCENTROID '(' expr ')' { NORMAL_FUNCTION(FCENTROID); }
    | FCHAR '(' expr ')' { NORMAL_FUNCTION(FCHAR); }
    | FCHARACTER_LENGTH '(' expr ')' { NORMAL_FUNCTION(FCHARACTER_LENGTH); }
    | FCOERCIBILITY '(' expr ')' { NORMAL_FUNCTION(FCOERCIBILITY); }
    | FCOMPRESS '(' expr ')' { NORMAL_FUNCTION(FCOMPRESS); }
    /* | FCONCAT '(' expr ')' { NORMAL_FUNCTION(FCONCAT); } */
    | FCONCAT_WS '(' expr ')' { NORMAL_FUNCTION(FCONCAT_WS); }
    | FCONNECTION_ID '(' expr ')' { NORMAL_FUNCTION(FCONNECTION_ID); }
    | FCONV '(' expr ')' { NORMAL_FUNCTION(FCONV); }
    | FCONVERT_TZ '(' expr ')' { NORMAL_FUNCTION(FCONVERT_TZ); }
    | FCOS '(' expr ')' { NORMAL_FUNCTION(FCOS); }
    | FCOT '(' expr ')' { NORMAL_FUNCTION(FCOT); }
    | FCRC32 '(' expr ')' { NORMAL_FUNCTION(FCRC32); }
    | FCROSSESS '(' expr ')' { NORMAL_FUNCTION(FCROSSESS); }
    | FCOUNT '(' expr ')' { NORMAL_FUNCTION(FCOUNT); }
    | FCOUNT '(' '*' ')' { NORMAL_FUNCTION_WILD(FCOUNT); }
    | FCHARSET '(' expr ')' { NORMAL_FUNCTION(FCHARSET); }
    | FCOLLATION '(' expr ')' { NORMAL_FUNCTION(FCOLLATION); }
    | FCURRENT_USER '(' expr ')' { NORMAL_FUNCTION(FCURRENT_USER); }
    | FCURDATE '(' ')' { NORMAL_FUNCTION_NO_PARAM(FCURDATE); }
    | FCURRENT_DATE '(' expr ')' { NORMAL_FUNCTION(FCURRENT_DATE); }
    | FCURTIME '(' ')' { NORMAL_FUNCTION_NO_PARAM(FCURTIME); }
    | FCURTIME_TIME '(' expr ')' { NORMAL_FUNCTION(FCURTIME_TIME); }
    | FCURTIME_TIMESTAMP '(' expr ')' { NORMAL_FUNCTION(FCURTIME_TIMESTAMP); }
    | FDATE '(' expr ')' { NORMAL_FUNCTION(FDATE); }
    | FDATEDIFF '(' expr ')' { NORMAL_FUNCTION(FDATEDIFF); }
    | FDATENAME '(' expr ')' { NORMAL_FUNCTION(FDATENAME); }
    | FDATEOFMONTH '(' expr ')' { NORMAL_FUNCTION(FDATEOFMONTH); }
    | FDATEOFWEEK '(' expr ')' { NORMAL_FUNCTION(FDATEOFWEEK); }
    | FDATEOFYEAR '(' expr ')' { NORMAL_FUNCTION(FDATEOFYEAR); }
    | FDATE_ADD '(' expr ')' { NORMAL_FUNCTION(FDATE_ADD); }
    | FDATE_SUB '(' expr ')' { NORMAL_FUNCTION(FDATE_SUB); }
    | FDATE_FORMAT '(' expr ')' { NORMAL_FUNCTION(FDATE_FORMAT); }
    | FDATABASE '(' expr ')' { NORMAL_FUNCTION(FDATABASE); }
    | FDEFAULT '(' expr ')' { NORMAL_FUNCTION(FDEFAULT); }
    | FDECODE '(' expr ')' { NORMAL_FUNCTION(FDECODE); }
    | FDEGREES '(' expr ')' { NORMAL_FUNCTION(FDEGREES); }
    | FDES_DECRYPT '(' expr ')' { NORMAL_FUNCTION(FDES_DECRYPT); }
    | FDES_ENCRYPT '(' expr ')' { NORMAL_FUNCTION(FDES_ENCRYPT); }
    | FDIMENSION '(' expr ')' { NORMAL_FUNCTION(FDIMENSION); }
    | FISJOINT '(' expr ')' { NORMAL_FUNCTION(FISJOINT); }
    | FELT '(' expr ')' { NORMAL_FUNCTION(FELT); }
    | FENCODE '(' expr ')' { NORMAL_FUNCTION(FENCODE); }
    | FENCRYPT '(' expr ')' { NORMAL_FUNCTION(FENCRYPT); }
    | FENDPOINT '(' expr ')' { NORMAL_FUNCTION(FENDPOINT); }
    | FENVELOPE '(' expr ')' { NORMAL_FUNCTION(FENVELOPE); }
    | FEQUALS '(' expr ')' { NORMAL_FUNCTION(FEQUALS); }
    | FEXP '(' expr ')' { NORMAL_FUNCTION(FEXP); }
    | FEXPORT_SET '(' expr ')' { NORMAL_FUNCTION(FEXPORT_SET); }
    | FEXTERIORRING '(' expr ')' { NORMAL_FUNCTION(FEXTERIORRING); }
    | FEXTRACTVALUE '(' expr ')' { NORMAL_FUNCTION(FEXTRACTVALUE); }
    | FFIELD '(' expr ')' { NORMAL_FUNCTION(FFIELD); }
    | FFIND_IN_SET '(' expr ')' { NORMAL_FUNCTION(FFIND_IN_SET); }
    | FFLOOR '(' expr ')' { NORMAL_FUNCTION(FFLOOR); }
    | FFORMAT '(' expr ')' { NORMAL_FUNCTION(FFORMAT); }
    | FFOUND_ROWS '(' expr ')' { NORMAL_FUNCTION(FFOUND_ROWS); }
    | FFROM_DAYS '(' expr ')' { NORMAL_FUNCTION(FFROM_DAYS); }
    | FFROM_UNIXTIME '(' expr ')' { NORMAL_FUNCTION(FFROM_UNIXTIME); }
    | FGET_FORMAT '(' expr ')' { NORMAL_FUNCTION(FGET_FORMAT); }
    | FGEOMCOLLFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FGEOMCOLLFROMTEXT); }
    | FGEOMCOLLFROMWKB '(' expr ')' { NORMAL_FUNCTION(FGEOMCOLLFROMWKB); }
    | FGEOMETRYCOLLECTIONFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FGEOMETRYCOLLECTIONFROMTEXT); }
    | FGEOMETRYCOLLECTIONFROMWKB '(' expr ')' { NORMAL_FUNCTION(FGEOMETRYCOLLECTIONFROMWKB); }
    | FGEOMETRYFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FGEOMETRYFROMTEXT); }
    | FGEOMETRYFROMWKB '(' expr ')' { NORMAL_FUNCTION(FGEOMETRYFROMWKB); }
    | FGEOMETRYN '(' expr ')' { NORMAL_FUNCTION(FGEOMETRYN); }
    | FGEOMETRYTYPE '(' expr ')' { NORMAL_FUNCTION(FGEOMETRYTYPE); }
    | FGEOMFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FGEOMFROMTEXT); }
    | FGEOMFROMWKB '(' expr ')' { NORMAL_FUNCTION(FGEOMFROMWKB); }
    | FGET_LOCK '(' expr ')' { NORMAL_FUNCTION(FGET_LOCK); }
    | FGLENGTH '(' expr ')' { NORMAL_FUNCTION(FGLENGTH); }
    | FGREATEST '(' expr ')' { NORMAL_FUNCTION(FGREATEST); }
    | FHEX '(' expr ')' { NORMAL_FUNCTION(FHEX); }
    | FHOUR '(' expr ')' { NORMAL_FUNCTION(FHOUR); }
    | FINSERT '(' expr ')' { NORMAL_FUNCTION(FINSERT); }
    | FINSTR '(' expr ')' { NORMAL_FUNCTION(FINSTR); }
    /* | FIFNULL '(' expr ')' { NORMAL_FUNCTION(FIFNULL); } */
    | FINET_ATON '(' expr ')' { NORMAL_FUNCTION(FINET_ATON); }
    | FINET_NTOA '(' expr ')' { NORMAL_FUNCTION(FINET_NTOA); }
    | FINTERIORRINGN '(' expr ')' { NORMAL_FUNCTION(FINTERIORRINGN); }
    | FINTERSECTS '(' expr ')' { NORMAL_FUNCTION(FINTERSECTS); }
    | FISCLOSED '(' expr ')' { NORMAL_FUNCTION(FISCLOSED); }
    | FISEMPTY '(' expr ')' { NORMAL_FUNCTION(FISEMPTY); }
    | FISNULL '(' expr ')' { NORMAL_FUNCTION(FISNULL); }
    | FISSIMPLE '(' expr ')' { NORMAL_FUNCTION(FISSIMPLE); }
    | FIS_FREE_LOCK '(' expr ')' { NORMAL_FUNCTION(FIS_FREE_LOCK); }
    | FIS_USED_LOCK '(' expr ')' { NORMAL_FUNCTION(FIS_USED_LOCK); }
    | FLAST_DAY '(' expr ')' { NORMAL_FUNCTION(FLAST_DAY); }
    | FLAST_INSERT_ID '(' expr ')' { NORMAL_FUNCTION(FLAST_INSERT_ID); }
    | FLCASE '(' expr ')' { NORMAL_FUNCTION(FLCASE); }
    | FLEFT '(' expr ')' { NORMAL_FUNCTION(FLEFT); }
    | FLENGTH '(' expr ')' { NORMAL_FUNCTION(FLENGTH); }
    | FLINEFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FLINEFROMTEXT); }
    | FLINEFROMWKB '(' expr ')' { NORMAL_FUNCTION(FLINEFROMWKB); }
    | FLINESTRINGFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FLINESTRINGFROMTEXT); }
    | FLINESTRINGFROMWKB '(' expr ')' { NORMAL_FUNCTION(FLINESTRINGFROMWKB); }
    | FLN '(' expr ')' { NORMAL_FUNCTION(FLN); }
    | FLOAD_FILE '(' expr ')' { NORMAL_FUNCTION(FLOAD_FILE); }
    | FLOCATE '(' expr ')' { NORMAL_FUNCTION(FLOCATE); }
    | FLOG '(' expr ')' { NORMAL_FUNCTION(FLOG); }
    | FLOG10 '(' expr ')' { NORMAL_FUNCTION(FLOG10); }
    | FLOG2 '(' expr ')' { NORMAL_FUNCTION(FLOG2); }
    | FLOWER '(' expr ')' { NORMAL_FUNCTION(FLOWER); }
    | FLPAD '(' expr ')' { NORMAL_FUNCTION(FLPAD); }
    | FLTRIM '(' expr ')' { NORMAL_FUNCTION(FLTRIM); }
    | FLOCALTIME '(' expr ')' { NORMAL_FUNCTION(FLOCALTIME); }
    | FLOCALTIMESTAMP '(' expr ')' { NORMAL_FUNCTION(FLOCALTIMESTAMP); }
    | FMAKEDATE '(' expr ')' { NORMAL_FUNCTION(FMAKEDATE); }
    | FMAKETIME '(' expr ')' { NORMAL_FUNCTION(FMAKETIME); }
    | FMAKE_SET '(' expr ')' { NORMAL_FUNCTION(FMAKE_SET); }
    | FMASTER_POS_WAIT '(' expr ')' { NORMAL_FUNCTION(FMASTER_POS_WAIT); }
    | FMBRCONTAINS '(' expr ')' { NORMAL_FUNCTION(FMBRCONTAINS); }
    | FMBRDISJOINT '(' expr ')' { NORMAL_FUNCTION(FMBRDISJOINT); }
    | FMBREQUAL '(' expr ')' { NORMAL_FUNCTION(FMBREQUAL); }
    | FMBRINTERSECTS '(' expr ')' { NORMAL_FUNCTION(FMBRINTERSECTS); }
    | FMBROVERLAPS '(' expr ')' { NORMAL_FUNCTION(FMBROVERLAPS); }
    | FMBRTOUCHES '(' expr ')' { NORMAL_FUNCTION(FMBRTOUCHES); }
    | FMBRWITHIN '(' expr ')' { NORMAL_FUNCTION(FMBRWITHIN); }
    | FMD5 '(' expr ')' { NORMAL_FUNCTION(FMD5); }
    | FMLINEFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FMLINEFROMTEXT); }
    | FMLINEFROMWKB '(' expr ')' { NORMAL_FUNCTION(FMLINEFROMWKB); }
    | FMONTHNAME '(' expr ')' { NORMAL_FUNCTION(FMONTHNAME); }
    | FMPOINTFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FMPOINTFROMTEXT); }
    | FMPOINTFROMWKB '(' expr ')' { NORMAL_FUNCTION(FMPOINTFROMWKB); }
    | FMPOLYFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FMPOLYFROMTEXT); }
    | FMPOLYFROMWKB '(' expr ')' { NORMAL_FUNCTION(FMPOLYFROMWKB); }
    | FMULTILINESTRINGFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FMULTILINESTRINGFROMTEXT); }
    | FMULTILINESTRINGFROMWKB '(' expr ')' { NORMAL_FUNCTION(FMULTILINESTRINGFROMWKB); }
    | FMULTIPOINTFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FMULTIPOINTFROMTEXT); }
    | FMULTIPOINTFROMWKB '(' expr ')' { NORMAL_FUNCTION(FMULTIPOINTFROMWKB); }
    | FMULTIPOLYGONFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FMULTIPOLYGONFROMTEXT); }
    | FMULTIPOLYGONFROMWKB '(' expr ')' { NORMAL_FUNCTION(FMULTIPOLYGONFROMWKB); }
    | FMICROSECOND '(' expr ')' { NORMAL_FUNCTION(FMICROSECOND); }
    | FMINUTE '(' expr ')' { NORMAL_FUNCTION(FMINUTE); }
    | FMONTH '(' expr ')' { NORMAL_FUNCTION(FMONTH); }
    | FGROUP_CONCAT '(' expr ')' { NORMAL_FUNCTION(FGROUP_CONCAT); }
    | FMAX '(' expr ')' { NORMAL_FUNCTION(FMAX); }
    | FMID '(' expr ')' { NORMAL_FUNCTION(FMID); }
    | FMIN '(' expr ')' { NORMAL_FUNCTION(FMIN); }
    | FMOD '(' expr ')' { NORMAL_FUNCTION(FMOD); }
    | FNOW '(' expr ')' { NORMAL_FUNCTION(FNOW); }
    | FNAME_CONST '(' expr ')' { NORMAL_FUNCTION(FNAME_CONST); }
    | FNULLIF '(' expr ')' { NORMAL_FUNCTION(FNULLIF); }
    | FNUMGEOMETRIES '(' expr ')' { NORMAL_FUNCTION(FNUMGEOMETRIES); }
    | FNUMINTERIORRINGS '(' expr ')' { NORMAL_FUNCTION(FNUMINTERIORRINGS); }
    | FNUMPOINTS '(' expr ')' { NORMAL_FUNCTION(FNUMPOINTS); }
    | FOCT '(' expr ')' { NORMAL_FUNCTION(FOCT); }
    | FOCTET_LENGTH '(' expr ')' { NORMAL_FUNCTION(FOCTET_LENGTH); }
    | FORD '(' expr ')' { NORMAL_FUNCTION(FORD); }
    | FOVERLAPS '(' expr ')' { NORMAL_FUNCTION(FOVERLAPS); }
    | FOLD_PASSWORD '(' expr ')' { NORMAL_FUNCTION(FOLD_PASSWORD); }
    | FPERIOD_ADD '(' expr ')' { NORMAL_FUNCTION(FPERIOD_ADD); }
    | FPERIOD_DIFF '(' expr ')' { NORMAL_FUNCTION(FPERIOD_DIFF); }
    | FPI '(' expr ')' { NORMAL_FUNCTION(FPI); }
    | FPOSITION '(' expr ')' { NORMAL_FUNCTION(FPOSITION); }
    | FPASSWORD '(' expr ')' { NORMAL_FUNCTION(FPASSWORD); }
    | FPOINTFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FPOINTFROMTEXT); }
    | FPOINTFROMWKB '(' expr ')' { NORMAL_FUNCTION(FPOINTFROMWKB); }
    | FPOINTN '(' expr ')' { NORMAL_FUNCTION(FPOINTN); }
    | FPOLYFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FPOLYFROMTEXT); }
    | FPOLYFROMWKB '(' expr ')' { NORMAL_FUNCTION(FPOLYFROMWKB); }
    | FPOLYGONFROMTEXT '(' expr ')' { NORMAL_FUNCTION(FPOLYGONFROMTEXT); }
    | FPOLYGONFROMWKB '(' expr ')' { NORMAL_FUNCTION(FPOLYGONFROMWKB); }
    | FPOW '(' expr ')' { NORMAL_FUNCTION(FPOW); }
    | FPOWER '(' expr ')' { NORMAL_FUNCTION(FPOWER); }
    | FQUARTER '(' expr ')' { NORMAL_FUNCTION(FQUARTER); }
    | FQUOTE '(' expr ')' { NORMAL_FUNCTION(FQUOTE); }
    | FRADIANS '(' expr ')' { NORMAL_FUNCTION(FRADIANS); }
    | FRAND '(' expr ')' { NORMAL_FUNCTION(FRAND); }
    | FROUND '(' expr ')' { NORMAL_FUNCTION(FROUND); }
    | FROW_COUNT '(' expr ')' { NORMAL_FUNCTION(FROW_COUNT); }
    | FREPEAT '(' expr ')' { NORMAL_FUNCTION(FREPEAT); }
    | FREPLACE '(' expr ')' { NORMAL_FUNCTION(FREPLACE); }
    | FREVERSE '(' expr ')' { NORMAL_FUNCTION(FREVERSE); }
    | FRIGHT '(' expr ')' { NORMAL_FUNCTION(FRIGHT); }
    | FRPAD '(' expr ')' { NORMAL_FUNCTION(FRPAD); }
    | FRTRIM '(' expr ')' { NORMAL_FUNCTION(FRTRIM); }
    | FRELEASE_LOCK '(' expr ')' { NORMAL_FUNCTION(FRELEASE_LOCK); }
    | FSEC_TO_TIME '(' expr ')' { NORMAL_FUNCTION(FSEC_TO_TIME); }
    | FSEC_TO_DATE '(' expr ')' { NORMAL_FUNCTION(FSEC_TO_DATE); }
    | FSHA '(' expr ')' { NORMAL_FUNCTION(FSHA); }
    | FSHA1 '(' expr ')' { NORMAL_FUNCTION(FSHA1); }
    | FSIGN '(' expr ')' { NORMAL_FUNCTION(FSIGN); }
    | FSIN '(' expr ')' { NORMAL_FUNCTION(FSIN); }
    | FSLEEP '(' expr ')' { NORMAL_FUNCTION(FSLEEP); }
    | FSCHEMA '(' expr ')' { NORMAL_FUNCTION(FSCHEMA); }
    | FSOUNDEX '(' expr ')' { NORMAL_FUNCTION(FSOUNDEX); }
    | FSPACE '(' expr ')' { NORMAL_FUNCTION(FSPACE); }
    | FSQRT '(' expr ')' { NORMAL_FUNCTION(FSQRT); }
    | FSRID '(' expr ')' { NORMAL_FUNCTION(FSRID); }
    | FSTARTPOINT '(' expr ')' { NORMAL_FUNCTION(FSTARTPOINT); }
    | FSTRCMP '(' expr ')' { NORMAL_FUNCTION(FSTRCMP); }
    | FSTR_TO_DATE '(' expr ')' { NORMAL_FUNCTION(FSTR_TO_DATE); }
    | FSECOND '(' expr ')' { NORMAL_FUNCTION(FSECOND); }
    | FSUBTIME '(' expr ')' { NORMAL_FUNCTION(FSUBTIME); }
    /*| FSUBSTRING '(' expr ')' { NORMAL_FUNCTION(FSUBSTRING); } */
    | FSUBSTRING_INDEX '(' expr ')' { NORMAL_FUNCTION(FSUBSTRING_INDEX); }
    | FSESSION_USER '(' expr ')' { NORMAL_FUNCTION(FSESSION_USER); }
    | FSTD '(' expr ')' { NORMAL_FUNCTION(FSTD); }
    | FSTDDEV '(' expr ')' { NORMAL_FUNCTION(FSTDDEV); }
    | FSTDDEV_POP '(' expr ')' { NORMAL_FUNCTION(FSTDDEV_POP); }
    | FSTDDEV_SAMP '(' expr ')' { NORMAL_FUNCTION(FSTDDEV_SAMP); }
    | FSUBDATE '(' expr ')' { NORMAL_FUNCTION(FSUBDATE); }
    | FSUM '(' expr ')' { NORMAL_FUNCTION(FSUM); }
    | FSUM'(' '*' ')' { NORMAL_FUNCTION_WILD(FSUM); }
    | FSYSDATE '(' expr ')' { NORMAL_FUNCTION(FSYSDATE); }
    | FSYSTEM_USER '(' expr ')' { NORMAL_FUNCTION(FSYSTEM_USER); }
    | FTAN '(' expr ')' { NORMAL_FUNCTION(FTAN); }
    | FTIMEDIFF '(' expr ')' { NORMAL_FUNCTION(FTIMEDIFF); }
    | FTIME_FORMAT '(' expr ')' { NORMAL_FUNCTION(FTIME_FORMAT); }
    | FTIME_TO_SEC '(' expr ')' { NORMAL_FUNCTION(FTIME_TO_SEC); }
    | FTRUNCATE '(' expr ')' { NORMAL_FUNCTION(FTRUNCATE); }
    | FTOUCHES '(' expr ')' { NORMAL_FUNCTION(FTOUCHES); }
    | FTO_DAYS '(' expr ')' { NORMAL_FUNCTION(FTO_DAYS); }
    /*| FTRIM '(' expr ')' { NORMAL_FUNCTION(FTRIM); } */
    | FTIME '(' expr ')' { NORMAL_FUNCTION(FTIME); }
    | FTIMESTAMP '(' expr ')' { NORMAL_FUNCTION(FTIMESTAMP); }
    | FTIMESTAMPADD '(' expr ')' { NORMAL_FUNCTION(FTIMESTAMPADD); }
    | FTIMESTAMPDIFF '(' expr ')' { NORMAL_FUNCTION(FTIMESTAMPDIFF); }
    | FVARIANCE '(' expr ')' { NORMAL_FUNCTION(FVARIANCE); }
    | FVAR_POP '(' expr ')' { NORMAL_FUNCTION(FVAR_POP); }
    | FVAR_SAMP '(' expr ')' { NORMAL_FUNCTION(FVAR_SAMP); }
    | FUCASE '(' expr ')' { NORMAL_FUNCTION(FUCASE); }
    | FUNCOMPRESS '(' expr ')' { NORMAL_FUNCTION(FUNCOMPRESS); }
    | FUNCOMPRESSED_LENGTH '(' expr ')' { NORMAL_FUNCTION(FUNCOMPRESSED_LENGTH); }
    | FUNHEX '(' expr ')' { NORMAL_FUNCTION(FUNHEX); }
    | FUSER '(' expr ')' { NORMAL_FUNCTION(FUSER); }
    | FUNIX_TIMESTAMP '(' expr ')' { NORMAL_FUNCTION(FUNIX_TIMESTAMP); }
    | FUPDATEXML '(' expr ')' { NORMAL_FUNCTION(FUPDATEXML); }
    | FUPPER '(' expr ')' { NORMAL_FUNCTION(FUPPER); }
    | FUUID '(' expr ')' { NORMAL_FUNCTION(FUUID); }
    | FUUID_SHORT '(' expr ')' { NORMAL_FUNCTION(FUUID_SHORT); }
    | FVERSION '(' expr ')' { NORMAL_FUNCTION(FVERSION); }
    | FUTC_DATE '(' expr ')' { NORMAL_FUNCTION(FUTC_DATE); }
    | FUTC_TIME '(' expr ')' { NORMAL_FUNCTION(FUTC_TIME); }
    | FUTC_TIMESTAMP '(' expr ')' { NORMAL_FUNCTION(FUTC_TIMESTAMP); }
    | FWEEK '(' expr ')' { NORMAL_FUNCTION(FWEEK); }
    | FWEEKDAY '(' expr ')' { NORMAL_FUNCTION(FWEEKDAY); }
    | FWEEKOFYEAR '(' expr ')' { NORMAL_FUNCTION(FWEEKOFYEAR); }
    | FYEAR '(' expr ')' { NORMAL_FUNCTION(FYEAR); }
    | FYEARWEEK '(' expr ')' { NORMAL_FUNCTION(FYEARWEEK); }
    | FX '(' expr ')' { NORMAL_FUNCTION(FX); }
    | FY '(' expr ')' { NORMAL_FUNCTION(FY); }

expr: FSUBSTRING '(' val_list ')' {
        debug("CALL SUBSTR");
        Item *i = calloc(1, sizeof(*i));
        i->right = $3;
        i->token1 = FSUBSTRING;
        $$ = i;
    }
    |FCONCAT '(' val_list ')' {
        debug("CALL SUBSTR");
        Item *i = calloc(1, sizeof(*i));
        i->right = $3;
        i->token1 = FCONCAT;
        $$ = i;
    }
    | FSUBSTRING '(' expr FROM expr ')' {  debug("CALL 2 SUBSTR"); }
    | FSUBSTRING '(' expr FROM expr FOR expr ')' {  debug("CALL 3 SUBSTR"); }
    | FTRIM '(' val_list ')' { 
        debug("CALL TRIM"); 
        Item *i = calloc(1, sizeof(*i));
        i->right = $3;
        i->token1 = FTRIM;
        $$ = i;
    }
    | FTRIM '(' trim_ltb expr FROM val_list ')' { debug("CALL 3 TRIM"); }
    | FIFNULL'(' val_list')'            {
        debug("CALL IFNULL");
        Item *i = calloc(1, sizeof(*i));
        i->right = $3;
        i->token1 = FIFNULL;
        $$ = i;
    }
    ;

trim_ltb: LEADING { debug("INT 1"); }
   | TRAILING { debug("INT 2"); }
   | BOTH { debug("INT 3"); }
   ;

expr: FDATE_ADD '(' expr ',' interval_exp ')' { debug("CALL 3 DATE_ADD"); }
   |  FDATE_SUB '(' expr ',' interval_exp ')' { debug("CALL 3 DATE_SUB"); }
   ;

interval_exp: INTERVAL expr DAY_HOUR { debug("NUMBER 1"); }
   | INTERVAL expr DAY_MICROSECOND { debug("NUMBER 2"); }
   | INTERVAL expr DAY_MINUTE { debug("NUMBER 3"); }
   | INTERVAL expr DAY_SECOND { debug("NUMBER 4"); }
   | INTERVAL expr YEAR_MONTH { debug("NUMBER 5"); }
   | INTERVAL expr YEAR       { debug("NUMBER 6"); }
   | INTERVAL expr HOUR_MICROSECOND { debug("NUMBER 7"); }
   | INTERVAL expr HOUR_MINUTE { debug("NUMBER 8"); }
   | INTERVAL expr HOUR_SECOND { debug("NUMBER 9"); }
   ;

expr: CASE expr case_list END               {
    debug("CASE");
    Item *c = calloc(1, sizeof(*c));
    c->token1 = CASE;
    c->left = $2;
    c->next = $3;
    $$ = c;

    } |  CASE expr case_list ELSE expr END  {
    debug("CASE ELSE");
    Item *c = calloc(1, sizeof(*c));
    c->token1 = CASE;
    c->token2 = ELSE;
    c->left = $2;
    c->right = $5;
    c->next = $3;
    $$ = c;

    } |  CASE case_list END                 {
    debug("CASE ");
    Item *c = calloc(1, sizeof(*c));
    c->token1 = CASE;
    c->next = $2;
    $$ = c;
    
    } |  CASE case_list ELSE expr END       {
    debug("CASE ELSE");
    Item *c = calloc(1, sizeof(*c));
    c->token1 = CASE;
    c->token2 = ELSE;
    c->right = $4;
    c->next = $2;
    $$ = c;

    };

case_list: WHEN expr THEN expr     {
        debug("WHEN THEN ");

        Item *then = calloc(1, sizeof(*then));
        then->token1 = THEN;
        then->left = $4;

        Item *i= calloc(1, sizeof(*i));
        i->token1 = WHEN;
        i->left = $2;

        list *l = listCreate();
        listAddNodeTail(l, i);
        listAddNodeTail(l, then);
        $$ = l;
    } | case_list WHEN expr THEN expr {
        debug("WHEN THEN ");

        Item *then = calloc(1, sizeof(*then));
        then->token1 = THEN;
        then->left = $3;

        Item *i= calloc(1, sizeof(*i));
        i->token1 = WHEN;
        i->left = $5;

        listAddNodeTail($1, i);
        listAddNodeTail($1, then);
        $$ = $1;
    };

expr: expr LIKE expr { 
        debug("LIKE");
        Item *i = calloc(1, sizeof(*i));
        i->token1 = LIKE;
        i->left = $1;
        i->right = $3;
        $$ = i;
    }
    | expr NOT LIKE expr { 
        debug("LIKE"); debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = LIKE;
        i->token2 = NOT;
        i->left = $1;
        i->right = $4;
        $$ = i;
    };

expr: expr REGEXP expr {
        debug("REGEXP");
        Item *i = calloc(1, sizeof(*i));
        i->token1 = REGEXP;
        i->left = $1;
        i->right = $3;
        $$ = i;
    }
    | expr NOT REGEXP expr { 
        debug("REGEXP"); debug("NOT"); 
        Item *i = calloc(1, sizeof(*i));
        i->token1 = REGEXP;
        i->token2 = NOT;
        i->left = $1;
        i->right = $4;
        $$ = i;
    };

expr: CURRENT_TIMESTAMP { debug("NOW") };
   | CURRENT_DATE    { debug("NOW") };
   | CURRENT_TIME    { debug("NOW") };
   ;

expr: BINARY expr %prec UMINUS { debug("STRTOBIN"); }
   ;

%%

void debug(char *s, ...) {
    va_list ap;
    va_start(ap, s);
     
    printf("rpn: ");
    vfprintf(stdout, s, ap);
    printf("\n");
    
    
}

void
yyerror(char *s, ...)
{
  extern yylineno;

  va_list ap;
  va_start(ap, s);

  fprintf(stderr, "%d: error: ", yylineno);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

