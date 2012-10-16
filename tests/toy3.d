module toy3;

import  dzmq.zmq    ;
import  std.stdio   ;

void main () {
    auto context = new ZMQContext;

    auto pub = context.publisherSocket();
    auto sub = context.subscriberSocket();
}

