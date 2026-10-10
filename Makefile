
#################################################################################
# GLOBALS
#################################################################################

PROJECT_NAME = lstm-log-analysis
PYTHON_INTERPRETER = python
VENV_DIR = .venv
VENV_PYTHON = $(VENV_DIR)/Scripts/python.exe
VENV_PIP = $(VENV_DIR)/Scripts/pip.exe

#################################################################################
# COMMANDS
#################################################################################

.PHONY: help setup_environment requirements data features train predict evaluate test lint clean all

help: ## Show this help message
	@echo "Available commands in $(PROJECT_NAME):"
	@echo "  setup_environment   Create virtual environment"
	@echo "  requirements        Install project dependencies"
	@echo "  data                Prepare raw log datasets"
	@echo "  features            Extract model features"
	@echo "  train               Train the LSTM model"
	@echo "  predict             Run anomaly detection"
	@echo "  evaluate            Run prediction and evaluation"
	@echo "  test                Run unit and integration tests"
	@echo "  lint                Check source code"
	@echo "  clean               Remove temporary files and caches"
	@echo "  all                 Run the complete pipeline"

setup_environment: ## Set up Python virtual environment
	$(PYTHON_INTERPRETER) -m venv $(VENV_DIR)
	$(VENV_PYTHON) -m pip install --upgrade pip setuptools wheel
	@echo ">>> Virtual environment created at $(VENV_DIR)."

requirements: ## Install Python dependencies
	$(VENV_PIP) install -r requirements.txt
	@echo ">>> Dependencies installed successfully."

data: ## Ingest and parse raw logs into structured event sequences
	$(VENV_PYTHON) src/dataset.py --download-or-generate
	@echo ">>> Raw and interim datasets prepared."

features: ## Extract sliding window sequences and persist train/val/test splits
	$(VENV_PYTHON) src/features.py
	@echo ">>> Feature engineering complete. Processed tensors saved."

train: ## Train DeepLog LSTM model on normal execution traces
	$(VENV_PYTHON) src/modeling/train.py
	@echo ">>> Model training complete. Model saved in models/."

predict: ## Run anomaly detection inference and output performance metrics
	$(VENV_PYTHON) src/modeling/predict.py --top-k 9
	@echo ">>> Inference evaluation complete."

evaluate: predict ## Alias for prediction and evaluation

test: ## Run unit and integration tests with pytest
	$(VENV_PYTHON) -m pytest tests/ src/test_scripts/ -v
	@echo ">>> Test suite completed."

lint: ## Check source code formatting and style
	$(VENV_PYTHON) -m flake8 src/ tests/ --count --select=E9,F63,F7,F82 --show-source --statistics

clean: ## Clean generated temporary files, caches, and build artifacts
	powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path . -Recurse -Directory -Force | Where-Object { $$_.Name -in @('__pycache__', '.pytest_cache') } | Remove-Item -Recurse -Force"
	powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path . -Recurse -File -Force | Where-Object { $$_.Extension -in @('.pyc', '.pyo') } | Remove-Item -Force"
	powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path . -Directory -Filter '*.egg-info' | Remove-Item -Recurse -Force"
	@echo ">>> Temporary artifacts cleaned."

all: data features train predict test ## Run the full pipeline
	@echo ">>> Full end-to-end pipeline finished successfully!"
