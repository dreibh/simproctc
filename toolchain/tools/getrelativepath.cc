// $Id$
// ###########################################################################
//             Thomas Dreibholz's R Simulation Scripts Collection
//                  Copyright (C) 2004-2010 Thomas Dreibholz
//
//           Author: Thomas Dreibholz, dreibh@iem.uni-due.de
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

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <iostream>


using namespace std;


#define MAX_DIR_SIZE 1024


const char* getFirstDirectory(const char* path, char* directory)
{
   size_t i = 0;

   while(path[i] != '/') {
      if(path[i] == 0x00) {
         return(NULL);
      }
      directory[i] = path[i];
      i++;
      if(i >= MAX_DIR_SIZE) {
         cerr << "ERROR: Directory name too long -> aborting" << endl;
         exit(1);
      }
   }
   directory[i] = 0x00;
   return((const char*)&path[i + 1]);
}


size_t countChar(const char* str, const char c)
{
   size_t count = 0, i = 0;
   while(str[i] != 0x00) {
      if(str[i] == c) {
         count++;
      }
      i++;
   }
   return(count);
}


// ###### Main program ######################################################
int main(int argc, char** argv)
{
   if(argc < 3) {
      cerr << "Usage: " << argv[0] << " [From Path] [To Path]" << endl;
     exit(1);
   }

   const char* fromPath = argv[1];
   const char* toPath = argv[2];

   char   directory1[MAX_DIR_SIZE];
   char   directory2[MAX_DIR_SIZE];
   size_t commonLevels = 0;

   for(;;) {
      const char* p1 = getFirstDirectory(fromPath, (char*)&directory1);
      const char* p2 = getFirstDirectory(toPath, (char*)&directory2);

      if( (p1 == NULL) || (p2 == NULL) ) {
         break;
      }
      if(strcmp(directory1, directory2) != 0) {
         break;
      }

      commonLevels++;
      fromPath = p1;
      toPath   = p2;
   }

   if(commonLevels < 1) {
      cerr << "ERROR: toPath=" << toPath << " is not in the hierachy of fromPath=" << fromPath << "!" << endl;
      exit(1);
   }

   if( (strcmp(fromPath, ".") == 0) &&
       (strcmp(toPath, ".") == 0) ) {
      cout << "." << endl;
   }
   else {
      const size_t steps = 1 + countChar(fromPath, '/');
      for(size_t i = 0;i < steps;i++) {
         if(i > 0) {
            cout << "/";
         }
         cout << "..";
      }
      cout << "/" << toPath << endl;
   }

   return 0;
}
