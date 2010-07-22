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
#include <fstream>

#include "inputfile.h"
#include "outputfile.h"


// ###### Read and process data file ########################################
void addDataFile(OutputFile&         outputFile,
                 unsigned long long& outputLineNumber,
                 const std::string&  varNames,
                 const std::string&  varValues,
                 const std::string&  inputFileName)
{
   // ====== Open input file ================================================
   InputFile       inputFile;
   InputFileFormat inputFileFormat = IFF_Plain;
   if( (inputFileName.rfind(".bz2") == inputFileName.size() - 4) ||
       (inputFileName.rfind(".BZ2") == inputFileName.size() - 4) ) {
       inputFileFormat = IFF_BZip2;
   }
   if(inputFile.initialize(inputFileName.c_str(), inputFileFormat) == false) {
      std::cerr << "ERROR: Unable to open input file \"" << inputFileName << "\"!" << std::endl;
      exit(1);
   }

   for(;;) {
      // ====== Read line from input file ===================================
      bool          eof;
      char          buffer[4097];
      const ssize_t bytesRead = inputFile.readLine((char*)&buffer, sizeof(buffer), eof);
      if((bytesRead < 0) || (eof)) {
         break;
      }

      // ====== Process line ================================================
      if(inputFile.getLine() == 1) {
         if(outputLineNumber == 0) {
            if(outputFile.printf("%s SubLineNo %s\n", varNames.c_str(), buffer) == false) {
               std::cerr << "ERROR: Writing to output file <"
                         << outputFile.getName() << "> failed!" << std::endl;
               outputFile.finish();
               exit(1);
            }
         }
      }
      else {
         if(outputFile.printf("%07llu\t%s\t%s\n",
                              outputLineNumber, varValues.c_str(), buffer) == false) {
            std::cerr << "ERROR: Writing to output file <"
                      << outputFile.getName() << "> failed!" << std::endl;
            outputFile.finish();
            exit(1);
         }
      }
      outputLineNumber++;
   }

   inputFile.finish();
}



// ###### Main program ######################################################
int main(int argc, char** argv)
{
   bool         quiet            = false;
   unsigned int compressionLevel = 9;

   if(argc < 3) {
      std::cerr << "Usage: " << argv[0]
                << " [Output File] [Var Names] {-compress=0-9} {-quiet}" << std::endl;
      exit(1);
   }
   for(int i = 3;i < argc;i++) {
      if(!(strcmp(argv[i], "-quiet"))) {
         quiet = true;
      }
      else if(!(strncmp(argv[i], "-compress=", 10))) {
         compressionLevel = atol((char*)&argv[i][10]);
         if(compressionLevel > 9) {
            compressionLevel = 9;
         }
      }
   }


   if(!quiet) {
      std::cout << "CombineSummaries - Version 2.20" << std::endl
                << "===============================" << std::endl << std::endl;
   }

   OutputFile outputFile;
   if(outputFile.initialize(argv[1],
                            (compressionLevel > 0) ? OFF_BZip2 : OFF_Plain,
                            compressionLevel)== false) {
      std::cerr << std::endl
                << "ERROR: Unable to create file <" << argv[1] << ">!" << std::endl;
      exit(1);
   }


   unsigned long long outputLineNumber = 0;
   std::string varNames                = argv[2];
   std::string varValues               = "";
   std::string simulationsDirectory    = ".";
   char        commandBuffer[4097];
   char*       command;

   if(!quiet) {
      std::cout << "Ready> ";
      std::cout.flush();
   }
   while((command = fgets((char*)&commandBuffer, sizeof(commandBuffer), stdin))) {
      command[strlen(command) - 1] = 0x00;
      if(command[0] == 0x00) {
         std::cout << "*** End of File ***" << std::endl;
         break;
      }
      if(!quiet) {
         std::cout << command << std::endl;
      }

      if(!(strncmp(command, "--values=", 9))) {
         varValues = (const char*)&command[9];
         if(varValues[0] == '\"') {
            varValues = varValues.substr(1, varValues.size() - 2);
         }
      }
      else if(!(strncmp(command, "--input=", 8))) {
         if(varValues[0] == 0x00) {
            std::cerr << "ERROR: No values given (parameter --values=...)!" << std::endl;
            exit(1);
         }
         addDataFile(outputFile, outputLineNumber,
                     varNames, varValues, std::string((const char*)&command[8]));
         varValues = "";
      }
      else if(!(strncmp(command, "--simulationsdirectory=", 23))) {
         simulationsDirectory = (const char*)&simulationsDirectory[23];
      }
      else {
         std::cerr << "ERROR: Invalid command!" << std::endl;
         exit(1);
      }

      if(!quiet) {
         std::cout << "Ready> ";
         std::cout.flush();
      }
   }


   unsigned long long in, out;
   if(outputFile.finish(true, &in, &out)) {
      if(!quiet) {
         std::cout << " (" << outputLineNumber << " lines";
         if(in > 0) {
            std::cout << ", " << in << " -> " << out << " - "
                      << ((double)out * 100.0 / in) << "%";
         }
         std::cout << ")" << std::endl;
      }
   }
   else {
      std::cerr << "ERROR: failed to close file <" << argv[1] << ">!" << std::endl;
      exit(1);
   }

   return(0);
}
