from pathlib import Path
import hashlib,sys
source_bytes=Path('/home/nss-marker/yhr/Cry/partition-source-b0fd479/source/rehearse_partition.py').read_bytes()
if hashlib.sha256(source_bytes).hexdigest()!='9a2d926c2df40bc03f0d81195190f256bd208457725e9c7358e854109ed7be10': raise SystemExit('Frozen source mismatch')
SOURCE_TEXT=source_bytes.decode()
sys.argv=['frozen_partition.py','run']
exec(compile(SOURCE_TEXT,'frozen_partition.py','exec'))