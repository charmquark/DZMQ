/*
    Original notice from 0MQ project:
    --------------------------------------------------------------------------------------------
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
    --------------------------------------------------------------------------------------------
*/

/***************************************************************************************************
 *  0MQ header translated into the D Programming Language.
 *
 *  While it is certainly possible to use this module directly, it is generally preferable (from a
 *  user code point of view) to instead use the wrapper in module dzmq.zmq.
 *
 *  Much of this documentation is lifted directly from the 0MQ API documentation available at
 *  $(LINK http://api.zeromq.org/3-2:__start), which is copyright (c) 2007-2012 iMatix Corporation, 
 *  and licensed under the Creative Commons Attribution-Share Alike 3.0 License. ØMQ is copyright 
 *  (c) Copyright (c) 2007-2012 iMatix Corporation and Contributors. ØMQ is free software licensed 
 *  under the LGPL. ØMQ, ZeroMQ, and 0MQ are trademarks of iMatix Corporation.
 *
 *  Where appropriate, minor edits have been made to fit the style of D, or for brevity.
 *
 *  Authors:    Christopher Nicholson-Sauls <ibisbasenji@gmail.com>
 *  Copyright:  Public Domain (within limits of license)
 *  Date:       October 17, 2012
 *  License:    GPLv3 (see file COPYING), LGPLv3 (see file COPYING.LESSER)
 *  Version:    0.1a
 *
 */

module zmq.zmq;

version( Windows ) {
    import std.c.windows.winsock;
}

public import core.stdc.errno;

/* Direct compiler to generate linkage with the 0MQ library. */
pragma( lib, "zmq" );

/* C linkage for all function prototypes. */
extern( C ):


////////////////////////////////////////////////////////////////////////////////////////////////////
//  0MQ versioning support.
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  Version constants for compile-time API version detection.
 */

enum    ZMQ_VERSION_MAJOR   = 3,
        ZMQ_VERSION_MINOR   = 2,
        ZMQ_VERSION_PATCH   = 2,
        ZMQ_VERSION         = ZMQ_VERSION_MAJOR * 10_000 
                            + ZMQ_VERSION_MINOR * 100 
                            + ZMQ_VERSION_PATCH;


/***************************************************************************************************
 *  Run-time API version detection.
 *
 *  The zmq_version() function shall fill in the integer variables pointed to by the major, minor 
 *  and patch arguments with the major, minor and patch level components of the ØMQ library version.
 *
 *  This functionality is intended for applications or language bindings dynamically linking to the 
 *  ØMQ library that wish to determine the actual version of the ØMQ library they are using.
 *
 *  Params:
 *      major   = pointer to variable receiving major version number
 *      minor   = pointer to variable receiving minor version number
 *      patch   = pointer to variable receiving patch version number
 *
 *  -----
 *  int major, minor, patch;
 *  zmq_version( &major, &minor, &patch );
 *  writefln( "Current 0MQ version is %s.%s.%s", major, minor, patch );
 *  -----
 */

void zmq_version ( int* major, int* minor, int* patch );


////////////////////////////////////////////////////////////////////////////////////////////////////
//  0MQ errors.
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  A number random enough not to collide with different errno ranges on different OSes.  The
 *  assumption is that error_t is at least 32-bit type.
 */

enum ZMQ_HAUSNUMERO = 156384712;

version( Windows ) {

    /***********************************************************************************************
     *  On Windows platform some of the standard POSIX errnos are not defined.
     */
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
else version( linux ) {

    /***********************************************************************************************
     *  On Linux we extend the errnos with ENOTSUP.
     */
    enum ENOTSUP = ZMQ_HAUSNUMERO + 1;

}
else {

    //TODO: add the lists for BSD and MacOS X.
    static assert( false, "Operating system not yet supported by DZMQ." );

}


/***************************************************************************************************
 *  Native 0MQ error codes.
 */

enum    EFSM            = ZMQ_HAUSNUMERO + 51   ,
        ENOCOMPATPROTO  = ZMQ_HAUSNUMERO + 52   ,
        ETERM           = ZMQ_HAUSNUMERO + 53   ,
        EMTHREAD        = ZMQ_HAUSNUMERO + 54   ;


/***************************************************************************************************
 *  This function retrieves the errno as it is known to 0MQ library. The goal of this function is to
 *  make the code 100% portable, including where 0MQ compiled with certain CRT library (on Windows)
 *  is linked to an application that uses different CRT library.
 *
 *  Returns: The value of the errno variable for the calling thread.
 */

int zmq_errno ();


/***************************************************************************************************
 *  Resolves system errors and 0MQ errors to human-readable string.
 *
 *  The zmq_strerror() function shall return a pointer to an error message string corresponding to 
 *  the error number specified by the errnum argument. As ØMQ defines additional error numbers over
 *  and above those defined by the operating system, applications should use zmq_strerror() in 
 *  preference to the standard strerror() function.
 *
 *  Returns: A pointer to an error message string (C style 0-terminated).
 *
 *  -----
 *  auto ctx = zmq_ctx_new();
 *  if ( ctx is null ) {
 *      auto err = zmq_errno();
 *      auto errstr = to!string( zmq_strerror( err ) );
 *      // report error ...
 *  }
 *  -----
 */

const( char )* zmq_strerror ( int errnum );


////////////////////////////////////////////////////////////////////////////////////////////////////
//  0MQ infrastructure (a.k.a. context) initialisation & termination.
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  Context options.
 */

enum    ZMQ_IO_THREADS  = 1 ,
        ZMQ_MAX_SOCKETS = 2 ;


/***************************************************************************************************
 *  Default for new contexts.
 */

enum    ZMQ_IO_THREADS_DFLT     = 1     ,
        ZMQ_MAX_SOCKETS_DFLT    = 1024  ;


/***************************************************************************************************
 *  The zmq_ctx_new() function creates a new ØMQ context.
 *
 *  This function replaces the deprecated function zmq_init(3).
 *  
 *  Thread_safety: 
 *      A ØMQ context is thread safe and may be shared among as many application threads 
 *      as necessary,  without any additional locking required on the part of the caller.
 *
 *  Returns: The zmq_ctx_new() function shall return an opaque handle to the newly created context 
 *  if successful. Otherwise it shall return null and set errno to one of the values defined below.
 *
 *  See_Also: zmq_ctx_set, zmq_ctx_get, zmq_ctx_destroy.
 */

void* zmq_ctx_new ();


/***************************************************************************************************
 *  The zmq_ctx_destroy() function shall destroy the ØMQ context context.
 *
 *  Context termination is performed in the following steps:
 *  $(UL
 *      $(LI Any blocking operations currently in progress on sockets open within context shall 
 *      return immediately with an error code of ETERM. With the exception of zmq_close(), any 
 *      further operations on sockets open within context shall fail with an error code of ETERM.)
 *
 *      $(LI After interrupting all blocking calls, zmq_ctx_destroy() shall block until the 
 *      following conditions are satisfied: 
 *          $(UL $(LI All sockets open within context have been closed with zmq_close().))
 *      )
 *
 *      $(LI For each socket within context, all messages sent by the application with zmq_send() 
 *      have either been physically transferred to a network peer, or the socket's linger period set
 *      with the ZMQ_LINGER socket option has expired.)
 *  )
 *
 *  For further details regarding socket linger behavior refer to the ZMQ_LINGER option in 
 *  zmq_setsockopt().
 *
 *  Params:
 *      context = handle created with zmq_ctx_new()
 *
 *  Returns: zero if successful; otherwise -1 and set errno to one of the values defined below.
 *
 *  Errors: 
 *  $(DL
 *      $(DT EFAULT)    $(DD The provided context was invalid.)
 *      $(DT EINTR)     $(DD Termination was interrupted by a signal. It can be restarted if needed.)
 *  )
 *
 *  -----
 *  auto context = zmq_ctx_new();
 *  scope( exit ) {
 *      auto rc = zmq_ctx_destroy( context );
 *      if ( rc != 0 ) {
 *          // attempt to handle/report error ...
 *      }
 *  }
 *  -----
 */

int zmq_ctx_destroy ( void* context );


/***************************************************************************************************
 *  The zmq_ctx_set() function shall set the option specified by the option_name argument to the 
 *  value of the option_value argument.
 *
 *  The zmq_ctx_set() function accepts the following options: 
 *  $(DL
 *      $(DT ZMQ_IO_THREADS) $(DD
 *          $(B Set number of I/O threads.)
 *          $(I Default value: 1.)
 *          The ZMQ_IO_THREADS argument specifies the size of the ØMQ thread pool to handle I/O 
 *          operations. If your application is using only the inproc transport for messaging you may
 *          set this to zero, otherwise set it to at least one. This option only applies before 
 *          creating any sockets on the context.
 *      )
 *      $(DT ZMQ_MAX_SOCKETS) $(DD
 *          $(B Set maximum number of sockets.)
 *          $(I Default value: 1024.)
 *          The ZMQ_MAX_SOCKETS argument sets the maximum number of sockets allowed on the context.
 *      )
 *  )
 *
 *  Params:
 *      context         = handle created with zmq_ctx_new()
 *      option_name     = constant identifier for selected option
 *      option_value    = new value for selected option
 *
 *  Returns: Zero if successful. Otherwise it returns -1 and sets errno to one of the values defined
 *  below.
 *
 *  Errors:
 *  $(DL
 *      $(DT EINVAL) $(DD The requested option option_name is unknown.)
 *  )
 *
 *  -----
 *  // Setting a limit on the number of sockets ////////////////////////////////////////////////////
 *  auto context = zmq_ctx_new();
 *  zmq_ctx_set (context, ZMQ_MAX_SOCKETS, 256);
 *  auto max_sockets = zmq_ctx_get(context, ZMQ_MAX_SOCKETS);
 *  assert (max_sockets == 256);
 *  -----
 */

int zmq_ctx_set ( void* context, int option_name, int option_value );


/***************************************************************************************************
 *  The zmq_ctx_get() function shall return the option specified by the option_name argument.
 *
 *  The zmq_ctx_get() function accepts the following option names:
 *  $(DL
 *      $(DT ZMQ_IO_THREADS) $(DD
 *          $(B Get number of I/O threads.)
 *          The ZMQ_IO_THREADS argument returns the size of the ØMQ thread pool for this context.
 *      )
 *      $(DT ZMQ_MAX_SOCKETS) $(DD
 *          $(B Set maximum number of sockets.)
 *          The ZMQ_MAX_SOCKETS argument returns the maximum number of sockets allowed for this 
 *          context.
 *      )
 *  )
 *
 *  Params:
 *      context     = handle created with zmq_ctx_new()
 *      option_name = constant identifier for selected option
 *
 *  Returns: A value of 0 or greater if successful. Otherwise it returns -1 and sets errno to one of
 *  the values defined below.
 *
 *  Errors:
 *  $(DL
 *      $(DT EINVAL) $(DD The requested option option_name is unknown.)
 *  )
 *
 *  -----
 *  // Setting a limit on the number of sockets ////////////////////////////////////////////////////
 *  auto context = zmq_ctx_new();
 *  zmq_ctx_set (context, ZMQ_MAX_SOCKETS, 256);
 *  auto max_sockets = zmq_ctx_get(context, ZMQ_MAX_SOCKETS);
 *  assert (max_sockets == 256);
 *  -----
 */

int zmq_ctx_get ( void* context, int option_name );


/***************************************************************************************************
 *  Legacy API.  The zmq_init() function initialises a ØMQ context.
 *
 *  The io_threads argument specifies the size of the ØMQ thread pool to handle I/O operations. If 
 *  your application is using only the inproc transport for messaging you may set this to zero, 
 *  otherwise set it to at least one.
 *
 *  Thread_safety:
 *      A ØMQ context is thread safe and may be shared among as many application threads as 
 *      necessary, without any additional locking required on the part of the caller.
 *
 *  $(B This function is deprecated by zmq_ctx_new.)
 *
 *  Params:
 *      io_threads = size of the 0MQ I/O thread pool
 *
 *  Returns: An opaque handle to the initialised context if successful. Otherwise it shall return 
 *  null and set errno to one of the values defined below.
 *
 *  Errors:
 *  $(DL
 *      $(DT EINVAL) $(DD An invalid number of io_threads was requested.)
 *  )
 */

deprecated
void* zmq_init ( int io_threads );


/***************************************************************************************************
 *  Legacy API.  The zmq_term() function shall terminate the ØMQ context context.
 *
 *  Context termination is performed in the following steps:
 *  $(UL
 *      $(LI Any blocking operations currently in progress on sockets open within context shall 
 *      return immediately with an error code of ETERM. With the exception of zmq_close(), any 
 *      further operations on sockets open within context shall fail with an error code of ETERM.)
 *
 *      $(LI After interrupting all blocking calls, zmq_term() shall block until the following 
 *      conditions are satisfied:
 *          $(UL $(LI All sockets open within context have been closed with zmq_close().))
 *      )
 *
 *      $(LI For each socket within context, all messages sent by the application with zmq_send() 
 *      have either been physically transferred to a network peer, or the socket's linger period set
 *      with the ZMQ_LINGER socket option has expired.)
 *  )
 *
 *  For further details regarding socket linger behaviour refer to the ZMQ_LINGER option in 
 *  zmq_setsockopt.
 *
 *  $(B This function is deprecated by zmq_ctx_destroy.)
 *
 *  Params:
 *      context = handle created with zmq_init
 *
 *  Returns: Zero if successful. Otherwise it shall return -1 and set errno to one of the values 
 *  defined below.
 *
 *  Errors:
 *  $(DL
 *      $(DT EFAULT)    $(DD The provided context was invalid.)
 *      $(DT EINTR)     $(DD Termination was interrupted by a signal. It can be restarted if needed.)
 *  )
 */

deprecated
int zmq_term ( void* context );


////////////////////////////////////////////////////////////////////////////////////////////////////
//  0MQ message definition.
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  Opaque message type.  Never try to delve into one of these -- they are strictly for the 0MQ
 *  library to handle and understand.  For you, they are pure mystery.
 */

struct zmq_msg_t {
    private ubyte[32] _;
}


/***************************************************************************************************
 *  Callback type for freeing message buffers.  This function must have C linkage and be thread safe.
 *
 *  Params:
 *      data  = pointer (void*) to buffer data
 *      hint  = pointer (void*) to arbitrary user provided information
 *
 *  See_Also:
 *      zmq_msg_init_data
 */

alias extern( C ) void function( void* data, void* hint )  zmq_free_fn;


/***************************************************************************************************
 *  The zmq_msg_init() function shall initialise the message object referenced by msg to represent 
 *  an empty message. This function is most useful when called before receiving a message with 
 *  zmq_recv().
 *
 *  Never access zmq_msg_t members directly, instead always use the zmq_msg family of functions.
 *
 *  The functions zmq_msg_init(), zmq_msg_init_data() and zmq_msg_init_size() are mutually 
 *  exclusive. Never initialize the same zmq_msg_t twice.
 *
 *  Params:
 *      msg = pointer to uninitialized message
 *
 *  Returns: Zero if successful. Otherwise it shall return -1 and set errno to one of the values 
 *  defined below.
 *
 *  -----
 *  // Receiving a message from a socket ///////////////////////////////////////////////////////////
 *  zmq_msg_t msg;
 *  rc = zmq_msg_init( &msg );
 *  assert( rc == 0 );
 *  rc = zmq_recvmsg( socket, &msg, 0 );
 *  assert( rc >= 0 );
 *  -----
 */

int zmq_msg_init ( zmq_msg_t* msg );


/***************************************************************************************************
 *  The zmq_msg_init_size() function shall allocate any resources required to store a message size 
 *  bytes long and initialise the message object referenced by msg to represent the newly allocated
 *  message.
 *
 *  The implementation shall choose whether to store message content on the stack (small messages) 
 *  or on the heap (large messages). For performance reasons zmq_msg_init_size() shall not clear the
 *  message data.
 *
 *  Never access zmq_msg_t members directly, instead always use the zmq_msg family of functions.
 *
 *  The functions zmq_msg_init(), zmq_msg_init_data() and zmq_msg_init_size() are mutually 
 *  exclusive. Never initialize the same zmq_msg_t twice.
 *
 *  Params:
 *      msg     = pointer to uninitialized message
 *      size    = desired byte-wise size
 *
 *  Returns: Zero if successful. Otherwise it shall return -1 and set errno to one of the values 
 *  defined below.
 *
 *  Errors:
 *  $(DL
 *      $(DT ENOMEM) $(DD Insufficient storage space is available.)
 *  )
 */

int zmq_msg_init_size ( zmq_msg_t* msg, size_t size );


/***************************************************************************************************
 *  The zmq_msg_init_data() function shall initialise the message object referenced by msg to 
 *  represent the content referenced by the buffer located at address data, size bytes long. No copy
 *  of data shall be performed and ØMQ shall take ownership of the supplied buffer.
 *
 *  If provided, the deallocation function ffn shall be called once the data buffer is no longer 
 *  required by ØMQ, with the data and hint arguments supplied to zmq_msg_init_data().
 *
 *  Never access zmq_msg_t members directly, instead always use the zmq_msg family of functions.
 *
 *  The deallocation function ffn needs to be thread-safe, since it will be called from an arbitrary
 *  thread.
 *
 *  The functions zmq_msg_init(), zmq_msg_init_data() and zmq_msg_init_size() are mutually 
 *  exclusive. Never initialize the same zmq_msg_t twice.
 *
 *  Params:
 *      msg     = pointer to uninitialized message
 *      data    = pointer to beginning of buffer
 *      size    = size of buffer
 *      ffn     = buffer free function (or null)
 *      hint    = hint to free function (can also be null; will only be used by the free function)
 *
 *  Returns: Aero if successful. Otherwise it shall return -1 and set errno to one of the values 
 *  defined below.
 *
 *  Errors:
 *  $(DL
 *      $(DT ENOMEM) $(DD Insufficient storage space is available.)
 *  )
 *
 *  -----
 *  // Initialising a message from a supplied buffer ///////////////////////////////////////////////
 *  // NOTE: This example is in C, not D. 
 *
 *  void my_free (void *data, void *hint)
 *  {
 *      free (data);
 *  }
 *
 *  // ...
 *
 *  void *data = malloc (6);
 *  assert (data);
 *  memcpy (data, "ABCDEF", 6);
 *  zmq_msg_t msg;
 *  rc = zmq_msg_init_data (&msg, data, 6, my_free, NULL); assert (rc == 0);
 *  -----
 */

int zmq_msg_init_data ( zmq_msg_t* msg, void* data, size_t size, zmq_free_fn ffn, void* hint );


/***************************************************************************************************
 *  The zmq_msg_send() function is identical to zmq_sendmsg(3), which shall be deprecated in future
 *  versions. zmq_msg_send() is more consistent with other message manipulation functions.
 *
 *  The zmq_msg_send() function shall queue the message referenced by the msg argument to be sent to
 *  the socket referenced by the socket argument. The flags argument is a combination of the flags 
 *  defined below:
 *  $(DL
 *      $(DT ZMQ_DONTWAIT) $(DD Specifies that the operation should be performed in non-blocking 
 *      mode. If the message cannot be queued on the socket, the zmq_msg_send() function shall fail 
 *      with errno set to EAGAIN.)
 *
 *      $(DT ZMQ_SNDMORE) $(DD Specifies that the message being sent is a multi-part message, and 
 *      that further message parts are to follow. Refer to the section regarding multi-part messages
 *      below for a detailed description.)
 *  )
 *
 *  The zmq_msg_t structure passed to zmq_msg_send() is nullified during the call. If you want to 
 *  send the same message to multiple sockets you have to copy it using (e.g. using zmq_msg_copy()).
 *
 *  A successful invocation of zmq_msg_send() does not indicate that the message has been 
 *  transmitted to the network, only that it has been queued on the socket and ØMQ has assumed 
 *  responsibility for the message.
 *
 *  Multi-part_messages:
 *      A ØMQ message is composed of 1 or more message parts. Each message part is an independent 
 *      zmq_msg_t in its own right. ØMQ ensures atomic delivery of messages: peers shall receive 
 *      either all message parts of a message or none at all. The total number of message parts is 
 *      unlimited except by available memory.
 *
 *      An application that sends multi-part messages must use the ZMQ_SNDMORE flag when sending 
 *      each message part except the final one.
 *
 *  Params:
 *
 *  Returns: The number of bytes in the message if successful. Otherwise it shall return -1 and set 
 *  errno to one of the values defined below.
 *
 *  Errors:
 *  $(DL
 *      $(DT EAGAIN) $(DD Non-blocking mode was requested and the message cannot be sent at the 
 *      moment.)
 *
 *      $(DT ENOTSUP) $(DD The zmq_msg_send() operation is not supported by this socket type.)
 *
 *      $(DT EFSM) $(DD The zmq_msg_send() operation cannot be performed on this socket at the 
 *      moment due to the socket not being in the appropriate state. This error may occur with 
 *      socket types that switch between several states, such as ZMQ_REP. See the messaging patterns
 *      section of zmq_socket() for more information.)
 *
 *      $(DT ETERM) $(DD The ØMQ context associated with the specified socket was terminated.)
 *
 *      $(DT ENOTSOCK) $(DD The provided socket was invalid.)
 *
 *      $(DT EINTR) $(DD The operation was interrupted by delivery of a signal before the message 
 *      was sent.)
 *
 *      $(DT EFAULT) $(DD Invalid message.)
 *  )
 *
 *  -----
 *  // Filling in a message and sending it to a socket /////////////////////////////////////////////
 *
 *  /+ Create a new message, allocating 6 bytes for message content +/
 *  zmq_msg_t msg;
 *  auto rc = zmq_msg_init_size( &msg, 6 );
 *  assert( rc == 0 );
 *
 *  /+ Fill in message content with 'AAAAAA' +/
 *  zmq_msg_data( &msg )[ 0 .. 6 ] = 'A';
 *
 *  /+ Send the message to the socket +/
 *  rc = zmq_msg_send( &msg, socket, 0 );
 *  assert( rc == 6 );
 *
 *
 *  // Sending a multi-part message ////////////////////////////////////////////////////////////////
 *
 *  /+ Send a multi-part message consisting of three parts to socket +/
 *  rc = zmq_msg_send( &part1, socket, ZMQ_SNDMORE );
 *  rc = zmq_msg_send( &part2, socket, ZMQ_SNDMORE );
 *
 *  /+ Final part; no more parts to follow +/
 *  rc = zmq_msg_send( &part3, socket, 0 );
 *  -----
 */

int zmq_msg_send ( zmq_msg_t* msg, void* s, int flags );


/***************************************************************************************************
 *  
 */

int zmq_msg_recv ( zmq_msg_t* msg, void* s, int flags );


/***************************************************************************************************
 *  
 */

int zmq_msg_close ( zmq_msg_t* msg );


/***************************************************************************************************
 *  
 */

int zmq_msg_move ( zmq_msg_t* dest, zmq_msg_t* src );


/***************************************************************************************************
 *  
 */

int zmq_msg_copy ( zmq_msg_t* dest, zmq_msg_t* src );


/***************************************************************************************************
 *  
 */

void* zmq_msg_data ( zmq_msg_t* msg );


/***************************************************************************************************
 *  
 */

size_t zmq_msg_size ( zmq_msg_t* msg );


/***************************************************************************************************
 *  
 */

int zmq_msg_more ( zmq_msg_t* msg );


/***************************************************************************************************
 *  
 */

int zmq_msg_get ( zmq_msg_t* msg, int option );


/***************************************************************************************************
 *  
 */

int zmq_msg_set ( zmq_msg_t* msg, int option, int optval );


////////////////////////////////////////////////////////////////////////////////////////////////////
//  0MQ socket definition.
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  
 */

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


/***************************************************************************************************
 *  
 */

/*  Deprecated aliases                                                        */
/+
#define ZMQ_XREQ ZMQ_DEALER
#define ZMQ_XREP ZMQ_ROUTER
+/
deprecated enum {
    ZMQ_XREQ    = ZMQ_DEALER    ,
    ZMQ_XREP    = ZMQ_ROUTER    
}


/***************************************************************************************************
 *  
 */

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


/***************************************************************************************************
 *  
 */

/*  Message options                                                           */
//#define ZMQ_MORE 1
enum ZMQ_MORE = 1;


/***************************************************************************************************
 *  
 */

/*  Send/recv options.                                                        */
/+
#define ZMQ_DONTWAIT 1
#define ZMQ_SNDMORE 2
+/
enum    ZMQ_DONTWAIT    = 1 ,
        ZMQ_SNDMORE     = 2 ;


/***************************************************************************************************
 *  
 */

/*  Deprecated aliases                                                        */
/+
#define ZMQ_NOBLOCK ZMQ_DONTWAIT
#define ZMQ_ROUTER_BEHAVIOR ZMQ_ROUTER_MANDATORY
+/
deprecated enum {
    ZMQ_NOBLOCK         = ZMQ_DONTWAIT          ,
    ZMQ_ROUTER_BEHAVIOR = ZMQ_ROUTER_MANDATORY
}


////////////////////////////////////////////////////////////////////////////////////////////////////
//  0MQ socket events and monitoring
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  
 */

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


/***************************************************************************************************
 *  
 */

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


/***************************************************************************************************
 *  
 */

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
void* zmq_socket ( void* c, int type );
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


/***************************************************************************************************
 *  
 */

/*  Experimental                                                              */
//struct iovec;
version( Windows ) {
    struct iovec {}
}
else {
    import core.sys.posix.sys.uio;
}


/***************************************************************************************************
 *  
 */

/+
ZMQ_EXPORT int zmq_sendiov (void *s, struct iovec *iov, size_t count, int flags);
ZMQ_EXPORT int zmq_recviov (void *s, struct iovec *iov, size_t *count, int flags);
+/
int zmq_sendiov ( void* s, iovec* iov, size_t count, int flags );
int zmq_recviov ( void* s, iovec* iov, size_t* count, int flags );


////////////////////////////////////////////////////////////////////////////////////////////////////
//  I/O multiplexing.
////////////////////////////////////////////////////////////////////////////////////////////////////


/***************************************************************************************************
 *  
 */

/+
#define ZMQ_POLLIN 1
#define ZMQ_POLLOUT 2
#define ZMQ_POLLERR 4
+/
enum    ZMQ_POLLIN  = 1 ,
        ZMQ_POLLOUT = 2 ,
        ZMQ_POLLERR = 4 ;


/***************************************************************************************************
 *  
 */

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


/***************************************************************************************************
 *  
 */

//ZMQ_EXPORT int zmq_poll (zmq_pollitem_t *items, int nitems, long timeout);
int zmq_poll ( zmq_pollitem_t* items, int nitems, int timeout );


/***************************************************************************************************
 *  
 */

//  Built-in message proxy (3-way)

//ZMQ_EXPORT int zmq_proxy (void *frontend, void *backend, void *capture);
int zmq_proxy ( void* frontend, void* backend, void* capture );


/***************************************************************************************************
 *  
 */

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


/***************************************************************************************************
 *  
 */

//  Deprecated method
//ZMQ_EXPORT int zmq_device (int type, void *frontend, void *backend);
deprecated int zmq_device ( int type, void* frontend, void* backend );

