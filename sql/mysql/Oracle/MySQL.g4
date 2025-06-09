grammar MySQL;

/*
  Copyright 2025 Jason Osgood

  Refactored MySQL grammar to adopt NormalSQL's rules, idioms, and style.
  Goal is for misc dialects to all emit the same parse tree (given the
  same input). A work in progress, as grammars converge over time, trial &
  error, balancing tradeoffs (lex vs parse vs semantic validation).

  Based on the excellent prior works done by Mike Lischke, Ivan Kochurkin,
  Ivan Khudyashev. As well as MySQL's original sql_yacc.yy.

  Prior copyright notices below.

  I'm unsure what license is in effect, so haven't added my own. IIRC, ANTLR4's
  grammars-v4 project requires MIT.

  FYI, NormalSQL uses APL2. It seemed the default (for Java projects). Having no
  opinions or preferences, I'll switch licenses as needed. If I continue to use
  and maintain this fork of grammars-v4, I may adopt same license, just
  just to keep things more simple for everyone. Would be grateful to have someone,
  any one, tell me what'd best for everyone.

*/


/*
 * Copyright © 2025, Oracle and/or its affiliates
 */

/*
 * Merged in all changes up to mysql-trunk git revision [d2c9971] (24. January 2024).
 *
 * MySQL grammar for ANTLR 4.5+ with language features from MySQL 8.0 and up.
 * The server version in the generated parser can be switched at runtime, making it so possible
 * to switch the supported feature set dynamically.
 *
 * The coverage of the MySQL language should be 100%, but there might still be bugs or omissions.
 *
 * To use this grammar you will need a few support classes (which should be close to where you found this grammar).
 * These classes implement the target specific action code, so we don't clutter the grammar with that
 * and make it simpler to adjust it for other targets. See the demo/test project for further details.
 *
 * Written by Mike Lischke. Direct all bug reports, omissions etc. to mike.lischke@oracle.com.
 */

 /*
  MySQL (Positive Technologies) grammar
  The MIT License (MIT).
  Copyright (c) 2015-2017, Ivan Kochurkin (kvanttt@gmail.com), Positive Technologies.
  Copyright (c) 2017, Ivan Khudyashev (IHudyashov@ptsecurity.com)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/

/*
   Copyright (c) 2000, 2025, Oracle and/or its affiliates.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License, version 2.0,
   as published by the Free Software Foundation.

   This program is designed to work with certain software (including
   but not limited to OpenSSL) that is licensed under separate terms,
   as designated in a particular file or component or in included license
   documentation.  The authors of MySQL hereby grant you an additional
   permission to link the program and your derivative works with the
   separately licensed software that they have either included with
   the program or referenced in the documentation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License, version 2.0, for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
 */

/**

   I have no idea how to accomodate MySQL extensions.
   Note: update rule 'keyword' whenever a new
   keyword (token) is added (or removed).

   Have matched order of alts from sql_yacc.yy, as needed, because I'm getting
   cross-eyed doing side-by-side comparisons.

   I think it'd be cool to topo sort the parser's rules.

   Inline delimited lists to ease post-parsing. By shortening parse tree,
   this moves (some) complexity from app code to grammar.

      // Good
      values : 'VALUES' term ( ',' term )* ;

      // Bad
      values : 'VALUES' terms ;
      terms : terms ( ',' term )* ;


   Have inlined most statements for now. May re-refactor once grammar has settled down.


   Known problems:

    - Only handles UTF-8 encoding

       - Does not handle multibyte Unicode

       - Does not handle pre-Unicode code page stuff

       - Does not handle emojis

     - Incorrectly discerns some numbers vs identifiers (that begin w/ digit)

       - eg "SELECT 1ea10.1a20" yields an ID, FLOAT, and ID. Should just be ID.

*/

options {
    caseInsensitive = true;
}

statements
    : ( dml | ddl )? ( ( ';' | '#end' ) ( dml | ddl )? )* EOF ;

dml
    : select
    | delete
    | insert
    | update
    | replace
    | load
    | set
    | transaction
    ;

ddl
    : database_ddl
    | event_ddl
    | function_ddl
    | index_ddl
    | logfileGroup_ddl
    | resourceGroup_ddl
    | rule_ddl
    | server_ddl
    | table_ddl
    | tablespace_ddl
    | trigger_ddl
    | user_ddl
    | view_ddl
    | spatial_ddl
    | other_ddl
    ;

with
    : 'WITH' 'RECURSIVE'? cte ( ',' cte )* ;

cte
    : tableColumns 'AS' '(' select ')' ;

tableColumns
    : qname ( '(' name ( ',' name )* ')' )? ;

select
    : with? selectCore ( ( 'UNION' | 'EXCEPT' | 'INTERSECT' ) ( 'DISTINCT' | 'ALL' )? selectCore )*
      orderBy? limit? into? locking* into?
    ;

insert
    : 'INSERT' ( 'LOW_PRIORITY' | 'DELAYED' | 'HIGH_PRIORITY' )?
      'IGNORE'?
      'INTO'? qname partition?
      // TODO fix this mess

      ( insertFromConstructor valuesReference?
      | 'SET' setter ( ',' setter )* valuesReference?
      | insertQueryExpression
      )
      ( 'ON' 'DUPLICATE' 'KEY' 'UPDATE' setter ( ',' setter )* )?
    ;

valuesReference
    : 'AS' tableColumns ;


replace
    : 'REPLACE' ( 'LOW_PRIORITY' | 'DELAYED' )?
      'INTO'? qname partition?
      ( insertFromConstructor | 'SET' setter ( ',' setter )* | insertQueryExpression )?
    ;

    insertFromConstructor
        : ( '(' ( qname ( ',' qname )* )? ')' )? ( 'VALUES' | 'VALUE' ) term  ( ',' term )* ;

    insertQueryExpression
        : with? selectCore orderBy? limit?
        | '(' select ')'
        | ( '(' ( qname ( ',' qname )* )? ')' )? select
        ;



update
    : with? 'UPDATE' 'LOW_PRIORITY'? 'IGNORE'? tableReferenceList
      'SET' setter ( ',' setter )*
      where?
      orderBy? limitCount?
    ;

delete
    : with? 'DELETE' 'LOW_PRIORITY'? 'QUICK'? 'IGNORE'?
      ( 'FROM' qname alias? ( 'PARTITION' '(' name ( ',' name )* ')' )? where? orderBy? limitCount?
      | qname ( ',' qname )* 'FROM' tableReferenceList where?
      | 'FROM' qname ( ',' qname )* 'USING' tableReferenceList where?
      )
    ;

load
    : 'LOAD' ( 'DATA' | 'XML' ) ( 'LOW_PRIORITY' | 'CONCURRENT' )? 'FROM'?
      'LOCAL'? ( 'INFILE' | 'URL' | 'S3' ) string
      ( 'COUNT' DECIMAL )?
      ( 'IN' 'PRIMARY' 'KEY' 'ORDER' )?
      // TODO DRY?
      ( 'REPLACE' | 'IGNORE' )?
      'INTO' 'TABLE' qname partition?
      charsetName?

      ( 'ROWS' 'IDENTIFIED' 'BY' string )?

      fieldHandling?
      lineHandling?

      ( 'IGNORE' DECIMAL ( 'LINES' | 'ROWS' ) )?

      ( '(' ( qname ( ',' qname )* )? ')' )?
      ( 'SET' setter ( ',' setter )* )?
    ;

set
    : 'SET' setter ( ',' setter )*
    | 'SET' 'NAMES' ( equal_ term | qname collate? | 'DEFAULT' )
    | 'SET' ( 'GLOBAL' | 'SESSION' )? 'TRANSACTION' transactionCharacteristics ( ',' transactionCharacteristics )*
    | 'SET' 'PASSWORD' ( 'FOR' user )? ( equal_ string | 'TO' 'RANDOM' ) replaceString? retainCurrentPassword?
    | 'SET' charset_ qname ;

transaction : 'COMMIT' 'WORK'? ( 'AND' 'NO'? 'CHAIN' )? ( 'NO'? 'RELEASE' )?
    | 'SAVEPOINT' qname
    | 'ROLLBACK' 'WORK'? ( 'TO' 'SAVEPOINT'? name | ( 'AND' 'NO'? 'CHAIN' )? ( 'NO'? 'RELEASE' )? )
    | 'RELEASE' 'SAVEPOINT' qname
    | 'LOCK' table_ lockItem ( ',' lockItem )*
    | 'LOCK' 'INSTANCE' 'FOR' 'BACKUP'
    | 'UNLOCK' ( table_ | 'INSTANCE' )

    | 'XA' ( 'START' | 'BEGIN' ) xid ( 'JOIN' | 'RESUME' )?
    | 'XA' 'END' xid ( 'SUSPEND' ( 'FOR' 'MIGRATE' )?)?
    | 'XA' 'PREPARE' xid
    | 'XA' 'COMMIT' xid ( 'ONE' 'PHASE' )?
    | 'XA' 'ROLLBACK' xid
    | 'XA' 'RECOVER' ( 'CONVERT' 'XID' )? ;

selectCore
    : 'SELECT' modifier* item ( ',' item )* into?
      ( 'FROM' ( 'DUAL' | tables ) )?
      where? groupBy? having? ( 'WINDOW' windowDef ( ',' windowDef )* )? qualify?
    | values
    | '(' select ')'
    | 'TABLE' qname
    ;

    modifier
        : 'ALL'
        | 'DISTINCT'
        | 'DISTINCTROW'
        | 'HIGH_PRIORITY'
        | 'STRAIGHT_JOIN'
        | 'SQL_SMALL_RESULT'
        | 'SQL_BIG_RESULT'
        | 'SQL_BUFFER_RESULT'
        | 'SQL_CALC_FOUND_ROWS'
        | 'SQL_NO_CACHE'
        ;

    item
        : '*'
        | term alias?
        | qname ( '.'  '*' )?
        ;

    into
        : 'INTO'
          ( 'OUTFILE' string charsetName? fieldHandling? lineHandling?
          | 'DUMPFILE' string
          | qname ( ',' qname )*
          )
        ;

    tables
        : tables ',' tables
        | tables ( ( 'INNER' | 'CROSS' )? 'JOIN' | 'STRAIGHT_JOIN' ) tables ( 'ON' term | 'USING' '(' name ( ',' name )* ')' )?
        | tables ( 'LEFT' | 'RIGHT' ) 'OUTER'? 'JOIN' tables ( 'ON' term | 'USING' '(' name ( ',' name )* ')' )
        | tables ( 'NATURAL' 'INNER'? 'JOIN' | 'NATURAL' ( 'LEFT' | 'RIGHT' ) 'OUTER'? 'JOIN' ) tables
        | qname partition? alias? indexHint* ( 'TABLESAMPLE' ( 'SYSTEM' | 'BERNOULLI' ) '(' literal ')' )?
        | 'LATERAL'? '(' select ')' ( 'AS'? tableColumns )?
        | values alias?
        | 'JSON_TABLE' '(' term ',' string 'COLUMNS' '(' jsonColumn ( ',' jsonColumn )* ')' ')' alias?
        | qname '(' term ( ',' term )* ')' alias?
        | '{' 'OJ' tables '}'
        | '(' tables ')'
        ;

    where
        : 'WHERE' term ;

    groupBy
        : 'GROUP' 'BY' orderExpression ( ',' orderExpression )* ( 'WITH' 'ROLLUP' )?
        | 'GROUP' 'BY' ( 'ROLLUP' | 'CUBE' ) terms
        ;

    having
        : 'HAVING' term ;

    qualify
        : 'QUALIFY' term ;

    limit
        : 'LIMIT' literal ( ( ',' | 'OFFSET' ) literal )? ;

    locking
        : 'FOR' ( 'UPDATE' | 'SHARE' ) ( 'OF' qname ( ',' qname )* )? ( 'SKIP' 'LOCKED' | 'NOWAIT' )?
        | 'LOCK' 'IN' 'SHARE' 'MODE'
        ;

terms
    : '(' term  ( ',' term )* ')' ;

term
    : 'ROW'? '(' ( term ( ',' term )* )? ')'
    | qname
    | literal
    | term ( '->' | '->>' ) string
    | term 'AT' 'LOCAL'
    | 'BINARY' term
    | 'CAST' '(' term 'AS' castType 'ARRAY'? ')'
    | 'CAST' '(' term 'AT' 'TIME' 'ZONE' 'INTERVAL'? string 'AS' 'DATETIME' ( '(' DECIMAL ')' )? ')'
    | 'CONVERT' '(' term ',' castType ')'
    | 'CONVERT' '(' term ',' dataType ')'
    | 'CONVERT' '(' term 'USING' name ')'

    | term 'COLLATE' name
    | '!' term
    | ( '+' | '-' | '~' ) term
    | term '^' term
    | term ( '*' | '/' | 'DIV' | '%' | 'MOD' ) term
    | term ( '+' | '-' ) term
    | term ( '<<' | '>>' ) term
    | term '&' term
    | term '|' term
    | term ( '=' | ':=' | '!=' | '<>' | '<=>' | '>=' | '>' | '<=' | '<' ) term

    | function nullTreatment? over?
//    | windowFunctionCall
    | 'GROUPING' terms
    | '{' name term '}'
    | 'MATCH' ( qname ( ',' qname )* | '(' qname ( ',' qname )* ')' ) 'AGAINST' '(' term fulltextOptions? ')'
    | 'DEFAULT' '(' qname ')'
    | term 'IS' 'NOT'? ( 'TRUE' | 'FALSE' | 'UNKNOWN' | null_ )
    | term 'NOT'? 'LIKE' term ( 'ESCAPE' term )?
    | term 'NOT'? ( 'REGEXP' | 'RLIKE' ) term
    | term 'NOT'? 'IN' ( '(' select ')' | terms )
    | term 'MEMBER' 'OF'? '(' term ')'
    | term 'NOT'? 'BETWEEN' term 'AND' term
    | 'CASE' term? ( 'WHEN' term 'THEN' term )+ ( 'ELSE' term )? 'END'
    | term 'SOUNDS' 'LIKE' term
    | 'EXISTS'? '(' select ')'
    | ( 'ALL' | 'ANY' | 'SOME' ) '(' select ')'

    | 'NOT' term
    | term ( 'AND' | '&&' ) term
    | term 'XOR' term
    | term ( 'OR' | '||' ) term
    | qname ':=' term
    ;

    function
        : ID '(' ( udfExpr ( ',' udfExpr )* )? ')'
        // TODO embue with essence of windowing (DISTINCT, ORDER BY)
        | qname '(' ( term ( ',' term )* )? ')'

        | 'CHAR' '(' term ( ',' term )* ( 'USING' name )? ')'
        | 'CURRENT_USER' ( '(' ')' )?
        | 'JSON_VALUE' '(' term ',' string ( 'RETURNING' castType )? ( jsonResponse jsonResponse? )? ')'
        | 'TRIM' '(' ( term ( 'FROM' term )? | 'LEADING' term? 'FROM' term | 'TRAILING' term? 'FROM' term | 'BOTH' term? 'FROM' term ) ')'

        | 'CURDATE' ( '(' ')' )?
        | 'CURTIME' ( '(' DECIMAL? ')' )?
        | ( 'DATE_ADD' | 'DATE_SUB' ) '(' term ',' interval ')'
        | 'EXTRACT' '(' timeUnitToo 'FROM' term ')'
        | 'GET_FORMAT' '(' ( 'DATE' | 'TIME' | 'DATETIME' | 'TIMESTAMP' ) ',' term ')'
        | now
        | 'POSITION' '(' term 'IN' term ')'
        | 'SUBSTRING' '(' term ( ',' term ( ',' term )? | 'FROM' term ( 'FOR' term )? ) ')'
        | 'SYSDATE' ( '(' DECIMAL? ')' )?
        | ( 'TIMESTAMPADD' | 'TIMESTAMPDIFF' ) '(' timeUnit ',' term ',' term ')'
        | 'UTC_DATE' ( '(' ')' )?
        | 'UTC_TIME' ( '(' DECIMAL? ')' )?
        | 'UTC_TIMESTAMP' ( '(' DECIMAL? ')' )?

        | 'WEIGHT_STRING' '(' term ( 'AS' ( 'CHAR' | 'BINARY' ) '(' DECIMAL ')' )? ')'
        | 'AVG' '(' 'DISTINCT'? 'ALL'? term ')'
        | ( 'BIT_AND' | 'BIT_OR' | 'BIT_XOR' ) '(' 'ALL'? term ')'
        | 'JSON_ARRAYAGG' '(' 'ALL'? term ')'
        | 'JSON_OBJECTAGG' '(' 'ALL'? term ',' 'ALL'? term ')'
        | 'ST_COLLECT' '(' 'DISTINCT'? 'ALL'? term ')'
        | 'COUNT' '(' ( 'ALL'? '*' | 'ALL'? term | 'DISTINCT' term ( ',' term )* ) ')'
        | ( 'MIN' | 'MAX' ) '(' 'DISTINCT'? 'ALL'? term ')'
        | ( 'STD' | 'VARIANCE' | 'STDDEV_SAMP' | 'VAR_SAMP' | 'SUM' ) '(' 'ALL'? term ')'
        | 'SUM' '(' 'DISTINCT' 'ALL'? term ')'
        | 'GROUP_CONCAT' '(' 'DISTINCT'? term ( ',' term )* orderBy? ( 'SEPARATOR' string )? ')'
        | 'NTH_VALUE' '(' term ',' term ')' ( 'FROM' ( 'FIRST' | 'LAST' ) )?
        ;

    nullTreatment
        : ( 'RESPECT' | 'IGNORE' ) 'NULLS' ;

    over
        : 'OVER' ( name | windowSpec ) ;

    fulltextOptions
        : 'IN' 'BOOLEAN' 'MODE'
        | 'IN' 'NATURAL' 'LANGUAGE' 'MODE' ( 'WITH' 'QUERY' 'EXPANSION' )?
        | 'WITH' 'QUERY' 'EXPANSION'
        ;

udfExpr
    : term alias? ;

orderBy
    : 'ORDER' 'BY' orderExpression ( ',' orderExpression )* ;

comment
    : 'COMMENT' string ;


other_ddl
    : 'CALL' qname ( '(' ( term ( ',' term )* )? ')' )?
    | 'DO' item ( ',' item )*
    | 'HANDLER' qname 'OPEN' alias?
    | 'HANDLER' qname ( 'CLOSE' | 'READ' handlerReadOrScan where? limit? )

    | 'PURGE' 'BINARY' 'LOGS' ( 'TO' string | 'BEFORE' term )
    | 'CHANGE' 'REPLICATION' 'SOURCE' 'TO' sourceDefinition ( ',' sourceDefinition )* forChannel?
    | 'RESET' resetOption ( ',' resetOption )*
    | 'RESET' 'PERSIST' ( exists? qname )?
    | 'CHANGE' 'REPLICATION' 'FILTER' filterDefinition ( ',' filterDefinition )* forChannel?
    | ( 'START' groupReplicationStartOptions? | 'STOP' ) 'GROUP_REPLICATION'
    | 'PREPARE' qname 'FROM' qname
    | 'EXECUTE' qname ( 'USING' qname ( ',' qname )* )?
    | ( 'DEALLOCATE' | 'DROP' ) 'PREPARE' name

    | 'CLONE' 'LOCAL' 'DATA' 'DIRECTORY' equal_? string
    | 'CLONE' 'REMOTE' ( 'FOR' 'REPLICATION' )?
    | 'CLONE' 'INSTANCE' 'FROM' user ':' DECIMAL 'IDENTIFIED' 'BY' name ( ssl | 'DATA' 'DIRECTORY' equal_? string ssl? )?

    | grant
    | revoke
    | setRole
    | 'ANALYZE' noLogging? table_ qname ( ',' qname )* histogram?
    | 'CHECK' table_ qname ( ',' qname )* checkOption*
    | 'CHECKSUM' 'TABLE' qname ( ',' qname )* ( 'QUICK' | 'EXTENDED' )?
    | 'OPTIMIZE' noLogging? table_ qname ( ',' qname )*
    | 'REPAIR' noLogging? table_ qname ( ',' qname )* repairType*
    | 'UNINSTALL' ( 'PLUGIN' name | 'COMPONENT' string ( ',' string )* )
    | 'INSTALL' 'PLUGIN' name 'SONAME' string
    | 'INSTALL' 'COMPONENT' string ( ',' string )* ( 'SET' setter ( ',' setter )* )?
    | 'TRUNCATE' 'TABLE'? qname
    | 'IMPORT' 'TABLE' 'FROM' string ( ',' string )*
    | show_ddl
    | 'SHUTDOWN'
    | ( 'SIGNAL' signalCondition | 'RESIGNAL' signalCondition? ) ( 'SET' signalItem ( ',' signalItem )* )?
    | 'START' 'TRANSACTION' ( startTransactionMode ( ',' startTransactionMode )* )?
    | 'START' 'REPLICA' replicaThreadOptions? ( 'UNTIL' replicaUntil )? userOption? ( 'PASSWORD' '=' string )? defaultAuthOption? pluginDirOption? forChannel?
    | 'STOP' 'REPLICA' replicaThreadOptions? forChannel?

    | 'BINLOG' string
    | 'CACHE' 'INDEX' keyCacheListOrParts 'IN' qname
    | 'FLUSH' noLogging? ( flushTables | flushOption ( ',' flushOption )* )
    | 'KILL' ( 'CONNECTION' | 'QUERY' )? term
    | 'LOAD' 'INDEX' 'INTO' 'CACHE' preloadKeys ( ',' preloadKeys )*

    | 'CREATE' 'LIBRARY' notExists? qname ( 'LANGUAGE' name | comment )+ 'AS' string
    | 'DROP' 'LIBRARY' exists? qname
    | 'ALTER' 'LIBRARY' exists? qname comment?

    | ( 'EXPLAIN' | 'DESCRIBE' | 'DESC' ) qname qname ?

    | ( 'EXPLAIN' | 'DESCRIBE' | 'DESC' )
      'ANALYZE'?
      ( 'FORMAT' '=' ( 'TRADITIONAL' | 'JSON' | 'TREE' | string ) )?
      ( 'INTO' qname )?
      ( ( 'FOR' database_ name )? ( select | delete | insert | replace | update )
      | 'FOR' 'CONNECTION' DECIMAL
      )

    | 'HELP' name
    | 'USE' name
    | 'RESTART'
    | 'GET' ( 'CURRENT' | 'STACKED' )? 'DIAGNOSTICS'
       ( statementInformationItem ( ',' statementInformationItem )*
       | 'CONDITION' literal conditionInformationItem ( ',' conditionInformationItem )*
       )
    | beginWork
    | 'ALTER' 'INSTANCE'
        ( enable_ 'INNODB' 'REDO_LOG'
        | 'ROTATE' ( 'INNODB' | 'BINLOG' ) 'MASTER' 'KEY'
        | 'RELOAD' 'TLS'
            ( 'FOR' 'CHANNEL' ( 'mysql_main' | 'mysql_admin' ) )?
            ( 'NO' 'ROLLBACK' 'ON' 'ERROR' )?
        | 'RELOAD' 'KEYRING'
        )
    ;

view_ddl
    : 'CREATE' orReplace_? viewAlgorithm? definer? security? 'VIEW' notExists? tableColumns 'AS' select viewOption?
    | 'ALTER' viewAlgorithm? definer? security? 'VIEW' tableColumns 'AS' select viewOption?
    | 'DROP' 'VIEW' exists? qname ( ',' qname )* ( 'RESTRICT' | 'CASCADE' )?
    ;

spatial_ddl
    : 'CREATE' orReplace_? 'SPATIAL' 'REFERENCE' 'SYSTEM' notExists? DECIMAL srsAttribute*
    | 'DROP' 'SPATIAL' 'REFERENCE' 'SYSTEM' exists? DECIMAL
    ;

user_ddl
    : 'CREATE' 'USER' notExists? userAuthID ( ',' userAuthID )* ( 'DEFAULT' 'ROLE' roleList )? require? resourceWith? passwordOption* ( comment | 'ATTRIBUTE' string )*

    | 'ALTER' 'USER' exists? user alterAuthOption? ( ',' user alterAuthOption? )* require? resourceWith? passwordOption* ( comment | 'ATTRIBUTE' string )*

    | 'ALTER' 'USER' exists? 'USER' '(' ')' alterAuthOption
    | 'ALTER' 'USER' exists? ( 'USER' '(' ')' | user ) ( DECIMAL 'FACTOR' )?
    | 'ALTER' 'USER' exists? user 'DEFAULT' 'ROLE' ( 'ALL' | 'NONE' | roleList )
    | 'DROP' 'USER' exists? user ( ',' user )*
    | 'RENAME' 'USER' user 'TO' user ( ',' user 'TO' user )*
    ;

    alterAuthOption
        : identified replaceString? retainCurrentPassword?
        | 'DISCARD' 'OLD' 'PASSWORD'
        ;

trigger_ddl
    : 'CREATE' definer? 'TRIGGER' notExists? qname ( 'BEFORE' | 'AFTER' ) ( 'INSERT' | 'UPDATE' | 'DELETE' ) 'ON' qname 'FOR' 'EACH' 'ROW' ( ( 'FOLLOWS' | 'PRECEDES' ) qname )? compound
    | 'DROP' 'TRIGGER' exists? qname ;

tablespace_ddl
    : 'CREATE' 'UNDO'? 'TABLESPACE' qname ( tablespaceOption ( ','? tablespaceOption )* )?
    | 'ALTER' 'UNDO'? 'TABLESPACE' qname tablespaceOption ( ','? tablespaceOption )*
    | 'DROP' 'UNDO'? 'TABLESPACE' qname ( tablespaceOption ( ','? tablespaceOption )* )?
    ;

    tablespaceOption
        : 'AUTOEXTEND_SIZE' '='? DECIMAL
        | 'COMMENT' '='? string
        | 'ENCRYPTION' '='? string
        | 'ENGINE' '='? name
        | 'EXTENT_SIZE' '='? byteSize
        | 'FILE_BLOCK_SIZE' '='? byteSize
        | 'INITIAL_SIZE' '='? byteSize
        | 'MAX_SIZE' '='? byteSize
        | 'NODEGROUP' '='? DECIMAL
        | 'RENAME' 'TO' name
        | 'SET' ( 'ACTIVE' | 'INACTIVE' )
        | 'USE' 'LOGFILE' 'GROUP' name
        | 'WAIT'
        | ( 'ADD' | 'DROP' ) 'DATAFILE' string
        ;


show_ddl
    : 'SHOW' 'BINARY' 'LOG' 'STATUS'
    | 'SHOW' 'BINARY' 'LOGS'
    // TODO verify FROM & IN
    | 'SHOW' 'BINLOG' 'EVENTS' ( 'IN' string )? ( 'FROM' DECIMAL )? limit?
    | 'SHOW' charset_ like?
    | 'SHOW' 'COLLATION' like?
    | 'SHOW' ( 'FULL' | 'EXTENDED' 'FULL'? )? ( 'FIELDS' | 'COLUMNS' ) inDb inDb? like?
    | 'SHOW' 'COUNT' '(' '*' ')' ( 'WARNINGS' | 'ERRORS' )

    | 'SHOW' 'CREATE' database_ notExists? qname
    | 'SHOW' 'CREATE' 'EVENT' qname
    | 'SHOW' 'CREATE' 'FUNCTION' qname
    | 'SHOW' 'CREATE' 'FUNCTION' 'CODE' qname
    | 'SHOW' 'CREATE' 'LIBRARY' qname
    | 'SHOW' 'CREATE' 'PROCEDURE' qname
    | 'SHOW' 'CREATE' 'PROCEDURE' 'CODE' qname
    | 'SHOW' 'CREATE' 'TABLE' qname
    | 'SHOW' 'CREATE' 'TRIGGER' qname
    | 'SHOW' 'CREATE' 'USER' user
    | 'SHOW' 'CREATE' 'VIEW' qname

    | 'SHOW' 'DATABASES' like?
    | 'SHOW' 'ENGINE' qname ( 'LOGS' | 'MUTEX' | 'STATUS' )
    | 'SHOW' 'STORAGE'? 'ENGINES'
    | 'SHOW' 'ERRORS' limit?
    | 'SHOW' 'EVENTS' inDb? like?

    | 'SHOW' 'FUNCTION' 'CODE' qname
    | 'SHOW' 'FUNCTION' 'STATUS' like?
    | 'SHOW' 'GRANTS' ( 'FOR' user ( 'USING' user ( ',' user )* )? )?
    | 'SHOW' 'EXTENDED'? ( 'KEYS' | 'INDEX' | 'INDEXES' ) inDb inDb? where?
    | 'SHOW' 'LIBRARY' 'STATUS' like?
    | 'SHOW' 'OPEN' 'TABLES' inDb? like?
    | 'SHOW' 'PARSE_TREE' ( dml | ddl )
    | 'SHOW' 'PLUGINS'
    | 'SHOW' 'PRIVILEGES'
    | 'SHOW' 'PROCEDURE' 'CODE' qname
    | 'SHOW' 'PROCEDURE' 'STATUS' like?
    | 'SHOW' 'FULL'? 'PROCESSLIST'
    | 'SHOW' 'PROFILE' ( profileDef ( ',' profileDef )* )? ( 'FOR' 'QUERY' DECIMAL )? limit?
    | 'SHOW' 'PROFILES'
    | 'SHOW' 'RELAYLOG' 'EVENTS' ( 'IN' string )? ( 'FROM' DECIMAL )? limit? forChannel?
    | 'SHOW' 'REPLICA' 'STATUS' forChannel?
    | 'SHOW' 'REPLICAS'
    | 'SHOW' 'REPLICA' 'HOSTS'
    | 'SHOW' scope? 'STATUS' like?
    | 'SHOW' 'TABLE' 'STATUS' inDb? like?
    | 'SHOW' ( 'FULL' | 'EXTENDED' 'FULL'? )? 'TABLES' inDb? like?
    | 'SHOW' 'FULL'? 'TRIGGERS' inDb? like?
    | 'SHOW' scope? 'VARIABLES' like?
    | 'SHOW' 'WARNINGS' limit? ;

table_ddl
    : 'CREATE' 'TEMPORARY'? 'TABLE' notExists? qname
      ( '(' ( createDef  | tableConstraintDef ) ( ',' ( createDef  | tableConstraintDef ) )* ')' )?
      ( tableCreateOption ( ','? tableCreateOption )* )? partitionBy? ( ( 'REPLACE' | 'IGNORE' )? 'AS'? select )?

    | 'CREATE' 'TEMPORARY'? 'TABLE' notExists? qname ( 'LIKE' qname | '(' 'LIKE' qname ')' )
    | 'ALTER' onlineOption? 'TABLE' qname ( tableAlterOption ( ','? tableAlterOption )* )?
    | 'RENAME' table_ qname 'TO' qname ( ',' qname 'TO' qname )*
    | 'DROP' 'TEMPORARY'? table_ exists? qname ( ',' qname )* ( 'RESTRICT' | 'CASCADE' )?
    ;

    tableConstraintDef
        : index_ name? indexType? '(' keyPart ( ',' keyPart )* ')' indexOption*
        | 'FULLTEXT' index_? name? '(' keyPart ( ',' keyPart )* ')' indexOption*
        | 'SPATIAL' index_? name? '(' keyPart ( ',' keyPart )* ')' indexOption*
        | ( 'CONSTRAINT' name? )?
            ( ( 'CLUSTERING' 'KEY' | 'PRIMARY' 'KEY' | 'UNIQUE' index_? ) name? indexType? '(' keyPart ( ',' keyPart )* ')' indexOption*
            | 'FOREIGN' 'KEY' name? '(' keyPart ( ',' keyPart )* ')' referenceDef
            | 'CHECK' '(' term ')' enforced_?
            )
        ;

    tableCreateOption
        : 'AUTOEXTEND_SIZE' '='? byteSize
        | 'AUTO_INCREMENT' '='? DECIMAL
        | 'AVG_ROW_LENGTH' '='? DECIMAL
        | 'CHECKSUM' '='? DECIMAL
        | 'COLLATE' '='? name
        | 'COMMENT' '='? string
        | 'COMPRESSION' '='? string
        | 'CONNECTION' '='? string
        | 'DATA' 'DIRECTORY' '='? string
        | 'DEFAULT'? charset_ '='? name
        | 'DELAY_KEY_WRITE' '='? DECIMAL
        | 'ENCRYPTION' '='? string
        | 'ENGINE' '='? name
        | 'ENGINE_ATTRIBUTE' '='? string
        | 'INDEX' 'DIRECTORY' '='? string
        | 'INSERT_METHOD' '='? ( 'NO' | 'FIRST' | 'LAST' )
        | 'KEY_BLOCK_SIZE' '='? DECIMAL
        | 'MAX_ROWS' '='? DECIMAL
        | 'MIN_ROWS' '='? DECIMAL
        | 'PACK_KEYS' '='? decimalDefault
        | 'PASSWORD' '='? string
        | 'ROW_FORMAT' '='? ( ID | 'DEFAULT' | 'DYNAMIC' | 'FIXED' | 'COMPRESSED' | 'REDUNDANT' | 'COMPACT' )
        | 'SECONDARY_ENGINE' equal_? name
        | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
        | 'START' 'TRANSACTION'
        | 'STATS_AUTO_RECALC' '='? decimalDefault
        | 'STATS_PERSISTENT' '='? decimalDefault
        | 'STATS_SAMPLE_PAGES' '='? ( FLOAT | DECIMAL | 'DEFAULT' )
        | 'STORAGE' ( 'DISK' | 'MEMORY' )
        | 'TABLESPACE' '='? name
        | 'TABLE_TYPE' '='? name
        | 'TRANSACTIONAL' '='? DECIMAL
        | 'UNION' '='? '(' ( qname ( ',' qname )* )? ')'
        ;

    tableAlterOption
        : commonIndexOption
        | validation_

        | 'ADD' 'COLUMN'? createDef place?
        | 'CHANGE' 'COLUMN'? name createDef place?
        | 'MODIFY' 'COLUMN'? createDef place?

        | 'ADD' 'COLUMN'? '(' ( createDef | tableConstraintDef ) ( ',' ( createDef | tableConstraintDef ) )* ')'
        | 'ADD' tableConstraintDef

        | 'DROP' ( 'COLUMN'? name ( 'RESTRICT' | 'CASCADE' )? | 'FOREIGN' 'KEY' name | 'PRIMARY' 'KEY' | index_ qname | 'CHECK' name | 'CONSTRAINT' name )
        | enable_ 'KEYS'
        | 'ALTER' 'COLUMN'? name ( 'SET' 'DEFAULT' ( '(' term ')' | literal ) | 'DROP' 'DEFAULT' | 'SET' visibility_ )
        | 'ALTER' 'INDEX' qname visibility_
        | 'ALTER' 'CHECK' name enforced_
        | 'ALTER' 'CONSTRAINT' name enforced_
        | 'RENAME' 'COLUMN' name 'TO' name
        | 'RENAME' ( 'TO' | 'AS' )? qname
        | 'RENAME' index_ qname 'TO' name
        | 'CONVERT' 'TO' charsetName collate?
        | 'FORCE'
        | orderBy
        | tableCreateOption
        | partitionBy
        | 'REMOVE' 'PARTITIONING'
        | 'DISCARD' 'TABLESPACE'
        | 'IMPORT' 'TABLESPACE'
        | 'ADD' 'PARTITION' ( noLogging? ( '(' partitionDef ( ',' partitionDef )* ')' | 'PARTITIONS' DECIMAL ) )?
        | 'DROP' 'PARTITION' name ( ',' name )*
        | 'REBUILD' 'PARTITION' noLogging? allOrPartitionNameList
        | 'OPTIMIZE' 'PARTITION' noLogging? allOrPartitionNameList noLogging?
        | 'ANALYZE' 'PARTITION' noLogging? allOrPartitionNameList
        | 'CHECK' 'PARTITION' allOrPartitionNameList checkOption*
        | 'REPAIR' 'PARTITION' noLogging? allOrPartitionNameList repairType*
        | 'COALESCE' 'PARTITION' noLogging? DECIMAL
        | 'TRUNCATE' 'PARTITION' allOrPartitionNameList
        | 'REORGANIZE' 'PARTITION' noLogging? ( name ( ',' name )* 'INTO' '(' partitionDef ( ',' partitionDef )* ')' )?
        | 'EXCHANGE' 'PARTITION' name 'WITH' 'TABLE' qname validation_?
        | 'DISCARD' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
        | 'IMPORT' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
        | 'SECONDARY_LOAD'
        | 'SECONDARY_UNLOAD'
        ;

    referenceDef
        : 'REFERENCES' qname ( '(' name ( ',' name )* ')' )?
          ( 'MATCH' ( 'FULL' | 'PARTIAL' | 'SIMPLE' ) )?
          ( referenceOption referenceOption? )?
        ;

    referenceOption
        : 'ON' ( 'UPDATE' | 'DELETE' )
          ( 'RESTRICT' | 'CASCADE' | 'SET' null_ | 'SET' 'DEFAULT' | 'NO' 'ACTION' )
        ;

server_ddl
    : 'CREATE' 'SERVER' qname 'FOREIGN' 'DATA' 'WRAPPER' qname 'OPTIONS' '(' serverOption ( ',' serverOption )* ')'
    | 'ALTER' 'SERVER' qname 'OPTIONS' '(' serverOption ( ',' serverOption )* ')'
    | 'DROP' 'SERVER' exists? name
    ;

    serverOption
        : 'HOST' string
        | 'DATABASE' string
        | 'USER' string
        | 'PASSWORD' string
        | 'SOCKET' string
        | 'OWNER' string
        | 'PORT' DECIMAL
        ;


rule_ddl
    : 'CREATE' 'ROLE' notExists? roleList
    | 'DROP' 'ROLE' exists? roleList
    ;

resourceGroup_ddl
    : 'CREATE' 'RESOURCE' 'GROUP' qname 'TYPE' equal_? ( 'USER' | 'SYSTEM' ) resourceGroupVcpuList? resourceGroupPriority? enable_?
    | 'ALTER' 'RESOURCE' 'GROUP' qname resourceGroupVcpuList? resourceGroupPriority? enable_? 'FORCE'?
    | 'SET' 'RESOURCE' 'GROUP' qname ( 'FOR' DECIMAL ( ','? DECIMAL )* )?
    | 'DROP' 'RESOURCE' 'GROUP' qname 'FORCE'?
    ;

    resourceGroupVcpuList
        : 'VCPU' equal_? range ( ','? range )* ;

    resourceGroupPriority
        : 'THREAD_PRIORITY' equal_? DECIMAL ;

logfileGroup_ddl
    : 'CREATE' 'LOGFILE' 'GROUP' qname 'ADD' 'UNDOFILE' string ( logfileAlterOption ( ','? logfileAlterOption )* )?
    | 'ALTER' 'LOGFILE' 'GROUP' qname 'ADD' 'UNDOFILE' string ( logfileCreateOptions ( ','? logfileCreateOptions )* )?
    | 'DROP' 'LOGFILE' 'GROUP' qname ( logfileDropOption ( ','? logfileDropOption )* )?
    ;

    logfileAlterOption
        : logfileCreateOptions
        | 'UNDO_BUFFER_SIZE' '='? byteSize
        | 'REDO_BUFFER_SIZE' '='? byteSize
        | 'NODEGROUP' '='? DECIMAL
        | 'COMMENT' '='? string
        ;

    logfileCreateOptions
        : 'INITIAL_SIZE' '='? byteSize
        | logfileDropOption
        ;

    logfileDropOption
        : 'WAIT'
        | 'NO_WAIT'
        | 'STORAGE'? 'ENGINE' '='? name
        ;

index_ddl
    : 'CREATE' ( 'UNIQUE' | 'FULLTEXT' | 'SPATIAL' )? 'INDEX' qname indexType? 'ON' qname '(' keyPart ( ',' keyPart )* ')' indexOption* commonIndexOption*
    | 'DROP' onlineOption? 'INDEX' qname 'ON' qname commonIndexOption*
    ;

    indexOption
        : 'KEY_BLOCK_SIZE' '='? DECIMAL
        | indexType
        | 'WITH' 'PARSER' name
        | comment
        | visibility_
        | 'ENGINE_ATTRIBUTE' '='? string
        | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
        ;

function_ddl
    : 'CREATE' definer? function_ notExists? qname '(' ( param ( ',' param )* )? ')' ( 'RETURNS' dataType collate? )? functionOption* ( compound | 'AS' string )
    | 'ALTER' function_ qname functionOption*
    | 'DROP' function_ exists? qname
    | 'CREATE' 'AGGREGATE'? 'FUNCTION' notExists? qname 'RETURNS' ( 'STRING' | int_ | 'REAL' | dec_ ) 'SONAME' string
    ;

    functionOption
        : comment
        | 'LANGUAGE' name
        | 'NOT'? 'DETERMINISTIC'
        | 'CONTAINS' 'SQL'
        | 'NO' 'SQL'
        | 'READS' 'SQL' 'DATA'
        | 'MODIFIES' 'SQL' 'DATA'
        | security
        | 'USING' '(' qname ( ',' qname )* ')'
        ;

event_ddl
    : 'CREATE' definer? 'EVENT' notExists? qname 'ON' 'SCHEDULE' schedule ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ( 'ENABLE' | 'DISABLE' ( 'ON' 'REPLICA' )? )? comment? 'DO' compound
    | 'ALTER' definer? 'EVENT' qname ( 'ON' 'SCHEDULE' schedule )? ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ( 'RENAME' 'TO' qname )? ( 'ENABLE' | 'DISABLE' ( 'ON' 'REPLICA' )? )? comment? ( 'DO' compound )?
    | 'DROP' 'EVENT' exists? qname
    ;

database_ddl
    : 'CREATE' database_ notExists? name databaseOption*
    | 'ALTER' database_ qname databaseOption+
    | 'DROP' database_ exists? qname
    ;

    databaseOption
        : 'DEFAULT'? charset_ '='? name
        | 'DEFAULT'? 'COLLATE' '='? name
        | 'DEFAULT'? 'ENCRYPTION' '='? string
        | 'READ' 'ONLY' '='? decimalDefault
        ;

commonIndexOption
    : 'ALGORITHM' '='? name
    | 'LOCK' '='? name
    ;

replaceString
    : 'REPLACE' string ;

startTransactionMode
    : ( 'WITH' 'CONSISTENT' 'SNAPSHOT' | 'READ' ( 'WRITE' | 'ONLY' ) ) ;

signalCondition
    : name
    | 'SQLSTATE' 'VALUE'? ( name | DECIMAL )
    ;

place
    : 'AFTER' name | 'FIRST' ;

allOrPartitionNameList
    : 'ALL'
    | name ( ',' name )*
    ;

viewOption
    : 'WITH' ( 'CASCADED' | 'LOCAL' )? 'CHECK' 'OPTION' ;

indexType
    : ( 'USING' | 'TYPE' ) ( 'BTREE' | 'HASH' | 'RTREE' ) ;

viewAlgorithm
    : 'ALGORITHM' '=' ( 'UNDEFINED' | 'MERGE' | 'TEMPTABLE' ) ;

security
    : 'SQL' 'SECURITY' ( 'DEFINER' | 'INVOKER' ) ;

srsAttribute
    : 'NAME' 'TEXT' string
    | 'DEFINITION' 'TEXT' string
    | 'ORGANIZATION' string 'IDENTIFIED' 'BY' DECIMAL
    | 'DESCRIPTION' 'TEXT' string
    ;

handlerReadOrScan
    : ( 'FIRST' | 'NEXT' )
    | name
      ( ( 'FIRST' | 'NEXT' | 'PREV' | 'LAST' )
      | ( '=' | '<' | '>' | '<=' | '>=' ) terms
      )
    ;

limitCount
    : 'LIMIT' DECIMAL ;

windowDef
    : name 'AS' windowSpec ;

windowSpec
    : '(' name? ( 'PARTITION' 'BY' orderExpression ( ',' orderExpression )* )? orderBy?
      ( ( 'ROWS' | 'RANGE' | 'GROUPS' ) ( windowFrameStart | windowFrameBetween )
      ( 'EXCLUDE' ( 'CURRENT' 'ROW' | 'GROUP' | 'TIES' | 'NO' 'OTHERS' ) )?
      )?
      ')'
    ;

windowFrameStart
    : literal 'PRECEDING'
//    : 'UNBOUNDED' 'PRECEDING'
//    | INTEGER 'PRECEDING'
//    | PARAM 'PRECEDING'
//    | 'INTERVAL' term interval 'PRECEDING'
    | 'CURRENT' 'ROW'
    ;

windowFrameBetween
    : 'BETWEEN' windowFrameBound 'AND' windowFrameBound ;

windowFrameBound
    : windowFrameStart
    | literal 'FOLLOWING'
//    | 'UNBOUNDED' 'FOLLOWING'
//    | INTEGER 'FOLLOWING'
//    | PARAM 'FOLLOWING'
//    | 'INTERVAL' term interval 'FOLLOWING'
    ;

orderExpression
    : term direction? ;

direction
    : 'ASC' | 'DESC' ;

tableReferenceList
    : tables ( ',' tables )* ;

values
    : 'VALUES' term ( ',' term )* ;

alias
    : 'AS'? name ;

jsonColumn
    : name 'FOR' 'ORDINALITY'
    | name dataType collate? 'EXISTS'? 'PATH' string ( jsonResponse jsonResponse? )?
    | 'NESTED' 'PATH' string 'COLUMNS' '(' jsonColumn ( ',' jsonColumn )* ')'
    ;

jsonResponse
    : ( 'ERROR' | 'NULL' | 'DEFAULT' string ) 'ON' ( 'EMPTY' | 'ERROR' ) ;

indexHint
    : ( 'USE' | 'IGNORE' | 'FORCE' ) index_ indexHintScope? '(' ( name ( ',' name )* )? ')'
//    | index_ indexHintScope? '(' ( name ( ',' name )* ) ')'
    ;

indexHintScope
    : 'FOR' ( 'JOIN' | 'ORDER' 'BY' | 'GROUP' 'BY' ) ;

beginWork
    : 'BEGIN' 'WORK'? ;

lockItem
    : qname alias? ( 'READ' 'LOCAL'? | 'WRITE' ) ;

xid
    : string ( ',' string ( ',' ( DECIMAL | string ) )? )? ;

resetOption
    : 'BINARY' 'LOGS' 'AND' 'GTIDS' ( 'TO' DECIMAL )?
    | 'REPLICA' 'ALL'? forChannel?
    ;

sourceDefinition
    : 'SOURCE_HOST' '=' string
    | 'NETWORK_NAMESPACE' '=' string
    | 'SOURCE_BIND' '=' string
    | 'SOURCE_USER' '=' string
    | 'SOURCE_PASSWORD' '=' string
    | 'SOURCE_PORT' '=' DECIMAL
    | 'SOURCE_CONNECT_RETRY' '=' DECIMAL
    | 'SOURCE_RETRY_COUNT' '=' DECIMAL
    | 'SOURCE_DELAY' '=' DECIMAL
    | 'SOURCE_SSL' '=' DECIMAL
    | 'SOURCE_SSL_CA' '=' string
    | 'SOURCE_SSL_CAPATH' '=' string
    | 'SOURCE_TLS_VERSION' '=' string
    | 'SOURCE_SSL_CERT' '=' string
    | 'SOURCE_TLS_CIPHERSUITES' '=' name
    | 'SOURCE_SSL_CIPHER' '=' string
    | 'SOURCE_SSL_KEY' '=' string
    | 'SOURCE_SSL_VERIFY_SERVER_CERT' '=' DECIMAL
    | 'SOURCE_SSL_CRL' '=' string
    | 'SOURCE_SSL_CRLPATH' '=' string
    | 'SOURCE_PUBLIC_KEY_PATH' '=' string
    | 'GET_SOURCE_PUBLIC_KEY' '=' DECIMAL
    | 'SOURCE_HEARTBEAT_PERIOD' '=' literal
    | 'IGNORE_SERVER_IDS' '=' '(' ( DECIMAL ( ',' DECIMAL )* )? ')'
    | 'SOURCE_COMPRESSION_ALGORITHM' '=' string
    | 'SOURCE_ZSTD_COMPRESSION_LEVEL' '=' DECIMAL
    | 'SOURCE_AUTO_POSITION' '=' DECIMAL
    | 'PRIVILEGE_CHECKS_USER' '=' user
    | 'REQUIRE_ROW_FORMAT' '=' DECIMAL
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK' '=' ( 'STREAM' | 'ON' | 'OFF' | 'GENERATE' )
    | 'SOURCE_CONNECTION_AUTO_FAILOVER' '=' DECIMAL
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS' '=' ( 'OFF' | 'LOCAL' | string )
    | 'GTID_ONLY' '=' DECIMAL
    | sourceFileDef
    ;

sourceFileDef
    : 'SOURCE_LOG_FILE' '=' string
    | 'SOURCE_LOG_POS' '=' DECIMAL
    | 'RELAY_LOG_FILE' '=' string
    | 'RELAY_LOG_POS' '=' DECIMAL
    ;

// TODO use qname (vs name, string) for all?
filterDefinition
    : 'REPLICATE_DO_DB' '=' '(' ( name ( ',' name )* )? ')'
    | 'REPLICATE_IGNORE_DB' '=' '(' ( name ( ',' name )* )? ')'
    | 'REPLICATE_DO_TABLE' '=' '(' ( qname ( ',' qname )* )? ')'
    | 'REPLICATE_IGNORE_TABLE' '=' '(' ( qname ( ',' qname )* )? ')'
    | 'REPLICATE_WILD_DO_TABLE' '=' '(' ( string ( ',' string )* )? ')'
    | 'REPLICATE_WILD_IGNORE_TABLE' '=' '(' ( string ( ',' string )* )? ')'
    | 'REPLICATE_REWRITE_DB' '=' '(' ( schemaIdentifierPair ( ',' schemaIdentifierPair )* )? ')'
    ;

schemaIdentifierPair
    : '(' name ',' name ')' ;

replicaUntil
    : sourceFileDef
    | 'SQL_BEFORE_GTIDS' '=' string
    | 'SQL_AFTER_GTIDS' '=' string
    | 'SQL_AFTER_MTS_GAPS'
    ;

userOption
    : 'USER' '=' string ;

defaultAuthOption
    : 'DEFAULT_AUTH' '=' string ;

pluginDirOption
    : 'PLUGIN_DIR' '=' string ;

replicaThreadOptions
    : replicaThreadOption ( ',' replicaThreadOption )* ;

replicaThreadOption
    : 'SQL_THREAD'
    | 'RELAY_THREAD'
    ;

groupReplicationStartOptions
    : groupReplicationStartOption ( ',' groupReplicationStartOption )* ;

groupReplicationStartOption
    : 'USER' '=' string
    | 'PASSWORD' '=' string
    | 'DEFAULT_AUTH' '=' string
    ;

ssl
    : 'REQUIRE' 'NO'? 'SSL' ;

resourceWith
    : 'WITH'
      ( ( 'MAX_QUERIES_PER_HOUR'
        | 'MAX_UPDATES_PER_HOUR'
        | 'MAX_CONNECTIONS_PER_HOUR'
        | 'MAX_USER_CONNECTIONS'
        ) DECIMAL
      )+ ;

require
    : 'REQUIRE' ( 'NONE' | tlsOption ( 'AND'? tlsOption )* ) ;

tlsOption
    : 'SSL'
    | 'X509'
    | ( 'CIPHER' | 'ISSUER' | 'SUBJECT' ) string
    ;

passwordOption
    : 'PASSWORD' 'EXPIRE' ( 'DEFAULT' | 'NEVER' | 'INTERVAL' DECIMAL 'DAY' )?
    | 'PASSWORD' 'HISTORY' ( 'DEFAULT' | DECIMAL )
    | 'PASSWORD' 'REUSE' 'INTERVAL' ( 'DEFAULT' | DECIMAL 'DAY' )
    | 'PASSWORD' 'REQUIRE' 'CURRENT' ( 'DEFAULT' | 'OPTIONAL' )?
    | 'FAILED_LOGIN_ATTEMPTS' DECIMAL
    | 'PASSWORD_LOCK_TIME' ( DECIMAL | 'UNBOUNDED' )
    | 'ACCOUNT' ( 'LOCK' | 'UNLOCK' )
    ;

grant
    : 'GRANT' ( roleOrPrivilegesList | 'ALL' 'PRIVILEGES'? ) 'ON' aclType? grantIdentifier
      'TO' grantTargetList ( 'WITH' 'GRANT' 'OPTION' )?
      // require? grantOptions?
      ( 'AS' user withRoles? )?
    | 'GRANT' 'PROXY' 'ON' user 'TO' grantTargetList
    | 'GRANT' roleOrPrivilegesList 'TO' user ( ',' user )* ( 'WITH' 'ADMIN' 'OPTION' )?
    ;

grantTargetList
    :  user ( ',' user )* ;

exceptRoleList
    : 'EXCEPT' roleList ;

withRoles
    : 'WITH' 'ROLE'
      ( roleList
      | 'ALL' exceptRoleList?
      | 'NONE'
      | 'DEFAULT'
      )
    ;

revoke
    : 'REVOKE' exists?
      ( roleOrPrivilegesList 'FROM' user ( ',' user )*
      | roleOrPrivilegesList 'ON' aclType? grantIdentifier 'FROM' user ( ',' user )*
      | 'ALL' 'PRIVILEGES'?
        ( 'ON' aclType? grantIdentifier
        | ',' 'GRANT' 'OPTION'
        )
        'FROM' user ( ',' user )*
      | 'PROXY' 'ON' user 'FROM' user ( ',' user )*
      )
      ( 'IGNORE' 'UNKNOWN' 'USER' )?
    ;

aclType
    : 'TABLE'
    | 'FUNCTION'
    | 'PROCEDURE'
    ;

roleOrPrivilegesList
    : roleOrPrivilege ( ',' roleOrPrivilege )* ;

roleOrPrivilege
    : tableColumns
    | user
    | ( 'SELECT' | 'INSERT' | 'UPDATE' | 'REFERENCES' ) ( '(' name ( ',' name )* ')' )?
    | 'DELETE' | 'USAGE' | 'INDEX' | 'DROP' | 'EXECUTE' | 'RELOAD' | 'SHUTDOWN' | 'PROCESS' | 'FILE' | 'PROXY' | 'SUPER' | 'EVENT' | 'TRIGGER'
    | 'GRANT' 'OPTION'
    | 'SHOW' 'DATABASES'
    | 'CREATE' ( 'TEMPORARY' 'TABLES' | 'ROUTINE' | 'TABLESPACE' | 'USER' | 'VIEW' )?
    | 'LOCK' 'TABLES'
    | 'REPLICATION' ( 'CLIENT' | 'REPLICA' )
    | 'SHOW' 'VIEW'
    | 'ALTER' 'ROUTINE'?
    | ( 'CREATE' | 'DROP' ) 'ROLE'
    ;

grantIdentifier
    : ( '*' | name ) ( '.' ( '*' | name ) )? ;

setRole
    : 'SET' 'ROLE' roleList
    | 'SET' 'ROLE' ( 'NONE' | 'DEFAULT' )
    | 'SET' 'ROLE' 'ALL' ( 'EXCEPT' roleList )?
    | 'SET' 'DEFAULT' 'ROLE' ( roleList | 'NONE' | 'ALL' ) 'TO' roleList
    ;

roleList
    : user ( ',' user )* ;

histogram
    : 'UPDATE' 'HISTOGRAM' 'ON' name
      ( ( ',' name )* ( 'WITH' DECIMAL 'BUCKETS' )? ( ( 'MANUAL' | 'AUTO' )? 'UPDATE' )?
      | ( 'USING' 'DATA' string )?
      )
    | 'DROP' 'HISTOGRAM' 'ON' name ( ',' name )*
    ;

checkOption
    : 'FOR' 'UPGRADE'
    | 'QUICK' | 'FAST' | 'MEDIUM' | 'EXTENDED' | 'CHANGED'
    ;

repairType
    : 'QUICK'
    | 'EXTENDED'
    | 'USE_FRM'
    ;

transactionCharacteristics
    : 'ISOLATION' 'LEVEL'
      ( 'REPEATABLE' 'READ'
      | 'READ' ( 'COMMITTED' | 'UNCOMMITTED' )
      | 'SERIALIZABLE'
      )
    | 'READ' ( 'WRITE' | 'ONLY' )
    ;

inDb
    : ( 'FROM' | 'IN' ) qname ;

profileDef
    : 'CPU'
    | 'MEMORY'
    | 'BLOCK' 'IO'
    | 'CONTEXT' 'SWITCHES'
    | 'PAGE' 'FAULTS'
    | 'IPC'
    | 'SWAPS'
    | 'SOURCE'
    | 'ALL'
    ;

keyCacheListOrParts
    : assignToKeycache ( ',' assignToKeycache )*
    | qname 'PARTITION' '(' allOrPartitionNameList ')' cacheKeyList?
    ;

assignToKeycache
    : qname cacheKeyList? ;

cacheKeyList
    : index_ '(' ( name ( ',' name )* )? ')' ;

flushOption
    : ( 'HOSTS' | 'PRIVILEGES' | 'STATUS' | 'USER_RESOURCES' )
    | ( 'BINARY' | 'ENGINE' | 'ERROR' | 'GENERAL' | 'SLOW' )? 'LOGS'
    | 'RELAY' 'LOGS' forChannel?
    | 'OPTIMIZER_COSTS'
    ;

flushTables
    : table_
      ( 'WITH' 'READ' 'LOCK'
      | qname ( ',' qname )* ( 'FOR' 'EXPORT' | 'WITH' 'READ' 'LOCK' )?
      )?
    ;

preloadKeys
    : qname ( 'PARTITION' '(' allOrPartitionNameList ')' )? cacheKeyList? ( 'IGNORE' 'LEAVES' )? ;

range
    : DECIMAL ( '-' DECIMAL )? ;

interval
    : 'INTERVAL' term timeUnitToo ;

castType
    : 'BINARY' ( '(' DECIMAL ')' )?
    | 'CHAR' ( '(' DECIMAL ')' )? ( charset_ name )? 'BINARY'?
    | ( 'NCHAR' | 'NATIONAL' 'CHAR' ) ( '(' DECIMAL ')' )?
    | ( 'SIGNED' | 'UNSIGNED' )? int_?
    | 'DATE'
    | 'YEAR'
    | 'TIME' ( '(' DECIMAL ')' )?
    | 'DATETIME' ( '(' DECIMAL ')' )?
    | dec_ floatOptions?
    | 'JSON'
    | 'REAL'
    | 'DOUBLE' 'PRECISION'?

    | 'FLOAT' floatOptions?
    | 'POINT'
    | 'LINESTRING'
    | 'POLYGON'
    | 'MULTIPOINT'
    | 'MULTILINESTRING'
    | 'MULTIPOLYGON'
    | 'GEOMETRYCOLLECTION'
    | 'GEOMCOLLECTION'
    ;

dataType
    : ( int_ | 'TINYINT' | 'SMALLINT' | 'MEDIUMINT' | 'BIGINT' ) typeLength? fieldOptions_*
    | ( 'REAL' | 'DOUBLE' 'PRECISION'? ) typePrecision? fieldOptions_*
    | ( 'FLOAT' | dec_ | 'NUMERIC' | 'FIXED' ) floatOptions? fieldOptions_*
    | 'BIT' typeLength?
    | 'BOOL'
    | 'BOOLEAN'
    | ( char_ 'VARYING'?
      | 'NATIONAL' char_ 'VARYING'?
      | 'NATIONAL'? 'VARCHAR'
      | 'NVARCHAR'
      | 'NCHAR' ( 'VARCHAR' | 'VARYING' )?
      ) typeLength? characterType*

    | 'BINARY' typeLength?

    | 'VARBINARY' typeLength
    | 'VECTOR' ( '(' DECIMAL ')' )?

    | 'YEAR' typeLength? fieldOptions_*
    | 'DATE'
    | 'TIME' ( '(' DECIMAL ')' )?
    | 'TIMESTAMP' ( '(' DECIMAL ')' )?
    | 'DATETIME' ( '(' DECIMAL ')' )?
    | 'TINYBLOB'
    | 'BLOB' typeLength?

    | 'GEOMETRY'
    | 'GEOMETRYCOLLECTION'
    | 'GEOMCOLLECTION'
    | 'POINT'
    | 'MULTIPOINT'
    | 'LINESTRING'
    | 'MULTILINESTRING'
    | 'POLYGON'
    | 'MULTIPOLYGON'

    | 'MEDIUMBLOB'
    | 'LONGBLOB'
    | 'LONG' 'VARBINARY'
    | 'LONG' ( 'CHAR' 'VARYING' | 'VARCHAR' )? characterType?
    | 'TINYTEXT' characterType?
    | 'TEXT' typeLength? characterType?
    | 'MEDIUMTEXT' characterType?
    | 'LONGTEXT' characterType?
    | 'ENUM' '(' term ( ',' term )* ')' characterType?
    | 'SET' '(' string ( ',' string )* ')' characterType?
    | 'LONG' characterType?
    | 'SERIAL'
    | 'JSON'

    | ( 'FLOAT4'
      | 'FLOAT8'
      | 'INT1'
      | 'INT2'
      | 'INT3'
      | 'INT4'
      | 'INT8'
      | 'MIDDLEINT' 
      ) fieldOptions_*
    ;

    floatOptions
        : typeLength | typePrecision ;

    typePrecision
        : '(' DECIMAL ',' DECIMAL ')' ;

    typeLength
        : '(' ( DECIMAL | FLOAT ) ')' ;

    characterType
        : 'BYTE'
        | 'BINARY' ( 'ASCII' | charsetName | 'UNICODE' )?
        | 'BINARY'? ( 'ASCII' | charsetName | 'UNICODE' )
        ;

charsetName
    : charset_ name ;

timeUnitToo
    : timeUnit
    | 'SECOND_MICROSECOND'
    | 'MINUTE_MICROSECOND'
    | 'MINUTE_SECOND'
    | 'HOUR_MICROSECOND'
    | 'HOUR_SECOND'
    | 'HOUR_MINUTE'
    | 'DAY_MICROSECOND'
    | 'DAY_SECOND'
    | 'DAY_MINUTE'
    | 'DAY_HOUR'
    | 'YEAR_MONTH'
    ;

timeUnit
    : 'MICROSECOND'
    | 'SECOND'
    | 'MINUTE'
    | 'HOUR'
    | 'DAY'
    | 'WEEK'
    | 'MONTH'
    | 'QUARTER'
    | 'YEAR'
    ;

forChannel
    : 'FOR' 'CHANNEL' string ;

compound
    : dml
    | ddl
    | block
    | name ':' block name?
    | 'IF' if 'END' 'IF'
    | 'CASE' term? ( 'WHEN' term then )+ ( 'ELSE' ( compound ';' )+ )? 'END' 'CASE'
    | 'ITERATE' name
    | 'OPEN' name
    | 'CLOSE' name
    | 'FETCH' ( 'NEXT'? 'FROM' )? name 'INTO' name ( ',' name )*
    | 'LEAVE' name
    | 'RETURN' term
    ;

    block
        : 'BEGIN' ( declare ';' )* ( compound ';' )* 'END'
        | 'LOOP' ( compound ';' )+ 'END' 'LOOP'
        | 'WHILE' term 'DO' ( compound ';' )+ 'END' 'WHILE'
        | 'REPEAT' ( compound ';' )+ 'UNTIL' term 'END' 'REPEAT'
        ;

    if
        : term then ( 'ELSEIF' if | 'ELSE' ( compound ';' )+ )? ;

    then
        : 'THEN' ( compound ';' )+ ;

    declare
        : 'DECLARE' name ( ',' name )* dataType collate? ( 'DEFAULT' term )?
        | 'DECLARE' name 'CONDITION' 'FOR' sqlState
        | 'DECLARE' ( 'CONTINUE' | 'EXIT' | 'UNDO' ) 'HANDLER' 'FOR' condition ( ',' condition )* compound
        | 'DECLARE' name 'CURSOR' 'FOR' select
        ;

    condition
        : sqlState
        | name
        | 'SQLWARNING'
        | 'NOT' 'FOUND'
        | 'SQLEXCEPTION'
        ;

    sqlState
        : DECIMAL
        | 'SQLSTATE' 'VALUE'? string
        ;

statementInformationItem
    : qname '=' ( 'NUMBER' | 'ROW_COUNT' ) ;

conditionInformationItem
    : qname '=' ( signalName | 'RETURNED_SQLSTATE' ) ;

signalItem
    : signalName '=' ( qname | DECIMAL ) ;

signalName
    : 'CLASS_ORIGIN'
    | 'SUBCLASS_ORIGIN'
    | 'CONSTRAINT_CATALOG'
    | 'CONSTRAINT_SCHEMA'
    | 'CONSTRAINT_NAME'
    | 'CATALOG_NAME'
    | 'SCHEMA_NAME'
    | 'TABLE_NAME'
    | 'COLUMN_NAME'
    | 'CURSOR_NAME'
    | 'MESSAGE_TEXT'
    | 'MYSQL_ERRNO'
    ;

schedule
    : 'AT' term
    | 'EVERY' term timeUnitToo ( 'STARTS' term )? ( 'ENDS' term )?
    ;

createDef
    : qname dataType columnAttribute* ;

// TODO refactor this and table constraint defs to better match docs
// https://dev.mysql.com/doc/refman/9.3/en/create-table.html
columnAttribute
    : 'NOT'? null_
    | 'NOT' 'SECONDARY'
    | 'DEFAULT' ( now | literal | '(' term ')' )
    | 'ON' 'UPDATE' now
    | 'AUTO_INCREMENT'
    | 'SERIAL' 'DEFAULT' 'VALUE'
    | 'PRIMARY'? 'KEY'
    | 'UNIQUE' 'KEY'?
    | comment
    | 'COLUMN_FORMAT' ( 'FIXED' | 'DYNAMIC' | 'DEFAULT' )
    | 'STORAGE' ( 'DISK' | 'MEMORY' | 'DEFAULT' )
    | 'SRID' DECIMAL
    | ( 'CONSTRAINT' name? )? 'CHECK' '(' term ')' ( 'NOT'? 'ENFORCED' )?
    | enforced_
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | visibility_
    | ( 'GENERATED' 'ALWAYS' )? 'AS' '(' term ')' ( 'VIRTUAL' | 'STORED' )?
    | referenceDef
    | collate
    ;

now
    : ( 'NOW' | 'CURRENT_TIMESTAMP' | 'LOCALTIME' | 'LOCALTIMESTAMP' ) ( '(' DECIMAL? ')' )? ;

keyPart
    : ( name typeLength? | '(' term ')' ) direction? ;

decimalDefault
    : DECIMAL | 'DEFAULT' ;

partitionBy
    : 'PARTITION' 'BY'
      ( hash
      | ( 'RANGE' | 'LIST' )
          ( '(' term ')'
          | 'COLUMNS' '(' ( name ( ',' name )* )? ')'
          )
      )
      ( 'PARTITIONS' DECIMAL )?
      ( 'SUBPARTITION' 'BY' hash ( 'SUBPARTITIONS' DECIMAL )? )?
      ( '(' partitionDef ( ',' partitionDef )* ')' )?
    ;

hash
    : 'LINEAR'?
      ( 'HASH' '(' term ')'
      | 'KEY' ( 'ALGORITHM' '=' DECIMAL )? '(' ( name ( ',' name )* )? ')'
      )
      ;

partitionDef
    : 'PARTITION' name
        ( 'VALUES'
            ( 'LESS' 'THAN' ( terms | 'MAXVALUE' )
            | 'IN' terms
            )
        )?
        partitionOption*
        ( '(' subpartition ( ',' subpartition )* ')' )?
    ;

    subpartition
        : 'SUBPARTITION' name partitionOption* ;

    partitionOption
        : 'COMMENT' '='? string
        | 'DEFAULT'? 'ENGINE' '='? name
        | 'NODEGROUP' '='? DECIMAL
        | 'TABLESPACE' '='? name
        | 'DATA' 'DIRECTORY' '='? string
        | 'INDEX' 'DIRECTORY' '='? string
        | ( 'MAX_ROWS' | 'MIN_ROWS' ) '='? DECIMAL
        ;

definer
    : 'DEFINER' '=' user ;

param
    : ( 'IN' | 'OUT' | 'INOUT' )? name dataType ;

collate
    : 'COLLATE' name ;

setter
    : scope? qname equal_? term ;

scope
    : 'PERSIST'
    | 'PERSIST_ONLY'
    | 'GLOBAL'
    | 'LOCAL'
    | 'SESSION'
    ;

fieldHandling
    : ( 'FIELDS' | 'COLUMNS' )
      ( ( 'TERMINATED' | 'OPTIONALLY'? 'ENCLOSED' | 'ESCAPED' ) 'BY' string )+
    ;

lineHandling
    : 'LINES' ( ( 'STARTING' | 'TERMINATED' ) 'BY' string )+ ;

userAuthID
    : user ( identified ( 'AND' identified ( 'AND' identified )? )? )? ;

identified
    : 'IDENTIFIED' 'WITH' qname ( 'AS' qname )?
    | 'IDENTIFIED' ( 'WITH' qname )? ( 'BY' ( qname | 'RANDOM' 'PASSWORD' ))
    ;

retainCurrentPassword
    : 'RETAIN' 'CURRENT' 'PASSWORD' ;

userRegistration
    : factor 'INITIATE' 'REGISTRATION'
    | factor 'UNREGISTER'
    | factor 'FINISH' 'REGISTRATION' 'SET' 'CHALLENGE_RESPONSE' 'AS' string
    ;

factor
    : DECIMAL 'FACTOR' ;

user
    : name ( '@' | qname )?
    | 'CURRENT_USER' ( '(' ')' )?
    ;

like
    : 'LIKE' name | where ;

onlineOption
    : 'ONLINE' | 'OFFLINE' ;

noLogging
    : 'LOCAL' | 'NO_WRITE_TO_BINLOG' ;

partition
    : 'PARTITION' '(' name ( ',' name )* ')' ;

qname
    : ( '.'? name | LOCAL | GLOBAL ) ( ( '.' name )? '.' ( name | '*' ) )? ;

name
    : ID
    | keyword
    | string
    // TODO remove this after lexer rule CHARSET is fixed
    | CHARSET
    ;

literal
    : ID
    | keyword
    | string
    | ( '+' | '-' )? DECIMAL
    | ( '+' | '-' )? FLOAT
    | BINARY
    | SIZE
    | datetime
    | null_
    | PARAM
    // TODO is this needed? mooted by rule qname?
    | LOCAL
    | GLOBAL
    | interval
    ;

string
    : CHARSET? ( STRING | QUOTED )+
    | CHARSET? HEXADECIMAL
    | CHARSET? BLOB
    | NATIONAL ( STRING | QUOTED )*
    // TODO disable <secret> after testing
    | '<secret>'
    ;

datetime
    : ( 'DATE' | 'TIME' | 'TIMESTAMP' ) string ;

byteSize
    : DECIMAL | SIZE ;


// Really simple rules, just terminal tokens; kinda like macros

exists
    : 'IF' 'EXISTS' ;

notExists
    : 'IF' 'NOT' 'EXISTS' ;

char_
    : 'CHAR' | 'CHARACTER' ;

charset_
    : char_ 'SET' | 'CHARSET' ;

database_
    : 'DATABASE' | 'SCHEMA' ;

dec_
    : 'DEC' | 'DECIMAL' ;

enable_
    : 'ENABLE' | 'DISABLE' ;

enforced_
    : 'NOT'? 'ENFORCED' ;

equal_
    : '=' | ':=' ;

fieldOptions_
    : 'SIGNED' | 'UNSIGNED' | 'ZEROFILL' ;

function_
    : 'FUNCTION' | 'PROCEDURE' ;

index_
    : 'INDEX' | 'KEY' ;

int_
    : 'INT' | 'INTEGER' ;

null_
    : 'NULL' | NOPE ;

orReplace_
    : 'OR' 'REPLACE' ;

table_
    : 'TABLE' | 'TABLES' ;

validation_
    : ( 'WITH' | 'WITHOUT' ) 'VALIDATION' ;

visibility_
    : 'VISIBLE' | 'INVISIBLE' ;


// TODO comment out reserved words
keyword
    : 'ACCOUNT'
    | 'ACTION'
    | 'ACTIVE'
    | 'ADD'
    | 'ADDDATE'
    | 'ADMIN'
    | 'AFTER'
    | 'AGAINST'
    | 'AGGREGATE'
    | 'ALGORITHM'
    | 'ALL'
    | 'ALTER'
    | 'ALWAYS'
    | 'ANALYZE'
    | 'AND'
    | 'ANY'
    | 'ARRAY'
    | 'AS'
    | 'ASC'
    | 'ASCII'
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS'
    | 'AT'
    | 'ATTRIBUTE'
    | 'AUTHENTICATION'
    | 'AUTO'
    | 'AUTO_INCREMENT'
    | 'AUTOEXTEND_SIZE'
    | 'AVG'
    | 'AVG_ROW_LENGTH'
    | 'BACKUP'
    | 'BEFORE'
    | 'BEGIN'
    | 'BERNOULLI'
    | 'BETWEEN'
    | 'BIGINT'
    | 'BINARY'
    | 'BINLOG'
    | 'BIT'
    | 'BIT_AND'
    | 'BIT_OR'
    | 'BIT_XOR'
    | 'BLOB'
    | 'BLOCK'
    | 'BOOL'
    | 'BOOLEAN'
    | 'BOTH'
    | 'BTREE'
    | 'BUCKETS'
    | 'BULK'
    | 'BY'
    | 'BYTE'
    | 'CACHE'
    | 'CALL'
    | 'CASCADE'
    | 'CASCADED'
    | 'CASE'
    | 'CAST'
    | 'CATALOG_NAME'
    | 'CHAIN'
    | 'CHALLENGE_RESPONSE'
    | 'CHANGE'
    | 'CHANGED'
    | 'CHANNEL'
    | 'CHAR'
    | 'CHARACTER'
    | 'CHARSET'
    | 'CHECK'
    | 'CHECKSUM'
    | 'CIPHER'
    | 'CLASS_ORIGIN'
    | 'CLIENT'
    | 'CLONE'
    | 'CLOSE'
    | 'CLUSTERING'
    | 'COALESCE'
    | 'CODE'
    | 'COLLATE'
    | 'COLLATION'
    | 'COLUMN'
    | 'COLUMN_FORMAT'
    | 'COLUMN_NAME'
    | 'COLUMNS'
    | 'COMMENT'
    | 'COMMIT'
    | 'COMMITTED'
    | 'COMPACT'
    | 'COMPLETION'
    | 'COMPONENT'
    | 'COMPRESSED'
    | 'COMPRESSION'
    | 'CONCURRENT'
    | 'CONDITION'
    | 'CONNECTION'
    | 'CONSISTENT'
    | 'CONSTRAINT'
    | 'CONSTRAINT_CATALOG'
    | 'CONSTRAINT_NAME'
    | 'CONSTRAINT_SCHEMA'
    | 'CONTAINS'
    | 'CONTEXT'
    | 'CONTINUE'
    | 'CONVERT'
    | 'COUNT'
    | 'CPU'
    | 'CREATE'
    | 'CROSS'
    | 'CUBE'
    | 'CUME_DIST'
    | 'CURDATE'
    | 'CURRENT'
    | 'CURRENT_TIMESTAMP'
    | 'CURRENT_USER'
    | 'CURSOR'
    | 'CURSOR_NAME'
    | 'CURTIME'
    | 'DATA'
    | 'DATABASE'
    | 'DATABASES'
    | 'DATAFILE'
    | 'DATE'
    | 'DATE_ADD'
    | 'DATE_SUB'
    | 'DATETIME'
    | 'DAY'
    | 'DAY_HOUR'
    | 'DAY_MICROSECOND'
    | 'DAY_MINUTE'
    | 'DAY_SECOND'
    | 'DEALLOCATE'
    | 'DEC'
    | 'DECIMAL'
    | 'DECLARE'
    | 'DEFAULT'
    | 'DEFAULT_AUTH'
    | 'DEFINER'
    | 'DEFINITION'
    | 'DELAY_KEY_WRITE'
    | 'DELAYED'
    | 'DELETE'
    | 'DENSE_RANK'
    | 'DESC'
    | 'DESCRIBE'
    | 'DESCRIPTION'
    | 'DETERMINISTIC'
    | 'DIAGNOSTICS'
    | 'DIRECTORY'
    | 'DISABLE'
    | 'DISCARD'
    | 'DISK'
    | 'DISTINCT'
    | 'DISTINCTROW'
    | 'DIV'
    | 'DO'
    | 'DOUBLE'
    | 'DROP'
    | 'DUAL'
    | 'DUMPFILE'
    | 'DUPLICATE'
    | 'DYNAMIC'
    | 'EACH'
    | 'ELSE'
    | 'ELSEIF'
    | 'EMPTY'
    | 'ENABLE'
    | 'ENCLOSED'
    | 'ENCRYPTION'
    | 'END'
    | 'ENDS'
    | 'ENFORCED'
    | 'ENGINE'
    | 'ENGINE_ATTRIBUTE'
    | 'ENGINES'
    | 'ENUM'
    | 'ERROR'
    | 'ERRORS'
    | 'ESCAPE'
    | 'ESCAPED'
    | 'EVENT'
    | 'EVENTS'
    | 'EVERY'
    | 'EXCEPT'
    | 'EXCHANGE'
    | 'EXCLUDE'
    | 'EXECUTE'
    | 'EXISTS'
    | 'EXIT'
    | 'EXPANSION'
    | 'EXPIRE'
    | 'EXPLAIN'
    | 'EXPORT'
    | 'EXTENDED'
    | 'EXTENT_SIZE'
    | 'EXTRACT'
    | 'FACTOR'
    | 'FAILED_LOGIN_ATTEMPTS'
    | 'FALSE'
    | 'FAST'
    | 'FAULTS'
    | 'FETCH'
    | 'FIELDS'
    | 'FILE'
    | 'FILE_BLOCK_SIZE'
    | 'FILTER'
    | 'FINISH'
    | 'FIRST'
    | 'FIRST_VALUE'
    | 'FIXED'
    | 'FLOAT'
    | 'FLOAT4'
    | 'FLOAT8'
    | 'FLUSH'
    | 'FOLLOWING'
    | 'FOLLOWS'
    | 'FOR'
    | 'FORCE'
    | 'FOREIGN'
    | 'FORMAT'
    | 'FOUND'
    | 'FROM'
    | 'FULL'
    | 'FULLTEXT'
    | 'FUNCTION'
    | 'GENERAL'
    | 'GENERATE'
    | 'GENERATED'
    | 'GEOMCOLLECTION'
    | 'GEOMETRY'
    | 'GEOMETRYCOLLECTION'
    | 'GET'
    | 'GET_FORMAT'
    | 'GET_SOURCE_PUBLIC_KEY'
    | 'GLOBAL'
    | 'GRANT'
    | 'GRANTS'
    | 'GROUP'
    | 'GROUP_CONCAT'
    | 'GROUP_REPLICATION'
    | 'GROUPING'
    | 'GROUPS'
    | 'GTID_ONLY'
    | 'GTIDS'
    | 'HANDLER'
    | 'HASH'
    | 'HAVING'
    | 'HELP'
    | 'HIGH_PRIORITY'
    | 'HISTOGRAM'
    | 'HISTORY'
    | 'HOST'
    | 'HOSTS'
    | 'HOUR'
    | 'HOUR_MICROSECOND'
    | 'HOUR_MINUTE'
    | 'HOUR_SECOND'
    | 'IDENTIFIED'
    | 'IF'
    | 'IGNORE'
    | 'IGNORE_SERVER_IDS'
    | 'IMPORT'
    | 'IN'
    | 'INACTIVE'
    | 'INDEX'
    | 'INDEXES'
    | 'INFILE'
    | 'INITIAL'
    | 'INITIAL_SIZE'
    | 'INITIATE'
    | 'INNER'
    | 'INNODB'
    | 'INOUT'
    | 'INSERT'
    | 'INSERT_METHOD'
    | 'INSTALL'
    | 'INSTANCE'
    | 'INT'
    | 'INT1'
    | 'INT2'
    | 'INT3'
    | 'INT4'
    | 'INT8'
    | 'INTEGER'
    | 'INTERSECT'
    | 'INTERVAL'
    | 'INTO'
    | 'INVISIBLE'
    | 'INVOKER'
    | 'IO'
    | 'IPC'
    | 'IS'
    | 'ISOLATION'
    | 'ISSUER'
    | 'ITERATE'
    | 'JOIN'
    | 'JSON'
    | 'JSON_ARRAYAGG'
    | 'JSON_OBJECTAGG'
    | 'JSON_TABLE'
    | 'JSON_VALUE'
    | 'KEY'
    | 'KEY_BLOCK_SIZE'
    | 'KEYRING'
    | 'KEYS'
    | 'KILL'
    | 'LAG'
    | 'LANGUAGE'
    | 'LAST'
    | 'LAST_VALUE'
    | 'LATERAL'
    | 'LEAD'
    | 'LEADING'
    | 'LEAVE'
    | 'LEAVES'
    | 'LEFT'
    | 'LESS'
    | 'LEVEL'
    | 'LIBRARY'
    | 'LIKE'
    | 'LIMIT'
    | 'LINEAR'
    | 'LINES'
    | 'LINESTRING'
    | 'LIST'
    | 'LOAD'
    | 'LOCAL'
    | 'LOCALTIME'
    | 'LOCALTIMESTAMP'
    | 'LOCK'
    | 'LOCKED'
    | 'LOG'
    | 'LOGFILE'
    | 'LOGS'
    | 'LONG'
    | 'LONGBLOB'
    | 'LONGTEXT'
    | 'LOOP'
    | 'LOW_PRIORITY'
    | 'MANUAL'
    | 'MASTER'
    | 'MATCH'
    | 'MAX'
    | 'MAX_CONNECTIONS_PER_HOUR'
    | 'MAX_QUERIES_PER_HOUR'
    | 'MAX_ROWS'
    | 'MAX_SIZE'
    | 'MAX_UPDATES_PER_HOUR'
    | 'MAX_USER_CONNECTIONS'
    | 'MAXVALUE'
    | 'MEDIUM'
    | 'MEDIUMBLOB'
    | 'MEDIUMINT'
    | 'MEDIUMTEXT'
    | 'MEMBER'
    | 'MEMORY'
    | 'MERGE'
    | 'MESSAGE_TEXT'
    | 'MICROSECOND'
    | 'MIDDLEINT'
    | 'MIGRATE'
    | 'MIN'
    | 'MIN_ROWS'
    | 'MINUTE'
    | 'MINUTE_MICROSECOND'
    | 'MINUTE_SECOND'
    | 'MOD'
    | 'MODE'
    | 'MODIFIES'
    | 'MODIFY'
    | 'MONTH'
    | 'MULTILINESTRING'
    | 'MULTIPOINT'
    | 'MULTIPOLYGON'
    | 'MUTEX'
    | 'mysql_admin'
    | 'MYSQL_ERRNO'
    | 'mysql_main'
    | 'NAME'
    | 'NAMES'
    | 'NATIONAL'
    | 'NATURAL'
    | 'NCHAR'
    | 'NESTED'
    | 'NETWORK_NAMESPACE'
    | 'NEVER'
    | 'NEXT'
    | 'NO'
    | 'NO_WAIT'
    | 'NO_WRITE_TO_BINLOG'
    | 'NODEGROUP'
    | 'NONE'
    | 'NOT'
    | 'NOW'
    | 'NOWAIT'
    | 'NTH_VALUE'
    | 'NTILE'
    | 'NULL'
    | 'NULLS'
    | 'NUMBER'
    | 'NUMERIC'
    | 'NVARCHAR'
    | 'OF'
    | 'OFF'
    | 'OFFLINE'
    | 'OFFSET'
    | 'OJ'
    | 'OLD'
    | 'ON'
    | 'ONE'
    | 'ONLINE'
    | 'ONLY'
    | 'OPEN'
    | 'OPTIMIZE'
    | 'OPTIMIZER_COSTS'
    | 'OPTION'
    | 'OPTIONAL'
    | 'OPTIONALLY'
    | 'OPTIONS'
    | 'OR'
    | 'ORDER'
    | 'ORDINALITY'
    | 'ORGANIZATION'
    | 'OTHERS'
    | 'OUT'
    | 'OUTER'
    | 'OUTFILE'
    | 'OVER'
    | 'OWNER'
    | 'PACK_KEYS'
    | 'PAGE'
    | 'PARALLEL'
    | 'PARSE_TREE'
    | 'PARSER'
    | 'PARTIAL'
    | 'PARTITION'
    | 'PARTITIONING'
    | 'PARTITIONS'
    | 'PASSWORD'
    | 'PASSWORD_LOCK_TIME'
    | 'PATH'
    | 'PERCENT_RANK'
    | 'PERSIST'
    | 'PERSIST_ONLY'
    | 'PHASE'
    | 'PLUGIN'
    | 'PLUGIN_DIR'
    | 'PLUGINS'
    | 'POINT'
    | 'POLYGON'
    | 'PORT'
    | 'POSITION'
    | 'PRECEDES'
    | 'PRECEDING'
    | 'PRECISION'
    | 'PREPARE'
    | 'PRESERVE'
    | 'PREV'
    | 'PRIMARY'
    | 'PRIVILEGE_CHECKS_USER'
    | 'PRIVILEGES'
    | 'PROCEDURE'
    | 'PROCESS'
    | 'PROCESSLIST'
    | 'PROFILE'
    | 'PROFILES'
    | 'PROXY'
    | 'PURGE'
    | 'QUALIFY'
    | 'QUARTER'
    | 'QUERY'
    | 'QUICK'
    | 'RANDOM'
    | 'RANGE'
    | 'RANK'
    | 'READ'
    | 'READS'
    | 'REAL'
    | 'REBUILD'
    | 'RECOVER'
    | 'RECURSIVE'
    | 'REDO_BUFFER_SIZE'
    | 'REDO_LOG'
    | 'REDUNDANT'
    | 'REFERENCE'
    | 'REFERENCES'
    | 'REGEXP'
    | 'REGISTRATION'
    | 'RELAY'
    | 'RELAY_LOG_FILE'
    | 'RELAY_LOG_POS'
    | 'RELAY_THREAD'
    | 'RELAYLOG'
    | 'RELEASE'
    | 'RELOAD'
    | 'REMOTE'
    | 'REMOVE'
    | 'RENAME'
    | 'REORGANIZE'
    | 'REPAIR'
    | 'REPEAT'
    | 'REPEATABLE'
    | 'REPLACE'
    | 'REPLICA'
    | 'REPLICAS'
    | 'REPLICATE_DO_DB'
    | 'REPLICATE_DO_TABLE'
    | 'REPLICATE_IGNORE_DB'
    | 'REPLICATE_IGNORE_TABLE'
    | 'REPLICATE_REWRITE_DB'
    | 'REPLICATE_WILD_DO_TABLE'
    | 'REPLICATE_WILD_IGNORE_TABLE'
    | 'REPLICATION'
    | 'REQUIRE'
    | 'REQUIRE_ROW_FORMAT'
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK'
    | 'RESET'
    | 'RESIGNAL'
    | 'RESOURCE'
    | 'RESPECT'
    | 'RESTART'
    | 'RESTRICT'
    | 'RESUME'
    | 'RETAIN'
    | 'RETURN'
    | 'RETURNED_SQLSTATE'
    | 'RETURNING'
    | 'RETURNS'
    | 'REUSE'
    | 'REVERSE'
    | 'REVOKE'
    | 'RIGHT'
    | 'RLIKE'
    | 'ROLE'
    | 'ROLLBACK'
    | 'ROLLUP'
    | 'ROTATE'
    | 'ROUTINE'
    | 'ROW'
    | 'ROW_COUNT'
    | 'ROW_FORMAT'
    | 'ROW_NUMBER'
    | 'ROWS'
    | 'RTREE'
    | 'S3'
    | 'SAVEPOINT'
    | 'SCHEDULE'
    | 'SCHEMA'
    | 'SCHEMA_NAME'
    | 'SECOND'
    | 'SECOND_MICROSECOND'
    | 'SECONDARY'
    | 'SECONDARY_ENGINE'
    | 'SECONDARY_ENGINE_ATTRIBUTE'
    | 'SECONDARY_LOAD'
    | 'SECONDARY_UNLOAD'
    | 'SECURITY'
    | 'SELECT'
    | 'SEPARATOR'
    | 'SERIAL'
    | 'SERIALIZABLE'
    | 'SERVER'
    | 'SESSION'
    | 'SET'
    | 'SHARE'
    | 'SHOW'
    | 'SHUTDOWN'
    | 'SIGNAL'
    | 'SIGNED'
    | 'SIMPLE'
    | 'SKIP'
    | 'SLOW'
    | 'SMALLINT'
    | 'SNAPSHOT'
    | 'SOCKET'
    | 'SOME'
    | 'SONAME'
    | 'SOUNDS'
    | 'SOURCE'
    | 'SOURCE_AUTO_POSITION'
    | 'SOURCE_BIND'
    | 'SOURCE_COMPRESSION_ALGORITHM'
    | 'SOURCE_CONNECT_RETRY'
    | 'SOURCE_CONNECTION_AUTO_FAILOVER'
    | 'SOURCE_DELAY'
    | 'SOURCE_HEARTBEAT_PERIOD'
    | 'SOURCE_HOST'
    | 'SOURCE_LOG_FILE'
    | 'SOURCE_LOG_POS'
    | 'SOURCE_PASSWORD'
    | 'SOURCE_PORT'
    | 'SOURCE_PUBLIC_KEY_PATH'
    | 'SOURCE_RETRY_COUNT'
    | 'SOURCE_SSL'
    | 'SOURCE_SSL_CA'
    | 'SOURCE_SSL_CAPATH'
    | 'SOURCE_SSL_CERT'
    | 'SOURCE_SSL_CIPHER'
    | 'SOURCE_SSL_CRL'
    | 'SOURCE_SSL_CRLPATH'
    | 'SOURCE_SSL_KEY'
    | 'SOURCE_SSL_VERIFY_SERVER_CERT'
    | 'SOURCE_TLS_CIPHERSUITES'
    | 'SOURCE_TLS_VERSION'
    | 'SOURCE_USER'
    | 'SOURCE_ZSTD_COMPRESSION_LEVEL'
    | 'SPATIAL'
    | 'SQL'
    | 'SQL_AFTER_GTIDS'
    | 'SQL_AFTER_MTS_GAPS'
    | 'SQL_BEFORE_GTIDS'
    | 'SQL_BIG_RESULT'
    | 'SQL_BUFFER_RESULT'
    | 'SQL_CALC_FOUND_ROWS'
    | 'SQL_NO_CACHE'
    | 'SQL_SMALL_RESULT'
    | 'SQL_THREAD'
    | 'SQLEXCEPTION'
    | 'SQLSTATE'
    | 'SQLWARNING'
    | 'SRID'
    | 'SSL'
    | 'ST_COLLECT'
    | 'STACKED'
    | 'START'
    | 'STARTING'
    | 'STARTS'
    | 'STATS_AUTO_RECALC'
    | 'STATS_PERSISTENT'
    | 'STATS_SAMPLE_PAGES'
    | 'STATUS'
    | 'STD'
    | 'STDDEV_SAMP'
    | 'STOP'
    | 'STORAGE'
    | 'STORED'
    | 'STRAIGHT_JOIN'
    | 'STREAM'
    | 'STRING'
    | 'SUBCLASS_ORIGIN'
    | 'SUBDATE'
    | 'SUBJECT'
    | 'SUBPARTITION'
    | 'SUBPARTITIONS'
    | 'SUBSTRING'
    | 'SUM'
    | 'SUPER'
    | 'SUSPEND'
    | 'SWAPS'
    | 'SWITCHES'
    | 'SYSDATE'
    | 'SYSTEM'
    | 'TABLE'
    | 'TABLE_CHECKSUM'
    | 'TABLE_NAME'
    | 'TABLE_TYPE'
    | 'TABLES'
    | 'TABLESAMPLE'
    | 'TABLESPACE'
    | 'TEMPORARY'
    | 'TEMPTABLE'
    | 'TERMINATED'
    | 'TEXT'
    | 'THAN'
    | 'THEN'
    | 'THREAD_PRIORITY'
    | 'TIES'
    | 'TIME'
    | 'TIMESTAMP'
    | 'TIMESTAMPADD'
    | 'TIMESTAMPDIFF'
    | 'TINYBLOB'
    | 'TINYINT'
    | 'TINYTEXT'
    | 'TLS'
    | 'TO'
    | 'TRADITIONAL'
    | 'TRAILING'
    | 'TRANSACTION'
    | 'TRANSACTIONAL'
    | 'TREE'
    | 'TRIGGER'
    | 'TRIGGERS'
    | 'TRIM'
    | 'TRUE'
    | 'TRUNCATE'
    | 'TYPE'
    | 'UNBOUNDED'
    | 'UNCOMMITTED'
    | 'UNDEFINED'
    | 'UNDO'
    | 'UNDO_BUFFER_SIZE'
    | 'UNDOFILE'
    | 'UNICODE'
    | 'UNINSTALL'
    | 'UNION'
    | 'UNIQUE'
    | 'UNKNOWN'
    | 'UNLOCK'
    | 'UNREGISTER'
    | 'UNSIGNED'
    | 'UNTIL'
    | 'UPDATE'
    | 'UPGRADE'
    | 'URL'
    | 'USAGE'
    | 'USE'
    | 'USE_FRM'
    | 'USER'
    | 'USER_RESOURCES'
    | 'USING'
    | 'UTC_DATE'
    | 'UTC_TIME'
    | 'UTC_TIMESTAMP'
    | 'VALIDATION'
    | 'VALUE'
    | 'VALUES'
    | 'VAR_SAMP'
    | 'VARBINARY'
    | 'VARCHAR'
    | 'VARIABLES'
    | 'VARIANCE'
    | 'VARYING'
    | 'VCPU'
    | 'VECTOR'
    | 'VIEW'
    | 'VIRTUAL'
    | 'VISIBLE'
    | 'WAIT'
    | 'WARNINGS'
    | 'WEEK'
    | 'WEIGHT_STRING'
    | 'WHEN'
    | 'WHERE'
    | 'WHILE'
    | 'WINDOW'
    | 'WITH'
    | 'WITHOUT'
    | 'WORK'
    | 'WRAPPER'
    | 'WRITE'
    | 'X509'
    | 'XA'
    | 'XID'
    | 'XML'
    | 'XOR'
    | 'YEAR'
    | 'YEAR_MONTH'
    | 'ZEROFILL'
    | 'ZONE'
    ;

PARAM
    : '?' ;

HEXADECIMAL
    : '0x' BASE16 ;

DECIMAL
    : BASE10 ;

BINARY
    : '0b' BASE2+ ;

FLOAT
    : ( BASE10 ( '.' BASE10? )? | '.' BASE10 ) ( 'E' [-+]? BASE10 )? ;

SIZE
    : BASE10 [KMGT] ;

QUOTED
    : '"' ( '\\'? .)*? '"' ;

LOCAL
    : '@' ( ID | STRING | QUOTED | IPV4 | IPV6 ) ;

GLOBAL
    : '@' '@' ( ID ( '.' ID )? )? ;


STRING
    : '$$' .*? '$$'
    | ( '\'' ( '\\'? . )*? '\'' )+
    ;

NATIONAL
    : 'N' STRING ;

// TODO match against supported list, otherwise is an ID. then remove from rule name
CHARSET
    : '_' [A-Z0-9]+ ;

ID
    : '`' ( ~'`' | '``' )* '`'
    | [A-Z0-9_$\u0080-\uFFFF]+
    ;

BLOB
    : 'x\'' BASE16? '\''
    | 'b\'' BASE2? '\''
    ;

// MySQL synonym for NULL
NOPE options { caseInsensitive = false; }
    : '\\N' ;

MYSQL_COMMENT
    : '/*!' ( BLOCK_COMMENT | . )*?  '*/' -> channel( HIDDEN );

BLOCK_COMMENT
    : '/*' ~[!] .*? '*/' -> channel( HIDDEN );

// Another MySQL-ism...?
POUND_COMMENT
    : '#' ~[\n\r]* -> channel( HIDDEN ) ;

COMMENT
    // MySQL requires whitespace before comment
    : '--' ( [ \t] ~[\n\r]* | [\n\r] | EOF ) -> channel( HIDDEN )
    // Playing around with variations, to see which I prefer.
//    : '--' ( [ \t] .*? )? ( [\n\r] | EOF ) -> channel( HIDDEN )
    ;

WHITESPACE
    : [ \t\f\r\n]+ -> channel( HIDDEN ) ;

fragment IPV4 
    : BASE10 '.' BASE10 '.' BASE10 '.' BASE10;

fragment IPV6 
    : ( GROUPS? '::' )? GROUPS ;

fragment GROUPS 
    : BASE16 ( ':' BASE16 )* ;

fragment BASE2 
    : [01]+ ;

fragment BASE10 
    : [0-9]+ ;

fragment BASE16 
    : [0-9A-F]+ ;
