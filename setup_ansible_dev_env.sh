#!/usr/bin/env -S bash - 
#===============================================================================
#
#          FILE: setup_ansible_dev_env.sh
#
#         USAGE: ./setup_ansible_dev_env.sh 
#
#   DESCRIPTION: This script will setup a dev-environment for ansible in the
#                directory where it is run.
#
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Marco Markgraf (mma), marco.markgraf@gmx.de
#  ORGANIZATION: NPG
#       CREATED: 2020-12-06 11:17
#       LICENSE: BSD-2-CLAUSE
#      REVISION:  ---
#===============================================================================

#=== Init ======================================================================
set -o nounset   # exit on unset variables.
set -o errexit   # exit on any error.
set -o errtrace  # any trap on ERR is inherited
#set -o xtrace    # show expanded command before execution.

unalias -a       # avoid rm being aliased to rm -rf and similar issues
LANG=C           # avoid locale issues
VERBOSE=         # Don't be verbose, unless given '-v'-option
WORKINGDIR="$(pwd)"
NEEDED_PACKAGES='git python3-venv'
PACKAGE_LIST=''

ScriptVersion="1.0"

trap "cleanup" EXIT SIGTERM

#=== Functions =================================================================
usage (){
  echo "

  Usage :  ${0##/*/} [options] [--]

  Options:
  -h|--help     Display this message
  -V|--version  Display script version
  -v|--verbose  Print informational text
  -t|--target   Set the name of your dev-env directory
                Defaults to '${WORKINGDIR}'

  "
  exit 0
}    # ----------  end of function usage  ----------

option_handling () {
  # see /usr/share/doc/util-linux/examples/getopt-parse.bash
  OPTS=$(getopt --name "$0" \
    --options hVvt: \
    --longoptions help,version,verbose,target: \
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
      -t|--target)
        TARGETDIR="$2"
        shift 2
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
for item in $NEEDED_PACKAGES ; do
  dpkg -l $item > /dev/null 2>&1 || PACKAGE_LIST+=" $item"
done

if [ ${#PACKAGE_LIST} -gt 0 ] ; then
  _notice "Need to install: $PACKAGE_LIST"
  sudo apt -y install $PACKAGE_LIST
fi

if [ -d "${WORKINGDIR}/.git" ]; then
  _verbose 'Removing previously existing .git directory' | _green
  rm -rf "${WORKINGDIR}/.git"
fi

if [ -d "${WORKINGDIR}/.venv" ]; then
  _verbose 'Removing previously existing .venv directory' | _green
  rm -rf "${WORKINGDIR}/.venv"
fi

_verbose "Setup virtual environment in .venv" | _green
python3 -m venv ${WORKINGDIR}/.venv

_verbose "Install ansible..." | _green
${WORKINGDIR}/.venv/bin/pip3 install ansible

for item in ${WORKINGDIR}/requirements.*.txt; do
  _verbose "Install $item ..." | _green
  if [[ -s ${item} ]]; then
    ${WORKINGDIR}/.venv/bin/pip3 install -r ${item}
  else
    printf '%s\n' "$item is empty. Nothing to do"
  fi
done

if [ ! -z ${TARGETDIR+x} ] ; then
  _notice "Renameing ${WORKINGDIR} to ${WORKINGDIR%/*}/${TARGETDIR}" | _green
  mv "${WORKINGDIR}" "${WORKINGDIR%/*}/${TARGETDIR}"
  cd "${WORKINGDIR%/*}/${TARGETDIR}"
fi

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

