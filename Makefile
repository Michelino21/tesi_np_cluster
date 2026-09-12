# Questo Makefile va usato sul cluster e su qualunque altra macchina Unix
# (es. Mac, per test locali). Sul PC Windows non serve make: si usano i
# comandi git direttamente e fetch_results.bat (vedi README.md).

# ==== Config ====
NB_DIR     := notebooks
SCRIPT_DIR := scripts
PBS_DIR    := pbs
CONFIG_DIR := config

NOTEBOOKS  := $(wildcard $(NB_DIR)/*.ipynb)
SCRIPTS    := $(patsubst $(NB_DIR)/%.ipynb,$(SCRIPT_DIR)/%.py,$(NOTEBOOKS))

.PHONY: help venv convert convert-all pull push commit chain clean

help:
	@echo "Comandi disponibili:"
	@echo "  make venv                             -> crea .venv/ e installa $(CONFIG_DIR)/requirements.txt"
	@echo "                                            (attivalo con: source .venv/bin/activate)"
	@echo "  make convert nb=notebooks/foo.ipynb   -> converte UN notebook in .py"
	@echo "  make convert-all                      -> converte TUTTI i notebook in $(SCRIPT_DIR)/"
	@echo "  make pull                             -> git pull"
	@echo "  make push                             -> git push"
	@echo "  make commit m=\"messaggio\"             -> git add -A && git commit -m messaggio"
	@echo "  make chain                            -> converte tutto e sottomette la catena PBS (solo cluster)"
	@echo "  make clean                             -> rimuove gli script .py generati"

venv:
	python3 -m venv .venv
	.venv/bin/pip install --upgrade pip
	.venv/bin/pip install -r $(CONFIG_DIR)/requirements.txt
	@echo "Fatto. Attiva con: source .venv/bin/activate"

convert:
	@if [ -z "$(nb)" ]; then echo "Uso: make convert nb=notebooks/foo.ipynb"; exit 1; fi
	@mkdir -p $(SCRIPT_DIR)
	jupyter nbconvert --to script "$(nb)" --output-dir $(SCRIPT_DIR)

convert-all: $(SCRIPTS)

$(SCRIPT_DIR)/%.py: $(NB_DIR)/%.ipynb
	@mkdir -p $(SCRIPT_DIR)
	jupyter nbconvert --to script "$<" --output-dir $(SCRIPT_DIR)

pull:
	git pull

push:
	git push

commit:
	@if [ -z "$(m)" ]; then echo "Uso: make commit m=\"messaggio\""; exit 1; fi
	git add -A
	git commit -m "$(m)"

chain: convert-all
	bash $(PBS_DIR)/submit_chain.sh

clean:
	rm -rf $(SCRIPT_DIR)
