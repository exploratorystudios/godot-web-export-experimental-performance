#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SDK="$ROOT/.web-perf-toolchain"
JOBS="${1:-2}"
mkdir -p "$SDK"
if [ ! -x "$SDK/emsdk/emsdk" ]; then
    git clone --depth 1 https://github.com/emscripten-core/emsdk.git "$SDK/emsdk"
fi
"$SDK/emsdk/emsdk" install 4.0.11
"$SDK/emsdk/emsdk" activate 4.0.11
if [ ! -x "$SDK/python/bin/python" ]; then python3 -m venv "$SDK/python"; fi
"$SDK/python/bin/pip" install 'scons==4.10.0'
source "$SDK/emsdk/emsdk_env.sh"
cd "$ROOT"
FLAGS=(platform=web arch=wasm32 target=template_release threads=no proxy_to_pthread=no optimize=size lto=thin wasm_simd=yes debug_symbols=no dev_build=no dev_mode=no use_closure_compiler=yes)
"$SDK/python/bin/scons" "${FLAGS[@]}" -j"$JOBS"
python3 - "${FLAGS[@]}" <<'PY'
import hashlib,json,subprocess,sys
from pathlib import Path
import shutil
root=Path.cwd()
archives=list((root/'bin').glob('godot.web.template_release.wasm32*.zip'))
assert len(archives)==1, archives
out=root/'bin/web-performance'
out.mkdir(exist_ok=True)
archive=out/'web_nothreads_release_patched_framebuffer_cache.zip'
shutil.copy2(archives[0],archive)
files=['drivers/gles3/rasterizer_scene_gles3.cpp','drivers/gles3/storage/render_scene_buffers_gles3.cpp','platform/web/js/libs/library_godot_audio.js','platform/web/js/libs/audio.position.worklet.js']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
manifest={'engine_commit':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'compiler':subprocess.check_output(['emcc','--version'],text=True).splitlines()[0],'flags':sys.argv[1:],'variant':'patched_framebuffer_cache','source_sha256':{p:sha(root/p) for p in files},'template_sha256':sha(archive)}
(out/'patched_framebuffer_cache.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(archive)
PY
