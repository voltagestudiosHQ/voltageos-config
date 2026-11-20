#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'test-docker: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'Usage: %s [--gui] [--presist|--persist]\n' "$0"
}

gui=false
presist=false
while (($#)); do
  case "$1" in
    --gui) gui=true ;;
    --presist|--persist) presist=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) usage >&2; die "unknown option: $1" ;;
  esac
  shift
done

command -v docker >/dev/null 2>&1 || die "required command not found: docker"

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
image_name=voltageos-config-test
docker build \
  --tag "$image_name" \
  --file "$repo_root/.devcontainer/Dockerfile" \
  "$repo_root"
if [[ "$gui" == true ]]; then
  gui_image_name="${image_name}-gui"
  docker build \
    --build-arg "BASE_IMAGE=$image_name" \
    --tag "$gui_image_name" \
    --file "$repo_root/.devcontainer/gui.Dockerfile" \
    "$repo_root"
  image_name="$gui_image_name"
fi

docker_args=(--init --workdir /home/vscode)
if [[ "$presist" == true ]]; then
  mkdir -p "$repo_root/presisted"
  docker_args+=(
    --volume "$repo_root/presisted:/home/vscode"
    --env HOME=/home/vscode
    --user "$(id -u):$(id -g)"
  )
else
  docker_args+=(--user vscode)
fi

if [[ "$gui" != true ]]; then
  exec docker run --rm -it "${docker_args[@]}" "$image_name" /bin/bash -l
fi

command -v curl >/dev/null 2>&1 || die "GUI mode requires curl to check noVNC startup"
container_name="voltageos-test-$$"
novnc_url='http://localhost:6080/vnc.html?autoconnect=true&resize=scale'
docker run \
  --rm \
  --detach \
  --publish 127.0.0.1:6080:6080 \
  --name "$container_name" \
  "${docker_args[@]}" \
  "$image_name" /usr/local/bin/voltageos-gui-session
cleanup() {
  docker stop "$container_name" >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

gui_ready=false
for ((attempt = 0; attempt < 50; attempt++)); do
  if curl --fail --silent "$novnc_url" >/dev/null; then
    gui_ready=true
    break
  fi
  if [[ "$(docker inspect --format '{{.State.Running}}' "$container_name")" != true ]]; then
    docker logs "$container_name" >&2 || true
    die "GUI container exited before noVNC became ready"
  fi
  sleep 0.2
done
if [[ "$gui_ready" != true ]]; then
  docker logs "$container_name" >&2 || true
  die "noVNC did not become ready at $novnc_url"
fi

printf 'noVNC: %s\n' "$novnc_url"
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$novnc_url" >/dev/null 2>&1 \
    || printf 'Could not open a browser automatically; open %s\n' "$novnc_url" >&2
else
  printf 'xdg-open not found; open %s in a browser\n' "$novnc_url"
fi

docker logs --follow "$container_name"
