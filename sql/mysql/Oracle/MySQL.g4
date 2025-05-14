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
    : statement? ( ';' statement? )* EOF ;

// TODO: inlining all the statements for now. will re-refactor as needed.

statement
    // DDL
    : 'ALTER' onlineOption? 'TABLE' qname alterTableActions?
    | 'ALTER' 'DATABASE' name (createDatabaseOption | 'READ' 'ONLY' '='? ternaryOption)+
    | 'ALTER' 'PROCEDURE' qname routineCreateOption*
    | 'ALTER' 'FUNCTION' qname routineCreateOption*
    | 'ALTER' viewAlgorithm? definerClause? security? 'VIEW' qname columns? 'AS' select viewCheckOption?
    | 'ALTER' alterEvent
    | 'ALTER' 'TABLESPACE' name ( ('ADD' | 'DROP') 'DATAFILE' string alterTablespaceOptions? | 'RENAME' 'TO' name | alterTablespaceOptions )
    | 'ALTER' 'UNDO' 'TABLESPACE' name 'SET' ( 'ACTIVE' | 'INACTIVE' ) undoTableSpaceOptions?
    | 'ALTER' 'LOGFILE' 'GROUP' name 'ADD' 'UNDOFILE' string alterLogfileGroupOptions?
    | 'SERVER' name 'OPTIONS' '(' serverOption (',' serverOption)* ')'
    | 'ALTER' alterInstanceStatement
    | 'CREATE' 'DATABASE' ifNotExists? name createDatabaseOption*
    | 'CREATE' 'TEMPORARY'? 'TABLE' ifNotExists? qname ( ('(' tableElementList ')')? createTableOptionsEtc? | 'LIKE' qname | '(' 'LIKE' qname ')' )
    | 'CREATE' definerClause? 'FUNCTION' ifNotExists? qname '(' ( functionParameter (',' functionParameter)* )? ')' 'RETURNS' dataType collate? routineCreateOption* storedRoutineBody
    | 'CREATE' definerClause? 'PROCEDURE' ifNotExists? qname '(' ( procedureParameter (',' procedureParameter)* )? ')' routineCreateOption* storedRoutineBody
    | 'CREATE' 'AGGREGATE'? 'FUNCTION' ifNotExists? name 'RETURNS' ( 'STRING' | 'INT' | 'REAL' | 'DECIMAL' ) 'SONAME' string
    | 'CREATE' 'LOGFILE' 'GROUP' name 'ADD' 'UNDOFILE' string logfileGroupOptions?
    | 'CREATE' viewReplaceOrAlgorithm? definerClause? security? 'VIEW' qname columns? 'AS' select viewCheckOption?
    | 'CREATE' definerClause? 'TRIGGER' ifNotExists? qname ( 'BEFORE' | 'AFTER' ) ('INSERT' | 'UPDATE' | 'DELETE') 'ON' qname 'FOR' 'EACH' 'ROW' ('FOLLOWS' | 'PRECEDES') name? compoundStatement
    | 'CREATE' createIndex
    | 'CREATE' 'SERVER' name 'FOREIGN' 'DATA' 'WRAPPER' name 'OPTIONS' '(' serverOption (',' serverOption)* ')'
    | 'CREATE' 'TABLESPACE' name ('ADD' 'DATAFILE' string)? ( 'USE' 'LOGFILE' 'GROUP' name )? tablespaceOptions?
    | 'CREATE' definerClause? 'EVENT' ifNotExists? qname 'ON' 'SCHEDULE' schedule ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )? ('ENABLE' | 'DISABLE' ('ON' replica)?)? ( 'COMMENT' string )? 'DO' compoundStatement
    | 'CREATE' 'ROLE' ifNotExists? roleList
    | 'CREATE' createSpatialReference
    | 'CREATE' 'UNDO' 'TABLESPACE' name 'ADD' 'DATAFILE' string undoTableSpaceOptions?
    | 'DROP' 'DATABASE' ifExists? name
    | 'DROP' 'EVENT' ifExists? qname
    | 'DROP' 'FUNCTION' ifExists? qname
    | 'DROP' 'PROCEDURE' ifExists? qname
    | 'DROP' onlineOption? 'INDEX' qname 'ON' qname indexLockAndAlgorithm?
    | 'DROP' 'LOGFILE' 'GROUP' name ( dropLogfileGroupOption (','? dropLogfileGroupOption)* )?
    | 'DROP' 'SERVER' ifExists? name
    | 'DROP' 'TEMPORARY'? ('TABLE' | 'TABLES') ifExists? qname (',' qname)* ( 'RESTRICT' | 'CASCADE' )?
    | 'DROP' 'TABLESPACE' name ( dropLogfileGroupOption (','? dropLogfileGroupOption)* )?
    | 'DROP' 'TRIGGER' ifExists? qname
    | 'DROP' 'VIEW' ifExists? qname (',' qname)* ('RESTRICT' | 'CASCADE')?
    | 'DROP' 'ROLE' ifExists? roleList
    | 'DROP' 'SPATIAL' 'REFERENCE' 'SYSTEM' ifExists? integer
    | 'DROP' 'UNDO' 'TABLESPACE' name undoTableSpaceOptions?
    | 'RENAME' ('TABLE' | 'TABLES') renamePair ( ',' renamePair )*
    | 'TRUNCATE' 'TABLE'? qname
    | 'IMPORT' 'TABLE' 'FROM' strings

    | 'CALL' qname ('(' (term (',' term)*)? ')')?
    | delete
    | 'DO' items
    | 'HANDLER' qname 'OPEN' tableAlias?
    | 'HANDLER' name ( 'CLOSE' | 'READ' handlerReadOrScan where? limit? )
    | insert
    | loadStatement
    | replace
    | select
    | updateStatement
    | 'START' 'TRANSACTION' ('WITH' 'CONSISTENT' 'SNAPSHOT' | transactionAccessMode )*
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
    | 'RESET' 'PERSIST' (ifExists 'DEFAULT'? qname)?
    | 'START' replica replicaThreadOptions? ('UNTIL' replicaUntil)? userOption? passwordOption? defaultAuthOption? pluginDirOption? channel?
    | 'STOP' replica replicaThreadOptions? channel?
    | 'CHANGE' 'REPLICATION' 'FILTER' filterDefinition ( ',' filterDefinition )* channel?
    | 'LOAD' ('DATA' | 'TABLE' qname) 'FROM' 'MASTER'
    | ('START' groupReplicationStartOptions? | 'STOP') 'GROUP_REPLICATION'
    | 'PREPARE' name 'FROM' (string | name)
    | 'EXECUTE' name ('USING' name ( ',' name )*)?
    | ('DEALLOCATE' | 'DROP') 'PREPARE' name

    | 'CLONE' 'LOCAL' 'DATA' 'DIRECTORY' equal? string
    | 'CLONE' 'REMOTE' ('FOR' 'REPLICATION')?
    | 'CLONE' 'INSTANCE' 'FROM' user ':' number 'IDENTIFIED' 'BY' string (ssl | 'DATA' 'DIRECTORY' equal? string ssl?)?

    | accountManagementStatement
    | tableAdministrationStatement
    | 'UNINSTALL' ( 'PLUGIN' name | 'COMPONENT' string (',' string)* )
    | 'INSTALL' 'PLUGIN' name 'SONAME' string
    | 'INSTALL' 'COMPONENT' strings ('SET' installSetValue ( ',' installSetValue )*)?
    | setStatement
    | 'SHOW' 'DATABASES' like?
    | 'SHOW' showCommandType? 'TABLES' inDb? like?
    | 'SHOW' 'FULL'? 'TRIGGERS' inDb? like?
    | 'SHOW' 'EVENTS' inDb? like?
    | 'SHOW' 'TABLE' 'STATUS' inDb? like?
    | 'SHOW' 'OPEN' 'TABLES' inDb? like?
    | 'SHOW' 'PARSE_TREE' statement
    | 'SHOW' 'PLUGINS'
    | 'SHOW' 'ENGINE' name 'LOGS'
    | 'SHOW' 'ENGINE' name 'MUTEX'
    | 'SHOW' 'ENGINE' name 'STATUS'
    | 'SHOW' showCommandType? 'COLUMNS' ('FROM' | 'IN') qname inDb? like?
    | 'SHOW' ('BINARY' | 'MASTER') 'LOGS'
    | 'SHOW' 'BINARY' 'LOG' 'STATUS'
    | 'SHOW' (replica 'HOSTS' | 'REPLICAS')
    | 'SHOW' 'BINLOG' 'EVENTS' ('IN' string)? ( 'FROM' number )? limit? channel?
    | 'SHOW' 'RELAYLOG' 'EVENTS' ('IN' string)? ( 'FROM' number )? limit? channel?
    | 'SHOW' 'EXTENDED'? ('INDEX' | 'INDEXES' | 'KEYS') fromOrIn qname inDb? where?
    | 'SHOW' 'STORAGE'? 'ENGINES'
    | 'SHOW' 'COUNT' '(' '*' ')' 'WARNINGS'
    | 'SHOW' 'COUNT' '(' '*' ')' 'ERRORS'
    | 'SHOW' 'WARNINGS' limit?
    | 'SHOW' 'ERRORS' limit?
    | 'SHOW' 'PROFILES'
    | 'SHOW' 'PROFILE' profileDefinitions? ( 'FOR' 'QUERY' NUMBER )? limit?
    | 'SHOW' scope? 'STATUS' like?
    | 'SHOW' 'FULL'? 'PROCESSLIST'
    | 'SHOW' scope? 'VARIABLES' like?
    | 'SHOW' charset like?
    | 'SHOW' 'COLLATION' like?
    | 'SHOW' 'PRIVILEGES'
    | 'SHOW' 'GRANTS' ('FOR' user ('USING' user (',' user)*)?)?
    | 'SHOW' 'CREATE' 'DATABASE' ifNotExists? name
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
    | 'SET' 'RESOURCE' 'GROUP' name ('FOR' integer (','? integer)*)?
    | 'DROP' 'RESOURCE' 'GROUP' name 'FORCE'?
    | 'BINLOG' string
    | 'CACHE' 'INDEX' keyCacheListOrParts 'IN' name
    | 'FLUSH' noLogging? ( flushTables | flushOption (',' flushOption)* )
    | 'KILL' ('CONNECTION' | 'QUERY')? term
    | 'LOAD' 'INDEX' 'INTO' 'CACHE' preloadTail
    | 'SHUTDOWN'

    // MySQL utility statements
    | ('EXPLAIN' | 'DESCRIBE' | 'DESC') qname ( string | qname )?
    | ('EXPLAIN' | 'DESCRIBE' | 'DESC') explainOptions? ( 'FOR' 'DATABASE' name )? explainableStatement
    | 'HELP' name
    | 'USE' name
    | 'RESTART'
    | 'GET' ('CURRENT' | 'STACKED')? 'DIAGNOSTICS' ( statementInformationItem (',' statementInformationItem)* | 'CONDITION' literal conditionInformationItem ( ',' conditionInformationItem )* )
    | ( 'SIGNAL' signalCondition | 'RESIGNAL' signalCondition? ) ( 'SET' signalItem (',' signalItem)* )?
    ;

signalCondition
    : name
    | 'SQLSTATE' 'VALUE'? string
    ;

alterEvent
    : definerClause? 'EVENT' qname ('ON' 'SCHEDULE' schedule)?
    ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )?
    ('RENAME' 'TO' name)?
    ( 'ENABLE' | 'DISABLE' ('ON' replica)? )?
    ('COMMENT' string)? ('DO' compoundStatement)?
    ;

alterLogfileGroupOptions
    : (initialSize | tsOptionEngine | tsOptionWait) (','? (initialSize | tsOptionEngine | tsOptionWait))* ;

alterTableActions
    : alterCommandList (partitionClause | removePartitioning)?
    | partitionClause
    | removePartitioning
    | (alterCommandsModifierList ',')? standaloneAlterCommands
    ;

alterCommandList
    : alterCommandsModifierList
    | (alterCommandsModifierList ',')? (alterListItem | createTableOption+) ( ',' ( alterListItem | alterCommandsModifier | createTableOption+ ) )*
    ;

alterCommandsModifierList
    : alterCommandsModifier (',' alterCommandsModifier)*
    ;

standaloneAlterCommands
    : 'DISCARD' 'TABLESPACE'
    | 'IMPORT' 'TABLESPACE'
    | alterPartition
    | 'SECONDARY_LOAD'
    | 'SECONDARY_UNLOAD'
    ;

alterPartition
    : 'ADD' 'PARTITION' noLogging?
        ( '(' partition (',' partition)* ')'
        | 'PARTITIONS' integer
        )
    | 'DROP' 'PARTITION' name (',' name)*
    | 'REBUILD' 'PARTITION' noLogging? allOrPartitionNameList

    // yes, twice "no write to bin log".
    | 'OPTIMIZE' 'PARTITION' noLogging? allOrPartitionNameList noLogging?
    | 'ANALYZE' 'PARTITION' noLogging? allOrPartitionNameList
    | 'CHECK' 'PARTITION' allOrPartitionNameList checkOption*
    | 'REPAIR' 'PARTITION' noLogging? allOrPartitionNameList repairType*
    | 'COALESCE' 'PARTITION' noLogging? integer
    | 'TRUNCATE' 'PARTITION' allOrPartitionNameList
    | 'REORGANIZE' 'PARTITION' noLogging? ( name (',' name)* 'INTO' '(' partition (',' partition)* ')' )?
    | 'EXCHANGE' 'PARTITION' name 'WITH' 'TABLE' qname withValidation?
    | 'DISCARD' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    | 'IMPORT' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    ;

alterCommandsModifier
    : alterAlgorithmOption
    | alterLockOption
    | withValidation
    ;

alterListItem
    : 'ADD' 'COLUMN'? ( name fieldDefinition checkOrReferences? place? | '(' tableElementList ')' )
    | 'ADD' tableConstraintDef
    | 'CHANGE' 'COLUMN'? name name fieldDefinition place?
    | 'MODIFY' 'COLUMN'? name fieldDefinition place?
    | 'DROP' ( 'COLUMN'? name ('RESTRICT' | 'CASCADE')? | 'FOREIGN' 'KEY' name | 'PRIMARY' 'KEY' | keyOrIndex qname | 'CHECK' name | 'CONSTRAINT' name )
    | 'DISABLE' 'KEYS'
    | 'ENABLE' 'KEYS'
    | 'ALTER' 'COLUMN'? name ( 'SET' 'DEFAULT' ( '(' term ')' | signedLiteral ) | 'DROP' 'DEFAULT' | 'SET' visibility )
    | 'ALTER' 'INDEX' qname visibility
    | 'ALTER' 'CHECK' name constraintEnforcement
    | 'ALTER' 'CONSTRAINT' name constraintEnforcement
    | 'RENAME' 'COLUMN' name 'TO' name
    | 'RENAME' ('TO' | 'AS')? qname
    | 'RENAME' keyOrIndex qname 'TO' name
    | 'CONVERT' 'TO' charset name collate?
    | 'FORCE'
    | 'ORDER' 'BY' name direction? (',' name direction?)*
    ;

place
    : 'AFTER' name
    | 'FIRST'
    ;

alterAlgorithmOption
    : 'ALGORITHM' '='? name
    ;

alterLockOption
    : 'LOCK' '='? name
    ;

indexLockAndAlgorithm
    : alterAlgorithmOption alterLockOption?
    | alterLockOption alterAlgorithmOption?
    ;

withValidation
    : ('WITH' | 'WITHOUT') 'VALIDATION'
    ;

removePartitioning
    : 'REMOVE' 'PARTITIONING'
    ;

allOrPartitionNameList
    : 'ALL'
    | name (',' name)*
    ;

undoTableSpaceOptions
    : tsOptionEngine (','? tsOptionEngine)*
    ;

alterTablespaceOptions
    : alterTablespaceOption (','? alterTablespaceOption)*
    ;

alterTablespaceOption
    : initialSize
    | tsOptionAutoextendSize
    | tsOptionMaxSize
    | tsOptionEngine
    | tsOptionWait
    | tsOptionEncryption
    | tsOptionEngineAttribute
    ;

viewCheckOption
    : 'WITH' ('CASCADED' | 'LOCAL')? 'CHECK' 'OPTION'
    ;

alterInstanceStatement
    : 'INSTANCE' 'ROTATE' name 'MASTER' 'KEY'
    | 'RELOAD' 'TLS'
        ( 'NO' 'ROLLBACK' 'ON' 'ERROR'
        | 'FOR' 'CHANNEL' name ( 'NO' 'ROLLBACK' 'ON' 'ERROR' )?
        )
    | ('ENABLE' | 'DISABLE') name name
    | 'RELOAD' 'KEYRING'

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
    : columnDefinition
    | tableConstraintDef
    ;

duplicateAsQe
    : ('REPLACE' | 'IGNORE')? 'AS'? select
    ;

storedRoutineBody
    : compoundStatement
    | 'AS' (STRING | DOLLAR_QUOTED_STRING_TEXT)
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

//createIndex
//    : onlineOption?
//        ( 'UNIQUE'? 'INDEX' name indexTypeClause? createIndexTarget indexOption*
//        | 'FULLTEXT' 'INDEX' name createIndexTarget fulltextIndexOption*
//        | 'SPATIAL' 'INDEX' name createIndexTarget commonIndexOption*
//        )
//        indexLockAndAlgorithm?
//    ;

createIndex
    : ( 'UNIQUE' | 'FULLTEXT' | 'SPATIAL')? 'INDEX' name ('USING' ('BTREE' | 'HASH'))?
        'ON' qname '(' keyPart (',' keyPart)* ')'
        indexOption2*

        ( 'ALGORITHM' '='? name | 'LOCK' '='? name )?
    ;

    indexOption2
        : 'KEY_BLOCK_SIZE' '='? number
        | ('USING' ('BTREE' | 'HASH'))
        | 'WITH' 'PARSER' name
        | 'COMMENT' string
        | visibility
        | 'ENGINE_ATTRIBUTE' '='? string
        | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
        ;



// TODO verify how this is used. there's overlap with
indexNameAndType
    : name ( 'TYPE' indexType )?
    | name? 'USING' indexType
    ;

//createIndexTarget
//    : 'ON' qname '(' keyPart (',' keyPart)* ')'
//    ;

logfileGroupOptions
    : logfileGroupOption (','? logfileGroupOption)*
    ;

logfileGroupOption
    : initialSize
    | tsOptionUndoRedoBufferSize
    | tsOptionNodegroup
    | tsOptionEngine
    | tsOptionWait
    | tsOptionComment
    ;

serverOption
    : 'HOST' string
    | 'DATABASE' string
    | 'USER' string
    | 'PASSWORD' string
    | 'SOCKET' string
    | 'OWNER' string
    | 'PORT' number
    ;

tablespaceOptions
    : tablespaceOption (','? tablespaceOption)*
    ;

tablespaceOption
    : initialSize
    | tsOptionAutoextendSize
    | tsOptionMaxSize
    | tsOptionExtentSize
    | tsOptionNodegroup
    | tsOptionEngine
    | tsOptionWait
    | tsOptionComment
    | tsOptionFileblockSize
    | tsOptionEncryption
    ;

initialSize
    : 'INITIAL_SIZE' '='? sizeNumber
    ;

tsOptionUndoRedoBufferSize
    : ('UNDO_BUFFER_SIZE' | 'REDO_BUFFER_SIZE') '='? sizeNumber
    ;

tsOptionAutoextendSize
    : 'AUTOEXTEND_SIZE' '='? sizeNumber
    ;

tsOptionMaxSize
    : 'MAX_SIZE' '='? sizeNumber
    ;

tsOptionExtentSize
    : 'EXTENT_SIZE' '='? sizeNumber
    ;

tsOptionNodegroup
    : 'NODEGROUP' '='? integer
    ;

tsOptionEngine
    : 'STORAGE'? 'ENGINE' '='? name
    ;

tsOptionWait
    : 'WAIT' | 'NO_WAIT'
    ;

tsOptionComment
    : 'COMMENT' '='? string
    ;

tsOptionFileblockSize
    : 'FILE_BLOCK_SIZE' '='? sizeNumber
    ;

tsOptionEncryption
    : 'ENCRYPTION' '='? string
    ;

tsOptionEngineAttribute
    : 'ENGINE' '='? string
    ;

viewReplaceOrAlgorithm
    : 'OR' 'REPLACE' viewAlgorithm?
    | viewAlgorithm
    ;

viewAlgorithm
    : 'ALGORITHM' '=' ( 'UNDEFINED' | 'MERGE' | 'TEMPTABLE' )
    ;

security
    : 'SQL' 'SECURITY' ('DEFINER' | 'INVOKER')
    ;

createSpatialReference
    : 'OR' 'REPLACE' 'SPATIAL' 'REFERENCE' 'SYSTEM' integer srsAttribute*
    | 'SPATIAL' 'REFERENCE' 'SYSTEM' ifNotExists? integer srsAttribute*
    ;

srsAttribute
    : 'NAME' 'TEXT' string
    | 'DEFINITION' 'TEXT' string
    | 'ORGANIZATION' string 'IDENTIFIED' 'BY' integer
    | 'DESCRIPTION' 'TEXT' string
    ;

dropLogfileGroupOption
    : tsOptionWait
    | tsOptionEngine
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
        | ( '=' | '<' | '>' | '<=' | '>=' ) '(' terms ')'
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
    : ('(' (wild (',' wild)*)? ')')? ('VALUES' | 'VALUE') '(' terms? ')' ( ',' '(' terms? ')' )*
    ;

insertQueryExpression
    : with? selectCore orderBy? limit?
    | '(' select ')'
    | ('(' (wild (',' wild)*)? ')')? select
    ;

terms
    : term  (',' term )*
    ;

valuesReference
    : 'AS' name columns?
    ;

loadStatement
    : 'LOAD' ('DATA' | 'XML') ('LOW_PRIORITY' | 'CONCURRENT')?
      'FROM'? 'LOCAL'? ('INFILE' | ('URL' | 'S3'))? string ('COUNT' NUMBER | IDENTIFIER NUMBER)?
      ('IN' 'PRIMARY' 'KEY' 'ORDER')?
      ( 'REPLACE' | 'IGNORE' )?
      'INTO' 'TABLE' qname usePartition? charset? ('ROWS' 'IDENTIFIED' 'BY' string)?
      fieldsClause? linesClause?
      ('IGNORE' NUMBER ('LINES' | 'ROWS'))?
      ('(' (name ( ',' name )*)? ')')?
      ( 'SET' setter (',' setter)* )? ('PARALLEL' '=' NUMBER)? ('MEMORY' '=' sizeNumber)? ('ALGORITHM' '=' 'BULK')?
    ;


select
    : with? selectCore ( ( 'UNION' | 'EXCEPT' | 'INTERSECT' ) ('DISTINCT' | 'ALL')? selectCore )*
      orderBy? limit? locking*
//    | selectStatementWithInto
    ;

selectCore
    : 'SELECT' unique? modifier* items into?
       from? where? groupBy? having? window? qualify?
    | 'VALUES' 'ROW' '(' terms? ')' (',' 'ROW' '(' terms? ')')*
    | 'TABLE' qname
    | '(' select ')'
    ;

unique
    : 'ALL' | 'DISTINCT' | 'DISTINCTROW' ;

modifier
    : 'HIGH_PRIORITY'
    | 'STRAIGHT_JOIN'
    | 'SQL_SMALL_RESULT'
    | 'SQL_BIG_RESULT'
    | 'SQL_BUFFER_RESULT'
    | 'SQL_CALC_FOUND_ROWS'
    | 'SQL_NO_CACHE'
    ;

//selectStatementWithInto
//    : '(' selectStatementWithInto ')'
//    | with? selectCore orderBy? limit? intoClause lockingClause*
//    | with? selectCore orderBy? limit? lockingClause+ intoClause
//    | '(' select ')' intoClause
//    ;

limit
    : 'LIMIT' literal ((',' | 'OFFSET') literal)?
    ;

limitCount
    : 'LIMIT' NUMBER
    ;

into
    : 'INTO'
        ( 'OUTFILE' string charset? fieldsClause? linesClause?
        | 'DUMPFILE' string
        | name ( ',' name )*
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
    | number 'PRECEDING'
    | PARAM 'PRECEDING'
    | 'INTERVAL' term interval 'PRECEDING'
    | 'CURRENT' 'ROW'
    ;

windowFrameBound
    : windowFrameStart
    | 'UNBOUNDED' 'FOLLOWING'
    | number 'FOLLOWING'
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
    | 'GROUP' 'BY' ( 'ROLLUP' | 'CUBE' ) '(' term (',' term)* ')'
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


// TODO inline items rule once wildcard is sorted out
items
    : (item | '*') (',' item)*
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
//    : ('AS' | '=')? name
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
    | 'LOW_PRIORITY'? 'WRITE' // low priority deprecated since 5.7
    ;

xid
    : string (',' string (',' number)?)?
    ;

resetOption
    : ('MASTER' | 'BINARY' 'LOGS' 'AND' 'GTIDS') ('TO' integer)?
    | replica 'ALL'? channel?
    ;

sourceDefinitions
    : sourceDefinition (',' sourceDefinition)*
    ;

sourceDefinition
    : ('MASTER_HOST'
    | 'SOURCE_HOST') '=' string
    | 'NETWORK_NAMESPACE' '=' string
    | ('MASTER_BIND'
    | 'SOURCE_BIND') '=' string
    | ('MASTER_USER'
    | 'SOURCE_USER') '=' string
    | ('MASTER_PASSWORD'
    | 'SOURCE_PASSWORD') '=' string
    | ('MASTER_PORT'
    | 'SOURCE_PORT') '=' number
    | ('MASTER_CONNECT_RETRY'
    | 'SOURCE_CONNECT_RETRY') '=' number
    | ('MASTER_RETRY_COUNT'
    | 'SOURCE_RETRY_COUNT') '=' number
    | ('MASTER_DELAY'
    | 'SOURCE_DELAY') '=' number
    | ('MASTER_SSL'
    | 'SOURCE_SSL') '=' number
    | ('MASTER_SSL_CA'
    | 'SOURCE_SSL_CA') '=' string
    | ('MASTER_SSL_CAPATH'
    | 'SOURCE_SSL_CAPATH') '=' string
    | ('MASTER_TLS_VERSION'
    | 'SOURCE_TLS_VERSION') '=' string
    | ('MASTER_SSL_CERT'
    | 'SOURCE_SSL_CERT') '=' string
    | ('MASTER_TLS_CIPHERSUITES'
    | 'SOURCE_TLS_CIPHERSUITES') '=' name
//    | 'SOURCE_TLS_CIPHERSUITES') '=' (string | 'NULL')
    | ('MASTER_SSL_CIPHER'
    | 'SOURCE_SSL_CIPHER') '=' string
    | ('MASTER_SSL_KEY'
    | 'SOURCE_SSL_KEY') '=' string
    | ('MASTER_SSL_VERIFY_SERVER_CERT'
    | 'SOURCE_SSL_VERIFY_SERVER_CERT') '=' number
    | ('MASTER_SSL_CRL'
    | 'SOURCE_SSL_CRL') '=' string
    | ('MASTER_SSL_CRLPATH'
    | 'SOURCE_SSL_CRLPATH') '=' string
    | ('MASTER_PUBLIC_KEY_PATH'
    | 'SOURCE_PUBLIC_KEY_PATH') '=' string
    | ('GET_MASTER_PUBLIC_KEY'
    | 'GET_SOURCE_PUBLIC_KEY') '=' number
    | ('MASTER_HEARTBEAT_PERIOD'
    | 'SOURCE_HEARTBEAT_PERIOD') '=' number
    | 'IGNORE_SERVER_IDS' '=' '(' (number (',' number)*)? ')'
    | ('MASTER_COMPRESSION_ALGORITHM'
    | 'SOURCE_COMPRESSION_ALGORITHM') '=' string
    | ('MASTER_ZSTD_COMPRESSION_LEVEL'
    | 'SOURCE_ZSTD_COMPRESSION_LEVEL') '=' number
    | ('MASTER_AUTO_POSITION'
    | 'SOURCE_AUTO_POSITION') '=' number
    | 'PRIVILEGE_CHECKS_USER' '=' userName
//    | 'PRIVILEGE_CHECKS_USER' '=' (userName | 'NULL')
    | 'REQUIRE_ROW_FORMAT' '=' number
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK' '=' ('STREAM' | 'ON' | 'OFF' | 'GENERATE')
    | 'SOURCE_CONNECTION_AUTO_FAILOVER' '=' integer
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS' '=' ('OFF' | 'LOCAL' | string)
    | 'GTID_ONLY' '=' integer
    | sourceFileDef
    ;

sourceFileDef
    : ('MASTER_LOG_FILE' | 'SOURCE_LOG_FILE') '=' string
    | ('MASTER_LOG_POS' | 'SOURCE_LOG_POS') '=' number
    | 'RELAY_LOG_FILE' '=' string
    | 'RELAY_LOG_POS' '=' number
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


// Note: SET PASSWORD is part of the SET statement.
accountManagementStatement
    : alterUserStatement
    | createUserStatement
    | dropUserStatement
    | grantStatement
    | renameUserStatement
    | revokeStatement
    | setRoleStatement
    ;

alterUserStatement
    : 'ALTER' 'USER' ifExists?
        ( ( createUser (',' createUser)* | alterUser (',' alterUser)* ) createUserTail
        | userFunction
            ( (identifiedByRandomPassword | identifiedByPassword) replacePassword? retainCurrentPassword?
            | 'DISCARD' 'OLD' 'PASSWORD'
            | userRegistration?
            )
        | user ( 'DEFAULT' 'ROLE' ('ALL' | 'NONE' | roleList) | userRegistration? )
        )
    ;

alterUser
    : oldAlterUser
    | user
        ( identifiedByPassword ( 'REPLACE' string retainCurrentPassword? | retainCurrentPassword? )
        | identifiedByRandomPassword ( retainCurrentPassword? | 'REPLACE' string retainCurrentPassword? )
        | identifiedWithPlugin
        | identifiedWithPluginAsAuth retainCurrentPassword?
        | identifiedWithPluginByPassword ( 'REPLACE' string retainCurrentPassword? | retainCurrentPassword? )
        | identifiedWithPluginByRandomPassword retainCurrentPassword?
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

createUserStatement
    : 'CREATE' 'USER' ifNotExists? createUser (',' createUser)* ('DEFAULT' 'ROLE' roleList)? createUserTail
    ;

createUserTail
    : requireClause? connectOptions? accountLockPasswordExpireOptions* userAttributes?
    ;

userAttributes
    : 'ATTRIBUTE' string
    | 'COMMENT' string
    ;

requireClause
    : 'REQUIRE'
        ( requireListElement ('AND'? requireListElement)*
        | ('SSL' | 'X509' | 'NONE')
        )
    ;

connectOptions
    : 'WITH' (
        'MAX_QUERIES_PER_HOUR' number
        | 'MAX_UPDATES_PER_HOUR' number
        | 'MAX_CONNECTIONS_PER_HOUR' number
        | 'MAX_USER_CONNECTIONS' number
    )+
    ;

accountLockPasswordExpireOptions
    : 'ACCOUNT' ('LOCK' | 'UNLOCK')
    | 'PASSWORD' (
        'EXPIRE' (
            'INTERVAL' integer 'DAY'
            | 'NEVER'
            | 'DEFAULT'
        )?
        | 'HISTORY' (integer | 'DEFAULT')
        | 'REUSE' 'INTERVAL' (
            integer 'DAY'
            | 'DEFAULT'
        )
        | 'REQUIRE' 'CURRENT' (
            'DEFAULT'
            | 'OPTIONAL'
        )?
    )
    | 'FAILED_LOGIN_ATTEMPTS' integer
    | 'PASSWORD_LOCK_TIME' (integer | 'UNBOUNDED')
    ;

//userAttribute
//    :
//    | 'ATTRIBUTE' textStringLiteral
//    | 'COMMENT' textStringLiteral
//    ;

dropUserStatement
    : 'DROP' 'USER' ifExists? user (',' user)*
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
    : 'REVOKE' ifExists?
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
    : '*' ('.' '*')?
    | name ('.' '*')?
    | qname
    | name '.' qname
    ;

requireListElement
    : ('CIPHER' | 'ISSUER' | 'SUBJECT') string
    ;

grantOption
    : 'GRANT' 'OPTION'
    | ( 'MAX_QUERIES_PER_HOUR' | 'MAX_UPDATES_PER_HOUR' | 'MAX_CONNECTIONS_PER_HOUR' | 'MAX_USER_CONNECTIONS' ) number
    ;

setRoleStatement
    : 'SET' 'ROLE' roleList
    | 'SET' 'ROLE' ('NONE' | 'DEFAULT')
    | 'SET' 'DEFAULT' 'ROLE' (roleList | 'NONE' | 'ALL') 'TO' roleList
    | 'SET' 'ROLE' 'ALL' ('EXCEPT' roleList)?
    ;

roleList
    : role (',' role)*
    ;

role
    : name name?
    ;

tableAdministrationStatement
    : 'ANALYZE' noLogging? 'TABLE' qname (',' qname)* histogram?
    | 'CHECK' 'TABLE' qname (',' qname)* checkOption*
    | 'CHECKSUM' 'TABLE' qname (',' qname)* ( 'QUICK' | 'EXTENDED' )?
    | 'OPTIMIZE' noLogging? 'TABLE' qname (',' qname)*
    | 'REPAIR' noLogging? 'TABLE' qname (',' qname)* repairType*
    ;

histogram
    : 'UPDATE' 'HISTOGRAM' 'ON' name (',' name)*
        (('WITH' NUMBER 'BUCKETS')? (('MANUAL' | 'AUTO')? 'UPDATE')?
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


setStatement
    : 'SET' optionValueNoOptionType (',' (scope 'DEFAULT'? qname equal term | optionValueNoOptionType))*
    | 'SET' scope? 'TRANSACTION' transactionCharacteristics
    | 'SET' scope? 'DEFAULT'? qname equal term (',' (scope 'DEFAULT'? qname equal term | optionValueNoOptionType))*
    | 'SET' 'PASSWORD' ('FOR' user)? equal ( string replacePassword? retainCurrentPassword? | 'PASSWORD' '(' string ')' )
    | 'SET' 'PASSWORD' ('FOR' user)? 'TO' 'RANDOM' replacePassword? retainCurrentPassword?
    ;

transactionCharacteristics
    : transactionAccessMode isolationLevel?
    | isolationLevel (',' transactionAccessMode)?
    ;

transactionAccessMode
    : 'READ' ('WRITE' | 'ONLY')
    ;

isolationLevel
    : 'ISOLATION' 'LEVEL'
        ( 'REPEATABLE' 'READ'
        | 'READ' ('COMMITTED' | 'UNCOMMITTED')
        | 'SERIALIZABLE'
        )
    ;

optionValueNoOptionType
    : 'DEFAULT'? qname equal term
    | charset
//    | name equal expr
    | qname equal term
    | 'NAMES' ( equal term | name collate? | 'DEFAULT' )
    ;


showCommandType
    : 'FULL'
    | 'EXTENDED' 'FULL'?
    ;

fromOrIn
    : 'FROM'
    | 'IN'
    ;

inDb
    : fromOrIn name
    ;

profileDefinitions
    : profileDefinition (',' profileDefinition)*
    ;

profileDefinition
    : 'BLOCK' 'IO'
    | 'CONTEXT' 'SWITCHES'
    | 'PAGE' 'FAULTS'
    | (
        'ALL'
        | 'CPU'
        | 'IPC'
        | 'MEMORY'
        | 'SOURCE'
        | 'SWAPS'
    )
    ;

keyCacheListOrParts
    : keyCacheList
    | assignToKeycachePartition
    ;

keyCacheList
    : assignToKeycache (',' assignToKeycache)*
    ;

assignToKeycache
    : qname cacheKeyList?
    ;

assignToKeycachePartition
    : qname 'PARTITION' '(' allOrPartitionNameList ')' cacheKeyList?
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
    : NUMBER ('-' NUMBER)?
    ;

resourceGroupPriority
    : 'THREAD_PRIORITY' equal? NUMBER
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
    | 'FOR' 'CONNECTION' integer
    ;

term
    : qname
    | term ( '->' | '->>' ) string
    | literal
    | term 'AT' 'LOCAL'
    | 'INTERVAL' term interval '+' term
    | 'BINARY' term
    | 'CAST' '(' term 'AS' castType 'ARRAY'? ')'
    | 'CAST' '(' term 'AT' 'TIME' 'ZONE' 'INTERVAL'? string 'AS' 'DATETIME' typeDatetimePrecision ')'
    | 'CONVERT' '(' term ',' castType ')'
    | 'CONVERT' '(' term 'USING' name ')'

    | term 'COLLATE' name
    | '!' term
    | ('+' | '-' | '~') term
//    | ('+' | '-' ) term
    | term '^' term
    | term ( '*' | '/' | 'DIV' | '%' | 'MOD' ) term
    | term ('+' | '-') term
//    | term ('+' | '-') 'INTERVAL' term interval
    | term ('<<' | '>>') term
    | term '&' term
    | term '|' term
    | term compOp term

    | function
    | sumExpr over?
    | windowFunctionCall
    | 'GROUPING' '(' term (',' term)* ')'
    | term 'CONCAT_PIPES' term
//    | ('!' | 'NOT2') term
    | '{' name term '}'
    | 'MATCH' (qname (',' qname)* | '(' qname (',' qname)* ')') 'AGAINST' '(' term fulltextOptions? ')'
    | 'DEFAULT' '(' qname ')'
    | 'VALUES' '(' qname ')'

    | term  'IS' notRule? ('TRUE' | 'FALSE' | 'UNKNOWN' | 'NULL')
    | term 'LIKE' term ('ESCAPE' term)?
    | term 'REGEXP' term
    | term notRule? 'IN' ('(' select ')' | '(' term (',' term)* ')')
    | term 'MEMBER' 'OF'? '(' term ')'
    | term 'BETWEEN' term 'AND' term
    | 'CASE' term? ('WHEN' term 'THEN' term)+ ('ELSE' term)? 'END'
//    | term 'SOUNDS' 'LIKE' term

    | 'ROW'? '(' term (',' term)* ')'
    | 'EXISTS'? '(' select ')'
    | ('ALL' | 'ANY') '(' select ')'

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
    | 'NTILE' ( '(' integer ')' | '(' term ')' ) over
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
    | 'CURTIME' ('(' integer? ')')?
    | ('DATE_ADD' | 'DATE_SUB') '(' term ',' 'INTERVAL' term interval ')'
    | 'EXTRACT' '(' interval 'FROM' term ')'
    | 'GET_FORMAT' '(' ('DATE' | 'TIME' | 'DATETIME' | 'TIMESTAMP') ',' term ')'
    | 'LOG' '(' term ( ',' term )? ')'
    | 'NOW' ('(' integer? ')')?
    | 'POSITION' '(' term 'IN' term ')'
    | 'SUBSTRING' '(' term ( ',' term (',' term)? | 'FROM' term ('FOR' term)? ) ')'
    | 'SYSDATE' ('(' integer? ')')?
    | ('TIMESTAMPADD' | 'TIMESTAMPDIFF') '(' intervalTimeStamp ',' term ',' term ')'
    | 'UTC_DATE' ('(' ')')?
    | 'UTC_TIME' ('(' integer? ')')?
    | 'UTC_TIMESTAMP' ('(' integer? ')')?

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
    | 'WEIGHT_STRING' '(' term ( ('AS' 'CHAR' '(' integer ')')? | 'AS' 'BINARY' '(' integer ')' | ',' number ',' number ',' number ) ')'
    | 'GEOMETRYCOLLECTION' '(' (term (',' term)*)? ')'
    | 'LINESTRING' '(' term (',' term)* ')'
    | 'MULTILINESTRING' '(' term (',' term)* ')'
    | 'MULTIPOINT' '(' term (',' term)* ')'
    | 'MULTIPOLYGON' '(' term (',' term)* ')'
    | 'POINT' '(' term ',' term ')'
    | 'POLYGON' '(' term (',' term)* ')'

    | IDENTIFIER '(' ( udfExpr ( ',' udfExpr )* )? ')'
    | qname '(' (term (',' term)* )? ')'

    ;

//weightStringLevels
//    : 'LEVEL' (
//        real_ulong_number '-' real_ulong_number
//        | weightStringLevelListItem (',' weightStringLevelListItem)*
//    )
//    ;

//weightStringLevelListItem
//    : real_ulong_number (('ASC' | 'DESC') 'REVERSE'? | 'REVERSE')?
//    ;

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

charset
    : ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) name
    ;

notRule
    : 'NOT'
//    | 'NOT2'
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
    : number
    | sqlstate
    ;

sqlstate
    : 'SQLSTATE' 'VALUE'? string
    ;

handlerCondition
    : spCondition
    | name
    | 'SQLWARNING'
    | notRule 'FOUND'
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

columnDefinition
    : name fieldDefinition checkOrReferences?
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
        ( columnAttribute*
        | collate? ('GENERATED' 'ALWAYS')? 'AS' '(' term ')' ( 'VIRTUAL' | 'STORED' )? columnAttribute*
        )
    ;

columnAttribute
    : 'NOT'? null
    | 'NOT' 'SECONDARY'
    | 'DEFAULT' ( 'NOW' ( '(' NUMBER? ')' )? | signedLiteral | '(' term ')' )
    | 'ON' 'UPDATE' 'NOW' ('(' integer? ')')?
    | 'AUTO_INCREMENT'
    | 'SERIAL' 'DEFAULT' 'VALUE'
    | 'PRIMARY'? 'KEY'
    | 'UNIQUE' 'KEY'?
    | 'COMMENT' string
    | collate
    | 'COLUMN_FORMAT' ('FIXED' | 'DYNAMIC' | 'DEFAULT')
    | 'STORAGE' ('DISK' | 'MEMORY' | 'DEFAULT')
    | 'SRID' integer
    | ('CONSTRAINT' name?)? checkConstraint
    | constraintEnforcement
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | visibility
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

indexOption
    : commonIndexOption
    | indexTypeClause
    ;


commonIndexOption
    : 'KEY_BLOCK_SIZE' '='? number
    | 'COMMENT' string
    | visibility
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    ;

visibility
    : 'VISIBLE'
    | 'INVISIBLE'
    ;

indexTypeClause
    : ('USING' | 'TYPE') indexType
    ;

fulltextIndexOption
    : commonIndexOption
    | 'WITH' 'PARSER' name
    ;

// TODO merge dataTyle and castType rules?
dataType
    : ( 'INT' | 'TINYINT' | 'SMALLINT' | 'MEDIUMINT' | 'BIGINT' ) fieldLength? fieldOptions?
    | ('REAL' | 'DOUBLE' 'PRECISION'?) (floatOptions)? fieldOptions?
    | ('FLOAT' | 'DECIMAL' | 'NUMERIC' | 'FIXED') floatOptions? fieldOptions?
    | 'BIT' fieldLength?
    | ('BOOL' | 'BOOLEAN')
    | 'CHAR' fieldLength? charsetWithOptBinary?
    | ('NCHAR'
    | 'NATIONAL' 'CHAR') fieldLength? 'BINARY'?
    | 'BINARY' fieldLength?
    | ('CHAR' 'VARYING' | 'VARCHAR') fieldLength charsetWithOptBinary?
    | (
        'NATIONAL' 'VARCHAR'
        | 'NVARCHAR'
        | 'NCHAR' 'VARCHAR'
        | 'NATIONAL' 'CHAR' 'VARYING'
        | 'NCHAR' 'VARYING'
    ) fieldLength 'BINARY'?
    | 'VARBINARY' fieldLength
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

fieldLength
//    : '(' (integer | DECIMAL_NUMBER) ')'
    : '(' integer  ')'
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
    : '(' NUMBER ')'
    ;

createTableOptionsEtc
    : createTableOption (','? createTableOption)* createPartitioningEtc?
    | createPartitioningEtc
    ;

createPartitioningEtc
    : partitionClause duplicateAsQe?
    | duplicateAsQe
    ;

createTableOption
    : 'ENGINE' '='? name
    | 'SECONDARY_ENGINE' equal? name
//    | 'SECONDARY_ENGINE' equal? ( 'NULL' | name )
    | 'MAX_ROWS' '='? number
    | 'MIN_ROWS' '='? number
    | 'AVG_ROW_LENGTH' '='? number
    | 'PASSWORD' '='? string
    | 'COMMENT' '='? string
    | 'COMPRESSION' '='? string
    | 'ENCRYPTION' '='? string
    | 'AUTO_INCREMENT' '='? number
    | 'PACK_KEYS' '='? ternaryOption
    | ( 'STATS_AUTO_RECALC' | 'STATS_PERSISTENT' | 'STATS_SAMPLE_PAGES' ) '='? ternaryOption
    | ('CHECKSUM' | 'TABLE_CHECKSUM') '='? number
    | 'DELAY_KEY_WRITE' '='? number
    | 'ROW_FORMAT' '='? ( 'DEFAULT' | 'DYNAMIC' | 'FIXED' | 'COMPRESSED' | 'REDUNDANT' | 'COMPACT' )
    | 'UNION' '='? '(' qname (',' qname)* ')'
    | 'DEFAULT'? ( 'CHAR' 'SET' | 'CHARACTER' 'SET' | 'CHARSET' ) '='? name
    | 'DEFAULT'? 'COLLATE' '='? name
    | 'INSERT_METHOD' '='? ( 'NO' | 'FIRST' | 'LAST' )
    | 'DATA' 'DIRECTORY' '='? string
    | 'INDEX' 'DIRECTORY' '='? string
    | 'TABLESPACE' '='? name
    | 'STORAGE' ('DISK' | 'MEMORY')
    | 'CONNECTION' '='? string
    | 'KEY_BLOCK_SIZE' '='? number
    | 'START' 'TRANSACTION'
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | tsOptionAutoextendSize
    ;

ternaryOption
    : number
    | 'DEFAULT'
    ;

partitionClause
    : 'PARTITION' 'BY' partitionTypeDef
      ( 'PARTITIONS' integer )? subPartitions?
      ('(' partition (',' partition)* ')')?
    ;

partitionTypeDef
    : keyOrHash
    | ('RANGE' | 'LIST') ( '(' term ')' | 'COLUMNS' '(' (name (',' name)*)? ')' )
    ;

subPartitions
    : 'SUBPARTITION' 'BY' keyOrHash
      ('SUBPARTITIONS' integer)?
    ;

keyOrHash : 'LINEAR'?
      ( 'HASH' '(' term ')' | 'KEY' ('ALGORITHM' '=' integer)? '(' name (',' name)* ')' ) ;

partition
    : 'PARTITION' name
        ( 'VALUES' 'LESS' 'THAN' ( '(' term (',' term)* ')' | 'MAXVALUE' )
        | 'VALUES' 'IN' partitionValuesIn
        )?
        partitionOption*
        ( '(' subpartition (',' subpartition)* ')' )?
    ;

partitionValuesIn
    : '(' term (',' term)* ')'
    | '(' '(' term (',' term)* ')' ( ',' '(' term (',' term)* ')' )* ')'
    ;

partitionOption
    : 'TABLESPACE' '='? name
    | 'STORAGE'? 'ENGINE' '='? name
    | 'NODEGROUP' '='? integer
    | ('MAX_ROWS' | 'MIN_ROWS') '='? integer
    | ('DATA' | 'INDEX') 'DIRECTORY' '='? string
    | 'COMMENT' '='? string
    ;

subpartition
    : 'SUBPARTITION' name partitionOption*
    ;

definerClause
    : 'DEFINER' '=' user
    ;

ifExists
    : 'IF' 'EXISTS'
    ;

ifNotExists
    : 'IF' notRule 'EXISTS'
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
        ( identification createUserWithMfa?
        | identifiedWithPlugin ('INITIAL' 'AUTHENTICATION' ( identifiedByRandomPassword | identifiedWithPluginAsAuth | identifiedByPassword ))?
        | createUserWithMfa
        )?
    ;

createUserWithMfa
    : 'AND' identification ('AND' identification)?
    ;

identification
    : identifiedByPassword
    | identifiedByRandomPassword
    | identifiedWithPlugin
    | identifiedWithPluginAsAuth
    | identifiedWithPluginByPassword
    | identifiedWithPluginByRandomPassword
    ;

identifiedByPassword
    : 'IDENTIFIED' 'BY' string
    ;

identifiedByRandomPassword
    : 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD'
    ;

identifiedWithPlugin
    : 'IDENTIFIED' 'WITH' name
    ;

identifiedWithPluginAsAuth
    : 'IDENTIFIED' 'WITH' name 'AS' string
    ;

identifiedWithPluginByPassword
    : 'IDENTIFIED' 'WITH' name 'BY' string
    ;

identifiedWithPluginByRandomPassword
    : 'IDENTIFIED' 'WITH' name 'BY' 'RANDOM' 'PASSWORD'
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
    : number 'FACTOR'
    ;

replacePassword
    : 'REPLACE' string
    ;

user
    : userName
    | 'CURRENT_USER' ('(' ')')?
    ;

userName
    : name name?
    ;

like
    : 'LIKE' string
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
    : '.'? name ( '.' name ( '.' name )? )?
    ;

integer
    : NUMBER
    ;

signedLiteral
    : literal
    | '+' number
    | '-' number
    ;

literal
//    : string
    : name
    | number
    | temporalLiteral
    | null
    | boolean
    | PARAM
    ;

string
    : STRING+
    | NCHAR_TEXT
    ;

strings
    : string (',' string)*
    ;

number
    : NUMBER
    | DECIMAL_NUMBER
    ;

boolean
    : 'TRUE'
    | 'FALSE'
    ;

null
    : 'NULL' | '\\N' ;

temporalLiteral
    : 'DATE' STRING
    | 'TIME' STRING
    | 'TIMESTAMP' STRING
    ;

floatOptions
    : fieldLength
    | '(' NUMBER ',' NUMBER ')'
    ;

name
    : IDENTIFIER
    | keyword
    | string
    ;

sizeNumber
    : integer
    | IDENTIFIER // Something like 10G. Semantic check needed for validity.
    ;

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
    : '?'
    ;


// Only lower case 'x' and 'b' count for hex + bin numbers. Otherwise it's an identifier.
NUMBER options { caseInsensitive = false; }
    : DIGITS
    | '0x' HEX+
    | '0b' [01]+
    ;

DECIMAL_NUMBER
  : ( DIGITS ( '.' DIGITS? )? | '.' DIGITS ) ( 'E' [-+]? DIGITS )?
//  | '0x' HEX_DIGIT+
  ;

IDENTIFIER
  : ( '"' ( ~'"' | '""' )* '"' )+
  | '`' ( ~'`' | '``' )* '`'
  | ('@'? '@')? [A-Z0-9_$\u007F-\uFFFF]+
  ;

// TODO from NormalSQL.g4. synthesize these STRING and string rules?
//STRING
//  : '\'' ( ~'\'' | '\'\'' )* '\'' ;

STRING
    : ( '\'' (('\\')? .)*? '\'' )+
    | 'x\'' HEX '\''
    | 'b\'' [01]+ '\''
    ;

NCHAR_TEXT
    : 'N' STRING
    ;

// TODO: check in the semantic phase that starting and ending tags are the same.
DOLLAR_QUOTED_STRING_TEXT
   : '$' DOLLAR_QUOTE_TAG_CHAR* '$' .*? '$' DOLLAR_QUOTE_TAG_CHAR* '$' ;




// There are 3 types of block comments:
// /* ... */ - The standard multi line comment.
// /*! ... */ - A comment used to mask code for other clients. In MySQL the content is handled as normal code.
// /*!12345 ... */ - Same as the previous one except code is only used when the given number is lower than or equal to
//                   the current server version (specifying so the minimum server version the code can run with).
VERSION_COMMENT_START
    : ('/*!' DIGITS) (
        // Will set this.inVersionComment if the number matches.
        | .*? '*/'
    ) -> channel(HIDDEN)
    ;

// this.inVersionComment is a variable in the base lexer.
// TODO: use a lexer mode instead of a member variable.
MYSQL_COMMENT_START
    : '/*!' { this.startInVersionComment(); } -> channel(HIDDEN)
    ;

VERSION_COMMENT_END
    : '*/' {this.isInVersionComment()}?
      { this.endInVersionComment(); } -> channel(HIDDEN)
    ;

BLOCK_COMMENT
    : ('/**/' | '/*' ~[!] .*? '*/') -> channel(HIDDEN)
    ;

INVALID_BLOCK_COMMENT
    : '/*' ~[*/]* EOF -> channel(HIDDEN)
    ; // Not 100% perfect but good enough.

POUND_COMMENT
    : '#' ~([\n\r])* -> channel(HIDDEN)
    ;

DASHES
    : '--' ([ \t] (~[\n\r])* | [\n\r] | EOF) -> channel(HIDDEN)
    ;

//COMMENT
//  : '--' ~[\r\n]* (( '\r'? '\n' ) | EOF ) -> channel(HIDDEN) ;


// White space handling
WHITESPACE
    : [ \t\f\r\n]+ -> channel(HIDDEN)
    ;

//// Input not covered elsewhere (unless quoted).
//INVALID_INPUT
//    : [\u0001-\u0008] // Control codes.
//    | '\u000B'        // Line tabulation.
//    | '\u000C'        // Form feed.
//    | [\u000E-\u001F] // More control codes.
//    | '['
//    | ']'
//    ;


// As defined in https://dev.mysql.com/doc/refman/8.0/en/identifiers.html.

fragment DOLLAR_QUOTE_TAG_CHAR
    : [0-9A-Z_\u0080-\uffff]
    ;

fragment DIGITS
    : [0-9]+
    ;

fragment HEX
    : [0-9A-F]+
    ;
