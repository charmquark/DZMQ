/*
    0MQ header translated into the D Programming Language 2.x
    by Christopher Nicholson-Sauls (2012).
*/

/*
    Copyright (c) 2009-2011 250bpm s.r.o.
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

module zmq.utils;

extern( C ):

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

/*  Helper functions are used by perf tests so that they don't have to care   */
/*  about minutiae of time-related functions on different OS platforms.       */

/*  Starts the stopwatch. Returns the handle to the watch.                    */
//ZMQ_EXPORT void *zmq_stopwatch_start (void);
void* zmq_stopwatch_start ();

/*  Stops the stopwatch. Returns the number of microseconds elapsed since     */
/*  the stopwatch was started.                                                */
//ZMQ_EXPORT unsigned long zmq_stopwatch_stop (void *watch_);
uint zmq_stopwatch_stop ( void* watch_ );

/*  Sleeps for specified number of seconds.                                   */
//ZMQ_EXPORT void zmq_sleep (int seconds_);
void zmq_sleep ( int seconds_ );
