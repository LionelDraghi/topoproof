<!-- omit from toc -->
# Changelog

All notable changes **from a user perspective** to this project will be documented in this file.  
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.1.0/), (guidelines at the bottom of the page).  
Version numbering adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

- **[0.1.0] - 2026-10-17**
  - [Added]   the TopoProof application and its first three operations: `translate`,
              `displacement` and `equal`, computing exactly on integer grid points,
              documented with executable scenarios under `docs/features/`
  - [Added]   the fundamental identity `Translate (A, Displacement (A, B)) = B` is
              proved by SPARK over the whole grid domain
  - [Added]   the complete verification chain `make check`: build, execution of the
              documentation, and GNATprove proofs, operational from a clean clone

---

[Keep a Changelog](http://keepachangelog.com/en/1.1.0/) Guiding Principles
  - Changelogs are for humans, not machines.
  - There should be an entry for every single version.
  - The same types of changes should be grouped.
  - Versions and sections should be linkable.
  - The latest version comes first.
  - The release date of each version is displayed.
  - Mention whether you follow Semantic Versioning.

Types of changes
  - Added for new features.
  - Changed for changes in existing functionality.
  - Deprecated for soon-to-be removed features.
  - Removed for now removed features.
  - Fixed for any bug fixes.
  - Security in case of vulnerabilities.
