# maketest -- This Makefile can pull, build, and test projects from GitHub Classroom
#             Relies heavily on extensions in GNU make 4.2 and later

# Allow STUDENTS, PROJECT, and ORG to be specified on the command line, e.g.
# make STUDENTS="phpeterson-usf gdbenson" PROJECT=project03
# These names must match what you set up in GitHub Classroom

# PROJECT=lab03
# ORG=USF-CS315-F20
# STUDENTS=gdbenson \
# phpeterson-usf

# STUDENTS and ORG are required if DIR is not defined
ifndef DIR
ifndef STUDENTS
$(error STUDENTS is not set)
endif
ifndef ORG
$(error ORG is not set)
endif
endif

ifndef PROJECT
$(error PROJECT is not set)
endif

ROOT_DIR := $(PWD)
TESTS_DIR = $(ROOT_DIR)/tests/$(PROJECT)
LOG_FILE = $(ROOT_DIR)/$(PROJECT).log
CSV_FILE = $(ROOT_DIR)/$(PROJECT).csv
PROJECT_PATH = github.com/$(ORG)/$(PROJECT)-

# Allow DIRECTORIES to be overridden by DIR below. It's here for an arcane make syntax reason
$(foreach s, $(STUDENTS), $(eval DIRECTORIES += $(PROJECT_PATH)$(s)))
ifdef DIR
# To test one student's project, we only need one directory
DIRECTORIES = $(DIR)
endif

# Set up these make targets for the clone, build, and test phase
# My approach relies on these target suffixes to generate unique targets
CLONE_SUFFIX = /__clone__
$(foreach d, $(DIRECTORIES), $(eval CLONE_TARGETS += $(d)$(CLONE_SUFFIX)))

PULL_SUFFIX = /__pull__
$(foreach d, $(DIRECTORIES), $(eval PULL_TARGETS += $(d)$(PULL_SUFFIX)))

CHECKOUT_SUFFIX = /__checkout__
$(foreach d, $(DIRECTORIES), $(eval CHECKOUT_TARGETS += $(d)$(CHECKOUT_SUFFIX)))

CLEAN_SUFFIX = /__clean__
$(foreach d, $(DIRECTORIES), $(foreach i, $(wildcard $(TESTS_DIR)/*.input), \
	$(eval CLEAN_TARGETS += $(d)/$(basename $(notdir $(i))).actual$(CLEAN_SUFFIX))))
$(foreach d, $(DIRECTORIES), $(eval CLEAN_TARGETS += $(d)/$(PROJECT).score$(CLEAN_SUFFIX)))

BUILD_SUFFIX = /__build__
$(foreach d, $(DIRECTORIES), $(eval BUILD_TARGETS += $(d)$(BUILD_SUFFIX)))

RUN_SUFFIX = /__run__
$(foreach d, $(DIRECTORIES), $(foreach i, $(shell ls $(TESTS_DIR)/*.input), \
	$(eval RUN_TARGETS += $(d)/$(basename $(notdir $(i)))$(RUN_SUFFIX))))

SCORE_SUFFIX = /__score__
$(foreach d, $(DIRECTORIES), $(eval SCORE_TARGETS += $(d)$(SCORE_SUFFIX)))

TEST_TARGETS = $(CLEAN_TARGETS) $(BUILD_TARGETS) $(RUN_TARGETS) csv_header $(SCORE_TARGETS)

.ONESHELL:  # TODO: Find out why the makefile is so sensitive to this being right here

test: $(TEST_TARGETS)
clone: $(CLONE_TARGETS)
pull: $(PULL_TARGETS)
checkout: $(CHECKOUT_TARGETS)
clean: $(CLEAN_TARGETS)

csv_header:
	echo "GitHub ID,Score" > $(CSV_FILE) # truncate

# Convenience functions encapsulate the tee
echo_t = echo $(1) | tee -a $(LOG_FILE)
echo_nt = echo -n $(1) | tee -a $(LOG_FILE)

# This target runs the clone out of github classroom using its URL format
$(CLONE_TARGETS):
	$(eval repo_path = $(subst $(CLONE_SUFFIX),,$@))
	$(eval repo_dir = $(ROOT_DIR)/$(repo_path))
	$(call echo_t, "clone: "$(repo_path))

	if [ ! -d $(repo_dir) ]; then
		git clone https://$(repo_path) $(repo_dir) 2>>$(LOG_FILE)
	fi

# This target runs git pull on each of the student repos
$(PULL_TARGETS):
	$(eval repo_path = $(subst $(PULL_SUFFIX),,$@))
	$(eval repo_dir = $(ROOT_DIR)/$(repo_path))
	$(call echo_t, " pull: "$(repo_path))

	if [ -d $(repo_dir) ]; then
		git -C $(repo_dir) pull 1>> $(LOG_FILE) 2>>$(LOG_FILE)
	else
		$(call echo_t, "no repo")
	fi

$(CHECKOUT_TARGETS):
	$(eval repo_path = $(subst $(CHECKOUT_SUFFIX),,$@))
	$(call echo_t, "checkout: "$(repo_path))

	if [ -d $(repo_path) ]; then
		git -C $(repo_dir) checkout $(DATE) 1>>$(LOG_FILE) 2>>$(LOG_FILE)
	else
		$(call echo_t, "no repo")
	fi

# This target removes maketest artifacts to prepare for a test run
# .actual may not matter much since we overwrite, but .score matters since we append
$(CLEAN_TARGETS):
	$(eval artifact = $(subst $(CLEAN_SUFFIX),,$@))
	if [ -f $(artifact) ]; then
		rm $(artifact)
	fi

# This target makes each of the student projects
$(BUILD_TARGETS):
	$(eval repo_dir = $(subst $(BUILD_SUFFIX),,$@))
	$(call echo_t, "build: "$(repo_dir))

	make -C $(repo_dir) 1>>$(LOG_FILE) 2>>$(LOG_FILE)

# This target runs the student's executable once for each test case, generating a .actual file
$(RUN_TARGETS):
	$(eval norun = $(subst $(RUN_SUFFIX),,$@))
	$(eval repo_dir = $(dir $(norun)))
	$(eval test_case = $(notdir $(norun)))
	$(eval params = $(file < $(TESTS_DIR)/$(test_case).input))
	$(eval executable = $(repo_dir)/$(PROJECT))
	$(call echo_nt, "  run: "$(repo_dir)" ")

	if [ -x $(executable) ]; then
		timeout 10s $(executable) $(params) > $(repo_dir)/$(test_case).actual

		$(eval rubric_file = $(TESTS_DIR)/$(test_case).rubric)
		if [ ! -f $(rubric_file) ]; then
			# Teacher needs to provide a rubric
			$(call echo_t, "no rubric file for test case "$(test_case))
		fi
		$(eval score_file = $(repo_dir)/$(PROJECT).score)

		# If the project's output is not on stdout, we use $(test_case).altactual to contain
		# the name of the output file which will be diff'd against $(test_case).expected 
		$(eval alt_actual_file = $(TESTS_DIR)/$(test_case).altactual)
		$(eval actual_file = $(repo_dir)$(test_case).actual)

		if [ -f $(alt_actual_file) ]; then
			$(eval actual_file = $(repo_dir)/$(file < $(alt_actual_file)))
			diff -b -i -s $(actual_file) $(TESTS_DIR)/$(test_case).expected >>$(LOG_FILE)
		else
			$(eval actual_file = $(repo_dir)$(test_case).actual)
			diff -b -i -s $(actual_file) $(TESTS_DIR)/$(test_case).expected >>$(LOG_FILE)
		fi
		if [ $$? -eq 0 ]; then
			# .actual == .expected
			$(call echo_nt, "\e[1;32mPass\e[0m")
			$(eval rubric = $(file < $(rubric_file)))
			$(call echo_nt, " + "$(rubric) >> $(score_file))
		else
			# .actual != .expected
			$(call echo_nt, "\e[1;31mFail\e[0m")
			$(call echo_nt, " + 0" >> $(score_file))
		fi
		$(call echo_t, " for test case: "$(test_case))
	else
		# Program didn't build
		$(call echo_t, "no executable - did the program build?")
		$(call echo_nt, " + 0" >> $(score_file))
	fi

# This target runs shell expr to add up the accumulated rubric scores for each test case
$(SCORE_TARGETS):
	$(eval repo_dir = $(subst $(SCORE_SUFFIX),,$@))
	$(call echo_nt, "score: "$(repo_dir)" ")
	$(eval score_file = $(repo_dir)/$(PROJECT).score)

	if [ -f $(score_file) ]; then
		$(eval score = $(shell expr $(file < $(score_file))))
		$(call echo_t, $(score))
		$(eval student = $(subst $(PROJECT_PATH)/,,$(repo_dir)))
		echo $(student)","$(score) >> $(CSV_FILE) # append
	else
		$(call echo_t, "no score file - are there test cases?")
	fi
