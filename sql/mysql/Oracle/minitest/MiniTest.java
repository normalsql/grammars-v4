import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.TerminalNodeImpl;

import static java.lang.System.out;

void main() throws Exception
{
    report = new PrintWriter( "/Users/jasonosgood/Projects/fork/grammars-v4/sql/mysql/Oracle/errors.txt" );
    report.println( "##" );

    String source = "/Users/jasonosgood/Projects/ScrapeMySQLTests/logs";
//     source = "./examples";
    var paths = Files.walk( Paths.get( source ) ).filter( Files::isRegularFile );

    for( var p : paths.toList() )
    {
        if( p.getFileName().toString().endsWith( ".sql" ) )
        {
            parse( p );
        }
        if( _errors > 20 ) break;
    }
    report.close();
}

Path fileName;

void parse( Path p ) throws Exception
{
    fileName = p.getFileName();
    out.println( fileName );
    var sql = Files.readString( p );

    var chars = CharStreams.fromString( sql );
    var lexer = new MySQLLexer( chars );
    var tokens = new CommonTokenStream( lexer );
    var parser = new MySQLParser( tokens );
    parser.removeErrorListeners( );
    parser.addErrorListener( new BaseErrorListener() {
        @Override
        public void syntaxError( Recognizer<?, ?> recognizer, Object offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e )
        {
            _errors++;
//            out.println( p.getFileName() );
            report.println( p.getFileName()+ " " + line + ":" + charPositionInLine  );
            report.flush();
            out.println( p.getFileName()+ " " + line + ":" + charPositionInLine  );
//            out.println( "line " + line + ":" + charPositionInLine + " " + msg );
        }
    });



    var ugh = parser.statements();


////    out.println( ugh.toStringTree( parser) );
//    if ( parser.getNumberOfSyntaxErrors() > 0 ) {
//        throw new Exception( "Syntax error" );
//    }
//    if ( parser.getNumberOfSyntaxErrors() == 0 ) {
////        out.println( "OK" );
//    } else {
//        out.println( "Syntax error" );
//        out.println( p.getFileName() );
//    }

    nodes = 0;
    terminals = 0;
    _level = 0;
    dump(  ugh, 0 );
//    out.println( "statements " + ugh.children.size() );
//    out.println( "level " + _level );
//    out.println( "nodes " + nodes );
//    out.println( "terminals " + terminals );
//    out.println( "##" );
}

int nodes = 0;
int terminals = 0;
int _level = 0;

int _errors = 0;

PrintWriter report = null;

void dump( ParseTree parent, int level )
{
    _level = Math.max( _level, level );
    for( int i = 0; i< parent.getChildCount(); i++ )
    {
        ParseTree child = parent.getChild( i );
        switch( child )
        {
            case ParserRuleContext ctx:
                nodes++;
//                out.println( "node " + nodes++ + " " + ctx.getClass().getSimpleName() );
                {
                    dump( child, ++level );
                }
                break;
            case TerminalNodeImpl node:
                terminals++;
//                out.println( "token " + terminals + " " + node.getText() );
                break;
            default:

        }

    }
}
