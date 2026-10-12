# CLAUDE.md

Fork `trypanosomatics/LIGYSIS` of the LIGYSIS ligand-site pipeline (upstream
`bartongroup/LIGYSIS`, formerly `JavierSanchez-Utges/LIGYSIS`). This repo is
the **umbrella** of the stack: it vendors our forks of ProIntVar, SM_VarAlign
and pdbe-arpeggio as git submodules and builds the pinned conda envs.

**The repo is public.** Never commit server paths, hostnames, credentials,
internal planning, or specific proteins or accession numbers (in files *or*
commit messages) other than those that already appear in upstream LIGYSIS docs
or papers. Machine-specific values go in git-ignored files (`site.env`,
`ligysis_config.txt`); only the `*.sample` versions with placeholders are
tracked.

## Start of session

If these git-excluded files exist, read them first and follow them. They take
precedence over this file for anything local:

- `RUNBOOK.local.md`
- `FORKPLAN.md`

`docs/` is for user documentation on installing and running this fork.

## Layout
- `ligysis.py`: the whole pipeline in a single script (`main()` near the end).
  Input is a UniProt accession. It reads `ligysis_config.txt` from the repo
  dir, and `config.py` defines the data/output folder names.
- `predict_rsa_labels.py`: last step (RSA cluster label + functional score), in
  the `DEEP_LEARNING` env.
- `run_ligysis.sh`: wrapper that puts the env `bin/` dirs on PATH; commands are
  `check`, `run <ACC> [opts]` and `rsa <output_dir> <ACC>_<seg>`.
- `install.sh`: builds the envs from `ENVS/pinned/*.explicit.txt`, pip-installs
  `vendor/*`, and runs `ProIntVar-config-load` from
  `config/prointvar_config.ini.sample`.
- `ENVS/pinned/`: exact locks (source of truth). `ENVS/*.yml` are upstream's
  unpinned originals.
- `vendor/{ProIntVar,SM_VarAlign,arpeggio}`: submodules (our forks, branch
  `main`). Change them inside the submodule repo, push there, then commit the
  new pointer here.
- Working dirs created at run time and git-ignored: `data/`, `output_V2/`,
  `logs/`, plus ProIntVar's stray `cath/ contacts/ dssp/ pdbx/ pfam/ pickled/
  sifts/ stamp/ tmp/ uniprot/`, `prointvar.sqlite`.

## Environments

The conda envs live under `$ENVS_DIR` (from `site.env`): `LIGYSIS` (python 3.6,
prointvar, varalign, hmmer), `ARPEGGIO` (called by absolute path), `DSSP`
(called by ProIntVar via `dssp_bin`) and `DEEP_LEARNING`. Never activate the
envs, and never `mv` or `cp -r` them; rebuild with `./install.sh <ENV>`
instead.

## Running

```sh
./run_ligysis.sh check                    # no FAIL lines expected
./run_ligysis.sh run P00517               # long: run in tmux
./run_ligysis.sh rsa output_V2/ P00517_1
```

- Results go to `output_V2/<ACC>/<seg>/results/`. If `*_results_table.pkl`
  exists, the run prints "Results available" and stops; use `--override` to
  redo it.
- The RSA table is pickle protocol 5, so read it with the `DEEP_LEARNING`
  python.

## Changes

- Before and after any change to `ligysis.py` or the dependencies, run the
  regression check defined in the local files. Upgrade python, pandas, etc.
  only on a branch.
- Default branch `main`; remotes `origin` = our fork, `upstream` = original.
  Keep upstream-bound fixes small and separate.
- Match the style of `ligysis.py`: plain functions, `log.info`/`log.warning`
  with explicit messages, no bare `except` in new code.
- Commit only when asked, and push only when asked.
