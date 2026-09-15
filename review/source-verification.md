# Source verification

Candidate: `094cfeff7fda9d59d354d37e21cea8b943b9b83c`.

The coordinator computed SHA-256, file modes, and symlink targets for every tracked file. The same manifest computation on each disposable worker's build source produced byte-identical JSON. `source-manifest.json` is the shared result. No file content, mode, or symlink difference was observed. This verifies the source used by the current-builder runs independently of the worker's copied Git administrative file.

The discovery regression invokes the real current builder for each named package and verifies scheduled discovery, architecture, and channel membership. It passes on the candidate, and fails on current master with the original PR additions under the retired tiered layout. The original-layout exit code is 1.

The full self-test workflow ran in an Arch container inside a disposable Proxmox worker and exited 0. Its complete log is `ci-self-tests.log`. A second worker ran the build-isolation workflow; its evidence is in the Omaspeak directory.
