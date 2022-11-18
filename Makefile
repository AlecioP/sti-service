# Get directory containing this makefile
MKF_ABS := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_DIR := $(dir $(MKF_ABS))



# In production no REMOTE_DATA variable will be passed to make.
# While in debug we pass the variable from command line
ifndef AM_DEBUG
$(error AM_DEBUG is undefined)
endif

ifeq ($(AM_DEBUG),true)
	ifndef CORE_DATA_ORIGIN
$(error In debug mode CORE_DATA_ORIGIN is required from command line)
	else
$(info CORE_DATA_ORIGIN is $(CORE_DATA_ORIGIN:/=))
	endif
else
	ifneq ($(AM_DEBUG),false)
$(error Wrong value for AM_DEBUG. Should be 'true' or 'false')
	endif
endif

ifndef CORE_DATA_ORIGIN
CORE_DATA_ORIGIN=http://cosenza.iit.cnr.it/repo/sti/dati_base
endif

SOLR_INDEX_CONF_LOCATION=/opt/solr/server/solr
SOLR_DATA_DIR=/var/solr/data
SOLR_INIT_SCRIPT=/opt/solr/bin/solr.in.sh
DATA_FILE=INDEX_SOLR_DATI_BASE.zip
# If CORE_DATA_ORIGIN ends with slash remove it
# should happen only in debug mode when defined from 
# command line
REMOTE_DATA=$(CORE_DATA_ORIGIN:/=)/$(DATA_FILE)
EXTRACTED_DIR=$(SOLR_DATA_DIR)/$(DATA_FILE:.zip=)

all: import

import: new-method #in-step1 in-step2 in-step3

# Reference https://tutorialspoint.com/apache_solr/apache_solr_core.htm
# " ...
# A Solr Core is a running instance of a Lucene index that contains 
# all the Solr configuration files required to use it. We need to create 
# a Solr Core to perform operations like indexing and analyzing.
# 
# A Solr application may contain one or multiple cores. If necessary, 
# two cores in a Solr application can communicate with each other.
# ... "

# Each core has the following structure:
# /var/solr/data/testcore/
# ├── conf
# │   ├── lang
# │   │   ├── stopwords.txt
# │   │   ├── contractions.txt
# │   │   └── userdict_ja.txt
# │   ├── managed-schema.xml
# │   ├── protwords.txt
# │   ├── solrconfig.xml
# │   └── synonyms.txt
# ├── core.properties
# └── data
#     ├── index
#     │   ├── segments_1
#     │   └── write.lock
#     ├── snapshot_metadata
#     └── tlog
# 
# 6 directories, 47 files
# 
# In order to recreate this structure we use the utility
# ${SOLR_INSTALL_DIR}/bin/solr create_core -c $CORE_NAME
# which will give us the default 'core.properties' file
# then we will replace 'conf/' subdirectory with the configuration
# provided in this repository at './extra/solr/solr_conf'
# and finally we replace 'data/' directory with the one available
# from the archive at $REMOTE_DATA
#
# This process is repeated for each lucene core defined in 
# './extra/solr/solr_conf'
CORE_CREATE_PATH=/opt/solr/bin/solr

new-method: n-step1 n-step2

n-step1:
#	sudo service solr start
	su tomcat -c "mkdir ~/tmp/ 2>/dev/null || rm -r ~/tmp/ && echo 'Removing and recreating ~/tmp/' && mkdir ~/tmp/"
	for dir in ./extra/solr/solr_conf/sti_*_conf/ ; do sudo cp -r $$dir /opt/tomcat/tmp/ ; done
	sudo chown -R tomcat: /opt/tomcat/tmp/
#	Using single quotes for external -c argument prevents core variable to be expanded from father shell
	su tomcat -c ' \
		cd ~/tmp/ && \
		for core in sti_*_conf/ ; do \
			rem_pre=$${core#sti_} && \
			rem_suf=$${rem_pre%_conf/} && \
			core_name=$${rem_suf^^} && \
			echo "Creating new core named $${core_name}_IDX" && \
			(ls "/var/solr/data/$$core_name" 2>/dev/null && echo "Core already exists" && echo "") || \
			(echo "No core in SOLR_HOME. Proceeding to creation" && $(CORE_CREATE_PATH) create_core -c $${core_name}_IDX) \
		; done'
#	sudo service solr stop

	su tomcat -c ' \
		if [ -f "/tmp/$(DATA_FILE)" ] ; then \
			echo "Data already downloaded"; \
		else \
			curl $(REMOTE_DATA) --output /tmp/$(DATA_FILE) \
		; fi '

n-step2:
# Repeating the for statement because create_core works only if Solr service is On, but changes to data dir
# should happen after the service is stopped
	su tomcat -c ' \
		(mkdir ~/tmp/extract/ 2>/dev/null || (rm -r ~/tmp/extract/ && mkdir ~/tmp/extract/) ) && \
		unzip -q /tmp/$(DATA_FILE) -d ~/tmp/extract/ && \
		cd ~/tmp/ && \
		for core in sti_*_conf/ ; do \
			rem_pre=$${core#sti_} && \
			rem_suf=$${rem_pre%_conf/} && \
			core_name=$${rem_suf^^} && \
			echo "Changing conf/ and data/ for core $${core_name}_IDX" && \
			echo "Deleting $(SOLR_DATA_DIR)/$${core_name}_IDX/conf/" && \
			rm -r $(SOLR_DATA_DIR)/$${core_name}_IDX/conf/ && \
			echo "Copying $${core}. in $(SOLR_DATA_DIR)/$${core_name}_IDX/conf/" && \
			cp -a $${core}. $(SOLR_DATA_DIR)/$${core_name}_IDX/conf/ && \
			echo "Deleting $(SOLR_DATA_DIR)/$${core_name}_IDX/data/" && \
			rm -r $(SOLR_DATA_DIR)/$${core_name}_IDX/data/ && \
			echo "Copying ./extract/$(DATA_FILE:.zip=)/$${core_name}_IDX/. in $(SOLR_DATA_DIR)/$${core_name}_IDX/data/" && \
			cp -a ./extract/$(DATA_FILE:.zip=)/$${core_name}_IDX/. $(SOLR_DATA_DIR)/$${core_name}_IDX/data/ && \
			echo "" \
		; done'


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
			echo "" \
		; else \
			echo "Directory $$CLEAN_NAME already exists in $(SOLR_INDEX_CONF_LOCATION)" && \
			echo "" \
		; fi \
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
