# ==== Config ====
NB_DIR     := notebooks
SCRIPT_DIR := scripts
PBS_DIR    := pbs
LOG_DIR    := logs

NOTEBOOKS  := $(wildcard $(NB_DIR)/*.ipynb)
SCRIPTS    := $(patsubst $(NB_DIR)/%.ipynb,$(SCRIPT_DIR)/%.py,$(NOTEBOOKS))

.PHONY: help convert convert-all pull push commit chain clean

help:
	@echo "Comandi disponibili:"
	@echo "  make convert nb=notebooks/foo.ipynb   -> converte UN notebook in .py"
	@echo "  make convert-all                      -> converte TUTTI i notebook in $(SCRIPT_DIR)/"
	@echo "  make pull                             -> git pull"
	@echo "  make push                             -> git push"
	@echo "  make commit m=\"messaggio\"             -> git add -A && git commit -m messaggio"
	@echo "  make chain                            -> sottomette la catena di job PBS"
	@echo "  make clean                             -> rimuove script generati e log locali"

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
	@mkdir -p $(LOG_DIR)
	bash $(PBS_DIR)/submit_chain.sh

clean:
	rm -rf $(SCRIPT_DIR) $(LOG_DIR)
