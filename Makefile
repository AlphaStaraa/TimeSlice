PYTHON ?= python3

.PHONY: help install check format test desktop lite benchmark android source
help:
	@echo "install | check | format | test | desktop | android | source"
install:
	$(PYTHON) -m pip install -r requirements-dev.txt
check:
	$(PYTHON) -m ruff format --check .
	$(PYTHON) -m ruff check .
	$(PYTHON) tools/verify_source.py
	$(PYTHON) tools/index_functions.py --check
format:
	$(PYTHON) -m ruff check --fix .
	$(PYTHON) -m ruff format .
	$(PYTHON) tools/index_functions.py
test:
	$(PYTHON) tools/check_desktop.py --cpu-only
	$(PYTHON) tools/golden.py
desktop:
	$(PYTHON) tools/build_desktop.py --package
android:
	$(PYTHON) mobile/tools/sync_android_stable.py
	gradle -p mobile/android assembleDebug
source:
	$(PYTHON) tools/export_source.py --destination dist/TimeSlice-source


lite:
	$(PYTHON) tools/build_lite_ffmpeg.py
	$(PYTHON) tools/build_lite.py --package
benchmark:
	$(PYTHON) tools/build_lite.py
	$(PYTHON) tools/benchmark.py --repeats 3
