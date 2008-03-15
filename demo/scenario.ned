// $Id$
// ###########################################################################
//                   A Very Simple Example Simulation for
//             Thomas Dreibholz's R Simulation Scripts Collection
//                    Copyright (C) 2008 Thomas Dreibholz
//
//           Author: Thomas Dreibholz, dreibh@exp-math.uni-essen.de
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


channel Link10M
    delay 10ms;
    datarate 10000000;
endchannel


simple Source
    parameters:
        startupDelay : numeric,
        headerSize : numeric const,
        payloadSize : numeric,
        interarrivalTime : numeric,
        id : numeric const,
        destination : numeric const;
    gates:
        out: outputGate;
endsimple


simple Multiplexer
    parameters:
        outputRate : numeric const,
        maxQueueLength : numeric const;
    gates:
        in: inputGate[];
        out: outputGate;
endsimple


simple Demultiplexer
    parameters:
    gates:
        in: inputGate;
        out: outputGate[];
endsimple


simple Sink
    gates:
        in: inputGate;
endsimple


module MultiSink
    parameters:
        sinks : numeric const;
    gates:
        in: inputGate;
    submodules:
        demultiplexer: Demultiplexer;
            parameters:
            gatesizes:
                outputGate[sinks];
            display: "i=xconn;p=80,120";
        sinkArray: Sink[sinks];
            display: "i=bwsink;p=240,60,column,60";
    connections:
        inputGate --> demultiplexer.inputGate;
        for i=0..sinks-1 do
            demultiplexer.outputGate[i] --> sinkArray[i].inputGate;
        endfor;
    display: "p=10,10;b=267,211";
endmodule


simple Fragmenter
    parameters:
        cellPayloadSize : numeric const,
        cellHeaderSize : numeric const;
    gates:
        in: inputGate;
        out: outputGate;
endsimple


simple Defragmenter
    parameters:
    gates:
        in: inputGate;
        out: outputGate;
endsimple


simple Duplicator
    gates:
        in: inputGate;
        out: outputGate[];
endsimple


module IntermediateNode
    parameters:
        outputRate : numeric const,
        maxQueueLength : numeric const;

    gates:
        in: inputGate;
        out: outputGate;
    submodules:
        outputBuffer: Multiplexer;
            parameters:
                outputRate = outputRate,
                maxQueueLength = maxQueueLength;
            gatesizes:
                inputGate[1];
            display: "p=82,64;i=queue";
    connections:
        inputGate --> outputBuffer.inputGate[0];
        outputBuffer.outputGate --> outputGate;
    display: "p=10,10;b=140,93";
endmodule


module FragmenterScenario
    parameters:
        intermediateNodeOutputRate : numeric const,
        sourceInterarrivalTime : numeric,
        sourcePayloadSize : numeric,
        sourceHeaderSize : numeric const;
    submodules:
        source: Source;
            parameters:
                startupDelay = 0s,
                interarrivalTime = sourceInterarrivalTime,
                payloadSize = sourcePayloadSize,
                headerSize = sourceHeaderSize,
                id = 1000,
                destination = 1;
            display: "b=34,34;p=260,310;i=bwgen";
        duplicator: Duplicator;
            gatesizes:
                outputGate[2];
            display: "p=160,310;i=fork;b=40,24";
        fragmenter: Fragmenter;
            parameters:
                cellPayloadSize = input(128),
                cellHeaderSize = input(8);
            display: "p=60,160;i=proc2";
        nodeArray1: IntermediateNode[4];
            parameters:
                outputRate = intermediateNodeOutputRate,
                maxQueueLength = intermediateNodeOutputRate;
            display: "b=32,30;p=60,60,row,100;i=queue";
        defragmenter: Defragmenter;
            display: "b=32,30;p=460,160;i=proc2";
        sink1: Sink;
            display: "b=34,34;p=460,260;i=bwsink";
        nodeArray2: IntermediateNode[4];
            parameters:
                outputRate = intermediateNodeOutputRate,
                maxQueueLength = intermediateNodeOutputRate;
            display: "p=60,460,row,100;i=queue";
        sink2: Sink;
            display: "b=34,34;p=460,360;i=bwsink";
    connections:
        source.outputGate --> Link10M --> duplicator.inputGate;
        duplicator.outputGate[0] --> fragmenter.inputGate;
        fragmenter.outputGate --> Link10M --> nodeArray1[0].inputGate;
        for i=0..2 do
            nodeArray1[i].outputGate --> Link10M --> nodeArray1[i + 1].inputGate;
        endfor;
        nodeArray1[3].outputGate --> Link10M --> defragmenter.inputGate;
        defragmenter.outputGate --> sink1.inputGate;

        duplicator.outputGate[1] --> Link10M --> nodeArray2[0].inputGate;
        for i=0..2 do
            nodeArray2[i].outputGate --> Link10M --> nodeArray2[i + 1].inputGate;
        endfor;
        nodeArray2[3].outputGate --> Link10M --> sink2.inputGate;
endmodule


network fragmenterScenario : FragmenterScenario
    parameters:
        intermediateNodeOutputRate = input(50000),
        sourceInterarrivalTime = input(0.1s),
        sourcePayloadSize = input(500),
        sourceHeaderSize = input(20);
endnetwork
