import psutil, datetime as dt

LIMITS = {'CPU': 80, 'MEM': 80, 'DISK': 80, 'PROCS': 300}
LOG = "system_health_py.log"

print(f"--- Report {dt.datetime.now()} ---")
metrics = {
    'CPU': psutil.cpu_percent(interval=1),
    'MEM': psutil.virtual_memory().percent,
    'DISK': psutil.disk_usage('/').percent,
    'PROCS': len(psutil.pids())
}

for k, v in metrics.items():
    ts = dt.datetime.now().strftime("%F %T")
    
    if v >= LIMITS[k]:
        out = f"❌ ALERT [{ts}]: {k}: {v} (>{LIMITS[k]})"
    else:
        out = f"✅ OK [{ts}]: {k}: {v}"
        
    print(out)
    with open(LOG, "a") as f: f.write(out + "\n")
print("-----------------------")