// $Id$
// ###########################################################################
//                   A Very Simple Example Simulation for
//             Thomas Dreibholz's R Simulation Scripts Collection
//                  Copyright (C) 2008-2022 Thomas Dreibholz
//
//               Author: Thomas Dreibholz, dreibh@iem.uni-due.de
// ###########################################################################
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY// without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// Contact: dreibh@iem.uni-due.de


channel Link10M extends ned.DatarateChannel
{
    parameters:
        delay    = 10ms;
        datarate = 10000000bps;
}


simple Source
{
    parameters:
        volatile double startupDelay     @unit(s);
        double          headerSize       @unit(B);
        volatile double payloadSize      @unit(B);
        volatile double interarrivalTime @unit(s);
        double          id;
        double          destination;
    gates:
        output outputGate;
}


simple Multiplexer
{
    parameters:
        double outputRate     @unit(Bps);
        double maxQueueLength @unit(B);
    gates:
        input inputGate[];
        output outputGate;
}


simple Demultiplexer
{
    parameters:
    gates:
        input  inputGate;
        output outputGate[];
}


simple Sink
{
    gates:
        input inputGate;
}


module MultiSink
{
    parameters:
        double sinks;
        @display("bgb=267,211;bgp=10,10");
    gates:
        input inputGate;
    submodules:
        demultiplexer: Demultiplexer {
            parameters:
                @display("i=xconn;p=80,120");
            gates:
                outputGate[sinks];
        }
        sinkArray[sinks]: Sink {
            parameters:
                @display("i=bwsink;p=240,60,column,60");
        }
    connections:
        inputGate --> demultiplexer.inputGate;
        for i=0..sinks-1 {
            demultiplexer.outputGate[i] --> sinkArray[i].inputGate;
        }
}


simple Fragmenter
{
    parameters:
        double cellPayloadSize @unit(B);
        double cellHeaderSize  @unit(B);
    gates:
        input  inputGate;
        output outputGate;
}


simple Defragmenter
{
    parameters:
    gates:
        input  inputGate;
        output outputGate;
}


simple Duplicator
{
    gates:
        input inputGate;
        output outputGate[];
}


module IntermediateNode
{
    parameters:
        double outputRate     @unit(Bps);
        double maxQueueLength @unit(B);

        @display("bgb=140,93;bgp=10,10");
    gates:
        input  inputGate;
        output outputGate;
    submodules:
        outputBuffer: Multiplexer {
            parameters:
                outputRate     = outputRate;
                maxQueueLength = maxQueueLength;
                @display("p=82,64;i=queue");
            gates:
                inputGate[1];
        }
    connections:
        inputGate --> outputBuffer.inputGate[0];
        outputBuffer.outputGate --> outputGate;
}


module FragmenterScenario
{
    parameters:
        double          intermediateNodeOutputRate     @unit(Bps);
        double          intermediateNodeMaxQueueLength @unit(B);
        volatile double sourceInterarrivalTime         @unit(s);
        volatile double sourcePayloadSize              @unit(B);
        double          sourceHeaderSize               @unit(B);
    submodules:
        source: Source {
            parameters:
                startupDelay     = 0s;
                interarrivalTime = sourceInterarrivalTime;
                payloadSize      = sourcePayloadSize;
                headerSize       = sourceHeaderSize;
                id               = 1000;
                destination      = 1;
                @display("b=34,34;p=260,310;i=bwgen");
        }
        duplicator: Duplicator {
            parameters:
                @display("p=160,310;i=fork;b=40,24");
            gates:
                outputGate[2];
        }
        fragmenter: Fragmenter {
            parameters:
                cellPayloadSize = default(128 B);
                cellHeaderSize  = default(8 B);
                @display("p=60,160;i=proc2");
        }
        nodeArray1[4]: IntermediateNode {
            parameters:
                outputRate     = intermediateNodeOutputRate;
                maxQueueLength = intermediateNodeMaxQueueLength;
                @display("b=32,30;p=60,60,row,100;i=queue");
        }
        defragmenter: Defragmenter {
            parameters:
                @display("b=32,30;p=460,160;i=proc2");
        }
        sink1: Sink {
            parameters:
                @display("b=34,34;p=460,260;i=bwsink");
        }
        nodeArray2[4]: IntermediateNode {
            parameters:
                outputRate     = intermediateNodeOutputRate;
                maxQueueLength = intermediateNodeMaxQueueLength;
                @display("p=60,460,row,100;i=queue");
        }
        sink2: Sink {
            parameters:
                @display("b=34,34;p=460,360;i=bwsink");
        }
    connections:
        source.outputGate --> Link10M --> duplicator.inputGate;
        duplicator.outputGate[0] --> fragmenter.inputGate;
        fragmenter.outputGate --> nodeArray1[0].inputGate;
        for i=0..2 {
            nodeArray1[i].outputGate --> Link10M --> nodeArray1[i+1].inputGate;
        }
        nodeArray1[3].outputGate --> Link10M --> defragmenter.inputGate;
        defragmenter.outputGate --> sink1.inputGate;

        duplicator.outputGate[1] --> nodeArray2[0].inputGate;
        for i=0..2 {
            nodeArray2[i].outputGate --> Link10M --> nodeArray2[i+1].inputGate;
        }
        nodeArray2[3].outputGate --> Link10M --> sink2.inputGate;
}


network fragmenterScenario extends FragmenterScenario
{
    parameters:
        intermediateNodeOutputRate     = default(50000 Bps);
        intermediateNodeMaxQueueLength = default(50000 B);
        sourceInterarrivalTime         = default(0.1s);
        sourcePayloadSize              = default(500 B);
        sourceHeaderSize               = default(20 B);
}
