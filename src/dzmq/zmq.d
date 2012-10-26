/*
    0MQ wrapper in the D Programming Language
    by Christopher Nicholson-Sauls (2012).
*/

/***************************************************************************************************
 *
 */

module dzmq.zmq;

import  std.algorithm   ,
        std.array       ,
        std.conv        ,
        std.range       ,
        std.string      ,
        std.traits      ;
import  dzmq.c.zmq      ;


/***************************************************************************************************
 *
 */

struct ZMQVersion { static:
    enum    Major   = ZMQ_VERSION_MAJOR ,
            Minor   = ZMQ_VERSION_MINOR ,
            Patch   = ZMQ_VERSION_PATCH ;

    enum    String  = xformat( "%d.%d.%d", Major, Minor, Patch );
}


/***************************************************************************************************
 *
 */

class ZMQException : Exception {


    /*******************************************************************************************
     *
     */
    int code;


    /*******************************************************************************************
     *
     */
    this ( int a_code, string msg, string file = null, size_t line = 0, Throwable next = null ) {
        code = a_code;
        super( to!string( zmq_strerror( code ) ) ~ " -- " ~ msg, file, line, next );
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    this ( string msg, string file = null, size_t line = 0, Throwable next = null ) {
        this( zmq_errno(), msg, file, line, next );
    }


} // end ZMQException


/***************************************************************************************************
 *
 */

final shared class ZMQContextImpl {


    /*******************************************************************************************
     *
     */
    
    this ( int a_ioThreads = ZMQ_IO_THREADS_DFLT ) {
        handle = cast( shared ) zmq_ctx_new();
        if ( handle is null ) {
            throw new ZMQException( "Failed to create context" );
        }
        ioThreads = a_ioThreads;
    }


    /*******************************************************************************************
     *
     */
    
    ~this () {
        if ( handle !is null ) {
            while ( sockets.length ) {
                destroy( sockets[ 0 ] );
            }
            zmq_ctx_destroy( chandle ) 
                .enforce0( "Failed to destroy context" );
            handle = null;
        }
    }


    /*******************************************************************************************
     *
     */
    
    @property
    int ioThreads () {
        return zmq_ctx_get( chandle, ZMQ_IO_THREADS );
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    @property
    int ioThreads ( int val )
    
    in {
        assert( val >= 0, "It is meaningless to have a negative number of io threads" );
    }
    
    body {
        return zmq_ctx_set( chandle, ZMQ_IO_THREADS, val );
    }


    /*******************************************************************************************
     *
     */
    
    @property
    int maxSockets () {
        return zmq_ctx_get( chandle, ZMQ_MAX_SOCKETS );
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    @property
    int maxSockets ( int val )
    
    in {
        assert( val > 0, "It is useless to have a context with zero (or negative!?) max sockets" );
    }
    
    body {
        return zmq_ctx_set( chandle, ZMQ_MAX_SOCKETS, val );
    }


    /*******************************************************************************************
     *
     */
    
    ZMQPoller poller ( int size = ZMQPoller.DEFAULT_SIZE ) {
        return new ZMQPoller( this, size );
    }


    /*******************************************************************************************
     *
     */
    
    ZMQSocket socket ( ZMQSocket.Type type )
    
    out ( result ) {
        assert( result !is null );
        assert( sockets[ $ - 1 ] is result );
    }
    
    body {
        return new ZMQSocket( this, type );
    }


    /*******************************************************************************************
     *
     */
    
    ZMQSocket opDispatch ( string Sym ) ()
    
    if ( Sym.length > 6 && Sym[ $ - 6 .. $ ] == "Socket" )
    
    body {
        return socket( mixin( `ZMQSocket.Type.` ~ Sym[ 0 .. $ - 6 ].capitalize() ) );
    }


    ////////////////////////////////////////////////////////////////////////////////////////////
    private:
    ////////////////////////////////////////////////////////////////////////////////////////////


    void*       handle  ;
    ZMQSocket[] sockets ;


    /*******************************************************************************************
     *
     */
    
    @property
    void* chandle () {
        return cast( void* ) handle;
    }


    /*******************************************************************************************
     *
     */
    
    void add ( ZMQSocket sock )
    
    out {
        assert( sockets.length );
        assert( sockets[ $ - 1 ] == sock );
    }
    
    body {
        sockets ~= sock;
    }


    /*******************************************************************************************
     *
     */
    
    void remove ( ZMQSocket sock ) {
        if ( sockets.length ) {
            auto idx = sockets.countUntil( sock );
            if ( idx >= 0 ) {
                sockets = sockets.remove( idx );
            }
        }
    }


} // end ZMQContext

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/// ditto

alias shared( ZMQContextImpl ) ZMQContext;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

unittest {
    ZMQContext  context ;
    ZMQPoller   poll    ;
    ZMQSocket   sock    ;
    int         i       ;
    
    context = new ZMQContext;
    scope( exit ) destroy( ctx );
    
    // property ioThreads
    assert( context.ioThreads == ZMQ_IO_THREADS_DFLT );
    i = ZMQ_IO_THREADS_DFLT * 2;
    context.ioThreads = i;
    assert( context.ioThreads == i );
    
    // property maxSockets
    assert( context.maxSockets == ZMQ_MAX_SOCKETS_DFLT );
    i = ZMQ_MAX_SOCKETS_DFLT * 2;
    context.maxSockets = i;
    assert( context.maxSockets == i );
    
    // method poller( ?size )
    poll = context.poller();
    assert( poll !is null );
    destroy( poll );
    
    // method socket( type )
    sock = context.socket( ZMQSocket.Type.Pub );
    assert( sock !is null );
    destroy( sock );

    // dynamic method <type>Socket()
    sock = context.pushSocket();
    assert( sock !is null );
    assert( sock.type == ZMQSocket.Type.Push );
    destroy( sock );
}


/***************************************************************************************************
 *
 */
final shared class ZMQSocketImpl {


    /*******************************************************************************************
     *
     */
    
    static enum Type {
        Pair    = ZMQ_PAIR,
        Pub     ,
        Sub     ,
        Req     ,
        Rep     ,
        Dealer  ,
        Router  ,
        Pull    ,
        Push    ,
        XPub    ,
        XSub    ,

        Publisher   = Pub   ,
        Subscriber  = Sub   ,
        Requester   = Req   ,
        Replier     = Rep
    }


    /*******************************************************************************************
     *
     */
    
    this ( ZMQContext a_context, Type a_type ) {
        open( a_context, a_type );
    }


    /*******************************************************************************************
     *
     */
    
    ~this () {
        close();
    }


    /*******************************************************************************************
     *
     */
    
    @property
    Type type () {
        enforceHandle( "Tried to get type of a closed socket" );
        int optval;
        size_t sz = optval.sizeof;
        zmq_getsockopt( chandle, ZMQ_TYPE, &optval, &sz )
            .enforce0( "Failed to get socket option value for ZMQ_TYPE" );
        return cast( Type ) optval;
    }


    /*******************************************************************************************
     *
     */
    
    void bind ( string addr ) {
        enforceHandle( "Tried to bind a closed socket" );
        zmq_bind( chandle, toStringz( addr ) )
            .enforce0( "Failed to bind socket to " ~ addr );
        bindings ~= addr;
    }


    /*******************************************************************************************
     *
     */
    
    void close () {
        if ( handle !is null ) {
            //unbindAll();
            //disconnectAll();
            zmq_close( chandle )
                .enforce0( "Failed to close socket" );
            handle = null;
        }
        if ( context !is null ) {
            context.remove( this );
            context = null;
        }
    }


    /*******************************************************************************************
     *
     */
    
    void connect ( string addr ) {
        enforceHandle( "Tried to connect a closed socket" );
        zmq_connect( chandle, toStringz( addr ) )
            .enforce0( "Failed to connect socket to " ~ addr );
        connections ~= addr;
    }


    /*******************************************************************************************
     *
     */
    
    void disconnect ( string addr ) {
        enforceHandle( "Tried to disconnect a closed socket" );
        if ( connections.length ) {
            auto idx = connections.countUntil( addr );
            if ( idx >= 0 ) {
                auto addrz  = toStringz( addr );
                int  err    ;
                int  rc     ;
                do {
                    rc = zmq_disconnect( chandle, addrz );
                    if ( rc != 0 ) {
                        err = zmq_errno();
                    }
                } while ( err == EAGAIN );
                enforce0( rc, err, "Failed to disconnect socket from " ~ addr );
                connections = connections.remove( idx );
            }
        }
    }


    /*******************************************************************************************
     *
     */
    
    void disconnectAll () {
        while ( connections.length ) {
            disconnect( connections[ 0 ] );
        }
    }


    /*******************************************************************************************
     *
     */
    
    void open ( ZMQContext a_context, Type a_type ) {
        if ( handle !is null ) {
            throw new ZMQException( 0, "Tried to open an already opened socket instance" );
        }
        context = a_context;
        handle = cast( shared ) zmq_socket( context.chandle, a_type );
        if ( handle is null ) {
            throw new ZMQException( "Failed to create socket" );
        }
        context.add( this );
    }


    /*******************************************************************************************
     *
     */
    
    T receive ( T ) ( int flags = 0 )
    
    if ( isDynamicArray!T )
    
    body {
        return cast( T ) _receive( flags );
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    T receive ( T ) ( int flags = 0 )
    
    if ( isStaticArray!T )
    
    body {
        alias ElementType!T E;
        
        T result;
        auto data = _receive( flags );
        if ( data.length != ( result.length * E.sizeof ) ) {
            throw new ZMQException( 0, "Data received is the wrong length for " ~ T.stringof );
        }
        result[] = cast( E[] ) data;
        return result;
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    T receive ( T ) ( int flags = 0 )
    
    if ( isScalarType!T )
    
    body {
        auto data = _receive( flags );
        if ( data.length != T.sizeof ) {
            throw new ZMQException( 0, "Data received is the wrong length for " ~ T.stringof );
        }
        return *( cast( T* ) data.ptr );
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    string receive () ( int flags = 0 ) {
        return receive!string( flags );
    }


    /*******************************************************************************************
     *
     */
    
    void send ( R ) ( R input, int flags = 0 )
    
    if ( isInputRange!R )
    
    body {
        enforceHandle( "Tried to send on a closed socket" );
        static if ( isForwardRange!R ) {
            input = input.save;
        }
        _send( cast( void[] ) input.array(), flags );
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    void send ( T ) ( T input, int flags = 0 )
    
    if ( isScalarType!T )
    
    body {
        _send( [ input ], flags );
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ///ditto
    
    void send ( T ) ( T input, int flags = 0 )
    
    if ( !isInputRange!T && !isScalarType!T )
    
    body {
        _send( to!string( input ), flags );
    }


    /*******************************************************************************************
     *
     */
    
    void unbind ( string addr ) {
        enforceHandle( "Tried to unbind a closed socket" );
        if ( bindings.length ) {
            auto idx = bindings.countUntil( addr );
            if ( idx >= 0 ) {
                auto addrz  = toStringz( addr );
                int  err    ;
                int  rc     ;
                do {
                    rc = zmq_unbind( chandle, addrz );
                    if ( rc != 0 ) {
                        err = zmq_errno();
                    }
                } while ( err == EAGAIN );
                enforce0( rc, err, "Failed to unbind socket from " ~ addr );
                bindings = bindings.remove( idx );
            }
        }
    }


    /*******************************************************************************************
     *
     */
    
    void unbindAll () {
        while ( bindings.length ) {
            unbind( bindings[ 0 ] );
        }
    }


    /*******************************************************************************************
     *
     */
    
    void opDispatch ( string Sym ) ( ZMQContext a_context )
    
    if ( Sym.length > 4 && Sym[ 0 .. 4 ] == "open" )
    
    body {
        open( a_context, mixin( `Type.` ~ Sym[ 4 .. $ ] ) );
    }


    ////////////////////////////////////////////////////////////////////////////////////////////
    private:
    ////////////////////////////////////////////////////////////////////////////////////////////


    string[]    bindings    ;
    string[]    connections ;
    ZMQContext  context     ;
    void*       handle      ;


    /*******************************************************************************************
     *
     */
    
    @property
    void* chandle () {
        return cast( void* ) handle;
    }


    /*******************************************************************************************
     *
     */
    
    void[] _receive ( int flags = 0 ) {
        enforceHandle( "Tried to receive on a closed socket" );
        zmq_msg_t msg;
        zmq_msg_init( &msg ) .enforce0( "Failed to initialize message" );
        scope( exit ) zmq_msg_close( &msg ) .enforce0( "Failed to close message" );
        
        bool more = true;
        void[] result;
        while ( more ) {
            auto rc = zmq_msg_recv( &msg, chandle, flags );
            if ( rc < 0 ) {
                auto err = zmq_errno();
                if ( err == EAGAIN ) {
                    continue;
                }
                else {
                    throw new ZMQException( err, "Failed to receive message" );
                }
            }
            result ~= zmq_msg_data( &msg )[ 0 .. zmq_msg_size( &msg ) ]; 
            more = zmq_msg_more( &msg ) == 1;
        }
        return result;
    }

    
    /*******************************************************************************************
     *
     */
    
    void _send ( void[] data, int flags = 0 ) {
        enforceHandle( "Tried to send on a closed socket" );
        auto rc = zmq_send( chandle, data.ptr, data.length, flags );
        if ( rc < 0 ) {
            throw new ZMQException( "Failed to send" );
        }
    }


    /*******************************************************************************************
     *
     */
    
    void enforceHandle ( lazy string msg ) {
        if ( handle is null ) {
            throw new ZMQException( 0, msg() );
        }
    }


} // end ZMQSocket

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
///ditto

alias shared( ZMQSocketImpl ) ZMQSocket;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

unittest {
    ZMQContext  context ;
    
    context = new ZMQContext;
    scope( exit ) destroy( context );
}


/***************************************************************************************************
 *
 */

 final shared class ZMQPollerImpl {


    /*******************************************************************************************
     *
     */
    
    enum DEFAULT_SIZE = 32;


    /*******************************************************************************************
     *
     */
    
    this ( ZMQContext a_context, int a_size = DEFAULT_SIZE ) {
        context = a_context;
        size    = a_size;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////
    private:
    ////////////////////////////////////////////////////////////////////////////////////////////


    ZMQContext  context ;
    int         size    ;


} // end ZMQPoller

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
///ditto

alias shared( ZMQPollerImpl ) ZMQPoller;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

unittest {
    ZMQContext  context ;
    
    context = new ZMQContext;
    scope( exit ) destroy( context );
}


////////////////////////////////////////////////////////////////////////////////////////////////////
private:
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *
 */

void enforce0 ( int expr, lazy string errMsg, size_t line = __LINE__ ) {
    if ( expr != 0 ) {
        throw new ZMQException( errMsg(), __FILE__, line );
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/// ditto

void enforce0 ( int expr, int err, lazy string errMsg, size_t line = __LINE__ ) {
    if ( expr != 0 ) {
        throw new ZMQException( err, errMsg(), __FILE__, line );
    }
}
