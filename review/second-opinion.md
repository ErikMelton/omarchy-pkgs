# PR 447 second-opinion source review

Reviewer: Codex, model `gpt-6-astra`, reasoning effort `xhigh`, running as the named T3 Code child agent `pr447_second_opinion`.

## Verdict

**No remaining actionable source/package defects found at `094cfeff7fda9d59d354d37e21cea8b943b9b83c`.** The original head had one release integration blocker, corrected by the final head. This is a source and static archive review; it does not assert runtime, audio, hardware, service-lifecycle, or publication success.

## Reviewed identities

- Original PR head: `c265346cdd7245b1835a901e9468b6daaf55d97a`.
- Current base inspected: `267d84c9e2eade6be0772fa475d5b093b3be3cfe` (`origin/master`).
- Final head rereviewed: `094cfeff7fda9d59d354d37e21cea8b943b9b83c`.
- Final diff: `git diff origin/master...094cfeff7fda9d59d354d37e21cea8b943b9b83c`, comprising ten added files under `pkgbuilds/omawake-bin/` and `pkgbuilds/omaspeak-bin/`.
- Omawake upstream tag `v0.0.1-rc` resolved to `9eb3e939a6a08adfce427bd2f20a306175670104`.
- Omaspeak upstream tag `v0.0.1-rc` resolved to `d942947e1da1dc9ca09fde2feb6dcd3246610f04`.

Both final PKGBUILDs, `.SRCINFO` files, and install hooks are byte-identical to their counterparts under `pkgbuilds/edge/` at the original head. The repair changes directory placement, adds package metadata, and permits that metadata in the two `.gitignore` files.

## Original finding, now fixed

### P1: Packages were invisible to the current build/release machinery

Original locations: `pkgbuilds/edge/omawake-bin/PKGBUILD:3` and `pkgbuilds/edge/omaspeak-bin/PKGBUILD:3`, with missing `.omarchy/package.json` files.

On current master, `helpers/package-metadata.sh:40-45` resolves an explicit package only at `$PKGBUILDS_DIR/$package`, while `package_dirs` at lines 290-297 searches only immediate child directories and requires both a PKGBUILD and `.omarchy/package.json`. The original nested directories satisfy neither discovery route. An unscoped release never queues these packages; an explicit `--package omawake-bin` or `--package omaspeak-bin` reaches the not-found error in `build/build.sh:566-574`. Successful standalone makepkg builds cannot establish integration with this builder.

The final head moves both recipes directly below `pkgbuilds/` and adds `{"source":"local","channels":["edge"]}` at each `.omarchy/package.json:1-4`. Both metadata files are tracked and both `.gitignore:6-7` entries permit them. These directories now satisfy `package_dirs` and `package_dir_for_name`; `package_builds_for_mirror` requires metadata, admits edge, and excludes rc/stable through the explicit channel restriction. The original `arch=('x86_64')` remains appropriate because neither pinned release publishes an aarch64 artifact. The fix introduces no package payload or hook change.

The parent specifically asked me to examine current-base compatibility during the review. I verified the failure mechanism directly from the current base source and final diff; I did not consume the parent's reproduction report or other worker reports as proof.

## Archive and package evidence

I fetched each pinned release archive through its public GitHub release URL into Python process memory, computed SHA-256 over the received bytes, parsed tar members as data, and inspected ELF structures using Python `struct`. I did not extract executable files to the coordinator, run a release executable, invoke a dynamic loader, source a PKGBUILD, or build/test contributor code.

| Archive | Independently computed SHA-256 | Result |
| --- | --- | --- |
| `omawake-0.0.1-rc-linux-x86_64.tar.xz` | `52441cefcee285e6941fa25bc45770dc628391f0dd035260509e5cb47c0eeb15` | Matches PKGBUILD, `.SRCINFO`, and GitHub asset digest |
| `omaspeak-0.0.1-rc-linux-x86_64.tar.xz` | `49c1d0bc2954aad7865746d7edbbe81343ad3a1d33ff0dd6d21e0ecd3a26b115` | Matches PKGBUILD, `.SRCINFO`, and GitHub asset digest |

The archive roots match each `release_root` expression. Both contain the executable, all eight individually installed documentation/example files, assets, benchmarks, a regular vendor unit, and a flat licenses directory. Therefore the exact paths and the nonrecursive `licenses/*` install match these frozen archives. Omawake carries 21 license/notice files; Omaspeak carries six. The PKGBUILDs copy all of them, including the project licenses, ONNX Runtime license and third-party notices, generated Rust notices, and the applicable sherpa/native or Supertonic notices. Models are absent from the package payload.

Each runtime directory contains `libonnxruntime.so.1.29.0`, the relative link `libonnxruntime.so.1 -> libonnxruntime.so.1.29.0`, and the relative link `libonnxruntime.so -> libonnxruntime.so.1`. Omawake additionally contains `libsherpa-onnx-c-api.so`. `cp -a lib/.` preserves those relative links after relocation to `/usr/lib/<app>`. Neither archive bundles accelerator provider DSOs.

### Static ELF dependencies and ABI

I parsed the ELF64 section table and dynamic entries for `DT_NEEDED`, `DT_SONAME`, and `DT_RUNPATH`, plus symbol-version strings in `.dynstr`. All inspected executable/library ELF headers identify x86-64.

- Omawake executable needs `libasound.so.2`, `libgcc_s.so.1`, `libc.so.6`, and the x86-64 glibc loader. Its declared `alsa-lib`, `gcc-libs`, and `glibc` dependencies cover those libraries.
- Omaspeak executable needs `libgcc_s.so.1`, `libm.so.6`, `libc.so.6`, and the glibc loader. Its `gcc-libs` and `glibc` dependencies cover those libraries; `alsa-utils` supplies the fallback `aplay` command used by upstream `src/main.rs:2918-2923`, with `pw-play` optional.
- Bundled ONNX Runtime needs glibc libraries, `libstdc++.so.6`, and `libgcc_s.so.1`; its SONAME is `libonnxruntime.so.1` and its RUNPATH is `$ORIGIN`.
- Bundled sherpa needs `libonnxruntime.so.1`, glibc libraries, `libstdc++.so.6`, and `libgcc_s.so.1`; its RUNPATH is `$ORIGIN`, so the adjacent bundled ORT satisfies its dependency after packaging.
- The executables contain no inference-runtime `DT_NEEDED` entry. Neither executable nor its bundled default runtime requires OpenVINO, CUDA, cuDNN, or another accelerator library at ELF load time.
- Maximum version strings observed are `GLIBC_2.34` for the executables/sherpa, `GLIBC_2.28` for ORT, `GLIBCXX_3.4.30` for sherpa, and `GLIBCXX_3.4.22` for ORT. These do not indicate a requirement beyond the current Arch/Omarchy dependency generation; actual installation/loader behavior remains a runtime check.

### Runtime lookup and user units

Omawake's tagged `src/runtime_paths.rs:475-488` searches the executable's sibling `lib`, its own directory, and `../lib/omawake`; `/usr/bin/omawake` therefore discovers `/usr/lib/omawake`. Omaspeak's tagged `src/runtime.rs:582-595` similarly searches the executable directory's parent plus `lib/omaspeak`. The packaging relocation matches those mechanisms without a global loader configuration change.

The tagged units and the copies read directly from the frozen archives specify `ExecStart=/usr/bin/omawake daemon` and `ExecStart=/usr/bin/omaspeak daemon` respectively. The PKGBUILDs install only the regular vendor unit under `/usr/lib/systemd/user`; they create no enabled-unit link. Both install hooks contain only echo statements. They do not run model setup, change configuration, install a launcher, enable a unit, start a service, or restart an existing daemon.

The optional accelerators are consistently external in both documentation and packaging. Omawake's documentation explicitly requires an additional ABI-matched ORT provider and patched sherpa stack; installing OpenVINO alone is not presented by its optdependency text as sufficient. Omaspeak documents direct OpenVINO loading. No accelerator execution or device-placement claim follows from this source review.

## Upstream behavior and remaining evidence gaps

No additional upstream application issue was established that warrants blocking these package recipes. Omawake deliberately requires a user-supplied wake-model archive; Omaspeak requires explicit model-license acceptance. Those setup contracts are upstream behavior, not a packaging download failure.

I did not run the current builder, makepkg, package install/upgrade/remove, systemd, inference, microphone capture, playback, GUI flows, or accelerator probes. The parent owns separate credential-free worker validation. I also did not prove that the release binaries are reproducible from the resolved tag commits; the immutable claim established here is the exact downloaded archive SHA-256 and static payload properties. This report does not prove signed publication to the edge channel.

No parent transcript, memory, TODO, or other agent report was read. The only filesystem write made by this review is this report.
