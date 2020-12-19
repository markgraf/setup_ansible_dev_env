#!/usr/bin/env -S bash - 
#===============================================================================
#
#          FILE: setup_ansible_dev_env.sh
#
#         USAGE:
#         $ git clone https://github.com/markgraf/setup_ansible_dev_env.git MyAwesomeAnsibleProject
#         $ ./setup_ansible_dev_env.sh [hvV]
#
#   DESCRIPTION: This script will setup a dev-environment for ansible in the
#                directory where it is run.
#
#       OPTIONS: try -h|--help
#  REQUIREMENTS: git, python3-venv
#        AUTHOR: Marco Markgraf (mma), marco.markgraf@gmx.de
#       CREATED: 2020-12-06 11:17
#       LICENSE: BSD-2-CLAUSE
#===============================================================================

#=== Init ======================================================================
set -o nounset   # exit on unset variables.
set -o errexit   # exit on any error.
set -o errtrace  # any trap on ERR is inherited
#set -o xtrace    # show expanded command before execution.

unalias -a       # avoid rm being aliased to rm -rf and similar issues
LANG=C           # avoid locale issues
VERBOSE=         # Don't be verbose, unless given '-v'-option
workingdir="$(pwd)"
needed_packages=' \
  git \
  libssl-dev \
  python3-pip \
  python3-vagrant \
  python3-venv \
  '
package_list=''

ScriptVersion="1.2"

trap "cleanup" EXIT SIGTERM

#=== Functions =================================================================
usage (){
  echo "

  Usage :  ${0##/*/} [options] [--]

  Description:
      Basic setup of an Ansible development environment.

  Options:
  -h|--help     Display this message
  -V|--version  Display script version
  -v|--verbose  Print informational text

  "
  exit 0
}    # ----------  end of function usage  ----------

option_handling () {
  # see /usr/share/doc/util-linux/examples/getopt-parse.bash
  OPTS=$(getopt --name "$0" \
    --options hVv \
    --longoptions help,version,verbose \
    --shell bash \
    -- "$@") \
    || (echo; echo "See above and try \"$0 --help\""; echo ; exit 1)

  eval set -- "$OPTS"
  unset OPTS

  while true ; do
    case "$1" in
      -h|--help)
        usage
        ;;
      -V|--version)
        echo "$0 -- Version $ScriptVersion"; exit 0
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      --)
        shift ; break
        ;;
      *)
        echo "I don't know what to do with \"$1\". Try $0 --help"
        exit 1
        ;;
    esac
  done
} # ----------  end of function option_handling  ----------

cleanup () { # Will be called by the trap above, no need to call it manually.
  :
} # ----------  end of function cleanup  ----------

_notice () { # yellow on blue NOTE, followed by $@
        if [ -t 0 ]; then
                >&2 printf '%s\n' "$(tput bold; tput setaf 3; tput setab 4) NOTE  $(tput sgr0) $@"
        else
                >&2 printf '[NOTE ] %s\n' "$@"
        fi
} # ----------  end of function _notice  ----------

_green () { tput setaf 2; [ -t 0 ] || cat; printf '%b' "$@"; tput sgr0; }

_verbose () { # printf '%s\n' if VERBOSE, be silent otherwise
  if [[ ${VERBOSE} ]]; then
    _verbose() {
      printf '%s\n' "$@"
    }
    _verbose "$@"
  else
    _verbose() {
      :
    }
  fi
} # ----------  end of function _verbose  ----------

option_handling "$@"

_notice "=== Setting up Ansible Dev-Environment ========================================="

_verbose 'Checking if needed packages are present...' | _green
for item in $needed_packages ; do
  dpkg -l $item > /dev/null 2>&1 || package_list+=" $item"
done

if [ ${#package_list} -gt 0 ] ; then
  _notice "Need to install: $package_list"
  sudo apt -y install $package_list
fi

if [ -f "${workingdir}/.delete.me" ] ; then
  _verbose 'Removing previously existing .git directory to make this yours.' | _green
  rm -rf "${workingdir}/.git"
  rm -f "${workingdir}/.delete.me"
fi

if [ -d "${workingdir}/.venv" ]; then
  _verbose 'Removing previously existing .venv directory' | _green
  rm -rf "${workingdir}/.venv"
fi

_verbose "Setup virtual environment in .venv" | _green
python3 -m venv ${workingdir}/.venv

_verbose 'upgrading pip, setuptools and wheel to avoid "error: invalid command "bdist_wheel"' | _green
${workingdir}/.venv/bin/pip3 install --upgrade pip setuptools wheel

for item in ${workingdir}/requirements.*.txt; do
  _verbose "Processing $item ..." | _green
  if [[ -s ${item} ]]; then
    ${workingdir}/.venv/bin/pip install -r ${item}
  else
    _verbose "$item is empty. Nothing to do." | _green
  fi
done

for item in ${workingdir}/requirements.*.yml; do
  _verbose "Processing $item ..." | _green
  filesize=$(stat -c%s "$item")
  if (( filesize > 4 )); then
    ${workingdir}/.venv/bin/ansible-galaxy install -r ${item}
  else
    printf '%s\n' "$item is empty. Nothing to do" | _green
  fi
done

_notice 'Clearing license and readme.  This is yours now!'

cat <<- ENDOFTEXT > LICENSE
  You should put a license here.
  Have a look at https://opensource.org/licenses
ENDOFTEXT

cat <<- ENDOFTEXT > README.md
  Title of your project
  =====================

  And a good description here.
ENDOFTEXT

_verbose "Initialize git-repo" | _green
git init
git add .
git commit -m 'Initial commit'

_notice "=== Done! ======================================================================"

#=== End =======================================================================
