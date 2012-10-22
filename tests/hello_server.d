module hello_server;

import  core.thread ,
        core.time   ;
import  dzmq.zmq    ;
import  std.stdio   ;


void main () {
    try {
        auto context    = new ZMQContext        ;
        auto responder  = context.repSocket()   ;
        
        responder.bind( "tcp://*:5555" );
        
        while ( true ) {
            auto request = responder.receive!string();
            writefln( "Received request: [%s]", request );
            
            if ( request.length == 0 ) {
                responder.send( "" );
                break;
            }
            
            Thread.sleep( dur!`seconds`( 1 ) );
            responder.send( "World" );
        }
        
        destroy( responder );
    }
    catch ( Throwable x ) {
        while ( x !is null ) {
            writeln( x );
            x = x.next;
        }
    }
}
