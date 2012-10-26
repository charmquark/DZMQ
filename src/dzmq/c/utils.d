/*
    Original notice from 0MQ project:
    --------------------------------------------------------------------------------------------
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
    --------------------------------------------------------------------------------------------
*/

/***************************************************************************************************
 *  0MQ header translated into the D Programming Language.
 *
 *  Helper functions are used by perf tests so that they don't have to care about minutiae of
 *  time-related functions on different OS platforms.
 *
 * ----------
 *  auto watch = zmq_stopwatch_start();
 *  // do some work... or fake it with zmq_sleep( seconds )
 *  auto span = zmq_stopwatch_stop( watch );
 *  writefln( "Completed in %s usecs.", span );
 * ----------
 *
 *  Authors:    Christopher Nicholson-Sauls <ibisbasenji@gmail.com>
 *  Copyright:  Public Domain (within limits of license)
 *  Date:       October 17, 2012
 *  License:    GPLv3 (see file COPYING), LGPLv3 (see file COPYING.LESSER)
 *  Version:    0.1a
 *
 */

module dzmq.c.utils;


// Direct compiler to generate linkage with the 0MQ library.
pragma( lib, "zmq" );


// C linkage for all function prototypes.
extern( C ):


/***************************************************************************************************
 *  Starts the stopwatch.
 *
 *  Returns: stopwatch resource handle; handle with care.
 */

void* zmq_stopwatch_start ();


/***************************************************************************************************
 *  Stops the stopwatch.
 *
 *  Params:
 *      watch_  = stopwatch resource handle (created with zmq_stopwatch_start)
 *  Returns: the number of microseconds elapsed since the stopwatch was started.
 */

uint zmq_stopwatch_stop ( void* watch_ );


/***************************************************************************************************
 *  Sleeps for specified number of seconds.
 *
 *  Params:
 *      seconds_    = the number of seconds to sleep
 */

void zmq_sleep ( int seconds_ );

