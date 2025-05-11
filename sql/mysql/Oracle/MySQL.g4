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
    | uninstallStatement
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
    | showEngineLogsStatement
    | showEngineMutexStatement
    | showEngineStatusStatement
    | showColumnsStatement
    | showBinaryLogsStatement
    | showBinaryLogStatusStatement
    | showReplicasStatement
    | showBinlogEventsStatement
    | showRelaylogEventsStatement
    | showKeysStatement
    | showEnginesStatement
    | showCountWarningsStatement
    | showCountErrorsStatement
    | showWarningsStatement
    | showErrorsStatement
    | showProfilesStatement
    | showProfileStatement
    | showStatusStatement
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
    | resignalStatement
    ;

//----------------- DDL statements -------------------------------------------------------------------------------------

alterStatement
    : 'ALTER' (
        alterTable
        | alterDatabase
        | 'PROCEDURE' qualifiedIdentifier (routineCreateOption+)?
        | 'FUNCTION' qualifiedIdentifier (routineCreateOption+)?
        | alterView
        | alterEvent
        | alterTablespace
        | alterUndoTablespace
        | alterLogfileGroup
        | alterServer
        // ALTER USER is part of the user management rule.
        | alterInstanceStatement
    )
    ;

alterDatabase
    : 'DATABASE' identifier alterDatabaseOption+
    ;

alterDatabaseOption
    : createDatabaseOption
    | 'READ' 'ONLY' '='? ternaryOption
    ;

alterEvent
    : definerClause? 'EVENT' qualifiedIdentifier ('ON' 'SCHEDULE' schedule)? (
        'ON' 'COMPLETION' 'NOT'? 'PRESERVE'
    )? ('RENAME' 'TO' identifier)? (
        'ENABLE'
        | 'DISABLE' ('ON' replica)?
    )? ('COMMENT' textLiteral)? ('DO' compoundStatement)?
    ;

alterLogfileGroup
    : 'LOGFILE' 'GROUP' identifier 'ADD' 'UNDOFILE' textLiteral alterLogfileGroupOptions?
    ;

alterLogfileGroupOptions
    : alterLogfileGroupOption (','? alterLogfileGroupOption)*
    ;

alterLogfileGroupOption
    : tsOptionInitialSize
    | tsOptionEngine
    | tsOptionWait
    ;

alterServer
    : 'SERVER' textOrIdentifier serverOptions
    ;

alterTable
    : onlineOption? 'TABLE' tableRef alterTableActions?
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
        | 'PARTITIONS' real_ulong_number
    )
    | 'DROP' 'PARTITION' identifierList
    | 'REBUILD' 'PARTITION' noWriteToBinLog? allOrPartitionNameList

    // yes, twice "no write to bin log".
    | 'OPTIMIZE' 'PARTITION' noWriteToBinLog? allOrPartitionNameList noWriteToBinLog?
    | 'ANALYZE' 'PARTITION' noWriteToBinLog? allOrPartitionNameList
    | 'CHECK' 'PARTITION' allOrPartitionNameList checkOption*
    | 'REPAIR' 'PARTITION' noWriteToBinLog? allOrPartitionNameList repairType*
    | 'COALESCE' 'PARTITION' noWriteToBinLog? real_ulong_number
    | 'TRUNCATE' 'PARTITION' allOrPartitionNameList
    | 'REORGANIZE' 'PARTITION' noWriteToBinLog? ( identifierList 'INTO' partitionDefinitions )?
    | 'EXCHANGE' 'PARTITION' identifier 'WITH' 'TABLE' tableRef withValidation?
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
        identifier fieldDefinition checkOrReferences? place?
        | '(' tableElementList ')'
    )
    | 'ADD' tableConstraintDef
    | 'CHANGE' 'COLUMN'? identifier identifier fieldDefinition place?
    | 'MODIFY' 'COLUMN'? identifier fieldDefinition place?
    | 'DROP' (
        'COLUMN'? identifier restrict?
        | 'FOREIGN' 'KEY' identifier
        | 'PRIMARY' 'KEY'
        | keyOrIndex fieldIdentifier
        | 'CHECK' identifier
        | 'CONSTRAINT' identifier
    )
    | 'DISABLE' 'KEYS'
    | 'ENABLE' 'KEYS'
    | 'ALTER' 'COLUMN'? identifier (
        'SET' 'DEFAULT' (
            exprWithParentheses
            | signedLiteralOrNull
        )
        | 'DROP' 'DEFAULT'
        | 'SET' visibility
    )
    | 'ALTER' 'INDEX' fieldIdentifier visibility
    | 'ALTER' 'CHECK' identifier constraintEnforcement
    | 'ALTER' 'CONSTRAINT' identifier constraintEnforcement
    | 'RENAME' 'COLUMN' identifier 'TO' identifier
    | 'RENAME' ('TO' | 'AS')? tableName
    | 'RENAME' keyOrIndex fieldIdentifier 'TO' identifier
    | 'CONVERT' 'TO' charset (
        'DEFAULT'
        | charsetName
    ) collate?
    | 'FORCE'
    | 'ORDER' 'BY' alterOrderList
    ;

place
    : 'AFTER' identifier
    | 'FIRST'
    ;

restrict
    : 'RESTRICT'
    | 'CASCADE'
    ;

alterOrderList
    : identifier direction? (',' identifier direction?)*
    ;

alterAlgorithmOption
    : 'ALGORITHM' '='? ('DEFAULT' | identifier)
    ;

alterLockOption
    : 'LOCK' '='? ('DEFAULT' | identifier)
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
    | identifierList
    ;

alterTablespace
    : 'TABLESPACE' identifier (
        ('ADD' | 'DROP') 'DATAFILE' textLiteral alterTablespaceOptions?
        | 'RENAME' 'TO' identifier
        | alterTablespaceOptions
    )
    ;

alterUndoTablespace
    : 'UNDO' 'TABLESPACE' identifier 'SET' (
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
    : 'INITIAL_SIZE' '='? sizeNumber
    | tsOptionAutoextendSize
    | tsOptionMaxSize
    | tsOptionEngine
    | tsOptionWait
    | tsOptionEncryption
    | tsOptionEngineAttribute
    ;

//changeTablespaceOption
//    : 'INITIAL_SIZE' '='? sizeNumber
//    | tsOptionAutoextendSize
//    | tsOptionMaxSize
//    ;

alterView
    : viewAlgorithm? definerClause? viewSuid? 'VIEW' viewRef viewTail
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
    : 'INSTANCE' 'ROTATE' textOrIdentifier 'MASTER' 'KEY'
    | (
        'RELOAD' 'TLS' (
            'NO' 'ROLLBACK' 'ON' 'ERROR'
            | 'FOR' 'CHANNEL' identifier (
                'NO' 'ROLLBACK' 'ON' 'ERROR'
            )?
        )
        | ('ENABLE' | 'DISABLE') identifier identifier
        | 'RELOAD' 'KEYRING'
    )
    ;

//----------------------------------------------------------------------------------------------------------------------

createStatement
    : 'CREATE' (
        createDatabase
        | createTable
        | createFunction
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

createDatabase
    : 'DATABASE' ifNotExists? identifier createDatabaseOption*
    ;

createDatabaseOption
    : defaultCharset
    | defaultCollation
    | defaultEncryption
    ;

createTable
    : 'TEMPORARY'? 'TABLE' ifNotExists? tableName (
        ('(' tableElementList ')')? createTableOptionsEtc?
        | 'LIKE' tableRef
        | '(' 'LIKE' tableRef ')'
    )
    ;

tableElementList
    : tableElement (',' tableElement)*
    ;

tableElement
    : columnDefinition
    | tableConstraintDef
    ;

duplicateAsQe
    : ('REPLACE' | 'IGNORE')? asCreateQueryExpression
    ;

asCreateQueryExpression
    : 'AS'? select
    ;

//queryExpressionOrParens
//    : queryExpression lockingClauseList?
//    | queryExpressionParens
//    ;

//createRoutine
//    : // Rule for external use only.
//    'CREATE' (createProcedure | createFunction | createUdf) ';'? EOF
//    ;

createProcedure
    : definerClause? 'PROCEDURE' ifNotExists? qualifiedIdentifier '(' (
        procedureParameter (',' procedureParameter)*
    )? ')' routineCreateOption* storedRoutineBody
    ;

routineString
    : textStringLiteral
    | DOLLAR_QUOTED_STRING_TEXT
    ;

storedRoutineBody
    : compoundStatement
    | 'AS' routineString
    ;

createFunction
    : definerClause? 'FUNCTION' ifNotExists? qualifiedIdentifier '(' (
        functionParameter (',' functionParameter)*
    )? ')' 'RETURNS' typeWithOptCollate routineCreateOption* storedRoutineBody
    ;

createUdf
    : 'AGGREGATE'? 'FUNCTION' ifNotExists? udfName 'RETURNS' (
        'STRING'
        | 'INT'
        | 'REAL'
        | 'DECIMAL'
    ) 'SONAME' textLiteral
    ;

// sp_c_chistic in the server grammar.
routineCreateOption
    : routineOption
    | 'NOT'? 'DETERMINISTIC'
    ;

routineOption
    : 'COMMENT' textLiteral
    | 'LANGUAGE' ( 'SQL' | identifier )
    | 'NO' 'SQL'
    | 'CONTAINS' 'SQL'
    | 'READS' 'SQL' 'DATA'
    | 'MODIFIES' 'SQL' 'DATA'
    | 'SQL' 'SECURITY' ( 'DEFINER' | 'INVOKER' )
    ;

createIndex
    : onlineOption? (
        'UNIQUE'? 'INDEX' identifier indexTypeClause? createIndexTarget indexOption*
        | 'FULLTEXT' 'INDEX' identifier createIndexTarget fulltextIndexOption*
        | 'SPATIAL' 'INDEX' identifier createIndexTarget (commonIndexOption)*
    ) indexLockAndAlgorithm?
    ;

indexNameAndType
    : identifier
    | (identifier)? 'USING' indexType
    | identifier 'TYPE' indexType
    ;

createIndexTarget
    : 'ON' tableRef keyListWithExpression
    ;

createLogfileGroup
    : 'LOGFILE' 'GROUP' identifier 'ADD' 'UNDOFILE' textLiteral logfileGroupOptions?
    ;

logfileGroupOptions
    : logfileGroupOption (','? logfileGroupOption)*
    ;

logfileGroupOption
    : tsOptionInitialSize
    | tsOptionUndoRedoBufferSize
    | tsOptionNodegroup
    | tsOptionEngine
    | tsOptionWait
    | tsOptionComment
    ;

createServer
    : 'SERVER' textOrIdentifier 'FOREIGN' 'DATA' 'WRAPPER' textOrIdentifier serverOptions
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
    | 'PORT' ulong_number
    ;

createTablespace
    : 'TABLESPACE' identifier tsDataFileName? (
        'USE' 'LOGFILE' 'GROUP' identifier
    )? tablespaceOptions?
    ;

createUndoTablespace
    : 'UNDO' 'TABLESPACE' identifier 'ADD' tsDataFile undoTableSpaceOptions?
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
    : tsOptionInitialSize
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

tsOptionInitialSize
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
    : 'NODEGROUP' '='? real_ulong_number
    ;

tsOptionEngine
    : 'STORAGE'? 'ENGINE' '='? textOrIdentifier
    ;

tsOptionWait
    : ('WAIT' | 'NO_WAIT')
    ;

tsOptionComment
    : 'COMMENT' '='? textLiteral
    ;

tsOptionFileblockSize
    : 'FILE_BLOCK_SIZE' '='? sizeNumber
    ;

tsOptionEncryption
    : 'ENCRYPTION' '='? textStringLiteral
    ;

tsOptionEngineAttribute
    : 'ENGINE' '='? textStringLiteral
    ;

createView
    : viewReplaceOrAlgorithm? definerClause? viewSuid? 'VIEW' viewName viewTail
    ;

viewReplaceOrAlgorithm
    : 'OR' 'REPLACE' viewAlgorithm?
    | viewAlgorithm
    ;

viewAlgorithm
    : 'ALGORITHM' '=' (
        'UNDEFINED'
        | 'MERGE'
        | 'TEMPTABLE'
    )
    ;

viewSuid
    : 'SQL' 'SECURITY' ('DEFINER' | 'INVOKER')
    ;

createTrigger
    : definerClause? 'TRIGGER' ifNotExists? qualifiedIdentifier (
        'BEFORE'
        | 'AFTER'
    ) ('INSERT' | 'UPDATE' | 'DELETE') 'ON' tableRef 'FOR' 'EACH' 'ROW'
        triggerFollowsPrecedesClause? compoundStatement
    ;

triggerFollowsPrecedesClause
    : ('FOLLOWS' | 'PRECEDES') textOrIdentifier // not a trigger reference!
    ;

createEvent
    : definerClause? 'EVENT' ifNotExists? qualifiedIdentifier 'ON' 'SCHEDULE' schedule (
        'ON' 'COMPLETION' 'NOT'? 'PRESERVE'
    )? ('ENABLE' | 'DISABLE' ('ON' replica)?)? (
        'COMMENT' textLiteral
    )? 'DO' compoundStatement
    ;

createRole
    // The server grammar has a clear_privileges rule here, which is only used to clear internal state.
    : 'ROLE' ifNotExists? roleList
    ;

createSpatialReference
    : 'OR' 'REPLACE' 'SPATIAL' 'REFERENCE' 'SYSTEM' real_ulong_number srsAttribute*
    | 'SPATIAL' 'REFERENCE' 'SYSTEM' ifNotExists? real_ulong_number srsAttribute*
    ;

srsAttribute
    : 'NAME' 'TEXT' textStringNoLinebreak
    | 'DEFINITION' 'TEXT' textStringNoLinebreak
    | 'ORGANIZATION' textStringNoLinebreak 'IDENTIFIED' 'BY' real_ulong_number
    | 'DESCRIPTION' 'TEXT' textStringNoLinebreak
    ;

//----------------------------------------------------------------------------------------------------------------------

dropStatement
    : 'DROP' (
        dropDatabase
        | dropEvent
        | dropFunction
        | dropProcedure
        | dropIndex
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

dropDatabase
    : 'DATABASE' ifExists? identifier
    ;

dropEvent
    : 'EVENT' ifExists? qualifiedIdentifier
    ;

dropFunction
    : 'FUNCTION' ifExists? qualifiedIdentifier // Including UDFs.
    ;

dropProcedure
    : 'PROCEDURE' ifExists? qualifiedIdentifier
    ;

dropIndex
    : onlineOption? 'INDEX' fieldIdentifier 'ON' tableRef indexLockAndAlgorithm?
    ;

dropLogfileGroup
    : 'LOGFILE' 'GROUP' identifier (
        dropLogfileGroupOption (','? dropLogfileGroupOption)*
    )?
    ;

dropLogfileGroupOption
    : tsOptionWait
    | tsOptionEngine
    ;

dropServer
    : 'SERVER' ifExists? textOrIdentifier
    ;

dropTable
    : 'TEMPORARY'? ('TABLE' | 'TABLES') ifExists? tableRefList (
        'RESTRICT'
        | 'CASCADE'
    )?
    ;

dropTableSpace
    : 'TABLESPACE' identifier (
        dropLogfileGroupOption (','? dropLogfileGroupOption)*
    )?
    ;

dropTrigger
    : 'TRIGGER' ifExists? qualifiedIdentifier
    ;

dropView
    : 'VIEW' ifExists? viewRefList ('RESTRICT' | 'CASCADE')?
    ;

dropRole
    : 'ROLE' ifExists? roleList
    ;

dropSpatialReference
    : 'SPATIAL' 'REFERENCE' 'SYSTEM' ifExists? real_ulong_number
    ;

dropUndoTablespace
    : 'UNDO' 'TABLESPACE' identifier undoTableSpaceOptions?
    ;

//----------------------------------------------------------------------------------------------------------------------

renameTableStatement
    : 'RENAME' ('TABLE' | 'TABLES') renamePair (
        ',' renamePair
    )*
    ;

renamePair
    : tableRef 'TO' tableName
    ;

//----------------------------------------------------------------------------------------------------------------------

truncateTableStatement
    : 'TRUNCATE' 'TABLE'? tableRef
    ;

//----------------------------------------------------------------------------------------------------------------------

importStatement
    : 'IMPORT' 'TABLE' 'FROM' textStringLiteralList
    ;

//--------------- DML statements ---------------------------------------------------------------------------------------

callStatement
    : 'CALL' qualifiedIdentifier ('(' exprList? ')')?
    ;

deleteStatement
    : with? 'DELETE' deleteStatementOption* (
        'FROM' (
            tableAliasRefList 'USING' tableReferenceList where? // Multi table variant 1.
            | tableRef (tableAlias)? partitionDelete? where? orderBy? simpleLimitClause?
            // Single table delete.
        )
        | tableAliasRefList 'FROM' tableReferenceList where? // Multi table variant 2.
    )
    ;

partitionDelete
    : 'PARTITION' '(' identifierList ')'
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
        tableRef 'OPEN' tableAlias?
        | identifier (
            'CLOSE'
            | 'READ' handlerReadOrScan where? limit?
        )
    )
    ;

handlerReadOrScan
    : ('FIRST' | 'NEXT') // Scan function.
    | identifier (
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
    : 'INSERT' insertLockOption? 'IGNORE'? 'INTO'? tableRef usePartition? (
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
    : 'AS' identifier columns?
    ;

insertUpdateList
    : 'ON' 'DUPLICATE' 'KEY' 'UPDATE' updateList
    ;

//----------------------------------------------------------------------------------------------------------------------

loadStatement
    : 'LOAD' dataOrXml loadDataLock? 'FROM'? 'LOCAL'? loadSourceType? textStringLiteral sourceCount? sourceOrder? (
        'REPLACE'
        | 'IGNORE'
    )? 'INTO' 'TABLE' tableRef usePartition? charsetClause? xmlRowsIdentifiedBy? fieldsClause? linesClause?
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
        | pureIdentifier INT_NUMBER
    )
    ;

sourceOrder
    : 'IN' 'PRIMARY' 'KEY' 'ORDER'
    ;

xmlRowsIdentifiedBy
    : 'ROWS' 'IDENTIFIED' 'BY' textString
    ;

loadDataFileTail
    : ('IGNORE' INT_NUMBER ('LINES' | 'ROWS'))? loadDataFileTargetList? (
        'SET' updateList
    )?
    ;

loadDataFileTargetList
    : '(' fieldOrVariableList? ')'
    ;

fieldOrVariableList
    : (fieldIdentifier | '@' textOrIdentifier | '@@') (
        ',' (
            fieldIdentifier
            | '@' textOrIdentifier
            | AT_TEXT_SUFFIX
            | '@@'
        )
    )*
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
    : 'REPLACE' ('LOW_PRIORITY' | 'DELAYED')? 'INTO'? tableRef usePartition? (
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
    | 'TABLE' tableRef
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
    : identifier
    | PARAM_MARKER | INT_NUMBER
//    | (PARAM_MARKER | ULONGLONG_NUMBER | LONG_NUMBER | INT_NUMBER)
    ;

intoClause
    : 'INTO' (
        'OUTFILE' textStringLiteral charsetClause? fieldsClause? linesClause?
        | 'DUMPFILE' textStringLiteral
        | (textOrIdentifier | userVariable) (
            ',' (textOrIdentifier | userVariable)
        )*
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
    : identifier 'AS' windowSpec
    ;

windowSpec
    : '(' windowSpecDetails ')'
    ;

windowSpecDetails
    : identifier? ('PARTITION' 'BY' orderList)? orderBy? windowFrameClause?
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
    | ulonglongNumber 'PRECEDING'
    | PARAM_MARKER 'PRECEDING'
    | 'INTERVAL' expr interval 'PRECEDING'
    | 'CURRENT' 'ROW'
    ;

windowFrameBetween
    : 'BETWEEN' windowFrameBound 'AND' windowFrameBound
    ;

windowFrameBound
    : windowFrameStart
    | 'UNBOUNDED' 'FOLLOWING'
    | ulonglongNumber 'FOLLOWING'
    | PARAM_MARKER 'FOLLOWING'
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
    : identifier columns? 'AS' '(' select ')'
    ;

groupByClause
    : 'GROUP' 'BY' orderList ( 'WITH' 'ROLLUP' )?
    | 'GROUP' 'BY' ( 'ROLLUP' | 'CUBE' ) '(' groupList ')'
    ;

orderBy
    : 'ORDER' 'BY' orderList
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
      | '{' ( identifier | 'OJ' ) tableFactor joinedTable* '}'
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
    | expr selectAlias?
    ;

selectAlias
    : 'AS'? (identifier | textStringLiteral)
    ;

where
    : 'WHERE' expr
    ;

joinedTable
    // Same as joined_table in sql_yacc.yy, but with removed left recursion.
    :
    innerJoinType tableReference (
        'ON' expr
        | 'USING' identifierListWithParentheses
    )?
    | outerJoinType tableReference (
        'ON' expr
        | 'USING' identifierListWithParentheses
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
    : tableRef usePartition? tableAlias? indexHintList? tablesampleClause?
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
    : 'JSON_TABLE' '(' expr ',' textStringLiteral columnsClause ')' tableAlias?
    ;

columnsClause
    : 'COLUMNS' '(' jtColumn (',' jtColumn)* ')'
    ;

jtColumn
    : identifier 'FOR' 'ORDINALITY'
    | identifier dataType (collate)? 'EXISTS'? 'PATH' textStringLiteral
        onEmptyOrErrorJsonTable?
    | 'NESTED' 'PATH' textStringLiteral columnsClause
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
    | 'DEFAULT' textStringLiteral
    ;

unionOption
    : 'DISTINCT'
    | 'ALL'
    ;

tableAlias
    : ('AS' | '=')? identifier
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
    : identifier
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
    : 'SAVEPOINT' identifier
    | 'ROLLBACK' 'WORK'? (
        'TO' 'SAVEPOINT'? identifier
        | ('AND' 'NO'? 'CHAIN')? ('NO'? 'RELEASE')?
    )
    | 'RELEASE' 'SAVEPOINT' identifier
    ;

lockStatement
    : 'LOCK' ('TABLES' | 'TABLE') lockItem (',' lockItem)*
    | 'LOCK' 'INSTANCE' 'FOR' 'BACKUP'
    | 'UNLOCK' ( 'TABLES' | 'TABLE' | 'INSTANCE')
    ;

lockItem
    : tableRef tableAlias? lockOption
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
    : textString (',' textString (',' ulong_number)?)?
    ;

//----------------------------------------------------------------------------------------------------------------------

replicationStatement
    : 'PURGE' purgeOptions
    | changeSource
    | 'RESET' resetOption (',' resetOption)*
    | 'RESET' 'PERSIST' ifExistsIdentifier?
    | startReplicaStatement
    | stopReplicaStatement
    | changeReplication
    | replicationLoad
    | groupReplication
    ;

purgeOptions
    : ('BINARY' | 'MASTER') 'LOGS' (
        'TO' textLiteral
        | 'BEFORE' expr
    )
    ;

resetOption
    : masterOrBinaryLogsAndGtids sourceResetOptions?
    | replica 'ALL'? channel?
    ;

masterOrBinaryLogsAndGtids
    : 'MASTER'
    | 'BINARY' 'LOGS' 'AND' 'GTIDS'
    ;

sourceResetOptions
    : 'TO' real_ulong_number
    ;

replicationLoad
    : 'LOAD' ('DATA' | 'TABLE' tableRef) 'FROM' 'MASTER'
    ;

changeReplicationSource
    : 'MASTER'
    | 'REPLICATION' 'SOURCE'
    ;

changeSource
    : 'CHANGE' changeReplicationSource 'TO' sourceDefinitions channel?
    ;

sourceDefinitions
    : sourceDefinition (',' sourceDefinition)*
    ;

sourceDefinition
    : // source_def in sql_yacc.yy
    changeReplicationSourceHost '=' textStringNoLinebreak
    | 'NETWORK_NAMESPACE' '=' textStringNoLinebreak
    | changeReplicationSourceBind '=' textStringNoLinebreak
    | changeReplicationSourceUser '=' textStringNoLinebreak
    | changeReplicationSourcePassword '=' textStringNoLinebreak
    | changeReplicationSourcePort '=' ulong_number
    | changeReplicationSourceConnectRetry '=' ulong_number
    | changeReplicationSourceRetryCount '=' ulong_number
    | changeReplicationSourceDelay '=' ulong_number
    | changeReplicationSourceSSL '=' ulong_number
    | changeReplicationSourceSSLCA '=' textStringNoLinebreak
    | changeReplicationSourceSSLCApath '=' textStringNoLinebreak
    | changeReplicationSourceTLSVersion '=' textStringNoLinebreak
    | changeReplicationSourceSSLCert '=' textStringNoLinebreak
    | changeReplicationSourceTLSCiphersuites '=' sourceTlsCiphersuitesDef
    | changeReplicationSourceSSLCipher '=' textStringNoLinebreak
    | changeReplicationSourceSSLKey '=' textStringNoLinebreak
    | changeReplicationSourceSSLVerifyServerCert '=' ulong_number
    | changeReplicationSourceSSLCLR '=' textLiteral
    | changeReplicationSourceSSLCLRpath '=' textStringNoLinebreak
    | changeReplicationSourcePublicKey '=' textStringNoLinebreak
    | changeReplicationSourceGetSourcePublicKey '=' ulong_number
    | changeReplicationSourceHeartbeatPeriod '=' ulong_number
    | 'IGNORE_SERVER_IDS' '=' serverIdList
    | changeReplicationSourceCompressionAlgorithm '=' textStringLiteral
    | changeReplicationSourceZstdCompressionLevel '=' ulong_number
    | changeReplicationSourceAutoPosition '=' ulong_number
    | 'PRIVILEGE_CHECKS_USER' '=' privilegeCheckDef
    | 'REQUIRE_ROW_FORMAT' '=' ulong_number
    | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK' '=' tablePrimaryKeyCheckDef
    | 'SOURCE_CONNECTION_AUTO_FAILOVER' '=' real_ulong_number
    | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS' '='
        assignGtidsToAnonymousTransactionsDefinition
    | 'GTID_ONLY' '=' real_ulong_number
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
    : userIdentifierOrText
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
    | textStringLiteral
    ;

sourceTlsCiphersuitesDef
    : textStringNoLinebreak
    | 'NULL'
    ;

sourceFileDef
    : sourceLogFile '=' textStringNoLinebreak
    | sourceLogPos '=' ulonglongNumber
    | 'RELAY_LOG_FILE' '=' textStringNoLinebreak
    | 'RELAY_LOG_POS' '=' ulong_number
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
    : '(' (ulong_number (',' ulong_number)*)? ')'
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
    : identifier (',' identifier)*
    ;

filterTableList
    : filterTableRef (',' filterTableRef)*
    ;

filterStringList
    : filterWildDbTableString (',' filterWildDbTableString)*
    ;

filterWildDbTableString
    : textStringNoLinebreak // sql_yacc.yy checks for the existance of at least one dot char in the string.
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
        | ('SQL_BEFORE_GTIDS' | 'SQL_AFTER_GTIDS') '=' textString
        | 'SQL_AFTER_MTS_GAPS'
    ) (',' sourceFileDef)*
    ;

userOption
    : 'USER' '=' textString
    ;

passwordOption
    : 'PASSWORD' '=' textString
    ;

defaultAuthOption
    : 'DEFAULT_AUTH' '=' textString
    ;

pluginDirOption
    : 'PLUGIN_DIR' '=' textString
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
    : 'USER' '=' textStringNoLinebreak
    ;

groupReplicationPassword
    : 'PASSWORD' '=' textStringNoLinebreak
    ;

groupReplicationPluginAuth
    : 'DEFAULT_AUTH' '=' textStringNoLinebreak
    ;

replica
    : // Part of the terminology cleanup starting with 8.0.24.
    'SLAVE'
    | 'REPLICA'
    ;

//----------------------------------------------------------------------------------------------------------------------

preparedStatement
    : 'PREPARE' identifier 'FROM' (textLiteral | userVariable)
    | executeStatement
    | ('DEALLOCATE' | 'DROP') 'PREPARE' identifier
    ;

executeStatement
    : 'EXECUTE' identifier ('USING' executeVarList)?
    ;

executeVarList
    : userVariable (',' userVariable)*
    ;

//----------------------------------------------------------------------------------------------------------------------

cloneStatement
    : 'CLONE' (
        'LOCAL' 'DATA' 'DIRECTORY' equal? textStringLiteral
        // Clone remote has been removed in 8.0.14. This alt is taken out by the conditional 'REMOTE'.
        | 'REMOTE' ('FOR' 'REPLICATION')?
        | 'INSTANCE' 'FROM' user ':' ulong_number 'IDENTIFIED' 'BY'
            textStringLiteral dataDirSSL?
    )
    ;

dataDirSSL
    : ssl
    | 'DATA' 'DIRECTORY' equal? textStringLiteral ssl?
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
    : 'ALTER' 'USER' ifExists? (
        (
            createUserList
            | alterUserList
        ) createUserTail
        | userFunction (
            (identifiedByRandomPassword | identifiedByPassword) replacePassword? retainCurrentPassword?
            | 'DISCARD' 'OLD' 'PASSWORD'
            | userRegistration?
        )
        | user (
            'DEFAULT' 'ROLE' ('ALL' | 'NONE' | roleList)
            | userRegistration?
        )
    )
    ;

alterUserList
    : alterUser (',' alterUser)*
    ;

alterUser
    : oldAlterUser
    | (
        user (
            identifiedByPassword (
                'REPLACE' textStringLiteral retainCurrentPassword?
                | retainCurrentPassword?
            )
            | identifiedByRandomPassword (
                retainCurrentPassword?
                | 'REPLACE' textStringLiteral retainCurrentPassword?
            )
            | identifiedWithPlugin
            | identifiedWithPluginAsAuth retainCurrentPassword?
            | identifiedWithPluginByPassword (
                'REPLACE' textStringLiteral retainCurrentPassword?
                | retainCurrentPassword?
            )
            | identifiedWithPluginByRandomPassword retainCurrentPassword?
            | discardOldPassword?
            | 'ADD' factor identification ('ADD' factor identification)?
            | 'MODIFY' factor identification (
                'MODIFY' factor identification
            )?
            | 'DROP' factor ('DROP' factor)?
        )
    )
    ;

oldAlterUser
    : user 'IDENTIFIED' 'BY' (
        textString 'REPLACE' textString retainCurrentPassword?
        | textString retainCurrentPassword?
        | 'RANDOM' 'PASSWORD' ('REPLACE' textString)? retainCurrentPassword?
    )
    | user 'IDENTIFIED' 'WITH' (
        textOrIdentifier (
            'BY' textString 'REPLACE' textString retainCurrentPassword?
            | 'AS' textStringHash retainCurrentPassword?
            | 'BY' textString retainCurrentPassword?
            | 'BY' 'RANDOM' 'PASSWORD' retainCurrentPassword?
        )?
    )
    | user discardOldPassword?
    ;

userFunction
    : 'USER' '(' ')'
    ;

createUserStatement
    : 'CREATE' 'USER' ifNotExists? createUserList defaultRoleClause? createUserTail
    ;

createUserTail
    : requireClause? connectOptions? accountLockPasswordExpireOptions* (
        userAttributes
    )?
    ;

userAttributes
    : 'ATTRIBUTE' textStringLiteral
    | 'COMMENT' textStringLiteral
    ;

defaultRoleClause
    : 'DEFAULT' 'ROLE' roleList
    ;

requireClause
    : 'REQUIRE' (
        requireList
        | ('SSL' | 'X509' | 'NONE')
    )
    ;

connectOptions
    : 'WITH' (
        'MAX_QUERIES_PER_HOUR' ulong_number
        | 'MAX_UPDATES_PER_HOUR' ulong_number
        | 'MAX_CONNECTIONS_PER_HOUR' ulong_number
        | 'MAX_USER_CONNECTIONS' ulong_number
    )+
    ;

accountLockPasswordExpireOptions
    : 'ACCOUNT' ('LOCK' | 'UNLOCK')
    | 'PASSWORD' (
        'EXPIRE' (
            'INTERVAL' real_ulong_number 'DAY'
            | 'NEVER'
            | 'DEFAULT'
        )?
        | 'HISTORY' (real_ulong_number | 'DEFAULT')
        | 'REUSE' 'INTERVAL' (
            real_ulong_number 'DAY'
            | 'DEFAULT'
        )
        | 'REQUIRE' 'CURRENT' (
            'DEFAULT'
            | 'OPTIONAL'
        )?
    )
    | 'FAILED_LOGIN_ATTEMPTS' real_ulong_number
    | 'PASSWORD_LOCK_TIME' (real_ulong_number | 'UNBOUNDED')
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
    : 'GRANT' (
        roleOrPrivilegesList 'TO' userList (
            'WITH' 'ADMIN' 'OPTION'
        )?
        | (roleOrPrivilegesList | 'ALL' 'PRIVILEGES'?) 'ON' aclType? grantIdentifier 'TO' grantTargetList
            versionedRequireClause? grantOptions? grantAs?
        | 'PROXY' 'ON' user 'TO' grantTargetList (
            'WITH' 'GRANT' 'OPTION'
        )?
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
    : (
        roleIdentifierOrText columns?
        | roleIdentifierOrText (AT_TEXT_SUFFIX | '@' textOrIdentifier)
    )
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
    | identifier ('.' '*')?
    | tableRef
    | identifier '.' tableRef
    ;

requireList
    : requireListElement ('AND'? requireListElement)*
    ;

requireListElement
    : ('CIPHER' | 'ISSUER' | 'SUBJECT') textString
    ;

grantOption
    : 'GRANT' 'OPTION'
    | ( 'MAX_QUERIES_PER_HOUR' | 'MAX_UPDATES_PER_HOUR' | 'MAX_CONNECTIONS_PER_HOUR' | 'MAX_USER_CONNECTIONS' ) ulong_number
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
    : roleIdentifierOrText userVariable?
    ;

//----------------------------------------------------------------------------------------------------------------------

tableAdministrationStatement
    : 'ANALYZE' noWriteToBinLog? 'TABLE' tableRefList histogram?
    | 'CHECK' 'TABLE' tableRefList checkOption*
    | 'CHECKSUM' 'TABLE' tableRefList (
        'QUICK'
        | 'EXTENDED'
    )?
    | 'OPTIMIZE' noWriteToBinLog? 'TABLE' tableRefList
    | 'REPAIR' noWriteToBinLog? 'TABLE' tableRefList repairType*
    ;

histogramAutoUpdate
    : ('MANUAL' | 'AUTO') 'UPDATE'
    ;

histogramUpdateParam
    : histogramNumBuckets? histogramAutoUpdate?
    | 'USING' 'DATA' textStringLiteral
    ;

histogramNumBuckets
    : 'WITH' INT_NUMBER 'BUCKETS'
    ;

histogram
    : 'UPDATE' 'HISTOGRAM' 'ON' identifierList histogramUpdateParam
    | 'DROP' 'HISTOGRAM' 'ON' identifierList
    ;

checkOption
    : 'FOR' 'UPGRADE'
    | ('QUICK' | 'FAST' | 'MEDIUM' | 'EXTENDED' | 'CHANGED')
    ;

repairType
    : 'QUICK'
    | 'EXTENDED'
    | 'USE_FRM'
    ;

//----------------------------------------------------------------------------------------------------------------------

uninstallStatement
    : 'UNINSTALL' (
        'PLUGIN' identifier
        | 'COMPONENT' textStringLiteral (',' textStringLiteral)*
    )
    ;

installStatement
    : 'INSTALL' (
        'PLUGIN' identifier 'SONAME' textStringLiteral
        | 'COMPONENT' textStringLiteralList installSetValueList?
    )
    ;

installOptionType
    : 'GLOBAL'
    | 'PERSIST'
    ;

installSetRvalue
    : expr
    | 'ON'
    ;

installSetValue
    : installOptionType lvalueVariable equal installSetRvalue
    ;

installSetValueList
    : 'SET' installSetValue (
        ',' installSetValue
    )*
    ;

//----------------------------------------------------------------------------------------------------------------------

setStatement
    : 'SET'
      ( optionValueNoOptionType (',' optionValue)*
      | 'TRANSACTION' transactionCharacteristics
      | optionType startOptionValueListFollowingOptionType
      | 'PASSWORD' ('FOR' user)? equal ( textString replacePassword? retainCurrentPassword? | textString replacePassword? retainCurrentPassword? | 'PASSWORD' '(' textString ')' )
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
    : 'ISOLATION' 'LEVEL' (
        'REPEATABLE' 'READ'
        | 'READ' ('COMMITTED' | 'UNCOMMITTED')
        | 'SERIALIZABLE'
    )
    ;

optionValueNoOptionType
    : lvalueVariable equal setExprOrDefault
    | charsetClause
    | userVariable equal expr
    | '@@' setVarIdentType? lvalueVariable equal setExprOrDefault
    | 'NAMES' (
        equal expr
        | charsetName collate?
        | 'DEFAULT'
    )
    ;

optionValue
    : optionType lvalueVariable equal setExprOrDefault
    | optionValueNoOptionType
    ;

//setSystemVariable
//    : '@@' setVarIdentType? lvalueVariable
//    ;

startOptionValueListFollowingOptionType
    : optionValueFollowingOptionType (',' optionValue)*
    | 'TRANSACTION' transactionCharacteristics
    ;

optionValueFollowingOptionType
    : lvalueVariable equal setExprOrDefault
    ;

setExprOrDefault
    : expr
    | 'DEFAULT'
    | 'ON'
    | 'ALL'
    | 'BINARY'
    | 'ROW'
    | 'SYSTEM'
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

showEngineLogsStatement
    : 'SHOW' 'ENGINE' engineOrAll 'LOGS'
    ;

showEngineMutexStatement
    : 'SHOW' 'ENGINE' engineOrAll 'MUTEX'
    ;

showEngineStatusStatement
    : 'SHOW' 'ENGINE' engineOrAll 'STATUS'
    ;

showColumnsStatement
    : 'SHOW' showCommandType? 'COLUMNS' ('FROM' | 'IN') tableRef inDb? likeOrWhere?
    ;

showBinaryLogsStatement
    : 'SHOW' ('BINARY' | 'MASTER') 'LOGS'
    ;

showBinaryLogStatusStatement
    : 'SHOW' 'BINARY' 'LOG' 'STATUS'
    ;

showReplicasStatement
    : 'SHOW' (replica 'HOSTS' | 'REPLICAS')
    ;

showBinlogEventsStatement
    : 'SHOW' 'BINLOG' 'EVENTS' ('IN' textString)? (
        'FROM' ulonglongNumber
    )? limit? channel?
    ;

showRelaylogEventsStatement
    : 'SHOW' 'RELAYLOG' 'EVENTS' ('IN' textString)? (
        'FROM' ulonglongNumber
    )? limit? channel?
    ;

showKeysStatement
    : 'SHOW' 'EXTENDED'? ('INDEX' | 'INDEXES' | 'KEYS') fromOrIn tableRef inDb? where?
    ;

showEnginesStatement
    : 'SHOW' 'STORAGE'? 'ENGINES'
    ;

showCountWarningsStatement
    : 'SHOW' 'COUNT' '(' '*' ')' 'WARNINGS'
    ;

showCountErrorsStatement
    : 'SHOW' 'COUNT' '(' '*' ')' 'ERRORS'
    ;

showWarningsStatement
    : 'SHOW' 'WARNINGS' limit?
    ;

showErrorsStatement
    : 'SHOW' 'ERRORS' limit?
    ;

showProfilesStatement
    : 'SHOW' 'PROFILES'
    ;

showProfileStatement
    : 'SHOW' 'PROFILE' profileDefinitions? (
        'FOR' 'QUERY' INT_NUMBER
    )? limit?
    ;

showStatusStatement
    : 'SHOW' optionType? 'STATUS' likeOrWhere?
    ;

showProcessListStatement
    : 'SHOW' 'FULL'? 'PROCESSLIST'
    ;

showVariablesStatement
    : 'SHOW' optionType? 'VARIABLES' likeOrWhere?
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
    : 'SHOW' 'CREATE' 'DATABASE' ifNotExists? identifier
    ;

showCreateTableStatement
    : 'SHOW' 'CREATE' 'TABLE' tableRef
    ;

showCreateViewStatement
    : 'SHOW' 'CREATE' 'VIEW' viewRef
    ;

showMasterStatusStatement
    : 'SHOW' 'MASTER' 'STATUS'
    ;

showReplicaStatusStatement
    : 'SHOW' replica 'STATUS' channel?
    ;

showCreateProcedureStatement
    : 'SHOW' 'CREATE' 'PROCEDURE' qualifiedIdentifier
    ;

showCreateFunctionStatement
    : 'SHOW' 'CREATE' 'FUNCTION' qualifiedIdentifier
    ;

showCreateTriggerStatement
    : 'SHOW' 'CREATE' 'TRIGGER' qualifiedIdentifier
    ;

showCreateProcedureStatusStatement
    : 'SHOW' 'CREATE' 'PROCEDURE' 'STATUS' likeOrWhere?
    ;

showCreateFunctionStatusStatement
    : 'SHOW' 'CREATE' 'FUNCTION' 'STATUS' likeOrWhere?
    ;

showCreateProcedureCodeStatement
    : 'SHOW' 'CREATE' 'PROCEDURE' 'CODE' qualifiedIdentifier
    ;

showCreateFunctionCodeStatement
    : 'SHOW' 'CREATE' 'FUNCTION' 'CODE' qualifiedIdentifier
    ;

showCreateEventStatement
    : 'SHOW' 'CREATE' 'EVENT' qualifiedIdentifier
    ;

showCreateUserStatement
    : 'SHOW' 'CREATE' 'USER' user
    ;

showCommandType
    : 'FULL'
    | 'EXTENDED' 'FULL'?
    ;

engineOrAll
    : textOrIdentifier
    | 'ALL'
    ;

fromOrIn
    : 'FROM'
    | 'IN'
    ;

inDb
    : fromOrIn identifier
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
        identifier
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
    : tableRef cacheKeyList?
    ;

assignToKeycachePartition
    : tableRef 'PARTITION' '(' allOrPartitionNameList ')' cacheKeyList?
    ;

cacheKeyList
    : keyOrIndex '(' keyUsageList? ')'
    ;

keyUsageElement
    : identifier
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
        | identifierList flushTablesOptions?
    )?
    ;

flushTablesOptions
    : 'FOR' 'EXPORT'
    | 'WITH' 'READ' 'LOCK'
    ;

preloadTail
    : tableRef adminPartition cacheKeyList? ('IGNORE' 'LEAVES')?
    | preloadList
    ;

preloadList
    : preloadKeys (',' preloadKeys)*
    ;

preloadKeys
    : tableRef cacheKeyList? ('IGNORE' 'LEAVES')?
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
    : 'CREATE' 'RESOURCE' 'GROUP' identifier 'TYPE' equal? (
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
    : 'ALTER' 'RESOURCE' 'GROUP' identifier resourceGroupVcpuList? resourceGroupPriority?
        resourceGroupEnableDisable? 'FORCE'?
    ;

setResourceGroup
    : 'SET' 'RESOURCE' 'GROUP' identifier ('FOR' threadIdList)?
    ;

threadIdList
    : real_ulong_number (','? real_ulong_number)*
    ;

dropResourceGroup
    : 'DROP' 'RESOURCE' 'GROUP' identifier 'FORCE'?
    ;

//----------------------------------------------------------------------------------------------------------------------

utilityStatement
    : describeStatement
    | explainStatement
    | helpCommand
    | useCommand
    | restartServer
    ;

describeStatement
    : ('EXPLAIN' | 'DESCRIBE' | 'DESC') tableRef (
        textString
        | fieldIdentifier
    )?
    ;

explainStatement
    : ('EXPLAIN' | 'DESCRIBE' | 'DESC') explainOptions? (
        'FOR' 'DATABASE' textOrIdentifier
    )? explainableStatement
    ;

explainOptions
    : 'FORMAT' '=' textOrIdentifier (
        explainInto
    )?
    | 'EXTENDED'
    | 'ANALYZE'
    | 'ANALYZE' 'FORMAT' '=' textOrIdentifier
    ;

explainableStatement
    : select
    | deleteStatement
    | insertStatement
    | replaceStatement
    | updateStatement
    | 'FOR' 'CONNECTION' real_ulong_number
    ;

explainInto
    : 'INTO' '@' textOrIdentifier
    ;

helpCommand
    : 'HELP' textOrIdentifier
    ;

useCommand
    : 'USE' identifier
    ;

restartServer
    : 'RESTART'
    ;

//----------------- Expression support ---------------------------------------------------------------------------------

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
        | 'MEMBER' 'OF'? simpleExprWithParentheses
        | 'SOUNDS' 'LIKE' bitExpr
    )?
    ;

predicateOperations
    : 'IN' ('(' select ')' | '(' exprList ')')
    | 'BETWEEN' bitExpr 'AND' predicate
    | 'LIKE' simpleExpr ('ESCAPE' simpleExpr)?
    | 'REGEXP' bitExpr
    ;

bitExpr
    : simpleExpr
    | bitExpr '^' bitExpr
    | bitExpr (
        '*'
        | '/'
        | '%'
        | 'DIV'
        | 'MOD'
    ) bitExpr
    | bitExpr ('+' | '-') bitExpr
    | bitExpr ('+' | '-') 'INTERVAL' expr interval
    | bitExpr ('<<' | '>>') bitExpr
    | bitExpr '&' bitExpr
    | bitExpr '|' bitExpr
    ;

simpleExpr
    : fieldIdentifier jsonOperator?
    | runtimeFunctionCall
    | functionCall
    | simpleExpr 'COLLATE' textOrIdentifier
    | literal
    | PARAM_MARKER
    | rvalueSystemOrUserVariable
    | userVariable ':=' expr
    | sumExpr
    | groupingOperation
    | windowFunctionCall
    | simpleExpr 'CONCAT_PIPES' simpleExpr
    | ('+' | '-' | '~') simpleExpr
    | not2Rule simpleExpr
    | 'ROW'? '(' exprList ')'
    | 'EXISTS'? '(' select ')'
    | '{' identifier expr '}'
    | 'MATCH' identListArg 'AGAINST' '(' bitExpr fulltextOptions? ')'
    | 'BINARY' simpleExpr
    | 'CAST' '(' expr ('AT' 'LOCAL')? 'AS' castType ('ARRAY')? ')'
    | 'CAST' '(' expr 'AT' 'TIME' 'ZONE' 'INTERVAL'? textStringLiteral 'AS'
        'DATETIME' typeDatetimePrecision ')'
    | 'CASE' expr? (whenExpression thenExpression)+ elseExpression? 'END'
    | 'CONVERT' '(' expr ',' castType ')'
    | 'CONVERT' '(' expr 'USING' charsetName ')'
    | 'DEFAULT' '(' simpleIdentifier ')'
    | 'VALUES' '(' simpleIdentifier ')'
    | 'INTERVAL' expr interval '+' expr
    ;


jsonOperator
    : '->' textStringLiteral
    | '->>' textStringLiteral
    ;

sumExpr
    : 'AVG' '(' 'DISTINCT'? inSumExpr ')' windowingClause?
    | ('BIT_AND' | 'BIT_OR' | 'BIT_XOR') '(' inSumExpr ')' windowingClause?
    | jsonFunction
    | 'ST_COLLECT' '(' 'DISTINCT'? inSumExpr ')' windowingClause?
    | 'COUNT' '(' ( 'ALL'? '*' | inSumExpr | 'DISTINCT' exprList ) ')' windowingClause?
    | ('MIN' | 'MAX') '(' 'DISTINCT'? inSumExpr ')' windowingClause?
    | ( 'STD' | 'VARIANCE' | 'STDDEV_SAMP' | 'VAR_SAMP' | 'SUM' ) '(' inSumExpr ')' windowingClause?
    | 'SUM' '(' 'DISTINCT' inSumExpr ')' windowingClause?
    | 'GROUP_CONCAT' '(' 'DISTINCT'? exprList orderBy? ( 'SEPARATOR' textString )? ')' windowingClause?
    ;

groupingOperation
    : 'GROUPING' '(' exprList ')'
    ;

windowFunctionCall
    : (
        'ROW_NUMBER'
        | 'RANK'
        | 'DENSE_RANK'
        | 'CUME_DIST'
        | 'PERCENT_RANK'
    ) '(' ')' windowingClause
    | 'NTILE' (
        '(' stableInteger ')'
        | simpleExprWithParentheses
    ) windowingClause
    | ('LEAD' | 'LAG') '(' expr leadLagInfo? ')' nullTreatment? windowingClause
    | ('FIRST_VALUE' | 'LAST_VALUE') exprWithParentheses nullTreatment? windowingClause
    | 'NTH_VALUE' '(' expr ',' simpleExpr ')' (
        'FROM' ('FIRST' | 'LAST')
    )? nullTreatment? windowingClause
    ;

samplingMethod
    : 'SYSTEM'
    | 'BERNOULLI'
    ;

samplingPercentage
    : ulonglongNumber
    | '@' textOrIdentifier
    | PARAM_MARKER
    ;

tablesampleClause
    : 'TABLESAMPLE' samplingMethod '(' samplingPercentage ')'
    ;

windowingClause
    : 'OVER' (identifier | windowSpec)
    ;

leadLagInfo
    : ',' (
        ulonglongNumber
        | PARAM_MARKER
        | stableInteger
    ) (',' expr)?
    ;

// The stable_integer nonterminal symbol is not really constant, but constant for the duration of an execution.
stableInteger
    : INT_NUMBER
    | paramOrVar
    ;

paramOrVar
    : PARAM_MARKER
    | identifier
    | '@' textOrIdentifier
    ;

nullTreatment
    : ('RESPECT' | 'IGNORE') 'NULLS'
    ;

jsonFunction
    : 'JSON_ARRAYAGG' '(' inSumExpr ')' windowingClause?
    | 'JSON_OBJECTAGG' '(' inSumExpr ',' inSumExpr ')' windowingClause?
    ;

inSumExpr
    : 'ALL'? expr
    ;

identListArg
    : identList
    | '(' identList ')'
    ;

identList
    : simpleIdentifier (',' simpleIdentifier)*
    ;

fulltextOptions
    : 'IN' 'BOOLEAN' 'MODE'
    | 'IN' 'NATURAL' 'LANGUAGE' 'MODE' ( 'WITH' 'QUERY' 'EXPANSION' )?
    | 'WITH' 'QUERY' 'EXPANSION'
    ;

// function_call_keyword and function_call_nonkeyword in sql_yacc.yy.
runtimeFunctionCall
    // Function names that are keywords.
    :
    'CHAR' '(' exprList ('USING' charsetName)? ')'
    | 'CURRENT_USER' ('(' ')')?
    | 'DATE' exprWithParentheses
    | 'DAY' exprWithParentheses
    | 'HOUR' exprWithParentheses
    | 'INSERT' '(' expr ',' expr ',' expr ',' expr ')'
    | 'INTERVAL' '(' expr (',' expr)+ ')'
    | 'JSON_VALUE' '(' simpleExpr ',' textLiteral returningType? onEmptyOrError ')'
    | 'LEFT' '(' expr ',' expr ')'
    | 'MINUTE' exprWithParentheses
    | 'MONTH' exprWithParentheses
    | 'RIGHT' '(' expr ',' expr ')'
    | 'SECOND' exprWithParentheses
    | 'TIME' exprWithParentheses
    | 'TIMESTAMP' '(' expr (',' expr)? ')'
    | 'TRIM' '(' ( expr ('FROM' expr)? | 'LEADING' expr? 'FROM' expr | 'TRAILING' expr? 'FROM' expr | 'BOTH' expr? 'FROM' expr ) ')'
    | userFunction
    | 'VALUES' exprWithParentheses
    | 'YEAR' exprWithParentheses

    // Function names that are not keywords.
    | ('ADDDATE' | 'SUBDATE') '(' expr ',' ( expr | 'INTERVAL' expr interval ) ')'
    | 'CURDATE' ('(' ')')?
    | 'CURTIME' timeFunctionParameters?
    | ('DATE_ADD' | 'DATE_SUB') '(' expr ',' 'INTERVAL' expr interval ')'
    | 'EXTRACT' '(' interval 'FROM' expr ')'
    | 'GET_FORMAT' '(' dateTimeTtype ',' expr ')'
    | 'LOG' '(' expr ( ',' expr )? ')'
    | 'NOW' timeFunctionParameters?
    | 'POSITION' '(' bitExpr 'IN' expr ')'
    | substringFunction
    | 'SYSDATE' timeFunctionParameters?
    | ('TIMESTAMPADD' | 'TIMESTAMPDIFF') '(' intervalTimeStamp ',' expr ',' expr ')'
    | 'UTC_DATE' ('(' ')')?
    | 'UTC_TIME' timeFunctionParameters?
    | 'UTC_TIMESTAMP' timeFunctionParameters?

    // Function calls with other conflicts.
    | 'ASCII' exprWithParentheses
    | 'CHARSET' exprWithParentheses
    | 'COALESCE' exprListWithParentheses
    | 'COLLATION' exprWithParentheses
    | 'DATABASE' '(' ')'
    | 'IF' '(' expr ',' expr ',' expr ')'
    | 'FORMAT' '(' expr ',' expr (',' expr)? ')'
    | 'MICROSECOND' exprWithParentheses
    | 'MOD' '(' expr ',' expr ')'
    | 'PASSWORD' exprWithParentheses
    | 'QUARTER' exprWithParentheses
    | 'REPEAT' '(' expr ',' expr ')'
    | 'REPLACE' '(' expr ',' expr ',' expr ')'
    | 'REVERSE' exprWithParentheses
    | 'ROW_COUNT' '(' ')'
    | 'TRUNCATE' '(' expr ',' expr ')'
    | 'WEEK' '(' expr (',' expr)? ')'
    | 'WEIGHT_STRING' '(' expr (
        ('AS' 'CHAR' wsNumCodepoints)?
        | 'AS' 'BINARY' wsNumCodepoints
        | ',' ulong_number ',' ulong_number ',' ulong_number
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
    : 'GEOMETRYCOLLECTION' '(' exprList? ')'
    | 'LINESTRING' exprListWithParentheses
    | 'MULTILINESTRING' exprListWithParentheses
    | 'MULTIPOINT' exprListWithParentheses
    | 'MULTIPOLYGON' exprListWithParentheses
    | 'POINT' '(' expr ',' expr ')'
    | 'POLYGON' exprListWithParentheses
    ;

timeFunctionParameters
    : '(' (INT_NUMBER)? ')'
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

dateTimeTtype
    : 'DATE'
    | 'TIME'
    | 'DATETIME'
    | 'TIMESTAMP'
    ;

substringFunction
    : 'SUBSTRING' '(' expr (
        ',' expr (',' expr)?
        | 'FROM' expr ('FOR' expr)?
    ) ')'
    ;

functionCall
    : pureIdentifier '(' udfExprList? ')'   // For both UDF + other functions.
    | qualifiedIdentifier '(' exprList? ')' // Other functions only.
    ;

udfExprList
    : udfExpr (',' udfExpr)*
    ;

udfExpr
    : expr selectAlias?
    ;

userVariable
    : '@' textOrIdentifier
    | AT_TEXT_SUFFIX
    ;

rvalueSystemOrUserVariable
    : userVariable
    | '@@' rvalueSystemVariableType? rvalueSystemVariable
    ;

lvalueVariable
    : (
        // Check in semantic phase that the first id is not global/local/session/default.
        identifier dotIdentifier?
        | lValueIdentifier dotIdentifier?
    )
    | 'DEFAULT' dotIdentifier
    ;

rvalueSystemVariable
    : textOrIdentifier dotIdentifier?
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
    | 'SIGNED' 'INT'?
    | 'UNSIGNED' 'INT'?
    | 'DATE'
    | 'YEAR'
    | 'TIME' typeDatetimePrecision?
    | 'DATETIME' typeDatetimePrecision?
    | 'DECIMAL' floatOptions?
    | 'JSON'
    | realType
    | 'FLOAT' (precision)?
    | 'POINT'
    | 'LINESTRING'
    | 'POLYGON'
    | 'MULTIPOINT'
    | 'MULTILINESTRING'
    | 'MULTIPOLYGON'
    | 'GEOMETRYCOLLECTION'
    ;

exprList
    : expr (',' expr)*
    ;

charset
    : 'CHAR' 'SET'
    | 'CHARSET'
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
    | (
        'SECOND_MICROSECOND'
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
    )
    ;

// Support for SQL_TSI_* units is added by mapping those to tokens without SQL_TSI_ prefix.
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

exprListWithParentheses
    : '(' exprList ')'
    ;

exprWithParentheses
    : '(' expr ')'
    ;

simpleExprWithParentheses
    : '(' simpleExpr ')'
    ;

orderList
    : orderExpression (',' orderExpression)*
    ;

orderExpression
    : expr direction?
    ;

groupList
    : expr (',' expr)*
    ;

channel
    : 'FOR' 'CHANNEL' textStringNoLinebreak
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
    : labelIdentifier ':' beginEndBlock (labelIdentifier)?
    ;

beginEndBlock
    : 'BEGIN' spDeclarations? compoundStatementList? 'END'
    ;

labeledControl
    : labelIdentifier ':' unlabeledControl (labelIdentifier)?
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
    : 'DECLARE' identifierList dataType collate? ('DEFAULT' expr)?
    ;

conditionDeclaration
    : 'DECLARE' identifier 'CONDITION' 'FOR' spCondition
    ;

spCondition
    : ulong_number
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
    | identifier
    | 'SQLWARNING'
    | notRule 'FOUND'
    | 'SQLEXCEPTION'
    ;

cursorDeclaration
    : 'DECLARE' identifier 'CURSOR' 'FOR' select
    ;

iterateStatement
    : 'ITERATE' labelIdentifier
    ;

leaveStatement
    : 'LEAVE' labelIdentifier
    ;

getDiagnosticsStatement
    : 'GET' ('CURRENT' | 'STACKED')? 'DIAGNOSTICS' (
        statementInformationItem (',' statementInformationItem)*
        | 'CONDITION' signalAllowedExpr conditionInformationItem (
            ',' conditionInformationItem
        )*
    )
    ;

// Only a limited subset of expr is allowed in SIGNAL/RESIGNAL/CONDITIONS.
signalAllowedExpr
    : literal
    | rvalueSystemOrUserVariable
    | qualifiedIdentifier
    ;

statementInformationItem
    : (userVariable | identifier) '=' ('NUMBER' | 'ROW_COUNT')
    ;

conditionInformationItem
    : (userVariable | identifier) '=' (
        signalInformationItemName
        | 'RETURNED_SQLSTATE'
    )
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
    : 'SIGNAL' (identifier | sqlstate) (
        'SET' signalInformationItem (',' signalInformationItem)*
    )?
    ;

resignalStatement
    : 'RESIGNAL' (identifier | sqlstate)? (
        'SET' signalInformationItem (',' signalInformationItem)*
    )?
    ;

signalInformationItem
    : signalInformationItemName '=' signalAllowedExpr
    ;

cursorOpen
    : 'OPEN' identifier
    ;

cursorClose
    : 'CLOSE' identifier
    ;

cursorFetch
    : 'FETCH' ('NEXT'? 'FROM')? identifier 'INTO' identifierList
    ;

//----------------- Supplemental rules ---------------------------------------------------------------------------------

// Schedules in CREATE/ALTER EVENT.
schedule
    : 'AT' expr
    | 'EVERY' expr interval ('STARTS' expr)? ('ENDS' expr)?
    ;

columnDefinition
    : identifier fieldDefinition checkOrReferences?
    ;

checkOrReferences
    : checkConstraint
    | references
    ;

checkConstraint
    : 'CHECK' exprWithParentheses
    ;

constraintEnforcement
    : 'NOT'? 'ENFORCED'
    ;

tableConstraintDef
    : ('KEY' | 'INDEX') indexNameAndType? keyListWithExpression indexOption*
    | 'FULLTEXT' keyOrIndex? (identifier)? keyListWithExpression fulltextIndexOption*
    | 'SPATIAL' keyOrIndex? (identifier)? keyListWithExpression (commonIndexOption)*
    | constraintName? (
        ('PRIMARY' 'KEY' | 'UNIQUE' keyOrIndex?) indexNameAndType? keyListWithExpression indexOption*
        | 'FOREIGN' 'KEY' (identifier)? keyList references
        | checkConstraint constraintEnforcement?
    )
    ;

constraintName
    : 'CONSTRAINT' identifier?
    ;

fieldDefinition
    : dataType (
        columnAttribute*
        | collate? ('GENERATED' 'ALWAYS')? 'AS' exprWithParentheses (
            'VIRTUAL'
            | 'STORED'
        )? columnAttribute*
    )
    ;

columnAttribute
    : 'NOT'? null
    | 'NOT' 'SECONDARY'
    | 'DEFAULT' ( nowOrSignedLiteral | exprWithParentheses )
    | 'ON' 'UPDATE' 'NOW' timeFunctionParameters?
    | 'AUTO_INCREMENT'
    | 'SERIAL' 'DEFAULT' 'VALUE'
    | 'PRIMARY'? 'KEY'
    | 'UNIQUE' 'KEY'?
    | 'COMMENT' textLiteral
    | collate
    | 'COLUMN_FORMAT' columnFormat
    | 'STORAGE' storageMedia
    | 'SRID' real_ulong_number
    | constraintName? checkConstraint
    | constraintEnforcement
    | 'ENGINE_ATTRIBUTE' '='? textStringLiteral
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? textStringLiteral
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
    | signedLiteralOrNull
    ;

//gcolAttribute
//    : 'UNIQUE' 'KEY'?
//    | 'COMMENT' textString
//    | notRule? 'NULL'
//    | 'PRIMARY'? 'KEY'
//    ;

references
    : 'REFERENCES' tableRef identifierListWithParentheses? (
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
    : identifier fieldLength? direction?
    ;

keyListWithExpression
    : '(' keyPartOrExpression (',' keyPartOrExpression)* ')'
    ;

keyPartOrExpression
    : // key_part_with_expression in sql_yacc.yy.
    keyPart
    | exprWithParentheses direction?
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
    : 'KEY_BLOCK_SIZE' '='? ulong_number
    | 'COMMENT' textLiteral
    | visibility
    | 'ENGINE_ATTRIBUTE' '='? textStringLiteral
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? textStringLiteral
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
    | 'WITH' 'PARSER' identifier
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
    | ('REAL' | 'DOUBLE' 'PRECISION'?) precision? fieldOptions?
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
    | 'ENUM' stringList charsetWithOptBinary?
    | 'SET' stringList charsetWithOptBinary?
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
    : '(' (real_ulong_number | DECIMAL_NUMBER) ')'
    ;

fieldOptions
    : ('SIGNED' | 'UNSIGNED' | 'ZEROFILL')+
    ;

charsetWithOptBinary
    : ascii
    | unicode
    | 'BYTE'
    | charset charsetName 'BINARY'?
    | 'BINARY' (charset charsetName)?
    ;

ascii
    : 'ASCII' 'BINARY'?
    | 'BINARY' 'ASCII'
    ;

unicode
    : 'UNICODE' 'BINARY'?
    | 'BINARY' 'UNICODE'
    ;

wsNumCodepoints
    : '(' real_ulong_number ')'
    ;

typeDatetimePrecision
    : '(' INT_NUMBER ')'
    ;

charsetName
    : textOrIdentifier
    | 'BINARY'
    | 'DEFAULT'
    ;

collationName
    : textOrIdentifier
    | 'DEFAULT'
    | 'BINARY'
    ;

createTableOptions
    : createTableOption (','? createTableOption)*
    ;

createTableOptionsEtc
    : createTableOptions createPartitioningEtc?
    | createPartitioningEtc
    ;

createPartitioningEtc
    : partitionClause duplicateAsQe?
    | duplicateAsQe
    ;

createTableOption
    : // In the order as they appear in the server grammar.
    'ENGINE' '='? textOrIdentifier
    | 'SECONDARY_ENGINE' equal? (
        'NULL'
        | textOrIdentifier
    )
    | 'MAX_ROWS' '='? ulonglongNumber
    | 'MIN_ROWS' '='? ulonglongNumber
    | 'AVG_ROW_LENGTH' '='? ulonglongNumber
    | 'PASSWORD' '='? textStringLiteral
    | 'COMMENT' '='? textStringLiteral
    | 'COMPRESSION' '='? textString
    | 'ENCRYPTION' '='? textString
    | 'AUTO_INCREMENT' '='? ulonglongNumber
    | 'PACK_KEYS' '='? ternaryOption
    | (
        'STATS_AUTO_RECALC'
        | 'STATS_PERSISTENT'
        | 'STATS_SAMPLE_PAGES'
    ) '='? ternaryOption
    | ('CHECKSUM' | 'TABLE_CHECKSUM') '='? ulong_number
    | 'DELAY_KEY_WRITE' '='? ulong_number
    | 'ROW_FORMAT' '='? (
        'DEFAULT'
        | 'DYNAMIC'
        | 'FIXED'
        | 'COMPRESSED'
        | 'REDUNDANT'
        | 'COMPACT'
    )
    | 'UNION' '='? '(' tableRefList ')'
    | defaultCharset
    | defaultCollation
    | 'INSERT_METHOD' '='? (
        'NO'
        | 'FIRST'
        | 'LAST'
    )
    | 'DATA' 'DIRECTORY' '='? textString
    | 'INDEX' 'DIRECTORY' '='? textString
    | 'TABLESPACE' '='? identifier
    | 'STORAGE' ('DISK' | 'MEMORY')
    | 'CONNECTION' '='? textString
    | 'KEY_BLOCK_SIZE' '='? ulonglongNumber
    | 'START' 'TRANSACTION'
    | 'ENGINE_ATTRIBUTE' '='? textStringLiteral
    | 'SECONDARY_ENGINE_ATTRIBUTE' '='? textStringLiteral
    | tsOptionAutoextendSize
    ;

ternaryOption
    : ulong_number
    | 'DEFAULT'
    ;

defaultCollation
    : 'DEFAULT'? 'COLLATE' '='? collationName
    ;

defaultEncryption
    : 'DEFAULT'? 'ENCRYPTION' '='? textStringLiteral
    ;

defaultCharset
    : 'DEFAULT'? charset '='? charsetName
    ;

// Partition rules for CREATE/ALTER TABLE.
partitionClause
    : 'PARTITION' 'BY' partitionTypeDef (
        'PARTITIONS' real_ulong_number
    )? subPartitions? partitionDefinitions?
    ;

partitionTypeDef
    : 'LINEAR'? 'KEY' partitionKeyAlgorithm? '(' identifierList? ')'
    | 'LINEAR'? 'HASH' '(' bitExpr ')'
    | ('RANGE' | 'LIST') (
        '(' bitExpr ')'
        | 'COLUMNS' '(' identifierList? ')'
    )
    ;

subPartitions
    : 'SUBPARTITION' 'BY' 'LINEAR'? (
        'HASH' '(' bitExpr ')'
        | 'KEY' partitionKeyAlgorithm? identifierListWithParentheses
    ) ('SUBPARTITIONS' real_ulong_number)?
    ;

partitionKeyAlgorithm
    : // Actually only 1 and 2 are allowed. Needs a semantic check.
    'ALGORITHM' '=' real_ulong_number
    ;

partitionDefinitions
    : '(' partitionDefinition (',' partitionDefinition)* ')'
    ;

partitionDefinition
    : 'PARTITION' identifier (
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
    : 'TABLESPACE' '='? identifier
    | 'STORAGE'? 'ENGINE' '='? textOrIdentifier
    | 'NODEGROUP' '='? real_ulong_number
    | ('MAX_ROWS' | 'MIN_ROWS') '='? real_ulong_number
    | ('DATA' | 'INDEX') 'DIRECTORY' '='? textLiteral
    | 'COMMENT' '='? textLiteral
    ;

subpartitionDefinition
    : 'SUBPARTITION' textOrIdentifier partitionOption*
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

ifExistsIdentifier
    : ifExists persistedVariableIdentifier
    ;

persistedVariableIdentifier
    : identifier
    | (
        qualifiedIdentifier
        | 'DEFAULT' dotIdentifier
    )
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
    : identifier typeWithOptCollate
    ;

collate
    : 'COLLATE' collationName
    ;

typeWithOptCollate
    : dataType collate?
    ;

schemaIdentifierPair
    : '(' identifier ',' identifier ')'
    ;

viewRefList
    : viewRef (',' viewRef)*
    ;

updateList
    : updateElement (',' updateElement)*
    ;

updateElement
    : fieldIdentifier '=' (expr | 'DEFAULT')
    ;

charsetClause
    : charset charsetName
    ;

fieldsClause
    : 'COLUMNS' fieldTerm+
    ;

fieldTerm
    : 'TERMINATED' 'BY' textString
    | 'OPTIONALLY'? 'ENCLOSED' 'BY' textString
    | 'ESCAPED' 'BY' textString
    ;

linesClause
    : 'LINES' lineTerm+
    ;

lineTerm
    : ('TERMINATED' | 'STARTING') 'BY' textString
    ;

userList
    : user (',' user)*
    ;

createUserList
    : createUser (',' createUser)*
    ;

createUser
    : user (
        identification createUserWithMfa?
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
    : 'IDENTIFIED' 'BY' textStringLiteral
    ;

identifiedByRandomPassword
    : 'IDENTIFIED' 'BY' 'RANDOM' 'PASSWORD'
    ;

identifiedWithPlugin
    : 'IDENTIFIED' 'WITH' textOrIdentifier
    ;

identifiedWithPluginAsAuth
    : 'IDENTIFIED' 'WITH' textOrIdentifier 'AS' textStringHash
    ;

identifiedWithPluginByPassword
    : 'IDENTIFIED' 'WITH' textOrIdentifier 'BY' textStringLiteral
    ;

identifiedWithPluginByRandomPassword
    : 'IDENTIFIED' 'WITH' textOrIdentifier 'BY' 'RANDOM' 'PASSWORD'
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
    : numLiteral 'FACTOR'
    ;

replacePassword
    : 'REPLACE' textString
    ;

userIdentifierOrText
    : textOrIdentifier userVariable?
    ;

user
    : userIdentifierOrText
    | 'CURRENT_USER' ('(' ')')?
    ;

likeClause
    : 'LIKE' textStringLiteral
    ;

likeOrWhere
    : // opt_wild_or_where in sql_yacc.yy
    likeClause
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
    : 'PARTITION' identifierListWithParentheses
    ;

//----------------- Object names and references ------------------------------------------------------------------------

// For each object we have at least 2 rules here:
// 1) The name when creating that object.
// 2) The name when used to reference it from other rules.
//
// Sometimes we need additional reference rules with different form, depending on the place such a reference is used.

// A name for a field (column/index). Can be qualified with the current schema + table (although it's not a reference).
fieldIdentifier
    : dotIdentifier
    | qualifiedIdentifier dotIdentifier?
    ;

// A reference to a column of the object we are working on.
columns
    : // column_list (+ parentheses) + opt_derived_column_list in sql_yacc.yy
    '(' identifier (',' identifier)* ')'
    ;

insertIdentifier
    : fieldIdentifier
    | tableWild
    ;

tableWild
    : identifier '.' (identifier '.')? '*'
    ;

viewName
    : qualifiedIdentifier
    | dotIdentifier
    ;

viewRef
    : qualifiedIdentifier
    | dotIdentifier
    ;

udfName
    : // UDFs are referenced at the same places as any other function. So, no dedicated *_ref here.
    identifier
    ;

tableName
    : qualifiedIdentifier
    | dotIdentifier
    ;

filterTableRef
    : // Always qualified.
    identifier dotIdentifier
    ;

tableRefWithWildcard
    : identifier (
        '.' '*'
        | dotIdentifier ('.' '*')?
    )?
    ;

tableRef
    : qualifiedIdentifier
    | dotIdentifier
    ;

tableRefList
    : tableRef (',' tableRef)*
    ;

tableAliasRefList
    : tableRefWithWildcard (',' tableRefWithWildcard)*
    ;

labelIdentifier
    : pureIdentifier
    | labelKeyword
    ;

roleIdentifier
    : pureIdentifier
    | roleKeyword
    ;

//----------------- Common basic rules ---------------------------------------------------------------------------------

// Identifiers excluding keywords (except if they are quoted). IDENT_sys in sql_yacc.yy.
pureIdentifier
    : IDENTIFIER
    | BACK_TICK_QUOTED_ID
    | DOUBLE_QUOTED_TEXT
    ;

// Identifiers including a certain set of keywords, which are allowed also if not quoted.
// ident in sql_yacc.yy
identifier
    : pureIdentifier
    | identifierKeyword
    ;

identifierList
    : // ident_string_list in sql_yacc.yy.
    identifier (',' identifier)*
    ;

identifierListWithParentheses
    : '(' identifierList ')'
    ;

qualifiedIdentifier
    : identifier dotIdentifier?
    ;

simpleIdentifier
    : // simple_ident + simple_ident_q
    identifier (dotIdentifier dotIdentifier?)?
    ;

// This rule encapsulates the frequently used dot + identifier sequence, which also requires a special
// treatment in the lexer. See there in the DOT_IDENTIFIER rule.
dotIdentifier
    : '.' identifier
    ;

ulong_number
    : INT_NUMBER
    | HEX_NUMBER
//    | LONG_NUMBER
//    | ULONGLONG_NUMBER
    | DECIMAL_NUMBER
    | FLOAT_NUMBER
    ;

real_ulong_number
    : INT_NUMBER
    | HEX_NUMBER
//    | LONG_NUMBER
//    | ULONGLONG_NUMBER
    ;

ulonglongNumber
    : INT_NUMBER
//    | LONG_NUMBER
//    | ULONGLONG_NUMBER
    | DECIMAL_NUMBER
    | FLOAT_NUMBER
    ;

signedLiteral
    : literal
    | '+' ulong_number
    | '-' ulong_number
    ;

signedLiteralOrNull
    : signedLiteral
//    | 'NULL'
    ;

literal
    : textLiteral
    | numLiteral
    | temporalLiteral
    | null
    | boolLiteral
    | UNDERSCORE_CHARSET? (HEX_NUMBER | BIN_NUMBER)
    ;

stringList
    : '(' textString (',' textString)* ')'
    ;

// TEXT_STRING_sys + TEXT_STRING_literal + TEXT_STRING_filesystem + TEXT_STRING + TEXT_STRING_password +
// TEXT_STRING_validated in sql_yacc.yy.
textStringLiteral
    : SINGLE_QUOTED_TEXT
    | DOUBLE_QUOTED_TEXT
    ;

textString
    : textStringLiteral
    | HEX_NUMBER
    | BIN_NUMBER
    ;

textStringHash
    : textStringLiteral
    | HEX_NUMBER
    ;

textLiteral
    : (UNDERSCORE_CHARSET? textStringLiteral | NCHAR_TEXT) textStringLiteral*
    ;

// A special variant of a text string that must not contain a linebreak (TEXT_STRING_sys_nonewline in sql_yacc.yy).
// Check validity in semantic phase.
textStringNoLinebreak
    : textStringLiteral
    ;

textStringLiteralList
    : textStringLiteral (',' textStringLiteral)*
    ;

numLiteral
    : INT_NUMBER
    | DECIMAL_NUMBER
    | FLOAT_NUMBER
    ;

boolLiteral
    : 'TRUE'
    | 'FALSE'
    ;

// In sql_yacc.cc both 'NULL' and '\N' are mapped to 'NULL'(which is our nullLiteral).
null
    : 'NULL' | '\\N' ;

// int64Literal if for unsigned exact integer literals in a range of [0 .. 2^64-1].

temporalLiteral
    : 'DATE' SINGLE_QUOTED_TEXT
    | 'TIME' SINGLE_QUOTED_TEXT
    | 'TIMESTAMP' SINGLE_QUOTED_TEXT
    ;

floatOptions
    : fieldLength
    | precision
    ;

precision
    : '(' INT_NUMBER ',' INT_NUMBER ')'
    ;

textOrIdentifier
    : identifier
    | textStringLiteral
    ;

lValueIdentifier
    : pureIdentifier
    | lValueKeyword
    ;

roleIdentifierOrText
    : roleIdentifier
    | textStringLiteral
    ;

sizeNumber
    : real_ulong_number
    | pureIdentifier // Something like 10G. Semantic check needed for validity.
    ;

equal
    : '='
    | ':='
    ;

optionType
    : 'PERSIST'
    | 'PERSIST_ONLY'
    | 'GLOBAL'
    | 'LOCAL'
    | 'SESSION'
    ;

rvalueSystemVariableType
    : 'GLOBAL' '.'
    | 'LOCAL' '.'
    | 'SESSION' '.'
    ;

setVarIdentType
    : (
        'PERSIST'
        | 'PERSIST_ONLY'
        | 'GLOBAL'
        | 'LOCAL'
        | 'SESSION'
    ) '.'
    ;

// Note: rules for non-reserved keywords have changed significantly with MySQL 8.0.17, which make their
//       version dependent handling complicated.
//       Comments for keyword rules are taken over directly from the server grammar, but usually don't apply here
//       since we don't have something like shift/reduce conflicts in ANTLR4 (which those ugly rules try to overcome).

// Non-reserved keywords are allowed as unquoted identifiers in general.
//
// OTOH, in a few particular cases statement-specific rules are used
// instead of `ident_keyword` to avoid grammar ambiguities:
//
//  * `label_keyword` for SP label names
//  * `role_keyword` for role names
//  * `lvalue_keyword` for variable prefixes and names in left sides of
//                     assignments in SET statements
//
// Normally, new non-reserved words should be added to the
// the rule `ident_keywords_unambiguous`. If they cause grammar conflicts, try
// one of `ident_keywords_ambiguous_...` rules instead.
identifierKeyword
    : (
        labelKeyword
        | roleOrIdentifierKeyword
        | 'EXECUTE'
        | 'SHUTDOWN' // Previously allowed as SP label as well.
        | 'RESTART'
    )
    | (
        identifierKeywordsUnambiguous
        | identifierKeywordsAmbiguous1RolesAndLabels
        | identifierKeywordsAmbiguous2Labels
        | identifierKeywordsAmbiguous3Roles
        | identifierKeywordsAmbiguous4SystemVariables
    )
    ;

// These non-reserved words cannot be used as role names and SP label names:
identifierKeywordsAmbiguous1RolesAndLabels
    : 'EXECUTE'
    | 'RESTART'
    | 'SHUTDOWN'
    ;

// These non-reserved keywords cannot be used as unquoted SP label names:
identifierKeywordsAmbiguous2Labels
    : 'ASCII'
    | 'BEGIN'
    | 'BYTE'
    | 'CACHE'
    | 'CHARSET'
    | 'CHECKSUM'
    | 'CLONE'
    | 'COMMENT'
    | 'COMMIT'
    | 'CONTAINS'
    | 'DEALLOCATE'
    | 'DO'
    | 'END'
    | 'FLUSH'
    | 'FOLLOWS'
    | 'HANDLER'
    | 'HELP'
    | 'IMPORT'
    | 'INSTALL'
    | 'LANGUAGE'
    | 'NO'
    | 'PRECEDES'
    | 'PREPARE'
    | 'REPAIR'
    | 'RESET'
    | 'ROLLBACK'
    | 'SAVEPOINT'
    | 'SIGNED'
    | 'SLAVE'
    | 'START'
    | 'STOP'
    | 'TRUNCATE'
    | 'UNICODE'
    | 'UNINSTALL'
    | 'XA'
    ;

// Keywords that we allow for labels in SPs in the unquoted form.
// Any keyword that is allowed to begin a statement or routine characteristics
// must be in `ident_keywords_ambiguous_2_labels` above, otherwise
// we get (harmful) shift/reduce conflicts.
//
// Not allowed:
//
//   ident_keywords_ambiguous_1_roles_and_labels
//   ident_keywords_ambiguous_2_labels
labelKeyword
    : (
        roleOrLabelKeyword
        | 'EVENT'
        | 'FILE'
        | 'NONE'
        | 'PROCESS'
        | 'PROXY'
        | 'RELOAD'
        | 'REPLICATION'
        | 'RESOURCE'
        | 'SUPER'
    )
    | (
        identifierKeywordsUnambiguous
        | identifierKeywordsAmbiguous3Roles
        | identifierKeywordsAmbiguous4SystemVariables
    )
    ;

// These non-reserved keywords cannot be used as unquoted role names:
identifierKeywordsAmbiguous3Roles
    : 'EVENT'
    | 'FILE'
    | 'NONE'
    | 'PROCESS'
    | 'PROXY'
    | 'RELOAD'
    | 'REPLICATION'
    | 'RESOURCE'
    | 'SUPER'
    ;

// These are the non-reserved keywords which may be used for unquoted
// identifiers everywhere without introducing grammar conflicts:
identifierKeywordsUnambiguous
    : (
        'ACTION'
        | 'ACCOUNT'
        | 'ACTIVE'
        | 'ADDDATE'
        | 'ADMIN'
        | 'AFTER'
        | 'AGAINST'
        | 'AGGREGATE'
        | 'ALGORITHM'
        | 'ALWAYS'
        | 'ANY'
        | 'AT'
        | 'ATTRIBUTE'
        | 'AUTHENTICATION'
        | 'AUTOEXTEND_SIZE'
        | 'AUTO_INCREMENT'
        | 'AVG_ROW_LENGTH'
        | 'AVG'
        | 'BACKUP'
        | 'BINLOG'
        | 'BIT'
        | 'BLOCK'
        | 'BOOLEAN'
        | 'BOOL'
        | 'BTREE'
        | 'BUCKETS'
        | 'CASCADED'
        | 'CATALOG_NAME'
        | 'CHAIN'
        | 'CHALLENGE_RESPONSE'
        | 'CHANGED'
        | 'CHANNEL'
        | 'CIPHER'
        | 'CLASS_ORIGIN'
        | 'CLIENT'
        | 'CLOSE'
        | 'COALESCE'
        | 'CODE'
        | 'COLLATION'
        | 'COLUMNS'
        | 'COLUMN_FORMAT'
        | 'COLUMN_NAME'
        | 'COMMITTED'
        | 'COMPACT'
        | 'COMPLETION'
        | 'COMPONENT'
        | 'COMPRESSED'
        | 'COMPRESSION'
        | 'CONCURRENT'
        | 'CONNECTION'
        | 'CONSISTENT'
        | 'CONSTRAINT_CATALOG'
        | 'CONSTRAINT_NAME'
        | 'CONSTRAINT_SCHEMA'
        | 'CONTEXT'
        | 'CPU'
        | 'CURRENT'
        | 'CURSOR_NAME'
        | 'DATAFILE'
        | 'DATA'
        | 'DATETIME'
        | 'DATE'
        | 'DAY'
        | 'DEFAULT_AUTH'
        | 'DEFINER'
        | 'DEFINITION'
        | 'DELAY_KEY_WRITE'
        | 'DESCRIPTION'
        | 'DIAGNOSTICS'
        | 'DIRECTORY'
        | 'DISABLE'
        | 'DISCARD'
        | 'DISK'
        | 'DUMPFILE'
        | 'DUPLICATE'
        | 'DYNAMIC'
        | 'ENABLE'
        | 'ENCRYPTION'
        | 'ENDS'
        | 'ENFORCED'
        | 'ENGINES'
        | 'ENGINE'
        | 'ENUM'
        | 'ERRORS'
        | 'ERROR'
        | 'ESCAPE'
        | 'EVENTS'
        | 'EVERY'
        | 'EXCHANGE'
        | 'EXCLUDE'
        | 'EXPANSION'
        | 'EXPIRE'
        | 'EXPORT'
        | 'EXTENDED'
        | 'EXTENT_SIZE'
        | 'FACTOR'
        | 'FAST'
        | 'FAULTS'
        | 'FILE_BLOCK_SIZE'
        | 'FILTER'
        | 'FINISH'
        | 'FIRST'
        | 'FIXED'
        | 'FOLLOWING'
        | 'FORMAT'
        | 'FOUND'
        | 'FULL'
        | 'GENERAL'
        | 'GEOMETRYCOLLECTION'
        | 'GEOMETRY'
        | 'GET_FORMAT'
        | 'GET_MASTER_PUBLIC_KEY'
        | 'GET_SOURCE_PUBLIC_KEY'
        | 'GRANTS'
        | 'GROUP_REPLICATION'
        | 'GTID_ONLY'
        | 'HASH'
        | 'HISTOGRAM'
        | 'HISTORY'
        | 'HOSTS'
        | 'HOST'
        | 'HOUR'
        | 'IDENTIFIED'
        | 'IGNORE_SERVER_IDS'
        | 'INACTIVE'
        | 'INDEXES'
        | 'INITIAL_SIZE'
        | 'INITIAL'
        | 'INITIATE'
        | 'INSERT_METHOD'
        | 'INSTANCE'
        | 'INVISIBLE'
        | 'INVOKER'
        | 'IO'
        | 'IPC'
        | 'ISOLATION'
        | 'ISSUER'
        | 'JSON'
        | 'JSON_VALUE'
        | 'KEY_BLOCK_SIZE'
        | 'KEYRING'
        | 'LAST'
        | 'LEAVES'
        | 'LESS'
        | 'LEVEL'
        | 'LINESTRING'
        | 'LIST'
        | 'LOCKED'
        | 'LOCKS'
        | 'LOGFILE'
        | 'LOGS'
        | 'MASTER_AUTO_POSITION'
        | 'MASTER_COMPRESSION_ALGORITHM'
        | 'MASTER_CONNECT_RETRY'
        | 'MASTER_DELAY'
        | 'MASTER_HEARTBEAT_PERIOD'
        | 'MASTER_HOST'
        | 'NETWORK_NAMESPACE'
        | 'MASTER_LOG_FILE'
        | 'MASTER_LOG_POS'
        | 'MASTER_PASSWORD'
        | 'MASTER_PORT'
        | 'MASTER_PUBLIC_KEY_PATH'
        | 'MASTER_RETRY_COUNT'
        | 'MASTER_SSL_CAPATH'
        | 'MASTER_SSL_CA'
        | 'MASTER_SSL_CERT'
        | 'MASTER_SSL_CIPHER'
        | 'MASTER_SSL_CRLPATH'
        | 'MASTER_SSL_CRL'
        | 'MASTER_SSL_KEY'
        | 'MASTER_SSL'
        | 'MASTER'
        | 'MASTER_TLS_CIPHERSUITES'
        | 'MASTER_TLS_VERSION'
        | 'MASTER_USER'
        | 'MASTER_ZSTD_COMPRESSION_LEVEL'
        | 'MAX_CONNECTIONS_PER_HOUR'
        | 'MAX_QUERIES_PER_HOUR'
        | 'MAX_ROWS'
        | 'MAX_SIZE'
        | 'MAX_UPDATES_PER_HOUR'
        | 'MAX_USER_CONNECTIONS'
        | 'MEDIUM'
        | 'MEMORY'
        | 'MERGE'
        | 'MESSAGE_TEXT'
        | 'MICROSECOND'
        | 'MIGRATE'
        | 'MINUTE'
        | 'MIN_ROWS'
        | 'MODE'
        | 'MODIFY'
        | 'MONTH'
        | 'MULTILINESTRING'
        | 'MULTIPOINT'
        | 'MULTIPOLYGON'
        | 'MUTEX'
        | 'MYSQL_ERRNO'
        | 'NAMES'
        | 'NAME'
        | 'NATIONAL'
        | 'NCHAR'
        | 'NDBCLUSTER'
        | 'NESTED'
        | 'NEVER'
        | 'NEW'
        | 'NEXT'
        | 'NODEGROUP'
        | 'NOWAIT'
        | 'NO_WAIT'
        | 'NULLS'
        | 'NUMBER'
        | 'NVARCHAR'
        | 'OFFSET'
        | 'OJ'
        | 'OLD'
        | 'ONE'
        | 'ONLY'
        | 'OPEN'
        | 'OPTIONAL'
        | 'OPTIONS'
        | 'ORDINALITY'
        | 'ORGANIZATION'
        | 'OTHERS'
        | 'OWNER'
        | 'PACK_KEYS'
        | 'PAGE'
        | 'PARSER'
        | 'PARTIAL'
        | 'PARTITIONING'
        | 'PARTITIONS'
        | 'PASSWORD'
        | 'PATH'
        | 'PHASE'
        | 'PLUGINS'
        | 'PLUGIN_DIR'
        | 'PLUGIN'
        | 'POINT'
        | 'POLYGON'
        | 'PORT'
        | 'PRECEDING'
        | 'PRESERVE'
        | 'PREV'
        | 'PRIVILEGES'
        | 'PRIVILEGE_CHECKS_USER'
        | 'PROCESSLIST'
        | 'PROFILES'
        | 'PROFILE'
        | 'QUARTER'
        | 'QUERY'
        | 'QUICK'
        | 'READ_ONLY'
        | 'REBUILD'
        | 'RECOVER'
        | 'REDO_BUFFER_SIZE'
        | 'REDUNDANT'
        | 'REFERENCE'
        | 'REGISTRATION'
        | 'RELAY'
        | 'RELAYLOG'
        | 'RELAY_LOG_FILE'
        | 'RELAY_LOG_POS'
        | 'RELAY_THREAD'
        | 'REMOVE'
        | 'ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS'
        | 'REORGANIZE'
        | 'REPEATABLE'
        | 'REPLICAS'
        | 'REPLICATE_DO_DB'
        | 'REPLICATE_DO_TABLE'
        | 'REPLICATE_IGNORE_DB'
        | 'REPLICATE_IGNORE_TABLE'
        | 'REPLICATE_REWRITE_DB'
        | 'REPLICATE_WILD_DO_TABLE'
        | 'REPLICATE_WILD_IGNORE_TABLE'
        | 'REPLICA'
        | 'USER_RESOURCES'
        | 'RESPECT'
        | 'RESTORE'
        | 'RESUME'
        | 'RETAIN'
        | 'RETURNED_SQLSTATE'
        | 'RETURNING'
        | 'RETURNS'
        | 'REUSE'
        | 'REVERSE'
        | 'ROLE'
        | 'ROLLUP'
        | 'ROTATE'
        | 'ROUTINE'
        | 'ROW_COUNT'
        | 'ROW_FORMAT'
        | 'RTREE'
        | 'SCHEDULE'
        | 'SCHEMA_NAME'
        | 'SECONDARY_ENGINE'
        | 'SECONDARY_ENGINE_ATTRIBUTE'
        | 'SECONDARY_LOAD'
        | 'SECONDARY'
        | 'SECONDARY_UNLOAD'
        | 'SECOND'
        | 'SECURITY'
        | 'SERIALIZABLE'
        | 'SERIAL'
        | 'SERVER'
        | 'SHARE'
        | 'SIMPLE'
        | 'SKIP'
        | 'SLOW'
        | 'SNAPSHOT'
        | 'SOCKET'
        | 'SONAME'
        | 'SOUNDS'
        | 'SOURCE_AUTO_POSITION'
        | 'SOURCE_BIND'
        | 'SOURCE_COMPRESSION_ALGORITHM'
        | 'SOURCE_CONNECTION_AUTO_FAILOVER'
        | 'SOURCE_CONNECT_RETRY'
        | 'SOURCE_DELAY'
        | 'SOURCE_HEARTBEAT_PERIOD'
        | 'SOURCE_HOST'
        | 'SOURCE_LOG_FILE'
        | 'SOURCE_LOG_POS'
        | 'SOURCE_PASSWORD'
        | 'SOURCE_PORT'
        | 'SOURCE_PUBLIC_KEY_PATH'
        | 'SOURCE_RETRY_COUNT'
        | 'SOURCE_SSL_CAPATH'
        | 'SOURCE_SSL_CA'
        | 'SOURCE_SSL_CERT'
        | 'SOURCE_SSL_CIPHER'
        | 'SOURCE_SSL_CRLPATH'
        | 'SOURCE_SSL_CRL'
        | 'SOURCE_SSL_KEY'
        | 'SOURCE_SSL'
        | 'SOURCE_SSL_VERIFY_SERVER_CERT'
        | 'SOURCE'
        | 'SOURCE_TLS_CIPHERSUITES'
        | 'SOURCE_TLS_VERSION'
        | 'SOURCE_USER'
        | 'SOURCE_ZSTD_COMPRESSION_LEVEL'
        | 'SQL_AFTER_GTIDS'
        | 'SQL_AFTER_MTS_GAPS'
        | 'SQL_BEFORE_GTIDS'
        | 'SQL_BUFFER_RESULT'
        | 'SQL_NO_CACHE'
        | 'SQL_THREAD'
        | 'SRID'
        | 'STACKED'
        | 'STARTS'
        | 'STATS_AUTO_RECALC'
        | 'STATS_PERSISTENT'
        | 'STATS_SAMPLE_PAGES'
        | 'STATUS'
        | 'STORAGE'
        | 'STRING'
        | 'ST_COLLECT'
        | 'SUBCLASS_ORIGIN'
        | 'SUBDATE'
        | 'SUBJECT'
        | 'SUBPARTITIONS'
        | 'SUBPARTITION'
        | 'SUSPEND'
        | 'SWAPS'
        | 'SWITCHES'
        | 'TABLES'
        | 'TABLESPACE'
        | 'TABLE_CHECKSUM'
        | 'TABLE_NAME'
        | 'TEMPORARY'
        | 'TEMPTABLE'
        | 'TEXT'
        | 'THAN'
        | 'THREAD_PRIORITY'
        | 'TIES'
        | 'TIMESTAMPADD'
        | 'TIMESTAMPDIFF'
        | 'TIMESTAMP'
        | 'TIME'
        | 'TLS'
        | 'TRANSACTION'
        | 'TRIGGERS'
        | 'TYPES'
        | 'TYPE'
        | 'UNBOUNDED'
        | 'UNCOMMITTED'
        | 'UNDEFINED'
        | 'UNDOFILE'
        | 'UNDO_BUFFER_SIZE'
        | 'UNKNOWN'
        | 'UNREGISTER'
        | 'UNTIL'
        | 'UPGRADE'
        | 'USER'
        | 'USE_FRM'
        | 'VALIDATION'
        | 'VALUE'
        | 'VARIABLES'
        | 'VCPU'
        | 'VIEW'
        | 'VISIBLE'
        | 'WAIT'
        | 'WARNINGS'
        | 'WEEK'
        | 'WEIGHT_STRING'
        | 'WITHOUT'
        | 'WORK'
        | 'WRAPPER'
        | 'X509'
        | 'XID'
        | 'XML'
        | 'YEAR'
        | 'ZONE'
    )
    | (
        'ARRAY'
        | 'FAILED_LOGIN_ATTEMPTS'
        | 'MASTER_COMPRESSION_ALGORITHM'
        | 'MASTER_TLS_CIPHERSUITES'
        | 'MASTER_ZSTD_COMPRESSION_LEVEL'
        | 'MEMBER'
        | 'OFF'
        | 'PASSWORD_LOCK_TIME'
        | 'PRIVILEGE_CHECKS_USER'
        | 'RANDOM'
        | 'REQUIRE_ROW_FORMAT'
        | 'REQUIRE_TABLE_PRIMARY_KEY_CHECK'
        | 'STREAM'
        | 'TIMESTAMP'
        | 'TIME'
    )
    | (
        'BULK'
        | 'GENERATE'
        | 'GTIDS'
        | 'LOG'
        | 'PARSE_TREE'
        | 'S3'
        | 'BERNOULLI'
    )
    /* INSERT OTHER KEYWORDS HERE */
    ;

// Non-reserved keywords that we allow for unquoted role names:
//
//  Not allowed:
//
//    ident_keywords_ambiguous_1_roles_and_labels
//    ident_keywords_ambiguous_3_roles
roleKeyword
    : (roleOrLabelKeyword | roleOrIdentifierKeyword)
    | (
        identifierKeywordsUnambiguous
        | identifierKeywordsAmbiguous2Labels
        | identifierKeywordsAmbiguous4SystemVariables
    )
    ;

// Non-reserved words allowed for unquoted unprefixed variable names and
// unquoted variable prefixes in the left side of assignments in SET statements:
//
// Not allowed:
//
//   ident_keywords_ambiguous_4_system_variables
lValueKeyword
    : identifierKeywordsUnambiguous
    | identifierKeywordsAmbiguous1RolesAndLabels
    | identifierKeywordsAmbiguous2Labels
    | identifierKeywordsAmbiguous3Roles
    ;

// These non-reserved keywords cannot be used as unquoted unprefixed
// variable names and unquoted variable prefixes in the left side of
// assignments in SET statements:
identifierKeywordsAmbiguous4SystemVariables
    : 'GLOBAL'
    | 'LOCAL'
    | 'PERSIST'
    | 'PERSIST_ONLY'
    | 'SESSION'
    ;

// $antlr-format groupedAlignments off

// These are the non-reserved keywords which may be used for roles or idents.
// Keywords defined only for specific server versions are handled at lexer level and so cannot match this rule
// if the current server version doesn't allow them. Hence we don't need predicates here for them.
roleOrIdentifierKeyword
    : (
        'ACCOUNT'
        | 'ASCII'
        | 'ALWAYS'
        | 'BACKUP'
        | 'BEGIN'
        | 'BYTE'
        | 'CACHE'
        | 'CHARSET'
        | 'CHECKSUM'
        | 'CLONE'
        | 'CLOSE'
        | 'COMMENT'
        | 'COMMIT'
        | 'CONTAINS'
        | 'DEALLOCATE'
        | 'DO'
        | 'END'
        | 'FLUSH'
        | 'FOLLOWS'
        | 'FORMAT'
        | 'GROUP_REPLICATION'
        | 'HANDLER'
        | 'HELP'
        | 'HOST'
        | 'INSTALL'
        | 'INVISIBLE'
        | 'LANGUAGE'
        | 'NO'
        | 'OPEN'
        | 'OPTIONS'
        | 'OWNER'
        | 'PARSER'
        | 'PARTITION'
        | 'PORT'
        | 'PRECEDES'
        | 'PREPARE'
        | 'REMOVE'
        | 'REPAIR'
        | 'RESET'
        | 'RESTORE'
        | 'ROLE'
        | 'ROLLBACK'
        | 'SAVEPOINT'
        | 'SECONDARY'
        | 'SECONDARY_ENGINE'
        | 'SECONDARY_LOAD'
        | 'SECONDARY_UNLOAD'
        | 'SECURITY'
        | 'SERVER'
        | 'SIGNED'
        | 'SOCKET'
        | 'SLAVE'
        | 'SONAME'
        | 'START'
        | 'STOP'
        | 'TRUNCATE'
        | 'UNICODE'
        | 'UNINSTALL'
        | 'UPGRADE'
        | 'VISIBLE'
        | 'WRAPPER'
        | 'XA'
    )
    ;

roleOrLabelKeyword
    : (
        'ACTION'
        | 'ACTIVE'
        | 'ADDDATE'
        | 'AFTER'
        | 'AGAINST'
        | 'AGGREGATE'
        | 'ALGORITHM'
        | 'ANY'
        | 'AT'
        | 'AUTO_INCREMENT'
        | 'AUTOEXTEND_SIZE'
        | 'AVG_ROW_LENGTH'
        | 'AVG'
        | 'BINLOG'
        | 'BIT'
        | 'BLOCK'
        | 'BOOL'
        | 'BOOLEAN'
        | 'BTREE'
        | 'BUCKETS'
        | 'CASCADED'
        | 'CATALOG_NAME'
        | 'CHAIN'
        | 'CHANGED'
        | 'CHANNEL'
        | 'CIPHER'
        | 'CLIENT'
        | 'CLASS_ORIGIN'
        | 'COALESCE'
        | 'CODE'
        | 'COLLATION'
        | 'COLUMN_NAME'
        | 'COLUMN_FORMAT'
        | 'COLUMNS'
        | 'COMMITTED'
        | 'COMPACT'
        | 'COMPLETION'
        | 'COMPONENT'
        | 'COMPRESSED'
        | 'COMPRESSION'
        | 'CONCURRENT'
        | 'CONNECTION'
        | 'CONSISTENT'
        | 'CONSTRAINT_CATALOG'
        | 'CONSTRAINT_SCHEMA'
        | 'CONSTRAINT_NAME'
        | 'CONTEXT'
        | 'CPU'
        | 'CURRENT'
        | 'CURSOR_NAME'
        | 'DATA'
        | 'DATAFILE'
        | 'DATETIME'
        | 'DATE'
        | 'DAY'
        | 'DEFAULT_AUTH'
        | 'DEFINER'
        | 'DELAY_KEY_WRITE'
        | 'DESCRIPTION'
        | 'DIAGNOSTICS'
        | 'DIRECTORY'
        | 'DISABLE'
        | 'DISCARD'
        | 'DISK'
        | 'DUMPFILE'
        | 'DUPLICATE'
        | 'DYNAMIC'
        | 'ENCRYPTION'
        | 'ENDS'
        | 'ENUM'
        | 'ENGINE'
        | 'ENGINES'
        | 'ENGINE_ATTRIBUTE'
        | 'ERROR'
        | 'ERRORS'
        | 'ESCAPE'
        | 'EVENTS'
        | 'EVERY'
        | 'EXCLUDE'
        | 'EXPANSION'
        | 'EXPORT'
        | 'EXTENDED'
        | 'EXTENT_SIZE'
        | 'FAULTS'
        | 'FAST'
        | 'FOLLOWING'
        | 'FOUND'
        | 'ENABLE'
        | 'FULL'
        | 'FILE_BLOCK_SIZE'
        | 'FILTER'
        | 'FIRST'
        | 'FIXED'
        | 'GENERAL'
        | 'GEOMETRY'
        | 'GEOMETRYCOLLECTION'
        | 'GET_FORMAT'
        | 'GRANTS'
        | 'GLOBAL'
        | 'HASH'
        | 'HISTOGRAM'
        | 'HISTORY'
        | 'HOSTS'
        | 'HOUR'
        | 'IDENTIFIED'
        | 'IGNORE_SERVER_IDS'
        | 'INVOKER'
        | 'INDEXES'
        | 'INITIAL_SIZE'
        | 'INSTANCE'
        | 'INACTIVE'
        | 'IO'
        | 'IPC'
        | 'ISOLATION'
        | 'ISSUER'
        | 'INSERT_METHOD'
        | 'JSON'
        | 'KEY_BLOCK_SIZE'
        | 'LAST'
        | 'LEAVES'
        | 'LESS'
        | 'LEVEL'
        | 'LINESTRING'
        | 'LIST'
        | 'LOCAL'
        | 'LOCKED'
        | 'LOCKS'
        | 'LOGFILE'
        | 'LOGS'
        | 'MAX_ROWS'
        | 'MASTER'
        | 'MASTER_HEARTBEAT_PERIOD'
        | 'MASTER_HOST'
        | 'MASTER_PORT'
        | 'MASTER_LOG_FILE'
        | 'MASTER_LOG_POS'
        | 'MASTER_USER'
        | 'MASTER_PASSWORD'
        | 'MASTER_PUBLIC_KEY_PATH'
        | 'MASTER_CONNECT_RETRY'
        | 'MASTER_RETRY_COUNT'
        | 'MASTER_DELAY'
        | 'MASTER_SSL'
        | 'MASTER_SSL_CA'
        | 'MASTER_SSL_CAPATH'
        | 'MASTER_TLS_VERSION'
        | 'MASTER_SSL_CERT'
        | 'MASTER_SSL_CIPHER'
        | 'MASTER_SSL_CRL'
        | 'MASTER_SSL_CRLPATH'
        | 'MASTER_SSL_KEY'
        | 'MASTER_AUTO_POSITION'
        | 'MAX_CONNECTIONS_PER_HOUR'
        | 'MAX_QUERIES_PER_HOUR'
        | 'MAX_SIZE'
        | 'MAX_UPDATES_PER_HOUR'
        | 'MAX_USER_CONNECTIONS'
        | 'MEDIUM'
        | 'MEMORY'
        | 'MERGE'
        | 'MESSAGE_TEXT'
        | 'MICROSECOND'
        | 'MIGRATE'
        | 'MINUTE'
        | 'MIN_ROWS'
        | 'MODIFY'
        | 'MODE'
        | 'MONTH'
        | 'MULTILINESTRING'
        | 'MULTIPOINT'
        | 'MULTIPOLYGON'
        | 'MUTEX'
        | 'MYSQL_ERRNO'
        | 'NAME'
        | 'NAMES'
        | 'NATIONAL'
        | 'NCHAR'
        | 'NDBCLUSTER'
        | 'NESTED'
        | 'NEVER'
        | 'NEXT'
        | 'NEW'
        | 'NO_WAIT'
        | 'NODEGROUP'
        | 'NULLS'
        | 'NOWAIT'
        | 'NUMBER'
        | 'NVARCHAR'
        | 'OFFSET'
        | 'OLD'
        | 'ONE'
        | 'OPTIONAL'
        | 'ORDINALITY'
        | 'ORGANIZATION'
        | 'OTHERS'
        | 'PACK_KEYS'
        | 'PAGE'
        | 'PARTIAL'
        | 'PARTITIONING'
        | 'PARTITIONS'
        | 'PASSWORD'
        | 'PATH'
        | 'PHASE'
        | 'PLUGIN_DIR'
        | 'PLUGIN'
        | 'PLUGINS'
        | 'POINT'
        | 'POLYGON'
        | 'PRECEDING'
        | 'PRESERVE'
        | 'PREV'
        | 'THREAD_PRIORITY'
        | 'PRIVILEGES'
        | 'PROCESSLIST'
        | 'PROFILE'
        | 'PROFILES'
        | 'QUARTER'
        | 'QUERY'
        | 'QUICK'
        | 'READ_ONLY'
        | 'REBUILD'
        | 'RECOVER'
        | 'REDO_BUFFER_SIZE'
        | 'REDUNDANT'
        | 'RELAY'
        | 'RELAYLOG'
        | 'RELAY_LOG_FILE'
        | 'RELAY_LOG_POS'
        | 'RELAY_THREAD'
        | 'REMOTE'
        | 'REORGANIZE'
        | 'REPEATABLE'
        | 'REPLICATE_DO_DB'
        | 'REPLICATE_IGNORE_DB'
        | 'REPLICATE_DO_TABLE'
        | 'REPLICATE_IGNORE_TABLE'
        | 'REPLICATE_WILD_DO_TABLE'
        | 'REPLICATE_WILD_IGNORE_TABLE'
        | 'REPLICATE_REWRITE_DB'
        | 'USER_RESOURCES'
        | 'RESPECT'
        | 'RESUME'
        | 'RETAIN'
        | 'RETURNED_SQLSTATE'
        | 'RETURNS'
        | 'REUSE'
        | 'REVERSE'
        | 'ROLLUP'
        | 'ROTATE'
        | 'ROUTINE'
        | 'ROW_COUNT'
        | 'ROW_FORMAT'
        | 'RTREE'
        | 'SCHEDULE'
        | 'SCHEMA_NAME'
        | 'SECOND'
        | 'SERIAL'
        | 'SERIALIZABLE'
        | 'SESSION'
        | 'SHARE'
        | 'SIMPLE'
        | 'SKIP'
        | 'SLOW'
        | 'SNAPSHOT'
        | 'SOUNDS'
        | 'SOURCE'
        | 'SQL_AFTER_GTIDS'
        | 'SQL_AFTER_MTS_GAPS'
        | 'SQL_BEFORE_GTIDS'
        | 'SQL_BUFFER_RESULT'
        | 'SQL_NO_CACHE'
        | 'SQL_THREAD'
        | 'SRID'
        | 'STACKED'
        | 'STARTS'
        | 'STATS_AUTO_RECALC'
        | 'STATS_PERSISTENT'
        | 'STATS_SAMPLE_PAGES'
        | 'STATUS'
        | 'STORAGE'
        | 'STRING'
        | 'SUBCLASS_ORIGIN'
        | 'SUBDATE'
        | 'SUBJECT'
        | 'SUBPARTITION'
        | 'SUBPARTITIONS'
        | 'SUPER'
        | 'SUSPEND'
        | 'SWAPS'
        | 'SWITCHES'
        | 'TABLE_NAME'
        | 'TABLES'
        | 'TABLE_CHECKSUM'
        | 'TABLESPACE'
        | 'TEMPORARY'
        | 'TEMPTABLE'
        | 'TEXT'
        | 'THAN'
        | 'TIES'
        | 'TRANSACTION'
        | 'TRIGGERS'
        | 'TIMESTAMP'
        | 'TIMESTAMPADD'
        | 'TIMESTAMPDIFF'
        | 'TIME'
        | 'TYPES'
        | 'TYPE'
        | 'UDF_RETURNS'
        | 'UNBOUNDED'
        | 'UNCOMMITTED'
        | 'UNDEFINED'
        | 'UNDO_BUFFER_SIZE'
        | 'UNDOFILE'
        | 'UNKNOWN'
        | 'UNTIL'
        | 'USER'
        | 'USE_FRM'
        | 'VARIABLES'
        | 'VCPU'
        | 'VIEW'
        | 'VALUE'
        | 'WARNINGS'
        | 'WAIT'
        | 'WEEK'
        | 'WORK'
        | 'WEIGHT_STRING'
        | 'X509'
        | 'XID'
        | 'XML'
        | 'YEAR'
    )
    // Tokens that entered or left this rule in specific versions and are not automatically
    // handled in the lexer.
    | 'ADMIN'
    ;

//tokens {
//    NOT2_SYMBOL,
//    'CONCAT_PIPES',
//
//    // Tokens assigned in NUMBER rule.
//    INT_NUMBER, // NUM in sql_yacc.yy
//    LONG_NUMBER,
//    ULONGLONG_NUMBER
//}



// The MySQL server parser uses custom code in its lexer to allow base alphanum chars (and ._$) as variable name.
// For this it handles user variables in 2 different ways and we have to model this to match that behavior.

AT_TEXT_SUFFIX
    : '@' SIMPLE_IDENTIFIER
    ;

PARAM_MARKER
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
    : ('0x' HEXDIGIT+)
    | ('x\'' HEXDIGIT+ '\'')
    ;

BIN_NUMBER
    : ('0b' [01]+)
    | ('b\'' [01]+ '\'')
    ;

INT_NUMBER
    : DIGITS
    ;

// Float types must be handled first or the DOT_IDENTIIFER rule will make them to identifiers
// (if there is no leading digit before the dot).
DECIMAL_NUMBER
    : DIGITS? '.' DIGITS
    ;

FLOAT_NUMBER
    : (DIGITS? '.')? DIGITS 'E' ('-' | '+')? DIGITS
    ;

// Special rule that should also match all keywords if they are directly preceded by a dot.
// Hence it's defined before all keywords.
// Here we make use of the ability in our base lexer to emit multiple tokens with a single rule.
DOT_IDENTIFIER
    : '.' LETTER_WHEN_UNQUOTED_NO_DIGIT LETTER_WHEN_UNQUOTED* -> type(IDENTIFIER)
    ;


// White space handling
WHITESPACE
    : [ \t\f\r\n]+ -> channel(HIDDEN)
    ; // Ignore whitespaces.

// Input not covered elsewhere (unless quoted).
INVALID_INPUT
    : [\u0001-\u0008] // Control codes.
    | '\u000B'        // Line tabulation.
    | '\u000C'        // Form feed.
    | [\u000E-\u001F] // More control codes.
    | '['
    | ']'
    ;

// String and text types.

// The underscore charset token is used to defined the repertoire of a string, though it conflicts
// with normal identifiers, which also can start with an underscore.
UNDERSCORE_CHARSET
    : '_' [a-z0-9]+
    ;

// TODO: check in the semantic phase that starting and ending tags are the same.
DOLLAR_QUOTED_STRING_TEXT
   : '$' DOLLAR_QUOTE_TAG_CHAR* '$' .*? '$' DOLLAR_QUOTE_TAG_CHAR* '$' {this.doDollarQuotedStringText()}?;

// Identifiers might start with a digit, even though it is discouraged, and may not consist entirely of digits only.
// All keywords above are automatically excluded.
IDENTIFIER
    : DIGITS+ 'E' (LETTER_WHEN_UNQUOTED_NO_DIGIT LETTER_WHEN_UNQUOTED*)?
    // Have to exclude float pattern, as this rule matches more.
    | DIGITS+ LETTER_WITHOUT_FLOAT_PART LETTER_WHEN_UNQUOTED*
    | LETTER_WHEN_UNQUOTED_NO_DIGIT LETTER_WHEN_UNQUOTED*
    ; // INT_NUMBER matches first if there are only digits.

NCHAR_TEXT
    : 'N' SINGLE_QUOTED_TEXT
    ;

// MySQL supports automatic concatenation of multiple single and double quoted strings if they follow each other as separate
// tokens. This is reflected in the `textLiteral` parser rule.
// Here we handle duplication of quotation chars only (which must be replaced by a single char in the target code).

BACK_TICK_QUOTED_ID
    : '`' (('\\')? .)*? '`'
    ;

DOUBLE_QUOTED_TEXT
    : ( '"' (('\\')? .)*? '"' )+ ;

SINGLE_QUOTED_TEXT
    : ( '\'' (('\\')? .)*? '\'' )+
    ;

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

DASHDASH_COMMENT
    : DOUBLE_DASH ([ \t] (~[\n\r])* | LINEBREAK | EOF) -> channel(HIDDEN)
    ;

fragment DOUBLE_DASH
    : '--'
    ;

fragment LINEBREAK
    : [\n\r]
    ;

fragment SIMPLE_IDENTIFIER
    : (DIGIT | [A-Z_$] | '.')+
    ;

fragment ML_COMMENT_HEAD
    : '/*'
    ;

fragment ML_COMMENT_END
    : '*/'
    ;

// As defined in https://dev.mysql.com/doc/refman/8.0/en/identifiers.html.
fragment LETTER_WHEN_UNQUOTED
    : DIGIT
    | LETTER_WHEN_UNQUOTED_NO_DIGIT
    ;

fragment LETTER_WHEN_UNQUOTED_NO_DIGIT
    : [A-Z_$\u0080-\uffff]
    ;

fragment DOLLAR_QUOTE_TAG_CHAR
    : [0-9A-Z_\u0080-\uffff]
    ;

// Any letter but without e/E and digits (which are used to match a decimal number).
fragment LETTER_WITHOUT_FLOAT_PART
    : [A-DF-Z_$\u0080-\uffff]
    ;
