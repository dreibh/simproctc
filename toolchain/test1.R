# ###########################################################################
#                   A Very Simple Example Simulation for
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2025 Thomas Dreibholz
#
#               Author: Thomas Dreibholz, thomas.dreibholz@gmail.com
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
# Contact: thomas.dreibholz@gmail.com


source("simulate-version1.R")

# ------ Simulation Settings ------------------------------------------------
simulationScriptOutputVerbosity <- 8
simulationDirectory <- "test1"
simulationDuration <- 1
simulationRuns <- 1
simulationStoreVectors <- FALSE
simulationExecuteMake <- TRUE
simulationSummaryCompressionLevel <- 5
simulationSummarySkipList <- c()
# -------------------------------------
distributionPool  <- "ScriptingPool"
distributionProcs <- 0    # Set to 0 for to disable distribution!
distributionPUOpt <- ""   # Add misc options for ScriptingPU here.
# Jabber addess to report simulation startup/completion to
# NOTE: sendxmpp is needed to send Jabber messages!
reportTo <- ""
# -------------------------------------

# ###########################################################################

simulationConfigurations <- list(
   # ------ Scenario Settings -----------------------------------------------
   list("cellPayloadSize", 4, 8, 16, 32, 64, 96, 128, 192, 256, 320, 384),
   list("cellHeaderSize", 4),
   list("intermediateNodeOutputRate", 150000),
   list("sourceInterarrivalTime", 0.1),
   list("sourcePayloadSize", 1000, 2500),
   list("sourceHeaderSize", 20)
)

# ###########################################################################

createSimulation(simulationDirectory, simulationConfigurations, demoDefaultSimulationConfiguration)
