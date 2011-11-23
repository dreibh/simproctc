# $Id$
# ###########################################################################
#             Thomas Dreibholz's R Simulation Scripts Collection
#                  Copyright (C) 2005-2012 Thomas Dreibholz
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


# Get the MD5 sum of a string (using the md5sum program)
getMD5SumOfString <- function(string)
{
   command <- paste(sep="", "echo MD5Sum StdIn && echo -n \"1 \" && (echo \"", string, "\" | md5sum)")
   table <- read.table(pipe(command))
   return(as.character(table$MD5Sum))
}

# Get the SHA1 sum of a string (using the sha1sum program)
getSHA1SumOfString <- function(string)
{
   command <- paste(sep="", "echo SHA1Sum StdIn && echo -n \"1 \" && (echo \"", string, "\" | sha1sum)")
   table <- read.table(pipe(command))
   return(as.character(table$SHA1Sum))
}
