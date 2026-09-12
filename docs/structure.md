# Struttura del repo

- `notebooks/` — notebook Jupyter (fonte di verita').
- `config/` — `requirements.txt` e `cluster_config.bat` (quest'ultimo personale, non versionato).
- `scripts/` — script `.py` generati dai notebook (non versionati, rigenerati con `make convert-all`).
- `pbs/submit_chain.sh` — sottomette la catena di job PBS, usata da `make chain` sul cluster.
- `fetch_results.bat` — da eseguire sul PC Windows per scaricare i risultati dal cluster.
- `run_local.bat` — converte ed esegue un notebook direttamente sul PC Windows (test locale, senza cluster).
- `results/` — dove finiscono tutti i risultati (non versionato, tranne `last_results.txt`) — vedi sotto.

## Come i notebook devono scrivere i propri output

La convenzione: scrivere nella directory corrente. `results/` e' dove finisce tutto, mai versionato (tranne `last_results.txt`, vedi sotto).

Per ogni job, `pbs/submit_chain.sh` crea (sul nodo di calcolo, non alla sottomissione) una cartella contenitore `results/<nome-notebook>_<timestamp>/` e ci fa `cd` DENTRO prima di lanciare lo script. Questo significa che:

- `log.txt` (l'output testuale del job: stdout/stderr, barre tqdm) e
- qualunque file scriva il notebook (con path relativi alla propria cwd, es. `Path("checkpoint.csv")`)

finiscono **sempre nella stessa cartella**, senza che gli script di infrastruttura debbano conoscere in anticipo il nome che il notebook usa per i propri dati.

**Conseguenza per come si scrive un notebook**: non deve gestire da solo nome ne' timestamp della propria cartella di output — deve assumere che chi lo esegue lo abbia gia' posizionato (con `cd`) nel posto giusto, e scrivere semplicemente nella directory corrente.

`notebooks/test_pipeline.ipynb` (il notebook "template", **non** uno di quelli reali) segue gia' questa convenzione:
```python
OUTPUT_DIR = Path(".")
CHECKPOINT = OUTPUT_DIR / "checkpoint.csv"
...
```
nessun `Path("nome_fisso")`, nessuna gestione di timestamp dentro al notebook.

## `results/last_results.txt`: l'unica eccezione versionata

Un elenco (una riga per cartella) dei run appena prodotti dall'ultima catena. Il flusso:

1. `submit_chain.sh` lo svuota all'inizio di ogni nuova catena.
2. Ogni job, appena calcola la propria cartella (`results/<nome>_<timestamp>`), ci aggiunge una riga.
3. L'ultimo job della catena (`chain_push`) fa `git add` + `git commit` + `git push` di questo file soltanto.
4. Sul PC Windows, `fetch_results.bat` fa `git pull`, legge il file riga per riga, e scarica via `scp` **solo** le cartelle elencate — niente da indovinare, niente liste di nomi da mantenere a mano.

Per collaudare che tutto questo funzioni davvero (senza aspettare i job veri), vedi la fine di [setup.md](setup.md).

Torna al [README](../README.md).
