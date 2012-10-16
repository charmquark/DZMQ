/*
    0MQ wrapper in the D Programming Language
    by Christopher Nicholson-Sauls (2012).
*/

module dzmq.zmq;

import  std.string  ;
import  zmq.zmq     ;


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


    int code;


    /*******************************************************************************************
     *
     */
    this ( int a_code, string msg, string file = null, size_t line = 0 ) {
        code = a_code;
        super( msg, file, line );
    }

    ///ditto
    this ( string msg, string file = null, size_t line = 0 ) {
        this( zmq_errno(), msg, file, line );
    }


} // end ZMQException


/***************************************************************************************************
 *
 */
final class ZMQContext {


    /*******************************************************************************************
     *
     */
    this ( int a_ioThreads = ZMQ_IO_THREADS_DFLT ) {
        handle = zmq_ctx_new();
        if ( handle is null ) {
            throw new ZMQException( "Failed to create context" );
        }
        if ( a_ioThreads != ZMQ_IO_THREADS_DFLT ) {
            ioThreads = a_ioThreads;
        }
    }


    /*******************************************************************************************
     *
     */
    ~this () {
        if ( handle is null ) {
            return;
        }
        auto rc = zmq_ctx_destroy( handle );
        if ( rc != 0 ) {
            throw new ZMQException( "Failed to destroy context" );
        }
    }


    /*******************************************************************************************
     *
     */
    @property
    int ioThreads () {
        return zmq_ctx_get( handle, ZMQ_IO_THREADS );
    }
    
    ///ditto
    @property
    int ioThreads ( int val )
    in {
        assert( val > 0, "It is useless to have zero (or negative!?) io threads" );
    }
    body {
        return zmq_ctx_set( handle, ZMQ_IO_THREADS, val );
    }


    /*******************************************************************************************
     *
     */
    @property
    int maxSockets () {
        return zmq_ctx_get( handle, ZMQ_MAX_SOCKETS );
    }
    
    ///ditto
    @property
    int maxSockets ( int val )
    in {
        assert( val > 0, "It is useless to have a context with zero (or negative!?) max sockets" );
    }
    body {
        return zmq_ctx_set( handle, ZMQ_MAX_SOCKETS, val );
    }


    /*******************************************************************************************
     *
     */
    ZMQPoller poller ( int size = ZMQPoller.DEFAULT_SIZE ) {
        return new Poller( this, size );
    }


    /*******************************************************************************************
     *
     */
    ZMQSocket socket ( ZMQSocket.Type type ) {
        return new ZMQSocket( handle, type );
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


    void* handle;


} // end ZMQContext


/***************************************************************************************************
 *
 */
final class ZMQSocket {


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
    private this ( void* contextHandle, Type a_type ) {
        handle = zmq_socket( contextHandle, a_type );
        if ( handle is null ) {
            throw new ZMQException( "Failed to create socket" );
        }
    }


    /*******************************************************************************************
     *
     */
    ~this () {
        if ( handle !is null ) {
            auto rc = zmq_close( handle );
            if ( rc != 0 ) {
                throw new ZMQException( "Failed to close socket" );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////////////////////
    private:
    ////////////////////////////////////////////////////////////////////////////////////////////


    void* handle;


} // end ZMQSocket


/***************************************************************************************************
 *
 */
final class ZMQPoller {


    /*******************************************************************************************
     *
     */
    enum DEFAULT_SIZE = 32;


    /*******************************************************************************************
     *
     */
    private this ( ZMQContext a_context, int a_size = DEFAULT_SIZE ) {
        context = a_context;
        size    = a_size;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////
    private:
    ////////////////////////////////////////////////////////////////////////////////////////////


    ZMQContext  context ;
    int         size    ;


} // end ZMQPoller
