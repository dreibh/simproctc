# $Id$
# ###########################################################################
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2010 Thomas Dreibholz
#
#              Author: Thomas Dreibholz, dreibh@iem.uni-due.de
# ###########################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Contact: dreibh@iem.uni-due.de


CPPFLAGS=-O0 -Wall -g
# CPPFLAGS=-O3 -Wall -g
CC=g++


all:	createsummary runtimeestimator combinesummaries extractvectors getrelativepath


createsummary:	createsummary.cc inputfile.o outputfile.o simpleredblacktree.o doublelinkedringlist.o
	$(CC) createsummary.cc -o createsummary inputfile.o outputfile.o simpleredblacktree.o doublelinkedringlist.o -lbz2 $(CPPFLAGS)

combinesummaries:	combinesummaries.cc
	$(CC) combinesummaries.cc -o combinesummaries $(CPPFLAGS) -lbz2

extractvectors:   extractvectors.cc
	$(CC) extractvectors.cc -o extractvectors $(CPPFLAGS) -lbz2

runtimeestimator:	runtimeestimator.cc
	$(CC) runtimeestimator.cc -o runtimeestimator $(CPPFLAGS)

getrelativepath: getrelativepath.cc
	$(CC) getrelativepath.cc -o getrelativepath $(CPPFLAGS)


simpleredblacktree.o:	simpleredblacktree.c simpleredblacktree.h redblacktree.h redblacktree_impl.h
	$(CC) simpleredblacktree.c -c -o simpleredblacktree.o $(CPPFLAGS)


doublelinkedringlist.o:	doublelinkedringlist.c doublelinkedringlist.h
	$(CC) doublelinkedringlist.c -c -o doublelinkedringlist.o $(CPPFLAGS)


inputfile.o:	inputfile.cc inputfile.h
	$(CC) inputfile.cc -c -o inputfile.o $(CPPFLAGS)

outputfile.o:	outputfile.cc outputfile.h
	$(CC) outputfile.cc -c -o outputfile.o $(CPPFLAGS)


t1:	test1.sca test2.sca createsummary
	( echo "--skip=tsb.nameServerArray.enrpServer" && echo "--simulationsdirectory=." && echo "--resultsdirectory=/tmp" && echo "--values=One" && echo "--input=test1.sca" && echo "--values=Two" && echo "--input=test2.sca" && echo "--skip=KeepAlive" ) | ./createsummary MyVarName

t1u:	test1.sca test2.sca createsummary
	( echo "--simulationsdirectory=." && echo "--resultsdirectory=/tmp" && echo "--values=One" && echo "--input=test1.sca" && echo "--values=Two" && echo "--input=test2.sca" ) | ./createsummary MyVarName -compress=0

t2:	test1.sca.bz2 test2.sca.bz2 createsummary
	( echo "--varnames=\"MyVarName\"" && echo "--simulationsdirectory=." && echo "--resultsdirectory=/tmp" && echo "--values=One" && echo "--input=test1.sca.bz2" && echo "--values=Two" && echo "--input=test2.sca.bz2" ) | ./createsummary

t2u:	test1.sca.bz2 test2.sca.bz2 createsummary
	( echo "--varnames=\"MyVarName\"" && echo "--simulationsdirectory=." && echo "--resultsdirectory=/tmp" && echo "--values=One" && echo "--input=test1.sca.bz2" && echo "--values=Two" && echo "--input=test2.sca.bz2" ) | ./createsummary X -compress=0


clean:
	rm -f runtimeestimator createsummary combinesummaries extractvectors getrelativepath test.results *~ *.o
