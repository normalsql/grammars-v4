grammar MySQL;

/*
  Copyright 2025 Jason Osgood

  Refactoring MySQL.g4 to adopt NormalSQL's rules, idioms, and style. Goal is
  for grammars of misc dialects to all emit the same parse tree (given the
  same input). A work in progress, as grammars converge over time.

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
//    : (statement | beginWork) ';' ;
    : statement? ( (';'|'|') statement? )* EOF ;

// TODO: inlining all the statements for now. will re-refactor as needed.

statement
    // DDL
    : 'ALTER' onlineOption? 'TABLE' qname alterTableActions?
    | 'ALTER' ( 'DATABASE' | 'SCHEMA' ) name (createDatabaseOption | 'READ' 'ONLY' '='? ternaryOption)+
    | 'ALTER' 'PROCEDURE' qname routineCreateOption*
    | 'ALTER' 'FUNCTION' qname routineCreateOption*
    | 'ALTER' viewAlgorithm? definer? security? 'VIEW' qname columns? 'AS' select viewCheckOption?
    | 'ALTER' definer? 'EVENT' qname ('ON' 'SCHEDULE' schedule)? ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ('RENAME' 'TO' name)? ( 'ENABLE' | 'DISABLE' ('ON' replica)? )? ('COMMENT' string)? ('DO' compoundStatement)?
    | 'ALTER' 'TABLESPACE' name ( ('ADD' | 'DROP') 'DATAFILE' string alterTablespaceOptions? | 'RENAME' 'TO' name | alterTablespaceOptions )
    | 'ALTER' 'UNDO' 'TABLESPACE' name 'SET' ( 'ACTIVE' | 'INACTIVE' ) undoTableSpaceOptions?
    | 'ALTER' 'USER' exists?  ( createUser (',' createUser)* | alterUser (',' alterUser)* ) createUserTail
    | 'ALTER' 'USER' exists?  userFunction
        ( ('IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD' | 'IDENTIFIED' 'BY' string) replacePassword? retainCurrentPassword?
        | 'DISCARD' 'OLD' 'PASSWORD'
        | userRegistration?
        )
//    | 'ALTER' 'USER' exists?  user ( 'DEFAULT' 'ROLE' ('ALL' | 'NONE' | roleList) | userRegistration? )
    | 'ALTER' 'USER' exists?  user 'DEFAULT' 'ROLE' ('ALL' | 'NONE' | userName ( ',' userName )* )
    | 'ALTER' 'LOGFILE' 'GROUP' name 'ADD' 'UNDOFILE' string alterLogfileGroupOptions?
    | 'ALTER' 'SERVER' name 'OPTIONS' '(' serverOption (',' serverOption)* ')'
    | 'ALTER' 'INSTANCE' 'ROTATE' name 'MASTER' 'KEY'
    | 'ALTER' 'RELOAD' 'TLS' ( 'NO' 'ROLLBACK' 'ON' 'ERROR' | 'FOR' 'CHANNEL' name ( 'NO' 'ROLLBACK' 'ON' 'ERROR' )? )
    | 'ALTER' ('ENABLE' | 'DISABLE') name name
    | 'ALTER' 'RELOAD' 'KEYRING'
    | 'CREATE' 'AGGREGATE'? 'FUNCTION' notExists? name 'RETURNS' ( 'STRING' | 'INT' | 'REAL' | 'DECIMAL' ) 'SONAME' string
    | 'CREATE' ( 'DATABASE' | 'SCHEMA' ) notExists? name createDatabaseOption*
    | 'CREATE' definer? 'FUNCTION' notExists? qname '(' ( functionParameter (',' functionParameter)* )? ')' 'RETURNS' dataType collate? routineCreateOption* storedRoutineBody
    | 'CREATE' definer? 'PROCEDURE' notExists? qname '(' ( procedureParameter (',' procedureParameter)* )? ')' routineCreateOption* storedRoutineBody
    | 'CREATE' definer? 'TRIGGER' notExists? qname ( 'BEFORE' | 'AFTER' ) ('INSERT' | 'UPDATE' | 'DELETE') 'ON' qname 'FOR' 'EACH' 'ROW' (('FOLLOWS' | 'PRECEDES') name)? compoundStatement
    | 'CREATE' createIndex
    | 'CREATE' 'LOGFILE' 'GROUP' name 'ADD' 'UNDOFILE' string (logfileGroupOption (','? logfileGroupOption)*)?
    | 'CREATE' 'SERVER' name 'FOREIGN' 'DATA' 'WRAPPER' name 'OPTIONS' '(' serverOption (',' serverOption)* ')'
    | 'CREATE' 'TABLESPACE' name ('ADD' 'DATAFILE' string)? ( 'USE' 'LOGFILE' 'GROUP' name )? tablespaceOptions?
    | 'CREATE' 'TEMPORARY'? 'TABLE' notExists? qname ('(' tableElementList ')')? ( tableOption (','? tableOption)* )? partitionBy? (('REPLACE' | 'IGNORE')? 'AS'? select)?
    | 'CREATE' 'TEMPORARY'? 'TABLE' notExists? qname ( 'LIKE' qname | '(' 'LIKE' qname ')' )
    | 'CREATE' ('OR' 'REPLACE' viewAlgorithm? | viewAlgorithm)? definer? security? 'VIEW' qname columns? 'AS' select viewCheckOption?
    | 'CREATE' definer? 'EVENT' notExists? qname 'ON' 'SCHEDULE' schedule ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ('ENABLE' | 'DISABLE' ('ON' replica)?)? ( 'COMMENT' string )? 'DO' compoundStatement
    | 'CREATE' 'ROLE' notExists? roleList
    | 'CREATE' orReplace? 'SPATIAL' 'REFERENCE' 'SYSTEM' notExists? INTEGER srsAttribute*
    | 'CREATE' 'UNDO' 'TABLESPACE' name 'ADD' 'DATAFILE' string undoTableSpaceOptions?
    | 'DROP' ( 'DATABASE' | 'SCHEMA' ) exists? name
    | 'DROP' 'EVENT' exists? qname
    | 'DROP' 'FUNCTION' exists? qname
    | 'DROP' 'PROCEDURE' exists? qname
    | 'DROP' onlineOption? 'INDEX' qname 'ON' qname ('ALGORITHM' '='? name | 'LOCK' '='? name)*
    | 'DROP' 'LOGFILE' 'GROUP' name ( dropLogfileGroupOption (','? dropLogfileGroupOption)* )?
    | 'DROP' 'SERVER' exists? name
    | 'DROP' 'TEMPORARY'? ('TABLE' | 'TABLES') exists? qname (',' qname)* ( 'RESTRICT' | 'CASCADE' )?
    | 'DROP' 'TABLESPACE' name ( dropLogfileGroupOption (','? dropLogfileGroupOption)* )?
    | 'DROP' 'TRIGGER' exists? qname
    | 'DROP' 'VIEW' exists? qname (',' qname)* ('RESTRICT' | 'CASCADE')?
    | 'DROP' 'ROLE' exists? roleList
    | 'DROP' 'SPATIAL' 'REFERENCE' 'SYSTEM' exists? INTEGER
    | 'DROP' 'UNDO' 'TABLESPACE' name undoTableSpaceOptions?
    | 'RENAME' ('TABLE' | 'TABLES') renamePair ( ',' renamePair )*
    | 'TRUNCATE' 'TABLE'? qname
    | 'IMPORT' 'TABLE' 'FROM' strings

    | 'CALL' qname ('(' (term (',' term)*)? ')')?
    | delete
    | 'DO' item (',' item)*
    | 'HANDLER' qname 'OPEN' tableAlias?
    | 'HANDLER' name ( 'CLOSE' | 'READ' handlerReadOrScan where? limit? )
    | insert
    | loadStatement
    | replace
    | select
    | updateStatement
    | 'START' 'TRANSACTION' ('WITH' 'CONSISTENT' 'SNAPSHOT' | 'READ' ('WRITE' | 'ONLY') )*
    | 'COMMIT' 'WORK'? ('AND' 'NO'? 'CHAIN')? ( 'NO'? 'RELEASE' )?
    | 'SAVEPOINT' name
    | 'ROLLBACK' 'WORK'? ( 'TO' 'SAVEPOINT'? name | ('AND' 'NO'? 'CHAIN')? ('NO'? 'RELEASE')? )
    | 'RELEASE' 'SAVEPOINT' name
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
    | 'RESET' 'PERSIST' (exists 'DEFAULT'? qname)?
    | 'START' replica replicaThreadOptions? ('UNTIL' replicaUntil)? userOption? passwordOption? defaultAuthOption? pluginDirOption? channel?
    | 'STOP' replica replicaThreadOptions? channel?
    | 'CHANGE' 'REPLICATION' 'FILTER' filterDefinition ( ',' filterDefinition )* channel?
    | 'LOAD' ('DATA' | 'TABLE' qname) 'FROM' 'MASTER'
    | ('START' groupReplicationStartOptions? | 'STOP') 'GROUP_REPLICATION'
    | 'PREPARE' name 'FROM' (string | name)
    | 'EXECUTE' name ('USING' qname ( ',' qname )*)?
    | ('DEALLOCATE' | 'DROP') 'PREPARE' name

    | 'CLONE' 'LOCAL' 'DATA' 'DIRECTORY' equal? string
    | 'CLONE' 'REMOTE' ('FOR' 'REPLICATION')?
    | 'CLONE' 'INSTANCE' 'FROM' user ':' INTEGER 'IDENTIFIED' 'BY' string (ssl | 'DATA' 'DIRECTORY' equal? string ssl?)?

    | 'CREATE' 'USER' notExists? createUser (',' createUser)* ('DEFAULT' 'ROLE' roleList)? createUserTail
    | dropUserStatement
    | grantStatement
    | renameUserStatement
    | revokeStatement
    | setRoleStatement
    | 'ANALYZE' noLogging? 'TABLE' qname (',' qname)* histogram?
    | 'CHECK' 'TABLE' qname (',' qname)* checkOption*
    | 'CHECKSUM' 'TABLE' qname (',' qname)* ( 'QUICK' | 'EXTENDED' )?
    | 'OPTIMIZE' noLogging? 'TABLE' qname (',' qname)*
    | 'REPAIR' noLogging? 'TABLE' qname (',' qname)* repairType*
    | 'UNINSTALL' ( 'PLUGIN' name | 'COMPONENT' string (',' string)* )
    | 'INSTALL' 'PLUGIN' name 'SONAME' string
    | 'INSTALL' 'COMPONENT' strings ('SET' installSetValue ( ',' installSetValue )*)?

//    | 'SET' optionValueNoOptionType (',' (scope 'DEFAULT'? qname equal term | optionValueNoOptionType))*
//    | 'SET' scope? qname equal term (',' scope? qname equal term )*
    | 'SET' setVariable (',' setVariable )*
    | 'SET' 'NAMES' ( equal term | name collate? | 'DEFAULT' )
//    | 'SET' scope? 'TRANSACTION' transactionCharacteristics
//    | 'SET' scope? 'DEFAULT'? qname equal term (',' (scope 'DEFAULT'? qname equal term | optionValueNoOptionType))*
//    | 'SET' 'PASSWORD' ('FOR' user)? equal ( string replacePassword? retainCurrentPassword? | 'PASSWORD' '(' string ')' )
//    | 'SET' 'PASSWORD' ('FOR' user)? 'TO' 'RANDOM' replacePassword? retainCurrentPassword?

    | 'SHOW' 'DATABASES' like?
    | 'SHOW' ('FULL' | 'EXTENDED' 'FULL'?)? 'TABLES' inDb? like?
    | 'SHOW' 'FULL'? 'TRIGGERS' inDb? like?
    | 'SHOW' 'EVENTS' inDb? like?
    | 'SHOW' 'TABLE' 'STATUS' inDb? like?
    | 'SHOW' 'OPEN' 'TABLES' inDb? like?
    | 'SHOW' 'PARSE_TREE' statement
    | 'SHOW' 'PLUGINS'
    | 'SHOW' 'ENGINE' name ('LOGS' | 'MUTEX' | 'STATUS')
    | 'SHOW' ('FULL' | 'EXTENDED' 'FULL'?)? 'COLUMNS' ('FROM' | 'IN') qname inDb? like?
    | 'SHOW' ('BINARY' | 'MASTER') 'LOGS'
    | 'SHOW' 'BINARY' 'LOG' 'STATUS'
    | 'SHOW' (replica 'HOSTS' | 'REPLICAS')
    | 'SHOW' 'BINLOG' 'EVENTS' ('IN' string)? ( 'FROM' INTEGER )? limit? channel?
    | 'SHOW' 'RELAYLOG' 'EVENTS' ('IN' string)? ( 'FROM' INTEGER )? limit? channel?
    | 'SHOW' 'EXTENDED'? ('INDEX' | 'INDEXES' | 'KEYS') ('FROM' | 'IN') qname inDb? where?
    | 'SHOW' 'STORAGE'? 'ENGINES'
    | 'SHOW' 'COUNT' '(' '*' ')' ('WARNINGS' | 'ERRORS')
    | 'SHOW' ('WARNINGS' | 'ERRORS') limit?
    | 'SHOW' 'PROFILES'
    | 'SHOW' 'PROFILE' (profileDefinition (',' profileDefinition)*)? ( 'FOR' 'QUERY' INTEGER )? limit?
    | 'SHOW' scope? 'STATUS' like?
    | 'SHOW' 'FULL'? 'PROCESSLIST'
    | 'SHOW' scope? 'VARIABLES' like?
    | 'SHOW' charset like?
    | 'SHOW' 'COLLATION' like?
    | 'SHOW' 'PRIVILEGES'
    | 'SHOW' 'GRANTS' ('FOR' user ('USING' user (',' user)*)?)?
    | 'SHOW' 'CREATE' ( 'DATABASE' | 'SCHEMA' ) notExists? name
    | 'SHOW' 'CREATE' 'TABLE' qname
    | 'SHOW' 'CREATE' 'VIEW' qname
    | 'SHOW' 'MASTER' 'STATUS'
    | 'SHOW' replica 'STATUS' channel?
    | 'SHOW' 'CREATE' 'PROCEDURE' qname
    | 'SHOW' 'CREATE' 'FUNCTION' qname
    | 'SHOW' 'CREATE' 'TRIGGER' qname
    | 'SHOW' 'CREATE' 'PROCEDURE' 'STATUS' like?
    | 'SHOW' 'CREATE' 'FUNCTION' 'STATUS' like?
    | 'SHOW' 'CREATE' 'PROCEDURE' 'CODE' qname
    | 'SHOW' 'CREATE' 'FUNCTION' 'CODE' qname
    | 'SHOW' 'CREATE' 'EVENT' qname
    | 'SHOW' 'CREATE' 'USER' user
    | 'CREATE' 'RESOURCE' 'GROUP' name 'TYPE' equal? ( 'USER' | 'SYSTEM' ) resourceGroupVcpuList? resourceGroupPriority? resourceGroupEnableDisable?
    | 'ALTER' 'RESOURCE' 'GROUP' name resourceGroupVcpuList? resourceGroupPriority? resourceGroupEnableDisable? 'FORCE'?
    | 'SET' 'RESOURCE' 'GROUP' name ('FOR' INTEGER (','? INTEGER)*)?
    | 'DROP' 'RESOURCE' 'GROUP' name 'FORCE'?
    | 'BINLOG' string
    | 'CACHE' 'INDEX' keyCacheListOrParts 'IN' name
    | 'FLUSH' noLogging? ( flushTables | flushOption (',' flushOption)* )
    | 'KILL' ('CONNECTION' | 'QUERY')? term
    | 'LOAD' 'INDEX' 'INTO' 'CACHE' preloadTail
    | 'SHUTDOWN'

    | ('EXPLAIN' | 'DESCRIBE' | 'DESC') qname ( string | qname )?
    | ('EXPLAIN' | 'DESCRIBE' | 'DESC') explainOptions? ( 'FOR' 'DATABASE' name )? explainableStatement
    | 'HELP' name
    | 'USE' name
    | 'RESTART'
    | 'GET' ('CURRENT' | 'STACKED')? 'DIAGNOSTICS' ( statementInformationItem (',' statementInformationItem)* | 'CONDITION' literal conditionInformationItem ( ',' conditionInformationItem )* )
    | ( 'SIGNAL' signalCondition | 'RESIGNAL' signalCondition? ) ( 'SET' signalItem (',' signalItem)* )?
    ;

setVariable : ( scope? qname | LOCAL | GLOBAL ) equal term ;

signalCondition
    : name
    | 'SQLSTATE' 'VALUE'? string
    ;

alterLogfileGroupOptions
    : ('INITIAL_SIZE' '='? byteSize | 'STORAGE'? 'ENGINE' '='? name | ('WAIT' | 'NO_WAIT')) (','? ('INITIAL_SIZE' '='? byteSize | 'STORAGE'? 'ENGINE' '='? name | ('WAIT' | 'NO_WAIT')))* ;

alterTableActions
    : alterCommandList (partitionBy | removePartitioning)?
    | partitionBy
    | removePartitioning
    | (alterCommandsModifierList ',')? standaloneAlterCommands
    ;

alterCommandList
    : alterCommandsModifierList
    | (alterCommandsModifierList ',')? (alterListItem | tableOption+) ( ',' ( alterListItem | alterCommandsModifier | tableOption+ ) )*
    ;

alterCommandsModifierList
    : alterCommandsModifier (',' alterCommandsModifier)*
    ;

standaloneAlterCommands
    : 'DISCARD' 'TABLESPACE'
    | 'IMPORT' 'TABLESPACE'
    | 'ADD' 'PARTITION' noLogging? ( '(' partitionDef (',' partitionDef)* ')' | 'PARTITIONS' INTEGER )
    | 'DROP' 'PARTITION' name (',' name)*
    | 'REBUILD' 'PARTITION' noLogging? allOrPartitionNameList
    | 'OPTIMIZE' 'PARTITION' noLogging? allOrPartitionNameList noLogging?
    | 'ANALYZE' 'PARTITION' noLogging? allOrPartitionNameList
    | 'CHECK' 'PARTITION' allOrPartitionNameList checkOption*
    | 'REPAIR' 'PARTITION' noLogging? allOrPartitionNameList repairType*
    | 'COALESCE' 'PARTITION' noLogging? INTEGER
    | 'TRUNCATE' 'PARTITION' allOrPartitionNameList
    | 'REORGANIZE' 'PARTITION' noLogging? ( name (',' name)* 'INTO' '(' partitionDef (',' partitionDef)* ')' )?
    | 'EXCHANGE' 'PARTITION' name 'WITH' 'TABLE' qname ('WITH' | 'WITHOUT') 'VALIDATION'?
    | 'DISCARD' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    | 'IMPORT' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    | 'SECONDARY_LOAD'
    | 'SECONDARY_UNLOAD'
    ;

alterCommandsModifier
    : 'ALGORITHM' '='? name
    | 'LOCK' '='? name
    | ('WITH' | 'WITHOUT') 'VALIDATION'
    ;

alterListItem
    : 'ADD' 'COLUMN'? ( name fieldDefinition checkOrReferences? place? | '(' tableElementList ')' )
    | 'ADD' tableConstraintDef
    | 'CHANGE' 'COLUMN'? name name fieldDefinition place?
    | 'MODIFY' 'COLUMN'? name fieldDefinition place?
    | 'DROP' ( 'COLUMN'? name ('RESTRICT' | 'CASCADE')? | 'FOREIGN' 'KEY' name | 'PRIMARY' 'KEY' | keyOrIndex qname | 'CHECK' name | 'CONSTRAINT' name )
    | 'DISABLE' 'KEYS'
    | 'ENABLE' 'KEYS'
    | 'ALTER' 'COLUMN'? name ( 'SET' 'DEFAULT' ( '(' term ')' | literal ) | 'DROP' 'DEFAULT' | 'SET' visibility )
    | 'ALTER' 'INDEX' qname visibility
    | 'ALTER' 'CHECK' name constraintEnforcement
    | 'ALTER' 'CONSTRAINT' name constraintEnforcement
    | 'RENAME' 'COLUMN' name 'TO' name
    | 'RENAME' ('TO' | 'AS')? qname
    | 'RENAME' keyOrIndex qname 'TO' name
    | 'CONVERT' 'TO' charset collate?
    | 'FORCE'
    | 'ORDER' 'BY' name direction? (',' name direction?)*
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

undoTableSpaceOptions
    : 'STORAGE'? 'ENGINE' '='? name (','? 'STORAGE'? 'ENGINE' '='? name)*
    ;

alterTablespaceOptions
    : alterTablespaceOption (','? alterTablespaceOption)*
    ;

alterTablespaceOption
    : 'INITIAL_SIZE' '='? byteSize
    | 'AUTOEXTEND_SIZE' '='? byteSize
    | 'MAX_SIZE' '='? byteSize
    | 'STORAGE'? 'ENGINE' '='? name
    | ('WAIT' | 'NO_WAIT')
    | 'ENCRYPTION' '='? string
    | 'ENGINE' '='? string
    ;

viewCheckOption
    : 'WITH' ('CASCADED' | 'LOCAL')? 'CHECK' 'OPTION'
    ;

createDatabaseOption
    : 'DEFAULT'? ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) '='? name
    | 'DEFAULT'? 'COLLATE' '='? name
    | 'DEFAULT'? 'ENCRYPTION' '='? string
    ;

tableElementList
    : tableElement (',' tableElement)*
    ;

tableElement
    : name fieldDefinition checkOrReferences?
    | tableConstraintDef
    ;

storedRoutineBody
    : compoundStatement
    | 'AS' string
    ;

routineCreateOption
    : 'COMMENT' string
    | 'LANGUAGE' name
    | 'NO' 'SQL'
    | 'CONTAINS' 'SQL'
    | 'READS' 'SQL' 'DATA'
    | 'MODIFIES' 'SQL' 'DATA'
    | security
    | 'NOT'? 'DETERMINISTIC'
    ;

createIndex
    : ( 'UNIQUE' | 'FULLTEXT' | 'SPATIAL')? 'INDEX' name ('USING' ('BTREE' | 'HASH'))?
        'ON' qname '(' keyPart (',' keyPart)* ')'
        createIndexOption*
    ;

createIndexOption
    : 'KEY_BLOCK_SIZE' '='? INTEGER
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
    : 'KEY_BLOCK_SIZE' '='? INTEGER
    | 'COMMENT' string
    | visibility
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | ('USING' | 'TYPE') indexType
    ;



// TODO verify how this is used. there's overlap with
indexNameAndType
    : name ( 'TYPE' indexType )?
    | name? 'USING' indexType
    ;

logfileGroupOption
    : 'INITIAL_SIZE' '='? byteSize
    | ('UNDO_BUFFER_SIZE' | 'REDO_BUFFER_SIZE') '='? byteSize
    | 'NODEGROUP' '='? INTEGER
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
    | 'PORT' INTEGER
    ;

tablespaceOptions
    : tablespaceOption (','? tablespaceOption)*
    ;

tablespaceOption
    : 'INITIAL_SIZE' '='? byteSize
    | 'AUTOEXTEND_SIZE' '='? byteSize
    | 'MAX_SIZE' '='? byteSize
    | 'EXTENT_SIZE' '='? byteSize
    | 'NODEGROUP' '='? INTEGER
    | 'STORAGE'? 'ENGINE' '='? name
    | ('WAIT' | 'NO_WAIT')
    | 'COMMENT' '='? string
    | 'FILE_BLOCK_SIZE' '='? byteSize
    | 'ENCRYPTION' '='? string
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
    | 'ORGANIZATION' string 'IDENTIFIED' 'BY' INTEGER
    | 'DESCRIPTION' 'TEXT' string
    ;

dropLogfileGroupOption
    : ('WAIT' | 'NO_WAIT')
    | 'STORAGE'? 'ENGINE' '='? name
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
       'INTO'? qname usePartition?
       ( insertFromConstructor | 'SET' setter (',' setter)* | insertQueryExpression )
    ;


insert
    : 'INSERT' ('LOW_PRIORITY' | 'DELAYED' | 'HIGH_PRIORITY')?
      'IGNORE'?
      'INTO'? qname usePartition?
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

loadStatement
    : 'LOAD' ('DATA' | 'XML') ('LOW_PRIORITY' | 'CONCURRENT')?
      'FROM'? 'LOCAL'? ('INFILE' | ('URL' | 'S3'))? string ('COUNT' INTEGER | ID INTEGER)?
      ('IN' 'PRIMARY' 'KEY' 'ORDER')?
      ( 'REPLACE' | 'IGNORE' )?
      'INTO' 'TABLE' qname usePartition? charset? ('ROWS' 'IDENTIFIED' 'BY' string)?
      fieldsClause? linesClause?
      ('IGNORE' INTEGER ('LINES' | 'ROWS'))?
      ('(' (name ( ',' name )*)? ')')?
      ( 'SET' setter (',' setter)* )? ('PARALLEL' '=' INTEGER)? ('MEMORY' '=' byteSize)? ('ALGORITHM' '=' 'BULK')?
    ;


select
    : with? selectCore ( ( 'UNION' | 'EXCEPT' | 'INTERSECT' ) ('DISTINCT' | 'ALL')? selectCore )*
      orderBy? limit? /* into? */ locking? into?
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
    : 'LIMIT' literal ((',' | 'OFFSET') literal)?
    ;

limitCount
    : 'LIMIT' INTEGER
    ;

into
    : 'INTO'
        ( 'OUTFILE' string charset? fieldsClause? linesClause?
        | 'DUMPFILE' string
        | name ( ',' name )*
        | LOCAL ( ',' LOCAL )*
        )
    ;

//procedureAnalyseClause
//    : 'PROCEDURE' '(' (INT_NUMBER (',' INT_NUMBER)?)? ')'
//    ;

having
    : 'HAVING' term
    ;

qualify
    : 'QUALIFY' term
    ;

window
    : 'WINDOW' windowDefinition (',' windowDefinition)*
    ;

windowDefinition
    : name 'AS' windowSpec
    ;

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
    : 'UNBOUNDED' 'PRECEDING'
    | INTEGER 'PRECEDING'
    | PARAM 'PRECEDING'
    | 'INTERVAL' term interval 'PRECEDING'
    | 'CURRENT' 'ROW'
    ;

windowFrameBound
    : windowFrameStart
    | 'UNBOUNDED' 'FOLLOWING'
    | INTEGER 'FOLLOWING'
    | PARAM 'FOLLOWING'
    | 'INTERVAL' term interval 'FOLLOWING'
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

direction
    : 'ASC' | 'DESC' ;

from
    : 'FROM' ('DUAL' | tables )
    ;

tableReferenceList
    : tables (',' tables)*
    ;


tables
//      // ODBC syntax
//      | '{' ( name | 'OJ' ) tableFactor joinedTable* '}'

    : tables ',' tables
    | tables (('INNER' | 'CROSS')? 'JOIN' | 'STRAIGHT_JOIN') tables ( 'ON' term | 'USING' '(' name (',' name)* ')' )?
    | tables ('LEFT' | 'RIGHT') 'OUTER'? 'JOIN' tables ( 'ON' term | 'USING' '(' name (',' name)* ')' )
    | tables ('NATURAL' 'INNER'? 'JOIN' | 'NATURAL' ('LEFT' | 'RIGHT') 'OUTER'? 'JOIN' ) tables
    | qname usePartition? tableAlias? (indexHint (',' indexHint)*)? ('TABLESAMPLE' ('SYSTEM' | 'BERNOULLI') '(' literal ')')?
    | 'JSON_TABLE' '(' term ',' string jsonColumns ')' tableAlias?
    | 'LATERAL'? '(' select ')' tableAlias? columns?
    | '(' tables ')'
    ;

locking
    : 'FOR' ( 'UPDATE' | 'SHARE' ) ('OF' qname (',' qname)*)? ( 'SKIP' 'LOCKED' | 'NOWAIT' )?
    | 'LOCK' 'IN' 'SHARE' 'MODE'
    ;


item
    : '*'
    | qname ( '.'  '*' )?
    | term alias?
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
    : 'AS'? name
    ;

indexHint
    : ('FORCE' | 'IGNORE' | 'USE' ) keyOrIndex indexHintClause? '(' name (',' name)* ')'
    ;

keyOrIndex
    : 'KEY'
    | 'INDEX'
    ;

indexHintClause
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
    : string (',' string (',' INTEGER)?)?
    ;

resetOption
    : ('MASTER' | 'BINARY' 'LOGS' 'AND' 'GTIDS') ('TO' INTEGER)?
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
    | ('MASTER_PORT' | 'SOURCE_PORT') '=' INTEGER
    | ('MASTER_CONNECT_RETRY' | 'SOURCE_CONNECT_RETRY') '=' INTEGER
    | ('MASTER_RETRY_COUNT' | 'SOURCE_RETRY_COUNT') '=' INTEGER
    | ('MASTER_DELAY' | 'SOURCE_DELAY') '=' INTEGER
    | ('MASTER_SSL' | 'SOURCE_SSL') '=' INTEGER
    | ('MASTER_SSL_CA' | 'SOURCE_SSL_CA') '=' string
    | ('MASTER_SSL_CAPATH' | 'SOURCE_SSL_CAPATH') '=' string
    | ('MASTER_TLS_VERSION' | 'SOURCE_TLS_VERSION') '=' string
    | ('MASTER_SSL_CERT' | 'SOURCE_SSL_CERT') '=' string
    | ('MASTER_TLS_CIPHERSUITES' | 'SOURCE_TLS_CIPHERSUITES') '=' name
    | ('MASTER_SSL_CIPHER' | 'SOURCE_SSL_CIPHER') '=' string
    | ('MASTER_SSL_KEY' | 'SOURCE_SSL_KEY') '=' string
    | ('MASTER_SSL_VERIFY_SERVER_CERT' | 'SOURCE_SSL_VERIFY_SERVER_CERT') '=' INTEGER
    | ('MASTER_SSL_CRL' | 'SOURCE_SSL_CRL') '=' string
    | ('MASTER_SSL_CRLPATH' | 'SOURCE_SSL_CRLPATH') '=' string
    | ('MASTER_PUBLIC_KEY_PATH' | 'SOURCE_PUBLIC_KEY_PATH') '=' string
    | ('GET_MASTER_PUBLIC_KEY' | 'GET_SOURCE_PUBLIC_KEY') '=' INTEGER
    | ('MASTER_HEARTBEAT_PERIOD' | 'SOURCE_HEARTBEAT_PERIOD') '=' INTEGER
    | 'IGNORE_SERVER_IDS' '=' '(' (INTEGER (',' INTEGER)*)? ')'
    | ('MASTER_COMPRESSION_ALGORITHM' | 'SOURCE_COMPRESSION_ALGORITHM') '=' string
    | ('MASTER_ZSTD_COMPRESSION_LEVEL' | 'SOURCE_ZSTD_COMPRESSION_LEVEL') '=' INTEGER
    | ('MASTER_AUTO_POSITION' | 'SOURCE_AUTO_POSITION') '=' INTEGER
    | 'PRIVILEGE_CHECKS_USER' '=' userName
    | 'REQUIRE_ROW_FORMAT' '=' INTEGER
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK' '=' ('STREAM' | 'ON' | 'OFF' | 'GENERATE')
    | 'SOURCE_CONNECTION_AUTO_FAILOVER' '=' INTEGER
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS' '=' ('OFF' | 'LOCAL' | string)
    | 'GTID_ONLY' '=' INTEGER
    | sourceFileDef
    ;

sourceFileDef
    : ('MASTER_LOG_FILE' | 'SOURCE_LOG_FILE') '=' string
    | ('MASTER_LOG_POS' | 'SOURCE_LOG_POS') '=' INTEGER
    | 'RELAY_LOG_FILE' '=' string
    | 'RELAY_LOG_POS' '=' INTEGER
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
    : ( sourceFileDef | ('SQL_BEFORE_GTIDS' | 'SQL_AFTER_GTIDS') '=' string | 'SQL_AFTER_MTS_GAPS' ) (',' sourceFileDef)*
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
    : 'SLAVE' | 'REPLICA'
    ;

ssl
    : 'REQUIRE' 'NO'? 'SSL'
    ;


alterUser
    : oldAlterUser
    | user
        ( 'IDENTIFIED' 'BY' string ( 'REPLACE' string retainCurrentPassword? | retainCurrentPassword? )
        | 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD' ( retainCurrentPassword? | 'REPLACE' string retainCurrentPassword? )
        | 'IDENTIFIED' 'WITH' name
        | 'IDENTIFIED' 'WITH' name 'AS' string retainCurrentPassword?
        | 'IDENTIFIED' 'WITH' name 'BY' string ( 'REPLACE' string retainCurrentPassword? | retainCurrentPassword? )
        | 'IDENTIFIED' 'WITH' name 'BY' 'RANDOM' 'PASSWORD' retainCurrentPassword?
        | discardOldPassword?
        | 'ADD' factor identification ('ADD' factor identification)?
        | 'MODIFY' factor identification ( 'MODIFY' factor identification )?
        | 'DROP' factor ('DROP' factor)?
        )
    ;

oldAlterUser
    : user 'IDENTIFIED' 'BY'
        ( string 'REPLACE' string retainCurrentPassword?
        | string retainCurrentPassword?
        | 'RANDOM' 'PASSWORD' ('REPLACE' string)? retainCurrentPassword?
        )
    | user 'IDENTIFIED' 'WITH' (
        name (
            'BY' string 'REPLACE' string retainCurrentPassword?
            | 'AS' string retainCurrentPassword?
            | 'BY' string retainCurrentPassword?
            | 'BY' 'RANDOM' 'PASSWORD' retainCurrentPassword?
        )?
    )
    | user discardOldPassword?
    ;

userFunction
    : 'USER' '(' ')'
    ;

createUserTail
    : requireClause? connectOptions? accountLockPasswordExpireOptions* ('ATTRIBUTE' string | 'COMMENT' string)?
    ;

requireClause
    : 'REQUIRE'
        ( requireListElement ('AND'? requireListElement)*
        | ('SSL' | 'X509' | 'NONE')
        )
    ;

connectOptions
    : 'WITH'
        ( 'MAX_QUERIES_PER_HOUR' INTEGER
        | 'MAX_UPDATES_PER_HOUR' INTEGER
        | 'MAX_CONNECTIONS_PER_HOUR' INTEGER
        | 'MAX_USER_CONNECTIONS' INTEGER
    )+
    ;

accountLockPasswordExpireOptions
    : 'ACCOUNT' ('LOCK' | 'UNLOCK')
    | 'PASSWORD'
        ( 'EXPIRE'
            ( 'INTERVAL' INTEGER 'DAY'
            | 'NEVER'
            | 'DEFAULT'
            )?
        | 'HISTORY' (INTEGER | 'DEFAULT')
        | 'REUSE' 'INTERVAL' ( INTEGER 'DAY' | 'DEFAULT' )
        | 'REQUIRE' 'CURRENT' ( 'DEFAULT' | 'OPTIONAL' )?
        )
    | 'FAILED_LOGIN_ATTEMPTS' INTEGER
    | 'PASSWORD_LOCK_TIME' (INTEGER | 'UNBOUNDED')
    ;

dropUserStatement
    : 'DROP' 'USER' exists? user (',' user)*
    ;

grantStatement
    : 'GRANT' roleOrPrivilegesList 'TO' user (',' user)* ( 'WITH' 'ADMIN' 'OPTION' )?
    | 'GRANT' (roleOrPrivilegesList | 'ALL' 'PRIVILEGES'?) 'ON' aclType? grantIdentifier 'TO' grantTargetList requireClause? grantOptions? ('AS' 'USER' withRoles?)?
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

renameUserStatement
    : 'RENAME' 'USER' user 'TO' user ( ',' user 'TO' user )*
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
        ignoreUnknownUser?
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
    : ( name columns? | name name )
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

requireListElement
    : ('CIPHER' | 'ISSUER' | 'SUBJECT') string
    ;

grantOption
    : 'GRANT' 'OPTION'
    | ( 'MAX_QUERIES_PER_HOUR' | 'MAX_UPDATES_PER_HOUR' | 'MAX_CONNECTIONS_PER_HOUR' | 'MAX_USER_CONNECTIONS' ) INTEGER
    ;

setRoleStatement
    : 'SET' 'ROLE' roleList
    | 'SET' 'ROLE' ('NONE' | 'DEFAULT')
    | 'SET' 'DEFAULT' 'ROLE' (roleList | 'NONE' | 'ALL') 'TO' roleList
    | 'SET' 'ROLE' 'ALL' ('EXCEPT' roleList)?
    ;

roleList
    : userName (',' userName)*
    ;

histogram
    : 'UPDATE' 'HISTOGRAM' 'ON' name (',' name)*
        (('WITH' INTEGER 'BUCKETS')? (('MANUAL' | 'AUTO')? 'UPDATE')?
        | 'USING' 'DATA' string
        )?
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

// TODO replace w/ setter
installSetValue
    : ('GLOBAL' | 'PERSIST') 'DEFAULT'? qname equal term
    ;


transactionCharacteristics
    : 'READ' ('WRITE' | 'ONLY') ('ISOLATION' 'LEVEL'
        ( 'REPEATABLE' 'READ'
        | 'READ' ('COMMITTED' | 'UNCOMMITTED')
        | 'SERIALIZABLE'
        ))?
    | 'ISOLATION' 'LEVEL'
        ( 'REPEATABLE' 'READ'
        | 'READ' ('COMMITTED' | 'UNCOMMITTED')
        | 'SERIALIZABLE'
        ) (',' 'READ' ('WRITE' | 'ONLY'))?
    ;

optionValueNoOptionType
    : 'DEFAULT'? qname equal term
    | charset
//    | name equal expr
//    | qname equal term
    | 'NAMES' ( equal term | name collate? | 'DEFAULT' )
    ;


inDb
    : ('FROM' | 'IN') name
    ;

profileDefinition
    : 'BLOCK' 'IO'
    | 'CONTEXT' 'SWITCHES'
    | 'PAGE' 'FAULTS'
    | ( 'ALL' | 'CPU' | 'IPC' | 'MEMORY' | 'SOURCE' | 'SWAPS' )
    ;

keyCacheListOrParts
    : assignToKeycache (',' assignToKeycache)*
    | qname 'PARTITION' '(' allOrPartitionNameList ')' cacheKeyList?
    ;

assignToKeycache
    : qname cacheKeyList?
    ;

cacheKeyList
    : keyOrIndex '(' (name (',' name)*)? ')'
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
      | name (',' name)* ('FOR' 'EXPORT' | 'WITH' 'READ' 'LOCK')?
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
    : 'VCPU' equal? vcpuNumOrRange (','? vcpuNumOrRange)*
    ;

vcpuNumOrRange
    : INTEGER ('-' INTEGER)?
    ;

resourceGroupPriority
    : 'THREAD_PRIORITY' equal? INTEGER
    ;

resourceGroupEnableDisable
    : 'ENABLE'
    | 'DISABLE'
    ;

explainOptions
    : 'FORMAT' '=' name ( 'INTO' '@' name )?
    | 'EXTENDED'
    | 'ANALYZE'
    | 'ANALYZE' 'FORMAT' '=' name
    ;

explainableStatement
    : select
    | delete
    | insert
    | replace
    | updateStatement
    | 'FOR' 'CONNECTION' INTEGER
    ;

term
    : qname
    | term ( '->' | '->>' ) string
    | literal
    | term 'AT' 'LOCAL'
    | 'INTERVAL' term interval
    | 'BINARY' term
    | 'CAST' '(' term 'AS' castType 'ARRAY'? ')'
    | 'CAST' '(' term 'AT' 'TIME' 'ZONE' 'INTERVAL'? string 'AS' 'DATETIME' typeDatetimePrecision ')'
    | 'CONVERT' '(' term ',' castType ')'
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
    | term compOp term

    | function
    | sumExpr over?
    | windowFunctionCall
    | 'GROUPING' terms
    | term 'CONCAT_PIPES' term
    | '{' name term '}'
    | 'MATCH' (qname (',' qname)* | '(' qname (',' qname)* ')') 'AGAINST' '(' term fulltextOptions? ')'
    | 'DEFAULT' '(' qname ')'
//    | 'VALUES' '(' qname ')'

    | term 'IS' 'NOT'? ('TRUE' | 'FALSE' | 'UNKNOWN' | 'NULL')
    | term 'NOT'? 'LIKE' term ('ESCAPE' term)?
    | term 'NOT'? ( 'REGEXP' | 'RLIKE' ) term
    | term 'NOT'? 'IN' ('(' select ')' | terms )
    | term 'MEMBER' 'OF'? '(' literal ')'
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

compOp
    : '=' | '!=' | '<>' | '<=>' | '>=' | '>' | '<=' | '<' ;

sumExpr
    : 'AVG' '(' 'DISTINCT'? 'ALL'? term ')'
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

windowFunctionCall
    : ( 'ROW_NUMBER' | 'RANK' | 'DENSE_RANK' | 'CUME_DIST' | 'PERCENT_RANK' ) '(' ')' over
    | 'NTILE' ( '(' INTEGER ')' | '(' term ')' ) over
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
    : 'CHAR' '(' term (',' term)* ('USING' name)? ')'
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
    | userFunction
    | 'VALUES' '(' term ')'
    | 'YEAR' '(' term ')'

    // Function names that are not keywords.
    | ('ADDDATE' | 'SUBDATE') '(' term ',' ( term | 'INTERVAL' term interval ) ')'
    | 'CURDATE' ('(' ')')?
    | 'CURTIME' ('(' (INTEGER)? ')')?
    | ('DATE_ADD' | 'DATE_SUB') '(' term ',' 'INTERVAL' term interval ')'
    | 'EXTRACT' '(' interval 'FROM' term ')'
    | 'GET_FORMAT' '(' ('DATE' | 'TIME' | 'DATETIME' | 'TIMESTAMP') ',' term ')'
    | 'LOG' '(' term ( ',' term )? ')'
    | now
    | 'POSITION' '(' term 'IN' term ')'
    | 'SUBSTRING' '(' term ( ',' term (',' term)? | 'FROM' term ('FOR' term)? ) ')'
    | 'SYSDATE' ('(' (INTEGER)? ')')?
    | ('TIMESTAMPADD' | 'TIMESTAMPDIFF') '(' intervalTimeStamp ',' term ',' term ')'
    | 'UTC_DATE' ('(' ')')?
    | 'UTC_TIME' ('(' (INTEGER)? ')')?
    | 'UTC_TIMESTAMP' ('(' (INTEGER)? ')')?

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
    | 'WEIGHT_STRING' '(' term ( 'AS' ( 'CHAR' | 'BINARY' ) '(' INTEGER ')' )? ')'
    | 'GEOMETRYCOLLECTION' '(' (term (',' term)*)? ')'
    | 'LINESTRING' '(' term (',' term)* ')'
    | 'MULTILINESTRING' '(' term (',' term)* ')'
    | 'MULTIPOINT' '(' term (',' term)* ')'
    | 'MULTIPOLYGON' '(' term (',' term)* ')'
    | 'POINT' '(' term ',' term ')'
    | 'POLYGON' '(' term (',' term)* ')'

    | ID '(' ( udfExpr ( ',' udfExpr )* )? ')'
    | qname '(' (term (',' term)* )? ')'

    ;

udfExpr
    : term alias?
    ;

castType
    : 'BINARY' fieldLength?
    | 'CHAR' fieldLength? charsetWithOptBinary?
    | ('NCHAR' | 'NATIONAL' 'CHAR') fieldLength?
    | 'SIGNED' ( 'INT' | 'INTEGER' )?
    | 'UNSIGNED' ( 'INT' | 'INTEGER' )?
    | 'DATE'
    | 'YEAR'
    | 'TIME' typeDatetimePrecision?
    | 'DATETIME' typeDatetimePrecision?
    | ('DEC' | 'DECIMAL' ) floatOptions?
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
    ;

// TODO merge dataType and castType rules?
dataType
    : ( 'INT' | 'INTEGER' | 'TINYINT' | 'SMALLINT' | 'MEDIUMINT' | 'BIGINT' ) fieldLength? fieldOptions?
    | 'FLOAT4'
    | 'FLOAT8'
    | 'INT1'
    | 'INT2'
    | 'INT3'
    | 'INT4'
    | 'INT8'
    | 'MIDDLEINT'
    | ('REAL' | 'DOUBLE' 'PRECISION'?) floatOptions? fieldOptions?
    | ('FLOAT' | 'DECIMAL' | 'NUMERIC' | 'FIXED') floatOptions? fieldOptions?
    | 'BIT' fieldLength?
    | ('BOOL' | 'BOOLEAN')
    | ('NCHAR' | 'NATIONAL' 'CHAR') fieldLength? 'BINARY'?
    | 'BINARY' fieldLength?
    | (( 'CHAR' | 'CHARACTER' ) 'VARYING'? | 'VARCHAR' ) fieldLength? charsetWithOptBinary?
    | ( 'NATIONAL' 'VARCHAR' | 'NVARCHAR' | 'NCHAR' 'VARCHAR' | 'NATIONAL' 'CHAR' 'VARYING' | 'NCHAR' 'VARYING' ) fieldLength 'BINARY'?
    | 'VARBINARY' fieldLength?
    | 'YEAR' fieldLength? fieldOptions?
    | 'DATE'
    | 'TIME' typeDatetimePrecision?
    | 'TIMESTAMP' typeDatetimePrecision?
    | 'DATETIME' typeDatetimePrecision?
    | 'TINYBLOB'
    | 'BLOB' fieldLength?
    | 'MEDIUMBLOB'
    | 'LONGBLOB'
    | 'LONG' 'VARBINARY'
    | 'LONG' ('CHAR' 'VARYING' | 'VARCHAR')? charsetWithOptBinary?
    | 'TINYTEXT' charsetWithOptBinary?
    | 'TEXT' fieldLength? charsetWithOptBinary?
    | 'MEDIUMTEXT' charsetWithOptBinary?
    | 'LONGTEXT' charsetWithOptBinary?
    | 'ENUM' '(' string (',' string)* ')' charsetWithOptBinary?
    | 'SET' '(' string (',' string)* ')' charsetWithOptBinary?
    | 'SERIAL'
    | 'JSON'
    | 'GEOMETRY'
    | 'GEOMETRYCOLLECTION'
    | 'POINT'
    | 'MULTIPOINT'
    | 'LINESTRING'
    | 'MULTILINESTRING'
    | 'POLYGON'
    | 'MULTIPOLYGON'
    ;


charset
    : ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) name
    ;

// None of the microsecond variants can be used in schedules (e.g. events).
interval
    : intervalTimeStamp
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

intervalTimeStamp
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

orderExpression
    : term direction?
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
    : INTEGER
    | sqlstate
    ;

sqlstate
    : 'SQLSTATE' 'VALUE'? string
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
    | 'EVERY' term interval ('STARTS' term)? ('ENDS' term)?
    ;

checkOrReferences
    : checkConstraint
    | references
    ;

checkConstraint
    : 'CHECK' '(' term ')'
    ;

constraintEnforcement
    : 'NOT'? 'ENFORCED'
    ;

tableConstraintDef
    : keyOrIndex indexNameAndType? '(' keyPart (',' keyPart)* ')' indexOption*
    | 'FULLTEXT' keyOrIndex? name? '(' keyPart (',' keyPart)* ')' fulltextIndexOption*
    | 'SPATIAL' keyOrIndex? name? '(' keyPart (',' keyPart)* ')' commonIndexOption*
    | ('CONSTRAINT' name?)?
        ( ('PRIMARY' 'KEY' | 'UNIQUE' keyOrIndex?) indexNameAndType? '(' keyPart (',' keyPart)* ')' indexOption*
        | 'FOREIGN' 'KEY' name? '(' keyPart (',' keyPart)* ')' references
        | checkConstraint constraintEnforcement?
        )
    ;

fieldDefinition
    : dataType
      ( collate? ( 'GENERATED' 'ALWAYS' )? 'AS' '(' term ')' ( 'VIRTUAL' | 'STORED' )? )?
      columnAttribute*
    ;

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
    | 'SRID' INTEGER
    | ('CONSTRAINT' name?)? checkConstraint
    | constraintEnforcement
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | visibility
    ;

now
    : ( 'NOW' | 'CURRENT_TIMESTAMP' | 'LOCALTIME' | 'LOCALTIMESTAMP' ) ( '(' INTEGER? ')' )?
    ;

references
    : 'REFERENCES' qname ('(' name (',' name)* ')')?
      ( 'MATCH' ('FULL' | 'PARTIAL' | 'SIMPLE') )?
        ( onUpdate onUpdate? )?
    ;

onUpdate
    : 'ON' ('UPDATE' | 'DELETE')
      ('RESTRICT' | 'CASCADE' | 'SET' null | 'SET' 'DEFAULT' | 'NO' 'ACTION')
    ;

keyPart
    : ( name fieldLength? | '(' term ')' ) direction?
    ;

indexType
    : 'BTREE' | 'RTREE' | 'HASH'
    ;


commonIndexOption
    : 'KEY_BLOCK_SIZE' '='? INTEGER
    | 'COMMENT' string
    | visibility
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    ;

fulltextIndexOption
    : commonIndexOption
    | 'WITH' 'PARSER' name
    ;


visibility
    : 'VISIBLE'
    | 'INVISIBLE'
    ;


fieldLength
    : '(' ( INTEGER | FLOAT ) ')'
    ;

fieldOptions
    : ('SIGNED' | 'UNSIGNED' | 'ZEROFILL')+
    ;

charsetWithOptBinary
    : ('ASCII' 'BINARY'? | 'BINARY' 'ASCII')
    | ('UNICODE' 'BINARY'? | 'BINARY' 'UNICODE')
    | 'BYTE'
    | charset 'BINARY'?
    | 'BINARY' charset?
    ;

typeDatetimePrecision
    : '(' INTEGER ')'
    ;

tableOption
    : 'AUTOEXTEND_SIZE' '='? byteSize
    | 'AUTO_INCREMENT' '='? INTEGER
    | 'AVG_ROW_LENGTH' '='? INTEGER
    | 'DEFAULT'? ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) '='? name
    | 'CHECKSUM' '='? INTEGER
    | 'DEFAULT'? 'COLLATE' '='? name
    | 'COMMENT' '='? string
    | 'COMPRESSION' '='? string
    | 'CONNECTION' '='? string
    | 'DATA' 'DIRECTORY' '='? string
    | 'INDEX' 'DIRECTORY' '='? string
    | 'DELAY_KEY_WRITE' '='? INTEGER
    | 'ENCRYPTION' '='? string
    | 'ENGINE' '='? name
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'INSERT_METHOD' '='? ( 'NO' | 'FIRST' | 'LAST' )
    | 'KEY_BLOCK_SIZE' '='? INTEGER
    | 'MAX_ROWS' '='? INTEGER
    | 'MIN_ROWS' '='? INTEGER
    | 'PACK_KEYS' '='? ternaryOption
    | 'PASSWORD' '='? string
    | 'ROW_FORMAT' '='? ( 'DEFAULT' | 'DYNAMIC' | 'FIXED' | 'COMPRESSED' | 'REDUNDANT' | 'COMPACT' )
    | 'START' 'TRANSACTION'
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | 'STATS_AUTO_RECALC' '='? ternaryOption
    | 'STATS_PERSISTENT' '='? ternaryOption
    | 'STATS_SAMPLE_PAGES' '='? INTEGER
    | 'TABLESPACE' '='? name
    | 'STORAGE' ('DISK' | 'MEMORY')
//    | 'SECONDARY_ENGINE' equal? name
    | 'UNION' '='? '(' qname (',' qname)* ')'
//    | 'TABLE_CHECKSUM' '='? INTEGER
    ;

ternaryOption
    : INTEGER
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
      ( 'PARTITIONS' INTEGER )?
      subpartitionBy?
      ('(' partitionDef (',' partitionDef)* ')')?
    ;

subpartitionBy
    : 'SUBPARTITION' 'BY' hash
      ('SUBPARTITIONS' INTEGER)?
    ;

hash
    : 'LINEAR'?
      ( 'HASH' '(' term ')'
      | 'KEY' ('ALGORITHM' '=' INTEGER)? '(' ( name (',' name)* )? ')'
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
    | 'NODEGROUP' '='? INTEGER
    | ('MAX_ROWS' | 'MIN_ROWS') '='? INTEGER
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

ignoreUnknownUser
    : 'IGNORE' 'UNKNOWN' 'USER'
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
    : qname '=' term
    ;

fieldsClause
    : 'COLUMNS' fieldTerm+
    ;

fieldTerm
    : ( 'TERMINATED' | 'OPTIONALLY'? 'ENCLOSED' | 'ESCAPED' ) 'BY' string ;

linesClause
    : 'LINES' lineTerm+
    ;

lineTerm
    : ('TERMINATED' | 'STARTING') 'BY' string
    ;

createUser
    : user
        ( identification ('AND' identification ('AND' identification)?)?
        | 'IDENTIFIED' 'WITH' name ('INITIAL' 'AUTHENTICATION' ( 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD' | 'IDENTIFIED' 'WITH' name 'AS' string | 'IDENTIFIED' 'BY' string ))?
        | 'AND' identification ('AND' identification)?
        )?
    ;

identification
    : 'IDENTIFIED' 'BY' string
    | 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD'
    | 'IDENTIFIED' 'WITH' name
    | 'IDENTIFIED' 'WITH' name 'AS' string
    | 'IDENTIFIED' 'WITH' name 'BY' string
    | 'IDENTIFIED' 'WITH' name 'BY' 'RANDOM' 'PASSWORD'
    ;

retainCurrentPassword
    : 'RETAIN' 'CURRENT' 'PASSWORD'
    ;

discardOldPassword
    : 'DISCARD' 'OLD' 'PASSWORD'
    ;

userRegistration
    : factor 'INITIATE' 'REGISTRATION'
    | factor 'UNREGISTER'
    | factor 'FINISH' 'REGISTRATION' 'SET' 'CHALLENGE_RESPONSE' 'AS' string
    ;

factor
    : INTEGER 'FACTOR'
    ;

replacePassword
    : 'REPLACE' string
    ;

user
    : userName
    | 'CURRENT_USER' ('(' ')')?
    ;

userName
    : ( string | ID ) LOCAL?
    ;

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

usePartition
    : 'PARTITION' '(' name (',' name)* ')'
    ;

columns
    : '(' name (',' name)* ')'
    ;

qname
      // weird reverse construction for [[database.]table.]column
    :  '.'? name ( '.' name ( '.' name )? )?
      // TODO would this way be better, worse?
//      (( '.'? name '.' )? name '.' )? name
    | LOCAL
    | GLOBAL
    ;

//signedLiteral
//    : literal
//    | ( '+' | '-' )? INTEGER
//    ;

literal
//    : name
    : ID
    | keyword
//    | string
    | CHARSET? STRING+
    | NATIONAL STRING*
    | BLOB
    | ( '+' | '-' )? INTEGER
    | ( '+' | '-' )? FLOAT
    | SIZE
    | datetime
    | null
    | PARAM
    | LOCAL
    | GLOBAL
    ;

string
    : CHARSET? STRING+
    | NATIONAL STRING*
    | BLOB
    ;

strings
    : string (',' string)*
    ;

null
    : 'NULL' | NOPE ;



datetime
    : ( 'DATE' | 'TIME' | 'TIMESTAMP' ) string ;

floatOptions
    : fieldLength
    | '(' INTEGER ',' INTEGER ')'
    ;

name
    : ID
    | keyword
    | string
    ;

byteSize
    : INTEGER | SIZE ;

equal
    : '='
    | ':='
    ;

scope
    : 'PERSIST'
    | 'PERSIST_ONLY'
    | 'GLOBAL'
    | 'LOCAL'
    | 'SESSION'
    ;

keyword
    : 	 'ACCOUNT'
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
      	| 'CONCAT_PIPES'
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
//      	| 'NOT2'
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

INTEGER options { caseInsensitive = false; }
    : DIGITS
    | '0x' BYTES+
    | '0b' [01]+
    ;

FLOAT
    : ( DIGITS ( '.' DIGITS? )? | '.' DIGITS ) ( 'E' [-+]? DIGITS )? ;

SIZE
    : DIGITS [KMGT] ;

ID
    : '"' ('\\'? .)*? '"'
    | '`' ( ~'`' | '``' )* '`'
    | [A-Z0-9$\u0080-\uFFFF] [A-Z0-9_$\u0080-\uFFFF]*
    ;

CHARSET
  : '_' [A-Z0-9$\u0080-\uFFFF]+ ;

LOCAL
    : '@' ( ID | STRING | IPV4 | IPV6 ) ;

GLOBAL
    : '@' '@' ( ID ( '.' ID )? )? ;

STRING
    : '\'' ('\\'? .)*? '\'' ;

NATIONAL
    : 'N' STRING ;

BLOB
    : 'x\'' BYTES '\''
    | 'b\'' [01]+ '\''
    ;

NOPE options { caseInsensitive = false; }
    : '\\N' ;

BLOCK_COMMENT
    : '/*' .*? '*/' -> channel(HIDDEN)
    ;

POUND_COMMENT
    : '#' ~[\n\r]* -> channel(HIDDEN)
    ;

COMMENT
    : '--' ([ \t] ~[\n\r]* | [\n\r] | EOF) -> channel(HIDDEN)
    ;

WHITESPACE
    : [ \t\f\r\n]+ -> channel(HIDDEN)
    ;

fragment IPV4 : DIGITS '.' DIGITS '.' DIGITS '.' DIGITS;

fragment IPV6 : GROUPS ( '::' GROUPS? )? ;

fragment GROUPS : GROUP ( ':' GROUP )* ;

fragment GROUP : BYTE BYTE BYTE BYTE ;

fragment DIGITS : [0-9]+ ;

fragment BYTES : BYTE+ ;

fragment BYTE : [0-9A-F] ;
