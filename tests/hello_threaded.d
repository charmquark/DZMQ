module hello_threaded;

import  core.thread     ,
        core.time       ;
import  dzmq.zmq        ;
import  std.concurrency ,
        std.stdio       ;


enum ADDR = "inproc://hello";


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

    auto foo = responder.receive!( int[3] )();
    writeln( "[server] Received static array ", typeof( foo ).stringof, " ", foo );
    
    double bar = 3.14;
    writeln( "[server] Sending scalar ", typeof( bar ).stringof, " ", bar );
    responder.send( bar );
    
    writeln( "[server] Stopping" );
    parent.send( thisTid );
}


void client ( Tid parent, ZMQContext context, string addr ) {
    auto requester = context.requesterSocket();
    scope( exit ) destroy( requester );
    
    requester.connect( addr );

    foreach ( nbr ; 0 .. 3 ) {
        writefln( "[client] Sending request %d", nbr );
        requester.send( "Hello" );
        
        auto reply = requester.receive();
        writefln( "[client] Received reply %d: [%s]", nbr, reply );
    }
    
    requester.send( "" );
    assert( requester.receive() == "" );

    int[3] foo = [ 1, 2, 3 ];
    writeln( "[client] Sending static array ", typeof( foo ).stringof, " ", foo );
    requester.send( foo );
    
    auto bar = requester.receive!double();
    writeln( "[client] Received scalar ", typeof( bar ).stringof, " ", bar );
    
    writeln( "[client] Stopping" );
    parent.send( thisTid );
}

