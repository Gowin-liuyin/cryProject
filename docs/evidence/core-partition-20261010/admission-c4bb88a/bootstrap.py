from pathlib import Path
import hashlib,sys
source_bytes=Path('/home/nss-marker/yhr/Cry/partition-source-c4bb88a/source/rehearse_partition.py').read_bytes()
if hashlib.sha256(source_bytes).hexdigest()!='dda496a5b1f1fd81688af30e4361ee9fee32f10d7a5145012266ccbe835b8f61': raise SystemExit('Frozen source mismatch')
SOURCE_TEXT=source_bytes.decode()
sys.argv=['frozen_partition.py','run']
exec(compile(SOURCE_TEXT,'frozen_partition.py','exec'))