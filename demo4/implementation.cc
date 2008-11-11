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
   public:
   Source();
   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   cGate*              OutputGate;
   cQueue              OutputQueue;
   cNewMessageEvent*   NewMessageEvent;
   cChannelReadyEvent* ChannelReadyEvent;
   cDoubleHistogram*   InterarrivalStat;
   cOutVector*         InterarrivalVector;
   unsigned long int   ID;
   unsigned long int   SeqNumber;
   simtime_t           LastMessageTimeStamp;
};

Define_Module(Source);


Source::Source() : cSimpleModule()
{
}

void Source::initialize()
{
   ID                   = par("id");
   SeqNumber            = 0;
   LastMessageTimeStamp = -1.0;

   OutputGate           = gate(findGate("outputGate"));

   InterarrivalStat = new cDoubleHistogram("Interarrival Time Statistics", 100);
   InterarrivalStat->setRange(0.005,1.005);
   InterarrivalVector = new cOutVector("Interarrival Time");

   ChannelReadyEvent = NULL;
   NewMessageEvent   = new cNewMessageEvent("NewMessageEvent");
   scheduleAt((simtime_t)par("startupDelay") + (simtime_t)par("interarrivalTime"), NewMessageEvent);
}

void Source::finish()
{
   delete InterarrivalStat;
   delete InterarrivalVector;
}

void Source::handleMessage(cMessage* msg)
{
   if(msg == NewMessageEvent) {
      const unsigned long int packetSize =
         (unsigned long int)par("headerSize") +
         (unsigned long int)par("payloadSize");

      cDataPacket* packet = new cDataPacket("DataPacket");
      packet->setSource(ID);
      packet->setDestination(par("destination"));
      packet->setMsgSeqNumber(SeqNumber++);
      packet->setTimestamp(simTime());
      packet->setBitLength(8 * packetSize);
      packet->setContextPointer((void*)ID);
      packet->setKind(ID);
      OutputQueue.insert(packet);

      if(LastMessageTimeStamp >= 0.0) {
         const simtime_t interarrivalTime = simTime() - LastMessageTimeStamp;
         InterarrivalStat->collect(interarrivalTime);
         InterarrivalVector->record(interarrivalTime);
      }
      LastMessageTimeStamp = simTime();

      if(ChannelReadyEvent == NULL) {
         ChannelReadyEvent = new cChannelReadyEvent("ChannelReadyEvent");
         scheduleAt(simTime(), ChannelReadyEvent);
      }

      NewMessageEvent = new cNewMessageEvent("NewMessageEvent");
      scheduleAt(simTime() + (simtime_t)par("interarrivalTime"), NewMessageEvent);
   }

   else if(msg == ChannelReadyEvent) {
      if(OutputQueue.empty()) {
         ChannelReadyEvent = NULL;
      }
      else {
         send(static_cast<cMessage*>(OutputQueue.pop()), "outputGate");
         ChannelReadyEvent = new cChannelReadyEvent("NewMessageEvent");
         scheduleAt(OutputGate->getTransmissionFinishTime(), ChannelReadyEvent);
      }
   }

   else {
      error("Unknown message type!");
   }

   delete msg;
}




class Sink : public cSimpleModule
{
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
   simtime_t         LastMessageTimeStamp;
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
   recordScalar("Average Packet Length", LengthStat->getMean());
   recordScalar("Average Delay", DelayStat->getMean());

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
      const simtime_t delay = simTime() - packet->getTimestamp();
      const double length   = packet->getBitLength() / 8;
      const unsigned int id = (unsigned int)((unsigned long)packet->getContextPointer());

      DelayStat->collect(delay);
      DelayVector->record(delay);
      LengthStat->collect(length);
      LengthVector->record(length);
      if(LastMessageTimeStamp >= 0.0) {
         const simtime_t interarrivalTime = simTime() - LastMessageTimeStamp;
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
   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   cQueue            OutputQueue;
   cGate*            OutputGate;
   cTimerEvent*      TimerEvent;
   cDoubleHistogram* QueueLengthStat;
   cOutVector*       QueueLengthVector;
   cOutVector*       BytesDroppedVector;
   cOutVector*       PacketsDroppedVector;
   double            OutputRate;
   unsigned int      MaxQueueLength;
   unsigned int      QueueLength;
};

Define_Module(Multiplexer);


void Multiplexer::initialize()
{
   OutputRate     = par("outputRate");
   OutputGate     = gate(findGate("outputGate"));
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
      const unsigned int packetLength = packet->getBitLength() / 8;

      if(QueueLength + packetLength <= MaxQueueLength) {
         OutputQueue.insert(packet);
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

      cDataPacket* packet = (cDataPacket*)OutputQueue.pop();
      const unsigned int packetLength = packet->getBitLength() / 8;
      QueueLength -= packetLength;
      QueueLengthStat->collect(QueueLength);
      QueueLengthVector->record(QueueLength);

      ev << "Sending message #" << packet->getMsgSeqNumber()
         << " from " << packet->getSource() << endl;

      send(packet, "outputGate");
      delete msg;
   }

   // ====== Unexpected message type ========================================
   else {
      error("Unexpected message type");
   }


   // ====== Finally, check if new timer can be scheduled ====================
   if((OutputQueue.front() != NULL) && (TimerEvent == NULL)) {
      cDataPacket* packet = (cDataPacket*)OutputQueue.front();
      const unsigned int packetLength = packet->getBitLength() / 8;
      const simtime_t    transmitTime = std::max(OutputGate->getTransmissionFinishTime(),
                                                 simTime() + (double)packetLength / OutputRate);
      ev << "Scheduling timer for message #" << packet->getMsgSeqNumber()
         << " from " << packet->getSource()
         << ", transmit time: "
         << transmitTime << "s" << endl;

      // We schedule a timer for the last bit of the packet being transmitted.
      // Then, we really send out the packet.
      TimerEvent = new cTimerEvent;
      scheduleAt(transmitTime, TimerEvent);
   }
}


class Demultiplexer : public cSimpleModule
{
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
      send(packet, "outputGate", packet->getDestination() - 1);
   }
   else {
      error("Unexpected message type");
   }
}



class Fragmenter : public cSimpleModule
{
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
      const unsigned int packetLength = packet->getBitLength() / 8;
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
         cell->setBitLength((CellHeaderSize + CellPayloadSize) * 8);
         cell->setSource(packet->getSource());
         cell->setDestination(packet->getDestination());
         cell->setMsgSeqNumber(packet->getMsgSeqNumber());
         cell->setCellPayloadLength(cellPayloadSize * 8);
         cell->setCellSeqNumber(cellSeqNumber);
         cell->setIsMessageStart((cellSeqNumber == 0));
         cell->setIsMessageEnd((toSend <= 0));
         cell->setTimestamp(packet->getTimestamp());
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
   virtual void handleMessage(cMessage* msg);
};

Define_Module(Dummy);


void Dummy::handleMessage(cMessage* msg)
{
   send(msg, "outputGate");
}




class Duplicator : public cSimpleModule
{
   virtual void initialize();
   virtual void handleMessage(cMessage* msg);

   private:
   int OutputGates;
};

Define_Module(Duplicator);


void Duplicator::initialize()
{
   OutputGates = gateSize("outputGate");
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
               cDataPacket* packet = new cDataPacket("DataPacket");
               packet->setSource(cell->getSource());
               packet->setDestination(cell->getDestination());
               packet->setMsgSeqNumber(cell->getMsgSeqNumber());
               packet->setTimestamp(cell->getTimestamp());
               packet->setBitLength(PacketLength);
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