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


#include <omnetpp.h>
#include "messages_m.h"


using namespace omnetpp;


// ##########################################################################
// #### Source Model                                                     ####
// ##########################################################################

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
   cHistogram*         InterarrivalStat;
   cOutVector*         InterarrivalVector;
   unsigned long int   ID;
   unsigned long int   SeqNumber;
   simtime_t           LastMessageTimeStamp;
};

Define_Module(Source);


Source::Source() : cSimpleModule()
{
}


// ###### Initialise ########################################################
void Source::initialize()
{
   ID                   = par("id");
   SeqNumber            = 0;
   LastMessageTimeStamp = -1.0;

   OutputGate           = gate(findGate("outputGate"));

   InterarrivalStat = new cHistogram("Interarrival Time Statistics", 100);
   InterarrivalStat->setRange(0.005,1.005);
   InterarrivalVector = new cOutVector("Interarrival Time");

   ChannelReadyEvent = NULL;
   NewMessageEvent   = new cNewMessageEvent("NewMessageEvent");
   scheduleAt((simtime_t)par("startupDelay") + (simtime_t)par("interarrivalTime"), NewMessageEvent);
}


// ###### Clean up ##########################################################
void Source::finish()
{
   delete InterarrivalStat;
   delete InterarrivalVector;
}


// ###### Handle message ####################################################
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
      if(OutputQueue.isEmpty()) {
         ChannelReadyEvent = NULL;
      }
      else {
         send(static_cast<cMessage*>(OutputQueue.pop()), "outputGate");
         ChannelReadyEvent = new cChannelReadyEvent("NewMessageEvent");
         scheduleAt(OutputGate->getChannel()->getTransmissionFinishTime(), ChannelReadyEvent);
      }
   }

   else {
      error("Unknown message type!");
   }

   delete msg;
}



// ##########################################################################
// #### Sink Model                                                       ####
// ##########################################################################

class Sink : public cSimpleModule
{
   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   cHistogram*  DelayStat;
   cHistogram*  LengthStat;
   cOutVector*  DelayVector;
   cOutVector*  LengthVector;
   cHistogram*  InterarrivalStat;
   cOutVector*  InterarrivalVector;
   cOutVector*  LossVector;
   simtime_t    LastMessageTimeStamp;
   unsigned int LastMessageSeqNumber;
};

Define_Module(Sink);


// ###### Initialise ########################################################
void Sink::initialize()
{
   DelayStat = new cHistogram("Packet Delay", 100);
   DelayStat->setRange(0.005,1.005);
   DelayVector = new cOutVector("Packet Delay");

   LengthStat = new cHistogram("Packet Length");
   LengthVector = new cOutVector("Packet Length");

   InterarrivalStat = new cHistogram("Packet Interarrival Time", 100);
   InterarrivalStat->setRange(0.005,1.0005);
   InterarrivalVector = new cOutVector("Packet Interarrival Time");

   LossVector = new cOutVector("Packet Loss");

   LastMessageTimeStamp = -1.0;
}


// ###### Clean up ##########################################################
void Sink::finish()
{
   recordStatistic(LengthStat);
   recordStatistic(DelayStat);
   recordStatistic(InterarrivalStat);

   delete InterarrivalStat;
   delete InterarrivalVector;
   delete DelayStat;
   delete DelayVector;
   delete LengthStat;
   delete LengthVector;
   delete LossVector;
}


// ###### Handle message ####################################################
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

      EV << "Message with delay " << delay << ", length " << length << " from station " << id << endl;
   }
   else {
      error("Unexpected message type");
   }

   delete msg;
}



// ##########################################################################
// #### Multiplexer Model                                                ####
// ##########################################################################

class Multiplexer : public cSimpleModule
{
   virtual void initialize();
   virtual void finish();
   virtual void handleMessage(cMessage* msg);

   private:
   cQueue       OutputQueue;
   cGate*       OutputGate;
   cTimerEvent* TimerEvent;
   cHistogram*  QueueLengthStat;
   cOutVector*  QueueLengthVector;
   cOutVector*  BytesDroppedVector;
   cOutVector*  PacketsDroppedVector;
   double       OutputRate;
   unsigned int MaxQueueLength;
   unsigned int QueueLength;
};

Define_Module(Multiplexer);


// ###### Initialise ########################################################
void Multiplexer::initialize()
{
   OutputRate     = par("outputRate");
   OutputGate     = gate(findGate("outputGate"));
   MaxQueueLength = par("maxQueueLength");
   QueueLength    = 0;
   TimerEvent     = NULL;

   QueueLengthStat = new cHistogram("Queue Length Statistics");
   QueueLengthStat->setRange(0, MaxQueueLength);
   QueueLengthVector    = new cOutVector("Queue Length");
   BytesDroppedVector   = new cOutVector("Bytes Dropped");
   PacketsDroppedVector = new cOutVector("Packets Dropped");
}


// ###### Clean up ##########################################################
void Multiplexer::finish()
{
   delete QueueLengthStat;
   delete QueueLengthVector;
   delete BytesDroppedVector;
   delete PacketsDroppedVector;
}


// ###### Handle message ####################################################
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

      EV << "Sending message #" << packet->getMsgSeqNumber()
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
      const simtime_t    transmitTime =
         std::max(
            OutputGate->getTransmissionChannel()->getTransmissionFinishTime(),
            simTime() + (double)packetLength / OutputRate
         );
      EV << "Scheduling timer for message #" << packet->getMsgSeqNumber()
         << " from " << packet->getSource()
         << ", transmit time: "
         << transmitTime << "s" << endl;

      // We schedule a timer for the last bit of the packet being transmitted.
      // Then, we really send out the packet.
      TimerEvent = new cTimerEvent;
      scheduleAt(transmitTime, TimerEvent);
   }
}



// ##########################################################################
// #### Demultiplexer Model                                              ####
// ##########################################################################

class Demultiplexer : public cSimpleModule
{
   virtual void initialize();
   virtual void handleMessage(cMessage* msg);

   private:
};

Define_Module(Demultiplexer);


// ###### Initialise ########################################################
void Demultiplexer::initialize()
{
}


// ###### Handle message ####################################################
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



// ##########################################################################
// #### Fragmenter Model                                                 ####
// ##########################################################################

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


// ###### Initialise ########################################################
void Fragmenter::initialize()
{
   CellPayloadSize = par("cellPayloadSize");
   CellHeaderSize  = par("cellHeaderSize");
   TotalPayload    = 0;
   TotalOverhead   = 0;
}


// ###### Clean up ##########################################################
void Fragmenter::finish()
{
   recordScalar("Total Payload",  TotalPayload);
   recordScalar("Total Overhead", TotalOverhead);
   recordScalar("Overhead To Payload Ratio", (double)TotalOverhead / TotalPayload);
}


// ###### Handle message ####################################################
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



// ##########################################################################
// #### Dummy Model                                                      ####
// ##########################################################################

class Dummy : public cSimpleModule
{
   virtual void handleMessage(cMessage* msg);
};

Define_Module(Dummy);


// ###### Handle message ####################################################
void Dummy::handleMessage(cMessage* msg)
{
   send(msg, "outputGate");
}



// ##########################################################################
// #### Duplicator Model                                                 ####
// ##########################################################################

class Duplicator : public cSimpleModule
{
   virtual void initialize();
   virtual void handleMessage(cMessage* msg);

   private:
   int OutputGates;
};

Define_Module(Duplicator);


// ###### Initialise ########################################################
void Duplicator::initialize()
{
   OutputGates = gateSize("outputGate");
}


// ###### Handle message ####################################################
void Duplicator::handleMessage(cMessage* msg)
{
   for(int i = 0;i < OutputGates;i++) {
      send((cMessage*)msg->dup(), "outputGate", i);
   }
   delete msg;
}



// ##########################################################################
// #### Defragmenter Model                                               ####
// ##########################################################################

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


// ###### Initialise ########################################################
void Defragmenter::initialize()
{
   InProgress        = false;
   LastMsgSeqNumber  = ~0;
   LastCellSeqNumber = ~0;
   PacketLength      = 0;
}


// ###### Handle message ####################################################
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
            EV << "Dropping cell!" << endl;
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
