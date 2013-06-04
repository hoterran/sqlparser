%option noyywrap nodefault yylineno case-insensitive
%{
#include "adlist.h"
#include "sql.h"
#include "sql.tab.h"
#include <stdarg.h>
#include <string.h>

void yyerror(char *s, ...);

int oldstate;

%}

    /* comment */
%x COMMENT
    /* between */
%s BTWMODE 

%%

    /* reserved key */
ACCESSIBLE  { return ACCESSIBLE; }
ADD         { return ADD; }
ALL         { return ALL; }
ALTER       { return ALTER; }
ANALYZE     { return ANALYZE; }

    /* Hack for BETWEEN ... AND ... 
     * return special AND token if BETWEEN seen
    */
<BTWMODE>AND    { BEGIN INITIAL; return AND; }
AND    { return ANDOP; }
AS    { return AS; }
ASC    { return ASC; }
ASENSITIVE { return ASENSITIVE;}

    /*AUTO_INCREMENT    { return AUTO_INCREMENT; } */
BEFORE    { return BEFORE; }
BETWEEN    { BEGIN BTWMODE; return BETWEEN; }
INT8|BIGINT    { return BIGINT; }
BINARY    { return BINARY; }
    /* BIT    { return BIT; } */
BLOB    { return BLOB; }
BOTH    { return BOTH; }
BY    { return BY; }
CALL    { return CALL; }
CASCADE    { return CASCADE; }
CASE    { return CASE; }
CHANGE    { return CHANGE; }
CHAR(ACTER)?    { return CHAR; }
CHECK    { return CHECK; }
COLLATE    { return COLLATE; }
COLUMN    { return COLUMN; }
    /* COMMENT    { return COMMENT; } */
CONDITION    { return CONDITION; }
    /* CONNECTION   { return CONNECTION; } */
CONSTRAINT    { return CONSTRAINT; }
CONTINUE    { return CONTINUE; }
CONVERT    { return CONVERT; }
CREATE    { return CREATE; }
CROSS    { return CROSS; }
CURRENT_DATE    { return CURRENT_DATE; }
CURRENT_TIME    { return CURRENT_TIME; }
CURRENT_TIMESTAMP    { return CURRENT_TIMESTAMP; }
CURRENT_USER    { return CURRENT_USER; }
CURSOR    { return CURSOR; }
DATABASE    { return DATABASE; }
DATABASES    { return DATABASES; }
    /* DATE    { return DATE; } */
    /* DATETIME    { return DATETIME; } */
DAY_HOUR    { return DAY_HOUR; }
DAY_MICROSECOND    { return DAY_MICROSECOND; }
DAY_MINUTE    { return DAY_MINUTE; }
DAY_SECOND    { return DAY_SECOND; }
NUMERIC|DEC|DECIMAL    { return DECIMAL; }
DECLARE    { return DECLARE; }
DEFAULT    { return DEFAULT; }
DELAYED    { return DELAYED; }
DELETE    { return DELETE; }
DESC(RIBE)?   { return DESC; }
DETERMINISTIC    { return DETERMINISTIC; }
DISTINCT    { return DISTINCT; }
DISTINCTROW    { return DISTINCTROW; }
DIV    { return DIV; }
FLOAT8|DOUBLE    { return DOUBLE; }
DROP    { return DROP; }
DUAL    { return DUAL; }
EACH    { return EACH; }
ELSE    { return ELSE; }
ELSEIF    { return ELSEIF; }
ENCLOSED    { return ENCLOSED; }
ESCAPED     { return ESCAPED; }
    /* END    { return END; } 
        ENUM { return ENUM; } */
EXISTS    { yylval.subtok = 0; return EXISTS; }
NOT[ \t\n]+EXISTS    { yylval.subtok = 1; return EXISTS; }
EXIT    { return EXIT; }
EXPLAIN    { return EXPLAIN; }
FETCH    { return FETCH; }
FLOAT[4|8]?    { return FLOAT; }
FOR    { return FOR; }
FORCE    { return FORCE; }
FOREIGN    { return FOREIGN; }
FROM    { return FROM; }
FULLTEXT    { return FULLTEXT; }
    /* GOTO    { return GOTO; } */
GRANT    { return GRANT; }
GROUP    { return GROUP; }
    /* GLOBAL { return GLOBAL; } */
HAVING    { return HAVING; }
HIGH_PRIORITY    { return HIGH_PRIORITY; }
HOUR_MICROSECOND    { return HOUR_MICROSECOND; }
HOUR_MINUTE    { return HOUR_MINUTE; }
HOUR_SECOND    { return HOUR_SECOND; }
IF    { return IF; }
IGNORE    { return IGNORE; }
IN    { return IN; }
INDEX    { return INDEX; }
INFILE    { return INFILE; }
INNER    { return INNER; }
INOUT    { return INOUT; }
INSENSITIVE    { return INSENSITIVE; }
INSERT    { return INSERT; }
INT|INT3|INT4|INT8|INTEGER    { return INTEGER; }
INTERVAL    { return INTERVAL; }
INTO    { return INTO; }
IS    { return IS; }
ITERATE    { return ITERATE; }
JOIN    { return JOIN; }
KEY    { return KEY; }
KEYS    { return KEYS; }
KILL    { return KILL; }
    /* LABEL { return LABEL; } */
LEADING    { return LEADING; }
LEAVE    { return LEAVE; }
LEFT    { return LEFT; }
LIKE    { return LIKE; }
LIMIT    { return LIMIT; }
LINER   { return LINER; }
LINES    { return LINES; }
LOAD    { return LOAD; }
LOCALTIME    { return LOCALTIME; }
LOCALTIMESTAMP    { return LOCALTIMESTAMP; }
LOCK    { return LOCK; }
LONG    { return LONG; }
LONGBLOB    { return LONGBLOB; }
LONGTEXT    { return LONGTEXT; }
LOOP    { return LOOP; }
LOW_PRIORITY    { return LOW_PRIORITY; }
MATCH    { return MATCH; }
MEDIUMBLOB    { return MEDIUMBLOB; }
MIDDLEINT|MEDIUMINT    { return MEDIUMINT; }
MEDIUMTEXT    { return MEDIUMTEXT; }
MINUTE_MICROSECOND    { return MINUTE_MICROSECOND; }
MINUTE_SECOND    { return MINUTE_SECOND; }
MOD    { return MOD; }
MODIFIES    { return MODIFIES; }
NATURAL    { return NATURAL; }

SET[ \t\n]+NAMES/[ \t\n]+   { return SETNAMES; }
SET[ \t\n]+CHARACTER/[ \t\n]+ { return SETCHARACTER; }
SET[ \t\n]+PASSWORD/[ \t\n]+ { return SETPASSWORD; }
    /* rds unoffical synatx, dont care */

SET[ \t\n]+OPTION; ;

SET[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+READ[ \t\n]+UNCOMMITTED {
        yylval.strval = strdup("TRANSACTION ISOLATION LEVEL READ UNCOMMITED");  return SETTRAN; 
    }
SET[ \t\n]+GLOBAL[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+READ[ \t\n]+UNCOMMITTED {
        yylval.strval = strdup("GLOBAL TRANSACTION ISOLATION LEVEL READ UNCOMMITED");  return SETTRAN; 
    }
SET[ \t\n]+SESSION[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+READ[ \t\n]+UNCOMMITTED {
        yylval.strval = strdup("SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITED");  return SETTRAN;
    }

SET[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+READ[ \t\n]+COMMITTED {
        yylval.strval = strdup("TRANSACTION ISOLATION LEVEL READ COMMITED");  return SETTRAN; 
    }
SET[ \t\n]+GLOBAL[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+READ[ \t\n]+COMMITTED {
        yylval.strval = strdup("GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITED");  return SETTRAN; 
    }
SET[ \t\n]+SESSION[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+READ[ \t\n]+COMMITTED {
        yylval.strval = strdup("SESSION TRANSACTION ISOLATION LEVEL READ COMMITED");  return SETTRAN;
    }

SET[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+REPEATABLE[ \t\n]+READ {
        yylval.strval = strdup("TRANSACTION ISOLATION LEVEL REPEATABLE READ");  return SETTRAN; 
    }
SET[ \t\n]+GLOBAL[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+REPEATABLE[ \t\n]+READ {
        yylval.strval = strdup("GLOBAL TRANSACTION ISOLATION LEVEL REPEATABLE READ");  return SETTRAN; 
    }
SET[ \t\n]+SESSION[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+REPEATABLE[ \t\n]+READ {
        yylval.strval = strdup("SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ");  return SETTRAN;
    }

SET[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+SERIALIZABLE {
        yylval.strval = strdup("TRANSACTION ISOLATION LEVEL SERIALIZABLE");  return SETTRAN; 
    }
SET[ \t\n]+GLOBAL[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+SERIALIZABLE {
        yylval.strval = strdup("GLOBAL TRANSACTION ISOLATION LEVEL SERIALIZABLE");  return SETTRAN; 
    }
SET[ \t\n]+SESSION[ \t\n]+TRANSACTION[ \t\n]+ISOLATION[ \t\n]+LEVEL[ \t\n]+SERIALIZABLE {
        yylval.strval = strdup("SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE");  return SETTRAN;
    }

NOT    { return NOT; }
NO_WRITE_TO_BINLOG    { return NO_WRITE_TO_BINLOG; }
NULL    { return NULLX; }
NUMERIC { return NUMERIC; }
ON    { return ON; }
ON[ \t\n]+DUPLICATE { return ONDUPLICATE; } /* hack due to limited lookahead */
OPTIMIZE    { return OPTIMIZE; }
OPTION    { return OPTION; }
OPTIONALLY    { return OPTIONALLY; }
OR    { return OR; }
ORDER    { return ORDER; }
OUT    { return OUT; }
OUTER    { return OUTER; }
OUTFILE    { return OUTFILE; }
PRECISION    { return PRECISION; }
PRIMARY    { return PRIMARY; }
PROCEDURE    { return PROCEDURE; }
PURGE    { return PURGE; }
    /* RANGE { return RANGE; } */
    /* QUICK    { return QUICK; } */
READ    { return READ; }
READS    { return READS; }
    /* READ_ONLY { return READ_ONLY ; }
    READ_WRITE { return READ_WRITE ; } */
REAL    { return REAL; }
REFERENCES    { return REFERENCES; }
REGEXP|RLIKE    { return REGEXP; }
RELEASE    { return RELEASE; }
RENAME    { return RENAME; }
REPEAT    { return REPEAT; }
REPLACE    { return REPLACE; }
REQUIRE    { return REQUIRE; }
RESTRICT    { return RESTRICT; }
RETURN    { return RETURN; }
REVOKE    { return REVOKE; }
RIGHT    { return RIGHT; }
    /* ROLLUP    { return ROLLUP; } */
SCHEMA    { return SCHEMA; }
SCHEMAS    { return SCHEMAS; }
SECOND_MICROSECOND    { return SECOND_MICROSECOND; }
SELECT    { return SELECT; }
SENSITIVE    { return SENSITIVE; }
SEPARATOR    { return SEPARATOR; }
    /* SESSION     { return SESSION; } */

SET    { return SET; }

SHOW    { return SHOW; }

SHOW[ \t\n]+COLLATION { return SHOWCOLLATION; }

SHOW[ \t\n]+VARIABLES { yylval.intval = 0; return SHOWVARIABLES; }
SHOW[ \t\n]+GLOBAL[ \t\n]+VARIABLES { yylval.intval = 1;  return SHOWVARIABLES; }
SHOW[ \t\n]+SESSION[ \t\n]+VARIABLES { yylval.intval = 2;  return SHOWVARIABLES; }

INT2|SMALLINT    { return SMALLINT; }
    /* SOME    { return SOME; }
    SONAME    { return SONAME; } */
SPATIAL    { return SPATIAL; }
SPECIFIC    { return SPECIFIC; }
SQL    { return SQL; }
SQLEXCEPTION    { return SQLEXCEPTION; }
SQLSTATE    { return SQLSTATE; }
SQLWARNING    { return SQLWARNING; }
SQL_BIG_RESULT    { return SQL_BIG_RESULT; }
SQL_CALC_FOUND_ROWS    { return SQL_CALC_FOUND_ROWS; }
SQL_SMALL_RESULT    { return SQL_SMALL_RESULT; }
SSL    { return SSL; }
STARTING    { return STARTING; }
STRAIGHT_JOIN    { return STRAIGHT_JOIN; }
TABLE    { return TABLE; }
    /* TEMPORARY    { return TEMPORARY; } */
TERMINATED    { return TERMINATED; }
    /* TEXT    { return TEXT; } */
THEN    { return THEN; }

    /* //TIME    { return TIME; }  time is not keyword can be column name */

TINYBLOB    { return TINYBLOB; }
    /* TIMESTAMP    { return TIMESTAMP; } */
INT1|TINYINT    { return TINYINT; }
TINYTEXT    { return TINYTEXT; }
TO    { return TO; }
TRAILING    { return TRAILING; }
TRIGGER    { return TRIGGER; }
UNDO    { return UNDO; }
UNION    { return UNION; }
UNIQUE    { return UNIQUE; }
UNLOCK    { return UNLOCK; }
UNSIGNED    { return UNSIGNED; }
UPDATE    { return UPDATE; }
USAGE    { return USAGE; }
USE    { return USE; }
USING    { return USING; }
UTC_DATE    { return UTC_DATE; }
UTC_TIME    { return UTC_TIME; }
UTC_TIMESTAMP    { return UTC_TIMESTAMP; }
    /* VARIABLES { return VARIABLES; } */
    /* values or value */
VALUES?[ \t\n]?/"("   { return VALUES; }
VARBINARY    { return VARBINARY; }
VARCHAR(ACTER)?    { return VARCHAR; }
VARYING    { return VARYING; }
WHEN    { return WHEN; }
WHERE    { return WHERE; }
WHILE    { return WHILE; }
WITH    { return WITH; }
WRITE    { return WRITE; }
X509    { return X509; }
XOR    { return XOR; }
    /* YEAR    { return YEAR; } */
YEAR_MONTH    { return YEAR_MONTH; }
ZEROFILL    { return ZEROFILL; }

    /* one line comment */

"--".*\n ;
    /* 
        take care this only for rds normalize sql, 
        other user remove below 
    */
":" ;

   /* numbers */

-?[0-9]+            { yylval.intval = atoi(yytext); return INTNUM; }

-?[0-9]+"."[0-9]* |
-?"."[0-9]+    |
-?[0-9]+E[-+]?[0-9]+    |
-?[0-9]+"."[0-9]*E[-+]?[0-9]+ |
-?"."[0-9]*E[-+]?[0-9]+    { yylval.floatval = atof(yytext); return APPROXNUM; }

    /* booleans */
TRUE    { yylval.intval = 1; return BOOL; }
UNKNOWN    { yylval.intval = -1; return BOOL; }
FALSE    { yylval.intval = 0; return BOOL; }

   /* strings single quote or double quote */
'(\\.|''|[^'\n])*'    |
\"(\\.|\"\"|[^"\n])*\"  { yylval.strval = strdup(yytext); return STRING; }

'(\\.|[^'\n])*$            { yyerror("Unterminated string %s", yytext); }
\"(\\.|[^"\n])*$    { yyerror("Unterminated string %s", yytext); }

   /* hex strings */
X'[0-9A-F]+' |  
0X[0-9A-F]+  { yylval.strval = strdup(yytext); return STRING; }

   /* bit strings */

0B[01]+      |
B'[01]+'     { yylval.strval = strdup(yytext); return STRING; }


   /* operators */
[-+&~|^/%*(),.;!]   { return yytext[0]; }

"&&"        { return ANDOP; }
"||"            { return OR; }

"="        { yylval.subtok = 4; return COMPARISON; }
"<=>"    { yylval.subtok = 12; return COMPARISON; }
">="    { yylval.subtok = 6; return COMPARISON; }
">"        { yylval.subtok = 2; return COMPARISON; }
"<="    { yylval.subtok = 5; return COMPARISON; }
"<"        { yylval.subtok = 1; return COMPARISON; }
"!="    |
"<>"    { yylval.subtok = 3; return COMPARISON; }
"<<"    { yylval.subtok = 1; return SHIFT; }
">>"    { yylval.subtok = 2; return SHIFT; }

    /* functions */

ABS/"(" {return FABS; }
ACOS/"(" {return FACOS; }
ADDTIME/"(" {return FADDTIME; }
AES_DECRYPT/"(" {return FAES_DECRYPT; }
AES_ENCRYPT/"(" {return FAES_ENCRYPT; }
AREA/"(" {return FAREA; }
ASBINARY/"(" {return FASBINARY; }
ASIN/"(" {return FASIN; }
ASTEXT/"(" {return FASTEXT; }
ASWKB/"(" {return FASWKB; }
ASWKT/"(" {return FASWKT; }
ATAN/"(" {return FATAN; }
ATAN2/"(" {return FATAN2; }
ASCII/"(" {return FASCII; }
AVG/"(" {return FAVG; }
ADDDATE/"(" {return FADDDATE; }
BENCHMARK/"(" {return FBENCHMARK; }
BIN/"(" {return FBIN; }
BIT_AND/"(" {return FBIT_AND; }
BIT_OR/"(" {return FBIT_OR; }
BIT_XOR/"(" {return FBIT_XOR; }
BIT_COUNT/"(" {return FBIT_COUNT; }
BIT_LENGTH/"(" {return FBIT_LENGTH; }
CAST/"(" {return FCAST; }
CEIL(ING)?/"(" {return FCEILING; }
CENTROID/"(" {return FCENTROID; }
CHAR/"(" {return FCHAR; }
CHAR(ACTER)?_LENGTH/"(" {return FCHARACTER_LENGTH; }
COERCIBILITY/"(" {return FCOERCIBILITY; }
COMPRESS/"(" {return FCOMPRESS; }
CONCAT/"(" {return FCONCAT; }
CONCAT_WS/"(" {return FCONCAT_WS; }
CONNECTION_ID/"(" {return FCONNECTION_ID; }
CONV/"(" {return FCONV; }
CONVERT_TZ/"(" {return FCONVERT_TZ; }
COS/"(" {return FCOS; }
COT/"(" {return FCOT; }
CRC32/"(" {return FCRC32; }
CROSSESS/"(" {return FCROSSESS; }
COUNT/"(" {return FCOUNT; }
CHARSET/"(" {return FCHARSET; }
COLLATION/"(" {return FCOLLATION; }
CURRENT_USER/"(" {return FCURRENT_USER; }
CURDATE/"(" {return FCURDATE; }
CURRENT_DATE/"(" {return FCURRENT_DATE; }
CURTIME/"(" {return FCURTIME; }
CURTIME_TIME/"(" {return FCURTIME_TIME; }
CURRENT_TIMESTAMP/"(" {return FCURRENT_TIMESTAMP; }
DATE/"(" {return FDATE; }
DATEDIFF/"(" {return FDATEDIFF; }
DATENAME/"(" {return FDATENAME; }
DATEOFMONTH/"(" {return FDATEOFMONTH; }
DATEOFWEEK/"(" {return FDATEOFWEEK; }
DATEOFYEAR/"(" {return FDATEOFYEAR; }
DATE_ADD/"(" {return FDATE_ADD; }
DATE_SUB/"(" {return FDATE_SUB; }
DATE_FORMAT/"(" {return FDATE_FORMAT; }
DATABASE/"(" {return FDATABASE; }

DAY/"(" {return FDAY; }
DAYNAME/"(" {return FDAYNAME; }
DAYOFMONTH/"(" {return FDAYOFMONTH; }
DAYOFWEEK/"(" {return FDAYOFWEEK; }
DAYOFYEAR/"(" {return FDAYOFYEAR; }

DEFAULT/"(" {return FDEFAULT; }
DECODE/"(" {return FDECODE; }
DEGREES/"(" {return FDEGREES; }
DES_DECRYPT/"(" {return FDES_DECRYPT; }
DES_ENCRYPT/"(" {return FDES_ENCRYPT; }
DIMENSION/"(" {return FDIMENSION; }
ISJOINT/"(" {return FISJOINT; }
ELT/"(" {return FELT; }
ENCODE/"(" {return FENCODE; }
ENCRYPT/"(" {return FENCRYPT; }
ENDPOINT/"(" {return FENDPOINT; }
ENVELOPE/"(" {return FENVELOPE; }
EQUALS/"(" {return FEQUALS; }
EXP/"(" {return FEXP; }
EXPORT_SET/"(" {return FEXPORT_SET; }
EXTRACT/"(" {return FEXTRACT; }
EXTERIORRING/"(" {return FEXTERIORRING; }
EXTRACTVALUE/"(" {return FEXTRACTVALUE; }
FIELD/"(" {return FFIELD; }
FIND_IN_SET/"(" {return FFIND_IN_SET; }
FLOOR/"(" {return FFLOOR; }
FORMAT/"(" {return FFORMAT; }
FOUND_ROWS/"(" {return FFOUND_ROWS; }
FROM_DAYS/"(" {return FFROM_DAYS; }
FROM_UNIXTIME/"(" {return FFROM_UNIXTIME; }
GET_FORMAT/"(" {return FGET_FORMAT; }
GEOMCOLLFROMTEXT/"(" {return FGEOMCOLLFROMTEXT; }
GEOMCOLLFROMWKB/"(" {return FGEOMCOLLFROMWKB; }
GEOMETRYCOLLECTIONFROMTEXT/"(" {return FGEOMETRYCOLLECTIONFROMTEXT; }
GEOMETRYCOLLECTIONFROMWKB/"(" {return FGEOMETRYCOLLECTIONFROMWKB; }
GEOMETRYFROMTEXT/"(" {return FGEOMETRYFROMTEXT; }
GEOMETRYFROMWKB/"(" {return FGEOMETRYFROMWKB; }
GEOMETRYN/"(" {return FGEOMETRYN; }
GEOMETRYTYPE/"(" {return FGEOMETRYTYPE; }
GEOMFROMTEXT/"(" {return FGEOMFROMTEXT; }
GEOMFROMWKB/"(" {return FGEOMFROMWKB; }
GET_LOCK/"(" {return FGET_LOCK; }
GLENGTH/"(" {return FGLENGTH; }
GREATEST/"(" {return FGREATEST; }
HEX/"(" {return FHEX; }
HOUR/"(" {return FHOUR; }
INSERT/"(" {return FINSERT; }
INSTR/"(" {return FINSTR; }
IFNULL/"(" {return FIFNULL; }
IF/"(" {return FIF; }
INET_ATON/"(" {return FINET_ATON; }
INET_NTOA/"(" {return FINET_NTOA; }
INTERIORRINGN/"(" {return FINTERIORRINGN; }
INTERSECTS/"(" {return FINTERSECTS; }
ISCLOSED/"(" {return FISCLOSED; }
ISEMPTY/"(" {return FISEMPTY; }
ISNULL/"(" {return FISNULL; }
ISSIMPLE/"(" {return FISSIMPLE; }
IS_FREE_LOCK/"(" {return FIS_FREE_LOCK; }
IS_USED_LOCK/"(" {return FIS_USED_LOCK; }
LAST_DAY/"(" {return FLAST_DAY; }
LAST_INSERT_ID/"(" {return FLAST_INSERT_ID; }
LCASE/"(" {return FLCASE; }
LEFT/"(" {return FLEFT; }
LENGTH/"(" {return FLENGTH; }
LINEFROMTEXT/"(" {return FLINEFROMTEXT; }
LINEFROMWKB/"(" {return FLINEFROMWKB; }
LINESTRINGFROMTEXT/"(" {return FLINESTRINGFROMTEXT; }
LINESTRINGFROMWKB/"(" {return FLINESTRINGFROMWKB; }
LN/"(" {return FLN; }
LOAD_FILE/"(" {return FLOAD_FILE; }
LOCATE/"(" {return FLOCATE; }
LOG/"(" {return FLOG; }
LOG10/"(" {return FLOG10; }
LOG2/"(" {return FLOG2; }
LOWER/"(" {return FLOWER; }
LPAD/"(" {return FLPAD; }
LTRIM/"(" {return FLTRIM; }
LOCALTIME/"(" {return FLOCALTIME; }
LOCALTIMESTAMP/"(" {return FLOCALTIMESTAMP; }
MAKEDATE/"(" {return FMAKEDATE; }
MAKETIME/"(" {return FMAKETIME; }
MAKE_SET/"(" {return FMAKE_SET; }
MASTER_POS_WAIT/"(" {return FMASTER_POS_WAIT; }
MBRCONTAINS/"(" {return FMBRCONTAINS; }
MBRDISJOINT/"(" {return FMBRDISJOINT; }
MBREQUAL/"(" {return FMBREQUAL; }
MBRINTERSECTS/"(" {return FMBRINTERSECTS; }
MBROVERLAPS/"(" {return FMBROVERLAPS; }
MBRTOUCHES/"(" {return FMBRTOUCHES; }
MBRWITHIN/"(" {return FMBRWITHIN; }
MD5/"(" {return FMD5; }
MLINEFROMTEXT/"(" {return FMLINEFROMTEXT; }
MLINEFROMWKB/"(" {return FMLINEFROMWKB; }
MONTHNAME/"(" {return FMONTHNAME; }
MPOINTFROMTEXT/"(" {return FMPOINTFROMTEXT; }
MPOINTFROMWKB/"(" {return FMPOINTFROMWKB; }
MPOLYFROMTEXT/"(" {return FMPOLYFROMTEXT; }
MPOLYFROMWKB/"(" {return FMPOLYFROMWKB; }
MULTILINESTRINGFROMTEXT/"(" {return FMULTILINESTRINGFROMTEXT; }
MULTILINESTRINGFROMWKB/"(" {return FMULTILINESTRINGFROMWKB; }
MULTIPOINTFROMTEXT/"(" {return FMULTIPOINTFROMTEXT; }
MULTIPOINTFROMWKB/"(" {return FMULTIPOINTFROMWKB; }
MULTIPOLYGONFROMTEXT/"(" {return FMULTIPOLYGONFROMTEXT; }
MULTIPOLYGONFROMWKB/"(" {return FMULTIPOLYGONFROMWKB; }
MICROSECOND/"(" {return FMICROSECOND; }
MINUTE/"(" {return FMINUTE; }
MONTH/"(" {return FMONTH; }
GROUP_CONCAT/"(" {return FGROUP_CONCAT; }
MAX/"(" {return FMAX; }
MID/"(" {return FMID; }
MIN/"(" {return FMIN; }
MOD/"(" {return FMOD; }
NOW/"(" {return FNOW; }
NAME_CONST/"(" {return FNAME_CONST; }
NULLIF/"(" {return FNULLIF; }
NUMGEOMETRIES/"(" {return FNUMGEOMETRIES; }
NUMINTERIORRINGS/"(" {return FNUMINTERIORRINGS; }
NUMPOINTS/"(" {return FNUMPOINTS; }
OCT/"(" {return FOCT; }
OCTET_LENGTH/"(" {return FOCTET_LENGTH; }
ORD/"(" {return FORD; }
OVERLAPS/"(" {return FOVERLAPS; }
OLD_PASSWORD/"(" {return FOLD_PASSWORD; }
PERIOD_ADD/"(" {return FPERIOD_ADD; }
PERIOD_DIFF/"(" {return FPERIOD_DIFF; }
PI/"(" {return FPI; }
POSITION/"(" {return FPOSITION; }
PASSWORD/"(" {return FPASSWORD; }
POINTFROMTEXT/"(" {return FPOINTFROMTEXT; }
POINTFROMWKB/"(" {return FPOINTFROMWKB; }
POINTN/"(" {return FPOINTN; }
POLYFROMTEXT/"(" {return FPOLYFROMTEXT; }
POLYFROMWKB/"(" {return FPOLYFROMWKB; }
POLYGONFROMTEXT/"(" {return FPOLYGONFROMTEXT; }
POLYGONFROMWKB/"(" {return FPOLYGONFROMWKB; }
POW(ER)?/"(" {return FPOWER; }
QUARTER/"(" {return FQUARTER; }
QUOTE/"(" {return FQUOTE; }
RADIANS/"(" {return FRADIANS; }
RAND/"(" {return FRAND; }
ROUND/"(" {return FROUND; }
ROW_COUNT/"(" {return FROW_COUNT; }
REPEAT/"(" {return FREPEAT; }
REPLACE/"(" {return FREPLACE; }
REVERSE/"(" {return FREVERSE; }
RIGHT/"(" {return FRIGHT; }
RPAD/"(" {return FRPAD; }
RTRIM/"(" {return FRTRIM; }
RELEASE_LOCK/"(" {return FRELEASE_LOCK; }
SEC_TO_TIME/"(" {return FSEC_TO_TIME; }
SEC_TO_DATE/"(" {return FSEC_TO_DATE; }
SHA/"(" {return FSHA; }
SHA1/"(" {return FSHA1; }
SIGN/"(" {return FSIGN; }
SIN/"(" {return FSIN; }
SLEEP/"(" {return FSLEEP; }
SCHEMA/"(" {return FSCHEMA; }
SOUNDEX/"(" {return FSOUNDEX; }
SPACE/"(" {return FSPACE; }
SQRT/"(" {return FSQRT; }
SRID/"(" {return FSRID; }
STARTPOINT/"(" {return FSTARTPOINT; }
STRCMP/"(" {return FSTRCMP; }
STR_TO_DATE/"(" {return FSTR_TO_DATE; }
SECOND/"(" {return FSECOND; }
SUBTIME/"(" {return FSUBTIME; }
SUBSTR(ING)?/"(" {return FSUBSTRING; }
SUBSTRING_INDEX/"(" {return FSUBSTRING_INDEX; }
SESSION_USER/"(" {return FSESSION_USER; }
STD/"(" {return FSTD; }
STDDEV/"(" {return FSTDDEV; }
STDDEV_POP/"(" {return FSTDDEV_POP; }
STDDEV_SAMP/"(" {return FSTDDEV_SAMP; }
SUBDATE/"(" {return FSUBDATE; }
SUM/"(" {return FSUM; }
SYSDATE/"(" {return FSYSDATE; }
SYSTEM_USER/"(" {return FSYSTEM_USER; }
TAN/"(" {return FTAN; }
TIMEDIFF/"(" {return FTIMEDIFF; }
TIME_FORMAT/"(" {return FTIME_FORMAT; }
TIME_TO_SEC/"(" {return FTIME_TO_SEC; }
TRUNCATE/"(" {return FTRUNCATE; }
TOUCHES/"(" {return FTOUCHES; }
TO_DAYS/"(" {return FTO_DAYS; }
TRIM/"(" {return FTRIM; }
TIME/"(" {return FTIME; }
TIMESTAMP/"(" {return FTIMESTAMP; }
TIMESTAMPADD/"(" {return FTIMESTAMPADD; }
TIMESTAMPDIFF/"(" {return FTIMESTAMPDIFF; }
VARIANCE/"(" {return FVARIANCE; }
VAR_POP/"(" {return FVAR_POP; }
VAR_SAMP/"(" {return FVAR_SAMP; }
UCASE/"(" {return FUCASE; }
UNCOMPRESS/"(" {return FUNCOMPRESS; }
UNCOMPRESSED_LENGTH/"(" {return FUNCOMPRESSED_LENGTH; }
UNHEX/"(" {return FUNHEX; }
USER/"(" {return FUSER; }
UNIX_TIMESTAMP/"(" {return FUNIX_TIMESTAMP; }
UPDATEXML/"(" {return FUPDATEXML; }
UPPER/"(" {return FUPPER; }
UUID/"(" {return FUUID; }
UUID_SHORT/"(" {return FUUID_SHORT; }
VERSION/"(" {return FVERSION; }
UTC_DATE/"(" {return FUTC_DATE; }
UTC_TIME/"(" {return FUTC_TIME; }
UTC_TIMESTAMP/"(" {return FUTC_TIMESTAMP; }
WEEK/"(" {return FWEEK; }
WEEKDAY/"(" {return FWEEKDAY; }
WEEKOFYEAR/"(" {return FWEEKOFYEAR; }
YEAR/"(" {return FYEAR; }
YEARWEEK/"(" {return FYEARWEEK; }
X/"(" {return FX; }
Y/"(" {return FY; }

    /* 
     * peek ahead and return function if name(
     * below not keyword
    */
    /*
COUNT[ ]+ { int c = input(); unput(c);
           if(c == '(') return FCOUNT;
           yylval.strval = strdup(yytext);
           printf("[%s]", yytext);
           return NAME; }
SUM[ ]+    { int c = input(); unput(c);
           if(c == '(') return FSUM;
           yylval.strval = strdup(yytext);
           return NAME; }
    */

[A-Za-z][A-Za-z0-9_]*    { yylval.strval = strdup(yytext);
                          return NAME; }
`[^`/\\\n]+`           { yylval.strval = strdup(yytext+1);
                          yylval.strval[yyleng-2] = 0;
                          return NAME; }

`[^`\n]*$               { yyerror("unterminated quoted name %s", yytext); }

    /* user variables */
@[0-9a-z_.$]+ |
@\"[^"\n]+\" |
@`[^`\n]+` |
@'[^'\n]+' { yylval.strval = strdup(yytext); return USERVAR; }

@@[0-9a-z_.$]+ |
@@\"[^"\n]+\" |
@@`[^`\n]+` |
@@'[^'\n]+' { yylval.strval = strdup(yytext); return USERVAR; }

@\"[^"\n]*$ { yyerror("unterminated quoted user variable %s", yytext); }
@`[^`\n]*$ { yyerror("unterminated quoted user variable %s", yytext); }
@'[^'\n]*$ { yyerror("unterminated quoted user variable %s", yytext); }

":="     { return ASSIGN; }

    /* comments */   
#.*        ;

"/*"            { oldstate = YY_START; BEGIN COMMENT; }
<COMMENT>"*/"   { BEGIN oldstate; }
<COMMENT>.|\n   ;
<COMMENT><<EOF>> { yyerror("unclosed comment"); }

[\?]    { yylval.strval = strdup(yytext); return NAME; }

    /* skip ping, rds special */
^[ \t\n]*PING; ;
^[ \t\n]*BEGIN; ;
^[ \t\n]*ROLLBACK; ;
^[ \t\n]*COMMIT; ;

^[ \t\n]*truncate[ \t\n]+               {return TRUNCATE;};
^[ \t\n]*truncate[ \t\n]+TABLE[ \t\n]+  {return TRUNCATE;};

    /* everything else */
[ \t\n]         /* white space and newline skip */
.               { yyerror("mystery character '%c'", *yytext); }

%%

