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


#include <omnetpp.h>
#include "messages_m.h"


class Source : public cSimpleModule
{
   Module_Class_Members(Source, cSimpleModule, 32768)

   virtual void initialize();
   virtual void finish();
   virtual void activity();

   private:
   cDoubleHistogram* InterarrivalStat;
   cOutVector*       InterarrivalVector;
};

Define_Module(Source);


void Source::initialize()
{
   InterarrivalStat = new cDoubleHistogram("Interarrival Time Statistics", 100);
   InterarrivalStat->setRange(0.005,1.005);
   InterarrivalVector = new cOutVector("Interarrival Time");
}

void Source::finish()
{
   delete InterarrivalStat;
   delete InterarrivalVector;
}

void Source::activity()
{
   unsigned long int id                   = par("id");
   unsigned long int seqNumber            = 0;
   double            lastMessageTimeStamp = -1.0;

   wait(par("startupDelay"));
   for(;;) {
      const unsigned long int packetSize =
         (unsigned long int)par("headerSize") +
         (unsigned long int)par("payloadSize");

      cDataPacket* packet = new cDataPacket("Data Packet");
      packet->setSource(id);
      packet->setDestination(par("destination"));
      packet->setMsgSeqNumber(seqNumber++);
      packet->setTimestamp(simTime());
      packet->setLength(8 * packetSize);
      packet->setContextPointer((void*)id);
      packet->setKind(id);
      send(packet, "outputGate");

      if(lastMessageTimeStamp >= 0.0) {
         const double interarrivalTime = simTime() - lastMessageTimeStamp;
         InterarrivalStat->collect(interarrivalTime);
         InterarrivalVector->record(interarrivalTime);
      }
      lastMessageTimeStamp = simTime();

      double next = par("interarrivalTime");
      wait(next);
   }
}




class Sink : public cSimpleModule
{
   Module_Class_Members(Sink, cSimpleModule, 0)

   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   cDoubleHistogram* DelayStat;
   cDoubleHistogram* LengthStat;
   cOutVector*       DelayVector;
   cOutVector*       LengthVector;
   cDoubleHistogram* InterarrivalStat;
   cOutVector*       InterarrivalVector;
   cOutVector*       LossVector;
   double            LastMessageTimeStamp;
   unsigned int      LastMessageSeqNumber;
};

Define_Module(Sink);


void Sink::initialize()
{
   DelayStat = new cDoubleHistogram("End-to-End Delay Statistics", 100);
   DelayStat->setRange(0.005,1.005);
   DelayVector = new cOutVector("End-to-End Delay");

   LengthStat = new cDoubleHistogram("Packet Length Statistics");
   LengthStat->setRangeAuto(100,1.5);
   LengthVector = new cOutVector("Packet Length");

   InterarrivalStat = new cDoubleHistogram("Interarrival Time Statistics", 100);
   InterarrivalStat->setRange(0.005,1.0005);
   InterarrivalVector = new cOutVector("Interarrival Time");

   LossVector = new cOutVector("Packet Loss");

   LastMessageTimeStamp = -1.0;
}

void Sink::finish()
{
   recordScalar("Average Packet Length", LengthStat->mean());
   recordScalar("Average Delay", DelayStat->mean());

   delete InterarrivalStat;
   delete InterarrivalVector;
   delete DelayStat;
   delete DelayVector;
   delete LengthStat;
   delete LengthVector;
   delete LossVector;
}

void Sink::handleMessage(cMessage* msg)
{
   if(dynamic_cast<cDataPacket*>(msg)) {
      cDataPacket* packet   = (cDataPacket*)msg;
      const double delay    = simTime() - packet->timestamp();
      const double length   = packet->length() / 8;
      const unsigned int id = (unsigned int)((unsigned long)packet->contextPointer());

      DelayStat->collect(delay);
      DelayVector->record(delay);
      LengthStat->collect(length);
      LengthVector->record(length);
      if(LastMessageTimeStamp >= 0.0) {
         const double interarrivalTime = simTime() - LastMessageTimeStamp;
         InterarrivalStat->collect(interarrivalTime);
         InterarrivalVector->record(interarrivalTime);
      }
      LastMessageTimeStamp = simTime();

      if(LastMessageSeqNumber + 1 != packet->getMsgSeqNumber()) {
         const int packetsLost = (int)packet->getMsgSeqNumber() -
                                    (int)(LastMessageSeqNumber + 1);
         if(packetsLost > 0) {
            LossVector->record(packetsLost);
         }
      }
      else {
         LossVector->record(0);
      }
      LastMessageSeqNumber = packet->getMsgSeqNumber();

      ev << "Message with delay " << delay << ", length " << length << " from station " << id << endl;
   }
   else {
      error("Unexpected message type");
   }

   delete msg;
}




class Multiplexer : public cSimpleModule
{
   Module_Class_Members(Multiplexer, cSimpleModule, 0)

   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   double            OutputRate;
   unsigned int      MaxQueueLength;
   unsigned int      QueueLength;
   cQueue            Queue;
   cTimerEvent*      TimerEvent;
   cDoubleHistogram* QueueLengthStat;
   cOutVector*       QueueLengthVector;
   cOutVector*       BytesDroppedVector;
   cOutVector*       PacketsDroppedVector;
};

Define_Module(Multiplexer);


void Multiplexer::initialize()
{
   OutputRate     = par("outputRate");
   MaxQueueLength = par("maxQueueLength");
   QueueLength    = 0;
   TimerEvent     = NULL;
   QueueLengthStat = new cDoubleHistogram("Queue Length Statistics");
   QueueLengthStat->setRange(0, MaxQueueLength);
   QueueLengthVector    = new cOutVector("Queue Length");
   BytesDroppedVector   = new cOutVector("Bytes Dropped");
   PacketsDroppedVector = new cOutVector("Packets Dropped");
}

void Multiplexer::finish()
{
   delete QueueLengthStat;
   delete QueueLengthVector;
   delete BytesDroppedVector;
   delete PacketsDroppedVector;
}

void Multiplexer::handleMessage(cMessage* msg)
{
   // ====== Handle a packet =================================================
   if(dynamic_cast<cDataPacket*>(msg)) {
      cDataPacket* packet = (cDataPacket*)msg;
      const unsigned int packetLength = packet->length() / 8;

      if(QueueLength + packetLength <= MaxQueueLength) {
         Queue.insert((cMessage*)packet->dup());
         QueueLength += packetLength;
         QueueLengthStat->collect(QueueLength);
         QueueLengthVector->record(QueueLength);
         BytesDroppedVector->record(0);
         PacketsDroppedVector->record(0);
      }
      else {
         BytesDroppedVector->record(packetLength);
         PacketsDroppedVector->record(1);
      }
   }

   // ====== Handle timer event ==============================================
   else if(msg == TimerEvent) {
      TimerEvent = NULL;

      cDataPacket* packet = (cDataPacket*)Queue.pop();
      const unsigned int packetLength = packet->length() / 8;
      QueueLength -= packetLength;
      QueueLengthStat->collect(QueueLength);
      QueueLengthVector->record(QueueLength);

      ev << "Sending message #" << packet->getMsgSeqNumber()
         << " from " << packet->getSource() << endl;

      send(packet, "outputGate");
   }

   // ====== Unexpected message type ========================================
   else {
      error("Unexpected message type");
   }


   // ====== Finally, check if new timer can be scheduled ====================
   if((Queue.tail() != NULL) && (TimerEvent == NULL)) {
      cDataPacket* packet = (cDataPacket*)Queue.tail();
      const unsigned int packetLength = packet->length() / 8;
      const double       transmitTime = (double)packetLength / OutputRate;
      ev << "Scheduling timer for message #" << packet->getMsgSeqNumber()
         << " from " << packet->getSource()
         << ", transmit time: "
         << transmitTime << "s" << endl;

      // We schedule a timer for the last bit of the packet being transmitted.
      // Then, we really send out the packet.
      TimerEvent = new cTimerEvent;
      scheduleAt(simTime() + transmitTime, TimerEvent);
   }

   delete msg;
}




class Demultiplexer : public cSimpleModule
{
   Module_Class_Members(Demultiplexer, cSimpleModule, 0)

   virtual void initialize();
   virtual void handleMessage(cMessage* msg);

   private:
};

Define_Module(Demultiplexer);


void Demultiplexer::initialize()
{
}


void Demultiplexer::handleMessage(cMessage* msg)
{
   cDataPacket* packet = dynamic_cast<cDataPacket*>(msg);
   if(packet) {
      cDataPacket* copy = (cDataPacket*)packet->dup();
      send(copy, "outputGate", copy->getDestination() - 1);
   }
   else {
      error("Unexpected message type");
   }
   delete msg;
}



class Fragmenter : public cSimpleModule
{
   Module_Class_Members(Fragmenter, cSimpleModule, 0)

   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   unsigned int       CellPayloadSize;
   unsigned int       CellHeaderSize;
   unsigned long long TotalPayload;
   unsigned long long TotalOverhead;
};

Define_Module(Fragmenter);


void Fragmenter::initialize()
{
   CellPayloadSize = par("cellPayloadSize");
   CellHeaderSize  = par("cellHeaderSize");
   TotalPayload    = 0;
   TotalOverhead   = 0;
}


void Fragmenter::finish()
{
   recordScalar("Total Payload",  TotalPayload);
   recordScalar("Total Overhead", TotalOverhead);
   recordScalar("Overhead To Payload Ratio", (double)TotalOverhead / TotalPayload);
}


void Fragmenter::handleMessage(cMessage* msg)
{
   cDataPacket* packet = dynamic_cast<cDataPacket*>(msg);
   if(packet) {
      const unsigned int packetLength = packet->length() / 8;
      int toSend                      = (int)packetLength;
      unsigned int cellSeqNumber      = 0;

      while(toSend > 0) {
         unsigned int cellPayloadSize = toSend;
         if(cellPayloadSize > CellPayloadSize) {
            cellPayloadSize = CellPayloadSize;
         }
         toSend -= cellPayloadSize;

         char str[64];
#ifdef __GNUC__
         snprintf((char*)&str, sizeof(str), "Cell %u.%u",
                  packet->getDestination(), cellSeqNumber + 1);
#else
         sprintf((char*)&str, "Cell %u.%u",
                 packet->getDestination(), cellSeqNumber + 1);
#endif
         cCell* cell = new cCell(str);
         cell->setLength((CellHeaderSize + CellPayloadSize) * 8);
         cell->setSource(packet->getSource());
         cell->setDestination(packet->getDestination());
         cell->setMsgSeqNumber(packet->getMsgSeqNumber());
         cell->setCellPayloadLength(cellPayloadSize * 8);
         cell->setCellSeqNumber(cellSeqNumber);
         cell->setIsMessageStart((cellSeqNumber == 0));
         cell->setIsMessageEnd((toSend <= 0));
         cell->setTimestamp(packet->timestamp());
         cell->setKind(cellSeqNumber + 67);

         cellSeqNumber++;
         send(cell, "outputGate");

         TotalPayload  += cellPayloadSize;
         TotalOverhead += CellHeaderSize + (CellPayloadSize - cellPayloadSize);
      }
   }
   else {
      error("Unexpected message type");
   }
   delete msg;
}




class Dummy : public cSimpleModule
{
   Module_Class_Members(Dummy, cSimpleModule, 0)

   virtual void handleMessage(cMessage* msg);
};

Define_Module(Dummy);


void Dummy::handleMessage(cMessage* msg)
{
   send((cMessage*)msg->dup(), "outputGate");
   delete msg;
}




class Duplicator : public cSimpleModule
{
   Module_Class_Members(Duplicator, cSimpleModule, 0)

   virtual void initialize();
   virtual void handleMessage(cMessage* msg);

   private:
   int OutputGates;
};

Define_Module(Duplicator);


void Duplicator::initialize()
{
   OutputGates = gate("outputGate")->size();
}


void Duplicator::handleMessage(cMessage* msg)
{
   for(int i = 0;i < OutputGates;i++) {
      send((cMessage*)msg->dup(), "outputGate", i);
   }
   delete msg;
}




class Defragmenter : public cSimpleModule
{
   Module_Class_Members(Defragmenter, cSimpleModule, 0)

   virtual void initialize();
   virtual void handleMessage(cMessage* msg);

   private:
   bool         InProgress;
   unsigned int LastMsgSeqNumber;
   unsigned int LastCellSeqNumber;
   unsigned int PacketLength;
};

Define_Module(Defragmenter);


void Defragmenter::initialize()
{
   InProgress        = false;
   LastMsgSeqNumber  = ~0;
   LastCellSeqNumber = ~0;
   PacketLength      = 0;
}

void Defragmenter::handleMessage(cMessage* msg)
{
   cCell* cell = dynamic_cast<cCell*>(msg);
   if(cell) {

      /*
      ev.printf("seq=%5u cell=%5u (%d %d)\n",
                cell->getMsgSeqNumber(),
                cell->getCellSeqNumber(),
                cell->getIsMessageStart(),cell->getIsMessageEnd());
      */

      if(cell->getIsMessageStart()) {
         InProgress = true;
         LastMsgSeqNumber  = cell->getMsgSeqNumber();
         LastCellSeqNumber = cell->getCellSeqNumber();
         PacketLength      = cell->getCellPayloadLength();
      }
      else {
         if((!InProgress) ||
            (cell->getMsgSeqNumber() != LastMsgSeqNumber) ||
            (cell->getCellSeqNumber() != LastCellSeqNumber + 1)) {
            ev << "Dropping cell!" << endl;
         }
         else {
            LastCellSeqNumber = cell->getCellSeqNumber();
            PacketLength += cell->getCellPayloadLength();
            if(cell->getIsMessageEnd()) {
               cDataPacket* packet = new cDataPacket("Data Packet");
               packet->setSource(cell->getSource());
               packet->setDestination(cell->getDestination());
               packet->setMsgSeqNumber(cell->getMsgSeqNumber());
               packet->setTimestamp(cell->timestamp());
               packet->setLength(PacketLength);
               packet->setKind(cell->getSource());
               send(packet, "outputGate");

               InProgress        = false;
               LastMsgSeqNumber  = ~0;
               LastCellSeqNumber = ~0;
               PacketLength      = 0;
            }
         }
      }
   }
   else {
      error("Unexpected message type");
   }
   delete msg;
}
