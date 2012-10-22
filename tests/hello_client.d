module hello_client;

import  dzmq.zmq    ;
import  std.stdio   ;


void main () {
    try {
        auto context = new ZMQContext;
        
        writeln( "Connecting to hello world server..." );
        auto requester = context.reqSocket();
        requester.connect( "tcp://localhost:5555" );
        
        foreach ( nbr ; 0 .. 3 ) {
            writefln( "Sending request %d...", nbr );
            requester.send( "Hello" );
            
            auto reply = requester.receive!string();
            writefln( "Received reply %d: [%s]", nbr, reply );
        }
        
        writeln( "Sending empty ('quit') request." );
        requester.send( "" );
        auto reply = requester.receive!string();
        writefln( "Received reply: [%s]", reply );
        destroy( requester );
    }
    catch ( Throwable x ) {
        if ( auto zx = cast( ZMQException ) x ) {
            stderr.writeln( "zmq_errno = ", zx.code );
        }
        while ( x !is null ) {
            writeln( x );
            x = x.next;
        }
    }
}
