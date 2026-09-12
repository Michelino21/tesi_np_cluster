# tesi

Repo per lo scambio di codice tra laptop e cluster dipartimentale (vedi `docs/Students_Cluster_Guide.pdf`).

## Struttura

- `notebooks/` — notebook Jupyter (fonte di verita').
- `scripts/` — script `.py` generati dai notebook (non versionati, rigenerati con `make convert-all`).
- `pbs/submit_chain.sh` — sottomette una catena di job PBS (uno dopo l'altro, `afterok`).
- `logs/` — output dei job PBS (non versionato).

## Workflow tipico

**Sul laptop** (editing):
```bash
make commit m="descrizione modifiche"
make push
```

**Sul cluster** (esecuzione):
```bash
. /etc/profile.d/pbs.sh          # solo se non gia' fatto in questa shell
make pull
source /software/pyplot/bin/activate   # ambiente con numpy/scipy/pandas/matplotlib/tqdm/nbconvert
make convert-all                 # notebook -> scripts/*.py
make chain                       # sottomette i job in sequenza
qstat -u $(whoami)                # monitoraggio
```

Vedi `make help` per l'elenco completo dei comandi.
