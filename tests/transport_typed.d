module transport_typed;

import  dzmq.zmq    ;
import  std.stdio   ;


enum string TEST_STRING = "hello world";
enum int    TEST_INT    = 42;
enum float  TEST_FLOAT  = 3.1459;

struct S {
    int i;
    string s;
}


void main () {
    auto context = new ZMQContext;
    scope( exit ) destroy( context );
    
    auto a = context.pairSocket();
    scope( exit ) destroy( a );
    a.bind( "inproc://transport_struct" );
    
    auto b = context.pairSocket();
    scope( exit ) destroy( b );
    b.connect( "inproc://transport_struct" );
    
    writefln( "Sending string [%s]", TEST_STRING );
    a.sendTyped( TEST_STRING );
    auto s = b.receiveTyped!string();
    writefln( "Received string [%s]", s );
    
    writefln( "Sending int [%s]", TEST_INT );
    a.sendTyped( TEST_INT );
    auto i = b.receiveTyped!int();
    writefln( "Received int [%s]", i );
    
    writefln( "Sending float [%s]", TEST_FLOAT );
    a.sendTyped( TEST_FLOAT );
    auto f = b.receiveTyped!float();
    writefln( "Received float [%s]", f );
    
    writefln( "Sending string [%s]", TEST_STRING );
    a.sendTyped( TEST_STRING );
    writeln( "Wrongly trying to receive an int..." );
    try {
        auto x = b.receiveTyped!int();
        writefln( "** ERROR ** Received int [%s]", x );
    }
    catch ( ZMQException zmqx ) {
        writeln( "Correctly threw an exception: ", zmqx.msg );
    }

    S s1 = S( TEST_INT, TEST_STRING );
    writeln( "Sending struct ", s1 );
    a.sendTyped( s1 );
    auto s2 = b.receiveTyped!S();
    writeln( "Received struct ", s2 );
}