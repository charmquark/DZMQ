module transport_struct;

import  dzmq.zmq    ;
import  std.stdio   ;


struct S {
    int i;
    float f;
    string s;
}


void main () {
    auto context = new ZMQContext;
    scope( exit ) destroy( context );
    
    auto rep = context.repSocket();
    scope( exit ) destroy( rep );
    rep.bind( "inproc://transport_struct" );
    
    auto req = context.reqSocket();
    scope( exit ) destroy( req );
    req.connect( "inproc://transport_struct" );
    
    S s1 = S( 42, 3.14, "foo" );
    writeln( "Sending ", s1 );
    req.send( s1 );
    
    S s2 = rep.receive!S();
    writeln( "Received ", s2 );
    
    s2 = S( 1, 2.3, "bar" );
    writeln( "Sending ", s2 );
    rep.send( s2 );
    
    s1 = req.receive!S();
    writeln( "Received ", s1 );
}