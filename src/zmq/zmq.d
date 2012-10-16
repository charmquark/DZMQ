/*
    0MQ header translated into the D Programming Language 2.x
    by Christopher Nicholson-Sauls (2012).
*/

/*
    Copyright (c) 2007-2012 iMatix Corporation
    Copyright (c) 2009-2011 250bpm s.r.o.
    Copyright (c) 2011 VMware, Inc.
    Copyright (c) 2007-2011 Other contributors as noted in the AUTHORS file

    This file is part of 0MQ.

    0MQ is free software; you can redistribute it and/or modify it under
    the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    0MQ is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

module zmq.zmq;

pragma( lib, "zmq" );

extern( C ):

/+
#if !defined WINCE
#include <errno.h>
#endif
+/
public import core.stdc.errno;

/+
#include <stddef.h>
#include <stdio.h>
#if defined _WIN32
#include <winsock2.h>
#endif
+/
version( Windows ) {
    import std.c.windows.winsock;
}

/+
/*  Handle DSO symbol visibility                                             */
#if defined _WIN32
#   if defined DLL_EXPORT
#       define ZMQ_EXPORT __declspec(dllexport)
#   else
#       define ZMQ_EXPORT __declspec(dllimport)
#   endif
#else
#   if defined __SUNPRO_C  || defined __SUNPRO_CC
#       define ZMQ_EXPORT __global
#   elif (defined __GNUC__ && __GNUC__ >= 4) || defined __INTEL_COMPILER
#       define ZMQ_EXPORT __attribute__ ((visibility("default")))
#   else
#       define ZMQ_EXPORT
#   endif
#endif
+/
//TODO: Try to support export cleanly.

/******************************************************************************/
/*  0MQ versioning support.                                                   */
/******************************************************************************/

/*  Version macros for compile-time API version detection                     */
/+
#define ZMQ_VERSION_MAJOR 3
#define ZMQ_VERSION_MINOR 2
#define ZMQ_VERSION_PATCH 2

#define ZMQ_MAKE_VERSION(major, minor, patch) \
    ((major) * 10000 + (minor) * 100 + (patch))
#define ZMQ_VERSION \
    ZMQ_MAKE_VERSION(ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH)
+/
enum    ZMQ_VERSION_MAJOR   = 3 ,
        ZMQ_VERSION_MINOR   = 2 ,
        ZMQ_VERSION_PATCH   = 2 ;
    
enum ZMQ_VERSION = ZMQ_VERSION_MAJOR * 10_000 + ZMQ_VERSION_MINOR * 100 + ZMQ_VERSION_PATCH;

/*  Run-time API version detection                                            */
//ZMQ_EXPORT void zmq_version (int *major, int *minor, int *patch);
void zmq_version ( int* major, int* minor, int* patch );

/******************************************************************************/
/*  0MQ errors.                                                               */
/******************************************************************************/

/*  A number random enough not to collide with different errno ranges on      */
/*  different OSes. The assumption is that error_t is at least 32-bit type.   */
//#define ZMQ_HAUSNUMERO 156384712
enum ZMQ_HAUSNUMERO = 156384712;

/*  On Windows platform some of the standard POSIX errnos are not defined.    */
/+
#ifndef ENOTSUP
#define ENOTSUP (ZMQ_HAUSNUMERO + 1)
#endif
#ifndef EPROTONOSUPPORT
#define EPROTONOSUPPORT (ZMQ_HAUSNUMERO + 2)
#endif
#ifndef ENOBUFS
#define ENOBUFS (ZMQ_HAUSNUMERO + 3)
#endif
#ifndef ENETDOWN
#define ENETDOWN (ZMQ_HAUSNUMERO + 4)
#endif
#ifndef EADDRINUSE
#define EADDRINUSE (ZMQ_HAUSNUMERO + 5)
#endif
#ifndef EADDRNOTAVAIL
#define EADDRNOTAVAIL (ZMQ_HAUSNUMERO + 6)
#endif
#ifndef ECONNREFUSED
#define ECONNREFUSED (ZMQ_HAUSNUMERO + 7)
#endif
#ifndef EINPROGRESS
#define EINPROGRESS (ZMQ_HAUSNUMERO + 8)
#endif
#ifndef ENOTSOCK
#define ENOTSOCK (ZMQ_HAUSNUMERO + 9)
#endif
#ifndef EMSGSIZE
#define EMSGSIZE (ZMQ_HAUSNUMERO + 10)
#endif
#ifndef EAFNOSUPPORT
#define EAFNOSUPPORT (ZMQ_HAUSNUMERO + 11)
#endif
#ifndef ENETUNREACH
#define ENETUNREACH (ZMQ_HAUSNUMERO + 12)
#endif
#ifndef ECONNABORTED
#define ECONNABORTED (ZMQ_HAUSNUMERO + 13)
#endif
#ifndef ECONNRESET
#define ECONNRESET (ZMQ_HAUSNUMERO + 14)
#endif
#ifndef ENOTCONN
#define ENOTCONN (ZMQ_HAUSNUMERO + 15)
#endif
#ifndef ETIMEDOUT
#define ETIMEDOUT (ZMQ_HAUSNUMERO + 16)
#endif
#ifndef EHOSTUNREACH
#define EHOSTUNREACH (ZMQ_HAUSNUMERO + 17)
#endif
#ifndef ENETRESET
#define ENETRESET (ZMQ_HAUSNUMERO + 18)
#endif
+/
version( Windows ) {
    enum {
        ENOTSUP         = ZMQ_HAUSNUMERO + 1,
        EPROTONOSUPPORT ,
        ENOBUFS         ,
        ENETDOWN        ,
        EADDRINUSE      ,
        EADDRNOTAVAIL   ,
        ECONNREFUSED    ,
        EINPROGRESS     ,
        ENOTSOCK        ,
        EMSGSIZE        ,
        EAFNOSUPPORT    ,
        ENETUNREACH     ,
        ECONNABORTED    ,
        ECONNRESET      ,
        ENOTCONN        ,
        ETIMEDOUT       ,
        EHOSTUNREACH    ,
        ENETRESET
    }
}
version( linux ) {
    enum {
        ENOTSUP         = ZMQ_HAUSNUMERO + 1,
    }
}
else {
    static assert( false, "Operating system not yet supported by DZMQ." );
}

/*  Native 0MQ error codes.                                                   */
/+
#define EFSM (ZMQ_HAUSNUMERO + 51)
#define ENOCOMPATPROTO (ZMQ_HAUSNUMERO + 52)
#define ETERM (ZMQ_HAUSNUMERO + 53)
#define EMTHREAD (ZMQ_HAUSNUMERO + 54)
+/
enum {
    EFSM            = ZMQ_HAUSNUMERO + 51,
    ENOCOMPATPROTO  ,
    ETERM           ,
    EMTHREAD
}

/*  This function retrieves the errno as it is known to 0MQ library. The goal */
/*  of this function is to make the code 100% portable, including where 0MQ   */
/*  compiled with certain CRT library (on Windows) is linked to an            */
/*  application that uses different CRT library.                              */
//ZMQ_EXPORT int zmq_errno (void);
int zmq_errno ();

/*  Resolves system errors and 0MQ errors to human-readable string.           */
//ZMQ_EXPORT const char *zmq_strerror (int errnum);
const( char )* zmq_strerror ( int errnum );

/******************************************************************************/
/*  0MQ infrastructure (a.k.a. context) initialisation & termination.         */
/******************************************************************************/

/*  New API                                                                   */
/*  Context options                                                           */
/+
#define ZMQ_IO_THREADS  1
#define ZMQ_MAX_SOCKETS 2
+/
enum {
    ZMQ_IO_THREADS  = 1,
    ZMQ_MAX_SOCKETS
}

/*  Default for new contexts                                                  */
/+
#define ZMQ_IO_THREADS_DFLT  1
#define ZMQ_MAX_SOCKETS_DFLT 1024
+/
enum    ZMQ_IO_THREADS_DFLT     = 1     ,
        ZMQ_MAX_SOCKETS_DFLT    = 1024  ;

/+
ZMQ_EXPORT void *zmq_ctx_new (void);
ZMQ_EXPORT int zmq_ctx_destroy (void *context);
ZMQ_EXPORT int zmq_ctx_set (void *context, int option, int optval);
ZMQ_EXPORT int zmq_ctx_get (void *context, int option);
+/
void* zmq_ctx_new ();
int zmq_ctx_destroy ( void* context );
int zmq_ctx_set ( void* context, int option, int opval );
int zmq_ctx_get ( void* context, int option );

/*  Old (legacy) API                                                          */
/+
ZMQ_EXPORT void *zmq_init (int io_threads);
ZMQ_EXPORT int zmq_term (void *context);
+/
void* zmq_init ( int io_threads );
int zmq_term ( void* context );


/******************************************************************************/
/*  0MQ message definition.                                                   */
/******************************************************************************/

//typedef struct zmq_msg_t {unsigned char _ [32];} zmq_msg_t;
struct zmq_msg_t {
    ubyte[32] _;
    alias _ this;
}

//typedef void (zmq_free_fn) (void *data, void *hint);
alias extern( C ) void function( void* data, void* hint )  zmq_free_fn;

/+
ZMQ_EXPORT int zmq_msg_init (zmq_msg_t *msg);
ZMQ_EXPORT int zmq_msg_init_size (zmq_msg_t *msg, size_t size);
ZMQ_EXPORT int zmq_msg_init_data (zmq_msg_t *msg, void *data,
    size_t size, zmq_free_fn *ffn, void *hint);
ZMQ_EXPORT int zmq_msg_send (zmq_msg_t *msg, void *s, int flags);
ZMQ_EXPORT int zmq_msg_recv (zmq_msg_t *msg, void *s, int flags);
ZMQ_EXPORT int zmq_msg_close (zmq_msg_t *msg);
ZMQ_EXPORT int zmq_msg_move (zmq_msg_t *dest, zmq_msg_t *src);
ZMQ_EXPORT int zmq_msg_copy (zmq_msg_t *dest, zmq_msg_t *src);
ZMQ_EXPORT void *zmq_msg_data (zmq_msg_t *msg);
ZMQ_EXPORT size_t zmq_msg_size (zmq_msg_t *msg);
ZMQ_EXPORT int zmq_msg_more (zmq_msg_t *msg);
ZMQ_EXPORT int zmq_msg_get (zmq_msg_t *msg, int option);
ZMQ_EXPORT int zmq_msg_set (zmq_msg_t *msg, int option, int optval);
+/
int zmq_msg_init ( zmq_msg_t* msg );
int zmq_msg_init_size ( zmq_msg_t* msg, size_t size );
int zmq_msg_init_data ( zmq_msg_t* msg, void* data, size_t size, zmq_free_fn ffn, void* hint );
int zmq_msg_send ( zmq_msg_t* msg, void* s, int flags );
int zmq_msg_recv ( zmq_msg_t* msg, void* s, int flags );
int zmq_msg_close ( zmq_msg_t* msg );
int zmq_msg_move ( zmq_msg_t* dest, zmq_msg_t* src );
int zmq_msg_copy ( zmq_msg_t* dest, zmq_msg_t* src );
void* zmq_msg_data ( zmq_msg_t* msg );
size_t zmq_msg_size ( zmq_msg_t* msg );
int zmq_msg_more ( zmq_msg_t* msg );
int zmq_msg_get ( zmq_msg_t* msg, int option );
int zmq_msg_set ( zmq_msg_t* msg, int option, int optval );

/******************************************************************************/
/*  0MQ socket definition.                                                    */
/******************************************************************************/

/*  Socket types.                                                             */ 
/+
#define ZMQ_PAIR 0
#define ZMQ_PUB 1
#define ZMQ_SUB 2
#define ZMQ_REQ 3
#define ZMQ_REP 4
#define ZMQ_DEALER 5
#define ZMQ_ROUTER 6
#define ZMQ_PULL 7
#define ZMQ_PUSH 8
#define ZMQ_XPUB 9
#define ZMQ_XSUB 10
+/
enum {
    ZMQ_PAIR    = 0,
    ZMQ_PUB     ,
    ZMQ_SUB     ,
    ZMQ_REQ     ,
    ZMQ_REP     ,
    ZMQ_DEALER  ,
    ZMQ_ROUTER  ,
    ZMQ_PULL    ,
    ZMQ_PUSH    ,
    ZMQ_XPUB    ,
    ZMQ_XSUB
}

/*  Deprecated aliases                                                        */
/+
#define ZMQ_XREQ ZMQ_DEALER
#define ZMQ_XREP ZMQ_ROUTER
+/
deprecated enum {
    ZMQ_XREQ    = ZMQ_DEALER    ,
    ZMQ_XREP    = ZMQ_ROUTER    
}

/*  Socket options.                                                           */
/+
#define ZMQ_AFFINITY 4
#define ZMQ_IDENTITY 5
#define ZMQ_SUBSCRIBE 6
#define ZMQ_UNSUBSCRIBE 7
#define ZMQ_RATE 8
#define ZMQ_RECOVERY_IVL 9
#define ZMQ_SNDBUF 11
#define ZMQ_RCVBUF 12
#define ZMQ_RCVMORE 13
#define ZMQ_FD 14
#define ZMQ_EVENTS 15
#define ZMQ_TYPE 16
#define ZMQ_LINGER 17
#define ZMQ_RECONNECT_IVL 18
#define ZMQ_BACKLOG 19
#define ZMQ_RECONNECT_IVL_MAX 21
#define ZMQ_MAXMSGSIZE 22
#define ZMQ_SNDHWM 23
#define ZMQ_RCVHWM 24
#define ZMQ_MULTICAST_HOPS 25
#define ZMQ_RCVTIMEO 27
#define ZMQ_SNDTIMEO 28
#define ZMQ_IPV4ONLY 31
#define ZMQ_LAST_ENDPOINT 32
#define ZMQ_ROUTER_MANDATORY 33
#define ZMQ_TCP_KEEPALIVE 34
#define ZMQ_TCP_KEEPALIVE_CNT 35
#define ZMQ_TCP_KEEPALIVE_IDLE 36
#define ZMQ_TCP_KEEPALIVE_INTVL 37
#define ZMQ_TCP_ACCEPT_FILTER 38
#define ZMQ_DELAY_ATTACH_ON_CONNECT 39
#define ZMQ_XPUB_VERBOSE 40
+/
enum {
    ZMQ_AFFINITY                = 4,
    ZMQ_IDENTITY                ,
    ZMQ_SUBSCRIBE               ,
    ZMQ_UNSUBSCRIBE             ,
    ZMQ_RATE                    ,
    ZMQ_RECOVERY_IVL            ,
    ZMQ_SNDBUF                  = 11,
    ZMQ_RCVBUF                  ,
    ZMQ_RCVMORE                 ,
    ZMQ_FD                      ,
    ZMQ_EVENTS                  ,
    ZMQ_TYPE                    ,
    ZMQ_LINGER                  ,
    ZMQ_RECONNECT_IVL           ,
    ZMQ_BACKLOG                 ,
    ZMQ_RECONNECT_IVL_MAX       = 21,
    ZMQ_MAXMSGSIZE              ,
    ZMQ_SNDHWM                  ,
    ZMQ_RCVHWM                  ,
    ZMQ_MULTICAST_HOPS          ,
    ZMQ_RCVTIMEO                = 27,
    ZMQ_SNDTIMEO                ,
    ZMQ_IPV4ONLY                = 31,
    ZMQ_LAST_ENDPOINT           ,
    ZMQ_ROUTER_MANDATORY        ,
    ZMQ_TCP_KEEPALIVE           ,
    ZMQ_TCP_KEEPALIVE_CNT       ,
    ZMQ_TCP_KEEPALIVE_IDLE      ,
    ZMQ_TCP_KEEPALIVE_INTVL     ,
    ZMQ_TCP_ACCEPT_FILTER       ,
    ZMQ_DELAY_ATTACH_ON_CONNECT ,
    ZMQ_XPUB_VERBOSE
}


/*  Message options                                                           */
//#define ZMQ_MORE 1
enum ZMQ_MORE = 1;

/*  Send/recv options.                                                        */
/+
#define ZMQ_DONTWAIT 1
#define ZMQ_SNDMORE 2
+/
enum    ZMQ_DONTWAIT    = 1 ,
        ZMQ_SNDMORE     = 2 ;

/*  Deprecated aliases                                                        */
/+
#define ZMQ_NOBLOCK ZMQ_DONTWAIT
#define ZMQ_ROUTER_BEHAVIOR ZMQ_ROUTER_MANDATORY
+/
deprecated enum {
    ZMQ_NOBLOCK         = ZMQ_DONTWAIT          ,
    ZMQ_ROUTER_BEHAVIOR = ZMQ_ROUTER_MANDATORY
}

/******************************************************************************/
/*  0MQ socket events and monitoring                                          */
/******************************************************************************/

/*  Socket transport events (tcp and ipc only)                                */
/+
#define ZMQ_EVENT_CONNECTED 1
#define ZMQ_EVENT_CONNECT_DELAYED 2
#define ZMQ_EVENT_CONNECT_RETRIED 4

#define ZMQ_EVENT_LISTENING 8
#define ZMQ_EVENT_BIND_FAILED 16

#define ZMQ_EVENT_ACCEPTED 32
#define ZMQ_EVENT_ACCEPT_FAILED 64

#define ZMQ_EVENT_CLOSED 128
#define ZMQ_EVENT_CLOSE_FAILED 256
#define ZMQ_EVENT_DISCONNECTED 512

#define ZMQ_EVENT_ALL ( ZMQ_EVENT_CONNECTED | ZMQ_EVENT_CONNECT_DELAYED | \
                        ZMQ_EVENT_CONNECT_RETRIED | ZMQ_EVENT_LISTENING | \
                        ZMQ_EVENT_BIND_FAILED | ZMQ_EVENT_ACCEPTED | \
                        ZMQ_EVENT_ACCEPT_FAILED | ZMQ_EVENT_CLOSED | \
                        ZMQ_EVENT_CLOSE_FAILED | ZMQ_EVENT_DISCONNECTED )
+/
enum {
    ZMQ_EVENT_CONNECTED         = 1     ,
    ZMQ_EVENT_CONNECT_DELAYED   = 2     ,
    ZMQ_EVENT_CONNECT_RETRIED   = 4     ,
    
    ZMQ_EVENT_LISTENING         = 8     ,
    ZMQ_EVENT_BIND_FAILED       = 16    ,
    
    ZMQ_EVENT_ACCEPTED          = 32    ,
    ZMQ_EVENT_ACCEPT_FAILED     = 64    ,
    
    ZMQ_EVENT_CLOSED            = 128   ,
    ZMQ_EVENT_CLOSE_FAILED      = 256   ,
    ZMQ_EVENT_DISCONNECTED      = 512   ,
    
    ZMQ_EVENT_ALL               =   ZMQ_EVENT_CONNECTED
                                |   ZMQ_EVENT_CONNECT_DELAYED
                                |   ZMQ_EVENT_CONNECT_RETRIED
                                |   ZMQ_EVENT_LISTENING
                                |   ZMQ_EVENT_BIND_FAILED
                                |   ZMQ_EVENT_ACCEPTED
                                |   ZMQ_EVENT_ACCEPT_FAILED
                                |   ZMQ_EVENT_CLOSED
                                |   ZMQ_EVENT_CLOSE_FAILED
                                |   ZMQ_EVENT_DISCONNECTED
}

/*  Socket event data (union member per event)                                */
/+
typedef struct {
    int event;
    union {
    struct {
        char *addr;
        int fd;
    } connected;
    struct {
        char *addr;
        int err;
    } connect_delayed;
    struct {
        char *addr;
        int interval;
    } connect_retried;
    struct {
        char *addr;
        int fd;
    } listening;
    struct {
        char *addr;
        int err;
    } bind_failed;
    struct {
        char *addr;
        int fd;
    } accepted;
    struct {
        char *addr;
        int err;
    } accept_failed;
    struct {
        char *addr;
        int fd;
    } closed;
    struct {
        char *addr;
        int err;
    } close_failed;
    struct {
        char *addr;
        int fd;
    } disconnected;
    } data;
} zmq_event_t;
+/
struct zmq_event_t {
    int event;
    struct {
        char* addr;
        int   fd;
        
        alias fd err, interval;
    }
}

/+
ZMQ_EXPORT void *zmq_socket (void *, int type);
ZMQ_EXPORT int zmq_close (void *s);
ZMQ_EXPORT int zmq_setsockopt (void *s, int option, const void *optval,
    size_t optvallen); 
ZMQ_EXPORT int zmq_getsockopt (void *s, int option, void *optval,
    size_t *optvallen);
ZMQ_EXPORT int zmq_bind (void *s, const char *addr);
ZMQ_EXPORT int zmq_connect (void *s, const char *addr);
ZMQ_EXPORT int zmq_unbind (void *s, const char *addr);
ZMQ_EXPORT int zmq_disconnect (void *s, const char *addr);
ZMQ_EXPORT int zmq_send (void *s, const void *buf, size_t len, int flags);
ZMQ_EXPORT int zmq_recv (void *s, void *buf, size_t len, int flags);
ZMQ_EXPORT int zmq_socket_monitor (void *s, const char *addr, int events);

ZMQ_EXPORT int zmq_sendmsg (void *s, zmq_msg_t *msg, int flags);
ZMQ_EXPORT int zmq_recvmsg (void *s, zmq_msg_t *msg, int flags);
+/
void* zmq_socket ( void* s, int type );
int zmq_close ( void* s );
int zmq_setsockopt ( void* s, int option, const( void )* optval, size_t optvallen );
int zmq_getsockopt ( void* s, int option, void* optval, size_t* optvallen );
int zmq_bind ( void* s, const( char )* addr );
int zmq_connect ( void* s, const( char )* addr );
int zmq_unbind ( void* s, const( char )* addr );
int zmq_disconnect ( void* s, const( char )* addr );
int zmq_send ( void* s, const( void )* buf, size_t len, int flags );
int zmq_recv ( void* s, void* buf, size_t len, int flags );
int zmq_socket_monitor ( void* s, const( char )* addr, int events );

int zmq_sendmsg ( void* s, zmq_msg_t* msg, int flags );
int zmq_recvmsg ( void* s, zmq_msg_t* msg, int flags );

/*  Experimental                                                              */
//struct iovec;
version( Windows ) {
    struct iovec {}
}
else {
    import core.sys.posix.sys.uio;
}

/+
ZMQ_EXPORT int zmq_sendiov (void *s, struct iovec *iov, size_t count, int flags);
ZMQ_EXPORT int zmq_recviov (void *s, struct iovec *iov, size_t *count, int flags);
+/
int zmq_sendiov ( void* s, iovec* iov, size_t count, int flags );
int zmq_recviov ( void* s, iovec* iov, size_t* count, int flags );

/******************************************************************************/
/*  I/O multiplexing.                                                         */
/******************************************************************************/

/+
#define ZMQ_POLLIN 1
#define ZMQ_POLLOUT 2
#define ZMQ_POLLERR 4
+/
enum    ZMQ_POLLIN  = 1 ,
        ZMQ_POLLOUT = 2 ,
        ZMQ_POLLERR = 4 ;

/+
typedef struct
{
    void *socket;
#if defined _WIN32
    SOCKET fd;
#else
    int fd;
#endif
    short events;
    short revents;
} zmq_pollitem_t;
+/
struct zmq_pollitem_t {
    void* socket;
    
    version( Windows ) {
        SOCKET fd;
    }
    else {
        int fd;
    }
    
    short events;
    short revents;
}

//ZMQ_EXPORT int zmq_poll (zmq_pollitem_t *items, int nitems, long timeout);
int zmq_poll ( zmq_pollitem_t* items, int nitems, int timeout );

//  Built-in message proxy (3-way)

//ZMQ_EXPORT int zmq_proxy (void *frontend, void *backend, void *capture);
int zmq_proxy ( void* frontend, void* backend, void* capture );

//  Deprecated aliases
/+
#define ZMQ_STREAMER 1
#define ZMQ_FORWARDER 2
#define ZMQ_QUEUE 3
+/
deprecated enum {
    ZMQ_STREAMER    = 1,
    ZMQ_FORWARDER   ,
    ZMQ_QUEUE
}
//  Deprecated method
//ZMQ_EXPORT int zmq_device (int type, void *frontend, void *backend);
deprecated int zmq_device ( int type, void* frontend, void* backend );

/+
#undef ZMQ_EXPORT

#ifdef __cplusplus
}
#endif

#endif
+/