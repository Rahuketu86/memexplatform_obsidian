.ONESHELL:
SHELL := /bin/bash
PORT=8989
HOST=0.0.0.0
APP=flutter
OBPORT=9200
DEVICE=web-server
DEBUG ?=
CORE ?=

ENV := $(PWD)/.env

# Environment variables for project
include $(ENV)

# Export all variable to sub-make
export

setwinhost:
ifeq ($(OS)_$(HOST),Windows_NT_0.0.0.0)
	@echo "Windows"
	$(eval HOST=localhost)
else
	@echo "Unix"
endif

remoterun: setwinhost

ifdef DEBUG
	cd $(APP)
	flutter run -d $(DEVICE) --web-hostname $(HOST) --web-port $(PORT) --observatory-port=$(OBPORT)
else
	cd $(APP)
	flutter run -d $(DEVICE) --web-hostname $(HOST) --web-port $(PORT)
endif

tools: setwinhost
	if [ ! -d "tools" ]; then \
		echo "Tools directory does not exist, skipping execution."; \
		exit 1; \
	else \
		cd tools; \
		python_files=$$(find . -type f -name "*.py"); \
		if [ -n "$$python_files" ]; then \
			echo "Running Python files in tools directory..."; \
			for file in $$python_files; do \
				echo "Running $$file..."; \
				python "$$file"; \
			done; \
		else \
			echo "No Python files found in tools directory"; \
		fi; \
	fi




nbdev_docs:
	nbdev_docs --n_workers 1

nbdev_test:
	nbdev_test

nbdev_proc_nbs:
	nbdev_proc_nbs

nbdev_prepare:
	nbdev_prepare

proc: 
	rm -rf _proc/_docs
	nbdev_proc_nbs --n_workers 1

nbdev_preview:
	nbdev_preview --n_workers 1

render:
	nbdev_docs

obsapp: render tools setwinhost
	cd _docs && python -m http.server $(PORT)


prodsrc:
	if [ ! -d "$(SRC_DIR)" ]; then \
		mkdir -p "$(DIR_PATH)"; \
		echo "Directory created: $(SRC_DIR)"; \
	else \
		echo "Directory already exists: $(SRC_DIR)"; \
	fi
	
	nbdev_export
	cp -r AutoMLOps ${SRC_DIR}
	cp settings.ini ${SRC_DIR}
	cp setup.py	${SRC_DIR}
	cd $(SRC_DIR) && find . -name "*.py" -execdir sh -c 'grep -v "^\s*#" "$$0" > "$$0.tmp" && mv "$$0.tmp" "$$0"' {} \;
	cd $(SRC_DIR) && find . -name "*.ini" -execdir sh -c 'grep -v "^\s*[#;]" "$$0" > "$$0.tmp" && mv "$$0.tmp" "$$0"' {} \;
	cd $(SRC_DIR) && awk '{ for (i=1; i<=NF; i++) { if ($$i ~ /^https?:\/\/[^ ]*$$/) $$i = "***" } } 1' *.ini > tmp && mv tmp *.ini 
	cd ${SRC_DIR} && awk '{ gsub(/https:\/\/[^'\''\s,"]+/, "***") } 1' AutoMLOps/_modidx.py > tmp && mv tmp AutoMLOps/_modidx.py

runapp:
	memexplatform_runapp

listroutes:
	memexplatform_listroutes
	
rundesktop:
	memexplatform_rundesktop

localapp:
	chat_runapp
	
syncdb:
	memexplatform_syncdb

deletedb:
	rm -rf ${JCMS_CUSTOM_DB}*

deletechatdb:
	rm -rf ${JCMSMEMEX_DB}

initdb:
	@if [ "$(filter REPLACE,$(MAKECMDGOALS))" != "" ]; then \
		echo "With replacement"; \
		memexplatform_initdb --replace; \
	else \
		memexplatform_initdb; \
	fi

REPLACE:
	@:

droptbl:
	@if [ -z "$(TABLE_NAME)" ]; then \
		echo "Error: TABLE_NAME is required."; \
		exit 1; \
	fi
	memexplatform_droptbl $(TABLE_NAME)

jl:
	echo "Running Jupyter"
	# echo $(AIKING_HOME)
	# echo $(JUPYTER_PASSWORD)
ifdef CORE
	jupyter lab --ip 0.0.0.0 --port 9000 --no-browser --core-mode
else
	jupyter lab --ip 0.0.0.0 --port 9000 --no-browser
endif

macjl:

	echo "Running Jupyter with xvfb for Mac"
	# echo $(AIKING_HOME)
	# echo $(JUPYTER_PASSWORD)
ifdef CORE
	xvfb-run jupyter lab --ip 0.0.0.0 --port 9000 --no-browser --core-mode
else
	xvfb-run jupyter lab --ip 0.0.0.0 --port 9000 --no-browser
endif

buildpkg:
	rm -rf bin/*.whl
	python setup.py bdist_wheel -d bin  # Ensure this line starts with a tab
