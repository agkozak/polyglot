#              _                 _
#   __ _  __ _| | _____ ______ _| | __
#  / _` |/ _` | |/ / _ \_  / _` | |/ /
# | (_| | (_| |   < (_) / / (_| |   <
#  \__,_|\__, |_|\_\___/___\__,_|_|\_\
#        |___/
#
# agkozak Git Prompt
#
# A Dynamic color Git prompt for zsh, bash, ksh93, mksh, and dash
#
# Copyright (C) 2017 Alexandros Kozák
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
#
# https://github.com/agkozak/agkozak-git-prompt
#

# shellcheck disable=SC2148

# Compile agkozak-git-prompt.sh with zcompile when necessary
if [[ ${0:a:h}/agkozak-git-prompt.sh -nt ${0:a:h}/agkozak-git-prompt.sh.zwc ]] || [[ ! -e ${0:a:h}/agkozak-git-prompt.sh.zwc ]]; then
  zcompile "${0:a:h}/agkozak-git-prompt.sh"
fi

#shellcheck source=/dev/null
 . "${0:a:h}/agkozak-git-prompt.sh"
