//
// Copyright 2009 Google Inc.
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
// Foundation, Inc., 51 Franklin Street, 5th Floor, Boston, MA 02110-1301, USA.

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

#include "MaoDebug.h"
#include "MaoPlugin.h"

void LoadPlugin(const char *path) {
  fprintf(stderr, "Loading plugin %s\n", path);

  char *error;
  void *lib_handle = dlopen(path, RTLD_NOW);

  MAO_ASSERT_MSG(lib_handle, "%s",  dlerror());

  // Clear any pending dlerror messages
  dlerror();

  // Load the version symbol from the plugin
  PluginVersion *version;
  version = static_cast<PluginVersion *>(dlsym(lib_handle, "mao_plugin_version"));
  if ((error = dlerror()) != NULL)
    MAO_ASSERT_MSG(false, "%s", error);

  MAO_ASSERT_MSG(version->major == MAO_MAJOR_VERSION,
                 "Plugin version %d.%d does not match MAO version %d.%d",
                 version->major, version->minor,
                 MAO_MAJOR_VERSION, MAO_MINOR_VERSION);

  // Load the init function from the plugin
  void (*init)();

  // See the dlopen man page for an explanation of the strange casting
  init = (void (*)())dlsym(lib_handle, "MaoInit");
  if ((error = dlerror()) != NULL)
    MAO_ASSERT_MSG(false, "%s", error);

  init();
}
