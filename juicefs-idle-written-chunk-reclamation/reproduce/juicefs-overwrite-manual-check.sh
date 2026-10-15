#!/usr/bin/env bash
set -euo pipefail
umask 077

# Only write a new dataset and observe space. No mount, reads, GC, or cleanup.
HOURS=1
INTERVAL=300
MNT=/data/reliability-lt-results/manual-overwrite-check/mnt
while (( $# )); do
    case "$1" in
        --hours|--interval|--mount)
            (( $# >= 2 )) || { printf 'Missing argument: %s\n' "$1" >&2; exit 2; }
            case "$1" in
                --hours) HOURS=$2 ;;
                --interval) INTERVAL=$2 ;;
                --mount) MNT=$2 ;;
            esac
            shift 2 ;;
        -h|--help)
            printf 'Usage: bash %s [--mount existing-JuiceFS-mount] [--hours 1..72] [--interval seconds>=30]\n' "${0##*/}"
            printf 'Initialize 4 GiB, overwrite four times, then record Ceph space. Files are preserved.\n'
            exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
[[ "$HOURS" =~ ^[1-9][0-9]*$ && "$INTERVAL" =~ ^[1-9][0-9]*$ ]] || exit 2
(( HOURS <= 72 && INTERVAL >= 30 )) || exit 2
[[ "$MNT" == /* ]] || { printf 'Mount path must be absolute\n' >&2; exit 2; }
for tool in fio findmnt pgrep realpath mktemp sudo tee; do command -v "$tool" >/dev/null; done
MNT=$(realpath -e -- "$MNT")
[[ $(findmnt -rn -M "$MNT" -o FSTYPE) == fuse.juicefs ]] || {
    printf 'Use an existing JuiceFS mount; ordinary directories are refused\n' >&2; exit 2;
}
if pgrep -x fio >/dev/null; then
    printf 'Another fio is running; wait for it to finish\n' >&2; exit 2
fi
CEPH=(sudo -n /usr/bin/ceph --conf /etc/ceph/ceph.conf
      --keyring /etc/ceph/ceph.client.admin.keyring -n client.admin)
"${CEPH[@]}" df detail >/dev/null  # Read-only permission check before writing.
OUT=$(mktemp -d /data/reliability-lt-results/manual-overwrite-result-XXXXXX)
DATA=$(mktemp -d "$MNT/manual-overwrite-data-XXXXXX")
printf 'DATA_DIR=%s\nRESULT_DIR=%s\n' "$DATA" "$OUT"
trap 'printf "Stopped; preserve data=%s results=%s\n" "$DATA" "$OUT" >&2' ERR

sample() {
    {
        printf '\n[%s] %s\n' "$(date '+%F %T %z')" "$1"
        df -h "$DATA"
        "${CEPH[@]}" df detail
    } | tee -a "$OUT/space.log"
}

sample before-write
for wave in 0 1 2 3 4; do
    BS=16M; ALLOW_CREATE=0
    if (( wave == 0 )); then BS=4M; ALLOW_CREATE=1; fi
    printf '[%s] write pass %s/4 (0=initialization)\n' "$(date '+%F %T %z')" "$wave"
    fio --directory="$DATA" --name=lt '--filename_format=lt.$jobnum.0' \
        --filesize=256M --size=256M --numjobs=16 --ioengine=psync --iodepth=1 \
        --direct=1 --fallocate=none --rw=write --allow_file_create="$ALLOW_CREATE" \
        --bs="$BS" --refill_buffers=1 --end_fsync=1 --output="$OUT/fio-$wave.log"
    if (( wave == 4 )); then OBS_END=$((SECONDS + HOURS * 3600)); fi
    sample "after-pass-$wave"
done
while (( SECONDS < OBS_END )); do
    WAIT_SECONDS=$((OBS_END - SECONDS))
    if (( WAIT_SECONDS > INTERVAL )); then WAIT_SECONDS=$INTERVAL; fi
    sleep "$WAIT_SECONDS"
    sample idle
done
printf '\nDone. Data remains 16 x 256 MiB; inspect %s/space.log. No automatic cleanup.\n' "$OUT"
