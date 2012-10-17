module hello_server;

import  core.thread ,
        core.time   ;
import  dzmq.zmq    ;
import  std.stdio   ;


void main () {
    auto context    = new ZMQContext        ;
    auto responder  = context.repSocket()   ;
    
    responder.bind( "tcp://*:5555" );
    
    while ( true ) {
        auto request = responder.receive!string();
        writefln( "Received request: [%s]", request );
        
        Thread.sleep( dur!`seconds`( 1 ) );
        
        responder.send( "World" );
    }
}

