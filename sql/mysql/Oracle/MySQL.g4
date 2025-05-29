grammar MySQL;

/*
  Copyright 2025 Jason Osgood

  Refactoring MySQL.g4 to adopt NormalSQL's rules, idioms, and style. Goal is
  for grammars of misc dialects to all emit the same parse tree (given the
  same input). A work in progress, as grammars converge over time.

  Learning MySQL as I go. Since both 8.0.? and 9.? have LTS, I suppose those
  are the versions/dialects to support. Meaning I'll postpone culling of all the
  'master' and 'slave' stuff for a while. Hmmm.

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

options {
    caseInsensitive = true;
}

statements
    : statement? ( ';' statement? )* EOF ;

// TODO: inlining all the statements for now. will re-refactor as needed.
// TODO: update: matching order from sql_yacc.yy, because I'm getting cross-eyed

statement
    : 'CREATE' ( 'DATABASE' | 'SCHEMA' ) notExists? name databaseOption*
    | 'ALTER' ( 'DATABASE' | 'SCHEMA' ) qname databaseOption+
    | 'DROP' ( 'DATABASE' | 'SCHEMA' ) exists? qname

    | 'CREATE' definer? 'EVENT' notExists? qname 'ON' 'SCHEDULE' schedule ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ('ENABLE' | 'DISABLE' ('ON' replica)?)? ( 'COMMENT' string )? 'DO' compoundStatement
    | 'ALTER' definer? 'EVENT' qname ('ON' 'SCHEDULE' schedule)? ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ('RENAME' 'TO' qname)? ( 'ENABLE' | 'DISABLE' ('ON' replica)? )? ('COMMENT' string)? ('DO' compoundStatement)?
    | 'DROP' 'EVENT' exists? qname

    | 'CREATE' definer? 'FUNCTION' notExists? qname '(' ( functionParameter (',' functionParameter)* )? ')' 'RETURNS' dataType collate? routineCreateOption* storedRoutineBody
    | 'CREATE' 'AGGREGATE'? 'FUNCTION' notExists? qname 'RETURNS' ( 'STRING' | 'INT' | 'INTEGER' | 'REAL' | 'DECIMAL' ) 'SONAME' string
    | 'ALTER' 'FUNCTION' qname routineCreateOption*
    | 'DROP' 'FUNCTION' exists? qname
    | 'CREATE' definer? 'PROCEDURE' notExists? qname '(' ( procedureParameter (',' procedureParameter)* )? ')' routineCreateOption* storedRoutineBody
    | 'ALTER' 'PROCEDURE' qname routineCreateOption*
    | 'DROP' 'PROCEDURE' exists? qname

    | 'CREATE' ( 'UNIQUE' | 'FULLTEXT' | 'SPATIAL')? 'INDEX' qname ('USING' ('BTREE' | 'HASH'))? 'ON' qname '(' keyPart (',' keyPart)* ')' createIndexOption*
    | 'DROP' onlineOption? 'INDEX' qname 'ON' qname ('ALGORITHM' '='? qname | 'LOCK' '='? qname)*

    | 'ALTER' 'LOGFILE' 'GROUP' qname 'ADD' 'UNDOFILE' string alterLogfileGroupOptions?
    | 'CREATE' 'LOGFILE' 'GROUP' qname 'ADD' 'UNDOFILE' string (logfileGroupOption (','? logfileGroupOption)*)?
    | 'DROP' 'LOGFILE' 'GROUP' qname ( dropLogfileGroupOption (','? dropLogfileGroupOption)* )?

    | 'CREATE' 'RESOURCE' 'GROUP' qname 'TYPE' equal? ( 'USER' | 'SYSTEM' ) resourceGroupVcpuList? resourceGroupPriority? resourceGroupEnableDisable?
    | 'ALTER' 'RESOURCE' 'GROUP' qname resourceGroupVcpuList? resourceGroupPriority? resourceGroupEnableDisable? 'FORCE'?
    | 'SET' 'RESOURCE' 'GROUP' qname ('FOR' DECIMAL (','? DECIMAL)*)?
    | 'DROP' 'RESOURCE' 'GROUP' qname 'FORCE'?

    | 'CREATE' 'ROLE' notExists? roleList
    | 'DROP' 'ROLE' exists? roleList

    | 'CREATE' 'SERVER' qname 'FOREIGN' 'DATA' 'WRAPPER' qname 'OPTIONS' '(' serverOption (',' serverOption)* ')'
    | 'ALTER' 'SERVER' qname 'OPTIONS' '(' serverOption ( ',' serverOption )* ')'
    | 'DROP' 'SERVER' exists? name


    | 'CREATE' 'TEMPORARY'? 'TABLE' notExists? qname
       ('(' (name columnDef  | tableConstraintDef) (',' (name columnDef  | tableConstraintDef))* ')')?
       ( tableOption (','? tableOption)* )? partitionBy? (('REPLACE' | 'IGNORE')? 'AS'? select)?
    | 'CREATE' 'TEMPORARY'? 'TABLE' notExists? qname ( 'LIKE' qname | '(' 'LIKE' qname ')' )
    | 'ALTER' onlineOption? 'TABLE' qname ( alterTableAction ( ','? alterTableAction )* )?
    | 'RENAME' ('TABLE' | 'TABLES') renamePair ( ',' renamePair )*
    | 'DROP' 'TEMPORARY'? ('TABLE' | 'TABLES') exists? qname (',' qname)* ( 'RESTRICT' | 'CASCADE' )?

    | 'CREATE' 'UNDO'? 'TABLESPACE' qname tablespaceOptions?
    | 'ALTER' 'UNDO'? 'TABLESPACE' qname tablespaceOptions
    | 'DROP' 'UNDO'? 'TABLESPACE' qname tablespaceOptions?

    | 'CREATE' definer? 'TRIGGER' notExists? qname ( 'BEFORE' | 'AFTER' ) ('INSERT' | 'UPDATE' | 'DELETE') 'ON' qname 'FOR' 'EACH' 'ROW' (('FOLLOWS' | 'PRECEDES') qname)? compoundStatement
    | 'DROP' 'TRIGGER' exists? qname

    | 'CREATE' 'USER' notExists? createUser (',' createUser)*
      ('DEFAULT' 'ROLE' roleList)? require?
      resourceWith?
      ( passwordOption2 | lockOption2 )*
      ('COMMENT' string | 'ATTRIBUTE' string )*

    | 'ALTER' 'USER' exists? ( 'USER' '(' ')' | user ) ( DECIMAL 'FACTOR' )?

    | 'ALTER' 'USER' exists? 'USER' '(' ')'
        ( 'IDENTIFIED' 'BY' string ( 'REPLACE' string )? retainCurrentPassword?
        | 'DISCARD' 'OLD' 'PASSWORD'
        )

    | 'ALTER' 'USER' exists? user alterAuthOption? ( ',' user alterAuthOption? )*
          require?
          resourceWith?
          ( passwordOption2 | lockOption2 )*
          ('COMMENT' string | 'ATTRIBUTE' string )*

    | 'ALTER' 'USER' exists? user 'DEFAULT' 'ROLE' ('ALL' | 'NONE' | roleList )

    | 'DROP' 'USER' exists? user ( ',' user )*
    | 'RENAME' 'USER' user 'TO' user ( ',' user 'TO' user )*

    | 'CREATE' ('OR' 'REPLACE' viewAlgorithm? | viewAlgorithm)? definer? security? 'VIEW' qname columns? 'AS' select viewCheckOption?
    | 'ALTER' viewAlgorithm? definer? security? 'VIEW' qname columns? 'AS' select viewCheckOption?
    | 'DROP' 'VIEW' exists? qname (',' qname)* ('RESTRICT' | 'CASCADE')?

    | 'ALTER' 'INSTANCE'
        ( ( 'ENABLE' | 'DISABLE' ) 'INNODB' 'REDO_LOG'
        | 'ROTATE' ( 'INNODB' | 'BINLOG') 'MASTER' 'KEY'
        | 'RELOAD' 'TLS'
            ( 'FOR' 'CHANNEL' ( 'mysql_main' | 'mysql_admin' ) )?
            ( 'NO' 'ROLLBACK' 'ON' 'ERROR' )?
        | 'RELOAD' 'KEYRING'
        )

    | 'CREATE' orReplace? 'SPATIAL' 'REFERENCE' 'SYSTEM' notExists? DECIMAL srsAttribute*
    | 'DROP' 'SPATIAL' 'REFERENCE' 'SYSTEM' exists? DECIMAL


    | 'CALL' qname ('(' (term (',' term)*)? ')')?
    | delete
    | 'DO' item (',' item)*
    | 'HANDLER' qname 'OPEN' tableAlias?
    | 'HANDLER' qname ( 'CLOSE' | 'READ' handlerReadOrScan where? limit? )
    | insert
    | loadData
    | loadXML
    | replace
    | select
    | updateStatement
    | 'COMMIT' 'WORK'? ('AND' 'NO'? 'CHAIN')? ( 'NO'? 'RELEASE' )?
    | 'SAVEPOINT' qname
    | 'ROLLBACK' 'WORK'? ( 'TO' 'SAVEPOINT'? name | ('AND' 'NO'? 'CHAIN')? ('NO'? 'RELEASE')? )
    | 'RELEASE' 'SAVEPOINT' qname
    | 'LOCK' ('TABLES' | 'TABLE') lockItem (',' lockItem)*
    | 'LOCK' 'INSTANCE' 'FOR' 'BACKUP'
    | 'UNLOCK' ( 'TABLES' | 'TABLE' | 'INSTANCE')

    | 'XA' ('START' | 'BEGIN') xid ('JOIN' | 'RESUME')?
    | 'XA' 'END' xid ('SUSPEND' ('FOR' 'MIGRATE')?)?
    | 'XA' 'PREPARE' xid
    | 'XA' 'COMMIT' xid ('ONE' 'PHASE')?
    | 'XA' 'ROLLBACK' xid
    | 'XA' 'RECOVER' ('CONVERT' 'XID')?

    | 'PURGE' ('BINARY' | 'MASTER') 'LOGS' ( 'TO' string | 'BEFORE' term )
    | 'CHANGE' ('MASTER' | 'REPLICATION' 'SOURCE') 'TO' sourceDefinitions channel?
    | 'RESET' resetOption (',' resetOption)*
    | 'RESET' 'PERSIST' ( exists? qname )?
    | 'CHANGE' 'REPLICATION' 'FILTER' filterDefinition ( ',' filterDefinition )* channel?
//    | 'LOAD' ('DATA' | 'TABLE' qname) 'FROM' 'MASTER'
    | ('START' groupReplicationStartOptions? | 'STOP') 'GROUP_REPLICATION'
    | 'PREPARE' qname 'FROM' qname
    | 'EXECUTE' qname ('USING' qname ( ',' qname )*)?
    | ('DEALLOCATE' | 'DROP') 'PREPARE' name

    | 'CLONE' 'LOCAL' 'DATA' 'DIRECTORY' equal? string
    | 'CLONE' 'REMOTE' ('FOR' 'REPLICATION')?
    | 'CLONE' 'INSTANCE' 'FROM' user ':' DECIMAL 'IDENTIFIED' 'BY' name (ssl | 'DATA' 'DIRECTORY' equal? string ssl?)?

    | grantStatement
    | revokeStatement
    | setRoleStatement
    | 'ANALYZE' noLogging? ( 'TABLE' | 'TABLES' ) qname (',' qname)* histogram?
    | 'CHECK' ( 'TABLE' | 'TABLES' ) qname (',' qname)* checkOption*
    | 'CHECKSUM' 'TABLE' qname (',' qname)* ( 'QUICK' | 'EXTENDED' )?
    | 'OPTIMIZE' noLogging? 'TABLE' qname (',' qname)*
    | 'REPAIR' noLogging? 'TABLE' qname (',' qname)* repairType*
    | 'UNINSTALL' ( 'PLUGIN' name | 'COMPONENT' string (',' string)* )
    | 'INSTALL' 'PLUGIN' name 'SONAME' string
    | 'INSTALL' 'COMPONENT' strings ('SET' setter ( ',' setter )*)?

//    | 'SET' optionValueNoOptionType (',' (scope 'DEFAULT'? qname equal term | optionValueNoOptionType))*
//    | 'SET' scope? qname equal term (',' scope? qname equal term )*
    | 'SET' setter (',' setter )*
    | 'SET' 'NAMES' ( equal term | qname collate? | 'DEFAULT' )
    | 'SET' ('GLOBAL' | 'SESSION')? 'TRANSACTION' transactionCharacteristics ( ',' transactionCharacteristics )*
//    | 'SET' scope? 'DEFAULT'? qname equal term (',' (scope 'DEFAULT'? qname equal term | optionValueNoOptionType))*
    | 'SET' 'PASSWORD' ('FOR' user)? ( equal string | 'TO' 'RANDOM' ) replace? retainCurrentPassword?
//            | 'PASSWORD' '(' string ')' )
//    | 'SET' 'PASSWORD' ('FOR' user)?  replace? retainCurrentPassword?
    | 'SET' charset3 qname

    | 'TRUNCATE' 'TABLE'? qname
    | 'IMPORT' 'TABLE' 'FROM' strings


    | 'SHOW' 'BINARY' 'LOG' 'STATUS'
//    | 'SHOW' ('BINARY' | 'MASTER') 'LOGS'
    | 'SHOW' 'BINARY' 'LOGS'
    | 'SHOW' 'BINLOG' 'EVENTS' ('IN' string)? ( 'FROM' DECIMAL )? limit?
    | 'SHOW' charset3 like?
    | 'SHOW' 'COLLATION' like?
//    | 'SHOW' ('FULL' | 'EXTENDED' 'FULL'?)? ('COLUMNS' | 'FIELDS' ) ('FROM' | 'IN') qname inDb? like?
    | 'SHOW' ('FULL' | 'EXTENDED' 'FULL'?)? ( 'COLUMNS' | 'FIELDS' ) inDb inDb? like?
    | 'SHOW' 'COUNT' '(' '*' ')' ( 'WARNINGS' | 'ERRORS' )

    | 'SHOW' 'CREATE' ( 'DATABASE' | 'SCHEMA' ) notExists? qname
    | 'SHOW' 'CREATE' 'EVENT' qname
    | 'SHOW' 'CREATE' 'FUNCTION' qname
    // ??
    | 'SHOW' 'CREATE' 'FUNCTION' 'CODE' qname
    | 'SHOW' 'CREATE' 'LIBRARY' qname
    | 'SHOW' 'CREATE' 'PROCEDURE' qname
    | 'SHOW' 'CREATE' 'PROCEDURE' 'CODE' qname
    | 'SHOW' 'CREATE' 'TABLE' qname
    | 'SHOW' 'CREATE' 'TRIGGER' qname
    | 'SHOW' 'CREATE' 'USER' user
    | 'SHOW' 'CREATE' 'VIEW' qname

    | 'SHOW' 'DATABASES' like?
    | 'SHOW' 'ENGINE' qname ('LOGS' | 'MUTEX' | 'STATUS')
    | 'SHOW' 'STORAGE'? 'ENGINES'
    | 'SHOW' 'ERRORS' limit?
    | 'SHOW' 'EVENTS' inDb? like?
    | 'SHOW' 'FUNCTION' 'CODE' qname
    | 'SHOW' 'FUNCTION' 'STATUS' like?
    | 'SHOW' 'GRANTS' ( 'FOR' user ( 'USING' user ( ',' user )* )? )?
    | 'SHOW' 'EXTENDED'? ( 'KEYS' | 'INDEX' | 'INDEXES' ) inDb inDb? where?
    | 'SHOW' 'LIBRARY' 'STATUS' like?
    | 'SHOW' 'OPEN' 'TABLES' inDb? like?
    | 'SHOW' 'PARSE_TREE' statement
    | 'SHOW' 'PLUGINS'
    | 'SHOW' 'PRIVILEGES'
    | 'SHOW' 'PROCEDURE' 'CODE' qname
    | 'SHOW' 'PROCEDURE' 'STATUS' like?
    | 'SHOW' 'FULL'? 'PROCESSLIST'
    | 'SHOW' 'PROFILE' (profileDef (',' profileDef)*)? ( 'FOR' 'QUERY' DECIMAL )? limit?
    | 'SHOW' 'PROFILES'
    | 'SHOW' 'RELAYLOG' 'EVENTS' ('IN' string)? ( 'FROM' DECIMAL )? limit? channel?
    | 'SHOW' 'REPLICA' 'STATUS' channel?
    | 'SHOW' 'REPLICAS'
    | 'SHOW' replica 'HOSTS'
    | 'SHOW' scope? 'STATUS' like?
    | 'SHOW' 'TABLE' 'STATUS' inDb? like?
    | 'SHOW' ('FULL' | 'EXTENDED' 'FULL'?)? 'TABLES' inDb? like?
    | 'SHOW' 'FULL'? 'TRIGGERS' inDb? like?
    | 'SHOW' scope? 'VARIABLES' like?
    | 'SHOW' 'WARNINGS' limit?


    | 'SHUTDOWN'
    | ( 'SIGNAL' signalCondition | 'RESIGNAL' signalCondition? ) ( 'SET' signalItem (',' signalItem)* )?
    | 'START' 'TRANSACTION' ('WITH' 'CONSISTENT' 'SNAPSHOT' | accessMode )*
    | 'START' replica replicaThreadOptions? ('UNTIL' replicaUntil)? userOption? passwordOption? defaultAuthOption? pluginDirOption? channel?
    | 'STOP' replica replicaThreadOptions? channel?

    | 'BINLOG' string
    | 'CACHE' 'INDEX' keyCacheListOrParts 'IN' qname
    | 'FLUSH' noLogging? ( flushTables | flushOption (',' flushOption)* )
    | 'KILL' ('CONNECTION' | 'QUERY')? term
    | 'LOAD' 'INDEX' 'INTO' 'CACHE' preloadTail

    | 'CREATE' 'LIBRARY' qname 'LANGUAGE' name ( 'COMMENT' string )? 'AS' string

    | ('EXPLAIN' | 'DESCRIBE' | 'DESC') qname ( string | qname )?
    | ('EXPLAIN' | 'DESCRIBE' | 'DESC') explainOption? ( 'FOR' ( 'DATABASE' | 'SCHEMA' ) name )? explainableStatement
    | 'HELP' name
    | 'USE' name
    | 'RESTART'
    | 'GET' ('CURRENT' | 'STACKED')? 'DIAGNOSTICS' ( statementInformationItem (',' statementInformationItem)* | 'CONDITION' literal conditionInformationItem ( ',' conditionInformationItem )* )
    | beginWork
    ;


signalCondition
    : name
    | 'SQLSTATE' 'VALUE'? string
    ;

alterLogfileGroupOptions
    : ('INITIAL_SIZE' '='? byteSize | 'STORAGE'? 'ENGINE' '='? name | ('WAIT' | 'NO_WAIT'))
(','? ('INITIAL_SIZE' '='? byteSize | 'STORAGE'? 'ENGINE' '='? name | ('WAIT' | 'NO_WAIT')))* ;

alterTableAction
    : 'ALGORITHM' '='? name
    | 'LOCK' '='? name
    | ('WITH' | 'WITHOUT') 'VALIDATION'

    | 'ADD' 'COLUMN'? name columnDef  place?
    | 'ADD' 'COLUMN'? '(' (name columnDef | tableConstraintDef) (',' (name columnDef | tableConstraintDef))* ')'
    | 'ADD' tableConstraintDef

    | 'CHANGE' 'COLUMN'? name name columnDef place?
    | 'MODIFY' 'COLUMN'? name columnDef place?
    | 'DROP' ( 'COLUMN'? name ('RESTRICT' | 'CASCADE')? | 'FOREIGN' 'KEY' name | 'PRIMARY' 'KEY' | indexKey qname | 'CHECK' name | 'CONSTRAINT' name )
    | 'DISABLE' 'KEYS'
    | 'ENABLE' 'KEYS'
    | 'ALTER' 'COLUMN'? name ( 'SET' 'DEFAULT' ( '(' term ')' | literal ) | 'DROP' 'DEFAULT' | 'SET' visibility )
    | 'ALTER' 'INDEX' qname visibility
    | 'ALTER' 'CHECK' name constraintEnforcement
    | 'ALTER' 'CONSTRAINT' name constraintEnforcement
    | 'RENAME' 'COLUMN' name 'TO' name
    | 'RENAME' ('TO' | 'AS')? qname
    | 'RENAME' indexKey qname 'TO' name
    | 'CONVERT' 'TO' charset collate?
    | 'FORCE'
//    | 'ORDER' 'BY' name direction? (',' name direction?)*
    | orderBy
    | tableOption
    | partitionBy
    | removePartitioning
    | 'DISCARD' 'TABLESPACE' | 'IMPORT' 'TABLESPACE'
    | 'ADD' 'PARTITION' noLogging? ( '(' partitionDef (',' partitionDef)* ')' | 'PARTITIONS' DECIMAL )
    | 'DROP' 'PARTITION' name (',' name)*
    | 'REBUILD' 'PARTITION' noLogging? allOrPartitionNameList
    | 'OPTIMIZE' 'PARTITION' noLogging? allOrPartitionNameList noLogging?
    | 'ANALYZE' 'PARTITION' noLogging? allOrPartitionNameList
    | 'CHECK' 'PARTITION' allOrPartitionNameList checkOption*
    | 'REPAIR' 'PARTITION' noLogging? allOrPartitionNameList repairType*
    | 'COALESCE' 'PARTITION' noLogging? DECIMAL
    | 'TRUNCATE' 'PARTITION' allOrPartitionNameList
    | 'REORGANIZE' 'PARTITION' noLogging? ( name (',' name)* 'INTO' '(' partitionDef (',' partitionDef)* ')' )?
    | 'EXCHANGE' 'PARTITION' name 'WITH' 'TABLE' qname (('WITH' | 'WITHOUT') 'VALIDATION')?
    | 'DISCARD' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    | 'IMPORT' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    | 'SECONDARY_LOAD'
    | 'SECONDARY_UNLOAD'
    ;

dropLogfileGroupOption
    : ('WAIT' | 'NO_WAIT')
    | 'STORAGE'? 'ENGINE' '='? name
    ;


place
    : 'AFTER' name
    | 'FIRST'
    ;

removePartitioning
    : 'REMOVE' 'PARTITIONING'
    ;

allOrPartitionNameList
    : 'ALL'
    | name (',' name)*
    ;

viewCheckOption
    : 'WITH' ('CASCADED' | 'LOCAL')? 'CHECK' 'OPTION'
    ;

databaseOption
    : 'DEFAULT'? charset3 '='? name
    | 'DEFAULT'? 'COLLATE' '='? name
    | 'DEFAULT'? 'ENCRYPTION' '='? string
    | 'READ' 'ONLY' '='? ternaryOption
    ;

storedRoutineBody
    : compoundStatement
    | 'AS' string
    ;

routineCreateOption
    : 'COMMENT' string
    | 'LANGUAGE' name
    | 'NOT'? 'DETERMINISTIC'
    | 'CONTAINS' 'SQL'
    | 'NO' 'SQL'
    | 'READS' 'SQL' 'DATA'
    | 'MODIFIES' 'SQL' 'DATA'
    | security
    | 'USING' '(' name ( ',' name )*')'
    ;

createIndexOption
    : 'KEY_BLOCK_SIZE' '='? DECIMAL
    | ('USING' ('BTREE' | 'HASH'))
    | 'WITH' 'PARSER' name
    | 'COMMENT' string
    | visibility
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | 'ALGORITHM' '='? name
    | 'LOCK' '='? name
    ;


indexOption
    : 'KEY_BLOCK_SIZE' '='? DECIMAL
    | 'COMMENT' string
    | visibility
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | ('USING' | 'TYPE') indexType
    | 'WITH' 'PARSER' name
    ;

// TODO verify how this is used. there's overlap with
indexNameAndType
    : name ( 'TYPE' indexType )?
    | name? 'USING' indexType
    ;

logfileGroupOption
    : 'INITIAL_SIZE' '='? byteSize
    | ('UNDO_BUFFER_SIZE' | 'REDO_BUFFER_SIZE') '='? byteSize
    | 'NODEGROUP' '='? DECIMAL
    | 'STORAGE'? 'ENGINE' '='? name
    | ('WAIT' | 'NO_WAIT')
    | 'COMMENT' '='? string
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

tablespaceOptions
    : tablespaceOption ( ','? tablespaceOption )*
    ;

tablespaceOption
    : ('ADD' | 'DROP') 'DATAFILE' string
    | 'USE' 'LOGFILE' 'GROUP' name
    | 'EXTENT_SIZE' '='? byteSize
    | 'INITIAL_SIZE' '='? byteSize
    | 'FILE_BLOCK_SIZE' '='? byteSize
    | 'MAX_SIZE' '='? byteSize
    | 'WAIT'
    | 'RENAME' 'TO' name
    | 'AUTOEXTEND_SIZE' '='? DECIMAL
    | 'SET' ('ACTIVE' | 'INACTIVE')
    | 'ENCRYPTION' '='? string
    | 'ENGINE' '='? name
    | 'NODEGROUP' '='? DECIMAL
    | 'COMMENT' '='? string
    ;

viewAlgorithm
    : 'ALGORITHM' '=' ( 'UNDEFINED' | 'MERGE' | 'TEMPTABLE' )
    ;

security
    : 'SQL' 'SECURITY' ('DEFINER' | 'INVOKER')
    ;

orReplace : 'OR' 'REPLACE' ;

srsAttribute
    : 'NAME' 'TEXT' string
    | 'DEFINITION' 'TEXT' string
    | 'ORGANIZATION' string 'IDENTIFIED' 'BY' DECIMAL
    | 'DESCRIPTION' 'TEXT' string
    ;

renamePair
    : qname 'TO' qname
    ;

delete
    : with? 'DELETE' 'LOW_PRIORITY'? 'QUICK'? 'IGNORE'?
        ( 'FROM' qname tableAlias? ('PARTITION' '(' name (',' name)* ')')? where? orderBy? limitCount?
        | wild ( ',' wild )* 'FROM' tableReferenceList where?
        | 'FROM' wild ( ',' wild )* 'USING' tableReferenceList where?
        )
    ;


    wild : qname ( '.' '*' )? ;

handlerReadOrScan
    : ('FIRST' | 'NEXT')
    | name
        ( ('FIRST' | 'NEXT' | 'PREV' | 'LAST')
        | ( '=' | '<' | '>' | '<=' | '>=' ) terms
        )
    ;

replace
    : 'REPLACE' ('LOW_PRIORITY' | 'DELAYED')?
       'INTO'? qname partition?
       ( insertFromConstructor | 'SET' setter (',' setter)* | insertQueryExpression )?
    ;


insert
    : 'INSERT' ('LOW_PRIORITY' | 'DELAYED' | 'HIGH_PRIORITY')?
      'IGNORE'?
      'INTO'? qname partition?
      ( insertFromConstructor valuesReference? | 'SET' setter (',' setter)* valuesReference? | insertQueryExpression )
      ('ON' 'DUPLICATE' 'KEY' 'UPDATE' setter (',' setter)*)?
    ;

insertFromConstructor
    : ('(' (wild (',' wild)*)? ')')? ('VALUES' | 'VALUE') terms0 ( ',' terms0 )*
    ;

insertQueryExpression
    : with? selectCore orderBy? limit?
    | '(' select ')'
    | ('(' (wild (',' wild)*)? ')')? select
    ;

terms
    : '(' term  (',' term )* ')'
    ;

terms0
    : '(' ( term  (',' term )* )? ')'
    ;

valuesReference
    : 'AS' name columns?
    ;

//loadDataOld
//    : 'LOAD' 'DATA' ('LOW_PRIORITY' | 'CONCURRENT')?
//      'FROM'? 'LOCAL'? ('INFILE' | ('URL' | 'S3'))? string ('COUNT' DECIMAL | ID DECIMAL)?
//      ('IN' 'PRIMARY' 'KEY' 'ORDER')?
//      ( 'REPLACE' | 'IGNORE' )?
//      'INTO' 'TABLE' qname partition? charset? ('ROWS' 'IDENTIFIED' 'BY' string)?
//      fields? lines?
//      ('IGNORE' DECIMAL ('LINES' | 'ROWS'))?
//      ('(' (name ( ',' name )*)? ')')?
//      ( 'SET' setter (',' setter)* )?
//      ('PARALLEL' '=' DECIMAL)? ('MEMORY' '=' byteSize)? ('ALGORITHM' '=' 'BULK')?
//    ;

loadData
    : 'LOAD' 'DATA' ('LOW_PRIORITY' | 'CONCURRENT')?
      'LOCAL'? ('INFILE' | ('URL' | 'S3')) string
      ( 'REPLACE' | 'IGNORE' )?
      'INTO' 'TABLE' qname
      partition?
      charset?
//      ('ROWS' 'IDENTIFIED' 'BY' string)?
      fields?
      lines?
      ( 'IGNORE' DECIMAL ( 'LINES' | 'ROWS' ))?
      ( '(' ( qname ( ',' qname )* )? ')' )?
      ( 'SET' setter (',' setter)* )?
//      ('PARALLEL' '=' INTEGER)? ('MEMORY' '=' byteSize)? ('ALGORITHM' '=' 'BULK')?
    ;


//loadXMLOld
//    : 'LOAD' 'XML' ('LOW_PRIORITY' | 'CONCURRENT')?
//      'FROM'? 'LOCAL'? ('INFILE' | ('URL' | 'S3'))? string ('COUNT' DECIMAL | ID DECIMAL)?
//      ('IN' 'PRIMARY' 'KEY' 'ORDER')?
//      ( 'REPLACE' | 'IGNORE' )?
//      'INTO' 'TABLE' qname partition? charset? ('ROWS' 'IDENTIFIED' 'BY' string)?
//      fields? lines?
//      ('IGNORE' DECIMAL ('LINES' | 'ROWS'))?
//      ('(' (name ( ',' name )*)? ')')?
//      ( 'SET' setter (',' setter)* )?
//      ('PARALLEL' '=' DECIMAL)? ('MEMORY' '=' byteSize)? ('ALGORITHM' '=' 'BULK')?
//    ;

loadXML
    : 'LOAD' 'XML' ('LOW_PRIORITY' | 'CONCURRENT')? 'LOCAL'?
      ('INFILE' | ('URL' | 'S3'))? string
//      ('COUNT' INTEGER | ID INTEGER)?
//      ('IN' 'PRIMARY' 'KEY' 'ORDER')?
      ( 'REPLACE' | 'IGNORE' )?
      'INTO' 'TABLE' qname
//      partition?
      charset?
      ('ROWS' 'IDENTIFIED' 'BY' string)?
//      fields? lines?
      ('IGNORE' DECIMAL ('LINES' | 'ROWS'))?
      ('(' (qname ( ',' qname )*)? ')')?
      ( 'SET' setter (',' setter)* )?
//      ('PARALLEL' '=' INTEGER)? ('MEMORY' '=' byteSize)? ('ALGORITHM' '=' 'BULK')?
    ;


select
    : with? selectCore ( ( 'UNION' | 'EXCEPT' | 'INTERSECT' ) ('DISTINCT' | 'ALL')? selectCore )*
      orderBy? limit? into? locking* into?
    ;

selectCore
    : 'SELECT' modifier* item (',' item)* into?
       from? where? groupBy? having? window? qualify?
    | 'VALUES' 'ROW' terms0 (',' 'ROW' terms0 )*
    | 'TABLE' qname
    | '(' select ')'
    ;

modifier
    : 'ALL' | 'DISTINCT' | 'DISTINCTROW'
    | 'HIGH_PRIORITY'
    | 'STRAIGHT_JOIN'
    | 'SQL_SMALL_RESULT'
    | 'SQL_BIG_RESULT'
    | 'SQL_BUFFER_RESULT'
    | 'SQL_CALC_FOUND_ROWS'
    | 'SQL_NO_CACHE'
    ;

limit
    : 'LIMIT' literal ((',' | 'OFFSET') literal)? ;

limitCount
    : 'LIMIT' DECIMAL ;

into
    : 'INTO'
        ( 'OUTFILE' string charset? fields? lines?
        | 'DUMPFILE' string
        | name ( ',' name )*
        | LOCAL ( ',' LOCAL )*
        )
    ;

//procedureAnalyseClause
//    : 'PROCEDURE' '(' (INT_NUMBER (',' INT_NUMBER)?)? ')'
//    ;

having
    : 'HAVING' term ;

qualify
    : 'QUALIFY' term ;

window
    : 'WINDOW' windowDefinition (',' windowDefinition)*
    ;

windowDefinition
    : name 'AS' windowSpec ;

windowSpec
    : '(' name? ('PARTITION' 'BY' orderExpression (',' orderExpression)*)? orderBy?
      (('ROWS' | 'RANGE' | 'GROUPS') windowFrameExtent
      ('EXCLUDE' ( 'CURRENT' 'ROW' | 'GROUP' | 'TIES' | 'NO' 'OTHERS' ))?
      )?
      ')'
    ;

windowFrameExtent
    : windowFrameStart
    | windowFrameBetween
    ;

windowFrameStart
    : literal 'PRECEDING'
//    : 'UNBOUNDED' 'PRECEDING'
//    | INTEGER 'PRECEDING'
//    | PARAM 'PRECEDING'
//    | 'INTERVAL' term interval 'PRECEDING'
    | 'CURRENT' 'ROW'
    ;

windowFrameBound
    : windowFrameStart
    | literal 'FOLLOWING'
//    | 'UNBOUNDED' 'FOLLOWING'
//    | INTEGER 'FOLLOWING'
//    | PARAM 'FOLLOWING'
//    | 'INTERVAL' term interval 'FOLLOWING'
    ;

windowFrameBetween
    : 'BETWEEN' windowFrameBound 'AND' windowFrameBound
    ;


with
    : 'WITH' 'RECURSIVE'? cte ( ',' cte )*
    ;

cte
    : name columns? 'AS' '(' select ')'
    ;

groupBy
    : 'GROUP' 'BY' orderExpression (',' orderExpression)* ( 'WITH' 'ROLLUP' )?
    | 'GROUP' 'BY' ( 'ROLLUP' | 'CUBE' ) terms
    ;

orderBy
    : 'ORDER' 'BY' orderExpression (',' orderExpression)*
    ;

orderExpression
    : term direction?
    ;

direction
    : 'ASC' | 'DESC' ;

from
    : 'FROM' ( 'DUAL' | tables ) ;

tableReferenceList
    : tables (',' tables)* ;

tables
    : tables ',' tables
    | tables (('INNER' | 'CROSS')? 'JOIN' | 'STRAIGHT_JOIN') tables ( 'ON' term | 'USING' '(' name (',' name)* ')' )?
    | tables ('LEFT' | 'RIGHT') 'OUTER'? 'JOIN' tables ( 'ON' term | 'USING' '(' name (',' name)* ')' )
    | tables ('NATURAL' 'INNER'? 'JOIN' | 'NATURAL' ('LEFT' | 'RIGHT') 'OUTER'? 'JOIN' ) tables
    | qname partition? tableAlias? indexHint* ('TABLESAMPLE' ('SYSTEM' | 'BERNOULLI') '(' literal ')')?
    | 'JSON_TABLE' '(' term ',' string jsonColumns ')' tableAlias?
    | 'LATERAL'? '(' select ')' tableAlias? columns?
    | '{' 'OJ' tables '}'
    | '(' tables ')'
    ;

locking
    : 'FOR' ( 'UPDATE' | 'SHARE' ) ('OF' qname (',' qname)*)? ( 'SKIP' 'LOCKED' | 'NOWAIT' )?
    | 'LOCK' 'IN' 'SHARE' 'MODE'
    ;


item
    : '*'
    | term alias?
    | qname ( '.'  '*' )?
    ;

alias
    : 'AS'? name
    ;

where
    : 'WHERE' term
    ;

jsonColumns
    : 'COLUMNS' '(' jsonColumn (',' jsonColumn)* ')'
    ;

jsonColumn
    : name 'FOR' 'ORDINALITY'
    | name dataType collate? 'EXISTS'? 'PATH' string ( jsonResponse jsonResponse? )?
    | 'NESTED' 'PATH' string jsonColumns
    ;

jsonResponse
    : ('ERROR' | 'NULL' | 'DEFAULT' string) 'ON' ('EMPTY' | 'ERROR')
    ;

tableAlias
    : 'AS'? name ;

indexHint
    : 'USE' indexKey indexHintScope? '(' ( name ( ',' name )* )? ')'
    | ( 'IGNORE' | 'FORCE' ) indexKey indexHintScope? '(' ( name ( ',' name )* ) ')'
    ;

indexKey
    : 'INDEX' | 'KEY' ;

indexHintScope
    : 'FOR' ('JOIN' | 'ORDER' 'BY' | 'GROUP' 'BY')
    ;

updateStatement
    : with? 'UPDATE' 'LOW_PRIORITY'? 'IGNORE'? tableReferenceList
      'SET' setter (',' setter)*
      where?
      orderBy? limitCount?
    ;

beginWork
    : 'BEGIN' 'WORK'?
    ;

lockItem
    : qname tableAlias? lockOption
    ;

lockOption
    : 'READ' 'LOCAL'?
    |
//    'LOW_PRIORITY'?
    'WRITE'
    ;

xid
    : string (',' string (',' DECIMAL)?)?
    ;

resetOption
    : ('MASTER' | 'BINARY' 'LOGS' 'AND' 'GTIDS') ('TO' DECIMAL)?
    | replica 'ALL'? channel?
    ;

sourceDefinitions
    : sourceDefinition (',' sourceDefinition)*
    ;

sourceDefinition
    : ('MASTER_HOST' | 'SOURCE_HOST') '=' string
    | 'NETWORK_NAMESPACE' '=' string
    | ('MASTER_BIND' | 'SOURCE_BIND') '=' string
    | ('MASTER_USER' | 'SOURCE_USER') '=' string
    | ('MASTER_PASSWORD' | 'SOURCE_PASSWORD') '=' string
    | ('MASTER_PORT' | 'SOURCE_PORT') '=' DECIMAL
    | ('MASTER_CONNECT_RETRY' | 'SOURCE_CONNECT_RETRY') '=' DECIMAL
    | ('MASTER_RETRY_COUNT' | 'SOURCE_RETRY_COUNT') '=' DECIMAL
    | ('MASTER_DELAY' | 'SOURCE_DELAY') '=' DECIMAL
    | ('MASTER_SSL' | 'SOURCE_SSL') '=' DECIMAL
    | ('MASTER_SSL_CA' | 'SOURCE_SSL_CA') '=' string
    | ('MASTER_SSL_CAPATH' | 'SOURCE_SSL_CAPATH') '=' string
    | ('MASTER_TLS_VERSION' | 'SOURCE_TLS_VERSION') '=' string
    | ('MASTER_SSL_CERT' | 'SOURCE_SSL_CERT') '=' string
    | ('MASTER_TLS_CIPHERSUITES' | 'SOURCE_TLS_CIPHERSUITES') '=' name
    | ('MASTER_SSL_CIPHER' | 'SOURCE_SSL_CIPHER') '=' string
    | ('MASTER_SSL_KEY' | 'SOURCE_SSL_KEY') '=' string
    | ('MASTER_SSL_VERIFY_SERVER_CERT' | 'SOURCE_SSL_VERIFY_SERVER_CERT') '=' DECIMAL
    | ('MASTER_SSL_CRL' | 'SOURCE_SSL_CRL') '=' string
    | ('MASTER_SSL_CRLPATH' | 'SOURCE_SSL_CRLPATH') '=' string
    | ('MASTER_PUBLIC_KEY_PATH' | 'SOURCE_PUBLIC_KEY_PATH') '=' string
    | ('GET_MASTER_PUBLIC_KEY' | 'GET_SOURCE_PUBLIC_KEY') '=' DECIMAL
    | ('MASTER_HEARTBEAT_PERIOD' | 'SOURCE_HEARTBEAT_PERIOD') '=' literal
    | 'IGNORE_SERVER_IDS' '=' '(' (DECIMAL (',' DECIMAL)*)? ')'
    | ('MASTER_COMPRESSION_ALGORITHM' | 'SOURCE_COMPRESSION_ALGORITHM') '=' string
    | ('MASTER_ZSTD_COMPRESSION_LEVEL' | 'SOURCE_ZSTD_COMPRESSION_LEVEL') '=' DECIMAL
    | ('MASTER_AUTO_POSITION' | 'SOURCE_AUTO_POSITION') '=' DECIMAL
    | 'PRIVILEGE_CHECKS_USER' '=' userName
    | 'REQUIRE_ROW_FORMAT' '=' DECIMAL
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK' '=' ('STREAM' | 'ON' | 'OFF' | 'GENERATE')
    | 'SOURCE_CONNECTION_AUTO_FAILOVER' '=' DECIMAL
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS' '=' ('OFF' | 'LOCAL' | string)
    | 'GTID_ONLY' '=' DECIMAL
    | sourceFileDef
    ;

sourceFileDef
    : ('MASTER_LOG_FILE' | 'SOURCE_LOG_FILE') '=' string
    | ('MASTER_LOG_POS' | 'SOURCE_LOG_POS') '=' DECIMAL
    | 'RELAY_LOG_FILE' '=' string
    | 'RELAY_LOG_POS' '=' DECIMAL
    ;

filterDefinition
    : 'REPLICATE_DO_DB' '=' '(' (name (',' name)*)? ')'
    | 'REPLICATE_IGNORE_DB' '=' '(' (name (',' name)*)? ')'
    | 'REPLICATE_DO_TABLE' '=' '(' (qname (',' qname)*)? ')'
    | 'REPLICATE_IGNORE_TABLE' '=' '(' (qname (',' qname)*)? ')'
    | 'REPLICATE_WILD_DO_TABLE' '=' '(' (string (',' string)*)? ')'
    | 'REPLICATE_WILD_IGNORE_TABLE' '=' '(' (string (',' string)*)? ')'
    | 'REPLICATE_REWRITE_DB' '=' '(' (schemaIdentifierPair (',' schemaIdentifierPair)*)? ')'
    ;

replicaUntil
    : sourceFileDef
    | 'SQL_BEFORE_GTIDS' '=' string
    | 'SQL_AFTER_GTIDS' '=' string
    | 'SQL_AFTER_MTS_GAPS'
    ;

userOption
    : 'USER' '=' string
    ;

passwordOption
    : 'PASSWORD' '=' string
    ;

defaultAuthOption
    : 'DEFAULT_AUTH' '=' string
    ;

pluginDirOption
    : 'PLUGIN_DIR' '=' string
    ;

replicaThreadOptions
    : replicaThreadOption (',' replicaThreadOption)*
    ;

replicaThreadOption
    : 'SQL_THREAD'
    | 'RELAY_THREAD'
    ;

groupReplicationStartOptions
    : groupReplicationStartOption (',' groupReplicationStartOption)*
    ;

groupReplicationStartOption
    : 'USER' '=' string
    | 'PASSWORD' '=' string
    | 'DEFAULT_AUTH' '=' string
    ;

replica
    : 'SLAVE' | 'REPLICA' ;

ssl
    : 'REQUIRE' 'NO'? 'SSL' ;

//alterUser
//    : oldAlterUser
//    | user
//        ( 'IDENTIFIED' 'BY' string ( replace retainCurrentPassword? | retainCurrentPassword? )
//        | 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD' ( retainCurrentPassword? | replace retainCurrentPassword? )
//        | 'IDENTIFIED' 'WITH' name
//        | 'IDENTIFIED' 'WITH' name 'AS' string retainCurrentPassword?
//        | 'IDENTIFIED' 'WITH' name 'BY' string ( replace retainCurrentPassword? | retainCurrentPassword? )
//        | 'IDENTIFIED' 'WITH' name 'BY' 'RANDOM' 'PASSWORD' retainCurrentPassword?
//        | discardOldPassword?
//        | 'ADD' factor identified ('ADD' factor identified)?
//        | 'MODIFY' factor identified ( 'MODIFY' factor identified )?
//        | 'DROP' factor ('DROP' factor)?
//        )
//    ;

//oldAlterUser
//    : 'OOK' ;
//    : user 'IDENTIFIED' 'BY'
//        ( string replace retainCurrentPassword?
//        | string retainCurrentPassword?
//        | 'RANDOM' 'PASSWORD' replace? retainCurrentPassword?
//        )
//    | user 'IDENTIFIED' 'WITH' (
//        name (
//            'BY' string replace retainCurrentPassword?
//            | 'AS' string retainCurrentPassword?
//            | 'BY' string retainCurrentPassword?
//            | 'BY' 'RANDOM' 'PASSWORD' retainCurrentPassword?
//        )?
//    )
//    | user discardOldPassword?
//    ;

resourceWith
    : 'WITH'
      ( ( 'MAX_QUERIES_PER_HOUR'
        | 'MAX_UPDATES_PER_HOUR'
        | 'MAX_CONNECTIONS_PER_HOUR'
        | 'MAX_USER_CONNECTIONS'
        ) DECIMAL
      )+ ;

passwordOption2
  : 'PASSWORD' 'EXPIRE' ( 'DEFAULT' | 'NEVER' | 'INTERVAL' DECIMAL 'DAY' )?
  | 'PASSWORD' 'HISTORY' ( 'DEFAULT' | DECIMAL )
  | 'PASSWORD' 'REUSE' 'INTERVAL' ( 'DEFAULT' | DECIMAL 'DAY' )
  | 'PASSWORD' 'REQUIRE' 'CURRENT' ('DEFAULT' | 'OPTIONAL')?
  | 'FAILED_LOGIN_ATTEMPTS' DECIMAL
  | 'PASSWORD_LOCK_TIME' (DECIMAL | 'UNBOUNDED')
;

lockOption2
    : 'ACCOUNT' ('LOCK' | 'UNLOCK') ;

require
    : 'REQUIRE'
        ( 'NONE'
        | tlsOption ( 'AND'? tlsOption )*
        )
    ;

tlsOption
    : 'SSL'
    | 'X509'
    | ('CIPHER' | 'ISSUER' | 'SUBJECT') string
    ;

grantStatement
    : 'GRANT' roleOrPrivilegesList 'TO' user (',' user)* ( 'WITH' 'ADMIN' 'OPTION' )?
    | 'GRANT' (roleOrPrivilegesList | 'ALL' 'PRIVILEGES'?) 'ON' aclType? grantIdentifier 'TO' grantTargetList require? grantOptions? ('AS' 'USER' withRoles?)?
    | 'GRANT' 'PROXY' 'ON' user 'TO' grantTargetList ( 'WITH' 'GRANT' 'OPTION' )?
    ;

grantTargetList
    : createUser (',' createUser)*
    | user (',' user)*
    ;

grantOptions
    : 'WITH' grantOption
    ;

exceptRoleList
    : 'EXCEPT' roleList
    ;

withRoles
    : 'WITH' 'ROLE' (
        roleList
        | 'ALL' exceptRoleList?
        | 'NONE'
        | 'DEFAULT'
    )
    ;

revokeStatement
    : 'REVOKE' exists?
        ( roleOrPrivilegesList 'FROM' user (',' user)*
        | roleOrPrivilegesList 'ON' aclType? grantIdentifier 'FROM' user (',' user)*
        | 'ALL' 'PRIVILEGES'?
            ( 'ON' aclType? grantIdentifier
            | ',' 'GRANT' 'OPTION'
            )
            'FROM' user (',' user)*
        | 'PROXY' 'ON' user 'FROM' user (',' user)*
        )
        ('IGNORE' 'UNKNOWN' 'USER')?
    ;

aclType
    : 'TABLE'
    | 'FUNCTION'
    | 'PROCEDURE'
    ;

roleOrPrivilegesList
    : roleOrPrivilege (',' roleOrPrivilege)*
    ;

roleOrPrivilege
    : ( name columns? | userName )
    | ('SELECT' | 'INSERT' | 'UPDATE' | 'REFERENCES') columns?
    | ( 'DELETE' | 'USAGE' | 'INDEX' | 'DROP' | 'EXECUTE' | 'RELOAD' | 'SHUTDOWN' | 'PROCESS' | 'FILE' | 'PROXY' | 'SUPER' | 'EVENT' | 'TRIGGER' )
    | 'GRANT' 'OPTION'
    | 'SHOW' 'DATABASES'
    | 'CREATE' ( 'TEMPORARY' 'TABLES' | 'ROUTINE' | 'TABLESPACE' | 'USER' | 'VIEW' )?
    | 'LOCK' 'TABLES'
    | 'REPLICATION' ('CLIENT' | replica)
    | 'SHOW' 'VIEW'
    | 'ALTER' 'ROUTINE'?
    | ('CREATE' | 'DROP') 'ROLE'
    ;

grantIdentifier
    : ( '*' | name ) ('.' ( '*' | name ))?
    ;

grantOption
    : 'GRANT' 'OPTION'
    | ( 'MAX_QUERIES_PER_HOUR' | 'MAX_UPDATES_PER_HOUR' | 'MAX_CONNECTIONS_PER_HOUR' | 'MAX_USER_CONNECTIONS' ) DECIMAL
    ;

setRoleStatement
    : 'SET' 'ROLE' roleList
    | 'SET' 'ROLE' ('NONE' | 'DEFAULT')
    | 'SET' 'ROLE' 'ALL' ('EXCEPT' roleList)?
    | 'SET' 'DEFAULT' 'ROLE' (roleList | 'NONE' | 'ALL') 'TO' roleList
    ;

roleList
    : userName ( ',' userName )*
    ;

histogram
    : 'UPDATE' 'HISTOGRAM' 'ON' name
        ((',' name)* ('WITH' DECIMAL 'BUCKETS')? (('MANUAL' | 'AUTO')? 'UPDATE')?
        | ('USING' 'DATA' string )?
        )
    | 'DROP' 'HISTOGRAM' 'ON' name (',' name)*
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
        | 'READ' ('COMMITTED' | 'UNCOMMITTED')
        | 'SERIALIZABLE'
        )
    | accessMode
    ;

accessMode
    : 'READ' ( 'WRITE' | 'ONLY' ) ;

//optionValueNoOptionType
//    : 'DEFAULT'? qname equal term
//    | charset
////    | name equal expr
////    | qname equal term
//    | 'NAMES' ( equal term | name collate? | 'DEFAULT' )
//    ;

inDb
    : ('FROM' | 'IN') qname ;

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
    : assignToKeycache (',' assignToKeycache)*
    | qname 'PARTITION' '(' allOrPartitionNameList ')' cacheKeyList?
    ;

assignToKeycache
    : qname cacheKeyList?
    ;

cacheKeyList
    : indexKey '(' (name (',' name)*)? ')'
    ;

flushOption
    : ( 'HOSTS' | 'PRIVILEGES' | 'STATUS' | 'USER_RESOURCES' )
    | ('BINARY' | 'ENGINE' | 'ERROR' | 'GENERAL' | 'SLOW')? 'LOGS'
    | 'RELAY' 'LOGS' channel?
    | 'OPTIMIZER_COSTS'
    ;

flushTables
    : ('TABLES' | 'TABLE')
      ( 'WITH' 'READ' 'LOCK'
      | qname (',' qname)* ('FOR' 'EXPORT' | 'WITH' 'READ' 'LOCK')?
      )?
    ;

preloadTail
    : qname adminPartition cacheKeyList? ('IGNORE' 'LEAVES')?
    | preloadKeys (',' preloadKeys)*
    ;

preloadKeys
    : qname cacheKeyList? ('IGNORE' 'LEAVES')?
    ;

adminPartition
    : 'PARTITION' '(' allOrPartitionNameList ')'
    ;

resourceGroupVcpuList
    : 'VCPU' equal? range (','? range)*
    ;

range
    : DECIMAL ('-' DECIMAL)?
    ;

resourceGroupPriority
    : 'THREAD_PRIORITY' equal? DECIMAL
    ;

resourceGroupEnableDisable
    : 'ENABLE'
    | 'DISABLE'
    ;

explainOption
    : 'FORMAT' '=' qname ( 'INTO' qname )?
    | 'EXTENDED'
    | 'ANALYZE'
    | 'ANALYZE' 'FORMAT' '=' qname
    ;

explainableStatement
    : select
    | delete
    | insert
    | replace
    | updateStatement
    | 'FOR' 'CONNECTION' DECIMAL
    ;

term
    : qname
    | literal
    | term ( '->' | '->>' ) string
    | term 'AT' 'LOCAL'
    | 'BINARY' term
    | 'CAST' '(' term 'AS' castType 'ARRAY'? ')'
    | 'CAST' '(' term 'AT' 'TIME' 'ZONE' 'INTERVAL'? string 'AS' 'DATETIME' '(' DECIMAL ')' ')'
//    | 'CONVERT' '(' term ',' castType ')'
    | 'CONVERT' '(' term ',' dataType ')'
    | 'CONVERT' '(' term 'USING' name ')'

    | term 'COLLATE' name
    | '!' term
    | ('+' | '-' | '~') term
    | term '^' term
    | term ( '*' | '/' | 'DIV' | '%' | 'MOD' ) term
    | term ('+' | '-') term
    | term ('<<' | '>>') term
    | term '&' term
    | term '|' term
    | term ( '=' | ':=' | '!=' | '<>' | '<=>' | '>=' | '>' | '<=' | '<' ) term

    | function over?
    | windowFunctionCall
    | 'GROUPING' terms
//    | term 'CONCAT_PIPES' term
    | '{' name term '}'
    | 'MATCH' (qname (',' qname)* | '(' qname (',' qname)* ')') 'AGAINST' '(' term fulltextOptions? ')'
    | 'DEFAULT' '(' qname ')'
//    | 'VALUES' '(' qname ')'

    | term 'IS' 'NOT'? ('TRUE' | 'FALSE' | 'UNKNOWN' | 'NULL')
    | term 'NOT'? 'LIKE' term ('ESCAPE' term)?
    | term 'NOT'? ( 'REGEXP' | 'RLIKE' ) term
    | term 'NOT'? 'IN' ('(' select ')' | terms )
    | term 'MEMBER' 'OF'? '(' term ')'
    | term 'NOT'? 'BETWEEN' term 'AND' term
    | 'CASE' term? ('WHEN' term 'THEN' term)+ ('ELSE' term)? 'END'
    | term 'SOUNDS' 'LIKE' term

    | 'ROW'? terms
    | 'EXISTS'? '(' select ')'
    | ('ALL' | 'ANY' | 'SOME') '(' select ')'

    | 'NOT' term
    | term ('AND' | '&&') term
    | term 'XOR' term
    | term ('OR' | '||') term
    | qname ':=' term
    ;

interval
    : 'INTERVAL' term timeUnitToo ;

windowFunctionCall
    : ( 'ROW_NUMBER' | 'RANK' | 'DENSE_RANK' | 'CUME_DIST' | 'PERCENT_RANK' ) '(' ')' over
    | 'NTILE' ( '(' DECIMAL ')' | '(' term ')' ) over
    | ('LEAD' | 'LAG') '(' term (',' term (',' term)? )? ')' nullTreatment? over
    | ('FIRST_VALUE' | 'LAST_VALUE') '(' term ')' nullTreatment? over
    | 'NTH_VALUE' '(' term ',' term ')' ( 'FROM' ('FIRST' | 'LAST') )? nullTreatment? over
    ;

over
    : 'OVER' (name | windowSpec)
    ;

nullTreatment
    : ('RESPECT' | 'IGNORE') 'NULLS'
    ;

fulltextOptions
    : 'IN' 'BOOLEAN' 'MODE'
    | 'IN' 'NATURAL' 'LANGUAGE' 'MODE' ( 'WITH' 'QUERY' 'EXPANSION' )?
    | 'WITH' 'QUERY' 'EXPANSION'
    ;

function
    // Function names that are keywords.
    : ID '(' ( udfExpr ( ',' udfExpr )* )? ')'
    | qname '(' (term (',' term)* )? ')'

    | 'CHAR' '(' term (',' term)* ('USING' name)? ')'
    | 'CURRENT_USER' ('(' ')')?
    | 'DATE' '(' term ')'
    | 'DAY' '(' term ')'
    | 'HOUR' '(' term ')'
    | 'INSERT' '(' term ',' term ',' term ',' term ')'
    | 'INTERVAL' '(' term (',' term)+ ')'
    | 'JSON_VALUE' '(' term ',' string ('RETURNING' castType)? ( jsonResponse jsonResponse? )? ')'
    | 'LEFT' '(' term ',' term ')'
    | 'MINUTE' '(' term ')'
    | 'MONTH' '(' term ')'
    | 'RIGHT' '(' term ',' term ')'
    | 'SECOND' '(' term ')'
    | 'TIME' '(' term ')'
    | 'TIMESTAMP' '(' term (',' term)? ')'
    | 'TRIM' '(' ( term ('FROM' term)? | 'LEADING' term? 'FROM' term | 'TRAILING' term? 'FROM' term | 'BOTH' term? 'FROM' term ) ')'
    | 'USER' '(' ')'
    | 'VALUES' '(' term ')'
    | 'YEAR' '(' term ')'

    // Function names that are not keywords.
    | ('ADDDATE' | 'SUBDATE') '(' term ',' term ')'
    | 'CURDATE' ('(' ')')?
    | 'CURTIME' ('(' (DECIMAL)? ')')?
    | ('DATE_ADD' | 'DATE_SUB') '(' term ',' interval ')'
    | 'EXTRACT' '(' timeUnitToo 'FROM' term ')'
    | 'GET_FORMAT' '(' ('DATE' | 'TIME' | 'DATETIME' | 'TIMESTAMP') ',' term ')'
    | 'LOG' '(' term ( ',' term )? ')'
    | now
    | 'POSITION' '(' term 'IN' term ')'
    | 'SUBSTRING' '(' term ( ',' term (',' term)? | 'FROM' term ('FOR' term)? ) ')'
    | 'SYSDATE' ('(' (DECIMAL)? ')')?
    | ('TIMESTAMPADD' | 'TIMESTAMPDIFF') '(' timeUnit ',' term ',' term ')'
    | 'UTC_DATE' ('(' ')')?
    | 'UTC_TIME' ('(' (DECIMAL)? ')')?
    | 'UTC_TIMESTAMP' ('(' (DECIMAL)? ')')?

    | 'ASCII' '(' term ')'
    | 'CHARSET' '(' term ')'
    | 'COALESCE' '(' term (',' term)* ')'
    | 'COLLATION' '(' term ')'
    | 'DATABASE' '(' ')'
    | 'IF' '(' term ',' term ',' term ')'
    | 'FORMAT' '(' term ',' term (',' term)? ')'
    | 'MICROSECOND' '(' term ')'
    | 'MOD' '(' term ',' term ')'
    | 'PASSWORD' '(' term ')'
    | 'QUARTER' '(' term ')'
    | 'REPEAT' '(' term ',' term ')'
    | 'REPLACE' '(' term ',' term ',' term ')'
    | 'REVERSE' '(' term ')'
    | 'ROW_COUNT' '(' ')'
    | 'TRUNCATE' '(' term ',' term ')'
    | 'WEEK' '(' term (',' term)? ')'
    | 'WEIGHT_STRING' '(' term ( 'AS' ( 'CHAR' | 'BINARY' ) '(' DECIMAL ')' )? ')'
    | 'GEOMETRYCOLLECTION' '(' (term (',' term)*)? ')'
    | 'LINESTRING' '(' term (',' term)* ')'
    | 'MULTILINESTRING' '(' term (',' term)* ')'
    | 'MULTIPOINT' '(' term (',' term)* ')'
    | 'MULTIPOLYGON' '(' term (',' term)* ')'
    | 'POINT' '(' term ',' term ')'
    | 'POLYGON' '(' term (',' term)* ')'

    | 'AVG' '(' 'DISTINCT'? 'ALL'? term ')'
    | ('BIT_AND' | 'BIT_OR' | 'BIT_XOR') '(' 'ALL'? term ')'
    | 'JSON_ARRAYAGG' '(' 'ALL'? term ')'
    | 'JSON_OBJECTAGG' '(' 'ALL'? term ',' 'ALL'? term ')'
    | 'ST_COLLECT' '(' 'DISTINCT'? 'ALL'? term ')'
    | 'COUNT' '(' ( 'ALL'? '*' | 'ALL'? term | 'DISTINCT' term (',' term)* ) ')'
    | ('MIN' | 'MAX') '(' 'DISTINCT'? 'ALL'? term ')'
    | ( 'STD' | 'VARIANCE' | 'STDDEV_SAMP' | 'VAR_SAMP' | 'SUM' ) '(' 'ALL'? term ')'
    | 'SUM' '(' 'DISTINCT' 'ALL'? term ')'
    | 'GROUP_CONCAT' '(' 'DISTINCT'? term (',' term)* orderBy? ( 'SEPARATOR' string )? ')'
    ;

udfExpr
    : term alias?
    ;

castType
    : 'BINARY' ('(' DECIMAL ')')?
//    | 'CHAR' ('(' INTEGER ')')? charsetWithOptBinary?
    | 'CHAR' ('(' DECIMAL ')')? ( charset3 name )? 'BINARY'?
    | ('NCHAR' | 'NATIONAL' 'CHAR') ('(' DECIMAL ')')?
    | 'SIGNED' ( 'INT' | 'INTEGER' )?
    | 'UNSIGNED' ( 'INT' | 'INTEGER' )?
    | 'DATE'
    | 'YEAR'
    | 'TIME' ('(' DECIMAL ')')?
    | 'DATETIME' ('(' DECIMAL ')')?
    | ('DEC' | 'DECIMAL' ) floatOptions?
//    | 'DOUBLE'
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
    : ( 'INT' | 'INTEGER' | 'TINYINT' | 'SMALLINT' | 'MEDIUMINT' | 'BIGINT' ) ( '(' ( DECIMAL | FLOAT ) ')' )? fieldOptions?
    | ( 'REAL' | 'DOUBLE' 'PRECISION'? ) ( '(' DECIMAL ',' DECIMAL ')' )? fieldOptions?
    | ( 'FLOAT' | 'DEC' | 'DECIMAL' | 'NUMERIC' | 'FIXED' ) floatOptions? fieldOptions?
    | 'BIT' ( '(' ( DECIMAL | FLOAT ) ')' )?
    | 'BOOL'
    | 'BOOLEAN'
    | ( ( 'CHAR' | 'CHARACTER' ) 'VARYING'?
      | 'NATIONAL' ( 'CHAR' | 'CHARACTER' ) 'VARYING'?
      | 'NATIONAL'? 'VARCHAR'
      | 'NVARCHAR'
      | 'NCHAR' ( 'VARCHAR' | 'VARYING' )?
      ) ('(' ( DECIMAL | FLOAT ) ')')? characterType*

    | 'BINARY' ('(' ( DECIMAL | FLOAT ) ')')?

    | 'VARBINARY' ('(' ( DECIMAL | FLOAT ) ')')
    | 'VECTOR' ('(' DECIMAL ')')?

    | 'YEAR' ('(' ( DECIMAL | FLOAT ) ')')? fieldOptions?
    | 'DATE'
    | 'TIME' ('(' DECIMAL ')')?
    | 'TIMESTAMP' ('(' DECIMAL ')')?
    | 'DATETIME' ('(' DECIMAL ')')?
    | 'TINYBLOB'
    | 'BLOB' ('(' ( DECIMAL | FLOAT ) ')')?

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
    | 'LONG' ('CHAR' 'VARYING' | 'VARCHAR')? characterType?
    | 'TINYTEXT' characterType?
    | 'TEXT' ('(' ( DECIMAL | FLOAT ) ')')? characterType?
    | 'MEDIUMTEXT' characterType?
    | 'LONGTEXT' characterType?
    | 'ENUM' '(' term ( ',' term )* ')' characterType?
    | 'SET' '(' string (',' string)* ')' characterType?
    | 'LONG' characterType?
    | 'SERIAL'
    | 'JSON'

    | 'FLOAT4'
    | 'FLOAT8'
    | 'INT1'
    | 'INT2'
    | 'INT3'
    | 'INT4'
    | 'INT8'
    | 'MIDDLEINT'

    ;


charset
    : ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) name
    ;

charset3
    : ( ( 'CHAR' | 'CHARACTER' ) 'SET' | 'CHARSET' )
    ;

//charset2
//    : ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) name
//    | 'ASCII'
//    | 'UNICODE'
//    ;

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

channel
    : 'FOR' 'CHANNEL' string
    ;

compoundStatement
    : statement
    | 'RETURN' term
    | 'IF' ifBody 'END' 'IF'
    | 'CASE' term? ('WHEN' term thenStatement)+ ('ELSE' (compoundStatement ';')+)? 'END' 'CASE'
    | name ':' beginEndBlock name?
    | beginEndBlock
    | name ':' unlabeledControl name?
    | unlabeledControl
    | 'LEAVE' name
    | 'ITERATE' name
    | 'OPEN' name
    | 'FETCH' ('NEXT'? 'FROM')? name 'INTO' name (',' name)*
    | 'CLOSE' name
    ;

ifBody
    : term thenStatement ('ELSEIF' ifBody | 'ELSE' (compoundStatement ';')+)?
    ;

thenStatement
    : 'THEN' (compoundStatement ';')+
    ;

beginEndBlock
    : 'BEGIN' (spDeclaration ';')* (compoundStatement ';')* 'END'
    ;

unlabeledControl
    : loopBlock
    | whileDoBlock
    | repeatUntilBlock
    ;

loopBlock
    : 'LOOP' (compoundStatement ';')+ 'END' 'LOOP'
    ;

whileDoBlock
    : 'WHILE' term 'DO' (compoundStatement ';')+ 'END' 'WHILE'
    ;

repeatUntilBlock
    : 'REPEAT' (compoundStatement ';')+ 'UNTIL' term 'END' 'REPEAT'
    ;

spDeclaration
    : 'DECLARE' name (',' name)* dataType collate? ('DEFAULT' term)?
    | 'DECLARE' name 'CONDITION' 'FOR' spCondition
    | 'DECLARE' ('CONTINUE' | 'EXIT' | 'UNDO') 'HANDLER' 'FOR' handlerCondition ( ',' handlerCondition )* compoundStatement
    | 'DECLARE' name 'CURSOR' 'FOR' select
    ;

spCondition
    : DECIMAL
    | 'SQLSTATE' 'VALUE'? string
    ;

handlerCondition
    : spCondition
    | name
    | 'SQLWARNING'
    | 'NOT' 'FOUND'
    | 'SQLEXCEPTION'
    ;

statementInformationItem
    : literal '=' ('NUMBER' | 'ROW_COUNT')
    ;

conditionInformationItem
    : literal '=' ( signalName | 'RETURNED_SQLSTATE' )
    ;

signalItem
    : signalName '=' literal
    ;

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
    | 'EVERY' term timeUnitToo ('STARTS' term)? ('ENDS' term)?
    ;

constraintEnforcement
    : 'NOT'? 'ENFORCED'
    ;

tableConstraintDef
    : indexKey indexNameAndType? '(' keyPart (',' keyPart)* ')' indexOption*
    | 'FULLTEXT' indexKey? name? '(' keyPart (',' keyPart)* ')' indexOption*
    | 'SPATIAL' indexKey? name? '(' keyPart (',' keyPart)* ')' indexOption*
    | ('CONSTRAINT' name?)?
        ( ('PRIMARY' 'KEY' | 'UNIQUE' indexKey?) indexNameAndType? '(' keyPart (',' keyPart)* ')' indexOption*
        | 'FOREIGN' 'KEY' name? '(' keyPart (',' keyPart)* ')' referenceDef
        | 'CHECK' '(' term ')' constraintEnforcement?
        )
    ;

columnDef
    : dataType columnAttribute* ;

columnAttribute
    : 'NOT'? null
    | 'NOT' 'SECONDARY'
    | 'DEFAULT' ( now | literal | '(' term ')' )
    | 'ON' 'UPDATE' now
    | 'AUTO_INCREMENT'
    | 'SERIAL' 'DEFAULT' 'VALUE'
    | 'PRIMARY'? 'KEY'
    | 'UNIQUE' 'KEY'?
    | 'COMMENT' string
    | collate
    | 'COLUMN_FORMAT' ('FIXED' | 'DYNAMIC' | 'DEFAULT')
    | 'STORAGE' ('DISK' | 'MEMORY' | 'DEFAULT')
    | 'SRID' DECIMAL
    | ('CONSTRAINT' name?)? 'CHECK' '(' term ')' ( 'NOT'? 'ENFORCED' )?
    | constraintEnforcement
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | visibility
    | ( 'GENERATED' 'ALWAYS' )? 'AS' '(' term ')' ( 'VIRTUAL' | 'STORED' )?
    | referenceDef
    ;

now
    : ( 'NOW' | 'CURRENT_TIMESTAMP' | 'LOCALTIME' | 'LOCALTIMESTAMP' ) ( '(' DECIMAL? ')' )?
    ;

referenceDef
    : 'REFERENCES' qname ('(' name (',' name)* ')')?
      ( 'MATCH' ('FULL' | 'PARTIAL' | 'SIMPLE') )?
        ( referenceOption referenceOption? )?
    ;

referenceOption
    : 'ON' ('UPDATE' | 'DELETE')
      ('RESTRICT' | 'CASCADE' | 'SET' null | 'SET' 'DEFAULT' | 'NO' 'ACTION')
    ;

keyPart
    : ( name ('(' ( DECIMAL | FLOAT ) ')')? | '(' term ')' ) direction?
    ;

indexType
    : 'BTREE' | 'RTREE' | 'HASH'
    ;

visibility
    : 'VISIBLE'
    | 'INVISIBLE'
    ;

fieldOptions
    : ('SIGNED' | 'UNSIGNED' | 'ZEROFILL')+
    ;

characterType
    : 'BYTE'
    | 'BINARY' ( 'ASCII' | charset | 'UNICODE' )?
    | 'BINARY'? ( 'ASCII' | charset | 'UNICODE' )
    ;

tableOption
    : 'AUTOEXTEND_SIZE' '='? byteSize
    | 'AUTO_INCREMENT' '='? DECIMAL
    | 'AVG_ROW_LENGTH' '='? DECIMAL
    | 'DEFAULT'? charset3 '='? name
    | 'CHECKSUM' '='? DECIMAL
//    | 'DEFAULT'? 'COLLATE' '='? name
    | 'COLLATE' '='? name
    | 'COMMENT' '='? string
    | 'COMPRESSION' '='? string
    | 'CONNECTION' '='? string
    | 'DATA' 'DIRECTORY' '='? string
    | 'INDEX' 'DIRECTORY' '='? string
    | 'DELAY_KEY_WRITE' '='? DECIMAL
    | 'ENCRYPTION' '='? string
    | 'ENGINE' '='? name
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'INSERT_METHOD' '='? ( 'NO' | 'FIRST' | 'LAST' )
    | 'KEY_BLOCK_SIZE' '='? DECIMAL
    | 'MAX_ROWS' '='? DECIMAL
    | 'MIN_ROWS' '='? DECIMAL
    | 'PACK_KEYS' '='? ternaryOption
    | 'PASSWORD' '='? string
    | 'ROW_FORMAT' '='? ( 'DEFAULT' | 'DYNAMIC' | 'FIXED' | 'COMPRESSED' | 'REDUNDANT' | 'COMPACT' )
    | 'START' 'TRANSACTION'
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | 'STATS_AUTO_RECALC' '='? ternaryOption
    | 'STATS_PERSISTENT' '='? ternaryOption
    | 'STATS_SAMPLE_PAGES' '='? ternaryOption
    | 'TABLESPACE' '='? name
    | 'STORAGE' ('DISK' | 'MEMORY')
    | 'SECONDARY_ENGINE' equal? name
    | 'UNION' '='? '(' qname (',' qname)* ')'
//    | 'TABLE_CHECKSUM' '='? INTEGER
    ;

ternaryOption
    : DECIMAL
    | 'DEFAULT'
    ;

partitionBy
    : 'PARTITION' 'BY'
      ( hash
      | ( 'RANGE' | 'LIST' )
          ( '(' term ')'
          | 'COLUMNS' '(' (name (',' name)*)? ')'
          )
      )
      ( 'PARTITIONS' DECIMAL )?
      subpartitionBy?
      ('(' partitionDef (',' partitionDef)* ')')?
    ;

subpartitionBy
    : 'SUBPARTITION' 'BY' hash ( 'SUBPARTITIONS' DECIMAL )? ;

hash
    : 'LINEAR'?
      ( 'HASH' '(' term ')'
      | 'KEY' ('ALGORITHM' '=' DECIMAL)? '(' ( name (',' name)* )? ')'
      )
      ;

partitionDef
    : 'PARTITION' name
        ( 'VALUES'
            ( 'LESS' 'THAN' ( terms | 'MAXVALUE' )
            | 'IN' terms
//            | '(' '(' term (',' term)* ')' ( ',' '(' term (',' term)* ')' )* ')')
            )
        )?
        partitionOption*
        ( '(' subpartition (',' subpartition)* ')' )?
    ;

partitionOption
    : 'TABLESPACE' '='? name
    | 'STORAGE'? 'ENGINE' '='? name
    | 'NODEGROUP' '='? DECIMAL
    | ('MAX_ROWS' | 'MIN_ROWS') '='? DECIMAL
    | ('DATA' | 'INDEX') 'DIRECTORY' '='? string
    | 'COMMENT' '='? string
    ;

subpartition
    : 'SUBPARTITION' name partitionOption*
    ;

definer
    : 'DEFINER' '=' user
    ;

exists
    : 'IF' 'EXISTS'
    ;

notExists
    : 'IF' 'NOT' 'EXISTS'
    ;

procedureParameter
    : ('IN' | 'OUT' | 'INOUT')? functionParameter
    ;

functionParameter
    : name dataType collate?
    ;

collate
    : 'COLLATE' name
    ;

schemaIdentifierPair
    : '(' name ',' name ')'
    ;

setter
    : scope? qname equal? term
    ;

fields
    : ( 'FIELDS' | 'COLUMNS' )
      ( 'TERMINATED' 'BY' ( string | HEXADECIMAL )
      | 'OPTIONALLY'? 'ENCLOSED' 'BY' ( string | HEXADECIMAL )
      | 'ESCAPED' 'BY' ( string | HEXADECIMAL )
      )+
    ;

lines
    : 'LINES'
      ( 'STARTING' 'BY' string
      | 'TERMINATED' 'BY' string
      )+
    ;

createUser
    : user ( identified ('AND' identified ('AND' identified)? )? )?
    ;

identified
    : 'IDENTIFIED' 'BY' name
    | 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD'
    | 'IDENTIFIED' 'WITH' name
    | 'IDENTIFIED' 'WITH' name 'BY' name
    | 'IDENTIFIED' 'WITH' name 'BY' 'RANDOM' 'PASSWORD'
    | 'IDENTIFIED' 'WITH' name 'AS' name
    ;



alterAuthOption
    : 'IDENTIFIED' 'WITH' name ('AS' name)?
    | 'IDENTIFIED' ('WITH' name )? ( 'BY' | 'AS' )
      ( name | 'RANDOM' 'PASSWORD' ) ('REPLACE' qname)? retainCurrentPassword?
    | 'DISCARD' 'OLD' 'PASSWORD'
    ;

retainCurrentPassword
    : 'RETAIN' 'CURRENT' 'PASSWORD' ;

//discardOldPassword
//    : 'DISCARD' 'OLD' 'PASSWORD'
//    ;

userRegistration
    : factor 'INITIATE' 'REGISTRATION'
    | factor 'UNREGISTER'
    | factor 'FINISH' 'REGISTRATION' 'SET' 'CHALLENGE_RESPONSE' 'AS' string
    ;

factor
    : DECIMAL 'FACTOR' ;

//replacePassword
//    : 'REPLACE' string ;

user
    : userName
    | 'CURRENT_USER' ('(' ')')?
    ;

userName
    : name ( '@' | qname )? ;

like
    : 'LIKE' name
    | where
    ;

onlineOption
    : 'ONLINE'
    | 'OFFLINE'
    ;

noLogging
    : 'LOCAL'
    | 'NO_WRITE_TO_BINLOG'
    ;

partition
    : 'PARTITION' '(' name (',' name)* ')'
    ;

columns
    : '(' name (',' name)* ')'
    ;

qname
    : ( '.'? name | LOCAL | GLOBAL )
      ( '.' name ( '.' name )? )?
    ;

literal
    // inlined the following (replacing 'name'), to shorten parse tree.
    // may revert if this makes climbing tree harder.
//    : name
    : ID
    | keyword
//    | CHARSET
    | string
//    // TODO can there be a space between CHARSET and STRING? if not, somehow move to lexer
//    | STRING+
//    | NATIONAL STRING*
//    | BLOB
//    | QUOTED+
    | ( '+' | '-' )? DECIMAL
    | ( '+' | '-' )? FLOAT
    | HEXADECIMAL
    | BINARY
    | SIZE
    | datetime
    | null
    | PARAM
    // TODO is this needed? mooted by rule qname?
    | LOCAL
    | GLOBAL
    | interval
    ;

string
    : CHARSET? STRING+
    | CHARSET? QUOTED+
    // Note: HEXADECIMAL without a CHARSET prefix is a number
    | CHARSET HEXADECIMAL
    | CHARSET? BLOB
    | NATIONAL STRING*
    // TODO disable <secret> after testing
    | '<secret>'
    ;

strings
    : string (',' string)*
    ;

null
    : 'NULL' | NOPE ;

datetime
    : ( 'DATE' | 'TIME' | 'TIMESTAMP' ) string ;

floatOptions
    : typeLength
    | typePrecision
    ;

typePrecision : '(' DECIMAL ',' DECIMAL ')' ;

typeLength : '(' ( DECIMAL | FLOAT ) ')' ;

name
    : ID
    | keyword
    | string
    // TODO remove this after lexer rule CHARSET is fixed
    | CHARSET
    ;

byteSize
    : DECIMAL | SIZE ;

equal
    : '=' | ':=' ;

scope
    : 'PERSIST'
    | 'PERSIST_ONLY'
    | 'GLOBAL'
    | 'LOCAL'
    | 'SESSION'
    ;

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
//    | 'AS'
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
//      	| 'CONCAT_PIPES'
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
    | 'FILE'
    | 'FILE_BLOCK_SIZE'
    | 'FILTER'
    | 'FINISH'
    | 'FIRST'
    | 'FIRST_VALUE'
    | 'FIXED'
    | 'FLOAT'
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
    | 'GEOMETRY'
    | 'GEOMETRYCOLLECTION'
    | 'GEOMCOLLECTION'
    | 'GET'
    | 'GET_FORMAT'
    | 'GET_MASTER_PUBLIC_KEY'
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
    | 'LIKE'
    | 'LIMIT'
    | 'LINEAR'
    | 'LINES'
    | 'LINESTRING'
    | 'LIST'
    | 'LOAD'
    | 'LOCAL'
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
    | 'MASTER_AUTO_POSITION'
    | 'MASTER_BIND'
    | 'MASTER_COMPRESSION_ALGORITHM'
    | 'MASTER_CONNECT_RETRY'
    | 'MASTER_DELAY'
    | 'MASTER_HEARTBEAT_PERIOD'
    | 'MASTER_HOST'
    | 'MASTER_LOG_FILE'
    | 'MASTER_LOG_POS'
    | 'MASTER_PASSWORD'
    | 'MASTER_PORT'
    | 'MASTER_PUBLIC_KEY_PATH'
    | 'MASTER_RETRY_COUNT'
    | 'MASTER_SSL'
    | 'MASTER_SSL_CA'
    | 'MASTER_SSL_CAPATH'
    | 'MASTER_SSL_CERT'
    | 'MASTER_SSL_CIPHER'
    | 'MASTER_SSL_CRL'
    | 'MASTER_SSL_CRLPATH'
    | 'MASTER_SSL_KEY'
    | 'MASTER_SSL_VERIFY_SERVER_CERT'
    | 'MASTER_TLS_CIPHERSUITES'
    | 'MASTER_TLS_VERSION'
    | 'MASTER_USER'
    | 'MASTER_ZSTD_COMPRESSION_LEVEL'
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
    | 'MYSQL_ERRNO'
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
    | 'SLAVE'
    | 'SLOW'
    | 'SMALLINT'
    | 'SNAPSHOT'
    | 'SOCKET'
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
    | 'TRAILING'
    | 'TRANSACTION'
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
    : '0x' BASE16+ ;

DECIMAL
    : BASE10 ;

BINARY
    : '0b' BASE2+ ;

FLOAT
    : ( BASE10 ( '.' BASE10? )? | '.' BASE10 ) ( 'E' [-+]? BASE10 )? ;

SIZE
    : BASE10 [KMGT] ;

// Sometimes a name, sometimes an ID, always a bummer
QUOTED
    : '"' ('\\'? .)*? '"' ;

LOCAL
    : '@' ( ID | STRING | IPV4 | IPV6 ) ;

GLOBAL
    : '@' '@' ( ID ( '.' ID )? )? ;

STRING
    : '\'' ('\\'? .)*? '\''
    | '$$' .*? '$$'
    ;

NATIONAL
    : 'N' STRING ;

// TODO match against supported list, otherwise is an ID
CHARSET
    : '_' [A-Z0-9]+ ;

ID
    : '`' ( ~'`' | '``' )* '`'
    | [A-Z0-9_$\u0080-\uFFFF]+
    ;


BLOB
    : 'x\'' BASE16+ '\''
    | 'b\'' BASE2+ '\''
    ;

// MySQL synonym for NULL. A separate token from 'NULL'
// because I'm not clear where its permitted.
NOPE options { caseInsensitive = false; }
    : '\\N' ;

MYSQL_COMMENT
    : '/*!' ( BLOCK_COMMENT | . )*?  '*/' -> channel(HIDDEN);
//    : '/*' .*? '*/' -> channel(HIDDEN);

BLOCK_COMMENT
// Nested block comments. Useful, but incorrect.
    : '/*' ~[!] .*? '*/' -> channel(HIDDEN);
//    : '/*' ~[!] .*? '*/' -> channel(HIDDEN);
//    : '/*' ( MYSQL_COMMENT | .*? ) '*/' -> channel(HIDDEN);

//BLOCK_COMMENT
//// Nested block comments. Useful, but incorrect.
//    : '/*' ( BLOCK_COMMENT | ~[*/] | '*' ~'/' )* '*/' -> channel(HIDDEN);
////    : '/*' .*? '*/' -> channel(HIDDEN);
//
// Another MySQL-ism...?
POUND_COMMENT
    : '#' ~[\n\r]* -> channel(HIDDEN) ;

COMMENT
    // MySQL requires whitespace before content
    : '--' ( [ \t] ~[\n\r]* | [\n\r] | EOF ) -> channel(HIDDEN)
    // Playing around with variations, to see which I prefer.
//    : '--' ( [ \t] .*? )? ( [\n\r] | EOF ) -> channel(HIDDEN)
    ;

WHITESPACE
    : [ \t\f\r\n]+ -> channel(HIDDEN)
    ;

fragment IPV4 : BASE10 '.' BASE10 '.' BASE10 '.' BASE10;

fragment IPV6 : GROUPS ( '::' GROUPS? )? ;

fragment GROUPS : GROUP ( ':' GROUP )* ;

fragment GROUP : BASE16 BASE16 BASE16 BASE16 ;

fragment BASE2 : [01]+ ;

fragment BASE10 : [0-9]+ ;

fragment BASE16 : [0-9A-F] ;
