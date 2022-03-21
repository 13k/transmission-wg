# shellcheck shell=bash

SCAN_DIR="/var/run/s6/services"
WAITSVC_MAX_RETRIES=25

logf() {
  local level="${1:?}"
  local format="${2:?}"

  shift 2

  level="${level^^}"

  printf "[%s] ${format}\n" "$level" "$@"
}

infof() {
  logf "info" "$@"
}

warnf() {
  logf "warn" "$@" >&2
}

errorf() {
  logf "error" "$@" >&2
}

fatalf() {
  errorf "$@"
  exit 1
}

fatalw() {
  errorf "$@"
  sleep infinity
  exit 1
}

write_credentials() {
  local username="${1:?}"
  local password="${2:?}"
  local file="${3:?}"

  infof "Writing credentials to %s" "$file"

  mkdir -p "$(dirname "$file")" || return $?
  printf "%s\n%s\n" "$username" "$password" >"$file" || return $?
  chmod 600 "$file" || return $?
}

read_credentials() {
  local file="${1:?}"
  local -a arr
  local -n arr_ref="${2:?}"

  infof "Reading credentials from %s" "$file"

  readarray -t arr <"$file" || return $?

  arr_ref["username"]="${arr[0]}"
  # shellcheck disable=2034
  arr_ref["password"]="${arr[1]}"

  return 0
}

wait_service() {
  local service="${1:?}"
  local servicedir="${SCAN_DIR:?}/${service}"

  infof "Waiting service %s (%s) to start" "${service@Q}" "$servicedir"

  # local retries=0

  # while ! s6-svok "$servicedir"; do
  #   if [[ "$((retries++))" -eq "$WAITSVC_MAX_RETRIES" ]]; then
  #     fatalf "Failed to wait for service %s (reached max [%s] retries)" \
  #       "${service@Q}" "$WAITSVC_MAX_RETRIES"
  #   fi

  #   sleep 0.2
  # done

  s6-svwait -U "$servicedir"

  local ret=$?

  if [[ $ret -ne 0 ]]; then
    errorf "Failed to wait for service %s (exit code: %s)" "${service@Q}" "$ret"
    exit $ret
  fi

  infof "Service %s (%s) is up" "${service@Q}" "$servicedir"

  return 0
}

notify_startup() {
  # assume fd 3
  echo >&3
}

wait_forever() {
  sleep infinity &
  wait
}

start_noop_service() {
  exec "/app/noop_service" "$@"
}
