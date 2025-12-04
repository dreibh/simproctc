# ###########################################################################
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2026 Thomas Dreibholz
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


source("hashfunctions.R")
source("plotter.R")


simulationDirectory <- "GiveAUsefulName"
simulationRuns <- 1
simulationDuration <- 60   # in minutes!
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

reportTo <- ""   # Jabber addess to report simulation startup/completion to
                 # NOTE: sendxmpp is needed to send Jabber messages!

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


# ====== Get total number of simulation run levels ==========================
getTotalSimulationRunLevels <- function(simulationConfigurations)
{
   if(is.list(simulationRuns)) {
      levels <- length(unique(unlist(simulationRuns)))
   }
   else {
      levels <- simulationRuns
   }
   return(levels)
}


# ====== Get total number of simulation runs per level ======================
getTotalSimulationRunsPerLevel <- function(simulationConfigurations)
{
   runs <- 1
   if(length(simulationConfigurations) > 0) {
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


# ====== Decide whether to include or skip run (can be replaced by user) ====
simulationIncludeOrSkip <- function(simulationConfigurations)
{
   # Default: include all
   return(TRUE)
}


# ====== Prepare simulation directory =======================================
prepareDirectory <- function(simulationDirectory)
{
   setGlobalVariable("gSimulationDirectoryName", simulationDirectory)
   dir.create(simulationDirectory, showWarnings=FALSE)
   setGlobalVariable("gResultsDirectoryName", paste(sep="", simulationDirectory, "/", "Results"))
   dir.create(gResultsDirectoryName, showWarnings=FALSE)
   setGlobalVariable("gTempDirectoryName", paste(sep="", simulationDirectory, "/", "Temp"))
   dir.create(gTempDirectoryName, showWarnings=FALSE)
   setGlobalVariable("gSimulationsDirectoryName", paste(sep="", simulationDirectory, "/", "Simulations"))
   dir.create(gSimulationsDirectoryName, showWarnings=FALSE)

   setGlobalVariable("gMakefileName", paste(sep="", simulationDirectory, "/", "Makefile"))
   setGlobalVariable("gDependenciesName", paste(sep="", simulationDirectory, "/", "dependencies.list"))
   setGlobalVariable("gSummaryName", paste(sep="", simulationDirectory, "/", "summary.input"))
   setGlobalVariable("gSummaryCompletedName", paste(sep="", simulationDirectory, "/", "summary-completed.txt"))
   setGlobalVariable("gSimulationsCompletedName", paste(sep="", simulationDirectory, "/", "simulations-completed.txt"))
   setGlobalVariable("gResultsArchiveName", paste(sep="", simulationDirectory, "/", simulationDirectory, ".tar.bz2"))
   setGlobalVariable("gRuntimeName", paste(sep="", simulationDirectory, "/", "runtime.dat"))
   setGlobalVariable("gLogfileName", paste(sep="", simulationDirectory, "/", "make.log"))
   setGlobalVariable("gErrorName",   paste(sep="", simulationDirectory, "/", "error.out"))
}


# ====== Start creating makefile ============================================
beginMakefile <- function()
{
   makefile <- file(gMakefileName, "w")

   cat(sep="", ".PHONY:\tall\n", file=makefile)
   cat(sep="", "all:\t", gSummaryCompletedName, "\n\n", file=makefile)
   cat(sep="", ".PHONY:\tsimulations-only\n", file=makefile)
   cat(sep="", "simulations-only:\t", gSimulationsCompletedName, "\n\n", file=makefile)

   cat(sep="", "# ===========================================================================\n\n", file=makefile)

   return(makefile)
}


# ====== Start creating status file dependencies ============================
beginDependencies <- function()
{
   dependencies <- file(gDependenciesName, "w")
   return(dependencies)
}


# ====== Add run to makefile ================================================
addRunToMakefile <- function(makefile, runNumber, runNumberInTotalRuns, totalRunLevels, runDirectoryName, shortcutLink, iniName, scalarName, vectorName, statusName, parameterString)
{
   cat(sep="", "# Parameters: ", parameterString, "\n", file=makefile)
   cat(sep="", "# INI file:   ", iniName, "\n", file=makefile)
   cat(sep="", "# Scalar:     ", scalarName, ".bz2\n", file=makefile)
   cat(sep="", "# Vector:     ", vectorName, ".bz2\n", file=makefile)
   cat(sep="", "# Shortcut:   ", shortcutLink, " -> ", runDirectoryName, "\n", file=makefile)
   cat(sep="", statusName, ":\t", simulationDirectory, "/simulation-environment.tar.bz2 ", gRuntimeName, "\n", file=makefile)
   if(distributionProcs < 1) {
      cat(sep="", "\t./perform-run ", simulationDirectory, " ", runDirectoryName, " ", runNumber, "\n", file=makefile)
   }
   else {
      cat(sep="", "\t./perform-run ", simulationDirectory, " ", runDirectoryName, " ", runNumber, " \"", distributionPool, "\" \"", distributionPUOpt, "\"\n", file=makefile)
   }
   cat(sep="", "\ttools/runtimeestimator ", gRuntimeName, " ", totalRunLevels, " ", runNumberInTotalRuns, "\n", file=makefile)
   cat(sep="", "\n", file=makefile)
}


# ====== Add status file dependency to Makefile =============================
addDependency <- function(dependencies, filePrefix)
{
   cat(sep="", filePrefix ,"\n", file=dependencies)
}


# ====== Get status file dependencies of Makefile ===========================
extractDependencies <- function(dependencies)
{
   close(dependencies)

   # Name Example: test1/Simulations/Set-2d4e51640b4524220cc2117face782770cbc9d59/run10-status.txt
   #  -> Sort by run number first, then set name
   r <- readLines(pc <- pipe(paste(sep="", "sort -t / -k 4.4n -k 2 ", gDependenciesName)))
   close(pc)

   return(paste(sep="", r, "-status.txt "))
}


# ====== Start creation of summary file =====================================
beginSummary <- function()
{
   summary <- file(gSummaryName, "w")
   cat(sep="", "--simulationsdirectory=", gResultsDirectoryName, "\n", file=summary)
   cat(sep="", "--resultsdirectory=", gResultsDirectoryName, "\n", file=summary)
   for(skipEntry in simulationSummarySkipList) {
      cat(sep="", "--skip=", skipEntry, "\n", file=summary)
   }
   return(summary)
}


# ====== Add run to summary file ============================================
addRunToSummary <- function(summary, scalarName, vectorName, iniName, logName, statusName, varValues)
{
   varValuesString <- ""
   for(value in varValues) {
      # ------ Encapsulate arguments containing spaces ----------------------
      valueString <- paste(sep="", value)
      if( (length(grep(" ", valueString)) > 0) ||
          (length(grep("\"", valueString)) > 0) ) {
         valueString <- paste(sep="", "'", valueString , "'")
      }
      else if(valueString == "") {
         valueString <- "\"\""   # empty string
      }
      # ------ Write output string ------------------------------------------
      if(varValuesString != "") {
         varValuesString <- paste(sep="", varValuesString, " ", valueString)
      }
      else {
         varValuesString <- valueString
      }
   }

   cat(sep="", "--values=\"", varValuesString, " \"", iniName, "\" \"", vectorName, ".bz2\"\"\n", file=summary)
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
   activeVariables       <- gActiveVariables
   for(variable in activeVariables) {
      if(activeVariablesString != "") {
         activeVariablesString <- paste(sep="", activeVariablesString, " ", variable)
      }
      else {
         activeVariablesString <- variable
      }
   }

   # ------ Create summary command string -----------------------------------
   summaryName <- gSummaryName
   summaryCommand <- paste(sep="",
                           "rm -rf ", gResultsDirectoryName, " && ",
                           "mkdir ", gResultsDirectoryName, " && ",
                           "tools/createsummary ",
                           "\"", activeVariablesString, " SourceINI SourceVec\" ",
                           "--batch --split ",
                           "--compress ", simulationSummaryCompressionLevel, " ",
                           "<", gSummaryName)
   return(summaryCommand)
}


# ====== Finish creation of makefile ========================================
finishMakefile <- function(makefile, dependencies, summaryCommand)
{
   cat(sep="", "# ===========================================================================\n\n", file=makefile)

   cat(sep="","tools/createsummary:\ttools/createsummary.cc\n", file=makefile)
   cat(sep="", "\tcd tools && $(MAKE) createsummary && cd ..\n\n", file=makefile)

   # ------ Simulation environment archive ----------------------------------
   cat(sep="", "simulation-binary:\n", file=makefile)
   cat(sep="", "\trm -rf ", gTempDirectoryName, "/*\n", file=makefile)
   if(reportTo != "") {
      poolingInfo <- " "
      if(distributionProcs > 0) {
         poolingInfo <- paste(sep="", ", distributing ", distributionProcs, " processes to pool \"", distributionPool, "\"")
      }
      cat(sep="", "\t( echo \"Starting simulation ", simulationDirectory, " on `hostname`", poolingInfo, " ...\" | sendxmpp --tls --interactive ", reportTo, " || true )\n", file=makefile)
   }
   cat(sep="", "\t( cd ", simCreatorSourcesDirectory, " && $(MAKE) )\n", file=makefile)
   cat(sep="", "\tif [ ! -e ", simCreatorSourcesDirectory, "/", simCreatorSimulationBinary, " ] ; then echo \"###### Did not find binary ", simCreatorSourcesDirectory, "/", simCreatorSimulationBinary, " -- Check your Makefile configuration (remove --make-so)! ######\" ; false ; fi\n\n", file=makefile)

   # ------ Simulation environment archive ----------------------------------
   cat(sep="", simulationDirectory, "/simulation-environment.tar.bz2:\tsimulation-binary tools/getrelativepath\n", file=makefile)

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
   cat(sep="", gRuntimeName, ":\ttools/runtimeestimator\n", file=makefile)
   cat(sep="", "\ttools/runtimeestimator ",
               gRuntimeName, " ",
               gTotalSimulationRunLevels * gTotalSimulationRunsPerLevel,
               " 0\n\n", file=makefile)

   # ------ Completion of simulation runs -----------------------------------
   cat(sep="", gSimulationsCompletedName, ":\tsimulation-binary ", simulationDirectory, "/simulation-environment.tar.bz2 tools/runtimeestimator tools/getrelativepath ", gRuntimeName, "   ", extractDependencies(dependencies), "\n", file=makefile)
   cat(sep="", "\trm -rf ", gTempDirectoryName, "/*\n", file=makefile)
   cat(sep="", "\tdate >", gSimulationsCompletedName, "\n", file=makefile)
   if(reportTo != "") {
      cat(sep="", "\t( echo \"Finished processing of runs for simulation ", simulationDirectory, " on `hostname`.\" | sendxmpp --tls --interactive ", reportTo, " || true )\n", file=makefile)
   }
   cat(sep="", "\techo \"Simulation completed!\"\n\n", file=makefile)

   # ------ Summary creation ------------------------------------------------
   cat(sep="", gSummaryCompletedName, ":\ttools/createsummary ", gSimulationsCompletedName, "\n", file=makefile)
   cat(sep="", "\tstartTime=`date`      &&      ", file=makefile)
   cat(sep="", summaryCommand, "      &&      ", file=makefile)
   cat(sep="", "endTime=`date`      &&      ", file=makefile)
   if(reportTo != "") {
      cat(sep="", "\t( echo \"Finished summary creation for simulation ", simulationDirectory, " on `hostname`.\" | sendxmpp --tls --interactive ", reportTo, " 2>/dev/null & ) && ", file=makefile)
   }
   cat(sep="", "echo \"Start: $$startTime\" >", gSimulationsCompletedName, " && ", file=makefile)
   cat(sep="", "echo \"End:   $$endTime\" >>", gSimulationsCompletedName, "\n", file=makefile)

   # ------ Archival of results ---------------------------------------------
   cat(sep="", gResultsArchiveName, ":\t", gSimulationsCompletedName, "\n", file=makefile)
   cat(sep="", "\tcd ", gSimulationDirectoryName, "/Results && tar cvf - *.data* | bzip2 >../", gSimulationDirectoryName, ".tar.bz2\n\n", file=makefile)

   # ------ Simulations only ------------------------------------------------
   cat(sep="", ".PHONY:\tclean-simulations-only\n", file=makefile)
   cat(sep="", "clean-simulations-only:\n", file=makefile)
   cat(sep="", "\tfind ", gSimulationDirectoryName,"/ -name \"*-output.txt*\" -or -name \"*-scalars.sca*\" -or -name \"*-vectors.vec*\" -or -name \"*-status.txt*\" | xargs -n64 rm -f\n", file=makefile)
   cat(sep="", "\trm -f ", gLogfileName, "\n", file=makefile)
   cat(sep="", "\techo \"Simulations-only clean-up completed!\"\n\n", file=makefile)

   # ------ Clean-up --------------------------------------------------------
   cat(sep="", ".PHONY:\tclean-simulations-and-results\n", file=makefile)
   cat(sep="", "clean-simulations-and-results:\tclean-simulations-only\n", file=makefile)
   cat(sep="", "\tfind ", gSimulationDirectoryName,"/Results/ -name \"*.data*\" | xargs -n64 rm -f\n", file=makefile)
   cat(sep="", "\trm -f ", gSimulationsCompletedName, " ", gSummaryCompletedName, " ", gRuntimeName, "\n", file=makefile)
   cat(sep="", "\techo \"Full clean-up completed!\"\n\n", file=makefile)

   # ------ Clean-up including removal of archived results ------------------
   cat(sep="", ".PHONY:\tdistclean\n", file=makefile)
   cat(sep="", "distclean:\tclean-simulations-and-results\n", file=makefile)
   cat(sep="", "\trm -f ", gResultsArchiveName, "\n\n", file=makefile)

   close(makefile)


   # ------ Removal of old output files -------------------------------------
   cmd <- paste(sep="", "find ", gSimulationDirectoryName, "/Simulations/ -name \"*.txt\" | xargs -n64 touch >/dev/null 2>/dev/null")
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
      cat(sep="", "* Step #4: Running make ...\n")
      if(exists("distributionPool") && (distributionPool != "") &&
         exists("distributionProcs") && (distributionProcs > 0)) {
         cat(sep="", "   - Distribution to pool \"", distributionPool, "\", ", CPUs , " processes\n")
      }
      cat(sep="", "   - To start make:   make -j" , CPUs, " -l -f ", gMakefileName, "\n")
      cat(sep="", "   - To view logfile: tail -f ", gLogfileName, " | grep -v another\n")
      cat(paste(sep="", "   - Sim. Start = ", startTime, "\n"))
   }

   # The output of "make" goes into the log file.
   # In case of error, the last 20 lines of the log file are copied into the error file.
   # The error file can later be used to write these lines to Jabber.
   cmd <- paste(sep="", " rm -f ", gErrorName, " && if [ -e Makefile ] ; then make MODE=release ", simCreatorSimulationBinary, " ; fi && ( make -k -j" ,
                CPUs,
                " -l -f ", gMakefileName,
                " all >", gLogfileName , " 2>&1 || tail -n20 ", gLogfileName, " | tee ", gErrorName, " )")

   # ------ Execute make ----------------------------------------------------
   # cat("\n\n",cmd,"\n\n")
   r <- readLines(pc <- pipe(cmd))
   close(pc)
   stopTime <- Sys.time()

   if(simulationScriptOutputVerbosity > 0) {
      cat(paste(sep="", "   - Sim. Stop  = ", stopTime, "\n"))
      cat(sep="", "   - Runtime    = ",
          signif(as.double(difftime(stopTime, startTime, units="min")),2), "min\n")
   }
   writeLines(r)

   if(reportTo != "") {
      cmd <- paste(sep="", "( ( echo \"Finished ", simulationDirectory, ".\" ; if [ -e ", gErrorName, " ] ; then echo \"Simulation processing has FAILED:\" ; echo \"----- Last Lines in Log -----\" ; cat ", gErrorName, " ; echo \"----- End of Log -----\" ; fi ) | sendxmpp --tls --interactive ", reportTo, " 2>/dev/null & )")

      # cat("\n\n",cmd,"\n\n")
      r <- readLines(pc <- pipe(cmd))
      close(pc)
   }
}


# ====== Create all simulation runs =========================================
createAllSimulationRuns <- function(simulationConfigurations,
                                    originalSimulationConfigurations,
                                    makefile, summary, dependencies,
                                    originalSetup=c())
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
                                 makefile, summary, dependencies, setup)
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
            cat(sprintf(" + Runs %d-%d of %d:\t",
                        1 + (gRunNumberInLevel - 1) * gTotalSimulationRunLevels,
                        1 + gRunNumberInLevel * gTotalSimulationRunLevels - 1,
                        gTotalSimulationRunLevels * gTotalSimulationRunsPerLevel))
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
         varNames      <- gActiveVariables
         origVarValues <- getActiveVariables(originalSimulationConfigurations, GAVType_VariableValues, duration)

         # ------ Compute auto-parameters -----------------------------------
         if(simCreatorAutoParameters(originalSimulationConfigurations) & simulationIncludeOrSkip(originalSimulationConfigurations) ) {

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
            parameterString <- ""
            if(simulationScriptOutputVerbosity > 4) {
               for(i in 1:length(varNames)) {
                  variable  <- varNames[i]
                  value     <- varValues[i]
                  origValue <- origVarValues[i]
                  parameterString <- paste(sep="", parameterString, variable, "=")
                  if((!is.na(origValue)) && (value == origValue)) {
                     parameterString <- paste(sep="", parameterString, value)
                  }
                  else {
                     parameterString <- paste(sep="", parameterString, value, "(", origValue, ")")
                  }
                  parameterString <- paste(sep="", parameterString, "\t")
               }
               cat(parameterString, "\n")
            }

            # ------ Create runs --------------------------------------------
            runDirectoryName <- paste(sep="", gSimulationsDirectoryName, "/",
                                      "Set-", setupHash)
            dir.create(runDirectoryName, showWarnings=FALSE)

            if(is.list(simulationRuns)) {
               levelsSet <- unique(unlist(simulationRuns))
            }
            else {
               levelsSet <- seq(1, simulationRuns)
            }

            # ====== Create shortcut link ===================================
            shortcutLink <- paste(sep="", "Shortcut-", sprintf("%06d", gRunNumberInLevel))
            oldWorkingDirectory <- setwd(gSimulationsDirectoryName)
            if(file.exists(shortcutLink)) {
               file.remove(shortcutLink)
            }
            file.symlink(paste(sep="", "Set-", setupHash), shortcutLink)
            setwd(oldWorkingDirectory)

            # ====== Create runs in level ===================================
            level <- 0
            for(simulationRun in levelsSet) {
               filePrefix <- paste(sep="", runDirectoryName, "/run", simulationRun)
               outputName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-output.txt")
               iniName    <- paste(sep="", runDirectoryName, "/run", simulationRun, "-parameters.ini")

               scalarName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-scalars.sca")
               vectorName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-vectors.vec")
               statusName <- paste(sep="", runDirectoryName, "/run", simulationRun, "-status.txt")


               ini <- file(iniName, "w")
               cat(sep="", "# ###### Created on ", date(), " ######\n", file=ini)
               simCreatorWriteHeader(ini, simulationRun, scalarName, vectorName, duration)
               simCreatorWriteParameterSection(filePrefix, ini, simulationRun, duration)

               close(ini)

               addRunToSummary(summary, scalarName, vectorName,
                               iniName,
                               outputName, statusName, varValues)
               addRunToMakefile(makefile, simulationRun,
                                gRunNumberInLevel + (level * gTotalSimulationRunsPerLevel),
                                gTotalSimulationRunLevels * gTotalSimulationRunsPerLevel,
                                runDirectoryName, shortcutLink,
                                iniName, scalarName, vectorName, statusName,
                                parameterString)
               addDependency(dependencies, filePrefix)
               level <- level + 1
            }
         }
         else {
            if(simulationScriptOutputVerbosity > 4) {
               cat(sep="","SKIPPING!\n")
               if(is.list(simulationRuns)) {
                  levelsSet <- unique(unlist(simulationRuns))
               }
               else {
                  levelsSet <- seq(1, simulationRuns)
               }
               for(simulationRun in levelsSet) {
               }
            }
         }

         setGlobalVariable("gRunNumberInLevel", gRunNumberInLevel + 1)
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

   # ====== Cross-check: each config item may exist only once ===============
   configItemSet <- c()
   for(j in 1:length(configuration)) {
      configItem <- unlist(configuration[j], recursive=FALSE)
      configItemSet <- append(configItemSet, as.character(configItem[1]))
   }
   duplicates <- duplicated(configItemSet)
   for(j in 1:length(configItemSet)) {
      if(duplicates[j]) {
         # print(duplicates)
         print(configItemSet)
         stop(cat(sep="", "ERROR: Parameter ", as.character(configItemSet[j]),
                          " has been specified twice!\n"))
      }
   }
   return(results)
}


# ====== Create simulation ==================================================
createSimulation <- function(simulationDirectory, simulationConfigurations, simulationDefaults)
{
   simulationConfigurations <- makeSimulations(simulationConfigurations, simulationDefaults)

   # ------ Initialize ------------------------------------------------------
   setGlobalVariable("gRunNumberInLevel", 1)
   setGlobalVariable("gTotalSimulationRunLevels",
                     getTotalSimulationRunLevels(simulationConfigurations))
   setGlobalVariable("gTotalSimulationRunsPerLevel",
                     getTotalSimulationRunsPerLevel(simulationConfigurations))
   setGlobalVariable("gActiveVariables",
                     getActiveVariables(simulationConfigurations, GAVType_VariableNames))

   # ------ Directory preparation -------------------------------------------
   if(simulationScriptOutputVerbosity > 0) {
      cat(sep="", "* Step #1: Preparing directory ", simulationDirectory, " ...\n")
   }
   prepareDirectory(simulationDirectory)
   makefile <- beginMakefile()
   summary <- beginSummary()
   dependencies <- beginDependencies()

   # ------ Input file creation ---------------------------------------------
   if(simulationScriptOutputVerbosity > 0) {
      cat(sep="", "* Step #2: Creating input files for ",
                  gTotalSimulationRunLevels * gTotalSimulationRunsPerLevel, " runs ...\n")
      cat(sep="",   " + Active variables:\n")
      for(varName in gActiveVariables) {
         cat(sep="", "  @ ", varName, "\n")
      }
   }
   createAllSimulationRuns(simulationConfigurations, simulationConfigurations, makefile, summary, dependencies)

   # ------ Finish summary and makefile -------------------------------------
   cat(sep="", "* Step #3: Writing summary script and makefile ...\n")
   summaryCommand <- finishSummary(summary)
   finishMakefile(makefile, dependencies, summaryCommand)
   if(simulationExecuteMake) {
     executeMake()
   }
   cat(sep="", "* Script completed!\n")
}


# ====== Check whether argument is a numeric value ==========================
isNumericValue <- function(value) {
   suppressWarnings(result <- as.numeric(value))
   return(!is.na(result))
}
