#!/usr/bin/env python3
"""Read-only, standard-library recomputation of the adjacent raw-data subset."""
import argparse
from collections import defaultdict
from decimal import Decimal
import hashlib
import json
from pathlib import Path

FIXED = {'read':'juicefs_fuse_read_size_bytes_sum',
         'write':'juicefs_fuse_written_size_bytes_sum',
         'compact_bytes':'juicefs_compact_size_histogram_bytes_sum',
         'compact_count':'juicefs_compact_size_histogram_bytes_count',
         'object_errors':'juicefs_object_request_errors'}


def counters(row, mini_fresh_workers=()):
    found = defaultdict(list)
    for line in row['text'].splitlines():
        if not line or line.startswith('#'): continue
        field,value,*_ = line.split()
        name=field.split('{')[0]
        keys=[k for k,v in FIXED.items() if name==v]
        if name=='juicefs_object_request_data_bytes':
            keys += [m for m in ('GET','PUT') if f'method="{m}"' in field]
        if name=='juicefs_object_request_durations_histogram_seconds_count' and 'method="DELETE"' in field:
            keys += ['DELETE_count']
        if not keys: continue
        d=Decimal(value)
        if not d.is_finite() or d<0 or d!=d.to_integral_value(): raise ValueError('invalid counter')
        for k in keys: found[k].append(int(d))
    if any(not found[k] for k in FIXED): raise ValueError('missing fixed metric')
    out={k:sum(found[k]) for k in FIXED}
    fresh=bool(row.get('fresh_process_zero'))
    if fresh and any(out.values()): raise ValueError('fresh process has nonzero counters')
    known_mini=row.get('worker',{}).get('pid') in mini_fresh_workers
    for method,side in [('GET','read'),('PUT','write')]:
        if not found[method] and not (fresh or (known_mini and not out[side] and not out['compact_bytes'])):
            raise ValueError('missing used method: '+method)
        out[method]=sum(found[method])
    out['DELETE_count']=sum(found['DELETE_count']) # lazy label; absence is recorded in raw text
    return out


def load_rows(directory):
    rows=[json.loads(s) for s in (directory/'metrics-boundaries.jsonl').read_text().splitlines()]
    if any(b['epoch']<=a['epoch'] for a,b in zip(rows,rows[1:])): raise ValueError('unordered boundaries')
    return rows


def pick(rows,label):
    selected=[r for r in rows if r['label']==label]
    if len(selected)!=1: raise ValueError('need one boundary '+label)
    return selected[0]


def window(rows,start,end,mini=False):
    a,b=pick(rows,start),pick(rows,end)
    fresh_workers={r['worker']['pid'] for r in rows if r.get('fresh_process_zero')} if mini else set()
    # Verify the purported fresh-process evidence before allowing an unused lazy method.
    for r in rows:
        if r.get('fresh_process_zero'): counters(r)
    selected=[r for r in rows if a['epoch']<=r['epoch']<=b['epoch']]
    if 'worker' in a and any(r.get('worker')!=a['worker'] for r in selected): raise ValueError('worker changed')
    values=[counters(r,fresh_workers) for r in selected]
    if any(any(y[k]<x[k] for k in x) for x,y in zip(values,values[1:])): raise ValueError('counter reset')
    d={k:values[-1][k]-values[0][k] for k in values[0]}
    return {'start_epoch':a['epoch'],'end_epoch':b['epoch'],'seconds':b['epoch']-a['epoch'],'delta':d}


def fio(directory,phase,expected_jobs):
    doc=json.loads((directory/phase/'fio.json').read_text()); jobs=doc['jobs']
    if len(jobs)!=expected_jobs or any(j.get('error',0) or j.get('total_err',0) or j.get('total_io_errors',0) for j in jobs):
        raise ValueError('fio failed or job count incorrect')
    return {'jobs':len(jobs),'bytes':{s:sum(j[s]['io_bytes'] for j in jobs) for s in ('read','write')},
            'minimum_job_runtime_ms':min(j.get('job_runtime',0) for j in jobs),
            'maximum_job_runtime_ms':max(j.get('job_runtime',0) for j in jobs),
            'explicit_seeds_in_job_options':[j.get('job options',{}).get('randseed') for j in jobs],
            'actual_iodepth_percentage_ranges':{k:[min(j['iodepth_level'][k] for j in jobs),max(j['iodepth_level'][k] for j in jobs)] for k in jobs[0].get('iodepth_level',{})}}


def reconcile(w,f):
    if {s:w['delta'][s] for s in ('read','write')}!=f['bytes']: raise ValueError('fio/FUSE mismatch')
    return dict(w,fio=f)


def compute(root,verify=True):
    if verify:
        manifest=json.loads((root/'source-manifest.json').read_text())
        for item in manifest['outputs']:
            if hashlib.sha256((root/item['output']).read_bytes()).hexdigest()!=item['output_sha256']:
                raise ValueError('SHA mismatch: '+item['output'])
    result={'schema':1,'groups':{},'warnings':[
        'Raw records retain original values and internal path/host labels; no credentials/config/preflight/environment files included.',
        'Boundaries alone do not audit every intermediate counter or object; complete source archives remain separately preserved.',
        'The minimal129x write example and aggregate23x workload answer different questions.']}
    for name in ('upstream-independent',):
        directory=root/'raw-test-data'/name; rows=load_rows(directory)
        w=window(rows,'formal-start','formal-end'); f=fio(directory,'formal',128)
        formal=reconcile(w,f); d=w['delta']
        formal.update(read_amplification=d['GET']/d['read'],write_amplification=d['PUT']/d['write'],
            PUT_minus_foreground_minus_compact=d['PUT']-d['write']-d['compact_bytes'],
            GET_minus_foreground_minus_compact=d['GET']-d['read']-d['compact_bytes'])
        crc=reconcile(window(rows,'final-crc-start','final-crc-end'),fio(directory,'final-crc',128))
        item={'formal':formal,'final_crc_separate':crc}
        item['postformal_before_crc']=window(rows,'formal-end','final-crc-start')
        item['manual_compact_boundary_window']=window(rows,'manual-compact-start','manual-compact-end')
        result['groups'][name]=item
    for name,n in [('mini-negative',1),('mini-positive',2)]:
        directory=root/'raw-test-data'/name; rows=load_rows(directory)
        layout=fio(directory,'layout',1)
        baseline=fio(directory,'baseline-crc',1)
        if layout['bytes']!={'read':0,'write':64*2**20} or baseline['bytes']!={'read':64*2**20,'write':0}:
            raise ValueError('mini preparation coverage is not64MiB')
        for phase in ('layout','baseline-crc'):
            if json.loads((directory/phase/'exit.json').read_text())['rc']!=0:
                raise ValueError('mini preparation command failed')
        writes=window(rows,'measurement-write-start','measurement-write-settle',True)
        fs=[fio(directory,'write-'+str(i+1),1) for i in range(n)]
        totals={s:sum(f['bytes'][s] for f in fs) for s in ('read','write')}
        if totals!={s:writes['delta'][s] for s in totals}: raise ValueError('mini writes/fio mismatch')
        cold=reconcile(window(rows,'trigger-start','measurement-read-settle',True),fio(directory,'trigger',1))
        crc=reconcile(window(rows,'final-crc-start','final-crc-end',True),fio(directory,'final-crc',1))
        prepared=json.loads((directory/'prepared-mapping.json').read_text())
        written=json.loads((directory/'written-mapping.json').read_text())
        end=json.loads((directory/'measurement-end-mapping.json').read_text())
        size=64*2**20; bs=256*2**10
        if len(prepared)!=1 or len(written)!=n+1: raise ValueError('mapping record count')
        expected=[(0,size)]+[(p,bs) for p in (16*2**20,48*2**20)[:n]]
        for record,(pos,length) in zip(written,expected):
            if record.get('pos',0)!=pos or record.get('off',0) or record['size']!=length or record['len']!=length:
                raise ValueError('mapping geometry mismatch')
        if n==1 and end!=written: raise ValueError('negative changed mapping')
        if n==2 and (len(end)!=1 or end[0]['size']!=size or end[0]['len']!=size or end[0]['id']==written[0]['id']):
            raise ValueError('positive did not commit new full slice')
        result['groups'][name]={'preparation_separate':{'layout':layout,'baseline_crc':baseline},
            'writes':writes,'write_fio':fs,'cold_read':cold,'final_crc_separate':crc,
            'mapping':{'prepared_records':len(prepared),'written_records':len(written),
                       'visible_segments_from_exact_geometry':1+2*n,'end_records':len(end)},
            'total_measured_write_amplification':(writes['delta']['PUT']+cold['delta']['PUT'])/writes['delta']['write'],
            'cold_GET_minus_foreground_minus_compact':cold['delta']['GET']-cold['delta']['read']-cold['delta']['compact_bytes']}
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    args=parser.parse_args()
    print(json.dumps(compute(args.root),indent=2,sort_keys=True))
