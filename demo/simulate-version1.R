# $Id$
# ###########################################################################
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2008 Thomas Dreibholz
#
#           Author: Thomas Dreibholz, dreibh@exp-math.uni-essen.de
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


source("simulation.R")


# ###########################################################################
# #### demo-specific Part                                                ####
# ###########################################################################

# ====== Write OMNeT++ INI file header ======================================
demoWriteHeader <- function(iniFile, simulationRun, scalarName, vectorName, duration)
{
   cat(sep="", "[General]\n", file=iniFile)
   cat(sep="", "network = ", simCreatorSimulationNetwork, "\n", file=iniFile)
   cat(sep="", "rng-class = cMersenneTwister\n", file=iniFile)
   cat(sep="", "seed-0-mt = ", simulationRun, "\n", file=iniFile)
   cat(sep="", "output-scalar-file = ", "run", simulationRun, "-scalars.sca\n", file=iniFile)
   cat(sep="", "output-vectors-file = ", "run", simulationRun, "-vectors.vec\n", file=iniFile)
   cat(sep="", "# --- Note: Set sim-time-limit larger than Controller::statisticsWriteTimeStamp! ---\n", file=iniFile)
   cat(sep="", "sim-time-limit = ", simCreatorSimulationStartup, " ", duration, "s 1ms\n", file=iniFile)
   cat(sep="", "\n\n", file=iniFile)

   cat(sep="", "[Cmdenv]\n", file=iniFile)
   cat(sep="", "express-mode = yes\n", file=iniFile)
   cat(sep="", "\n", file=iniFile)

   cat(sep="", "[Tkenv]\n", file=iniFile)
   cat(sep="", "default-run = 1\n", file=iniFile)
   cat(sep="", "\n", file=iniFile)

   cat(sep="", "[OutVectors]\n", file=iniFile)
   if(simulationStoreVectors) {
      cat(sep="", "**.enabled = yes\n", file=iniFile)
   }
   else {
      cat(sep="", "**.enabled = no\n", file=iniFile)
   }
   cat(sep="", "**.interval = ", simCreatorSimulationStartup, "..", simCreatorSimulationStartup, " ", duration, "\n", file=iniFile)
   cat(sep="", "\n", file=iniFile)
   cat(sep="", "\n", file=iniFile)
}


# ====== demo automatic parameter setup =====================================
demoAutoParameters <- function(simulationConfigurations)
{
   return(TRUE)
}


# ====== Write demo INI file parameter section ==============================
demoWriteParameterSection <- function(filePrefix, iniFile, simulationRun, duration)
{
   # NewParam: Add appropriate lines to the .ini file in this function.

   cat(sep="", "[Parameters]\n", file=iniFile)

   # ------ Scenario settings -----------------------------------------------
   cat(sep="", "# ----- Scenario settings --------------------------------\n", file=iniFile)
   cat(sep="", "fragmenterScenario.fragmenter.cellPayloadSize = ", cellPayloadSize, "\n", file=iniFile)
   cat(sep="", "fragmenterScenario.fragmenter.cellHeaderSize = ", cellHeaderSize, "\n", file=iniFile)
   cat(sep="", "fragmenterScenario.intermediateNodeOutputRate = ", intermediateNodeOutputRate, "\n", file=iniFile)
   cat(sep="", "fragmenterScenario.sourceInterarrivalTime = exponential(", sourceInterarrivalTime, ")\n", file=iniFile)
   cat(sep="", "fragmenterScenario.sourcePayloadSize = exponential(", sourcePayloadSize, ")\n", file=iniFile)
   cat(sep="", "fragmenterScenario.sourceHeaderSize = ", sourceHeaderSize, "\n", file=iniFile)
   cat(sep="", "\n", file=iniFile)
}


simCreatorSimulationBinary      <- "demo"
simCreatorSimulationNetwork     <- "fragmenterScenario"
simCreatorSimulationStartup     <- "5s"
simCreatorWriteHeader           <- demoWriteHeader
simCreatorWriteParameterSection <- demoWriteParameterSection
simCreatorAutoParameters        <- demoAutoParameters
# Add variables here which should be handled as active (i.e. their value
# is recorded) even it is constant for all runs. The value of this variable
# is required for plotting.
# NewParam: If new parameters should always be recorded, add them here.
simCreatorAdditionalActiveVariables <- c(
   "cellPayloadSize",
   "cellHeaderSize",
   "sourceInterarrivalTime",
   "sourcePayloadSize",
   "sourceHeaderSize"
)
# Here, you can provide additional files for packaging, e.g. "my-nedfile.ned".
# You may even use a pattern, e.g. "Test*.ned".
simulationMiscFiles <- ""


# NewParam: Finally, add the new parameter to your simulation configuration.


demoPlotVariables <- list(
   # ------ Format example --------------------------------------------------
   # list("Variable",
   #         "Unit[x]{v]"
   #          "100.0 * data1$x / data1$y", <- Manipulator expression:
   #                                           "data" is the data table
   #                                        NA here means: use data1$Variable.
   #          "myColor",
   #          list("InputFile1", "InputFile2", ...))
   #             (simulationDirectory/Results/....data.tar.bz2 is added!)
   # ------------------------------------------------------------------------

   list("cellPayloadSize",        "Cell Payload Size{P}[1]", NA, NA, NA),
   list("cellHeaderSize",         "Cell Header Size{H}[1]",  NA, NA, NA),
   list("sourceInterarrivalTime", "Interarrival Time{T}[s]", NA, NA, NA),
   list("sourcePayloadSize",      "Payload Size{p}[1]",      NA, NA, NA),
   list("sourceHeaderSize",       "Header Size{h}[1]",       NA, NA, NA),

   list("fragmenter.TotalPayload",
           "Total Payload in Fragmenter[1]",
           "100.0 * data1$fragmenter.TotalPayload",
           "green4",
           list("fragmenter-TotalPayload")),
   list("fragmenter.TotalOverhead",
           "Total Overhead in Fragmenter[1]",
           "100.0 * data1$fragmenter.TotalOverhead",
           "yellow4",
           list("fragmenter-TotalOverhead")),

   list("fragmenter.AddedOverhead",
           "Overhead Added by Fragmenter[%]",
           "100.0 * (data2$fragmenter.TotalOverhead / data1$fragmenter.TotalPayload)",
           "red4",
           list("fragmenter-TotalPayload", "fragmenter-TotalOverhead")),

   list("fragmenter.OverheadToPayloadRatio",
           "Overhead to Payload Ratio[%]",
           "100.0 * data1$fragmenter.OverheadToPayloadRatio",
           "brown4",
           list("fragmenter-OverheadToPayloadRatio")),

   list("sink", "Sink Number{S}", NA, NA, NA),

   list("sink.AverageDelay",
           "Average Delay[ms]",
           "data1$sink.AverageDelay * 1000.0",
           "blue4",
           list("sink-AverageDelay"))
)
