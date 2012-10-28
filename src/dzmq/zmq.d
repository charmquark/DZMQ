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
        std.concurrency ,
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
        ownerTid = cast( shared ) thisTid;
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
    bool isOwnerThread () {
        return cast( shared ) thisTid == ownerTid;
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


    void*       handle      ;
    Tid         ownerTid    ;
    ZMQSocket[] sockets     ;


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
            throw new ZMQException( -1, "Tried to open an already opened socket instance" );
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

    T receive ( T = string ) ( int flags = 0 ) {
        enforceHandle( "Tried to receive on a closed socket" );
        
        static if ( is( T == struct ) ) {
            return dataTo!T( doReceiveParts( flags ) );
        }
        
        else {
            return dataTo!T( doReceive( flags ) );
        }
    }


    /*******************************************************************************************
     *
     */

    T receiveTyped ( T = string ) ( int flags = 0 ) {
        enforceHandle( "Tried to receive on a closed socket" );
        auto data = doReceiveParts( flags );
        auto name = to!string( data[ 0 ] );
        if ( name != T.stringof ) {
            throw new ZMQException( -1, text(
                "Received wrongly typed data; ",
                name, " for ", T.stringof
            ) );
        }
        
        static if ( is( T == struct ) ) {
            return dataTo!T( data[ 1 .. $ ] );
        }
        
        else {
            return dataTo!T( data[ 1 ] );
        }
    }


    /*******************************************************************************************
     *
     */

    void send ( T ) ( T input, int flags = 0 ) {
        enforceHandle( "Tried to send on a closed socket" );
        
        static if ( is( T == struct ) ) {
            doSendParts( itemToData( input ) );
        }
        
        else {
            doSend( itemToData( input ), flags );
        }
    }


    /*******************************************************************************************
     *
     */

    void sendTyped ( T ) ( T input, int flags = 0 ) {
        enforceHandle( "Tried to send on a closed socket" );
        
        doSend( cast( void[] ) T.stringof, flags | ZMQ_SNDMORE );
        send( input, flags );
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
    
    void[] doReceive ( int flags = 0 ) {
        auto msg = openMsg();
        scope( exit ) msg.close();
        
    L_top:
        auto rc = zmq_msg_recv( &msg, chandle, flags );
        if ( rc < 0 ) {
            auto err = zmq_errno();
            if ( err == EAGAIN ) {
                goto L_top;
            }
            else {
                throw new ZMQException( err, "Failed to receive message" );
            }
        }
        return msg.data();
    }


    /*******************************************************************************************
     *
     */
    
    void[][] doReceiveParts ( int flags = 0 ) {
        void[][] result;
        bool more = true;
        while ( more ) {
            auto msg = openMsg();
        
        L_top:
            auto rc = zmq_msg_recv( &msg, chandle, flags );
            if ( rc < 0 ) {
                auto err = zmq_errno();
                if ( err == EAGAIN ) {
                    goto L_top;
                }
                else {
                    throw new ZMQException( err, "Failed to receive message" );
                }
            }
            result ~= msg.data();
            more = zmq_msg_more( &msg ) == 1;
            msg.close();
        }
        return result;
    }

    
    /*******************************************************************************************
     *
     */
    
    void doSend ( void[] data, int flags = 0 ) {
        auto msg = openMsg( data );
        scope( exit ) msg.close();
        
        auto rc = zmq_msg_send( &msg, chandle, flags );
        if ( rc < 0 ) {
            throw new ZMQException( "Failed to send" );
        }
    }

    
    /*******************************************************************************************
     *
     */

    void doSendParts ( void[][] data, int flags = 0 ) {
        foreach ( part ; data[ 0 .. $ -1 ] ) {
            doSend( part, flags | ZMQ_SNDMORE );
        }
        doSend( data[ $ - 1 ], flags );
    }
    

    /*******************************************************************************************
     *
     */
    
    void enforceHandle ( lazy string msg ) {
        if ( handle is null ) {
            throw new ZMQException( -1, msg() );
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

void close ( ref zmq_msg_t msg ) {
    zmq_msg_close( &msg ) .enforce0( "Failed to close message" );
}


/***************************************************************************************************
 *
 */

void[] data ( ref zmq_msg_t msg ) {
    return zmq_msg_data( &msg )[ 0 .. zmq_msg_size( &msg ) ].dup;
}


/***************************************************************************************************
 *
 */

T dataTo ( T ) ( void[] data )

if ( !is( T == struct ) )

body {
    static if ( isDynamicArray!T ) {
        alias ElementType!T E;
        
        static if ( isScalarType!E ) {
            return cast( T ) data;
        }
        else {
            static assert( false, "Transport of type " ~ T.stringof ~ " not yet supported." );
        }
    }
    
    else static if ( isStaticArray!T ) {
        alias ElementType!T E;
        
        static if ( isScalarType!E ) {
            if ( data.length != ( T.length * E.sizeof ) ) {
                throw new ZMQException( -1, text( 
                    "Data received is the wrong length; ", 
                    data.length, " for ", T.stringof
                ) );
            }
            T result;
            result[] = cast( E[] ) data;
            return result;
        }
    }
    
    else static if ( isScalarType!T ) {
        if ( data.length != T.sizeof ) {
            throw new ZMQException( -1, text(
                "Data received is the wrong length; ",
                data.length, " for ", T.stringof
            ) );
        }
        return *( cast( T* ) data.ptr );
    }
    
    else {
        static assert( false, "ZMQSocket doesn't know how to receive type " ~ T.stringof );
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/// ditto

T dataTo ( T ) ( void[][] data )

if ( is( T == struct ) )

body {
    T result;
    auto tmp = result.tupleof;
    if ( data.length != tmp.length ) {
        throw new ZMQException( -1, text( 
            "Data received is the wrong length; ", 
            data.length, " for ", T.stringof
        ) );
    }
    foreach ( idx, ref elem ; tmp ) {
        elem = dataTo!( typeof( elem ) )( data[ idx ] );
    }
    result = T( tmp );
    return result;
}


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


/***************************************************************************************************
 *
 */

void[] itemToData ( T ) ( T item )

if ( !is( T == struct ) )

body {
    static if ( isArray!T ) {
        alias ElementType!T E;
        
        static if ( isScalarType!E ) {
            return cast( void[] ) item.dup;
        }
        else {
            static assert( false, "Transport of type " ~ T.stringof ~ " not yet supported." );
        }
    }
    
    else static if ( isScalarType!T ) {
        return itemToData( [ item ] );
    }
    
    else {
        return itemToData( to!string( item ) );
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/// ditto

void[][] itemToData ( T ) ( T item )

if ( is( T == struct ) )

body {
    void[][] result;
    foreach ( field ; item.tupleof ) {
        result ~= itemToData( field );
    }
    return result;
}

/***************************************************************************************************
 *
 */

zmq_msg_t openMsg () {
    zmq_msg_t msg;
    zmq_msg_init( &msg ) .enforce0( "Failed to initialize message" );
    return msg;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/// ditto

zmq_msg_t openMsg ( void[] data ) {
    zmq_msg_t msg;
    zmq_msg_init_data( &msg, data.ptr, data.length, null, null )
        .enforce0( "Failed to initialize message" );
    return msg;
}

