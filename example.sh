#!/usr/bin/env bash
# shellcheck enable=all
# vim: ft=bash
#
# An example bash shell script using rocr_bash_lib.sh.

# https://github.com/robin-crampton/rocr-bash-lib
export PROGRAM_VERSION="1.0.0"
export PROGRAM_SUPPORT="\
Report bugs to <bugs@example.com>"
export PROGRAM_ATTRIBUTION="\
Written by Author Example <author@example.com>"
export PROGRAM_PACKAGE="example package"
# shellcheck source=./rocr_bash_lib.sh
source "${ROCR_BASH_LIB_PATH:-/opt/rocr-bash-lib/rocr_bash_lib.sh}" \
  || exit

main() {
  local usage
  rocr::set_variable_from_heredoc usage <<!
Usage: ${PROGRAM_NAME} [OPTION]... EXAMPLE

An example bash shell script using rocr_bash_lib.sh.

  -v, --verbose   print more information about progress (cumulative)
      --help      display this help and exit
      --version   output version information and exit

${PROGRAM_SUPPORT}
!
  readonly usage

  # Parse the command line.
  local options
  options="$(rocr::get_options \
    "v" \
    "verbose,help,version" \
    "$@")" \
    || exit 2
  readonly options
  eval set -- "${options}"
  while true; do
    case "$1" in
      -v|--verbose)
        shift
        export VERBOSITY="$((${VERBOSITY:-0} + 1))"
        ;;
      --help)
        rocr::usage_help_exit "${usage}"
        ;;
      --version)
        rocr::version_exit
        ;;
      --)
        break
        ;;
      *)
        rocr::usage_error_exit
    esac
  done
  shift

  # Check the arguments.
  (($# < 1)) \
    && rocr::usage_error_help_exit "Too few arguments." "${usage}"
  (($# > 1)) \
    && rocr::usage_error_exit "Too many arguments."

  # Check for dependencies.
  rocr::assert_installed \
    ls
  rocr::assert_variable_nonempty \
    PATH

  # Do stuff here.
  rocr::trace "Example trace message."
  rocr::debug "Example debug message."
  rocr::info "Example informative message."
  #rocr::warn "Example warning message."
  #rocr::error "Example error message."
  rocr::info "Done."
}

main "$@"
