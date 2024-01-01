# shellcheck shell=bash
# shellcheck enable=all
# vim: ft=bash
#
# Constants and functions for bash shell scripts.
# https://github.com/robin-crampton/rocr-bash-lib

[[ -n "${PROGRAM_NAME}" ]] \
  || PROGRAM_NAME="$(basename "$0")"
readonly PROGRAM_NAME

[[ -n "${PROGRAM_VERSION}" ]] \
  || PROGRAM_VERSION="1.0.0"
readonly PROGRAM_VERSION

rocr::add_carriage_returns() {
  sed 's/$/\r/'
}

rocr::assert_at_least_n_arguments() {
  (($# < 2)) \
    && rocr::function_error_exit "Too few arguments (expected 2, received $#)."
  (($# > 2)) \
    && rocr::function_error_exit "Too many arguments (expected 2, received $#)."
  (($1 >= $2)) \
    || rocr::error_exit "Too few arguments (expected at least $2, received $1)."
}

rocr::assert_date() {
  rocr::function_assert_one_argument $#
  date -d "$1" &>/dev/null \
    || rocr::error_exit "Invalid date: ${_}"
}

rocr::assert_file() {
  rocr::function_assert_nonzero_arguments $#
  local file_name
  for file_name in "$@"; do
    [[ -n "${file_name}" ]] \
      || rocr::error_exit "Missing file name."
    test -e "${file_name}" \
      || rocr::error_exit "Missing file: ${_}"
    test -f "${file_name}" \
      || rocr::error_exit "Not a regular file: ${_}"
    test -r "${file_name}" \
      || rocr::error_exit "Unreadable file: ${_}"
  done
}

rocr::assert_file_nonblank() {
  rocr::function_assert_nonzero_arguments $#
  local file_name
  for file_name in "$@"; do
    rocr::assert_file_nonempty "${file_name}"
    grep --quiet '[^[:space:]]' "${file_name}" \
      || rocr::error_exit "Blank file: ${_}"
  done
}

rocr::assert_file_nonempty() {
  rocr::function_assert_nonzero_arguments $#
  local file_name
  for file_name in "$@"; do
    rocr::assert_file "${file_name}"
    test -s "${file_name}" \
      || rocr::error_exit "Empty file: ${_}"
  done
}

rocr::assert_installed() {
  rocr::function_assert_nonzero_arguments $#
  local dependency
  for dependency in "$@"; do
    rocr::test_installed "${dependency}" \
      || rocr::error_exit "Command not found: ${_}"
  done
}

rocr::assert_length() {
  rocr::function_assert_n_arguments $# 3
  if ! rocr::test_length "$1" "$2"; then
    local -r length="$(printf "%'d" "${#1}")"
    local -r limit="$(printf "%'d" "$2")"
    local -r argument_name_lowercase="${3,,}"
    rocr::error_exit "${argument_name_lowercase^} too long: length is ${length}, limit is ${limit}."
  fi
}

rocr::assert_n_arguments() {
  (($# < 2)) \
    && rocr::function_error_exit "Too few arguments (expected 2, received $#)."
  (($# > 2)) \
    && rocr::function_error_exit "Too many arguments (expected 2, received $#)."
  (($1 < $2)) \
    && rocr::error_exit "Too few arguments (expected $2, received $1)."
  (($1 > $2)) \
    && rocr::error_exit "Too many arguments (expected $2, received $1)."
}

rocr::assert_no_arguments() {
  (($# < 1)) \
    && rocr::function_error_exit "Too few arguments (expected 1, received $#)."
  (($# > 1)) \
    && rocr::function_error_exit "Too many arguments (expected 1, received $#)."
  (($1 < 1)) \
    || rocr::error_exit "Too many arguments (expected 0, received $1)."
}

rocr::assert_nonzero_arguments() {
  (($# < 1)) \
    && rocr::function_error_exit "Too few arguments (expected 1, received $#)."
  (($# > 1)) \
    && rocr::function_error_exit "Too many arguments (expected 1, received $#)."
  (($1 > 0)) \
    || rocr::error_exit "Too few arguments (expected 1 or more, received $#)."
}

rocr::assert_one_argument() {
  (($# < 1)) \
    && rocr::function_error_exit "Too few arguments (expected 1, received $#)."
  (($# > 1)) \
    && rocr::function_error_exit "Too many arguments (expected 1, received $#)."
  (($1 < 1)) \
    && rocr::error_exit "Too few arguments (expected 1, received $1)."
  (($1 > 1)) \
    && rocr::error_exit "Too many arguments (expected 1, received $1)."
}

rocr::assert_variable_is_directory() {
  rocr::function_assert_nonzero_arguments $#
  local variable
  for variable in "$@"; do
    rocr::assert_variable_nonempty "${variable}"
    [[ -d "${!variable}" ]] \
      || rocr::error_exit "Value of environment variable ${variable} is not a directory: ${!variable}"
  done
}

rocr::assert_variable_nonempty() {
  rocr::function_assert_nonzero_arguments $#
  local variable
  for variable in "$@"; do
    declare -p "${variable}" &>/dev/null \
      || rocr::error_exit "Environment variable ${variable} is not set."
    rocr::test_variable_nonempty "${variable}" \
      || rocr::error_exit "Environment variable ${variable} is empty."
  done
}

rocr::assert_zip_file() {
  rocr::function_assert_nonzero_arguments $#
  local zip_file_name
  for zip_file_name in "$@"; do
    [[ -n "${zip_file_name}" ]] \
      || rocr::error_exit "Missing zip file name."
    [[ "${zip_file_name}" =~ \.zip$ ]] \
      || rocr::usage_error_exit "Zip file name suffix is not .zip: ${zip_file_name}"
    test -e "${zip_file_name}" \
      || rocr::error_exit "Missing zip file: ${_}"
    test -f "${zip_file_name}" \
      || rocr::error_exit "Not a regular zip file: ${_}"
    test -r "${zip_file_name}" \
      || rocr::error_exit "Unreadable zip file: ${_}"
    test -s "${zip_file_name}" \
      || rocr::error_exit "Empty zip file: ${_}"
    rocr::assert_installed unzip
    rocr::info "Checking zip file: ${zip_file_name}"
    unzip -tqq "${zip_file_name}" \
      || rocr::error_exit "Invalid zip file: ${_}"
  done
}

rocr::compress_whitespace() {
  local set_extglob_flag
  if ! shopt -q extglob; then
    shopt -s extglob
    set_extglob_flag=1
  fi
  readonly set_extglob_flag

  local -r all_arguments="$*"
  local -r single_spaces="${all_arguments//+([[:space:]])/ }"
  local -r no_leading_space="${single_spaces# }"
  local -r no_trailing_space="${no_leading_space% }"
  rocr::echo "${no_trailing_space}"

  [[ -z "${set_extglob_flag}" ]] \
    || shopt -u extglob
}

rocr::debug() {
  rocr::function_assert_nonzero_arguments $#
  rocr::log debug "$@"
}

rocr::duration_to_seconds() {
  rocr::function_assert_one_argument $#
  local -a time_component
  IFS=":" read -ra time_component <<< "$1"
  readonly time_component
  [[ "${time_component[0]}" =~ [0-9]+ ]] \
    || rocr::error_exit "Missing hours component: $1"
  local -r hours="${time_component[0]}"
  [[ "${time_component[1]}" =~ [0-9]+ ]] \
    || rocr::error_exit "Missing minutes component: $1"
  local -r minutes="${time_component[1]}"
  [[ "${time_component[2]}" =~ [0-9]+\.[0-9]+ ]] \
    || rocr::error_exit "Missing seconds component: $1"
  local -r seconds="${time_component[2]}"
  rocr::function_assert_installed bc
  local bc
  bc="$(bc -l <<< "${hours} * 60 * 60 + ${minutes} * 60 + ${seconds}")" \
    || exit
  readonly bc
  rocr::echo "${bc/#./0.}"
}

rocr::echo() {
  # https://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo
  if (($# > 0)); then
     printf '%s' "$1"
     shift
     (($# > 0)) \
       && printf ' %s' "$@"
  fi
  printf '\n'
}

rocr::error() {
  rocr::function_assert_nonzero_arguments $#
  rocr::log error "$@"
}

rocr::error_exit() {
  rocr::function_assert_nonzero_arguments $#
  rocr::error "$@"
  exit 1
}

rocr::filename_timestamp() {
  date "+%Y-%m-%d_%H%M%S"
}

rocr::format_seconds() {
  rocr::function_assert_n_arguments $# 2
  local -r format="$1"
  shift
  local remaining_seconds="$1"
  shift
  rocr::assert_installed bc
  local hours
  hours="$(bc <<< "${remaining_seconds} / 3600")" \
    || rocr::function_error_exit "Cannot calculate hours."
  readonly hours
  remaining_seconds="$(bc <<< "${remaining_seconds} - ${hours} * 3600")" \
    || rocr::function_error_exit "Cannot update remaining seconds."
  local minutes
  minutes="$(bc <<< "${remaining_seconds} / 60")" \
    || rocr::function_error_exit "Cannot calculate minutes."
  readonly minutes
  remaining_seconds="$(bc <<< "${remaining_seconds} - ${minutes} * 60")" \
    || rocr::function_error_exit "Cannot calculate seconds."
  readonly remaining_seconds
  # SC2059 (info): Don't use variables in the printf format string. Use printf '..%s..' "$foo".
  # shellcheck disable=SC2059
  printf "${format}\n" "${hours}" "${minutes}" "${remaining_seconds}"
}

rocr::function_assert_at_least_n_arguments() {
  (($# < 2)) \
    && rocr::function_error_exit "Too few arguments (expected 2, received $#)."
  (($# > 2)) \
    && rocr::function_error_exit "Too many arguments (expected 2, received $#)."
  (($1 >= $2)) \
    || rocr::error_exit "${FUNCNAME[1]}: Too few arguments (expected at least $2, received $1)."
}

rocr::function_assert_n_arguments() {
  (($# < 2)) \
    && rocr::function_error_exit "Too few arguments (expected 2, received $#)."
  (($# > 2)) \
    && rocr::function_error_exit "Too many arguments (expected 2, received $#)."
  (($1 < $2)) \
    && rocr::error_exit "${FUNCNAME[1]}: Too few arguments (expected $2, received $1)."
  (($1 > $2)) \
    && rocr::error_exit "${FUNCNAME[1]}: Too many arguments (expected $2, received $1)."
}

rocr::function_assert_no_arguments() {
  (($# < 1)) \
    && rocr::function_error_exit "Too few arguments (expected 1, received $#)."
  (($# > 1)) \
    && rocr::function_error_exit "Too many arguments (expected 1, received $#)."
  (($1 < 1)) \
    || rocr::error_exit "${FUNCNAME[1]}: Too many arguments (expected 0, received $1)."
}

rocr::function_assert_nonzero_arguments() {
  (($# < 1)) \
    && rocr::function_error_exit "Too few arguments (expected 1, received $#)."
  (($# > 1)) \
    && rocr::function_error_exit "Too many arguments (expected 1, received $#)."
  (($1 > 0)) \
    || rocr::error_exit "${FUNCNAME[1]}: Too few arguments (expected at least 1, received $1)."
}

rocr::function_assert_one_argument() {
  (($# < 1)) \
    && rocr::function_error_exit "Too few arguments (expected 1, received $#)."
  (($# > 1)) \
    && rocr::function_error_exit "Too many arguments (expected 1, received $#)."
  (($1 < 1)) \
    && rocr::error_exit "${FUNCNAME[1]}: Too few arguments (expected 1, received $1)."
  (($1 > 1)) \
    && rocr::error_exit "${FUNCNAME[1]}: Too many arguments (expected 1, received $1)."
}

rocr::function_debug() {
  rocr::debug "${FUNCNAME[1]}:" "$@"
}

rocr::function_error() {
  rocr::error "${FUNCNAME[1]}:" "$@"
}

rocr::function_error_exit() {
  rocr::error_exit "${FUNCNAME[1]}:" "$@"
}

rocr::function_test_at_least_n_arguments() {
  if (($# < 2)); then
    rocr::function_error "Too few arguments (expected 2, received $#)."
    return 2
  fi
  if (($# > 2)); then
    rocr::function_error "Too many arguments (expected 2, received $#)."
    return 2
  fi
  if (($1 < $2)); then
    rocr::error "${FUNCNAME[1]}: Too few arguments (expected at least $2, received $1)."
    return 2
  fi
}

rocr::function_test_n_arguments() {
  if (($# < 2)); then
    rocr::function_error "Too few arguments (expected 2, received $#)."
    return 2
  fi
  if (($# > 2)); then
    rocr::function_error "Too many arguments (expected 2, received $#)."
    return 2
  fi
  if (($1 < $2)); then
    rocr::error "${FUNCNAME[1]}: Too few arguments (expected $2, received $1)."
    return 2
  fi
  if (($1 > $2)); then
    rocr::error "${FUNCNAME[1]}: Too many arguments (expected $2, received $1)."
    return 2
  fi
}

rocr::function_test_nonzero_arguments() {
  if (($# < 1)); then
    rocr::function_error "Too few arguments (expected 1, received $#)."
    return 2
  fi
  if (($# > 1)); then
    rocr::function_error "Too many arguments (expected 1, received $#)."
    return 2
  fi
  if (($1 < 1)); then
    rocr::error "${FUNCNAME[1]}: Too few arguments (expected at least 1, received $1)."
    return 2
  fi
}

rocr::function_test_one_argument() {
  if (($# < 1)); then
    rocr::function_error "Too few arguments (expected 1, received $#)."
    return 2
  fi
  if (($# > 1)); then
    rocr::function_error "Too many arguments (expected 1, received $#)."
    return 2
  fi
  if (($1 < 1)); then
    rocr::error "${FUNCNAME[1]}: Too few arguments (expected 1, received $1)."
    return 2
  fi
  if (($1 > 1)); then
    rocr::error "${FUNCNAME[1]}: Too many arguments (expected 1, received $1)."
    return 2
  fi
}

rocr::get_options() {
  rocr::function_assert_at_least_n_arguments $# 2
  local short_options
  short_options="$(rocr::trim "$1")" \
    || exit
  readonly short_options
  shift
  local long_options
  long_options="$(rocr::trim "$1")" \
    || exit
  readonly long_options
  shift
  local options
  options="$(POSIXLY_CORRECT=1 getopt \
    --name "${PROGRAM_NAME}" \
    --options "${short_options}" \
    --longoptions "${long_options}" \
    -- "$@" \
    )" \
    || exit
  readonly options
  rocr::echo "${options}"
}

rocr::info() {
  rocr::function_assert_nonzero_arguments $#
  rocr::log info "$@"
}

rocr::load_id_array() {
  rocr::function_assert_at_least_n_arguments $# 2
  local -n id_array_reference="$1"
  shift
  local -r id_type_name_lowercase="${1,,}"
  shift
  [[ -n "${id_type_name_lowercase}" ]] \
    || rocr::function_error_exit "Missing id type."
  id_array_reference=()
  local -A id_associative_array
  local id
  for id in "$@"; do
    id="$(rocr::trim "${id}")" \
      || exit
    [[ -n "${id}" ]] \
      || rocr::error_exit "Empty ${id_type_name_lowercase} id found."
    rocr::test_natural_number "${id}" \
      || rocr::error_exit "${id_type_name_lowercase^} id is not a natural number: ${id}"
    [[ -z "${id_associative_array[${id}]}" ]] \
      || rocr::error_exit "Duplicate ${id_type_name_lowercase} id: ${id}"
    id_associative_array["${id}"]=1
    id_array_reference+=("${id}")
  done
}

rocr::log() {
  rocr::function_assert_at_least_n_arguments $# 2
  local -r message_log_level="$1"
  shift
  [[ -n "${message_log_level}" ]] \
    || rocr::error_exit "Missing message log level."
  local -r message_log_level_lowercase="${message_log_level,,}"
  case "${message_log_level_lowercase}" in
    all|trace|debug|info|warn|error)
      ;;
    *)
      rocr::error_exit "Invalid message log level: ${message_log_level}"
  esac
  local current_log_level_lowercase
  current_log_level_lowercase="$(rocr::verbosity_to_log_level)" \
    || exit
  readonly current_log_level_lowercase
  case "${message_log_level_lowercase}-${current_log_level_lowercase}" in
    all-all)
      ;;
    trace-trace|trace-all)
      ;;
    debug-debug|debug-trace|debug-all)
      ;;
    info-info|info-debug|info-trace|info-all)
      ;;
    warn-warn|warn-info|warn-debug|warn-trace|warn-all)
      ;;
    error-error|error-warn|error-info|error-debug|error-trace|error-all)
      ;;
    *)
      return
  esac
  if [[ -n "${ROCR_BASH_LIB_LOG_STYLE}" && "${ROCR_BASH_LIB_LOG_STYLE}" =~ logfile ]]; then
    local timestamp
    timestamp="$(date "+%Y-%m-%d %H:%M:%S.%3N")" \
      || exit
    readonly timestamp
    case "${message_log_level_lowercase}" in
      info)
        printf "${timestamp} %-5s ${PROGRAM_NAME}: $*\\n" "${message_log_level_lowercase^^}"
        ;;
      *)
        printf "${timestamp} %-5s ${PROGRAM_NAME}: $*\\n" "${message_log_level_lowercase^^}" >&2
    esac
  else
    case "${message_log_level_lowercase}" in
      info)
        rocr::echo "${PROGRAM_NAME}: ${message_log_level_lowercase}: $*"
        ;;
      warn)
        rocr::echo "${PROGRAM_NAME}: WARNING: $*" >&2
        ;;
      *)
        rocr::echo "${PROGRAM_NAME}: ${message_log_level_lowercase^^}: $*" >&2
    esac
  fi
}

rocr::plural() {
  rocr::function_assert_n_arguments $# 2
  if (($2 == 1)); then
    rocr::echo "$1"
  else
    rocr::echo "$1s"
  fi
}

rocr::remove_carriage_returns() {
  tr -d '\r'
}

rocr::remove_first_open_p_and_last_close_p_tags() {
  rocr::function_assert_one_argument $#
  sed --null-data -e 's/^\s*<p>\s*//' -e 's/\s*<\/p>\s*$//' <<< "$1"
}

rocr::replace_newlines_with_spaces() {
  # https://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-Quoting.html
  local -r without_carriage_returns="${1//[$'\r']}"
  rocr::echo "${without_carriage_returns//[$'\n']/ }"
}

rocr::seconds_to_hhmmssxxx() {
  rocr::function_assert_one_argument $#
  rocr::format_seconds '%02d:%02d:%06.3f' "$1"
}

rocr::seconds_to_hours_mmssxxx() {
  rocr::function_assert_one_argument $#
  rocr::format_seconds '%d:%02d:%06.3f' "$1"
}

rocr::set_variable_from_heredoc() {
  local -n variable="$1"
  read -r -d "" variable
}

rocr::sql_escape() {
  rocr::function_assert_one_argument $#
  rocr::echo "${1//\'/\'\'}"
}

rocr::sql_escape_multiline() {
  rocr::function_assert_one_argument $#
  sed -e "s/'/''/g" -e "s/^/        || '/" -e "s/\$/' || CHR(10)/" <<< "$1"
}

rocr::sql_escaped_or_clause() {
  rocr::function_assert_at_least_n_arguments $# 1
  local column_name="$1"
  shift
  local argument
  local or_clause
  for argument in "$@"; do
    if [[ -z "${or_clause}" ]]; then
      or_clause="${column_name} = '""${argument//\'/\'\'}""'"
    else
      # Include a newline to avoid "SP2-0027: Input is too long", an Oracle SQL*Plus limitation.
      or_clause+="
         OR ${column_name} = ""'""${argument//\'/\'\'}""'"
    fi
  done
  rocr::echo "${or_clause}"
}

rocr::sql_to_csv() {
  # The output of this function is likely to be read via process substitution,
  # so return an error code rather than exiting the subshell.
  rocr::function_test_nonzero_arguments $# \
    && rocr::sqlplus_with_markup "CSV ON QUOTE OFF" "$@"
}

rocr::sql_to_quoted_csv() {
  # The output of this function is likely to be read via process substitution,
  # so return an error code rather than exiting the subshell.
  rocr::function_test_nonzero_arguments $# \
    && rocr::sqlplus_with_markup "CSV ON QUOTE ON" "$@"
}

rocr::sqlplus_with_markup() {
  # The output of this function is likely to be read via process substitution,
  # so return an error code rather than exiting the subshell.
  rocr::function_test_at_least_n_arguments $# 2 \
    || return
  local -r markup="$1"
  shift
  if [[ -z "${markup}" ]]; then
    rocr::function_error "Missing markup."
    return 2
  fi
  if ! rocr::test_installed sqlplus; then
    rocr::error "Command not found: ${_}"
    return 1
  fi
  if ! rocr::test_database_connection "$@"; then
    rocr::error "Cannot connect to the database."
    return 1
  fi
  local input
  if ! input="$(</dev/stdin)"; then
    rocr::error "Cannot read standard input."
    return 1
  fi
  input="
SET HEADING OFF
SET FEEDBACK OFF
SET LONG 999999999
${input}
"
  local -r nls_lang="${NLS_LANG}"
  export NLS_LANG=".AL32UTF8"
  local output
  local sqlplus_error
  output="$(sqlplus -S -M "${markup}" "$@" <<< "${input}")" \
    || sqlplus_error=1
  if [[ -n "${nls_lang}" ]]; then
    NLS_LANG="${nls_lang}"
  else
    unset NLS_LANG
  fi
  if [[ -n "${sqlplus_error}" ]]; then
    rocr::error "Cannot run the SQL."
    return 1
  fi
  output="$(tr -d '\r' <<< "${output}")" \
    || return 1
  # Print the output, deleting the last line if it's blank.
  sed '${/./!d}' <<< "${output}" \
    || true
}

rocr::test_database_connection() {
  rocr::function_test_nonzero_arguments $# \
    || return
  rocr::test_installed sqlplus \
    || return
  local -r nls_lang="${NLS_LANG}"
  export NLS_LANG=".AL32UTF8"
  local output
  local sqlplus_error
  output="$(sqlplus -S -M "CSV ON QUOTE OFF" "$@" <<!
SET HEADING OFF
SET FEEDBACK OFF
SELECT 'deadc0de' FROM dual;
!
    )" \
    || sqlplus_error=1
  if [[ -n "${nls_lang}" ]]; then
    NLS_LANG="${nls_lang}"
  else
    unset NLS_LANG
  fi
  if [[ -n "${sqlplus_error}" ]]; then
    rocr::function_debug "Cannot connect to the database."
    return 1
  fi
  if ! grep --fixed-strings --quiet 'deadc0de' <<< "${output}"; then
    rocr::function_debug "Cannot query the database."
    return 1
  fi
}

rocr::test_email_address() {
  rocr::function_test_one_argument $# \
    || return
  # https://en.wikipedia.org/wiki/Email_address#Syntax
  if [[ ! "$1" =~ ^[^@]{1,64}@([[:alnum:]-]{1,63}.)+[[:alnum:]-]{1,63}$ ]]; then
    rocr::function_debug "Invalid email address: $1"
    return 1
  fi
}

rocr::test_installed() {
  rocr::function_test_nonzero_arguments $# \
    || return
  local missing_dependency_flag
  local dependency
  for dependency in "$@"; do
    if ! hash "${dependency}" 2>/dev/null; then
      rocr::function_debug "Command not found: ${_}"
      missing_dependency_flag=1
    fi
  done
  [[ -z "${missing_dependency_flag}" ]]
}

rocr::test_iso_calendar_date() {
  rocr::function_test_one_argument $# \
    || return
  # https://en.wikipedia.org/wiki/ISO_8601#Calendar_dates
  if [[ ! "$1" =~ ^[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$ && ! "$1" =~ ^[[:digit:]]{4}[[:digit:]]{2}[[:digit:]]{2}$ ]]; then
    rocr::function_debug "Invalid ISO-8601 calendar date format: $1"
    return 1
  fi
  if ! date --date="$1" &>/dev/null; then
    rocr::function_debug "Invalid ISO-8601 calendar date: $1"
    return 1
  fi
}

rocr::test_iso_date_time_basic() {
  rocr::function_test_one_argument $# \
    || return
  # https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations
  if [[ ! "$1" =~ ^[[:digit:]]{4}[[:digit:]]{2}[[:digit:]]{2}T[[:digit:]]{2}[[:digit:]]{2}$ ]]; then
    rocr::function_debug "Invalid ISO-8601 basic combined date and time format: $1"
    return 1
  fi
  if ! date --date="$1" &>/dev/null; then
    rocr::function_debug "Invalid ISO-8601 basic combined date and time: $1"
    return 1
  fi
}

rocr::test_iso_date_time_extended() {
  rocr::function_test_one_argument $# \
    || return
  # https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations
  if [[ ! "$1" =~ ^[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}T[[:digit:]]{2}:[[:digit:]]{2}$ ]]; then
    rocr::function_debug "Invalid ISO-8601 extended combined date and time format: $1"
    return 1
  fi
  if ! date --date="$1" &>/dev/null; then
    rocr::function_debug "Invalid ISO-8601 extended combined date and time: $1"
    return 1
  fi
}

rocr::test_iso_extended_time_hhmm() {
  rocr::function_test_one_argument $# \
    || return
  # https://en.wikipedia.org/wiki/ISO_8601#Times
  if ! [[ "$1" =~ ^[[:digit:]]{2}:[[:digit:]]{2}$ ]]; then
    rocr::function_debug "Invalid ISO-8601 extended time format: $1"
    return 1
  fi
  if ! date --date="1970-01-01 $1" &>/dev/null; then
    rocr::function_debug "Invalid ISO-8601 extended time: $1"
    return 1
  fi
}

rocr::test_length() {
  rocr::function_test_n_arguments $# 2 \
    || return
  if [[ ! "$2" =~ ^[[:digit:]]+$ ]]; then
    rocr::function_error "Invalid length: $2"
    return 2
  fi
  ((${#1} <= $2))
}

rocr::test_natural_number() {
  rocr::function_test_one_argument $# \
    || return
  [[ "$1" =~ ^[[:digit:]]+$ ]]
}

rocr::test_real_nonnegative_number() {
  rocr::function_test_one_argument $# \
    || return
  [[ "$1" =~ ^[[:digit:]]+(\.[[:digit:]]+)?$ ]]
}

rocr::test_variable_nonempty() {
  rocr::function_test_one_argument $# \
    || return
  [[ -n "${!1}" ]]
}

rocr::tidy() {
  rocr::function_assert_nonzero_arguments $#
  rocr::assert_installed tidy
  tidy \
    -asxhtml \
    -quiet \
    -utf8 \
    -wrap 0 \
    --break-before-br 1 \
    --doctype "omit" \
    --indent "yes" \
    --show-body-only "yes" \
    --show-warnings "no" \
    "$@"
}

rocr::to_csv() {
  local csv
  local i
  for i in "$@"; do
    if [[ -z "${csv}" ]]; then
      csv="${i}"
    else
      csv+=", ${i}"
    fi
  done
  rocr::echo "${csv}"
}

rocr::to_csv_from_lines() {
  # Skip blank lines and comments.
  local line
  local csv
  while IFS= read -r line; do
    line="$(rocr::trim "${line}")" \
      || exit
    [[ -z "${line}" || "${line:0:1}" == "#" ]] \
      && continue
    if [[ -z "${csv}" ]]; then
      csv="${line}"
    else
      csv+=", ${line}"
    fi
  done
  rocr::echo "${csv}"
}

rocr::to_sql_escaped_csv() {
  local i
  local csv
  for i in "$@"; do
    if [[ -z "${csv}" ]]; then
      csv="'""${i//\'/\'\'}""'"
    else
      csv+=", ""'""${i//\'/\'\'}""'"
    fi
  done
  rocr::echo "${csv}"
}

rocr::to_sql_escaped_csv_from_lines() {
  # Skip blank lines and comments.
  local line
  local csv
  while IFS= read -r line; do
    line="$(rocr::trim "${line}")" \
      || exit
    [[ -z "${line}" || "${line:0:1}" == "#" ]] \
      && continue
    if [[ -z "${csv}" ]]; then
      csv="'""${line//\'/\'\'}""'"
    else
      csv+=", ""'""${line//\'/\'\'}""'"
    fi
  done
  rocr::echo "${csv}"
}

rocr::trace() {
  rocr::function_assert_nonzero_arguments $#
  rocr::log trace "$@"
}

rocr::trim() {
  local set_extglob_flag
  if ! shopt -q extglob; then
    shopt -s extglob
    set_extglob_flag=1
  fi
  readonly set_extglob_flag

  local -r all_arguments="$*"
  local -r no_leading_spaces="${all_arguments##+([[:space:]])}"
  local -r no_trailing_spaces="${no_leading_spaces%%+([[:space:]])}"
  rocr::echo "${no_trailing_spaces}"

  [[ -z "${set_extglob_flag}" ]] \
    || shopt -u extglob
}

# SC2120 (warning): rocr::usage_error_exit references arguments, but none are ever passed.
# shellcheck disable=SC2120
rocr::usage_error_exit() {
  (($# < 1)) \
    || rocr::error "$@"
  rocr::echo "Try ${PROGRAM_NAME} --help for more information." >&2
  exit 2
}

rocr::usage_error_help_exit() {
  rocr::function_assert_nonzero_arguments $#
  rocr::error "$1"
  shift
  if [[ -n "$1" ]]; then
    rocr::echo "$@" >&2
  else
    rocr::echo "Try ${PROGRAM_NAME} --help for more information." >&2
  fi
  exit 2
}

rocr::usage_help_exit() {
  rocr::function_assert_nonzero_arguments $#
  rocr::echo "$@"
  exit 0
}

rocr::verbosity_to_log_level() {
  local verbosity_level="${VERBOSITY:-0}"
  rocr::test_natural_number "${verbosity_level}" \
    || verbosity_level=0
  if ((verbosity_level <= 0)); then
    rocr::echo "warn"
  elif ((verbosity_level == 1)); then
    rocr::echo "info"
  elif ((verbosity_level == 2)); then
    rocr::echo "debug"
  elif ((verbosity_level == 3)); then
    rocr::echo "trace"
  else
    rocr::echo "all"
  fi
}

rocr::version_exit() {
  if [[ -n "${PROGRAM_PACKAGE}" ]]; then
    rocr::echo "${PROGRAM_NAME} (${PROGRAM_PACKAGE:?}) ${PROGRAM_VERSION}"
  else
    rocr::echo "${PROGRAM_NAME} ${PROGRAM_VERSION}"
  fi
  [[ -z "${PROGRAM_ATTRIBUTION}" ]] \
    || rocr::echo "${PROGRAM_ATTRIBUTION:?}"
  exit 0
}

rocr::warn() {
  rocr::function_assert_nonzero_arguments $#
  rocr::log warn "$@"
}
