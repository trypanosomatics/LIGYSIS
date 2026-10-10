# Installation

This fork (`trypanosomatics/LIGYSIS`) is the umbrella of the LIGYSIS stack. One recursive clone
gives everything, pinned to tested commits (`vendor/`):

| Submodule | Fork of | Change against upstream |
|---|---|---|
| `vendor/ProIntVar` | `bartongroup/ProIntVar` (`JSU_branch`) | `exclude_columns` fix for mmCIFs lacking optional columns |
| `vendor/SM_VarAlign` | `bartongroup/SM_VarAlign` (`JSU_branch`) | gnomAD `INFO/vep` as well as `INFO/CSQ` |
| `vendor/arpeggio` | `PDBeurope/arpeggio` v1.4.4 | `_chem_comp` lookups commented out (upstream issue #20); replaces the old manual patch |

## Steps

```sh
git clone --recurse-submodules https://github.com/trypanosomatics/LIGYSIS.git
cd LIGYSIS

cp site.env.sample site.env                       # set ENVS_DIR (and MIRROR_DIR, see below)
./install.sh                                      # builds DSSP, ARPEGGIO, LIGYSIS, DEEP_LEARNING envs

cp ligysis_config.txt.sample ligysis_config.txt   # paths to gnomAD, SwissProt, Ensembl cache, ARPEGGIO
./run_ligysis.sh check                            # sanity check
./run_ligysis.sh run <UNIPROT_ACC>
```

If you cloned without `--recurse-submodules`: `git submodule update --init`.
`./install.sh ARPEGGIO` (or any env name) rebuilds only that env.

## What `install.sh` does

- Creates each env from `ENVS/pinned/<ENV>.explicit.txt` (exact packages and md5).
- `LIGYSIS` env: pip-installs the pinned pip packages, then `vendor/ProIntVar` and `vendor/SM_VarAlign`
  (in that order, non-editable), then runs `ProIntVar-config-load` with `dssp_bin` pointing at
  `$ENVS_DIR/DSSP/bin/mkdssp` (template: `config/prointvar_config.ini.sample`).
- `ARPEGGIO` env: pip-installs `vendor/arpeggio`.

## Packages not on conda-forge

A few pinned packages come from personal or old channels (`salilab`, `rdonnelly`, Anaconda `defaults`),
see `ENVS/pinned/README.md`. Keep a local copy and set `MIRROR_DIR` in `site.env` to a local conda
channel directory (containing `linux-64/`); `install.sh` then rewrites those URLs to the mirror.
Without `MIRROR_DIR` the original URLs are used, which works only while they are still served.

## Databases and configuration

`ligysis_config.txt` (git-ignored) holds the paths to the databases that are not part of the repo:
gnomAD exomes VCF (+ `.tbi`; r2.0.x and r2.1.x both work), SwissProt fasta, and the Ensembl cache
(an empty sqlite is created on first use). Human variants are optional: proteins without human
homologs are supported.

## Reproducibility

Deliberate upgrades of python or pandas must go on a branch: behaviour of parsing and numerics
changes. `FORKPLAN.md` describes the regression test.
