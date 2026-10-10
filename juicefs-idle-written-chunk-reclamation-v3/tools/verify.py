#!/usr/bin/env python3
"""Read-only verification of bundled V3 artifacts and recorded evidence."""
import collections
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GIB = 2**30


def require(value, message):
    if not value:
        raise ValueError(message)


def read(path):
    return json.loads((ROOT / path).read_text())


def events(path):
    return [json.loads(x) for x in (ROOT / path).read_text().splitlines() if x.strip()]


def leaves(rows, prefix):
    selected = [r for r in rows if r.get('Test', '').startswith(prefix)
                and r['Action'] in ('pass', 'fail', 'skip')]
    names = {r['Test'] for r in selected}
    return [r for r in selected if not any(n.startswith(r['Test'] + '/') for n in names)]


def error_free(data):
    require(data.get('jobs'), 'fio jobs missing')
    for job in data['jobs']:
        require(not any(job.get(k, 0) for k in ('error', 'total_err', 'total_io_errors')),
                'fio error in recorded evidence')


def verify():
    checksums = {}
    for line in (ROOT / 'SHA256SUMS').read_text().splitlines():
        digest, relative = line.split('  ', 1)
        path = Path(relative)
        require(not path.is_absolute() and '..' not in path.parts, 'unsafe checksum path')
        require(path.as_posix() not in checksums, 'duplicate checksum entry')
        require(not (ROOT / path).is_symlink(), 'symlink in material')
        require(hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest,
                'checksum differs: ' + relative)
        checksums[relative] = digest
    present = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if p.is_file()
               and p.name not in ('SHA256SUMS', 'verification.json')}
    require(set(checksums) == present, 'checksum manifest missing/unexpected files')

    manifest = read('patches/manifest.json')
    require(manifest['base_commit'] == '0b90c7db5a929ae6adc5faad948d108efd2c99f9', 'wrong base')
    for patch in manifest['patches']:
        require(checksums[patch['path']] == patch['sha256'], 'patch fingerprint differs')
    replay = read('raw-test-data/patch-replay.json')
    require(replay['all_application_checks_passed'] and replay['all_result_sources_match_recorded_v3']
            and replay['all_modified_existing_files_match_fixed_upstream_before_series'],
            'patch replay not accepted')
    require(replay['go_mod_go_sum_unchanged'], 'dependency identity changed')

    race_path = 'raw-test-data/logs/v3-final-bcatchup-race.log'
    race = events(race_path)
    require(race[-1]['Action'] == 'pass' and 'DATA RACE' not in (ROOT / race_path).read_text(),
            'final race suite failed')
    counts = {}
    for prefix, expected in {'TestIdleCompactV3': 108, 'TestIdleTriggerRegression': 27,
                             'TestCompactRetry': 66, 'TestC13': 24}.items():
        count = collections.Counter(r['Action'] for r in leaves(race, prefix))
        require(count == {'pass': expected}, 'unexpected leaf counts: ' + prefix)
        counts[prefix] = dict(count)
    control = events('raw-test-data/logs/v2-bcatchup-control-final.log')
    require(collections.Counter(r['Action'] for r in leaves(control, 'TestIdleTriggerRegression')) == {'fail': 9},
            'wrong V2 failure count')
    require(control[-1]['Action'] == 'fail', 'V2 control unexpectedly passed')
    require(sum('IDLE_TRIGGER_MISSING' in r.get('Output', '') for r in control) == 9,
            'V2 failures do not match expected mechanism')
    for name in ('v3-bcatchup-core-final.log', 'v3-cli-bcatchup-final.log', 'v3-vfs-compact-final.log'):
        require(events('raw-test-data/logs/' + name)[-1]['Action'] == 'pass', 'selected regression failed')

    field = {}
    for name, logical in (('c15', 64*GIB), ('c16', 128*GIB), ('c17', 128*GIB)):
        path = 'raw-test-data/field/' + name + '/'
        result, frozen = read(path + 'result.json'), read(path + 'cold-frozen.json')
        require(result['binary_sha256'] == manifest['field_binary']['sha256'], 'field version differs')
        require(result['automatic_clean_before_crc'] and result['full_crc'] == 'PASS'
                and result['private_unmounted'] and result['original_mount_preserved'], 'field incomplete')
        require(not result['layout_repeated'] and not result['manual_compact_gc_during_formal'],
                'formal maintenance/layout interference')
        require(frozen['minimal'] and frozen['automatic_clean'] and frozen['no_user_file_reads']
                and not frozen['manual_compact_gc'], 'idle observation method differs')
        last = frozen['rows'][-1]
        require(last['minimal'] and last['metadata']['raw_full_slice_bytes'] == logical
                and last['metadata']['fully_shadowed_full_slice_bytes'] == 0
                and last['pending'] == 0 and last['uploading'] == 0, 'idle recovery not minimal/drained')

        if name == 'c15':
            crc = read(path + 'final-crc-fio.json')
            timeline = events(path + 'events.jsonl')
            crc_start = next(r['epoch'] for r in timeline if r['event'] == 'CRC_BEGIN_AFTER_COLD_FREEZE')
            counted = None  # Formal fio is not bundled; do not fabricate an independent recomputation.
        else:
            crc = read(path + 'final-crc/fio.json')
            crc_runtime = read(path + 'final-crc/runtime.json')
            require(crc_runtime['rc'] == 0, 'CRC runtime failed')
            crc_start = crc_runtime['start_epoch']
            counted = {'read': 0, 'write': 0}
            for window in ('formal-01', 'formal-02'):
                fio = read(path + window + '/fio.json')
                runtime = read(path + window + '/runtime.json')
                error_free(fio)
                require(runtime['rc'] == 0 and runtime['elapsed_s'] >= 3600, 'incomplete formal window')
                job = fio['jobs'][0]
                require(len(fio['jobs']) == 1 and int(job['job options']['numjobs']) == 128
                        and job['job_runtime'] >= 128*3600000, 'formal job/runtime contract differs')
                require(job['job options']['rw'] == ('randrw' if name == 'c16' else 'randwrite')
                        and job['job options']['bs'].lower() == '256k', 'wrong formal workload')
                for direction in counted:
                    counted[direction] += job[direction]['io_bytes']
            require(counted['write'] == result['total_written_bytes']
                    and counted['read'] == result['total_read_bytes'], 'formal/result byte mismatch')
            stopped = read(path + 'stopped-io-counts.json')
            before_crc = read(path + 'before-final-crc-metrics.json')
            require(stopped['fio_bytes'] == counted and stopped['fuse_bytes'] == counted
                    and before_crc['fuse_bytes'] == counted and before_crc['cold_user_file_io_unchanged'],
                    'user IO changed during idle interval')
        error_free(crc)
        require(sum(j['read']['io_bytes'] for j in crc['jobs']) == logical
                and sum(j['write']['io_bytes'] for j in crc['jobs']) == 0, 'CRC coverage differs')
        require(last['epoch'] < crc_start < result['epoch'], 'recovery not frozen before CRC')
        field[name] = {'logical_bytes': logical, 'crc': 'PASS', 'automatic_recovery_before_crc': True,
                       'formal_bytes_independently_recomputed': counted,
                       'idle_attempts': last['attempts']}
    return {'checksum_files': len(checksums), 'patch_replay': 'PASS', 'race_leaf_counts': counts,
            'v2_expected_missing_trigger_failures': 9, 'field_checks': field,
            'scope': 'Bundled recorded evidence only; no new test execution, no 24/72h write acceptance.'}


if __name__ == '__main__':
    print(json.dumps(verify(), ensure_ascii=False, indent=2))
