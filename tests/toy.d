module toy;

import  std.stdio       ;
import  dzmq.c.utils    ,
        dzmq.c.zmq      ;

void main () {
    writefln( "0MQ version %s.%s.%s", ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH );
    
    writeln( "Creating context." );
    auto watch = zmq_stopwatch_start();
    auto context = zmq_ctx_new();
    writefln( "0MQ context %X", context );
    writeln( " ... io threads: ", zmq_ctx_get( context, ZMQ_IO_THREADS ) );
    writeln( " ... max sockets: ", zmq_ctx_get( context, ZMQ_MAX_SOCKETS ) );
    
    writeln( "Setting io threads to 2." );
    zmq_ctx_set( context, ZMQ_IO_THREADS, 2 );
    writeln( " ... io threads: ", zmq_ctx_get( context, ZMQ_IO_THREADS ) );
    
    writeln( "Destroying context." );
    zmq_ctx_destroy( context );
    writefln( "0MQ context %08X", context );
    auto time = zmq_stopwatch_stop( watch );
    writeln( "Execution time: ", time );
}
