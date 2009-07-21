//
// Copyright 2008 Google Inc.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#ifndef MAO_H_
#define MAO_H_
#define MAO_REVISION "$Rev$"
//#define MAO_VERSION "0.1 r" REV_NUM
#define MAO_VERSION "0.1 " MAO_REVISION

// gas main entry point
extern "C" {
// gas main entry point
int as_main (int argc, char ** argv);
const char *get_default_arch ();
}

#endif  // MAO_H_
