<!--
  SPDX-FileCopyrightText: 2025 Soulfind Contributors
  SPDX-License-Identifier: GPL-3.0-or-later
-->

# winsqlite3 Library Bindings

Windows needs a .lib file to link against the system winsqlite3 dll, but such
files are only shipped with the Windows SDK, which is huge. To avoid this
hassle, we generate .lib files ourselves using a .def file listing exported
functions.

Whenever you use new sqlite functions, you must add them to the .def file.
GitHub Actions will then generate the new .lib files for you, and commit them
to your branch.
