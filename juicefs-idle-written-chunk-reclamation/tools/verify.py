#!/usr/bin/env python3
import argparse,collections,hashlib,json,shutil,subprocess,tempfile
from pathlib import Path
D=Path(__file__).resolve().parents[1]
NON_SUBMISSION={'SHA256SUMS','verification.json','code-flow.md'}
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def need(x,msg):
    if not x:raise ValueError(msg)
def read(n):return json.loads((D/n).read_text())
def log(n):
    text=(D/'raw-test-data'/(n+'.log')).read_text()
    rows=[json.loads(l) for l in text.splitlines() if l.startswith('{')]
    done=[r for r in rows if 'Test'in r and r['Action']in ('pass','fail','skip')];names={r['Test'] for r in done}
    leaves=[r for r in done if not any(k.startswith(r['Test']+'/') for k in names)]
    return text,rows,collections.Counter(r['Action'] for r in leaves),[r['Action'] for r in rows if 'Test'not in r and r['Action']in ('pass','fail')]
def verify(upstream):
    entries={}
    for line in (D/'SHA256SUMS').read_text().splitlines():
        h,n=line.split('  ',1);p=Path(n)
        need(not p.is_absolute() and '..'not in p.parts and n not in entries and n not in NON_SUBMISSION,'manifest path')
        need(not (D/p).is_symlink() and sha(D/p)==h,'hash '+n);entries[n]=h
    need(set(entries)=={p.relative_to(D).as_posix() for p in D.rglob('*') if p.is_file() and p.name not in NON_SUBMISSION},'manifest completeness')
    m=read('patches/manifest.json');need(len(m['patches'])==2,'patch count')
    for p in m['patches']:
        need(sha(D/p['path'])==p['sha256'],'patch hash')
        text=(D/p['path']).read_text();need('Assisted-by: gpt 6\nSigned-off-by: Li Lingfeng <a1151488180@gmail.com>'in text,'trailers')
    text,rows,count,pkg=log('focused-race');need(count=={'pass':108} and pkg==['pass'] and 'DATA RACE'not in text,'focused race')
    text,rows,negative,pkg=log('stock-negative');need(negative=={'fail':1} and pkg==['fail'] and 'IDLE_WRITE_TRIGGER_MISSING'in text and 'DATA RACE'not in text,'stock negative')
    for name in ('clients-race','stock-clients-race'):
        text,_,_,pkg=log(name);need(pkg==['fail'] and 'DATA RACE'in text,'broad failure evidence')
    _,rows,_,pkg=log('clients');need(pkg==['pass'],'clients')
    for name in ('TestMemKVClient','TestSQLiteClient','TestBadgerClient'):need(any(r.get('Test')==name and r['Action']=='pass' for r in rows),'client '+name)
    need(read('raw-test-data/build.json')['exit_code']==0,'build')
    cause=read('raw-test-data/cause/independent-audit.json')
    for rn in ('R01','R02'):
        r=cause['rounds'][rn];need(r['trace_complete'] and r['all_write_mappings_exactly_replayed'] and r['six_trees_identical'],'cause '+rn)
        need(r['raw_source_bytes']==20*2**30 and r['shadowed_bytes']==16*2**30 and r['logical_bytes']==4*2**30,'cause accounting')
    # These check the supplied audit summaries, not a new full trace replay.
    first=read('raw-test-data/field-short/first-auto-review.json')
    need(first['fio_write_bytes']==20*2**30 and first['logical_and_referenced_bytes']==4*2**30 and first['shadowed_bytes']==0,'first field accounting')
    need(first['trace_no_gaps_or_drops'] and first['no_user_reads_before_freeze'] and first['no_manual_compact'],'first field scope')
    crc=read('raw-test-data/field-short/first-crc-review.json')
    need(crc['crc']=={'jobs':16,'bytes':4*2**30,'direction':'read','rc':0} and not crc['source_audit']['pending_obsolete_ids'],'first field CRC/deletion')
    need(read('raw-test-data/field-short/first-closure.json')['result']=='CLOSED_PASS','first field closure')
    repeat=read('raw-test-data/field-short/repeat-auto-review.json')
    need(repeat['user_write_bytes']==20*2**30 and repeat['live_bytes']==4*2**30 and repeat['trace_no_gaps_or_drops'],'repeat field summary')
    overlap=read('raw-test-data/field-short/overlap-auto-review.json')['overlap']
    need(overlap['generation_changed'] and overlap['latest_write_source_preserved'] and overlap['same_chunk_writes_before_idle_finish']==1,'actual overlap scope')
    final=read('raw-test-data/field-short/repeat-overlap-closure-review.json')
    need(final['result']=='FINAL_INDEPENDENT_REVIEW_PASS' and final['closure']['result']=='CLOSED_PASS' and all(r['bytes']==4*2**30 for r in final['crc'].values()),'repeat/overlap CRC/closure summaries')
    replay=None
    if upstream:
        root=Path(tempfile.mkdtemp(prefix='write-idle-replay-',dir='/tmp/opencode'))/'source'
        shutil.copytree(upstream,root,ignore=shutil.ignore_patterns('.git'));subprocess.run(['chmod','-R','u+w',str(root)],check=True)
        for p in m['patches']:
            for f in p['file_hashes']:
                n=root/f['path'];need(sha(n)==f['before_sha256'] if f['before_sha256'] else not n.exists(),'before '+f['path'])
            subprocess.run(['git','apply','--check',str(D/p['path'])],cwd=root,check=True)
            subprocess.run(['git','apply',str(D/p['path'])],cwd=root,check=True)
            for f in p['file_hashes']:need(sha(root/f['path'])==f['after_sha256'],'after '+f['path'])
        for name in ('go.mod','go.sum'):need(sha(root/name)==sha(Path(upstream)/name),'dependency change')
        replay=str(root)
    return {'files_verified':len(entries),'focused_race':dict(count),'upstream_expected_failure':dict(negative),'broad_client_race':'FAIL on both upstream and candidate','client_nonrace':'PASS','build':'PASS','replay_source':replay,'field_short_summary_checks':'PASS; supplied audits, not a new full trace replay','candidate_field_acceptance':False,'candidate_field_acceptance_scope':'Long-term/production acceptance is not established'}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--upstream',type=Path);a=p.parse_args();print(json.dumps(verify(a.upstream),indent=2))
