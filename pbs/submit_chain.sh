#!/bin/bash
# Sottomette una catena di job PBS: ogni job parte solo se il precedente
# e' terminato con successo (dipendenza "afterok").
#
# Per ogni job, ALL'AVVIO (sul nodo di calcolo, non alla sottomissione)
# viene creata una cartella contenitore results/<nome-notebook>_<timestamp>/,
# con cd dentro PRIMA di lanciare python: cosi' il log (log.txt) e
# qualunque cosa il notebook scriva con path relativi finiscono sempre
# nella stessa cartella, senza che questo script debba sapere in anticipo
# il nome che il notebook usa per i propri dati.
#
# Il nome di ciascuna cartella viene anche annotato in results/last_results.txt
# (un file TRACCIATO da git, unica eccezione dentro results/): l'ultimo job
# della catena fa commit + push di quel file, cosi' il PC Windows puo' fare
# `git pull`, leggere i nomi esatti delle cartelle dell'ultimo run e scaricare
# solo quelle con fetch_results.bat, senza doverli indovinare.
#
# IMPORTANTE: perche' il push funzioni senza password (il job non ha un
# terminale interattivo), il cluster deve avere accesso push non interattivo
# al repo (chiave SSH associata all'account git, o credential helper per
# HTTPS) - vedi README.md.
#
# Da eseguire SUL CLUSTER (login node), dalla root del repo, dopo aver
# generato gli script Python con `make convert-all`.
set -euo pipefail

# ---- Configurazione ----
QUEUE="cpu"
NCPUS=1
WALLTIME="04:00:00"
VENV_ACTIVATE=".venv/bin/activate"   # creato con `make venv`
SCRIPT_DIR="scripts"
RESULTS_DIR="results"
MANIFEST="${RESULTS_DIR}/last_results.txt"

# Ordine di esecuzione della catena.
JOBS=(
#    "gaussian_H1_highBref_imbalance_validation"
"multidistribution_cluster_compliant"
#    "unbalanced_multidistribution_cluster_ready_clean"
#    "test_pipeline"
)

mkdir -p "$RESULTS_DIR"
: > "$MANIFEST"   # svuota: conterra' solo i risultati di QUESTO run

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

cd \$PBS_O_WORKDIR
source ${VENV_ACTIVATE}
TS=\$(date +%y_%m_%d__%H_%M)
RUNDIR="${RESULTS_DIR}/${name}_\${TS}"
mkdir -p "\$RUNDIR"
echo "\$RUNDIR" >> "${MANIFEST}"
cd "\$RUNDIR"
python ../../${script} > log.txt 2>&1
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

# ---- Job finale: commit + push di last_results.txt ----
push_jobscript="$(mktemp)"
cat > "$push_jobscript" <<PBSEOF
#!/bin/bash
#PBS -N chain_push
#PBS -q ${QUEUE}
#PBS -l select=1:ncpus=1
#PBS -l walltime=00:05:00

cd \$PBS_O_WORKDIR
git add ${MANIFEST}
git commit -m "Aggiorna ${MANIFEST} \$(date +%Y-%m-%d\ %H:%M)" || true
git push
PBSEOF

PUSH_JOBID=$(qsub -W depend=afterok:"$PREV_JOBID" "$push_jobscript")
echo "Sottomesso 'chain_push' -> ${PUSH_JOBID}  (dipende da: ${PREV_JOBID})"
rm -f "$push_jobscript"

echo ""
echo "Catena completa. Monitora con: qstat -u \$(whoami)"
echo "Ogni run finisce in results/<nome-notebook>_<timestamp>/ (dati + log.txt insieme)."
echo "Se un job fallisce prima di creare quella cartella (es. venv non trovato), PBS"
echo "scrive comunque un log di scorta in <nome_job>.o<jobid> nella root del repo."
echo "A catena e push finiti, esegui fetch_results.bat sul PC Windows: fara' 'git pull'"
echo "per leggere ${MANIFEST} e scarichera' solo le cartelle elencate li'."
