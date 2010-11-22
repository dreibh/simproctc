# $Id$
# ###########################################################################
#                   A Very Simple Example Simulation for
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2010 Thomas Dreibholz
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


source("simulate-version1.R")

# ------ Plotter Settings ---------------------------------------------------
simulationDirectory  <- "test1"
plotColorMode        <- cmColor
plotHideLegend       <- FALSE
plotLegendSizeFactor <- 0.8
plotOwnOutput        <- FALSE
plotFontFamily       <- "Helvetica"
plotFontPointsize    <- 22
plotWidth            <- 10
plotHeight           <- 10
plotConfidence       <- 0.95

# ###########################################################################

# ------ Plots --------------------------------------------------------------
plotConfigurations <- list(
   # ------ Format example --------------------------------------------------
   # list(simulationDirectory, "output.pdf",
   #      "Plot Title",
   #      list(xAxisTicks) or NA, list(yAxisTicks) or NA, list(legendPos) or NA,
   #      "x-Axis Variable", "y-Axis Variable",
   #      "z-Axis Variable", "v-Axis Variable", "w-Axis Variable",
   #      "a-Axis Variable", "b-Axis Variable", "p-Axis Variable")
   # ------------------------------------------------------------------------

   list(simulationDirectory, paste(sep="", simulationDirectory, "-MeanPacketDelay.pdf"),
        "Mean Packet Delay at Sinks", NA, NA, list(0.5,0.75),
        "cellPayloadSize", "sink.MeanPacketDelay",
        "sink", "sourcePayloadSize", "cellHeaderSize"),
   list(simulationDirectory, paste(sep="", simulationDirectory, "-MeanPacketLength.pdf"),
        "Mean Packet Length at Sinks", NA, NA, list(0.5,0.5),
        "cellPayloadSize", "sink.MeanPacketLength",
        "sink", "sourcePayloadSize", "cellHeaderSize"),
   list(simulationDirectory, paste(sep="", simulationDirectory, "-MeanPacketInterarrivalTime.pdf"),
        "Mean Packet Interarrival Time at Sinks", NA, NA, list(0,1),
        "cellPayloadSize", "sink.MeanPacketInterarrivalTime",
        "sink", "sourcePayloadSize", "cellHeaderSize"),

   list(simulationDirectory, paste(sep="", simulationDirectory, "-Overhead3.pdf"),
        "Overhead Added by Fragmenter", NA, list(seq(0, 100, 20)), list(0.5,1),
        "cellPayloadSize", "fragmenter.AddedOverhead",
        "sourcePayloadSize", "cellHeaderSize", ""),
   list(simulationDirectory, paste(sep="", simulationDirectory, "-Overhead.pdf"),
        "Overhead to Payload Ratio", NA, list(seq(0, 100, 20)), list(0.5,1),
        "cellPayloadSize", "fragmenter.OverheadToPayloadRatio",
        "sourcePayloadSize", "cellHeaderSize", ""),

   list(simulationDirectory, paste(sep="", simulationDirectory, "-Overhead1.pdf"),
        "Transmitted Payload", NA, NA, list(1,0.5),
        "cellPayloadSize", "fragmenter.TotalPayload",
        "sourcePayloadSize", "cellHeaderSize", ""),
   list(simulationDirectory, paste(sep="", simulationDirectory, "-Overhead2.pdf"),
        "Transmitted Fragmenter Overhead", NA, NA, list(1,0.5),
        "cellPayloadSize", "fragmenter.TotalOverhead",
        "sourcePayloadSize", "cellHeaderSize", "")
)


# ------ Variable templates -------------------------------------------------
plotVariables <- append(list(
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

   # list("controller.SystemAverageUtilization",
   #         "Average Utilization[%]",
   #         "100.0 * data1$controller.SystemAverageUtilization",
   #         "blue4",
   #         list("controller-SystemAverageUtilization"))

), demoPlotVariables)

# ###########################################################################

createPlots(simulationDirectory, plotConfigurations)
