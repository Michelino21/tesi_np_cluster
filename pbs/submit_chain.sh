#!/bin/bash
# Sottomette una catena di job PBS: ogni job parte solo se il precedente
# e' terminato con successo (dipendenza "afterok").
#
# Da eseguire SUL CLUSTER (login node), dalla root del repo, dopo aver
# generato gli script Python con `make convert-all`.
set -euo pipefail

# ---- Configurazione ----
QUEUE="cpu"
NCPUS=1
WALLTIME="04:00:00"
VENV_ACTIVATE="/software/pyplot/bin/activate"   # oppure $HOME/my_env/bin/activate
SCRIPT_DIR="scripts"
LOG_DIR="logs"

# Ordine di esecuzione della catena (aggiungi / togli / riordina qui)
JOBS=(
    "gaussian_H1_highBref_imbalance_validation"
    "multidistribution_cluster_ready_clean"
    "unbalanced_multidistribution_cluster_ready_clean"
)

mkdir -p "$LOG_DIR"

PREV_JOBID=""
i=0
for name in "${JOBS[@]}"; do
    i=$((i + 1))
    jobname="chain${i}"
    script="${SCRIPT_DIR}/${name}.py"

    if [ ! -f "$script" ]; then
        echo "Errore: $script non trovato. Esegui prima 'make convert-all'." >&2
        exit 1
    fi

    jobscript="$(mktemp)"
    cat > "$jobscript" <<PBSEOF
#!/bin/bash
#PBS -N ${jobname}
#PBS -q ${QUEUE}
#PBS -l select=1:ncpus=${NCPUS}
#PBS -l walltime=${WALLTIME}
#PBS -j oe
#PBS -o ${LOG_DIR}/${name}.log

cd \$PBS_O_WORKDIR
source ${VENV_ACTIVATE}
python ${script}
PBSEOF

    if [ -z "$PREV_JOBID" ]; then
        JOBID=$(qsub "$jobscript")
    else
        JOBID=$(qsub -W depend=afterok:"$PREV_JOBID" "$jobscript")
    fi

    echo "Sottomesso '${name}' (PBS: ${jobname}) -> ${JOBID}  (dipende da: ${PREV_JOBID:-nessuno})"
    PREV_JOBID="$JOBID"
    rm -f "$jobscript"
done

echo ""
echo "Catena completa. Monitora con: qstat -u \$(whoami)"
echo "Log in: ${LOG_DIR}/"
