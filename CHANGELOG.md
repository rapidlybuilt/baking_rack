# Changelog

All notable changes to this project will be documented in this file.

## [0.2.1] - 2026-02-20

### Added

- **`prune` command** — Compares the current build directory with the remote (e.g. S3) and removes files that exist on the remote but not locally. The CLI lists candidate files in red, prompts for confirmation, and with `--dry-run` shows what would be deleted without making changes. Requires a deployer that supports pruning (e.g. `BakingRack::AwsS3::Deployer`).
