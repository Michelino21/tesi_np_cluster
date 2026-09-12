# Prima configurazione

Procedure da fare **una volta sola** (per macchina): PC Windows, accesso a GitHub dal cluster, clone sul cluster.

## Setup una tantum sul PC Windows

1. Installa [Git for Windows](https://git-scm.com/download/win) (da' anche `scp`/`ssh`, gia' inclusi di norma anche in Windows 10/11 senza installare nulla).
2. Copia `config/cluster_config.bat.example` in `config/cluster_config.bat` e apri quest'ultimo con un editor: imposta `CLUSTER_USER` (es. `u12345678`).
3. Se la connessione al cluster usa una chiave SSH (invece della password), assicurati che `scp` la trovi in automatico: o e' nel percorso di default (`%USERPROFILE%\.ssh\id_ed25519` ecc.), oppure aggiungi una entry in `%USERPROFILE%\.ssh\config` per l'host `10.78.18.100` con `IdentityFile <percorso-chiave>` — cosi' non serve modificare `fetch_results.bat`.

## Accesso a GitHub dal cluster (una tantum, prima del primo clone)

Il cluster deve potersi autenticare su GitHub. Il modo pulito e' una chiave SSH dedicata, generata sul cluster (diversa da quella che usi per entrare nel cluster stesso).

**1. Genera la chiave** (login node):
```bash
ssh-keygen -t ed25519 -C "cluster-tesi" -f ~/.ssh/id_ed25519_github -N ""
```
`-N ""` = nessuna passphrase, voluto: un job PBS non puo' digitarla.

**2. Dì a SSH di usarla per github.com** — apri il file con:
```bash
nano ~/.ssh/config
```
Aggiungi (in fondo, senza toccare eventuali righe gia' presenti):
```
Host github.com
    IdentityFile ~/.ssh/id_ed25519_github
```
Poi salva ed esci: `Ctrl+O`, invio per confermare il nome file, `Ctrl+X` per uscire.

**3. Copia la chiave pubblica**:
```bash
cat ~/.ssh/id_ed25519_github.pub
```

**4. Aggiungila su GitHub** (nel browser, sul tuo PC):
   - Se ti basta l'accesso a un repo solo: apri il repo su github.com → **Settings** → **Deploy keys** (menu a sinistra) → **Add deploy key** → incolla il contenuto copiato al punto 3 → **spunta "Allow write access"** (senza, il clone funziona ma il push no) → **Add key**.
   

**5. Verifica la connessione** (dal cluster):
```bash
ssh -T git@github.com
```
La prima volta chiede conferma dell'host (rispondi `yes`); poi dovrebbe rispondere con un messaggio tipo `Hi <utente>! You've successfully authenticated`.

## Setup una tantum sul cluster

Il repo va clonato in `/work/<username>/tesi` (non in `/home`): `/work` e' condiviso via NFS come `/home` (quindi visibile identico da login node e nodi di calcolo) ma con quota piu' ampia (~50 GB contro 10 GB), utile visto che i job scrivono checkpoint/CSV durante l'esecuzione (vedi `docs/Students_Cluster_Guide.pdf`, sezioni 2.1 e 4.1).

Alla primissima connessione (non hai ancora il Makefile, quindi si fa tutto a mano) — nota l'URL `git@github.com:...`, non `https://`, per usare la chiave appena configurata:
```bash
mkdir -p /work/$(whoami)
git clone git@github.com:<tuo-utente>/<tuo-repo>.git /work/$(whoami)/tesi
cd /work/$(whoami)/tesi
```
Da qui in poi trovi il Makefile. Crea subito l'ambiente Python:
```bash
make venv
```

Nota: a fine catena un job fa `git push` in automatico (per aggiornare `results/last_results.txt`), usando la stessa chiave configurata sopra. Se per qualche motivo fallisse, l'unico effetto e' che quel file non si aggiorna: i risultati restano comunque sul cluster, recuperabili a mano.

## Collaudo finale (verifica che tutto sia a posto)

Con la configurazione appena fatta, verifica che la pipeline funzioni davvero, usando `test_pipeline.ipynb` — un notebook leggero (gira in meno di un secondo) che produce lo stesso tipo di output dei notebook reali (checkpoint CSV, summary CSV, manifest JSON, figura PNG). Vedi anche [structure.md](structure.md) per la convenzione che segue.

### In locale (es. sul Mac, prima di girare sul cluster)

Il notebook si aspetta che la cartella di destinazione esista gia' e che tu ci sia gia' dentro (esattamente cio' che fa `submit_chain.sh` sul cluster):
```bash
make venv
source .venv/bin/activate
make convert nb=notebooks/test_pipeline.ipynb

TS=$(date +%y_%m_%d__%H_%M)
mkdir -p "results/test_pipeline_${TS}"
cd "results/test_pipeline_${TS}"
python ../../scripts/test_pipeline.py
cd ../..
```
Controlla che sia comparsa `results/test_pipeline_<timestamp>/` con dentro `checkpoint.csv`, `summary.csv`, `manifest.json` e `test_plot.png`.

### Sul cluster

```bash
make convert nb=notebooks/test_pipeline.ipynb
qsub -I
source .venv/bin/activate
TS=$(date +%y_%m_%d__%H_%M)
mkdir -p "results/test_pipeline_${TS}"
cd "results/test_pipeline_${TS}"
python ../../scripts/test_pipeline.py
cd ../..
exit
```
Prendi nota del nome esatto della cartella (`results/test_pipeline_<timestamp>/`), poi dal PC Windows, per verificare anche che lo `scp` funzioni, puoi scaricarla a mano una volta:
```
scp -r CLUSTER_USER@10.78.18.100:/work/CLUSTER_USER/tesi/results/test_pipeline_<timestamp> results\
```
Se tutto arriva correttamente, la stessa identica meccanica vale per `make chain` + `fetch_results.bat` con i notebook veri.

### Direttamente sul PC Windows (senza toccare il cluster)

`run_local.bat` automatizza conversione + esecuzione, con lo stesso schema di cartelle (`results\<nome>_<timestamp>\`) — utile per collaudare un notebook prima ancora di portarlo sul cluster. A differenza della catena PBS, **non** tocca `results\last_results.txt`: qui i dati restano gia' sul PC, non c'e' nulla da recuperare da remoto.

Richiede un ambiente Python locale (una tantum):
```
python -m venv .venv
.venv\Scripts\pip install -r config\requirements.txt
```
Poi, ad ogni test:
```
run_local.bat test_pipeline
```
(doppio click, oppure da `cmd`/PowerShell, passando il nome del notebook — con o senza `.ipynb`). L'output finisce in `results\test_pipeline_<timestamp>\`.

Torna al [README](../README.md) per il workflow di tutti i giorni.
