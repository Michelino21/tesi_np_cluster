# tesi

Repo per lo scambio di codice tra PC Windows e cluster dipartimentale (vedi `docs/Students_Cluster_Guide.pdf`).

- **Struttura del repo** (cosa c'e', a cosa serve, come scrivere i notebook): [docs/structure.md](docs/structure.md)
- **Prima configurazione** (PC Windows, accesso GitHub dal cluster, clone): [docs/setup.md](docs/setup.md)

## Workflow di tutti i giorni

**Sul PC Windows** (editing, con Git Bash o `cmd`/PowerShell — niente `make`):
```bash
git add -A
git commit -m "descrizione modifiche"
git push
```

**PER ENTRARE NEL CLUSTER***
```bash
./cluster_login.bat
```

**Sul cluster** (esecuzione):
```bash
cd /work/$(whoami)/tesi          # cartella di lavoro
. /etc/profile.d/pbs.sh          # comandi PBS (basta una volta per shell) (NON SERVE)
make pull                        # aggiorna il repo
source .venv/bin/activate        # attiva ambiente python
make chain                       # converte i notebook e sottomette i job in sequenza
qstat -u $(whoami)               # monitoraggio, ripeti finche' non e' vuoto (l'ultimo job e' 'chain_push')
```

**Sul PC Windows, a job finiti** (VPN attiva):
- Fai doppio click su `fetch_results.bat` (oppure eseguilo da un terminale).
- Fa `git pull` (legge `results/last_results.txt`, gia' aggiornato e pushato dal cluster) e scarica via `scp` solo le cartelle dell'ultimo run.

Vedi `make help` per l'elenco completo dei comandi.
