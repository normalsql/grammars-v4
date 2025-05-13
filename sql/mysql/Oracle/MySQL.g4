grammar MySQL;

/*
  Copyright 2025 Jason Osgood

  Refactoring MySQL.g4 to adopt NormalSQL's rules, idioms, and style. Goal is to emit
  a common parse tree across multiple dialects.

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

statement
    // DDL
    : alterStatement
    | createStatement
    | dropStatement
    | renameTableStatement
    | truncateTableStatement
    | importStatement

    // DML
    | callStatement
    | deleteStatement
    | doStatement
    | handlerStatement
    | insertStatement
    | loadStatement
    | replaceStatement
    | select
    | updateStatement
    | transactionOrLockingStatement
    | replicationStatement
    | preparedStatement

    // Data Directory
    | cloneStatement

    // Database administration
    | accountManagementStatement
    | tableAdministrationStatement
    | 'UNINSTALL' (
        'PLUGIN' name
        | 'COMPONENT' string (',' string)*
    )
    | installStatement
    | setStatement // SET PASSWORD is handled in accountManagementStatement.
    | showDatabasesStatement
    | showTablesStatement
    | showTriggersStatement
    | showEventsStatement
    | showTableStatusStatement
    | showOpenTablesStatement
    | showParseTreeStatement
    | showPluginsStatement
    | 'SHOW' 'ENGINE' engineOrAll 'LOGS'
    | 'SHOW' 'ENGINE' engineOrAll 'MUTEX'
    | 'SHOW' 'ENGINE' engineOrAll 'STATUS'
    | 'SHOW' showCommandType? 'COLUMNS' ('FROM' | 'IN') qname inDb? likeOrWhere?
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
    | 'SHOW' 'PROFILE' profileDefinitions? ( 'FOR' 'QUERY' INT_NUMBER )? limit?
    | 'SHOW' scope? 'STATUS' likeOrWhere?
    | showProcessListStatement
    | showVariablesStatement
    | showCharacterSetStatement
    | showCollationStatement
    | showPrivilegesStatement
    | showGrantsStatement
    | showCreateDatabaseStatement
    | showCreateTableStatement
    | showCreateViewStatement
    | showMasterStatusStatement
    | showReplicaStatusStatement
    | showCreateProcedureStatement
    | showCreateFunctionStatement
    | showCreateTriggerStatement
    | showCreateProcedureStatusStatement
    | showCreateFunctionStatusStatement
    | showCreateProcedureCodeStatement
    | showCreateFunctionCodeStatement
    | showCreateEventStatement
    | showCreateUserStatement
    | resourceGroupManagement
    | otherAdministrativeStatement

    // MySQL utility statements
    | utilityStatement
    | getDiagnosticsStatement
    | signalStatement
    ;

alterStatement
    : 'ALTER'
        ( onlineOption? 'TABLE' qname alterTableActions?
        | alterDatabase
        | 'PROCEDURE' qname (routineCreateOption+)?
        | 'FUNCTION' qname (routineCreateOption+)?
        | alterView
        | alterEvent
        | alterTablespace
        | alterUndoTablespace
        | alterLogfileGroup
        | 'SERVER' name serverOptions
        // ALTER USER is part of the user management rule.
        | alterInstanceStatement
    )
    ;

alterDatabase
    : 'DATABASE' name alterDatabaseOption+
    ;

alterDatabaseOption
    : createDatabaseOption
    | 'READ' 'ONLY' '='? ternaryOption
    ;

alterEvent
    : definerClause? 'EVENT' qname ('ON' 'SCHEDULE' schedule)? (
        'ON' 'COMPLETION' 'NOT'? 'PRESERVE'
    )? ('RENAME' 'TO' name)? (
        'ENABLE'
        | 'DISABLE' ('ON' replica)?
    )? ('COMMENT' textLiteral)? ('DO' compoundStatement)?
    ;

alterLogfileGroup
    : 'LOGFILE' 'GROUP' name 'ADD' 'UNDOFILE' textLiteral alterLogfileGroupOptions?
    ;

alterLogfileGroupOptions
    : (initialSize
    | tsOptionEngine
    | tsOptionWait) (','? (initialSize
    | tsOptionEngine
    | tsOptionWait))*
    ;

alterTableActions
    : alterCommandList (partitionClause | removePartitioning)?
    | partitionClause
    | removePartitioning
    | (alterCommandsModifierList ',')? standaloneAlterCommands
    ;

alterCommandList
    : alterCommandsModifierList
    | (alterCommandsModifierList ',')? alterList
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
    : 'ADD' 'PARTITION' noWriteToBinLog? (
        partitionDefinitions
        | 'PARTITIONS' integer
    )
    | 'DROP' 'PARTITION' name (',' name)*
    | 'REBUILD' 'PARTITION' noWriteToBinLog? allOrPartitionNameList

    // yes, twice "no write to bin log".
    | 'OPTIMIZE' 'PARTITION' noWriteToBinLog? allOrPartitionNameList noWriteToBinLog?
    | 'ANALYZE' 'PARTITION' noWriteToBinLog? allOrPartitionNameList
    | 'CHECK' 'PARTITION' allOrPartitionNameList checkOption*
    | 'REPAIR' 'PARTITION' noWriteToBinLog? allOrPartitionNameList repairType*
    | 'COALESCE' 'PARTITION' noWriteToBinLog? integer
    | 'TRUNCATE' 'PARTITION' allOrPartitionNameList
    | 'REORGANIZE' 'PARTITION' noWriteToBinLog? ( name (',' name)* 'INTO' partitionDefinitions )?
    | 'EXCHANGE' 'PARTITION' name 'WITH' 'TABLE' qname withValidation?
    | 'DISCARD' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    | 'IMPORT' 'PARTITION' allOrPartitionNameList 'TABLESPACE'
    ;

alterList
    : (alterListItem | createTableOption+) (
        ',' (
            alterListItem
            | alterCommandsModifier
            | createTableOption+
        )
    )*
    ;

alterCommandsModifier
    : alterAlgorithmOption
    | alterLockOption
    | withValidation
    ;

alterListItem
    : 'ADD' 'COLUMN'? (
        name fieldDefinition checkOrReferences? place?
        | '(' tableElementList ')'
    )
    | 'ADD' tableConstraintDef
    | 'CHANGE' 'COLUMN'? name name fieldDefinition place?
    | 'MODIFY' 'COLUMN'? name fieldDefinition place?
    | 'DROP' (
        'COLUMN'? name restrict?
        | 'FOREIGN' 'KEY' name
        | 'PRIMARY' 'KEY'
        | keyOrIndex qname
        | 'CHECK' name
        | 'CONSTRAINT' name
    )
    | 'DISABLE' 'KEYS'
    | 'ENABLE' 'KEYS'
    | 'ALTER' 'COLUMN'? name (
        'SET' 'DEFAULT' (
            '(' expr ')'
            | signedLiteral
        )
        | 'DROP' 'DEFAULT'
        | 'SET' visibility
    )
    | 'ALTER' 'INDEX' qname visibility
    | 'ALTER' 'CHECK' name constraintEnforcement
    | 'ALTER' 'CONSTRAINT' name constraintEnforcement
    | 'RENAME' 'COLUMN' name 'TO' name
    | 'RENAME' ('TO' | 'AS')? qname
    | 'RENAME' keyOrIndex qname 'TO' name
    | 'CONVERT' 'TO' charset (
        'DEFAULT'
        | name
    ) collate?
    | 'FORCE'
    | 'ORDER' 'BY' alterOrderList
    ;

place
    : 'AFTER' name
    | 'FIRST'
    ;

restrict
    : 'RESTRICT'
    | 'CASCADE'
    ;

alterOrderList
    : name direction? (',' name direction?)*
    ;

alterAlgorithmOption
    : 'ALGORITHM' '='? ('DEFAULT' | name)
    ;

alterLockOption
    : 'LOCK' '='? ('DEFAULT' | name)
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

alterTablespace
    : 'TABLESPACE' name (
        ('ADD' | 'DROP') 'DATAFILE' textLiteral alterTablespaceOptions?
        | 'RENAME' 'TO' name
        | alterTablespaceOptions
    )
    ;

alterUndoTablespace
    : 'UNDO' 'TABLESPACE' name 'SET' (
        'ACTIVE'
        | 'INACTIVE'
    ) undoTableSpaceOptions?
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

alterView
    : viewAlgorithm? definerClause? viewSuid? 'VIEW' qname viewTail
    ;

// This is not the full view_tail from sql_yacc.yy as we have either a view name or a view reference,
// depending on whether we come from createView or alterView. Everything until this difference is duplicated in those rules.
viewTail
    : columns? 'AS' viewQueryBlock
    ;

viewQueryBlock
    : select viewCheckOption?
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

createStatement
    : 'CREATE'
        ( 'DATABASE' ifNotExists? name createDatabaseOption*
        | 'TEMPORARY'? 'TABLE' ifNotExists? qname ( ('(' tableElementList ')')? createTableOptionsEtc? | 'LIKE' qname | '(' 'LIKE' qname ')' )
        | definerClause? 'FUNCTION' ifNotExists? qname '(' ( functionParameter (',' functionParameter)* )? ')' 'RETURNS' typeWithOptCollate routineCreateOption* storedRoutineBody
        | createProcedure
        | createUdf
        | createLogfileGroup
        | createView
        | createTrigger
        | createIndex
        | createServer
        | createTablespace
        | createEvent
        | createRole
        | createSpatialReference
        | createUndoTablespace
        )
    ;

createDatabaseOption
    : defaultCharset
    | defaultCollation
    | defaultEncryption
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

createProcedure
    : definerClause? 'PROCEDURE' ifNotExists? qname
      '(' ( procedureParameter (',' procedureParameter)* )? ')'
      routineCreateOption* storedRoutineBody
    ;

storedRoutineBody
    : compoundStatement
    | 'AS' (STRING | DOLLAR_QUOTED_STRING_TEXT)
    ;

createUdf
    : 'AGGREGATE'? 'FUNCTION' ifNotExists? name 'RETURNS'
    ( 'STRING' | 'INT' | 'REAL' | 'DECIMAL' )
    'SONAME' textLiteral
    ;

// sp_c_chistic in the server grammar.
routineCreateOption
    : routineOption
    | 'NOT'? 'DETERMINISTIC'
    ;

routineOption
    : 'COMMENT' textLiteral
    | 'LANGUAGE' ( 'SQL' | name )
    | 'NO' 'SQL'
    | 'CONTAINS' 'SQL'
    | 'READS' 'SQL' 'DATA'
    | 'MODIFIES' 'SQL' 'DATA'
    | 'SQL' 'SECURITY' ( 'DEFINER' | 'INVOKER' )
    ;

createIndex
    : onlineOption? (
        'UNIQUE'? 'INDEX' name indexTypeClause? createIndexTarget indexOption*
        | 'FULLTEXT' 'INDEX' name createIndexTarget fulltextIndexOption*
        | 'SPATIAL' 'INDEX' name createIndexTarget (commonIndexOption)*
    ) indexLockAndAlgorithm?
    ;

indexNameAndType
    : name
    | (name)? 'USING' indexType
    | name 'TYPE' indexType
    ;

createIndexTarget
    : 'ON' qname keyListWithExpression
    ;

createLogfileGroup
    : 'LOGFILE' 'GROUP' name 'ADD' 'UNDOFILE' textLiteral logfileGroupOptions?
    ;

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

createServer
    : 'SERVER' name 'FOREIGN' 'DATA' 'WRAPPER' name serverOptions
    ;

serverOptions
    : 'OPTIONS' '(' serverOption (',' serverOption)* ')'
    ;

// Options for CREATE/ALTER SERVER, used for the federated storage engine.
serverOption
    : 'HOST' textLiteral
    | 'DATABASE' textLiteral
    | 'USER' textLiteral
    | 'PASSWORD' textLiteral
    | 'SOCKET' textLiteral
    | 'OWNER' textLiteral
    | 'PORT' number
    ;

createTablespace
    : 'TABLESPACE' name tsDataFileName? ( 'USE' 'LOGFILE' 'GROUP' name )? tablespaceOptions?
    ;

createUndoTablespace
    : 'UNDO' 'TABLESPACE' name 'ADD' tsDataFile undoTableSpaceOptions?
    ;

tsDataFileName
    : 'ADD' tsDataFile
    ;

tsDataFile
    : 'DATAFILE' textLiteral
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
    : 'COMMENT' '='? textLiteral
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

createView
    : viewReplaceOrAlgorithm? definerClause? viewSuid? 'VIEW' qname viewTail
    ;

viewReplaceOrAlgorithm
    : 'OR' 'REPLACE' viewAlgorithm?
    | viewAlgorithm
    ;

viewAlgorithm
    : 'ALGORITHM' '=' ( 'UNDEFINED' | 'MERGE' | 'TEMPTABLE' )
    ;

viewSuid
    : 'SQL' 'SECURITY' ('DEFINER' | 'INVOKER')
    ;

createTrigger
    : definerClause? 'TRIGGER' ifNotExists? qname ( 'BEFORE' | 'AFTER' )
      ('INSERT' | 'UPDATE' | 'DELETE') 'ON' qname 'FOR' 'EACH' 'ROW'
        ('FOLLOWS' | 'PRECEDES') name? compoundStatement
    ;

createEvent
    : definerClause? 'EVENT' ifNotExists? qname 'ON' 'SCHEDULE' schedule
      ( 'ON' 'COMPLETION' 'NOT'? 'PRESERVE' )?
      ('ENABLE' | 'DISABLE' ('ON' replica)?)?
      ( 'COMMENT' textLiteral )? 'DO' compoundStatement
    ;

createRole
    // The server grammar has a clear_privileges rule here, which is only used to clear internal state.
    : 'ROLE' ifNotExists? roleList
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

//----------------------------------------------------------------------------------------------------------------------

dropStatement
    : 'DROP'
        ( 'DATABASE' ifExists? name
        | 'EVENT' ifExists? qname
        | 'FUNCTION' ifExists? qname
        | 'PROCEDURE' ifExists? qname
        | onlineOption? 'INDEX' qname 'ON' qname indexLockAndAlgorithm?
        | dropLogfileGroup
        | dropServer
        | dropTable
        | dropTableSpace
        | dropTrigger
        | dropView
        | dropRole
        | dropSpatialReference
        | dropUndoTablespace
    )
    ;

dropLogfileGroup
    : 'LOGFILE' 'GROUP' name (
        dropLogfileGroupOption (','? dropLogfileGroupOption)*
    )?
    ;

dropLogfileGroupOption
    : tsOptionWait
    | tsOptionEngine
    ;

dropServer
    : 'SERVER' ifExists? name
    ;

dropTable
    : 'TEMPORARY'? ('TABLE' | 'TABLES') ifExists? qnames (
        'RESTRICT'
        | 'CASCADE'
    )?
    ;

dropTableSpace
    : 'TABLESPACE' name (
        dropLogfileGroupOption (','? dropLogfileGroupOption)*
    )?
    ;

dropTrigger
    : 'TRIGGER' ifExists? qname
    ;

dropView
    : 'VIEW' ifExists? qname (',' qname)* ('RESTRICT' | 'CASCADE')?
    ;

dropRole
    : 'ROLE' ifExists? roleList
    ;

dropSpatialReference
    : 'SPATIAL' 'REFERENCE' 'SYSTEM' ifExists? integer
    ;

dropUndoTablespace
    : 'UNDO' 'TABLESPACE' name undoTableSpaceOptions?
    ;

//----------------------------------------------------------------------------------------------------------------------

renameTableStatement
    : 'RENAME' ('TABLE' | 'TABLES') renamePair (
        ',' renamePair
    )*
    ;

renamePair
    : qname 'TO' qname
    ;

//----------------------------------------------------------------------------------------------------------------------

truncateTableStatement
    : 'TRUNCATE' 'TABLE'? qname
    ;

//----------------------------------------------------------------------------------------------------------------------

importStatement
    : 'IMPORT' 'TABLE' 'FROM' strings
    ;

//--------------- DML statements ---------------------------------------------------------------------------------------

callStatement
    : 'CALL' qname ('(' (expr (',' expr)*)? ')')?
    ;

deleteStatement
    : with? 'DELETE' deleteStatementOption* (
        'FROM' (
            tableAliasRefList 'USING' tableReferenceList where? // Multi table variant 1.
            | qname (tableAlias)? partitionDelete? where? orderBy? simpleLimitClause?
            // Single table delete.
        )
        | tableAliasRefList 'FROM' tableReferenceList where? // Multi table variant 2.
    )
    ;

partitionDelete
    : 'PARTITION' '(' name (',' name)* ')'
    ;

deleteStatementOption
    : // opt_delete_option in sql_yacc.yy, but the name collides with another rule (delete_options).
    'QUICK'
    | 'LOW_PRIORITY'
    | 'QUICK'
    | 'IGNORE'
    ;

doStatement
    : 'DO' items
    ;

handlerStatement
    : 'HANDLER' (
        qname 'OPEN' tableAlias?
        | name (
            'CLOSE'
            | 'READ' handlerReadOrScan where? limit?
        )
    )
    ;

handlerReadOrScan
    : ('FIRST' | 'NEXT') // Scan function.
    | name (
        // The rkey part.
        ('FIRST' | 'NEXT' | 'PREV' | 'LAST')
        | (
            '='
            | '<'
            | '>'
            | '<='
            | '>='
        ) '(' values ')'
    )
    ;

//----------------------------------------------------------------------------------------------------------------------

insertStatement
    : 'INSERT' insertLockOption? 'IGNORE'? 'INTO'? qname usePartition? (
        insertFromConstructor valuesReference?
        | 'SET' updateList valuesReference?
        | insertQueryExpression
    ) insertUpdateList?
    ;

insertLockOption
    : 'LOW_PRIORITY'
    | 'DELAYED' // Only allowed if no select is used. Check in the semantic phase.
    | 'HIGH_PRIORITY'
    ;

insertFromConstructor
    : ('(' fields? ')')? insertValues
    ;

fields
    : insertIdentifier (',' insertIdentifier)*
    ;

insertValues
    : ('VALUES' | 'VALUE') valueList
    ;

insertQueryExpression
    : with? selectCore orderBy? limit?
    | '(' select ')'
    | ('(' fields? ')')? select
    ;

valueList
    : '(' values? ')' (
        ',' '(' values? ')'
    )*
    ;

values
    : (expr | 'DEFAULT') (',' (expr | 'DEFAULT'))*
    ;

valuesReference
    : 'AS' name columns?
    ;

insertUpdateList
    : 'ON' 'DUPLICATE' 'KEY' 'UPDATE' updateList
    ;

//----------------------------------------------------------------------------------------------------------------------

loadStatement
    : 'LOAD' dataOrXml loadDataLock? 'FROM'? 'LOCAL'? loadSourceType? string sourceCount? sourceOrder? (
        'REPLACE'
        | 'IGNORE'
    )? 'INTO' 'TABLE' qname usePartition? (charset)? xmlRowsIdentifiedBy? fieldsClause? linesClause?
        loadDataFileTail loadParallel? loadMemory? loadAlgorithm?
    ;

dataOrXml
    : 'DATA'
    | 'XML'
    ;

loadDataLock
    : 'LOW_PRIORITY'
    | 'CONCURRENT'
    ;

loadSourceType
    : 'INFILE'
    | ('URL' | 'S3')
    ;

sourceCount
    : (
        'COUNT' INT_NUMBER
        | IDENTIFIER INT_NUMBER
    )
    ;

sourceOrder
    : 'IN' 'PRIMARY' 'KEY' 'ORDER'
    ;

xmlRowsIdentifiedBy
    : 'ROWS' 'IDENTIFIED' 'BY' string
    ;

loadDataFileTail
    : ('IGNORE' INT_NUMBER ('LINES' | 'ROWS'))?
      ('(' (name ( ',' name )*)? ')')?
      ( 'SET' updateList )?
    ;

loadAlgorithm
    : 'ALGORITHM' '=' 'BULK'
    ;

loadParallel
    : 'PARALLEL' '=' INT_NUMBER
    ;

loadMemory
    : 'MEMORY' '=' sizeNumber
    ;

//----------------------------------------------------------------------------------------------------------------------

replaceStatement
    : 'REPLACE' ('LOW_PRIORITY' | 'DELAYED')? 'INTO'? qname usePartition? (
        insertFromConstructor
        | 'SET' updateList
        | insertQueryExpression
    )
    ;

//----------------------------------------------------------------------------------------------------------------------

/*
select
  : with?
    selectCore (( 'UNION' 'ALL'? | 'INTERSECT' | 'EXCEPT' ) selectCore )*
    orderBy? limit?
  ;

selectCore
  : 'SELECT' unique? ( item ( ',' item )* ','? )?
    from?
    where?
    // TODO decide between inlined or separate rules for GROUP BY and WINDOW
    ( 'GROUP' 'BY' terms ( 'HAVING' term )? )?
    ( 'WINDOW' window ( ',' window )* )?
  | values
  | '(' select ')'
  ;

  'SELECT'
      ('ALL' | 'DISTINCT' | 'DISTINCTROW' )?
      'HIGH_PRIORITY'?
      'STRAIGHT_JOIN'?
      'SQL_SMALL_RESULT'?
      'SQL_BIG_RESULT'?
      'SQL_BUFFER_RESULT'?
      'SQL_NO_CACHE'?
      'SQL_CALC_FOUND_ROWS'?
      select_expr (',' select_expr)*
      into_option?
      ('FROM' table_references ( 'PARTITION' partition_list )? )?
      ('WHERE' where_condition)?
      ('GROUP' 'BY' (col_name | expr | position) ',' ... ('WITH' 'ROLLUP'))?
      ('HAVING' where_condition)
      ('WINDOW' window_name 'AS' '('window_spec)
          (',' window_name 'AS' '('window_spec))? ...)?
      ('ORDER' 'BY' (col_name | expr | position )
        ('ASC' | 'DESC')',' ... ('WITH' 'ROLLUP'))?
      ('LIMIT' ( ( offset ',')? row_count | row_count 'OFFSET' offset )?
      into_option?
      ('FOR' ('UPDATE' | 'SHARE'}
          ('OF' tbl_name (',' tbl_name) ...)?
          ('NOWAIT' | 'SKIP' 'LOCKED')
        | 'LOCK' 'IN' 'SHARE' 'MODE')
      into_option?
*/

select
    : with? selectCore ( ( 'UNION' | 'EXCEPT' | 'INTERSECT' ) unionOption? selectCore )*
      orderBy? limit? lockingClause*
    | selectStatementWithInto
    ;


selectCore
    : 'SELECT' unique? modifier* items intoClause? fromClause? where? groupByClause? havingClause? windowClause?
        qualifyClause?
    | 'VALUES' rowValueExplicit (',' rowValueExplicit)*
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



selectStatementWithInto
    : '(' selectStatementWithInto ')'
    | with? selectCore orderBy? limit? intoClause lockingClause*
    | with? selectCore orderBy? limit? lockingClause+ intoClause
    | '(' select ')' intoClause
    ;

limit
    : 'LIMIT' limitOptions
    ;

simpleLimitClause
    : 'LIMIT' limitOption
    ;

limitOptions
    : limitOption ((',' | 'OFFSET') limitOption)?
    ;

limitOption
    : name
    | PARAM | INT_NUMBER
//    | (PARAM_MARKER | ULONGLONG_NUMBER | LONG_NUMBER | INT_NUMBER)
    ;

intoClause
    : 'INTO' (
        'OUTFILE' string (charset)? fieldsClause? linesClause?
        | 'DUMPFILE' string
        | name ( ',' name )*
    )
    ;

//procedureAnalyseClause
//    : 'PROCEDURE' '(' (INT_NUMBER (',' INT_NUMBER)?)? ')'
//    ;

havingClause
    : 'HAVING' expr
    ;

qualifyClause
    : 'QUALIFY' expr
    ;

windowClause
    : 'WINDOW' windowDefinition (',' windowDefinition)*
    ;

windowDefinition
    : name 'AS' windowSpec
    ;

windowSpec
    : '(' windowSpecDetails ')'
    ;

windowSpecDetails
    : name? ('PARTITION' 'BY' orderExpression (',' orderExpression)*)? orderBy? windowFrameClause?
    ;

windowFrameClause
    : windowFrameUnits windowFrameExtent windowFrameExclusion?
    ;

windowFrameUnits
    : 'ROWS'
    | 'RANGE'
    | 'GROUPS'
    ;

windowFrameExtent
    : windowFrameStart
    | windowFrameBetween
    ;

windowFrameStart
    : 'UNBOUNDED' 'PRECEDING'
    | number 'PRECEDING'
    | PARAM 'PRECEDING'
    | 'INTERVAL' expr interval 'PRECEDING'
    | 'CURRENT' 'ROW'
    ;

windowFrameBetween
    : 'BETWEEN' windowFrameBound 'AND' windowFrameBound
    ;

windowFrameBound
    : windowFrameStart
    | 'UNBOUNDED' 'FOLLOWING'
    | number 'FOLLOWING'
    | PARAM 'FOLLOWING'
    | 'INTERVAL' expr interval 'FOLLOWING'
    ;

windowFrameExclusion
    : 'EXCLUDE'
      ( 'CURRENT' 'ROW'
      | 'GROUP'
      | 'TIES'
      | 'NO' 'OTHERS'
      )
    ;

with
    : 'WITH' 'RECURSIVE'? cte ( ',' cte )*
    ;

cte
    : name columns? 'AS' '(' select ')'
    ;

groupByClause
    : 'GROUP' 'BY' orderExpression (',' orderExpression)* ( 'WITH' 'ROLLUP' )?
    | 'GROUP' 'BY' ( 'ROLLUP' | 'CUBE' ) '(' expr (',' expr)* ')'
    ;

orderBy
    : 'ORDER' 'BY' orderExpression (',' orderExpression)*
    ;

direction
    : 'ASC'
    | 'DESC'
    ;

fromClause
    : 'FROM' ('DUAL' | tableReferenceList)
    ;

tableReferenceList
    : tableReference (',' tableReference)*
    ;


tableReference
    // Note: we have also a tableRef rule for identifiers that reference a table anywhere.
    : ( tableFactor
      // ODBC syntax
      | '{' ( name | 'OJ' ) tableFactor joinedTable* '}'
      )
      joinedTable*
    ;

rowValueExplicit
    : 'ROW' '(' values? ')'
    ;

lockingClause
    : 'FOR' ( 'UPDATE' | 'SHARE' ) ('OF' tableAliasRefList)? ( 'SKIP' 'LOCKED' | 'NOWAIT' )?
    | 'LOCK' 'IN' 'SHARE' 'MODE'
    ;


// TODO inline items rule once wildcard is sorted out
items
    : (item | '*') (',' item)*
    ;

item
    : tableWild
    | expr alias?
    ;

alias
    : 'AS'? name
    ;

where
    : 'WHERE' expr
    ;

joinedTable
    // Same as joined_table in sql_yacc.yy, but with removed left recursion.
    :
    innerJoinType tableReference (
        'ON' expr
        | 'USING' '(' name (',' name)* ')'
    )?
    | outerJoinType tableReference (
        'ON' expr
        | 'USING' '(' name (',' name)* ')'
    )
    | naturalJoinType tableFactor
    ;

naturalJoinType
    : 'NATURAL' 'INNER'? 'JOIN'
    | 'NATURAL' ('LEFT' | 'RIGHT') 'OUTER'? 'JOIN'
    ;

innerJoinType
    : ('INNER' | 'CROSS')? 'JOIN'
    | 'STRAIGHT_JOIN'
    ;

outerJoinType
    : ('LEFT' | 'RIGHT') 'OUTER'? 'JOIN'
    ;

tableFactor
    : singleTable
    | singleTableParens
    | derivedTable
    | tableReferenceListParens
    | tableFunction
    ;

singleTable
    : qname usePartition? tableAlias? indexHintList? tablesampleClause?
    ;

singleTableParens
    : '(' (singleTable | singleTableParens) ')'
    ;

derivedTable
    : '(' select ')' tableAlias? columns?
    | 'LATERAL' '(' select ')' tableAlias? columns?
    ;

// This rule covers both: joined_table_parens and table_reference_list_parens from sql_yacc.yy.
// We can simplify that because we have unrolled the indirect left recursion in joined_table <-> table_reference.
tableReferenceListParens
    : '(' (tableReferenceList | tableReferenceListParens) ')'
    ;

tableFunction
    : 'JSON_TABLE' '(' expr ',' string columnsClause ')' tableAlias?
    ;

columnsClause
    : 'COLUMNS' '(' jtColumn (',' jtColumn)* ')'
    ;

jtColumn
    : name 'FOR' 'ORDINALITY'
    | name dataType (collate)? 'EXISTS'? 'PATH' string
        onEmptyOrErrorJsonTable?
    | 'NESTED' 'PATH' string columnsClause
    ;

onEmptyOrError
    : onEmpty onError?
    | onError
    ;

// One variation of the empty/error syntax that is going to be deprecated, but currently still allowed.
onEmptyOrErrorJsonTable
    : onEmptyOrError
    | onError onEmpty
    ;

onEmpty
    : jsonOnResponse 'ON' 'EMPTY'
    ;

onError
    : jsonOnResponse 'ON' 'ERROR'
    ;

jsonOnResponse
    : 'ERROR'
    | 'NULL'
    | 'DEFAULT' string
    ;

unionOption
    : 'DISTINCT'
    | 'ALL'
    ;

tableAlias
    : ('AS' | '=')? name
    ;

indexHintList
    : indexHint (',' indexHint)*
    ;

indexHint
    : indexHintType keyOrIndex indexHintClause? '(' indexList ')'
    | 'USE' keyOrIndex indexHintClause? '(' indexList? ')'
    ;

indexHintType
    : 'FORCE'
    | 'IGNORE'
    ;

keyOrIndex
    : 'KEY'
    | 'INDEX'
    ;

//constraintKeyType
//    : 'PRIMARY' 'KEY'
//    | 'UNIQUE' keyOrIndex?
//    ;

indexHintClause
    : 'FOR' ('JOIN' | 'ORDER' 'BY' | 'GROUP' 'BY')
    ;

indexList
    : indexListElement (',' indexListElement)*
    ;

indexListElement
    : name
    | 'PRIMARY'
    ;

//----------------------------------------------------------------------------------------------------------------------

updateStatement
    : with? 'UPDATE' 'LOW_PRIORITY'? 'IGNORE'? tableReferenceList 'SET' updateList where?
        orderBy? simpleLimitClause?
    ;

//----------------------------------------------------------------------------------------------------------------------

transactionOrLockingStatement
    : transactionStatement
    | savepointStatement
    | lockStatement
    | xaStatement
    ;

transactionStatement
    : 'START' 'TRANSACTION' startTransactionOptionList*
    | 'COMMIT' 'WORK'? ('AND' 'NO'? 'CHAIN')? (
        'NO'? 'RELEASE'
    )?
    // SET TRANSACTION is part of setStatement.
    ;

// BEGIN WORK is separated from transactional statements as it must not appear as part of a stored program.
beginWork
    : 'BEGIN' 'WORK'?
    ;

startTransactionOptionList
    : 'WITH' 'CONSISTENT' 'SNAPSHOT'
    | 'READ' ('WRITE' | 'ONLY')
    ;

savepointStatement
    : 'SAVEPOINT' name
    | 'ROLLBACK' 'WORK'? (
        'TO' 'SAVEPOINT'? name
        | ('AND' 'NO'? 'CHAIN')? ('NO'? 'RELEASE')?
    )
    | 'RELEASE' 'SAVEPOINT' name
    ;

lockStatement
    : 'LOCK' ('TABLES' | 'TABLE') lockItem (',' lockItem)*
    | 'LOCK' 'INSTANCE' 'FOR' 'BACKUP'
    | 'UNLOCK' ( 'TABLES' | 'TABLE' | 'INSTANCE')
    ;

lockItem
    : qname tableAlias? lockOption
    ;

lockOption
    : 'READ' 'LOCAL'?
    | 'LOW_PRIORITY'? 'WRITE' // low priority deprecated since 5.7
    ;

xaStatement
    : 'XA' (
        ('START' | 'BEGIN') xid ('JOIN' | 'RESUME')?
        | 'END' xid ('SUSPEND' ('FOR' 'MIGRATE')?)?
        | 'PREPARE' xid
        | 'COMMIT' xid ('ONE' 'PHASE')?
        | 'ROLLBACK' xid
        | 'RECOVER' xaConvert?
    )
    ;

xaConvert
    : 'CONVERT' 'XID'
    ;

xid
    : string (',' string (',' number)?)?
    ;

//----------------------------------------------------------------------------------------------------------------------

replicationStatement
    : 'PURGE' ('BINARY' | 'MASTER') 'LOGS' ( 'TO' textLiteral | 'BEFORE' expr )
    | 'CHANGE' ('MASTER' | 'REPLICATION' 'SOURCE') 'TO' sourceDefinitions channel?
    | 'RESET' resetOption (',' resetOption)*
    | 'RESET' 'PERSIST' (ifExists 'DEFAULT'? qname)?
    | startReplicaStatement
    | stopReplicaStatement
    | changeReplication
    | replicationLoad
    | groupReplication
    ;

resetOption
    : ('MASTER' | 'BINARY' 'LOGS' 'AND' 'GTIDS') ('TO' integer)?
    | replica 'ALL'? channel?
    ;

replicationLoad
    : 'LOAD' ('DATA' | 'TABLE' qname) 'FROM' 'MASTER'
    ;

sourceDefinitions
    : sourceDefinition (',' sourceDefinition)*
    ;

sourceDefinition
    : // source_def in sql_yacc.yy
    changeReplicationSourceHost '=' string
    | 'NETWORK_NAMESPACE' '=' string
    | changeReplicationSourceBind '=' string
    | changeReplicationSourceUser '=' string
    | changeReplicationSourcePassword '=' string
    | changeReplicationSourcePort '=' number
    | changeReplicationSourceConnectRetry '=' number
    | changeReplicationSourceRetryCount '=' number
    | changeReplicationSourceDelay '=' number
    | changeReplicationSourceSSL '=' number
    | changeReplicationSourceSSLCA '=' string
    | changeReplicationSourceSSLCApath '=' string
    | changeReplicationSourceTLSVersion '=' string
    | changeReplicationSourceSSLCert '=' string
    | changeReplicationSourceTLSCiphersuites '=' sourceTlsCiphersuitesDef
    | changeReplicationSourceSSLCipher '=' string
    | changeReplicationSourceSSLKey '=' string
    | changeReplicationSourceSSLVerifyServerCert '=' number
    | changeReplicationSourceSSLCLR '=' textLiteral
    | changeReplicationSourceSSLCLRpath '=' string
    | changeReplicationSourcePublicKey '=' string
    | changeReplicationSourceGetSourcePublicKey '=' number
    | changeReplicationSourceHeartbeatPeriod '=' number
    | 'IGNORE_SERVER_IDS' '=' serverIdList
    | changeReplicationSourceCompressionAlgorithm '=' string
    | changeReplicationSourceZstdCompressionLevel '=' number
    | changeReplicationSourceAutoPosition '=' number
    | 'PRIVILEGE_CHECKS_USER' '=' privilegeCheckDef
    | 'REQUIRE_ROW_FORMAT' '=' number
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK' '=' tablePrimaryKeyCheckDef
    | 'SOURCE_CONNECTION_AUTO_FAILOVER' '=' integer
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS' '='
        assignGtidsToAnonymousTransactionsDefinition
    | 'GTID_ONLY' '=' integer
    | sourceFileDef
    ;

changeReplicationSourceAutoPosition
    : 'MASTER_AUTO_POSITION'
    | 'SOURCE_AUTO_POSITION'
    ;

changeReplicationSourceHost
    : 'MASTER_HOST'
    | 'SOURCE_HOST'
    ;

changeReplicationSourceBind
    : 'MASTER_BIND'
    | 'SOURCE_BIND'
    ;

changeReplicationSourceUser
    : 'MASTER_USER'
    | 'SOURCE_USER'
    ;

changeReplicationSourcePassword
    : 'MASTER_PASSWORD'
    | 'SOURCE_PASSWORD'
    ;

changeReplicationSourcePort
    : 'MASTER_PORT'
    | 'SOURCE_PORT'
    ;

changeReplicationSourceConnectRetry
    : 'MASTER_CONNECT_RETRY'
    | 'SOURCE_CONNECT_RETRY'
    ;

changeReplicationSourceRetryCount
    : 'MASTER_RETRY_COUNT'
    | 'SOURCE_RETRY_COUNT'
    ;

changeReplicationSourceDelay
    : 'MASTER_DELAY'
    | 'SOURCE_DELAY'
    ;

changeReplicationSourceSSL
    : 'MASTER_SSL'
    | 'SOURCE_SSL'
    ;

changeReplicationSourceSSLCA
    : 'MASTER_SSL_CA'
    | 'SOURCE_SSL_CA'
    ;

changeReplicationSourceSSLCApath
    : 'MASTER_SSL_CAPATH'
    | 'SOURCE_SSL_CAPATH'
    ;

changeReplicationSourceSSLCipher
    : 'MASTER_SSL_CIPHER'
    | 'SOURCE_SSL_CIPHER'
    ;

changeReplicationSourceSSLCLR
    : 'MASTER_SSL_CRL'
    | 'SOURCE_SSL_CRL'
    ;

changeReplicationSourceSSLCLRpath
    : 'MASTER_SSL_CRLPATH'
    | 'SOURCE_SSL_CRLPATH'
    ;

changeReplicationSourceSSLKey
    : 'MASTER_SSL_KEY'
    | 'SOURCE_SSL_KEY'
    ;

changeReplicationSourceSSLVerifyServerCert
    : 'MASTER_SSL_VERIFY_SERVER_CERT'
    | 'SOURCE_SSL_VERIFY_SERVER_CERT'
    ;

changeReplicationSourceTLSVersion
    : 'MASTER_TLS_VERSION'
    | 'SOURCE_TLS_VERSION'
    ;

changeReplicationSourceTLSCiphersuites
    : 'MASTER_TLS_CIPHERSUITES'
    | 'SOURCE_TLS_CIPHERSUITES'
    ;

changeReplicationSourceSSLCert
    : 'MASTER_SSL_CERT'
    | 'SOURCE_SSL_CERT'
    ;

changeReplicationSourcePublicKey
    : 'MASTER_PUBLIC_KEY_PATH'
    | 'SOURCE_PUBLIC_KEY_PATH'
    ;

changeReplicationSourceGetSourcePublicKey
    : 'GET_MASTER_PUBLIC_KEY'
    | 'GET_SOURCE_PUBLIC_KEY'
    ;

changeReplicationSourceHeartbeatPeriod
    : 'MASTER_HEARTBEAT_PERIOD'
    | 'SOURCE_HEARTBEAT_PERIOD'
    ;

changeReplicationSourceCompressionAlgorithm
    : 'MASTER_COMPRESSION_ALGORITHM'
    | 'SOURCE_COMPRESSION_ALGORITHM'
    ;

changeReplicationSourceZstdCompressionLevel
    : 'MASTER_ZSTD_COMPRESSION_LEVEL'
    | 'SOURCE_ZSTD_COMPRESSION_LEVEL'
    ;

privilegeCheckDef
    : userName
    | 'NULL'
    ;

tablePrimaryKeyCheckDef
    : 'STREAM'
    | 'ON'
    | 'OFF'
    | 'GENERATE'
    ;

assignGtidsToAnonymousTransactionsDefinition
    : 'OFF'
    | 'LOCAL'
    | string
    ;

sourceTlsCiphersuitesDef
    : string
    | 'NULL'
    ;

sourceFileDef
    : sourceLogFile '=' string
    | sourceLogPos '=' number
    | 'RELAY_LOG_FILE' '=' string
    | 'RELAY_LOG_POS' '=' number
    ;

sourceLogFile
    : 'MASTER_LOG_FILE'
    | 'SOURCE_LOG_FILE'
    ;

sourceLogPos
    : 'MASTER_LOG_POS'
    | 'SOURCE_LOG_POS'
    ;

serverIdList
    : '(' (number (',' number)*)? ')'
    ;

changeReplication
    : 'CHANGE' 'REPLICATION' 'FILTER' filterDefinition (
        ',' filterDefinition
    )* channel?
    ;

filterDefinition
    : 'REPLICATE_DO_DB' '=' '(' filterDbList? ')'
    | 'REPLICATE_IGNORE_DB' '=' '(' filterDbList? ')'
    | 'REPLICATE_DO_TABLE' '=' '(' filterTableList? ')'
    | 'REPLICATE_IGNORE_TABLE' '=' '(' filterTableList? ')'
    | 'REPLICATE_WILD_DO_TABLE' '=' '(' filterStringList? ')'
    | 'REPLICATE_WILD_IGNORE_TABLE' '=' '(' filterStringList? ')'
    | 'REPLICATE_REWRITE_DB' '=' '(' filterDbPairList? ')'
    ;

filterDbList
    : name (',' name)*
    ;

filterTableList
    : qname (',' qname)*
    ;

filterStringList
    : filterWildDbTableString (',' filterWildDbTableString)*
    ;

filterWildDbTableString
    : string // sql_yacc.yy checks for the existance of at least one dot char in the string.
    ;

filterDbPairList
    : schemaIdentifierPair (',' schemaIdentifierPair)*
    ;

startReplicaStatement
    : 'START' replica replicaThreadOptions? ('UNTIL' replicaUntil)? userOption? passwordOption? defaultAuthOption?
        pluginDirOption? channel?
    ;

stopReplicaStatement
    : 'STOP' replica replicaThreadOptions? channel?
    ;

replicaUntil
    : (
        sourceFileDef
        | ('SQL_BEFORE_GTIDS' | 'SQL_AFTER_GTIDS') '=' string
        | 'SQL_AFTER_MTS_GAPS'
    ) (',' sourceFileDef)*
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

groupReplication
    : ('START' groupReplicationStartOptions? | 'STOP') 'GROUP_REPLICATION'
    ;

groupReplicationStartOptions
    : groupReplicationStartOption (',' groupReplicationStartOption)*
    ;

groupReplicationStartOption
    : groupReplicationUser
    | groupReplicationPassword
    | groupReplicationPluginAuth
    ;

groupReplicationUser
    : 'USER' '=' string
    ;

groupReplicationPassword
    : 'PASSWORD' '=' string
    ;

groupReplicationPluginAuth
    : 'DEFAULT_AUTH' '=' string
    ;

replica
    : // Part of the terminology cleanup starting with 8.0.24.
    'SLAVE'
    | 'REPLICA'
    ;

//----------------------------------------------------------------------------------------------------------------------

preparedStatement
    : 'PREPARE' name 'FROM' (textLiteral | name)
    | executeStatement
    | ('DEALLOCATE' | 'DROP') 'PREPARE' name
    ;

executeStatement
    : 'EXECUTE' name ('USING' name ( ',' name )*)?
    ;

//----------------------------------------------------------------------------------------------------------------------

cloneStatement
    : 'CLONE' (
        'LOCAL' 'DATA' 'DIRECTORY' equal? string
        // Clone remote has been removed in 8.0.14. This alt is taken out by the conditional 'REMOTE'.
        | 'REMOTE' ('FOR' 'REPLICATION')?
        | 'INSTANCE' 'FROM' user ':' number 'IDENTIFIED' 'BY'
            string dataDirSSL?
    )
    ;

dataDirSSL
    : ssl
    | 'DATA' 'DIRECTORY' equal? string ssl?
    ;

ssl
    : 'REQUIRE' 'NO'? 'SSL'
    ;

//----------------------------------------------------------------------------------------------------------------------

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
        ( ( createUserList | alterUser (',' alterUser)* ) createUserTail
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
    : user 'IDENTIFIED' 'BY' (
        string 'REPLACE' string retainCurrentPassword?
        | string retainCurrentPassword?
        | 'RANDOM' 'PASSWORD' ('REPLACE' string)? retainCurrentPassword?
    )
    | user 'IDENTIFIED' 'WITH' (
        name (
            'BY' string 'REPLACE' string retainCurrentPassword?
            | 'AS' textStringHash retainCurrentPassword?
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
    : 'CREATE' 'USER' ifNotExists? createUserList ('DEFAULT' 'ROLE' roleList)? createUserTail
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
    : 'DROP' 'USER' ifExists? userList
    ;

grantStatement
    : 'GRANT'
        ( roleOrPrivilegesList 'TO' userList ( 'WITH' 'ADMIN' 'OPTION' )?
        | (roleOrPrivilegesList | 'ALL' 'PRIVILEGES'?) 'ON' aclType? grantIdentifier 'TO' grantTargetList
            versionedRequireClause? grantOptions? grantAs?
        | 'PROXY' 'ON' user 'TO' grantTargetList ( 'WITH' 'GRANT' 'OPTION' )?
    )
    ;

grantTargetList
    : createUserList
    | userList
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

grantAs
    : 'AS' 'USER' withRoles?
    ;

versionedRequireClause
    : requireClause
    ;

renameUserStatement
    : 'RENAME' 'USER' user 'TO' user (
        ',' user 'TO' user
    )*
    ;

revokeStatement
    : 'REVOKE' (ifExists)? (
        roleOrPrivilegesList 'FROM' userList
        | roleOrPrivilegesList 'ON' aclType? grantIdentifier 'FROM' userList
        | 'ALL' 'PRIVILEGES'? (
            'ON' aclType? grantIdentifier
            | ',' 'GRANT' 'OPTION'
        ) 'FROM' userList
        | 'PROXY' 'ON' user 'FROM' userList
    ) (ignoreUnknownUser)?
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

//----------------------------------------------------------------------------------------------------------------------

tableAdministrationStatement
    : 'ANALYZE' noWriteToBinLog? 'TABLE' qnames histogram?
    | 'CHECK' 'TABLE' qnames checkOption*
    | 'CHECKSUM' 'TABLE' qnames ( 'QUICK' | 'EXTENDED' )?
    | 'OPTIMIZE' noWriteToBinLog? 'TABLE' qnames
    | 'REPAIR' noWriteToBinLog? 'TABLE' qnames repairType*
    ;

histogram
    : 'UPDATE' 'HISTOGRAM' 'ON' name (',' name)* histogramUpdateParam
    | 'DROP' 'HISTOGRAM' 'ON' name (',' name)*
    ;

histogramUpdateParam
    : ('WITH' INT_NUMBER 'BUCKETS')? ('MANUAL' | 'AUTO') 'UPDATE'?
    | 'USING' 'DATA' string
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

//----------------------------------------------------------------------------------------------------------------------

installStatement
    : 'INSTALL' ( 'PLUGIN' name 'SONAME' string | 'COMPONENT' strings ('SET' installSetValue (
        ',' installSetValue
    )*)? )
    ;

installSetRvalue
    : expr
    | 'ON'
    ;

// TODO replace w/ setter
installSetValue
    : ('GLOBAL' | 'PERSIST') lvalueVariable equal installSetRvalue
    ;

//----------------------------------------------------------------------------------------------------------------------

setStatement
    : 'SET'
      ( optionValueNoOptionType (',' (scope lvalueVariable equal expr | optionValueNoOptionType))*
      | scope? 'TRANSACTION' transactionCharacteristics
      | scope? lvalueVariable equal expr (',' (scope lvalueVariable equal expr | optionValueNoOptionType))*
      | 'PASSWORD' ('FOR' user)? equal ( string replacePassword? retainCurrentPassword? | 'PASSWORD' '(' string ')' )
      | 'PASSWORD' ('FOR' user)? 'TO' 'RANDOM' replacePassword? retainCurrentPassword?
      )
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
    : lvalueVariable equal expr
    | charset
//    | name equal expr
    | qname equal expr
    | 'NAMES' ( equal expr | name collate? | 'DEFAULT' )
    ;

//----------------------------------------------------------------------------------------------------------------------

showDatabasesStatement
    : 'SHOW' 'DATABASES' likeOrWhere?
    ;

showTablesStatement
    : 'SHOW' showCommandType? 'TABLES' inDb? likeOrWhere?
    ;

showTriggersStatement
    : 'SHOW' 'FULL'? 'TRIGGERS' inDb? likeOrWhere?
    ;

showEventsStatement
    : 'SHOW' 'EVENTS' inDb? likeOrWhere?
    ;

showTableStatusStatement
    : 'SHOW' 'TABLE' 'STATUS' inDb? likeOrWhere?
    ;

showOpenTablesStatement
    : 'SHOW' 'OPEN' 'TABLES' inDb? likeOrWhere?
    ;

showParseTreeStatement
    : 'SHOW' 'PARSE_TREE' statement
    ;

showPluginsStatement
    : 'SHOW' 'PLUGINS'
    ;

showProcessListStatement
    : 'SHOW' 'FULL'? 'PROCESSLIST'
    ;

showVariablesStatement
    : 'SHOW' scope? 'VARIABLES' likeOrWhere?
    ;

showCharacterSetStatement
    : 'SHOW' charset likeOrWhere?
    ;

showCollationStatement
    : 'SHOW' 'COLLATION' likeOrWhere?
    ;

showPrivilegesStatement
    : 'SHOW' 'PRIVILEGES'
    ;

showGrantsStatement
    : 'SHOW' 'GRANTS' ('FOR' user ('USING' userList)?)?
    ;

showCreateDatabaseStatement
    : 'SHOW' 'CREATE' 'DATABASE' ifNotExists? name
    ;

showCreateTableStatement
    : 'SHOW' 'CREATE' 'TABLE' qname
    ;

showCreateViewStatement
    : 'SHOW' 'CREATE' 'VIEW' qname
    ;

showMasterStatusStatement
    : 'SHOW' 'MASTER' 'STATUS'
    ;

showReplicaStatusStatement
    : 'SHOW' replica 'STATUS' channel?
    ;

showCreateProcedureStatement
    : 'SHOW' 'CREATE' 'PROCEDURE' qname
    ;

showCreateFunctionStatement
    : 'SHOW' 'CREATE' 'FUNCTION' qname
    ;

showCreateTriggerStatement
    : 'SHOW' 'CREATE' 'TRIGGER' qname
    ;

showCreateProcedureStatusStatement
    : 'SHOW' 'CREATE' 'PROCEDURE' 'STATUS' likeOrWhere?
    ;

showCreateFunctionStatusStatement
    : 'SHOW' 'CREATE' 'FUNCTION' 'STATUS' likeOrWhere?
    ;

showCreateProcedureCodeStatement
    : 'SHOW' 'CREATE' 'PROCEDURE' 'CODE' qname
    ;

showCreateFunctionCodeStatement
    : 'SHOW' 'CREATE' 'FUNCTION' 'CODE' qname
    ;

showCreateEventStatement
    : 'SHOW' 'CREATE' 'EVENT' qname
    ;

showCreateUserStatement
    : 'SHOW' 'CREATE' 'USER' user
    ;

showCommandType
    : 'FULL'
    | 'EXTENDED' 'FULL'?
    ;

engineOrAll
    : name
    | 'ALL'
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

//----------------------------------------------------------------------------------------------------------------------

otherAdministrativeStatement
    : 'BINLOG' textLiteral
    | 'CACHE' 'INDEX' keyCacheListOrParts 'IN' (
        name
        | 'DEFAULT'
    )
    | 'FLUSH' noWriteToBinLog? (
        flushTables
        | flushOption (',' flushOption)*
    )
    | 'KILL' ('CONNECTION' | 'QUERY')? expr
    | 'LOAD' 'INDEX' 'INTO' 'CACHE' preloadTail
    | 'SHUTDOWN'
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
    : keyOrIndex '(' keyUsageList? ')'
    ;

keyUsageElement
    : name
    | 'PRIMARY'
    ;

keyUsageList
    : keyUsageElement (',' keyUsageElement)*
    ;

flushOption
    : (
        'HOSTS'
        | 'PRIVILEGES'
        | 'STATUS'
        | 'USER_RESOURCES'
    )
    | logType? 'LOGS'
    | 'RELAY' 'LOGS' channel?
    | 'OPTIMIZER_COSTS'
    ;

logType
    : 'BINARY'
    | 'ENGINE'
    | 'ERROR'
    | 'GENERAL'
    | 'SLOW'
    ;

flushTables
    : ('TABLES' | 'TABLE') (
        'WITH' 'READ' 'LOCK'
        | name (',' name)* flushTablesOptions?
    )?
    ;

flushTablesOptions
    : 'FOR' 'EXPORT'
    | 'WITH' 'READ' 'LOCK'
    ;

preloadTail
    : qname adminPartition cacheKeyList? ('IGNORE' 'LEAVES')?
    | preloadList
    ;

preloadList
    : preloadKeys (',' preloadKeys)*
    ;

preloadKeys
    : qname cacheKeyList? ('IGNORE' 'LEAVES')?
    ;

adminPartition
    : 'PARTITION' '(' allOrPartitionNameList ')'
    ;

//----------------------------------------------------------------------------------------------------------------------

resourceGroupManagement
    : createResourceGroup
    | alterResourceGroup
    | setResourceGroup
    | dropResourceGroup
    ;

createResourceGroup
    : 'CREATE' 'RESOURCE' 'GROUP' name 'TYPE' equal? (
        'USER'
        | 'SYSTEM'
    ) resourceGroupVcpuList? resourceGroupPriority? resourceGroupEnableDisable?
    ;

resourceGroupVcpuList
    : 'VCPU' equal? vcpuNumOrRange (','? vcpuNumOrRange)*
    ;

vcpuNumOrRange
    : INT_NUMBER ('-' INT_NUMBER)?
    ;

resourceGroupPriority
    : 'THREAD_PRIORITY' equal? INT_NUMBER
    ;

resourceGroupEnableDisable
    : 'ENABLE'
    | 'DISABLE'
    ;

alterResourceGroup
    : 'ALTER' 'RESOURCE' 'GROUP' name resourceGroupVcpuList? resourceGroupPriority?
        resourceGroupEnableDisable? 'FORCE'?
    ;

setResourceGroup
    : 'SET' 'RESOURCE' 'GROUP' name ('FOR' threadIdList)?
    ;

threadIdList
    : integer (','? integer)*
    ;

dropResourceGroup
    : 'DROP' 'RESOURCE' 'GROUP' name 'FORCE'?
    ;

//----------------------------------------------------------------------------------------------------------------------

utilityStatement
    : describeStatement
    | explainStatement
    | 'HELP' name
    | 'USE' name
    | 'RESTART'
    ;

describeStatement
    : ('EXPLAIN' | 'DESCRIBE' | 'DESC') qname (
        string
        | qname
    )?
    ;

explainStatement
    : ('EXPLAIN' | 'DESCRIBE' | 'DESC') explainOptions? (
        'FOR' 'DATABASE' name
    )? explainableStatement
    ;

explainOptions
    : 'FORMAT' '=' name ( 'INTO' '@' name )?
    | 'EXTENDED'
    | 'ANALYZE'
    | 'ANALYZE' 'FORMAT' '=' name
    ;

explainableStatement
    : select
    | deleteStatement
    | insertStatement
    | replaceStatement
    | updateStatement
    | 'FOR' 'CONNECTION' integer
    ;

expr
    : boolPri (
        'IS' notRule? ('TRUE' | 'FALSE' | 'UNKNOWN')
    )?
    | 'NOT' expr
    | expr ('AND' | '&&') expr
    | expr 'XOR' expr
    | expr ('OR' | '||') expr
    ;

boolPri
    : predicate
    | boolPri 'IS' notRule? 'NULL'
    | boolPri compOp predicate
    | boolPri compOp ('ALL' | 'ANY') '(' select ')'
    ;

compOp
    : '='
    | '<=>'
    | '>='
    | '>'
    | '<='
    | '<'
    | '!='
    ;

predicate
    : bitExpr (
        notRule? predicateOperations
        | 'MEMBER' 'OF'? '(' simpleExpr ')'
        | 'SOUNDS' 'LIKE' bitExpr
    )?
    ;

predicateOperations
    : 'IN' ('(' select ')' | '(' expr (',' expr)* ')')
    | 'BETWEEN' bitExpr 'AND' predicate
    | 'LIKE' simpleExpr ('ESCAPE' simpleExpr)?
    | 'REGEXP' bitExpr
    ;

bitExpr
    : simpleExpr
    | bitExpr '^' bitExpr
    | bitExpr ( '*' | '/' | '%' | 'DIV' | 'MOD' ) bitExpr
    | bitExpr ('+' | '-') bitExpr
    | bitExpr ('+' | '-') 'INTERVAL' expr interval
    | bitExpr ('<<' | '>>') bitExpr
    | bitExpr '&' bitExpr
    | bitExpr '|' bitExpr
    ;

simpleExpr
    : qname jsonOperator?
    | runtimeFunctionCall
    | functionCall
    | simpleExpr 'COLLATE' name
    | literal
    | PARAM
//    | rvalueSystemOrUserVariable
    | qname ':=' expr
    | sumExpr windowingClause?
    | 'GROUPING' '(' expr (',' expr)* ')'
    | windowFunctionCall
    | simpleExpr 'CONCAT_PIPES' simpleExpr
    | ('+' | '-' | '~') simpleExpr
    | not2Rule simpleExpr
    | 'ROW'? '(' expr (',' expr)* ')'
    | 'EXISTS'? '(' select ')'
    | '{' name expr '}'
    | 'MATCH' identListArg 'AGAINST' '(' bitExpr fulltextOptions? ')'
    | 'BINARY' simpleExpr
    | 'CAST' '(' expr ('AT' 'LOCAL')? 'AS' castType ('ARRAY')? ')'
    | 'CAST' '(' expr 'AT' 'TIME' 'ZONE' 'INTERVAL'? string 'AS'
        'DATETIME' typeDatetimePrecision ')'
    | 'CASE' expr? (whenExpression thenExpression)+ elseExpression? 'END'
    | 'CONVERT' '(' expr ',' castType ')'
    | 'CONVERT' '(' expr 'USING' name ')'
    | 'DEFAULT' '(' qname ')'
    | 'VALUES' '(' qname ')'
    | 'INTERVAL' expr interval '+' expr
    ;


jsonOperator
    : '->' string
    | '->>' string
    ;

sumExpr
    : 'AVG' '(' 'DISTINCT'? 'ALL'? expr ')'
    | ('BIT_AND' | 'BIT_OR' | 'BIT_XOR') '(' 'ALL'? expr ')'
    | 'JSON_ARRAYAGG' '(' 'ALL'? expr ')'
    | 'JSON_OBJECTAGG' '(' 'ALL'? expr ',' 'ALL'? expr ')'
    | 'ST_COLLECT' '(' 'DISTINCT'? 'ALL'? expr ')'
    | 'COUNT' '(' ( 'ALL'? '*' | 'ALL'? expr | 'DISTINCT' expr (',' expr)* ) ')'
    | ('MIN' | 'MAX') '(' 'DISTINCT'? 'ALL'? expr ')'
    | ( 'STD' | 'VARIANCE' | 'STDDEV_SAMP' | 'VAR_SAMP' | 'SUM' ) '(' 'ALL'? expr ')'
    | 'SUM' '(' 'DISTINCT' 'ALL'? expr ')'
    | 'GROUP_CONCAT' '(' 'DISTINCT'? expr (',' expr)* orderBy? ( 'SEPARATOR' string )? ')'
    ;

windowFunctionCall
    : ( 'ROW_NUMBER' | 'RANK' | 'DENSE_RANK' | 'CUME_DIST' | 'PERCENT_RANK' ) '(' ')' windowingClause
    | 'NTILE' ( '(' integer ')' | '(' simpleExpr ')' ) windowingClause
    | ('LEAD' | 'LAG') '(' expr (',' expr (',' expr)? )? ')' nullTreatment? windowingClause
    | ('FIRST_VALUE' | 'LAST_VALUE') '(' expr ')' nullTreatment? windowingClause
    | 'NTH_VALUE' '(' expr ',' simpleExpr ')' ( 'FROM' ('FIRST' | 'LAST') )? nullTreatment? windowingClause
    ;

samplingMethod
    : 'SYSTEM'
    | 'BERNOULLI'
    ;

samplingPercentage
    : number
//    | '@' textOrIdentifier
    | name
    | PARAM
    ;

tablesampleClause
    : 'TABLESAMPLE' samplingMethod '(' samplingPercentage ')'
    ;

windowingClause
    : 'OVER' (name | windowSpec)
    ;

nullTreatment
    : ('RESPECT' | 'IGNORE') 'NULLS'
    ;

identListArg
    : qnames
    | '(' qnames ')'
    ;

fulltextOptions
    : 'IN' 'BOOLEAN' 'MODE'
    | 'IN' 'NATURAL' 'LANGUAGE' 'MODE' ( 'WITH' 'QUERY' 'EXPANSION' )?
    | 'WITH' 'QUERY' 'EXPANSION'
    ;

// function_call_keyword and function_call_nonkeyword in sql_yacc.yy.
runtimeFunctionCall
    // Function names that are keywords.
    : 'CHAR' '(' expr (',' expr)* ('USING' name)? ')'
    | 'CURRENT_USER' ('(' ')')?
    | 'DATE' '(' expr ')'
    | 'DAY' '(' expr ')'
    | 'HOUR' '(' expr ')'
    | 'INSERT' '(' expr ',' expr ',' expr ',' expr ')'
    | 'INTERVAL' '(' expr (',' expr)+ ')'
    | 'JSON_VALUE' '(' simpleExpr ',' textLiteral returningType? onEmptyOrError ')'
    | 'LEFT' '(' expr ',' expr ')'
    | 'MINUTE' '(' expr ')'
    | 'MONTH' '(' expr ')'
    | 'RIGHT' '(' expr ',' expr ')'
    | 'SECOND' '(' expr ')'
    | 'TIME' '(' expr ')'
    | 'TIMESTAMP' '(' expr (',' expr)? ')'
    | 'TRIM' '(' ( expr ('FROM' expr)? | 'LEADING' expr? 'FROM' expr | 'TRAILING' expr? 'FROM' expr | 'BOTH' expr? 'FROM' expr ) ')'
    | userFunction
    | 'VALUES' '(' expr ')'
    | 'YEAR' '(' expr ')'

    // Function names that are not keywords.
    | ('ADDDATE' | 'SUBDATE') '(' expr ',' ( expr | 'INTERVAL' expr interval ) ')'
    | 'CURDATE' ('(' ')')?
    | 'CURTIME' ('(' integer? ')')?
    | ('DATE_ADD' | 'DATE_SUB') '(' expr ',' 'INTERVAL' expr interval ')'
    | 'EXTRACT' '(' interval 'FROM' expr ')'
    | 'GET_FORMAT' '(' ('DATE' | 'TIME' | 'DATETIME' | 'TIMESTAMP') ',' expr ')'
    | 'LOG' '(' expr ( ',' expr )? ')'
    | 'NOW' ('(' integer? ')')?
    | 'POSITION' '(' bitExpr 'IN' expr ')'
    | substringFunction
    | 'SYSDATE' ('(' integer? ')')?
    | ('TIMESTAMPADD' | 'TIMESTAMPDIFF') '(' intervalTimeStamp ',' expr ',' expr ')'
    | 'UTC_DATE' ('(' ')')?
    | 'UTC_TIME' ('(' integer? ')')?
    | 'UTC_TIMESTAMP' ('(' integer? ')')?

    // Function calls with other conflicts.
    | 'ASCII' '(' expr ')'
    | 'CHARSET' '(' expr ')'
    | 'COALESCE' '(' expr (',' expr)* ')'
    | 'COLLATION' '(' expr ')'
    | 'DATABASE' '(' ')'
    | 'IF' '(' expr ',' expr ',' expr ')'
    | 'FORMAT' '(' expr ',' expr (',' expr)? ')'
    | 'MICROSECOND' '(' expr ')'
    | 'MOD' '(' expr ',' expr ')'
    | 'PASSWORD' '(' expr ')'
    | 'QUARTER' '(' expr ')'
    | 'REPEAT' '(' expr ',' expr ')'
    | 'REPLACE' '(' expr ',' expr ',' expr ')'
    | 'REVERSE' '(' expr ')'
    | 'ROW_COUNT' '(' ')'
    | 'TRUNCATE' '(' expr ',' expr ')'
    | 'WEEK' '(' expr (',' expr)? ')'
    | 'WEIGHT_STRING' '(' expr (
        ('AS' 'CHAR' '(' integer ')')?
        | 'AS' 'BINARY' '(' integer ')'
        | ',' number ',' number ',' number
    ) ')'
    | geometryFunction
    ;

// JSON_VALUE's optional JSON returning clause.
returningType
    :
    // The default returning type is CHAR(512). (The max length of 512
    // is chosen so that the returned values are not handled as BLOBs
    // internally. See CONVERT_IF_BIGGER_TO_BLOB.)
    'RETURNING' castType
    ;

geometryFunction
    : 'GEOMETRYCOLLECTION' '(' (expr (',' expr)*)? ')'
    | 'LINESTRING' '(' expr (',' expr)* ')'
    | 'MULTILINESTRING' '(' expr (',' expr)* ')'
    | 'MULTIPOINT' '(' expr (',' expr)* ')'
    | 'MULTIPOLYGON' '(' expr (',' expr)* ')'
    | 'POINT' '(' expr ',' expr ')'
    | 'POLYGON' '(' expr (',' expr)* ')'
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

substringFunction
    : 'SUBSTRING' '(' expr (
        ',' expr (',' expr)?
        | 'FROM' expr ('FOR' expr)?
    ) ')'
    ;

functionCall
    : IDENTIFIER '(' (udfExpr ( ',' udfExpr )*)? ')'   // For both UDF + other functions.
    | qname '(' (expr (',' expr)*)? ')' // Other functions only.
    ;

udfExpr
    : expr alias?
    ;

//userVariable
//    : '@' name
//    | AT_TEXT_SUFFIX
//    ;

//rvalueSystemOrUserVariable
//    : userVariable
//    | '@@' rvalueSystemVariableType? qname
//    ;

lvalueVariable
    :  'DEFAULT'? qname
    ;

whenExpression
    : 'WHEN' expr
    ;

thenExpression
    : 'THEN' expr
    ;

elseExpression
    : 'ELSE' expr
    ;

castType
    : 'BINARY' fieldLength?
    | 'CHAR' fieldLength? charsetWithOptBinary?
    | nchar fieldLength?
    | 'SIGNED' ( 'INT' | 'INTEGER' )?
    | 'UNSIGNED' ( 'INT' | 'INTEGER' )?
    | 'DATE'
    | 'YEAR'
    | 'TIME' typeDatetimePrecision?
    | 'DATETIME' typeDatetimePrecision?
    | ('DEC' | 'DECIMAL' ) floatOptions?
    | 'JSON'
    | realType
    | 'FLOAT' (floatOptions)?
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
    | 'NOT2' // A NOT with a different (higher) operator precedence.
    ;

not2Rule
    : '!'
    | 'NOT2'
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
    : expr direction?
    ;

channel
    : 'FOR' 'CHANNEL' string
    ;

//----------------- Stored routines rules ------------------------------------------------------------------------------

// Compound syntax for stored procedures, stored functions, triggers and events.
// Implements both, sp_proc_stmt and ev_sql_stmt_inner from the server grammar.
compoundStatement
    : statement
    | returnStatement
    | ifStatement
    | caseStatement
    | labeledBlock
    | beginEndBlock
    | labeledControl
    | unlabeledControl
    | leaveStatement
    | iterateStatement
    | cursorOpen
    | cursorFetch
    | cursorClose
    ;

returnStatement
    : 'RETURN' expr
    ;

ifStatement
    : 'IF' ifBody 'END' 'IF'
    ;

ifBody
    : expr thenStatement ('ELSEIF' ifBody | 'ELSE' compoundStatementList)?
    ;

thenStatement
    : 'THEN' compoundStatementList
    ;

compoundStatementList
    : (compoundStatement ';')+
    ;

caseStatement
    : 'CASE' expr? (whenExpression thenStatement)+ elseStatement? 'END' 'CASE'
    ;

elseStatement
    : 'ELSE' compoundStatementList
    ;

labeledBlock
    : name ':' beginEndBlock (name)?
    ;

beginEndBlock
    : 'BEGIN' spDeclarations? compoundStatementList? 'END'
    ;

labeledControl
    : name ':' unlabeledControl (name)?
    ;

unlabeledControl
    : loopBlock
    | whileDoBlock
    | repeatUntilBlock
    ;

loopBlock
    : 'LOOP' compoundStatementList 'END' 'LOOP'
    ;

whileDoBlock
    : 'WHILE' expr 'DO' compoundStatementList 'END' 'WHILE'
    ;

repeatUntilBlock
    : 'REPEAT' compoundStatementList 'UNTIL' expr 'END' 'REPEAT'
    ;

spDeclarations
    : (spDeclaration ';')+
    ;

spDeclaration
    : variableDeclaration
    | conditionDeclaration
    | handlerDeclaration
    | cursorDeclaration
    ;

variableDeclaration
    : 'DECLARE' name (',' name)* dataType collate? ('DEFAULT' expr)?
    ;

conditionDeclaration
    : 'DECLARE' name 'CONDITION' 'FOR' spCondition
    ;

spCondition
    : number
    | sqlstate
    ;

sqlstate
    : 'SQLSTATE' 'VALUE'? textLiteral
    ;

handlerDeclaration
    : 'DECLARE' ('CONTINUE' | 'EXIT' | 'UNDO') 'HANDLER' 'FOR' handlerCondition (
        ',' handlerCondition
    )* compoundStatement
    ;

handlerCondition
    : spCondition
    | name
    | 'SQLWARNING'
    | notRule 'FOUND'
    | 'SQLEXCEPTION'
    ;

cursorDeclaration
    : 'DECLARE' name 'CURSOR' 'FOR' select
    ;

iterateStatement
    : 'ITERATE' name
    ;

leaveStatement
    : 'LEAVE' name
    ;

getDiagnosticsStatement
    : 'GET' ('CURRENT' | 'STACKED')? 'DIAGNOSTICS' (
        statementInformationItem (',' statementInformationItem)*
        | 'CONDITION' qname conditionInformationItem (
            ',' conditionInformationItem
        )*
    )
    ;

statementInformationItem
    : name '=' ('NUMBER' | 'ROW_COUNT')
    ;

conditionInformationItem
    : name '=' ( signalInformationItemName | 'RETURNED_SQLSTATE' )
    ;

signalInformationItemName
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

signalStatement
    : ( 'SIGNAL' | 'RESIGNAL' ) (name | sqlstate) ( 'SET' signalInformationItem (',' signalInformationItem)* )?
    ;

signalInformationItem
    : signalInformationItemName '=' qname
    ;

cursorOpen
    : 'OPEN' name
    ;

cursorClose
    : 'CLOSE' name
    ;

cursorFetch
    : 'FETCH' ('NEXT'? 'FROM')? name 'INTO' name (',' name)*
    ;

//----------------- Supplemental rules ---------------------------------------------------------------------------------

// Schedules in CREATE/ALTER EVENT.
schedule
    : 'AT' expr
    | 'EVERY' expr interval ('STARTS' expr)? ('ENDS' expr)?
    ;

columnDefinition
    : name fieldDefinition checkOrReferences?
    ;

checkOrReferences
    : checkConstraint
    | references
    ;

checkConstraint
    : 'CHECK' '(' expr ')'
    ;

constraintEnforcement
    : 'NOT'? 'ENFORCED'
    ;

tableConstraintDef
    : ('KEY' | 'INDEX') indexNameAndType? keyListWithExpression indexOption*
    | 'FULLTEXT' keyOrIndex? (name)? keyListWithExpression fulltextIndexOption*
    | 'SPATIAL' keyOrIndex? (name)? keyListWithExpression (commonIndexOption)*
    | constraintName? (
        ('PRIMARY' 'KEY' | 'UNIQUE' keyOrIndex?) indexNameAndType? keyListWithExpression indexOption*
        | 'FOREIGN' 'KEY' (name)? keyList references
        | checkConstraint constraintEnforcement?
    )
    ;

constraintName
    : 'CONSTRAINT' name?
    ;

fieldDefinition
    : dataType (
        columnAttribute*
        | collate? ('GENERATED' 'ALWAYS')? 'AS' '(' expr ')' (
            'VIRTUAL'
            | 'STORED'
        )? columnAttribute*
    )
    ;

columnAttribute
    : 'NOT'? null
    | 'NOT' 'SECONDARY'
    | 'DEFAULT' ( nowOrSignedLiteral | '(' expr ')' )
    | 'ON' 'UPDATE' 'NOW' ('(' integer? ')')?
    | 'AUTO_INCREMENT'
    | 'SERIAL' 'DEFAULT' 'VALUE'
    | 'PRIMARY'? 'KEY'
    | 'UNIQUE' 'KEY'?
    | 'COMMENT' textLiteral
    | collate
    | 'COLUMN_FORMAT' columnFormat
    | 'STORAGE' storageMedia
    | 'SRID' integer
    | constraintName? checkConstraint
    | constraintEnforcement
    | 'ENGINE_ATTRIBUTE' '='? string
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? string
    | visibility
    ;

columnFormat
    : 'FIXED'
    | 'DYNAMIC'
    | 'DEFAULT'
    ;

storageMedia
    : 'DISK'
    | 'MEMORY'
    | 'DEFAULT'
    ;

now
    : 'NOW' ( '(' INT_NUMBER? ')' )?
    ;

nowOrSignedLiteral
    : now
    | signedLiteral
    ;

references
    : 'REFERENCES' qname ('(' name (',' name)* ')')? (
        'MATCH' ('FULL' | 'PARTIAL' | 'SIMPLE')
    )? (
        'ON' 'UPDATE' deleteOption (
            'ON' 'DELETE' deleteOption
        )?
        | 'ON' 'DELETE' deleteOption (
            'ON' 'UPDATE' deleteOption
        )?
    )?
    ;

deleteOption
    : ('RESTRICT' | 'CASCADE')
    | 'SET' null
    | 'SET' 'DEFAULT'
    | 'NO' 'ACTION'
    ;

keyList
    : '(' keyPart (',' keyPart)* ')'
    ;

keyPart
    : name fieldLength? direction?
    ;

keyListWithExpression
    : '(' keyPartOrExpression (',' keyPartOrExpression)* ')'
    ;

keyPartOrExpression
    : // key_part_with_expression in sql_yacc.yy.
    keyPart
    | '(' expr ')' direction?
    ;

indexType
    : ('BTREE' | 'RTREE' | 'HASH')
    ;

indexOption
    : commonIndexOption
    | indexTypeClause
    ;

// These options are common for all index types.
commonIndexOption
    : 'KEY_BLOCK_SIZE' '='? number
    | 'COMMENT' textLiteral
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

//dataTypeDefinition
//    : // For external use only. Don't reference this in the normal grammar.
//    dataType EOF
//    ;

dataType
    : // type in sql_yacc.yy
    (
        'INT'
        | 'TINYINT'
        | 'SMALLINT'
        | 'MEDIUMINT'
        | 'BIGINT'
    ) fieldLength? fieldOptions?
    | ('REAL' | 'DOUBLE' 'PRECISION'?) (floatOptions)? fieldOptions?
    | ('FLOAT' | 'DECIMAL' | 'NUMERIC' | 'FIXED') floatOptions? fieldOptions?
    | 'BIT' fieldLength?
    | ('BOOL' | 'BOOLEAN')
    | 'CHAR' fieldLength? charsetWithOptBinary?
    | nchar fieldLength? 'BINARY'?
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
    | ('MEDIUMBLOB' | 'LONGBLOB')
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
    | (
        'GEOMETRY'
        | 'GEOMETRYCOLLECTION'
        | 'POINT'
        | 'MULTIPOINT'
        | 'LINESTRING'
        | 'MULTILINESTRING'
        | 'POLYGON'
        | 'MULTIPOLYGON'
    )
    ;

nchar
    : 'NCHAR'
    | 'NATIONAL' 'CHAR'
    ;

realType
    : 'REAL'
    | 'DOUBLE' 'PRECISION'?
    ;

fieldLength
    : '(' (integer | DECIMAL_NUMBER) ')'
    ;

fieldOptions
    : ('SIGNED' | 'UNSIGNED' | 'ZEROFILL')+
    ;

charsetWithOptBinary
    : ('ASCII' 'BINARY'? | 'BINARY' 'ASCII')
    | ('UNICODE' 'BINARY'? | 'BINARY' 'UNICODE')
    | 'BYTE'
    | charset 'BINARY'?
    | 'BINARY' (charset)?
    ;

typeDatetimePrecision
    : '(' INT_NUMBER ')'
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
    | 'SECONDARY_ENGINE' equal? ( 'NULL' | name )
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
    | 'UNION' '='? '(' qnames ')'
    | defaultCharset
    | defaultCollation
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

defaultCollation
    : 'DEFAULT'? 'COLLATE' '='? name
    ;

defaultEncryption
    : 'DEFAULT'? 'ENCRYPTION' '='? string
    ;

defaultCharset
    : 'DEFAULT'? charset '='? name
    ;

// Partition rules for CREATE/ALTER TABLE.
partitionClause
    : 'PARTITION' 'BY' partitionTypeDef (
        'PARTITIONS' integer
    )? subPartitions? partitionDefinitions?
    ;

partitionTypeDef
    : 'LINEAR'? 'KEY' partitionKeyAlgorithm? '(' (name (',' name)*)? ')'
    | 'LINEAR'? 'HASH' '(' bitExpr ')'
    | ('RANGE' | 'LIST') (
        '(' bitExpr ')'
        | 'COLUMNS' '(' (name (',' name)*)? ')'
    )
    ;

subPartitions
    : 'SUBPARTITION' 'BY' 'LINEAR'? (
        'HASH' '(' bitExpr ')'
        | 'KEY' partitionKeyAlgorithm? '(' name (',' name)* ')'
    ) ('SUBPARTITIONS' integer)?
    ;

partitionKeyAlgorithm
    : // Actually only 1 and 2 are allowed. Needs a semantic check.
    'ALGORITHM' '=' integer
    ;

partitionDefinitions
    : '(' partitionDefinition (',' partitionDefinition)* ')'
    ;

partitionDefinition
    : 'PARTITION' name (
        'VALUES' 'LESS' 'THAN' (
            partitionValueItemListParen
            | 'MAXVALUE'
        )
        | 'VALUES' 'IN' partitionValuesIn
    )? partitionOption* (
        '(' subpartitionDefinition (',' subpartitionDefinition)* ')'
    )?
    ;

partitionValuesIn
    : partitionValueItemListParen
    | '(' partitionValueItemListParen (
        ',' partitionValueItemListParen
    )* ')'
    ;

partitionOption
    : 'TABLESPACE' '='? name
    | 'STORAGE'? 'ENGINE' '='? name
    | 'NODEGROUP' '='? integer
    | ('MAX_ROWS' | 'MIN_ROWS') '='? integer
    | ('DATA' | 'INDEX') 'DIRECTORY' '='? textLiteral
    | 'COMMENT' '='? textLiteral
    ;

subpartitionDefinition
    : 'SUBPARTITION' name partitionOption*
    ;

partitionValueItemListParen
    : '(' partitionValueItem (',' partitionValueItem)* ')'
    ;

partitionValueItem
    : bitExpr
    | 'MAXVALUE'
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
    : name typeWithOptCollate
    ;

collate
    : 'COLLATE' name
    ;

typeWithOptCollate
    : dataType collate?
    ;

schemaIdentifierPair
    : '(' name ',' name ')'
    ;

updateList
    : updateElement (',' updateElement)*
    ;

updateElement
    : qname '=' (expr | 'DEFAULT')
    ;

fieldsClause
    : 'COLUMNS' fieldTerm+
    ;

fieldTerm
    : 'TERMINATED' 'BY' string
    | 'OPTIONALLY'? 'ENCLOSED' 'BY' string
    | 'ESCAPED' 'BY' string
    ;

linesClause
    : 'LINES' lineTerm+
    ;

lineTerm
    : ('TERMINATED' | 'STARTING') 'BY' string
    ;

userList
    : user (',' user)*
    ;

createUserList
    : createUser (',' createUser)*
    ;

createUser
    : user
        ( identification createUserWithMfa?
        | identifiedWithPlugin initialAuth?
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
    : 'IDENTIFIED' 'WITH' name 'AS' textStringHash
    ;

identifiedWithPluginByPassword
    : 'IDENTIFIED' 'WITH' name 'BY' string
    ;

identifiedWithPluginByRandomPassword
    : 'IDENTIFIED' 'WITH' name 'BY' 'RANDOM' 'PASSWORD'
    ;

initialAuth
    : 'INITIAL' 'AUTHENTICATION' (
        identifiedByRandomPassword
        | identifiedWithPluginAsAuth
        | identifiedByPassword
    )
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
    | factor 'FINISH' 'REGISTRATION' 'SET' 'CHALLENGE_RESPONSE' 'AS' textStringHash
    ;

factor
    : number 'FACTOR'
    ;

replacePassword
    : 'REPLACE' string
    ;

userName
    : name name?
    ;

user
    : userName
    | 'CURRENT_USER' ('(' ')')?
    ;

likeClause
    : 'LIKE' string
    ;

likeOrWhere
    : likeClause
    | where
    ;

onlineOption
    : 'ONLINE'
    | 'OFFLINE'
    ;

noWriteToBinLog
    : 'LOCAL'
    | 'NO_WRITE_TO_BINLOG'
    ;

usePartition
    : 'PARTITION' '(' name (',' name)* ')'
    ;

columns
    : '(' name (',' name)* ')'
    ;

insertIdentifier
    : qname
    | tableWild
    ;

tableWild
    : name '.' (name '.')? '*'
    ;

tableRefWithWildcard
    : qname
    ;

qnames
    : qname (',' qname)*
    ;

tableAliasRefList
    : tableRefWithWildcard (',' tableRefWithWildcard)*
    ;

qname
    : '.'? name ( '.' name ( '.' name )? )? // ('.' '*')?
    ;

integer
    : INT_NUMBER
    | HEX_NUMBER
    ;

signedLiteral
    : literal
    | '+' number
    | '-' number
    ;

literal
    : textLiteral
    | number
    | temporalLiteral
    | null
    | boolLiteral
//    | UNDERSCORE_CHARSET? (HEX_NUMBER | BIN_NUMBER)
    ;

string
    : STRING+
    | NCHAR_TEXT
    | HEX_NUMBER
    | BIN_NUMBER
//    | DOUBLE_QUOTED_TEXT
    ;

textStringHash
    : string
    | HEX_NUMBER
    ;

textLiteral
//    : (UNDERSCORE_CHARSET? textStringLiteral | NCHAR_TEXT) textStringLiteral*
    : NCHAR_TEXT string+
    ;

strings
    : string (',' string)*
    ;

number
    : INT_NUMBER
    | DECIMAL_NUMBER
    | HEX_NUMBER
//    | FLOAT_NUMBER
    ;

boolLiteral
    : 'TRUE'
    | 'FALSE'
    ;

// In sql_yacc.cc both 'NULL' and '\N' are mapped to 'NULL'(which is our nullLiteral).
null
    : 'NULL' | '\\N' ;

temporalLiteral
    : 'DATE' STRING
    | 'TIME' STRING
    | 'TIMESTAMP' STRING
    ;

floatOptions
    : fieldLength
    | '(' INT_NUMBER ',' INT_NUMBER ')'
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
      	| 'NOT2'
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



// The MySQL server parser uses custom code in its lexer to allow base alphanum chars (and ._$) as variable name.
// For this it handles user variables in 2 different ways and we have to model this to match that behavior.

//AT_TEXT_SUFFIX
//    : '@' (DIGIT | [A-Z_$] | '.')+
//    ;

PARAM
    : '?'
    ;

fragment DIGIT
    : [0-9]
    ;

fragment DIGITS
    : DIGIT+
    ;

fragment HEXDIGIT
    : [0-9A-F]
    ;

// Only lower case 'x' and 'b' count for hex + bin numbers. Otherwise it's an identifier.
HEX_NUMBER
options {
    caseInsensitive = false;
}

    : ('0x' HEXDIGIT+)
    | ('x\'' HEXDIGIT+ '\'')
    ;

BIN_NUMBER
options {
    caseInsensitive = false;
}
    : ('0b' [01]+)
    | ('b\'' [01]+ '\'')
    ;

INT_NUMBER
    : DIGITS
    ;

// Float types must be handled first or the DOT_IDENTIIFER rule will make them to identifiers
// (if there is no leading digit before the dot).
//DECIMAL_NUMBER
//    : DIGITS? '.' DIGITS
//    ;
//
//FLOAT_NUMBER
//    : (DIGITS? '.')? DIGITS 'E' ('-' | '+')? DIGITS
//    ;

DECIMAL_NUMBER
  : ( DIGITS ( '.' DIGITS? )? | '.' DIGITS ) ( 'E' [-+]? DIGITS )?
//  | '0x' HEX_DIGIT+
  ;


//// Special rule that should also match all keywords if they are directly preceded by a dot.
//// Hence it's defined before all keywords.
//// Here we make use of the ability in our base lexer to emit multiple tokens with a single rule.
//DOT_IDENTIFIER
//    : '.' LETTER_WHEN_UNQUOTED_NO_DIGIT LETTER_WHEN_UNQUOTED* -> type(IDENTIFIER)
//    ;




//// The underscore charset token is used to defined the repertoire of a string, though it conflicts
//// with normal identifiers, which also can start with an underscore.
//UNDERSCORE_CHARSET
//    : '_' [a-z0-9]+
//    ;

//// Identifiers might start with a digit, even though it is discouraged, and may not consist entirely of digits only.
//// All keywords above are automatically excluded.
//IDENTIFIER
//    : DIGITS+ 'E' (LETTER_WHEN_UNQUOTED_NO_DIGIT LETTER_WHEN_UNQUOTED*)?
//    // Have to exclude float pattern, as this rule matches more.
//    | DIGITS+ LETTER_WITHOUT_FLOAT_PART LETTER_WHEN_UNQUOTED*
//    | LETTER_WHEN_UNQUOTED_NO_DIGIT LETTER_WHEN_UNQUOTED*
//    ; // INT_NUMBER matches first if there are only digits.


// MySQL supports automatic concatenation of multiple single and double quoted strings if they follow each other as separate
// tokens. This is reflected in the `textLiteral` parser rule.
// Here we handle duplication of quotation chars only (which must be replaced by a single char in the target code).

//DOUBLE_QUOTED_TEXT
//    : ( '"' (('\\')? .)*? '"' )+ ;
//
//BACK_TICK_QUOTED_ID
//    : '`' (('\\')? .)*? '`'
//    ;

IDENTIFIER
  : '"' ( ~'"' | '""' )* '"'
  | '`' ( ~'`' | '``' )* '`'
//  | [A-Z_\u007F-\uFFFF] [A-Z0-9_$\u007F-\uFFFF]*
  | ('@'? '@')? [A-Z0-9_$\u007F-\uFFFF]+
  ;

// TODO from NormalSQL.g4. synthesize these STRING and string rules?
//STRING
//  : '\'' ( ~'\'' | '\'\'' )* '\'' ;

STRING
    : ( '\'' (('\\')? .)*? '\'' )+
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
