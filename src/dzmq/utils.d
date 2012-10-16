/*
    0MQ wrapper in the D Programming Language
    by Christopher Nicholson-Sauls (2012).
*/

module dzmq.utils;

import  core.time   ;
import  zmq.utils   ;


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
        return time;
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
