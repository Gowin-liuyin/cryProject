from pathlib import Path
import importlib.util
import os
import sys
import tempfile

root = Path(__file__).resolve().parents[3]
work = root / 'build/litqa'
for name in ['tmp', 'cache', 'config']:
    (work / name).mkdir(parents=True, exist_ok=True)
for name in ['TMPDIR', 'TMP', 'TEMP']:
    os.environ[name] = str(work / 'tmp')
os.environ['XDG_CACHE_HOME'] = str(work / 'cache')
os.environ['XDG_CONFIG_HOME'] = str(work / 'config')
os.environ['FONTCONFIG_FILE'] = str(work / 'fonts.conf')
tempfile.tempdir = str(work / 'tmp')
skill = Path('/Users/yin/.codex/plugins/cache/openai-primary-runtime/documents/26.1007.11041/skills/documents/render_docx.py')
spec = importlib.util.spec_from_file_location('document_renderer', skill)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
# 保留用户要求的仓库内临时目录，不使用渲染器的系统临时目录默认值。
module._default_macos_tmpdir_for_soffice = lambda: None
module.main()
