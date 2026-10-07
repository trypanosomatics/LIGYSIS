#!/usr/bin/env bash
# Wrapper to run LIGYSIS without manually activating conda environments.
#
#   ./run_ligysis.sh run   <UNIPROT_ACC> [ligysis.py options]   # main pipeline
#   ./run_ligysis.sh rsa   <output_dir> <seg_name>              # RSA labels (DEEP_LEARNING env)
#   ./run_ligysis.sh check                                      # sanity-check the installation
#
# Environments are NOT activated; each tool is reached through the env's bin directory:
#   LIGYSIS        python + varalign + prointvar (+ a jackhmmer copy)
#   ARPEGGIO       called via absolute paths from ligysis_config.txt
#   DSSP           called by ProIntVar via dssp_bin in its own config
#   HMMER          fallback jackhmmer (LIGYSIS env copy takes precedence)
#   DEEP_LEARNING  predict_rsa_labels.py only
#
# Site settings: ENVS_DIR (directory holding the conda envs above) comes from the
# environment, or from a git-ignored "site.env" next to this script
# (copy site.env.sample). Set LIGYSIS_SITE_ENV to use another file.

set -euo pipefail

LIGYSIS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_ENV="${LIGYSIS_SITE_ENV:-$LIGYSIS_HOME/site.env}"
if [[ -z "${ENVS_DIR:-}" && -f "$SITE_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$SITE_ENV"
fi
: "${ENVS_DIR:?ENVS_DIR is not set; copy site.env.sample to site.env and edit it}"

# LIGYSIS first (python), HMMER last (only supplies jackhmmer if LIGYSIS lacks it)
export PATH="$ENVS_DIR/LIGYSIS/bin:$ENVS_DIR/DSSP/bin:$PATH:$ENVS_DIR/HMMER/bin"

# keep numerical libs from oversubscribing shared cores
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"

usage() { sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }

check() {
    local fail=0
    ok()  { printf '  [ ok ] %s\n' "$1"; }
    bad() { printf '  [FAIL] %s\n' "$1"; fail=1; }

    echo "Executables"
    for f in \
        "$ENVS_DIR/LIGYSIS/bin/python" \
        "$ENVS_DIR/ARPEGGIO/bin/pdbe-arpeggio" \
        "$ENVS_DIR/DSSP/bin/mkdssp" \
        "$ENVS_DIR/DEEP_LEARNING/bin/python"; do
        [[ -x $f ]] && ok "$f" || bad "$f"
    done
    if command -v jackhmmer >/dev/null; then ok "jackhmmer -> $(command -v jackhmmer)"; else bad "jackhmmer not on PATH"; fi

    echo "Python packages (LIGYSIS env)"
    for m in prointvar varalign Bio pandas pysam; do
        "$ENVS_DIR/LIGYSIS/bin/python" -c "import $m" 2>/dev/null && ok "$m" || bad "$m"
    done

    echo "ARPEGGIO patch (JSU_patch.diff)"
    if grep -qE '^\s*# self.component_types' \
        "$ENVS_DIR"/ARPEGGIO/lib/python3.9/site-packages/arpeggio/core/interactions.py; then
        ok "patch applied"; else bad "patch NOT applied"; fi

    echo "Config paths (ligysis_config.txt)"
    while IFS= read -r p; do
        [[ -e $p ]] && ok "$p" || bad "$p"
    done < <(sed -nE 's/^(arpeggio_python_bin|arpeggio_bin|ensembl_sqlite|gnomad_vcf|swissprot)[[:space:]]*=[[:space:]]*//p' \
             "$LIGYSIS_HOME/ligysis_config.txt")
    local vcf; vcf=$(sed -nE 's/^gnomad_vcf[[:space:]]*=[[:space:]]*//p' "$LIGYSIS_HOME/ligysis_config.txt")
    [[ -e "$vcf.tbi" ]] && ok "$vcf.tbi" || bad "$vcf.tbi (tabix index)"

    echo "ProIntVar DSSP path"
    "$ENVS_DIR/LIGYSIS/bin/python" -c "
from prointvar.config import config as c
print('  dssp_bin =', c.dssp_bin)" 2>/dev/null || bad "could not read ProIntVar config"

    return $fail
}

[[ $# -ge 1 ]] || usage
cmd="$1"; shift

case "$cmd" in
    run)
        [[ $# -ge 1 ]] || usage
        cd "$LIGYSIS_HOME"    # ligysis.py resolves config/input/output relative to its own location
        # ligysis.py assumes the folders defined in config.py exist but never creates them
        python -c "
import os, config
for n in dir(config):
    if n.endswith('_FOLDER'):
        os.makedirs(getattr(config, n), exist_ok=True)"
        exec python ligysis.py "$@"
        ;;
    rsa)
        [[ $# -eq 2 ]] || usage
        cd "$LIGYSIS_HOME"
        exec "$ENVS_DIR/DEEP_LEARNING/bin/python" predict_rsa_labels.py "$@"
        ;;
    check)
        check
        ;;
    *) usage ;;
esac
