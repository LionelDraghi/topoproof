<!-- omit from toc -->
# Release procedure

The release procedure is common to all Lionel's Ada projects and lives
in [the reference repository on GitHub](https://github.com/LionelDraghi/ada-project-template/blob/main/release_procedure.md).
Read both documents together; on any conflict, this file wins.

This file gives the parameter values and the TopoProof-specific
additions; all other steps are described in the common procedure.

## Parameters

- Changelog: `docs/changelog.md`; the development section is `[x.y.z-dev]`;
  its categories are `### Added`, `### Changed`, `### Fixed`, ...
- Complete local validation: `make check` (build, bbt documentation
  execution, and GNATprove).
- Version check: `grep Crate_Version src/Alire_config/topoproof_config.ads`.
- Regenerated configuration: `src/Alire_config/topoproof_config.ads`.
- Clean command: `make clean`.
- Remote: `origin`.
- GitHub releases page:
  [LionelDraghi/topoproof releases](https://github.com/LionelDraghi/topoproof/releases);
  no release asset is attached.
- Required GitHub Actions checks (Linux): `build-and-bbt`, `prove`.
- Alire platform availability: per the `[available]` section of
  `alire.toml`.

## TopoProof-specific additions

- Step 3: search for other version strings that must be updated,
  including version strings in the sources, examples and generated
  documentation.
- Step 5: the local validation includes GNATprove; a proof failure
  blocks the release like any other failure.
