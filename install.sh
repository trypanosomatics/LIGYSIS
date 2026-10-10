#!/usr/bin/env bash
# Build the four LIGYSIS conda envs from ENVS/pinned/*.explicit.txt and install the vendored forks.
#
#   git clone --recurse-submodules https://github.com/trypanosomatics/LIGYSIS.git
#   cd LIGYSIS && cp site.env.sample site.env && $EDITOR site.env
#   ./install.sh [ENV ...]        # default: DSSP ARPEGGIO LIGYSIS DEEP_LEARNING
#
# site.env (or the environment) provides:
#   ENVS_DIR     where the envs are created (required)
#   MIRROR_DIR   optional local conda channel (linux-64/) holding the packages that are not on
#                conda-forge (salilab, rdonnelly, Anaconda defaults), see ENVS/pinned/README.md.
#                If unset, the original URLs in the lock files are used.
#   CONDA        conda executable (default: conda on PATH)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_ENV="${LIGYSIS_SITE_ENV:-$HERE/site.env}"
if [[ -f $SITE_ENV ]]; then
    # shellcheck disable=SC1090
    source "$SITE_ENV"
fi
: "${ENVS_DIR:?ENVS_DIR is not set; copy site.env.sample to site.env and edit it}"
CONDA="${CONDA:-conda}"
PIN="$HERE/ENVS/pinned"

for sub in ProIntVar SM_VarAlign arpeggio; do
    [[ -e $HERE/vendor/$sub/setup.py ]] || { echo "vendor/$sub is empty: run 'git submodule update --init'" >&2; exit 1; }
done

ENV_LIST=("$@"); [[ ${#ENV_LIST[@]} -gt 0 ]] || ENV_LIST=(DSSP ARPEGGIO LIGYSIS DEEP_LEARNING)
mkdir -p "$ENVS_DIR"

for e in "${ENV_LIST[@]}"; do
    echo "=== $e: conda packages"
    lock=$(mktemp)
    if [[ -n ${MIRROR_DIR:-} ]]; then
        sed -E "s#^https://(conda\.anaconda\.org/(salilab|rdonnelly)|repo\.anaconda\.com/pkgs/main)/linux-64/([^#]+)#file://$MIRROR_DIR/linux-64/\3#" \
            "$PIN/$e.explicit.txt" > "$lock"
    else
        cp "$PIN/$e.explicit.txt" "$lock"
    fi
    rm -rf "${ENVS_DIR:?}/$e"
    "$CONDA" create -y -q -p "$ENVS_DIR/$e" --file "$lock"
    rm -f "$lock"
    py="$ENVS_DIR/$e/bin/python"

    case $e in
    LIGYSIS)
        echo "=== LIGYSIS: pip packages and vendored ProIntVar / VarAlign"
        pipreq=$(mktemp)
        sed -n '/^ *- pip:/,$p' "$PIN/LIGYSIS.pinned.yml" | grep -E '^ +- [A-Za-z].*==' | sed -E 's/^ +- //' > "$pipreq"
        "$py" -m pip install -q --no-deps -r "$pipreq"; rm -f "$pipreq"
        # ProIntVar first: VarAlign imports it
        "$py" -m pip install -q --no-deps "$HERE/vendor/ProIntVar" "$HERE/vendor/SM_VarAlign"
        echo "=== LIGYSIS: ProIntVar-config-load (dssp_bin -> $ENVS_DIR/DSSP/bin/mkdssp)"
        ini="$ENVS_DIR/ProIntVar_config.ini"
        sed "s#@ENVS_DIR@#$ENVS_DIR#" "$HERE/config/prointvar_config.ini.sample" > "$ini"
        echo y | "$ENVS_DIR/LIGYSIS/bin/ProIntVar-config-load" "$ini"
        ;;
    ARPEGGIO)
        echo "=== ARPEGGIO: vendored pdbe-arpeggio (fork with the _chem_comp change, no manual patch)"
        "$py" -m pip install -q --no-deps "$HERE/vendor/arpeggio"
        ;;
    esac
done

echo "=== done. Next: cp ligysis_config.txt.sample ligysis_config.txt (edit paths), then ./run_ligysis.sh check"
