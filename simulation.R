# $Id$
# ###########################################################################
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2009 Thomas Dreibholz
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


source("hashfunctions.R")
source("plotter.R")


simulationDirectory <- "GiveAUsefulName"
simulationRuns <- 1
simulationDuration <- 60
simulationStoreVectors <- FALSE
simulationExecuteMake <- TRUE
simulationScriptOutputVerbosity <- 8
simulationSummaryCompressionLevel <- 9
simulationSummarySkipList <- c()

# The sources directory of the simulation.
simCreatorSourcesDirectory <- "GiveAUsefulName"

# The simulation binary.
# NOTE: The path here is relative to the directory set in sourcesDirectory!
simCreatorSimulationBinary <- "GiveAUsefulName"

# The directory where the binary should be executed.
# NOTE: The path here is relative to the directory set in sourcesDirectory!
simCreatorSimulationBaseDir <- "GiveAUsefulName"

# A list of directories to be recursively searched for NED files. These NED
# files will be copied into the environment directory.
# NOTE: The paths here are relative to the directory set in sourcesDirectory!
# Example: list("src", "examples/sctp")
simCreatorNEDFiles <- list("")

# A list of directories to be recursively searched for misc files. These misc
# files will be copied into the environment directory.
# NOTE: The paths here are relative to the directory set in sourcesDirectory!
# Example: list(c("*.mrt", "examples/sctp/cmttest1"))
simCreatorMiscFiles <- list()

# The simulation network to be loaded.
simCreatorSimulationNetwork <- "giveANetworkName"

distributionPool  <- "ScriptingPool"
distributionProcs <- 0   # Set to 0 for to disable distribution!
distributionPUOpt <- ""


# IMPORTANT NOTICE:
# In order to add new simulation parameters, look for the comments marked
# with "NewParam:"!


# ###########################################################################
# #### Simulation Toolkit                                                ####
# ###########################################################################


# ====== Run external program ===============================================
execute <- function(cmd)
{
   r <- readLines(pc <- pipe(cmd))
   # cat(r)
   close(pc)
}


# ====== Get number of CPUs by reading /proc/cpuinfo ========================
getNumberOfCPUs <- function()
{
   command <- paste(sep="", "cat /proc/cpuinfo 2>/dev/null|grep \"^processor\"|wc --lines")
   answerLine <- readLines(pc <- pipe(command))
   close(pc)
   cpus <- as.numeric(answerLine)
   if(cpus < 1) {
      cpus <- 1
   }
   return(cpus)
}


# ====== Check existence of global variable (given as name string) ==========
existsGlobalVariable <- function(variable)
{
   globalEnv <- sys.frame()
   return(exists(variable, envir=globalEnv))
}


# ====== Get value of global variable (given as name string) ================
getGlobalVariable <- function(variable)
{
   globalEnv <- sys.frame()
   return(get(variable, env=globalEnv))
}


# ====== Set global variable (given as name string) to given value ==========
setGlobalVariable <- function(variable, value)
{
   globalEnv <- sys.frame()
   assign(variable, value, envir=globalEnv)
}


# ====== Get total number of simulation runs ================================
getTotalSimulationRuns <- function(simulationConfigurations)
{
   if(length(simulationConfigurations) > 0) {
      if(is.list(simulationRuns)) {
         runs <- length(unique(unlist(simulationRuns)))
      }
      else {
         runs <- simulationRuns
      }
      for(parameterConfiguration in simulationConfigurations) {
         parameters <- length(parameterConfiguration) - 1
         if(parameters > 0) {
            runs <- runs * parameters
         }
      }
   }
   else {
      runs <- 0
   }
   return(runs)
}


# ====== Create all simulation runs =========================================
GAVType_VariableNames  <- 1
GAVType_VariableValues <- 2
GAVType_Hash           <- 3
getActiveVariables <- function(simulationConfigurations, type, duration=0)
{
   resultSet <- c()
   if((type == GAVType_VariableNames) || (type == GAVType_Hash)) {
      resultSet <- append(resultSet, c("simulationDuration"))
   }
   if((type == GAVType_VariableValues) || (type == GAVType_Hash)) {
      resultSet <- append(resultSet, c(duration))
   }

   # ------ Get a parameter configuration -----------------------------------
   for(i in 1:length(simulationConfigurations)) {
      parameterConfiguration <- unlist(simulationConfigurations[i], recursive=FALSE)

      parameterName <- as.character(parameterConfiguration[1])
      parameterValueSet <- parameterConfiguration[2:length(parameterConfiguration)]
      parameters <- length(parameterValueSet)

      isAdditionalActive <- FALSE
      if(parameters == 1) {
         # Variable is not active, but should be recorded anyway.
         for(v in simCreatorAdditionalActiveVariables) {
            if(parameterName == v) {
               isAdditionalActive <- TRUE
               break
            }
         }
      }

      if((type == GAVType_Hash) || (parameters != 1) || (isAdditionalActive)) {
         if((type == GAVType_VariableNames) || (type == GAVType_Hash)) {
            resultSet <- append(resultSet, c(parameterName))
         }
         if((type == GAVType_VariableValues) || (type == GAVType_Hash)) {
            resultSet <- append(resultSet, c(getGlobalVariable(parameterName)))
         }
      }
   }

   # ------ Compute hash of setup -------------------------------------------
   if(type == GAVType_Hash) {
      string <- ""
      for(item in resultSet) {
         string <- paste(sep="", string, "-", item)
      }
      return(getSHA1SumOfString(string))
   }

   return(resultSet)
}


# ------ Check if variable is active ----------------------------------------
CVT_Any     <- 0
CVT_Active  <- 1
CVT_Passive <- 2
CVT_Auto    <- 3
checkVariableType <- function(simulationConfigurations, variable, type)
{
   for(i in 1:length(simulationConfigurations)) {
      parameterConfiguration <- unlist(simulationConfigurations[i], recursive=FALSE)

      parameterName <- parameterConfiguration[1]
      if(parameterName == variable) {
         parameters <- length(parameterConfiguration) - 1
         if(type == CVT_Auto) {
            if(parameters == 0) {
               return(TRUE)
            }
         }
         else if(type == CVT_Active) {
            if(parameters > 1) {
               return(TRUE)
            }
         }
         else if(type == CVT_Passive) {
            if(parameters == 0) {
               return(TRUE)
            }
         }
         else {
            return(TRUE)
         }
      }
   }
   return(FALSE)
}


# ====== Prepare simulation directory =======================================
prepareDirectory <- function(simulationDirectory)
{
   setGlobalVariable("gSimulationDirectoryName", simulationDirectory)
   dir.create(simulationDirectory, showWarnings=FALSE)
   setGlobalVariable("gResultsDirectoryName", paste(sep="", simulationDirectory, "/", "Results"))
   dir.create(getGlobalVariable("gResultsDirectoryName"), showWarnings=FALSE)
   setGlobalVariable("gSimulationsDirectoryName", paste(sep="", simulationDirectory, "/", "Simulations"))
   dir.create(getGlobalVariable("gSimulationsDirectoryName"), showWarnings=FALSE)

   setGlobalVariable("gMakefileName", paste(sep="", simulationDirectory, "/", "Makefile"))
   setGlobalVariable("gSummaryName", paste(sep="", simulationDirectory, "/", "summary.input"))
   setGlobalVariable("gSummaryCompletedName", paste(sep="", simulationDirectory, "/", "summary-completed.txt"))
   setGlobalVariable("gSimulationsCompletedName", paste(sep="", simulationDirectory, "/", "simulations-completed.txt"))
   setGlobalVariable("gResultsArchiveName", paste(sep="", simulationDirectory, "/", simulationDirectory, ".tar.bz2"))
   setGlobalVariable("gRuntimeName", paste(sep="", simulationDirectory, "/", "runtime.dat"))
   setGlobalVariable("gLogfileName", paste(sep="", simulationDirectory, "/", "make.log"))
}


# ====== Start creating makefile ============================================
beginMakefile <- function()
{
   makefile <- file(getGlobalVariable("gMakefileName"), "w")

   cat(sep="", ".PHONY:\tall\n", file=makefile)
   cat(sep="", "all:\t", getGlobalVariable("gSummaryCompletedName"), "\n\n", file=makefile)
   cat(sep="", ".PHONY:\tsimulations-only\n", file=makefile)
   cat(sep="", "simulations-only:\t", getGlobalVariable("gSimulationsCompletedName"), "\n\n", file=makefile)

   cat(sep="", "# ===========================================================================\n\n", file=makefile)

   return(makefile)
}


# ====== Add run to makefile ================================================
addRunToMakefile <- function(makefile, runNumber, runDirectoryName, statusName)
{
   cat(sep="", statusName, ":\t", simulationDirectory, "/simulation-environment.tar.bz2 ", getGlobalVariable("gRuntimeName"), "\n", file=makefile)
   if(distributionProcs < 1) {
      cat(sep="", "\t./perform-run ", simulationDirectory, " ", runDirectoryName, " ", runNumber, "\n", file=makefile)
   }
   else {
      cat(sep="", "\t./perform-run ", simulationDirectory, " ", runDirectoryName, " ", runNumber, " \"", distributionPool, "\" \"", distributionPUOpt, "\"\n", file=makefile)
   }
   cat(sep="", "\ttools/runtimeestimator ", getGlobalVariable("gRuntimeName"), " ", getGlobalVariable("gTotalSimulationRuns"), " ", getGlobalVariable("gRunNumber"), "\n", file=makefile)
   cat(sep="", "\n", file=makefile)
}


# ====== Start creation of summary file =====================================
beginSummary <- function()
{
   setGlobalVariable("gSimulationDependencies", "")

   summary <- file(getGlobalVariable("gSummaryName"), "w")
   cat(sep="", "--simulationsdirectory=", getGlobalVariable("gResultsDirectoryName"), "\n", file=summary)
   cat(sep="", "--resultsdirectory=", getGlobalVariable("gResultsDirectoryName"), "\n", file=summary)
   for(skipEntry in simulationSummarySkipList) {
      cat(sep="", "--skip=", skipEntry, "\n", file=summary)
   }
   return(summary)
}


# ====== Add run to summary file ============================================
addRunToSummary <- function(summary, scalarName, iniName, logName, statusName, varValues)
{
   varValuesString <- ""
   for(value in varValues) {
      # ------ Encapsulate arguments containing spaces ----------------------
      valueString <- paste(sep="", value)
      if(length(grep(" ", valueString)) > 0) {
         valueString <- paste(sep="", "\"", valueString , "\"")
      }

      # ------ Write output string ------------------------------------------
      if(varValuesString != "") {
         varValuesString <- paste(sep="", varValuesString, " ", valueString)
      }
      else {
         varValuesString <- valueString
      }
   }

   cat(sep="", "--values=\"", varValuesString, " \"", iniName, "\"\"\n", file=summary)
   cat(sep="", "--statusfile=", statusName, "\n", file=summary)
   cat(sep="", "--logfile=", logName, "\n", file=summary)
   cat(sep="", "--input=", scalarName, ".bz2\n", file=summary)
}


# ====== Finish creation of summary file ====================================
finishSummary <- function(summary)
{
   close(summary)

   # ------ Create table head with active variables -------------------------
   activeVariablesString <- ""
   activeVariables       <- getGlobalVariable("gActiveVariables")
   for(variable in activeVariables) {
      if(activeVariablesString != "") {
         activeVariablesString <- paste(sep="", activeVariablesString, " ", variable)
      }
      else {
         activeVariablesString <- variable
      }
   }

   # ------ Create summary command string -----------------------------------
   summaryName <- paste(sep="", getGlobalVariable("gSummaryName"))
   summaryCommand <- paste(sep="",
                           "rm -rf ", getGlobalVariable("gResultsDirectoryName"), " && ",
                           "mkdir ", getGlobalVariable("gResultsDirectoryName"), " && ",
                           "tools/createsummary ",
                           "\"", activeVariablesString, " SourceINI\" ",
                           "-batch ",
                           "-compress=", simulationSummaryCompressionLevel, " ",
                           "<", getGlobalVariable("gSummaryName"))
   return(summaryCommand)
}


# ====== Finish creation of makefile ========================================
finishMakefile <- function(makefile, summaryCommand)
{
   cat(sep="", "# ===========================================================================\n\n", file=makefile)

   cat(sep="","tools/createsummary:\ttools/createsummary.cc\n", file=makefile)
   cat(sep="", "\tcd tools && $(MAKE) createsummary && cd ..\n\n", file=makefile)

   # ------ Simulation environment archive ----------------------------------
   cat(sep="", toupper(simCreatorSimulationBinary), "_SRCS=$(wildcard *.cc) $(wildcard *.c) $(wildcard *.h) $(wildcard *.msg) $(wildcard *.ned)\n", file=makefile)
   cat(sep="", simCreatorSimulationBinary, ":\t$(", toupper(simCreatorSimulationBinary), "_SRCS)\n", file=makefile)
   # cat(sep="", "\t( cd ", simCreatorSourcesDirectory, " && $(MAKE) MODE=release )\n\n", file=makefile)
   cat(sep="", "\t( cd ", simCreatorSourcesDirectory, " && $(MAKE) )\n\n", file=makefile)

   # ------ Simulation environment archive ----------------------------------
   cat(sep="", simulationDirectory, "/simulation-environment.tar.bz2:\t", simCreatorSimulationBinary, "\n", file=makefile)

   makeEnvParams <- ""
   for(n in simCreatorNEDFiles) {
      makeEnvParams <- paste(sep="", makeEnvParams, " -n ", n)
   }
   for(m in simCreatorMiscFiles) {
      makeEnvParams <- paste(sep="", makeEnvParams, " -misc \"", m[1], "\" ", m[2])
   }

   cat(sep="","\t./make-environment ", simulationDirectory, " ", simCreatorSourcesDirectory, " ", simCreatorSimulationBinary, " ", simCreatorSimulationBaseDir, " ", makeEnvParams, "\n", file=makefile)
   cat(sep="","\n", file=makefile)

   # ------ runtimeestimator ------------------------------------------------
   cat(sep="","tools/runtimeestimator:\n", file=makefile)
   cat(sep="", "\tcd tools && $(MAKE) runtimeestimator && cd ..\n\n", file=makefile)

   # ------ getrelativepath -------------------------------------------------
   cat(sep="","tools/getrelativepath:\n", file=makefile)
   cat(sep="", "\tcd tools && $(MAKE) getrelativepath && cd ..\n\n", file=makefile)

   # ------ First run of runtimeestimator -----------------------------------
   cat(sep="", getGlobalVariable("gRuntimeName"), ":\n", file=makefile)
   cat(sep="", "\ttools/runtimeestimator ",
               getGlobalVariable("gRuntimeName"), " ",
               getGlobalVariable("gTotalSimulationRuns"),
               " 0\n\n", file=makefile)

   # ------ Completion of simulation runs -----------------------------------
   cat(sep="", getGlobalVariable("gSimulationsCompletedName"), ":\t", simCreatorSimulationBinary, " ", simulationDirectory, "/simulation-environment.tar.bz2 tools/runtimeestimator tools/getrelativepath ", getGlobalVariable("gRuntimeName"), "   ", getGlobalVariable("gSimulationDependencies"), "\n", file=makefile)
   cat(sep="", "\tdate >", getGlobalVariable("gSimulationsCompletedName"), "\n", file=makefile)
   cat(sep="", "\techo \"Simulation completed!\"\n\n", file=makefile)

   # ------ Summary creation ------------------------------------------------
   cat(sep="", getGlobalVariable("gSummaryCompletedName"), ":\ttools/createsummary ", getGlobalVariable("gSimulationsCompletedName"), "\n", file=makefile)
   cat(sep="", "\tstartTime=`date`      &&      ", file=makefile)
   cat(sep="", summaryCommand, "      &&      ", file=makefile)
   cat(sep="", "endTime=`date`      &&      ", file=makefile)
   cat(sep="", "echo \"Start: $$startTime\" >", getGlobalVariable("gSimulationsCompletedName"), " && ", file=makefile)
   cat(sep="", "echo \"End:   $$endTime\" >>", getGlobalVariable("gSimulationsCompletedName"), "\n", file=makefile)
   cat(sep="", "\t@echo \"Summary completed!\"\n\n", file=makefile)

   # ------ Archival of results ---------------------------------------------
   cat(sep="", getGlobalVariable("gResultsArchiveName"), ":\t", getGlobalVariable("gSimulationsCompletedName"), "\n", file=makefile)
   cat(sep="", "\tcd ", getGlobalVariable("gSimulationDirectoryName"), "/Results && tar cvf - *.data* | bzip2 >../", getGlobalVariable("gSimulationDirectoryName"), ".tar.bz2\n\n", file=makefile)

   # ------ Simulations only ------------------------------------------------
   cat(sep="", ".PHONY:\tclean-simulations-only\n", file=makefile)
   cat(sep="", "clean-simulations-only:\n", file=makefile)
   cat(sep="", "\tfind ", getGlobalVariable("gSimulationDirectoryName"),"/ -name \"*-output.txt*\" -or -name \"*-scalars.sca*\" -or -name \"*-vectors.vec*\" -or -name \"*-status.txt*\" | xargs -n64 rm -f\n", file=makefile)
   cat(sep="", "\trm -f ", getGlobalVariable("gLogfileName"), "\n", file=makefile)
   cat(sep="", "\techo \"Simulations-only clean-up completed!\"\n\n", file=makefile)

   # ------ Clean-up --------------------------------------------------------
   cat(sep="", ".PHONY:\tclean-simulations-and-results\n", file=makefile)
   cat(sep="", "clean-simulations-and-results:\tclean-simulations-only\n", file=makefile)
   cat(sep="", "\tfind ", getGlobalVariable("gSimulationDirectoryName"),"/Results/ -name \"*.data*\" | xargs -n64 rm -f\n", file=makefile)
   cat(sep="", "\trm -f ", getGlobalVariable("gSimulationsCompletedName"), " ", getGlobalVariable("gSummaryCompletedName"), " ", getGlobalVariable("gRuntimeName"), "\n", file=makefile)
   cat(sep="", "\techo \"Full clean-up completed!\"\n\n", file=makefile)

   # ------ Clean-up including removal of archived results ------------------
   cat(sep="", ".PHONY:\tdistclean\n", file=makefile)
   cat(sep="", "distclean:\tclean-simulations-and-results\n", file=makefile)
   cat(sep="", "\trm -f ", getGlobalVariable("gResultsArchiveName"), "\n\n", file=makefile)

   close(makefile)


   # ------ Removal of old output files -------------------------------------
   cmd <- paste(sep="", "find ", getGlobalVariable("gSimulationDirectoryName"), "/Simulations/ -name \"*.txt\" | xargs -n64 touch >/dev/null 2>/dev/null")
   r <- readLines(pc <- pipe(cmd))
   close(pc)
}


# ====== Execute make =======================================================
executeMake <- function()
{
   startTime <- Sys.time()

   CPUs <- getNumberOfCPUs()
   if(exists("distributionPool") && (distributionPool != "") &&
      exists("distributionProcs") && (distributionProcs > 0)) {
      CPUs <- distributionProcs
   }

   if(simulationScriptOutputVerbosity > 0) {
      cat(sep="", "* Step #4: Running make...\n")
      if(exists("distributionPool") && (distributionPool != "") &&
         exists("distributionProcs") && (distributionProcs > 0)) {
         cat(sep="", "   - Distribution to pool \"", distributionPool, "\", ", CPUs , " processes\n")
      }
      cat(sep="", "   - To start make:   make -j" , CPUs, " -f ", getGlobalVariable("gMakefileName"), "\n")
      cat(sep="", "   - To view logfile: tail -f ", getGlobalVariable("gLogfileName"), "\n")
      cat(paste(sep="", "   - Sim. Start = ", startTime, "\n"))
   }
   cmd <- paste(sep="", " if [ -e Makefile ] ; then make MODE=release ", simCreatorSimulationBinary, " ; fi && cd tools && make runtimeestimator && cd .. && make -j" ,
                CPUs,
                " -f ", getGlobalVariable("gMakefileName"),
                " all >", getGlobalVariable("gLogfileName"))

   # ------ Execute make ----------------------------------------------------
   r <- readLines(pc <- pipe(cmd))
   close(pc)
   stopTime <- Sys.time()

   if(simulationScriptOutputVerbosity > 0) {
      cat(paste(sep="", "   - Sim. Stop  = ", stopTime, "\n"))
      cat(sep="", "   - Runtime    = ",
          signif(as.double(difftime(stopTime, startTime, units="min")),2), "min\n")
   }
}


# ====== Create all simulation runs =========================================
createAllSimulationRuns <- function(simulationConfigurations,
                                    originalSimulationConfigurations,
                                    makefile, summary, originalSetup=c())
{
   # ------ Get a parameter configuration -----------------------------------
   # Example: parameterConfiguration <- c("Parameter Name", "Value 1", ...)
   parameterConfiguration <- unlist(simulationConfigurations[1])
   parameterName <- parameterConfiguration[1]
   if(length(parameterConfiguration) > 1) {
      parameterValueSet <- parameterConfiguration[2:length(parameterConfiguration)]
   }
   else {
      parameterValueSet <- NA   # Parameter value is calculated later!
   }

   # ------ Create a run for each parameter setting -------------------------
   for(parameterValue in parameterValueSet) {
      setup <- append(originalSetup, c(parameterName, parameterValue))

      # ------ Handle next parameter, if there are more ---------------------
      if(length(simulationConfigurations) > 1) {
         createAllSimulationRuns(simulationConfigurations[2:length(simulationConfigurations)],
                                 originalSimulationConfigurations,
                                 makefile, summary, setup)
      }

      # ------ All settings have been collected. Create a new run -----------
      else {
         # ------ Set all variables -----------------------------------------
         if(is.list(simulationRuns)) {
            mySimulationRuns <- length(unlist(simulationRuns))
         }
         else {
            mySimulationRuns <- simulationRuns
         }
         if(simulationScriptOutputVerbosity > 4) {
            cat(sprintf(" + Runs %d-%d of %d:   ",
                        getGlobalVariable("gRunNumber"),
                        getGlobalVariable("gRunNumber") + mySimulationRuns - 1,
                        getGlobalVariable("gTotalSimulationRuns")))
         }
         for(i in seq(1, length(setup)-1, 2)) {
            setGlobalVariable(setup[i], setup[i+1])
         }

         # ------ Obtain duration (may be a function) -----------------------
         if(is.function(simulationDuration)) {
            duration <- 60 * simulationDuration()
         }
         else {
            duration <- 60 * simulationDuration
         }

         # ------ Get variables and *original* values -----------------------
         varNames  <- getGlobalVariable("gActiveVariables")
         origVarValues <- getActiveVariables(originalSimulationConfigurations, GAVType_VariableValues, duration)

         # ------ Compute auto-parameters -----------------------------------
         if(simCreatorAutoParameters(originalSimulationConfigurations)) {

            # ------ Get *updated* values and hash --------------------------
            varValues <- getActiveVariables(originalSimulationConfigurations, GAVType_VariableValues, duration)
            setupHash <- getActiveVariables(originalSimulationConfigurations, GAVType_Hash, duration)
            for(i in 1:length(varNames)) {
               variable <- varNames[i]
               value    <- varValues[i]
               if(is.na(value)) {
                  cat("\n")
                  stop(paste(sep="", "ERROR: Auto-Variable ", variable, " is not set!\n",
                           "               Check simulation configuration and auto-parameter function!"))
               }
            }

            # ------ Debug output ----------------------------------------------
            if(simulationScriptOutputVerbosity > 4) {
               for(i in 1:length(varNames)) {
                  variable  <- varNames[i]
                  value     <- varValues[i]
                  origValue <- origVarValues[i]
                  cat(sep="", variable, "=")
                  if((!is.na(origValue)) && (value == origValue)) {
                     cat(sep="", value)
                  }
                  else {
                     cat(sep="", value, "(", origValue, ")")
                  }
                  cat("   ")
               }
               cat("\n")
            }

            # ------ Create runs --------------------------------------------
            runDirectoryName <- paste(sep="", getGlobalVariable("gSimulationsDirectoryName"), "/",
                                      "Set-", setupHash)
            dir.create(runDirectoryName, showWarnings=FALSE)

            if(is.list(simulationRuns)) {
               runsSet <- unique(unlist(simulationRuns))
            }
            else {
               runsSet <- seq(1, simulationRuns)
            }
            for(simulationRun in runsSet) {
               filePrefix <- paste(sep="", runDirectoryName, "/run", simulationRun)
               outputName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-output.txt")
               iniName    <- paste(sep="", runDirectoryName, "/run", simulationRun, "-parameters.ini")
               scalarName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-scalars.sca")
               vectorName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-vectors.vec")
               statusName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-status.txt")

               ini <- file(iniName, "w")
               simCreatorWriteHeader(ini, simulationRun, scalarName, vectorName, duration)
               simCreatorWriteParameterSection(filePrefix, ini, simulationRun, duration)
               close(ini)

               addRunToSummary(summary, scalarName, iniName, outputName, statusName, varValues)
               addRunToMakefile(makefile, simulationRun, runDirectoryName, statusName)

               setGlobalVariable("gRunNumber", getGlobalVariable("gRunNumber") + 1)
               setGlobalVariable("gSimulationDependencies",
                                 append(getGlobalVariable("gSimulationDependencies"), c(" ", statusName)))
            }
         }
         else {
            if(simulationScriptOutputVerbosity > 4) {
               cat(sep="","SKIPPING!\n")
            }
         }
      }
   }
}


# ====== Reronciliate configuration and default settings ====================
makeSimulations <- function(configuration, defaults)
{
   results <- list()

   # ====== Replace all defaults by new configurations ======================
   for(i in 1:length(defaults)) {
      defaultConfigItem <- unlist(defaults[i], recursive=FALSE)
      override <- FALSE
      for(j in 1:length(configuration)) {
         configItem <- unlist(configuration[j], recursive=FALSE)
         # ====== Replace default setting ===================================
         if(as.character(configItem[1]) == as.character(defaultConfigItem[1])) {
            # cat("Override default: ",as.character(defaultConfigItem[1]),"\n")
            results <- append(results, configuration[j])
            override <- TRUE
            break
         }
      }
      # ====== Keep default setting, since no new value has been set ========
      if(!override) {
         results <- append(results, defaults[i])
      }
   }

   # ====== Cross-check: for each value, there should be a default value ====
   for(j in 1:length(configuration)) {
      configItem <- unlist(configuration[j], recursive=FALSE)
      found <- FALSE
      for(i in 1:length(defaults)) {
         defaultConfigItem <- unlist(defaults[i], recursive=FALSE)
         if(as.character(configItem[1]) == as.character(defaultConfigItem[1])) {
            found <- TRUE
            break
         }
      }
      if(!found) {
         stop(paste(sep="", "ERROR: There is no default setting for parameter ",
                     as.character(configItem[1]), "!\n         ",
                     "This is either a typo or the simulation generator script has to be updated!"))
      }
   }

   return(results)
}


# ====== Create simulation ==================================================
createSimulation <- function(simulationDirectory, simulationConfigurations, simulationDefaults)
{
   simulationConfigurations <- makeSimulations(simulationConfigurations, simulationDefaults)

   # ------ Initialize ------------------------------------------------------
   setGlobalVariable("gRunNumber", 1)
   setGlobalVariable("gTotalSimulationRuns",
                     getTotalSimulationRuns(simulationConfigurations))
   setGlobalVariable("gActiveVariables",
                     getActiveVariables(simulationConfigurations, GAVType_VariableNames))

   # ------ Directory preparation -------------------------------------------
   if(simulationScriptOutputVerbosity > 0) {
      cat(sep="", "* Step #1: Preparing directory ", simulationDirectory, " ...\n")
   }
   prepareDirectory(simulationDirectory)
   makefile <- beginMakefile()
   summary <- beginSummary()

   # ------ Input file creation ---------------------------------------------
   if(simulationScriptOutputVerbosity > 0) {
      cat(sep="", "* Step #2: Creating input files for ",
                  getGlobalVariable("gTotalSimulationRuns"), " runs ...\n")
      cat(sep="",   " + Active variables:\n")
      for(varName in getGlobalVariable("gActiveVariables")) {
         cat(sep="", "  @ ", varName, "\n")
      }
   }
   createAllSimulationRuns(simulationConfigurations, simulationConfigurations, makefile, summary)

   # ------ Finish summary and makefile -------------------------------------
   cat(sep="", "* Step #3: Writing summary script and makefile ...\n")
   summaryCommand <- finishSummary(summary)
   finishMakefile(makefile, summaryCommand)
   if(simulationExecuteMake) {
     executeMake()
   }
   cat(sep="", "* Script completed!\n")
}
