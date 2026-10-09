from pathlib import Path
import json,os,datetime
root=Path('/sys/devices/system/cpu')
def read(p):
 try: return {'value':p.read_text().strip()}
 except OSError as e: return {'errno':e.errno,'error_type':type(e).__name__}
print(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'effective_uid':os.geteuid(),'cppc':{str(c):{n:read(root/f'cpu{c}'/'acpi_cppc'/n) for n in ('highest_perf','nominal_perf','lowest_nonlinear_perf','lowest_perf','nominal_freq','lowest_freq','reference_perf','wraparound_time','feedback_ctrs')} for c in (2,18)},'configuration_writes':0},indent=2))