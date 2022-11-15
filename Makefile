all: import

SOLR_INDEX_CONF_LOCATION=/opt/solr/server/solr
SOLR_DATA_DIR=/var/solr/data
SOLR_INIT_SCRIPT=/opt/solr/bin/solr.in.sh
DATA_FILE=INDEX_SOLR_DATI_BASE.zip
REMOTE_DATA=file:///home/alecio/Documenti/sti/data/$(DATA_FILE)

EXTRACTED_DIR=$(SOLR_DATA_DIR)/$(DATA_FILE:.zip=)

import: in-step1 in-step2 in-step3

# Step 1 : 	From this repository copy each Index configuration
# 			and move it to Solr conf directory
#			then rename directory as STI_{INDEX_NAME}
in-step1:
	@echo "Import indexes"
	ls -l ./extra/solr/solr_conf/
	@echo ""

	@cd ./extra/solr/solr_conf/ && \
	for d in sti_*_conf/ ; do \
		echo "Import extra/solr/solr_conf/$$d" && \
		CLEAN_NAME=$$(echo $$d | sed -Ee 's/_conf//g') && echo "Without suffix $$CLEAN_NAME" && \
		if ! test -d $(SOLR_INDEX_CONF_LOCATION)/$$CLEAN_NAME ; then \
			echo "Directory $$CLEAN_NAME does not exist" && \
			sudo cp -r $$d $(SOLR_INDEX_CONF_LOCATION) && \
			sudo mv $(SOLR_INDEX_CONF_LOCATION)/$$d $(SOLR_INDEX_CONF_LOCATION)/$$CLEAN_NAME && \
			echo "" ; \
		else \
			echo "Directory $$CLEAN_NAME already exists in $(SOLR_INDEX_CONF_LOCATION)" && \
			echo "" ; \
		fi \
	done

	@echo ""
	sudo ls -l $(SOLR_INDEX_CONF_LOCATION)
	@echo ""

# Step 2 : 	Write in solr init script the location 
# 			for every Index we are importing
#			These paths are set in SOLR_OPTIONS variable
in-step2:
	@if [ -z "$$(cat $(SOLR_INIT_SCRIPT) | grep "sti.index")" ] ; then \
		echo "Options are not set" && \
		for d in $(SOLR_INDEX_CONF_LOCATION)/sti*/ ; do \
			NAME=$$(echo $$d | sed -Ee 's;$(SOLR_INDEX_CONF_LOCATION)/sti_(.*)/;\1;g') && echo "$$NAME" && \
			echo "Set dataDir value from command line for $$d" && \
			echo "" | sudo tee -a $(SOLR_INIT_SCRIPT) > /dev/null && \
			echo "SOLR_OPTIONS=\" \$$SOLR_OPTIONS -Dsti.index.location.$$NAME=$(SOLR_DATA_DIR)/$${NAME^^}_IDX/ \"" | sudo tee -a $(SOLR_INIT_SCRIPT) > /dev/null \
		;done \
	; else \
		echo "STI options already set" \
	; fi

	@echo ""
	cat $(SOLR_INIT_SCRIPT) | tail 

# Step 3 : 	Download actual data and move 
# 			to Solr data directory which was set
#			during previous step in SOLR_OPTIONS variable
in-step3:

	@read -n 1 -p "STOP" action

	@if [ -f "/tmp/$(DATA_FILE)" ] ; then \
		echo "Data already downloaded"; \
	else \
		curl $(REMOTE_DATA) --output /tmp/$(DATA_FILE) ; \
	fi

	sudo unzip -q /tmp/$(DATA_FILE) -d $(SOLR_DATA_DIR)

	@for d in $$(sudo ls $(EXTRACTED_DIR) | grep IDX) ; do \
		echo "Moving $(EXTRACTED_DIR)/$$d in $(SOLR_DATA_DIR) " && \
		sudo mv $(EXTRACTED_DIR)/$$d $(SOLR_DATA_DIR)/ \
	; done && echo "" && echo "Removing $(EXTRACTED_DIR)" && sudo rmdir $(EXTRACTED_DIR)/

	@echo ""
	sudo ls -l $(SOLR_DATA_DIR)
