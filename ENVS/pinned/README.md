# Pinned environments

Exact versions of the four environments that LIGYSIS uses (`LIGYSIS`, `ARPEGGIO`,
`DSSP`, `DEEP_LEARNING`), exported from a working installation (2026-10-08, linux-64).

- `<ENV>.pinned.yml`: exact versions without build strings; `conda env create -f`.
- `<ENV>.explicit.txt`: exact URLs and md5 (`conda create -n <ENV> --file <ENV>.explicit.txt`),
  the most reproducible form, as long as the URLs are still served.
- `prointvar` and `varalign` are not listed: they are installed from source (see the install notes).
- The ARPEGGIO patch (`OTHER/JSU_patch.diff`) is applied after creating the env.

## Packages that are not on conda-forge

| Package | Env | Source channel |
|---|---|---|
| `dssp` 3.0.0 | DSSP | `salilab` |
| `libboost` 1.73.0 | DSSP | `rdonnelly` (personal channel) |
| `matplotlib` 2.1.1, `qt` 5.6.2 (build 14), `gstreamer` 1.12.4 | LIGYSIS | Anaconda `defaults` (not on conda-forge) |
| `hmmer`, `pysam` | LIGYSIS | `bioconda` |

Personal and old channels can disappear. Keep a local copy of these packages (the `.tar.bz2` / `.conda`
files), index it with `python -m conda_index <dir>` and add it as a channel at install time
(`-c file://<dir>`), with `--override-channels` and `channel_priority: strict`.
The location of that copy is site-specific and must not be committed.
