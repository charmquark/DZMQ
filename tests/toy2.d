module toy2;

version( DZMQ_UTILS ) {
    
    import  dzmq.utils  ,
            dzmq.zmq    ;
    import  std.stdio   ;

    void main () {
        ZMQStopwatch watch;
        
        writeln( "0MQ version ", ZMQVersion.String );
        
        writeln( "Creating context." );
        watch.start();
        auto context = new ZMQContext;
        writefln( "0MQ context: %016X", cast( void* ) context );
        writeln( " ... io threads: ", context.ioThreads );
        writeln( " ... max sockets: ", context.maxSockets );

        writeln( "Setting io threads to 2." );
        context.ioThreads = 2;
        writeln( " ... io threads: ", context.ioThreads );

        writeln( "Destroying context." );
        delete context;
        writefln( "0MQ context: %016X", cast( void* ) context );
        watch.stop();
        writefln( "Execution time: %s", watch.time );
    }

}
else {
    
    import  dzmq.zmq    ;
    import  std.stdio   ;
    import  zmq.utils   ;

    void main () {
        writeln( "0MQ version ", ZMQVersion.String );
        
        writeln( "Creating context." );
        auto watch = zmq_stopwatch_start();
        auto context = new ZMQContext;
        writefln( "0MQ context: %016X", cast( void* ) context );
        writeln( " ... io threads: ", context.ioThreads );
        writeln( " ... max sockets: ", context.maxSockets );

        writeln( "Setting io threads to 2." );
        context.ioThreads = 2;
        writeln( " ... io threads: ", context.ioThreads );

        writeln( "Destroying context." );
        delete context;
        writefln( "0MQ context: %016X", cast( void* ) context );
        auto usecs = zmq_stopwatch_stop( watch );
        writefln( "Execution time: %s usecs", usecs );
    }

}