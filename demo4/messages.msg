// $Id: omnetpp.ini 51 2008-01-22 11:23:51Z dreibh $
// ###########################################################################
//             Thomas Dreibholz's R Simulation Scripts Collection
//                  Copyright (C) 2005-2008 Thomas Dreibholz
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


message cDataPacket extends cPacket
{
    unsigned int Source;
    unsigned int Destination;
    unsigned int MsgSeqNumber;
}


message cCell extends cDataPacket
{
    unsigned int CellSeqNumber;
    unsigned int CellPayloadLength;
    bool         IsMessageStart;
    bool         IsMessageEnd;
}


message cTimerEvent
{
}
