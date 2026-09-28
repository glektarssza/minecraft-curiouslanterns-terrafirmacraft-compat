#!/usr/bin/env bash
set +x +e

declare -A EXIT_CODES=(
    [SUCCESS]=0
    [UNSUPPORTED_SHELL]=1
    [EXISTING_ARCHIVE_REMOVAL_FAILED]=2
    [ARCHIVE_GENERATION_FAILED]=3
)

declare -A EXIT_MESSAGES=(
    [SUCCESS]="Successfully generated datapack archive!"
    [UNSUPPORTED_SHELL]="Unsupported shell! Please use bash, ksh93, or zsh."
    [EXISTING_ARCHIVE_REMOVAL_FAILED]="Failed to remove existing datapack archive!"
    [ARCHIVE_GENERATION_FAILED]="Failed to generate datapack archive!"
)

SCRIPT_DIR="$( (
    function get_script_dir() {
        pushd . 2>&1 > /dev/null || return 1
        local SCRIPT_PATH
        if [[ -n "${BASH}" ]]; then
            # shellcheck disable=SC2128
            SCRIPT_PATH="${BASH_SOURCE}"
        elif [[ -n "${ZSH_VERSION}" ]]; then
            # shellcheck disable=SC2296
            SCRIPT_PATH="${(%):-%x}"
        elif [[ -n "${TMOUT}" ]]; then
            # shellcheck disable=SC2296
            SCRIPT_PATH="${.sh.file}"
        elif [[ "${0##*/}" == "dash" ]]; then
            local x
            x="$(lsof -p $$ -Fn0 | tail -1)"
            # shellcheck disable=SC2296
            SCRIPT_PATH="${x#n}"
        else
            printf '\e[38;5;196m[ERROR]\e[0m %s' "${EXIT_MESSAGES[UNSUPPORTED_SHELL]}" 1>&2
            # shellcheck disable=SC2086
            return ${EXIT_CODES[UNSUPPORTED_SHELL]}
        fi
        while [[ -L "${SCRIPT_PATH}" ]]; do
            cd "$(dirname -- "${SCRIPT_PATH}")" || return 2
            SCRIPT_PATH="$(readlink -e -- "$SCRIPT_PATH")"
        done
        cd "$(dirname -- "$SCRIPT_PATH")" > /dev/null || return 2
        SCRIPT_PATH="$(pwd)"
        popd 2>&1 > /dev/null || return 3
        echo "${SCRIPT_PATH}"
        return 0
    }
    get_script_dir
))"

_LIB_PATH="$(readlink -e -- "${SCRIPT_DIR}/scripts/lib/")"

# shellcheck source=./scripts/lib/logging.sh
source "${_LIB_PATH}/logging.sh"

# -- The path to the project root directory
PROJECT_ROOT="$(readlink -e -- "${SCRIPT_DIR}/")"

VERSION="$(git describe --tags 2> /dev/null)"

ARCHIVE="${PROJECT_ROOT}/curiouslanterns-terrafirmacraft-compat-$(if [[ -n "${VERSION}" && $* =~ --release ]]; then echo "${VERSION}"; else echo "vDEV"; fi).zip"

lib::logging::info "Starting to generate datapack archive..."

if [[ -f "${ARCHIVE}" ]]; then
    lib::logging::info "Removing existing datapack archive..."
    rm "${ARCHIVE}"
    RESULT=$?
    if [[ ${RESULT} -ne 0 ]]; then
        lib::logging::error "${EXIT_MESSAGES[EXISTING_ARCHIVE_REMOVAL_FAILED]}"
        # shellcheck disable=SC2086
        exit ${EXIT_CODES[EXISTING_ARCHIVE_REMOVAL_FAILED]}
    fi
fi

zip -r -9 -UN=UTF8 "${ARCHIVE}" "${PROJECT_ROOT}/data/" \
    "${PROJECT_ROOT}/pack.mcmeta" "${PROJECT_ROOT}/pack.png"
RESULT=$?

if [[ ${RESULT} -ne 0 ]]; then
    lib::logging::error "${EXIT_MESSAGES[ARCHIVE_GENERATION_FAILED]}"
    # shellcheck disable=SC2086
    exit ${EXIT_CODES[ARCHIVE_GENERATION_FAILED]}
fi

lib::logging::info "${EXIT_MESSAGES[SUCCESS]}"
# shellcheck disable=SC2086
exit ${EXIT_CODES[SUCCESS]}
