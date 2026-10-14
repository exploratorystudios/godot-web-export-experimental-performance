# Experimental web performance template

This repository contains the Godot 4.7.2 source snapshot from upstream commit
`ed1daf0bf001b61586d9930840f2f1394092c079`, with four experimental engine changes:

* Reuse decoded Web Audio buffers when channel counts match.
* Report audio sample positions at approximately 60 Hz while counting every input block.
* Cache unchanged GLES3 integer uniforms within a render list.
* Validate the scene backbuffer framebuffer when creating or changing attachments.

The source snapshot starts this repository's history; upstream Git history is not included.
Godot's existing license and copyright notices remain in place.

The tested release is `web-perf-4.7.2-1`. Its single-threaded release template uses
Emscripten 4.0.11, `optimize=size`, ThinLTO, SIMD and Closure Compiler. It retains
Godot/Emscripten's buffered canvas presentation. Speed optimization and direct
presentation were tested but are not part of the preferred pipeline.

Download the template ZIP and provenance JSON from this repository's release.
The ZIP is a custom **release** export template for a matching standard Godot
4.7.2 editor; it does not replace the editor or supply a debug template.
Windward's `tools/export_web.sh` downloads and verifies the pinned release.

## Rebuild

On Linux with Python 3, venv, Git, a C++ build environment, and Java available:

```sh
tools/web_performance/build.sh 2
```

This installs Emscripten and SCons inside `.web-perf-toolchain/`, and writes the
ZIP and build manifest to `bin/web-performance/`. A cold build recompiles the
engine and can take tens of minutes. A normal game export reuses the template.

The focused upstream diff is preserved in `engine-changes.patch`; compact
renderer and position-reporting results are in `validation/`.

## Validation and limits

Audio buffer tests passed eight checks. Position-reporting tests passed six
checks, including unchanged PCM and sample progression. Renderer fixtures matched
pixels with uniform caching and framebuffer caching; framebuffer validation still
runs for newly created or changed attachments and after resizing.

Windward user testing improved from roughly 10 FPS initially to roughly 20 FPS
after the audio changes, then roughly 30 FPS with the framebuffer-cache build.
These are observations from one game/system, not controlled cross-device results.
Reduced audio reporting can leave main-thread playback-position reads stale for
about one reporting interval (roughly 20 ms at common sample rates).

Windward separately disables the depth prepass on web and honors the player's
render scale. Those game settings are not engine changes in this repository.
