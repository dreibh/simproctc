# ###########################################################################
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2022 Thomas Dreibholz
#
#               Author: Thomas Dreibholz, dreibh@iem.uni-due.de
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
   cat(sep="", "output-vector-file = ", "run", simulationRun, "-vectors.vec\n", file=iniFile)
   cat(sep="", "cmdenv-express-mode = true\n", file=iniFile)
   cat(sep="", "sim-time-limit = ", simCreatorSimulationStartup, " ", duration, "s 1ms\n", file=iniFile)
   cat(sep="", "\n\n", file=iniFile)

   if(simulationStoreVectors) {
      cat(sep="", "**.vector-recording = true\n", file=iniFile)
   }
   else {
      cat(sep="", "**.vector-recording = false\n", file=iniFile)
   }
   cat(sep="", "# NOTE: In OMNeT++ 4.0, this parameter has been named vector-recording-interval!\n", file=iniFile)
   cat(sep="", "# To use under OMNeT++ 4.0, check simulate-version1.R and replace:\n", file=iniFile)
   cat(sep="", "# vector-recording-intervals by vector-recording-interval!\n", file=iniFile)
   cat(sep="", "**.vector-recording-intervals = ", simCreatorSimulationStartup, "..", simCreatorSimulationStartup, " ", duration, "s\n", file=iniFile)
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

   # ------ Scenario settings -----------------------------------------------
   cat(sep="", "# ----- Scenario settings --------------------------------\n", file=iniFile)
   cat(sep="", "fragmenterScenario.fragmenter.cellPayloadSize = ", cellPayloadSize, " B\n", file=iniFile)
   cat(sep="", "fragmenterScenario.fragmenter.cellHeaderSize  = ", cellHeaderSize, " B\n", file=iniFile)
   cat(sep="", "fragmenterScenario.intermediateNodeOutputRate = ", intermediateNodeOutputRate, " Bps\n", file=iniFile)
   cat(sep="", "fragmenterScenario.sourceInterarrivalTime     = exponential(", sourceInterarrivalTime, " s)\n", file=iniFile)
   cat(sep="", "fragmenterScenario.sourcePayloadSize          = exponential(", sourcePayloadSize, " B)\n", file=iniFile)
   cat(sep="", "fragmenterScenario.sourceHeaderSize           = ", sourceHeaderSize, " B\n", file=iniFile)
   cat(sep="", "\n", file=iniFile)
}


# The sources directory of the simulation.
simCreatorSourcesDirectory <- paste(sep="", getwd(), "/../example-simulation")   # i.e. the current directory

# The simulation binary.
# NOTE: The path here is relative to the directory set in simCreatorSourcesDirectory!
simCreatorSimulationBinary <- "example-simulation"

# The directory where the binary should be executed.
# NOTE: The path here is relative to the directory set in simCreatorSourcesDirectory!
simCreatorSimulationBaseDir <- "."

# A list of directories to be recursively searched for NED files. These NED
# files will be copied into the environment directory.
# NOTE: The paths here are relative to the directory set in simCreatorSourcesDirectory!
# Example: list("src", "examples/sctp")
simCreatorNEDFiles <- list(".")
# NOTE: Before examples/sctp can be used, examples/package.ned must be read.
#       It contains the package name. Without this, there will be an error
#       about wrong package name when the simulation is run!

# A list of directories to be recursively searched for misc files. These misc
# files will be copied into the environment directory.
# NOTE: The paths here are relative to the directory set in simCreatorSourcesDirectory!
# Example: list(c("*.mrt", "examples/sctp/cmttest1"))
simCreatorMiscFiles <- list()

# The simulation network to be loaded.
simCreatorSimulationNetwork <- "fragmenterScenario"

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

# Here, you can provide .ned files or directories containing .ned files. All
# these files will be copied into a new directory and transfered to the remote
# processing PEs. A corresponding nedfiles.lst will be written and also
# transferred to the PE.
# Examples: simCreatorNEDFiles  <- "."
#           simCreatorNEDFiles  <- "../alpha/nedfiles ../beta/nedfiles"
simCreatorNEDFiles  <- "."

# Here, you can provide additional files for packaging, e.g. "my-nedfile.ned".
# You may even use a pattern, e.g. "Test*.ned".
simulationMiscFiles <- ""



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
           "cyan4",
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

   list("sink.MeanPacketDelay",
           "Mean Packet Delay[ms]",
           "data1$sink.MeanPacketDelay * 1000.0",
           "blue4",
           list("sink-MeanPacketDelay")),
   list("sink.MeanPacketLength",
           "Mean Packet Length[Bytes]",
           "data1$sink.MeanPacketLength * 1000.0",
           "gold4",
           list("sink-MeanPacketLength")),
   list("sink.MeanPacketInterarrivalTime",
           "Mean Packet InterarrivalTime[ms]",
           "data1$sink.MeanPacketInterarrivalTime * 1000.0",
           "magenta4",
           list("sink-MeanPacketInterarrivalTime"))
)


# NewParam: Finally, add the new parameter to your default simulation configuration.

demoDefaultSimulationConfiguration <- list(
   # ------ Scenario Settings -----------------------------------------------
   list("cellPayloadSize", 128),
   list("cellHeaderSize", 4),
   list("intermediateNodeOutputRate", 150000),
   list("sourceInterarrivalTime", 0.1),
   list("sourcePayloadSize", 1000),
   list("sourceHeaderSize", 20)
)
