module hello_threaded;

import  core.thread     ,
        core.time       ;
import  dzmq.zmq        ;
import  std.concurrency ,
        std.stdio       ;


enum ADDR = "ipc://hello";


void main () {
    auto context = new ZMQContext;
    scope( exit ) destroy( context );
    
    auto serverTid = spawn( &server, thisTid, context, ADDR );
    int ready = receiveOnly!int();
    assert( ready == 1 );
    
    auto clientTid = spawn( &client, thisTid, context, ADDR );
    
    // let the other threads do their thing
    receiveOnly!Tid();
    receiveOnly!Tid();
}


void server ( Tid parent, ZMQContext context, string addr ) {
    scope( exit ) parent.send( thisTid );
    
    auto responder = context.replierSocket();
    scope( exit ) destroy( responder );
    
    responder.bind( addr );
    
    // report readiness
    parent.send( 1 );

    while ( true ) {
        auto request = responder.receive();
        writefln( "[server] Received request: [%s]", request );
        
        if ( request.length == 0 ) {
            responder.send( "" );
            break;
        }
        
        Thread.sleep( dur!`seconds`( 1 ) );
        responder.send( "World" );
    }
    writeln( "[server] Stopping" );
}


void client ( Tid parent, ZMQContext context, string addr ) {
    scope( exit ) parent.send( thisTid );
    
    auto requester = context.requesterSocket();
    scope( exit ) destroy( requester );
    
    requester.connect( addr );

    foreach ( nbr ; 0 .. 3 ) {
        writefln( "[client] Sending request %d", nbr );
        requester.send( "Hello" );
        
        auto reply = requester.receive();
        writefln( "[client] Received reply %d: [%s]", nbr, reply );
    }
    
    writeln( "[client] Stopping" );
    requester.send( "" );
    assert( requester.receive() == "" );
}

