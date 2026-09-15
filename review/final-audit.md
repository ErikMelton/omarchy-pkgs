# PR 447 final evidence and security audit

Reviewer: Codex (`gpt-6-astra`, xhigh), named T3 Code child agent `pr447_second_opinion`. Candidate: `094cfeff7fda9d59d354d37e21cea8b943b9b83c`.

## Verdict

**Ready for maintainer review within the demonstrated scope: edge packages, Linux x86_64, bundled default CPU runtimes, and virtual audio. No unresolved package defect or material evidence gap blocks that verdict.** Source review remains clean at the unchanged candidate. This audit does not authorize or establish a merge, signed channel publication, accelerator compatibility, or physical microphone/speaker performance.

I inspected the supplied worker outputs as evidence, independently compared source manifests against Git objects, recalculated hashes and WAV statistics, opened five actual screenshots, and read final-head GitHub CI state. I did not execute contributor code, package hooks, inference binaries, or model binaries on the coordinator. The only new filesystem write for this audit is this report.

## Identity and verification

- All three source manifests are byte-identical, SHA-256 `3e44b38453f63a2f5b4c76d2147722194313e9c663a1aa14e1ade5dcc458b9e7`. I independently compared all 754 entries with the candidate's Git blobs, file modes, and symlink targets. No differences remain after representing Git symlinks with their filesystem mode `0777`.
- Both current-builder logs select edge/x86_64 and finish with one built package, zero failures, and zero blocked packages. Their source checksums pass. The frozen source review independently verified the exact upstream release archives and payload layout.
- Independently downloading the frozen release archives again and hashing their executable/library members produces the exact hashes recorded for installed `/usr/bin/omawake`, `/usr/bin/omaspeak`, both packaged ORT libraries, and Omawake's sherpa library. Installed integrity checks report 256 Omawake files and 176 Omaspeak files, with zero altered files. Worker package-identity records name the repaired package archives, rather than relying on the earlier package builds.
- The discovery regression uses the real builder and asserts explicit discovery, scheduled discovery, edge-only membership, x86_64 support, and aarch64 exclusion. Its original-layout mutation fails with exit 1; the repaired candidate passes.
- The supplied self-test log covers the current workflow, including 22 upstream-watch tests and the remaining shell self-tests. All six reported build-isolation checks pass. I separately queried GitHub Actions run `34931729292`: its head is the exact candidate, both `build-isolation` and `self-tests` completed successfully, and neither job reports a failed step.

## Runtime evidence that supports readiness

| Area | Evidence and conclusion |
| --- | --- |
| Vendor user units | `omawake/daemon-start.log` and `omaspeak/runtime-lifecycle.log` show active services with `FragmentPath=/usr/lib/systemd/user/<app>.service` and real PIDs. This exercises the packaged units rather than only app-generated replacements. |
| Installed runtime loading | Omaspeak's live process maps point at `/usr/lib/omaspeak/libonnxruntime.so.1.29.0`; its status reports CPU execution with no fallback. Omawake's runtime inventory and final configuration resolve the private packaged runtime and report default CPU execution without fallback. |
| Wake detection and controls | Final positive input detects Lovely Child and Forever and records successful direct actions; unrelated speech and silence produce no detections. Live journal entries record detection, zero action exit status, and rearming. Pause/resume logs show the capture state clearing and returning. These are bounded fixtures, not a noisy-room accuracy study. |
| Speech generation | Standalone, daemon, alternate-voice, and stdin requests produce valid nonempty 44.1 kHz PCM WAVs. I independently inspected all WAV members of the supplied audio archive; their hashes, sample counts, peak values, and RMS values match the metrics. Invalid text, voice, and speed tests fail with the intended errors. |
| Speech content | Whisper.cpp's result transcribes the generated sentence with the exact expected words, allowing capitalization/punctuation differences. The published `desktop.wav` hash is `66e49d80e508cba216fc59e1bf531076a4c6092cd8c836e5f010cf0ab9654b77`; the actual resampled ASR input `desktop16.wav` hashes to `72c995627dbe9a9e709a522b680411191ad8c9dae5b5e526ea384400f93bfe5b`. I recalculated both hashes and their WAV metrics. The latter file matches the path named by the ASR log and the worker's input-hash record. |
| Playback and cross-package flow | The virtual playback-monitor capture contains nonzero PCM audio. Omawake's configuration maps Computer directly to `/usr/bin/omaspeak say "Wake word received" --no-play`; the live journal records detection, a successful synthesis response, action exit 0, and rearming. I verified the response WAV hash `9c9e06b27f8da28d9677ac19b702262a8b83f909f07f38690146a47ce7b205ea` and its 76,667 mono frames at 44.1 kHz, lasting 1.738 seconds. |
| Package lifecycle | Removal/reinstall logs show owned binaries removed, user configuration/model provenance preserved, installed integrity restored, and vendor units disabled/inactive afterwards. Active setup restart is separately exercised; inactive setup does not start a daemon. |
| Omaspeak cold autostart | The later public reboot log shows different boot IDs, explicit enablement of the vendor unit through `graphical-session.target.wants`, and the same vendor unit active after reboot with `/usr/bin/omaspeak` and the packaged CPU ORT in its live process maps. Synthesis produces 126,882 mono frames at 44.1 kHz (2.877 seconds). I independently verified WAV hash `cce01cbc92b73ca7bf9bed8a5d25a4021a7ed783434930e45d701bd46660ff58`. The test then restores disabled/inactive state. |

## Intermediate failures and corrections

The complete build logs contain `/proc`, systemd catalog, and chroot-detection diagnostics from bootstrap/dependency hooks. The logs proceed to successful package creation, and the installed artifacts subsequently pass runtime checks. These diagnostics do not show a failed package build and should not be described as absent.

Initial ASR helper installation encountered repository retrieval errors. The later official-package installation succeeds with package integrity/keyring checks retained, and the ASR run identifies the installed helper and CPU backend. Those helper retrieval failures are not an Omaspeak package defect.

`omawake/cross-package.log` retains an Omaspeak setup-check failure caused by copying its model/configuration without its desktop launcher. The later `cross-package-setup-complete.log` shows the app's own launcher installation, all setup checks passing, and an inactive service. The earlier failure is resolved; the logs should retain both facts.

The new clean synthesis screenshot writes `desktop-final.wav`; ASR evidence belongs to the earlier `desktop.wav`/`desktop16.wav` sample. They are distinct successful runs. The curated README now states that distinction. Matching duration or sample count alone was not treated as proof that their PCM bytes are the same.

## Screenshots and publication boundary

I opened Omaspeak's `10-runtime-clean.png`, `11-summary-clean.png`, and `13-final-desktop-synthesis.png`, plus Omawake's `05-final-cross-package.png` and `06-final-setup-check.png`. They show the real terminal surfaces, package runtime paths, command results, and journal lines described above. The selected CPU option and runtime paths are readable; some explanatory text is dim. The final images have sufficient readable content for the claims made, and no cosmetic issue blocks runtime readiness. Screenshots are corroboration; the process paths, hashes, WAV files, and journal results provide the stronger checks.

I inspected the curated publication tree as it stood before this report was added: 55 files, consisting of documentation, logs, JSON/TOML, the discovery check, PNGs, and generated WAVs. There were no model-weight files or symlink escapes. A text scan found no private-key markers, GitHub token patterns, AWS access-key patterns, credential-bearing URLs, or private infrastructure address matches. I additionally inspected the later public Omaspeak reboot log and generated WAV; the public log omits the transient connection error's private address. The raw reboot log was not included in this audit's publication approval. This is a bounded inspection of the curated tree and these named later artifacts, not an assurance about other future files added after it. Model paths and hashes in logs are metadata, not model weights.

At the final GitHub read, PR 447 was open, unmerged, and pointed at the exact candidate. This reviewer performed no GitHub write and no default-branch mutation. The parent remains responsible for the immutable evidence commit/readback, final publication checks, and worker destruction. The evidence demonstrates local unsigned candidate packages; it does not demonstrate signed edge publication.

## Remaining limits

Only Linux x86_64 CPU runtime behavior is established. Microphone input and playback used virtual audio; physical devices, noisy-room performance, OpenVINO/CUDA placement, and aarch64 execution remain untested here. Omawake cold graphical-login autostart remains untested; Omaspeak has the separate successful reboot/autostart evidence above. Archive hashes establish exact binary bytes and do not establish reproducible upstream builds. There is no unresolved source/runtime mismatch within these limits.
