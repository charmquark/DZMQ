/*
    0MQ wrapper in the D Programming Language
    by Christopher Nicholson-Sauls (2012).
*/

/***************************************************************************************************
 *
 */
module dzmq.utils;

import  core.time       ;
import  dzmq.c.utils    ;


/***************************************************************************************************
 *
 */
struct ZMQStopwatch {

    /*******************************************************************************************
     *
     */
    void start () {
        if ( !running ) {
            running = true;
            handle = zmq_stopwatch_start();
        }
    }


    /*******************************************************************************************
     *
     */
    void stop () {
        if ( running ) {
            span = dur!`usecs`( zmq_stopwatch_stop( handle ) );
            running = false;
        }
    }


    /*******************************************************************************************
     *
     */
    @property
    Duration time () {
        return span;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////
    //private:
    ////////////////////////////////////////////////////////////////////////////////////////////
    
    
    Duration    span            ;
    void*       handle  = null  ;
    bool        running = false ;


} // end ZMQStopwatch


/***************************************************************************************************
 *
 */
void zmqSleep ( Duration d ) {
    zmq_sleep( cast( int ) d.total!`seconds`() );
}

///ditto
alias zmq_sleep zmqSleep;
