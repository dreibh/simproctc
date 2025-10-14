<h1 align="center">
 SimProcTC<br />
 <span style="font-size: 30%">A Simulation Processing Tool-Chain for OMNeT++ Simulations</span><br />
 <a href="https://www.nntb.no/~dreibh/omnetpp/">
  <img alt="RSPLIB Project Logo" src="logo/Logo-SimProcTC.svg" width="25%" /><br />
  <span style="font-size: 30%;">https://www.nntb.no/~dreibh/omnetpp</span>
 </a>
</h1>


# 💡 What is SimProcTC (Simulation Processing Tool-Chain)?

SimProcTC (Simulation Processing Tool-Chain) is a flexible and powerful tool-chain for the setup, parallel run execution, results aggregation, data analysis and debugging of discrete event simulations based on the [OMNeT++](https://omnetpp.org/) discrete event simulator. Particularly, it is used for example for simulations with the [RSPSIM RSerPool simulation model](https://www.nntb.no/~dreibh/rserpool/) or with the [NetPerfMeter/CMT-SCTP models in the INET Framework](https://www.wiwi.uni-due.de/fileadmin/fileupload/I-TDR/SCTP/Paper/OMNeT__Workshop2010-SCTP.pdf). However, SimProcTC is model-independent and can be adapted easily to other simulation models.

Further details about SimProcTC can be found in Appendix&nbsp;B of «[Evaluation and Optimisation of Multi-Path Transport using the Stream Control Transmission Protocol](https://duepublico2.uni-due.de/servlets/MCRFileNodeServlet/duepublico_derivate_00029737/Dre2012_final.pdf#appendix.B)»!


# 💾 Build from Sources

SimProcTC is released under the [GNU General Public Licence&nbsp;(GPL)](https://www.gnu.org/licenses/gpl-3.0.en.html#license-text).

Please use the issue tracker at [https://github.com/dreibh/simproctc/issues](https://github.com/dreibh/simproctc/issues) to report bugs and issues!

## Development Version

The Git repository of the SimProcTC sources can be found at [https://github.com/dreibh/simproctc](https://github.com/dreibh/simproctc):

<pre><code><span class="fu">git</span> clone <a href="https://github.com/dreibh/simproctc">https://github.com/dreibh/simproctc</a>
<span class="bu">cd</span> simproctc
<span class="bu">cd</span> toolchain/tools &amp;&amp; make <span class="fu">&amp;&amp;</span> <span class="bu">cd</span> ..
</code></pre>

Contributions:

* Issue tracker: [https://github.com/dreibh/simproctc/issues](https://github.com/dreibh/simproctc/issues).
  Please submit bug reports, issues, questions, etc. in the issue tracker!

* Pull Requests for SimProcTC: [https://github.com/dreibh/simproctc/pulls](https://github.com/dreibh/simproctc/pulls).
  Your contributions to SimProcTC are always welcome!

## Release Versions

See [https://www.nntb.no/~dreibh/omnetpp/#current-stable-release](https://www.nntb.no/~dreibh/omnetpp/#current-stable-release) for release packages!


# 📦 Installation of OMNeT++, SimProcTC and a Demo Simulation

The following items are a step-by-step installation guide for SimProcTC.

## Install OMNeT++

Get the latest version of OMNeT++ [here](https://omnetpp.org/download/) and install it under Linux. See the [OMNeT++ Installation Guide](https://doc.omnetpp.org/omnetpp/InstallGuide.pdf) for details!

If you do not have Linux installed already, you may find my [Little Ubuntu Linux Installation Guide](https://www.nntb.no/~dreibh/ubuntu/) helpful. This installation guide also provides help on how to install OMNeT++ on an Ubuntu system.
Note that while OMNeT++ also works under Microsoft Windows, my tool-chain has not been tested under this operating system, yet. In particular, run distribution using RSerPool will not work under Windows unless you port the [RSPLIB RSerPool implementation](https://www.nntb.no/~dreibh/rserpool/) to Windows.

After installing OMNeT++, make sure that it is working properly.

## Install GNU&nbsp;R

Install [GNU&nbsp;R](https://www.r-project.org/). Usually, it will be available for your Linux distribution as installation package. However, if you decide to install it from source, you can download the source [here](https://www.r-project.org/).
Under Ubuntu/Debian Linux, you can download and install GNU&nbsp;R using the following command line:

* Ubuntu/Debian:
  ```bash
  sudo apt-get install r-base
  ```
* Fedora:
  ```bash
  sudo dnf install R-base
  ```
* FreeBSD:
  ```bash
  sudo pkg install R
  ```

After installation, you can start GNU&nbsp;R by:

```bash
R --vanilla
```

You can quit GNU&nbsp;R using Ctrl+D.

## Install libbz2

The simulation tool-chain requires libbz2 for compression and decompression of files, including the development headers. In particular, also the developer files (include files) of this library are required to compile the tool-chain. Usually, it will be available for your Linux distribution as installation package. However, if you decide to install it from source, you can download the source from [bzip2: Home](https://sourceware.org/bzip2/). In most cases, it can be installed by the operating system’s package management:

* Ubuntu/Debian:
  ```bash
  sudo apt-get install bzip2 libbz2-dev
  ```
* Fedora:
  ```bash
  sudo dnf install bzip2 bzip2-devel
  ```
* FreeBSD:
  ```bash
  sudo pkg install bzip2
  ```

## Install chrpath

`chrpath` is a shell tool to modify the path to look for shared libraries in executables, which is needed for run distribution. If not already installed, it can be installed by the operating system's package management:

* Ubuntu/Debian:
  ```bash
  sudo apt-get install chrpath
  ```
* Fedora:
  ```bash
  sudo dnf install chrpath
  ```
* FreeBSD:
  ```bash
  sudo pkg install chrpath
  ```

## Install the Simulation Tool-Chain

Get the simulation tool-chain package from the [Build from Sources](#build-from-sources) section and unpack it, or clone the Git repository. Also, take a look at the description paper in the [`docs`](https://github.com/dreibh/simproctc/blob/master/docs/) directory; they provide important information on what the tool-chain actually does! The tool-chain archive includes the files of the tool chain as well as a small example simulation. The files have the following purposes:

* [`toolchain`](https://github.com/dreibh/simproctc/blob/master/toolchain/) directory: This directory contains the tool-chain scripts.
  - [`simulation.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulation.R): Generic simulation tool-chain code.
  - [`simulate-version1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulate-version1.R): Model-specific simulation tool-chain code.
  - [`hashfunctions.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/hashfunctions.R): GNU R functions to calculate [MD5](https://en.wikipedia.org/wiki/MD5) and [SHA-1](https://en.wikipedia.org/wiki/SHA-1) hashes.
  - [`plotter.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plotter.R): GNU R functions for plotting.
  - [`make-environment`](https://github.com/dreibh/simproctc/blob/master/toolchain/make-environment): Shell script to collect all files to create the environment file.
  - [`get-libs`](https://github.com/dreibh/simproctc/blob/master/toolchain/get-libs): Shell script to collect all shared libraries needed by the model.
  - [`get-neds`](https://github.com/dreibh/simproctc/blob/master/toolchain/get-neds): Shell script to collect all NED files needed by the model.
  - [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R): Example simulation script.
  - [`plot-test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plot-test1.R): Plotting script for the example.
  - [`ssdistribute`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssdistribute): Shell script to distribute runs in a computation pool.
  - [`ssrun`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssrun): Shell script to perform a simulation run (on a remote pool PC).
* [`toolchain/tools`](https://github.com/dreibh/simproctc/blob/master/toolchain/tools/) directory: This directory contains the `createsummary` tool for scalar file processing. For performance reasons, it is written in C++, and therefore has to be compiled.
* [`example-simulation`](https://github.com/dreibh/simproctc/blob/master/example-simulation/) directory:
    This directory contains the simple example model "example-simulation" for OMNeT++ 5.x/6.x.
  - [`scenario.ned`](https://github.com/dreibh/simproctc/blob/master/example-simulation/scenario.ned): NED file.
  - [`messages.msg`](https://github.com/dreibh/simproctc/blob/master/example-simulation/messages.msg): Messages file.
  - [`implementation.cc`](https://github.com/dreibh/simproctc/blob/master/example-simulation/implementation.cc): Model implementation.
  - [`omnetpp.ini`](https://github.com/dreibh/simproctc/blob/master/example-simulation/omnetpp.ini): Example run for testing the Qtenv/Cmdenv environments simulation.

In order to compile tool-chain and examples, call the following commands in the SimProcTC main directory:

```bash
cd toolchain/tools && make && cd ../.. && \
cd example-simulation && \
opp_makemake -I . -f && \
make
```

Notes:

* Make sure to compile in the OMNeT++ Python environment (see the [OMNeT++ Installation Guide](https://doc.omnetpp.org/omnetpp/InstallGuide.pdf)), i.e.:

  ```bash
  source <PATH_TO_OMNET++_DIRECTORY>/setenv
  ```

  If `opp_makemake` is not found, this step is likely missing!

* Make sure that everything compiles successfully. Otherwise, the tool-chain will not work properly!

After compilation, you can start the demo simulation by calling:

```bash
./example-simulation
```


# 🏃 Running the Demo Simulation

The example simulation packaged with SimProcTC simply presents the effects of fragmenting large packets into cells and forwarding them: the delays will significantly reduce at the price of increased overhead. Take a look into [`scenario.ned`](https://github.com/dreibh/simproctc/blob/master/example-simulation/scenario.ned) to see the parameters of the model:

* _fragmenterScenario.fragmenter.cellHeaderSize_
* _fragmenterScenario.fragmenter.cellPayloadSize_
* _fragmenterScenario.intermediateNodeOutputRate_
* _fragmenterScenario.sourceHeaderSize_
* _fragmenterScenario.sourcePayloadSize_
* _fragmenterScenario.sourceInterarrivalTime_

An example simulation for this model is defined in [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R): for each parameter of the model, the list _simulationConfigurations_ contains a list with the parameter name as first element and its value(s) as further elements. For example, ```list("sourcePayloadSize", 1000, 2500)``` means that the parameter _sourcePayloadSize_ should be used with the values 1000&nbsp;bytes and 2500&nbsp;bytes. For each parameter combination, a separate run will be created. Furthermore, the variable _simulationRuns_ specifies how many different seeds should be used. That is, for ```simulationRuns=3```, runs for each parameter combinations are created with 3&nbsp;different seeds (i.e.&nbsp;tripling the number of runs!).

The actual output of `.ini` files is realized in [`simulate-version1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulate-version1.R). Take a look over this file first, it should be quite self-explaining! In the function ```demoWriteParameterSection()```, the actual lines for the parameters above are written for each simulation run. _simCreatorAdditionalActiveVariables_ defines for which variables a table row should always be written. For example, if you always use ```cellHeaderSize=4```, the `createsummary` tool would omit this parameter in the output table, because it always has the same value. Since it may be useful for your post-processing, you can add it to _simCreatorAdditionalActiveVariables_. Note, that _simCreatorWriteParameterSection_ is set to _demoWriteParameterSection_. In the generic [`simulation.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulation.R) script, always the names <em>simCreator&#42;</em> instead of <em>demo&#42;</em> are used. In order to be model-independent, it is necessary to set these variables to the actual model-dependent functions in simulate-version1.R! When you adapt the tool-chain to you own model, you only have to create your own <tt>simulation-version<em>X</em>.R</tt> script and leave the other scripts unmodified.

The variables _distributionPool_ and _distributionProcs_ in [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R) are used to control the request distribution. They will be explained later. For now, make sure that _distributionProcs_ is set to&nbsp;0! This setting means that all runs are processed on the local machine.

Now, in order to perform the simulation defined in [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R), simply execute [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R) using R:

```bash
R --vanilla < test1.R
```

The script will now create an `.ini` file for each run and a `Makefile` containing all runs. Finally, `make` will be called to process the created `Makefile`. `make` will already be called with the `-j` parameter corresponding to your number of CPUs/cores, so that it fully utilises the computation power of your machine. You can observe the progress of the simulation processing by monitoring the log file:

```bash
tail -f test1/make.log
```

You can abort the simulation processing and continue later. Only the run(s) currently in progress are lost and have to be re-processed upon resumption. Already completed runs are saved and no re-processing is necessary.


# 📈 Plotting the Results

After processing the simulation defined by [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R), you can plot the results using [`plot-test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plot-test1.R):

```bash
R --vanilla < plot-test1.R
```

The results will be written to `test1.pdf` (the file name will be the simulation output directory + `.pdf`). You can view it with any PDF reader, e.g.&nbsp;[Okular](https://okular.kde.org/). The plotter settings at the head of [`plot-test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plot-test1.R) should be almost self-explaining. For _colorMode_, you can also use _cmBlackAndWhite_ or _cmGreyScale_. Setting _plotOwnOutput_ to TRUE results in an own output file for each plot (instead of a single PDF file). _plotConfigurations_ contains the definitions for each plot, in particular title, output file name for _plotOwnOutput_, x- and y-axis ticks, legend position and the results data for each axis given by a template. A set of model-specific templates is already defined in [`simulate-version1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulate-version1.R), you can add additional ones there or to _plotVariables_ in [`plot-test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plot-test1.R). See also the paper for more details on templates.


# 🚀 Run Distribution to a Pool of PCs

Make sure that the previous steps (performing simulations and plotting) work. If they are not working properly, the run distribution will also fail! First, it is necessary to install the [RSPLIB RSerPool implementation](https://www.nntb.no/~dreibh/rserpool/). On a Ubuntu/Debian system, RSPLIB can be installed directly:

```bash
sudo apt-get install rsplib-registrar rsplib-services rsplib-tools
```

In case of a need for a manual installation, also see the [RSPLIB documentation](https://www.nntb.no/~dreibh/rserpool/)!

One one computer, run CSP monitor to display the status of the other components:

```bash
cspmonitor
```

Note the IP address of this system. The CSP monitor runs on UDP port&nbsp;2960.

For the other components to be started, define environment variables:

```bash
export CSP_SERVER=<IP_OF_CSP_MONITOR>:2960
export CSP_INTERVAL=333
```

You can put these commands e.g.&nbsp;into `$HOME/.bashrc`, so that the variables are available in all new shell sessions!

In your network, start at least one RSerPool Pool Registrar&nbsp;(PR):

```bash
rspregistrar
```

With the environment variables above set correctly, the CSP monitor should show the registrar.

Then, start a Scripting Service Pool Element&nbsp;(PE) in another shell.

```bash
rspserver -scripting -policy=LeastUsed -ssmaxthreads=4
```

The parameter `-ssmaxthreads` specifies the number of parallel sessions; use the number of cores/CPUs in your machine). The output of `rspserver` should look as follows:

<pre style="background: #5555dd22;">
Starting service ...
Scripting Server - Version 2.0
==============================

General Parameters:
   Pool Handle             = ScriptingPool
   Reregistration Interval = 30.000s
   Local Addresses         = { all }
   Runtime Limit           = off
   Max Threads             = 4
   Policy Settings
      Policy Type          = LeastUsed
      Load Degradation     = 0.000%
      Load DPF             = 0.000%
      Weight               = 0
      Weight DPF           = 0.000%
Scripting Parameters:
   Keep Temp Dirs          = no
   Verbose Mode            = no
   Transmit Timeout        = 30000 [ms]
   Keep-Alive Interval     = 15000 [ms]
   Keep-Alive Timeout      = 10000 [ms]
   Cache Max Size          = 131072 [KiB]
   Cache Max Entries       = 16
   Cache Directory         =
   Keyring                 =
   Trust DB                =
Registration:
   Identifier              = $249c7176
</pre>

In particular, take care of the "Identifier" line. This is the ID of the pool element under which it has been registered. If there are error messages saying that registration has failed, etc., take a look into the [RSPLIB documentation](https://www.nntb.no/~dreibh/rserpool/). Usually, this means a small configuration problem which can be solved easily! It may also be helpful to use [Wireshark](https://www.wireshark.org/) for debugging network issues; it has dissectors for the RSerPool protocols as well as for CSP and the Scripting Service protocols!

With the environment variables above set correctly, the CSP monitor should show the PE.

Take a look into the script [`ssdistribute`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssdistribute). Ensure that the variable setting for _SIMULATION_POOLUSER_ points to the program `scriptingclient` of the RSPLIB package (if installed from the Ubuntu/Debian package: `/usr/bin/scriptingclient`).

```bash
SIMULATION_POOLUSER=/usr/bin/scriptingclient
```

If `scriptingclient` is located else where, e.g.&nbsp;`$HOME/src/rsplib-3.5.4/src` in your home directory, the line should be:

```bash
SIMULATION_POOLUSER=~/src/rsplib-3.5.4/src/scriptingclient
```

In [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R), set _distributionProcs_ to the maximum number of simultaneous sessions (at least&nbsp;1; if you later start 5&nbsp;pool elements with 2&nbsp;cores each, you should use&nbsp;10). It is safe to use&nbsp;1 for the following test. After modifying _distributionProcs_, increase _simulationRuns_ e.g.&nbsp;by&nbsp;1. Otherwise, since you have already performed the run of [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R) before, no more runs would be necessary (since their results are already there!). Now, run [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R) again:

```bash
R --vanilla < test1.R
```

Take a look at the output of `rspserver`: it should receive jobs and process them. Also, take a look at the log output:

```bash
tail -f test1/make.log
```

When the job distribution is working properly, you can start more pool elements and set up your simulation computation pool. Do not forget to increase _distributionProcs_ accordingly!

With the environment variables above set correctly, the CSP monitor should show the status of pool users and pool elements during the simulation processing.

The workload distribution system works as follows:

* First, the `Makefile` calls [`make-environment`](https://github.com/dreibh/simproctc/blob/master/toolchain/make-environment) to generate Tar/BZip2 file `simulation-environment.tar.bz2` in the simulation directory. It contains the simulation binary, all shared libraries it needs (found out by the [`get-libs`](https://github.com/dreibh/simproctc/blob/master/toolchain/get-libs) script), all `.ned` files it needs (found out by the [`get-neds`](https://github.com/dreibh/simproctc/blob/master/toolchain/get-neds) script) and the script `simulation.config-stage0` which sets two environment variables: _SIMULATION_PROGRAM_ contains the name of the binary, _SIMULATION_LIBS_ contains the location of the libraries. If your simulation needs additional files, they can be specified by the variable _simulationMiscFiles_ in [`simulate-version1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulate-version1.R).

* [`ssdistribute`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssdistribute) – which is called to actually distribute a run to a pool – creates the Tar/GZip file for the run. This file includes the environment file (i.e.&nbsp;usually `simulation-environment.tar.bz2`) specified by the variable _SIMULATION_ENVIRONMENT_ and additional configuration files like `simulation.config-stage0` (but named [`simulation.config-stage1`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulation.config-stage1), `simulation.config-stage2`, ...) specified by the environment variable _SIMULATION_CONFIGS_. You have to set these two environment variables in the [`ssdistribute`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssdistribute) script. Furthermore, the Tar/GZip file of the run contains the `.ini` file for the run.

* [`ssrun`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssrun) performs a run on a (usually) remote node. First, it finds all `simulation.config-stage*` scripts and executes them in alphabetical order. That is, [`simulation.config-stage1`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulation.config-stage1) may overwrite settings of `simulation.config-stage0` and so on. After that, it looks for `.ini` files. For each `.ini` file, it runs the program specified by the environment variable _SIMULATION_PROGRAM_. If the variable _SIMULATION_LIBS_ is set, does not call the binary directly but tells the shared library loader to do this and use the specified set of shared libraries.
If everything went well, a status file is created. The existence of this status file means that the run has been successful.

* Finding out what is going wrong with the remote execution can be difficult sometimes. In such a case, only start a single instance of `rspserver` and use the parameter `-sskeeptempdirs`. This parameter results in not deleting the temporary session directory after shutdown of the session. That is, you can dissect the directory's contents for troubleshooting. The name of the directory for each session is shown in the output of `rspserver`.


# 🔧 Adapting SimProcTC to Your Own Simulation

In order to use SimProcTC with your own model, perform the following tasks:

* Copy the SimProcTC files to your model's directory: [`ssrun`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssrun), [`ssdistribute`](https://github.com/dreibh/simproctc/blob/master/toolchain/ssdistribute), [`simulation.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulation.R), [`hashfunctions.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/hashfunctions.R), [`plotter.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plotter.R), [`make-environment`](https://github.com/dreibh/simproctc/blob/master/toolchain/make-environment), [`get-libs`](https://github.com/dreibh/simproctc/blob/master/toolchain/get-libs), [`get-neds`](https://github.com/dreibh/simproctc/blob/master/toolchain/get-neds).
* Create a model-specific `.ini` file generation script (use [`simulate-version1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/simulate-version1.R) of the demo simulation as a template).
* Create a simulation definition script (use [`test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/test1.R) of the demo simulation as a template).
* Create a plot script for your simulation (use [`plot-test1.R`](https://github.com/dreibh/simproctc/blob/master/toolchain/plot-test1.R) of the demo simulation as a template).

Before using the RSerPool-based run distribution, first test your simulation on your local machine! This makes finding problems much easier. If everything works, you can continue with run distribution.


# 🖋️ Citing SimProcTC in Publications

SimProcTC and related BibTeX entries can be found in [AllReferences.bib](https://www.nntb.no/~dreibh/omnetpp/bibtex/AllReferences.bib)!

* [Dreibholz, Thomas](https://www.nntb.no/~dreibh/): «[Evaluation and Optimisation of Multi-Path Transport using the Stream Control Transmission Protocol](https://duepublico2.uni-due.de/servlets/MCRFileNodeServlet/duepublico_derivate_00029737/Dre2012_final.pdf)» ([PDF](https://duepublico2.uni-due.de/servlets/MCRFileNodeServlet/duepublico_derivate_00029737/Dre2012_final.pdf), 36779&nbsp;KiB, 264&nbsp;pages, 🇬🇧), Habilitation Treatise, University of Duisburg-Essen, Faculty of Economics, Institute for Computer Science and Business Information Systems, URN&nbsp;[urn:nbn:de:hbz:464-20120315-103208-1](https://nbn-resolving.org/urn:nbn:de:hbz:464-20120315-103208-1), March&nbsp;13, 2012.
* [Dreibholz, Thomas](https://www.nntb.no/~dreibh/); [Zhou, Xing](https://web.archive.org/web/20210517200550/https://hd.hainanu.edu.cn/scscs/info/1019/1029.htm) and [Rathgeb, Erwin Paul](https://web.archive.org/web/20241126012608/https://tdr.informatik.uni-due.de/en/team/erwin-p-rathgeb/): «[SimProcTC – The Design and Realization of a Powerful Tool-Chain for OMNeT++ Simulations](https://www.wiwi.uni-due.de/fileadmin/fileupload/I-TDR/ReliableServer/Publications/OMNeT__Workshop2009.pdf)» ([PDF](https://www.wiwi.uni-due.de/fileadmin/fileupload/I-TDR/ReliableServer/Publications/OMNeT__Workshop2009.pdf), 552&nbsp;KiB, 8&nbsp;pages, 🇬🇧), in *Proceedings of the 2nd ACM/ICST International Workshop on OMNeT++*, pp.&nbsp;1–8, DOI&nbsp;[10.4108/ICST.SIMUTOOLS2009.5517](https://dx.doi.org/10.4108/ICST.SIMUTOOLS2009.5517), ISBN&nbsp;978-963-9799-45-5, Rome/Italy, March&nbsp;6, 2009.
* [Dreibholz, Thomas](https://www.nntb.no/~dreibh/) and [Rathgeb, Erwin Paul](https://web.archive.org/web/20241126012608/https://tdr.informatik.uni-due.de/en/team/erwin-p-rathgeb/): «[A Powerful Tool-Chain for Setup, Distributed Processing, Analysis and Debugging of OMNeT++ Simulations](https://www.wiwi.uni-due.de/fileadmin/fileupload/I-TDR/ReliableServer/Publications/OMNeTWorkshop2008.pdf)» ([PDF](https://www.wiwi.uni-due.de/fileadmin/fileupload/I-TDR/ReliableServer/Publications/OMNeTWorkshop2008.pdf), 558&nbsp;KiB, 8&nbsp;pages, 🇬🇧), in *Proceedings of the 1st ACM/ICST International Workshop on OMNeT++*, DOI&nbsp;[10.4108/ICST.SIMUTOOLS2008.2990](https://dx.doi.org/10.4108/ICST.SIMUTOOLS2008.2990), ISBN&nbsp;978-963-9799-20-2, Marseille, Bouches-du-Rhône/France, March&nbsp;7, 2008.


# 🔗 Useful Links

## Simulation and Data Processing Software

* [OMNeT++ Simulation Toolkit Community Site](https://omnetpp.org/)
* [The R Project for Statistical Computing](https://www.r-project.org)

## Other Resources

* [Thomas Dreibholz's Reliable Server Pooling (RSerPool) Page](https://www.nntb.no/~dreibh/rserpool/)
* [Thomas Dreibholz's SCTP Page](https://www.nntb.no/~dreibh/sctp/)
* [Thomas Dreibholz's Multi-Path TCP (MPTCP) Page](https://www.nntb.no/~dreibh/mptcp/)
* [Thomas Dreibholz's Little Ubuntu Linux Installation Guide](https://www.nntb.no/~dreibh/ubuntu/)
* [Wireshark](https://www.wireshark.org/)
