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

CMAKE_MINIMUM_REQUIRED(VERSION 3.12)
PROJECT(simproctc-tools LANGUAGES CXX)

SET(CMAKE_CXX_STANDARD          20)
SET(CMAKE_CXX_STANDARD_REQUIRED ON)
SET(CMAKE_CXX_EXTENSIONS        OFF)


#############################################################################
#### REQUIREMENTS                                                        ####
#############################################################################

# ====== NetBSD: liberty ====================================================
IF (CMAKE_SYSTEM_NAME MATCHES "NetBSD")
   FIND_LIBRARY(LIBIBERTY_LIBRARY NAMES iberty PATHS /usr/pkg/lib)
   FIND_PATH(LIBIBERTY_INCLUDE_DIR NAMES libiberty.h PATHS /usr/pkg/include)
   IF ((LIBIBERTY_LIBRARY) AND (LIBIBERTY_INCLUDE_DIR))
      ADD_DEFINITIONS(-DHAVE_LIBIBERTY)
      MESSAGE(STATUS "Libiberty library found:")
      MESSAGE(STATUS " LIBIBERTY_LIBRARY:     ${LIBIBERTY_LIBRARY}")
      MESSAGE(STATUS " LIBIBERTY_INCLUDE_DIR: ${LIBIBERTY_INCLUDE_DIR}")
   ELSE()
      MESSAGE(FATAL_ERROR
              "Cannot find Libiberty library! Try:\n"
              " * NetBSD: sudo pkgin -y install libiberty")
   ENDIF()
ENDIF()

# ====== libz ===============================================================
FIND_LIBRARY(Z_LIBRARY NAMES z)
FIND_PATH(Z_INCLUDE_DIR NAMES zlib.h)
IF (Z_LIBRARY AND Z_INCLUDE_DIR)
   MESSAGE(STATUS "GZip library found:")
   MESSAGE(STATUS " Z_LIBRARY:     ${Z_LIBRARY}")
   MESSAGE(STATUS " Z_INCLUDE_DIR: ${Z_INCLUDE_DIR}")
ELSE()
   MESSAGE(FATAL_ERROR
           "Cannot find Z library! Try:\n"
           " * Ubuntu/Debian: sudo apt install -y zlib1g-dev\n"
           " * Fedora:        sudo dnf install -y zlib-ng-compat-devel\n"
           " * OpenSUSE:      sudo zypper install -y zlib-devel\n"
           " * Alpine:        sudo apk add zlib-ng-dev\n"
           " * FreeBSD:       (should be installed by default)\n"
           " * NetBSD:        (should be installed by default)\n"
           " * OpenBSD:       (should be installed by default)\n"
           " * Solaris:       sudo pkg install zlib\n"
           " * Apple:         brew install zlib")
ENDIF()

# ====== libbz2 =============================================================
FIND_LIBRARY(BZ2_LIBRARY NAMES bz2)
FIND_PATH(BZ2_INCLUDE_DIR NAMES bzlib.h)
IF (BZ2_LIBRARY AND BZ2_INCLUDE_DIR)
   MESSAGE(STATUS "BZip2 library found:")
   MESSAGE(STATUS " BZ2_LIBRARY:     ${BZ2_LIBRARY}")
   MESSAGE(STATUS " BZ2_INCLUDE_DIR: ${BZ2_INCLUDE_DIR}")
ELSE()
   MESSAGE(FATAL_ERROR
           "Cannot find BZip2 library! Try:\n"
           " * Ubuntu/Debian: sudo apt install -y libbz2-dev\n"
           " * Fedora:        sudo dnf install -y bzip2-devel\n"
           " * OpenSUSE:      sudo zypper install -y libbz2-devel\n"
           " * Alpine:        sudo apk add bzip2-dev\n"
           " * FreeBSD:       sudo pkg install -y bzip2\n"
           " * NetBSD:        (should be installed by default)\n"
           " * OpenBSD:       (should be installed by default)\n"
           " * Solaris:       sudo pkg install bzip2\n"
           " * Apple:         brew install bzip2")
ENDIF()

# ====== liblzma ============================================================
FIND_LIBRARY(LZMA_LIBRARY NAMES lzma)
FIND_PATH(LZMA_INCLUDE_DIR NAMES lzma.h)
IF (LZMA_LIBRARY AND LZMA_INCLUDE_DIR)
   MESSAGE(STATUS "LZMA library found:")
   MESSAGE(STATUS " LZMA_LIBRARY:     ${LZMA_LIBRARY}")
   MESSAGE(STATUS " LZMA_INCLUDE_DIR: ${LZMA_INCLUDE_DIR}")
ELSE()
   MESSAGE(FATAL_ERROR
           "Cannot find LZMA library! Try:\n"
           " * Ubuntu/Debian: sudo apt install -y liblzma-dev\n"
           " * Fedora:        sudo dnf install -y xz-devel\n"
           " * OpenSUSE:      sudo zypper install -y xz-devel\n"
           " * Alpine:        sudo apk add xz-dev\n"
           " * FreeBSD:       sudo pkg install -y lzmalib\n"
           " * NetBSD:        sudo pkgin -y install lzmalib\n"
           " * OpenBSD:       sudo pkg_add xz\n"
           " * Solaris:       sudo pkg install compress/xz\n"
           " * Apple:         brew install xz")
ENDIF()

# ====== libzstd ============================================================
FIND_LIBRARY(ZSTD_LIBRARY NAMES zstd)
FIND_PATH(ZSTD_INCLUDE_DIR NAMES zstd.h)
IF (ZSTD_LIBRARY AND ZSTD_INCLUDE_DIR)
   MESSAGE(STATUS "ZSTD library found:")
   MESSAGE(STATUS " ZSTD_LIBRARY:     ${ZSTD_LIBRARY}")
   MESSAGE(STATUS " ZSTD_INCLUDE_DIR: ${ZSTD_INCLUDE_DIR}")
ELSE()
   MESSAGE(FATAL_ERROR
           "Cannot find ZSTD library! Try:\n"
           " * Ubuntu/Debian: sudo apt install -y libzstd-dev\n"
           " * Fedora:        sudo dnf install -y libzstd-devel\n"
           " * OpenSUSE:      sudo zypper install -y libzstd-devel\n"
           " * Alpine:        sudo apk add libzstd-devel\n"
           " * FreeBSD:       sudo pkg install -y zstd\n"
           " * NetBSD:        sudo pkgin -y install zstd\n"
           " * OpenBSD:       sudo pkg_add zstd\n"
           " * Solaris:       sudo pkg install compress/zstd\n"
           " * Apple:         brew install zsdt")
ENDIF()


#############################################################################
#### LIBRARIES                                                           ####
#############################################################################

ADD_LIBRARY(libfileio SHARED
   fileio.h
   fileio.cc
   inputfile.cc
   inputfile.h
   outputfile.cc
   outputfile.h
)
TARGET_INCLUDE_DIRECTORIES(libfileio
                           PRIVATE ${ZSTD_INCLUDE_DIR}
                                   ${LZMA_INCLUDE_DIR}
                                   ${BZ2_INCLUDE_DIR}
                                   ${Z_INCLUDE_DIR}
                                   ${LIBIBERTY_INCLUDE_DIR})
TARGET_LINK_LIBRARIES(libfileio
                      PRIVATE ${ZSTD_LIBRARY}
                              ${LZMA_LIBRARY}
                              ${BZ2_LIBRARY}
                              ${Z_LIBRARY}
                              ${LIBIBERTY_LIBRARY})


#############################################################################
#### PROGRAMS                                                            ####
#############################################################################

# ====== Create Summary Tool ================================================
ADD_EXECUTABLE(createsummary createsummary.cc debug.h)
TARGET_INCLUDE_DIRECTORIES(createsummary
                           PRIVATE ${LIBIBERTY_INCLUDE_DIR})
TARGET_LINK_LIBRARIES(createsummary
                      PRIVATE libfileio
                              ${LIBIBERTY_LIBRARY})

# ====== Combine Summaries Tool =============================================
ADD_EXECUTABLE(combinesummaries combinesummaries.cc)
TARGET_INCLUDE_DIRECTORIES(combinesummaries
                           PRIVATE libfileio
                                   ${LIBIBERTY_INCLUDE_DIR})
TARGET_LINK_LIBRARIES(combinesummaries
                      PRIVATE libfileio
                              ${LIBIBERTY_LIBRARY})

# ====== Extract Vectors Tool ===============================================
ADD_EXECUTABLE(extractvectors extractvectors.cc)
TARGET_INCLUDE_DIRECTORIES(extractvectors
                           PRIVATE ${LIBIBERTY_INCLUDE_DIR})
TARGET_LINK_LIBRARIES(extractvectors
                      PRIVATE libfileio
                              ${LIBIBERTY_LIBRARY})
