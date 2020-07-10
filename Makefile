# maketest -- This Makefile can pull, build, and test projects from GitHub Classroom
#             Relies heavily on extensions in GNU make 4.2 and later

# Allow STUDENTS, PROJECT, and ORG to be specified on the command line, e.g.
# make STUDENTS="ankitakhatri chelseaxkaye" PROJECT=project03
# These names must match what you set up in GitHub Classroom
ifndef STUDENTS
$(error STUDENTS is not set)
endif

ifndef PROJECT
$(error PROJECT is not set)
endif

ifndef ORG
$(error ORG is not set)
endif

ifndef $(EXECUTABLE)
	EXECUTABLE = $(PROJECT)
endif

TESTS_DIR = $(PWD)/tests/$(PROJECT)
LOG = $(PWD)/$(PROJECT).log
GITHUB = github.com

# Allow DIRECTORIES to be overridden by DIR below. It's here for an arcane make syntax reason
$(foreach s, $(STUDENTS), $(eval DIRECTORIES += $(GITHUB)/$(ORG)/$(PROJECT)-$(s)))
ifdef DIR
	# To test one student's project, we only need one directory
	DIRECTORIES = $(DIR)
endif

# Set up these make targets for the clone, build, and test phase
# My approach relies on these target suffixes to generate unique targets
CLONE_SUFFIX = __clone__
$(foreach d, $(DIRECTORIES), $(eval CLONE_TARGETS += $(d)/$(CLONE_SUFFIX)))

PULL_SUFFIX = __pull__
$(foreach d, $(DIRECTORIES), $(eval PULL_TARGETS += $(d)/$(PULL_SUFFIX)))

CLEAN_SUFFIX = __clean__
$(foreach d, $(DIRECTORIES), $(foreach i, $(wildcard $(TESTS_DIR)/*.input), \
	$(eval CLEAN_TARGETS += $(d)/$(basename $(notdir $(i))).actual$(CLEAN_SUFFIX))))
$(foreach d, $(DIRECTORIES), $(eval CLEAN_TARGETS += $(d)/$(PROJECT).score$(CLEAN_SUFFIX)))

BUILD_SUFFIX = __build__
$(foreach d, $(DIRECTORIES), $(eval BUILD_TARGETS += $(d)/$(BUILD_SUFFIX)))

RUN_SUFFIX = __run__
$(foreach d, $(DIRECTORIES), $(foreach i, $(wildcard $(TESTS_DIR)/*.input), \
	$(eval RUN_TARGETS += $(d)/$(notdir $(i))$(RUN_SUFFIX))))

SCORE_SUFFIX = __score__
$(foreach d, $(DIRECTORIES), $(eval SCORE_TARGETS += $(d)/$(SCORE_SUFFIX)))

TEST_TARGETS = $(CLEAN_TARGETS) $(BUILD_TARGETS) $(RUN_TARGETS) $(SCORE_TARGETS)

.ONESHELL:  # TODO: Find out why the makefile is so sensitive to this being right here

test: $(TEST_TARGETS)
clone: $(CLONE_TARGETS)
pull: $(PULL_TARGETS)

# Convenience functions encapsulate the tee
echo_t = echo $(1) | tee -a $(LOG)
echo_nt = echo -n $(1) | tee -a $(LOG)

# This target runs the clone out of github classroom using its URL format
$(CLONE_TARGETS):
	$(eval repo_path = $(subst $(CLONE_SUFFIX),,$@))
	$(eval repo_dir = $(PWD)/$(repo_path))
	$(call echo_t, "clone: "$(repo_path))

	if [ ! -d $(repo_dir) ]; then
		git clone https://$(repo_path) $(repo_dir) 2>>$(LOG)
	fi

# This target runs git pull on each of the student repos
$(PULL_TARGETS):
	$(eval repo_path = $(subst $(PULL_SUFFIX),,$@))
	$(eval repo_dir = $(PWD)/$(repo_path))
	$(call echo_t, " pull: "$(repo_path))

	if [ -d $(repo_dir) ]; then
		git -C $(repo_dir) pull 1>> $(LOG) 2>>$(LOG)
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

	if [ -f $(repo_dir)/Makefile ]; then
		make -C $(repo_dir) 1>>$(LOG) 2>>$(LOG)
	else
		gcc -o $(repo_dir)/$(EXECUTABLE) $(repo_dir)/nt.c 1>>$(LOG) 2>>$(LOG) # TODO: what if no Makefile
	fi

# This target runs the student's executable once for each test case, generating a .actual file
$(RUN_TARGETS):
	$(eval norun = $(subst $(RUN_SUFFIX),,$@))
	$(eval repo_dir = $(dir $(norun)))
	$(eval input_file = $(notdir $(norun)))
	$(eval params = $(file < $(TESTS_DIR)/$(input_file)))
	$(eval test_case = $(basename $(input_file)))
	$(call echo_nt, "  run: "$(repo_dir)" ")

	if [ -x $(repo_dir)/$(EXECUTABLE) ]; then
		$(repo_dir)/$(EXECUTABLE) $(params) > $(repo_dir)/$(test_case).actual

		$(eval rubric_file = $(TESTS_DIR)/$(test_case).rubric)
		if [ ! -f $(rubric_file) ]; then
			# Teacher needs to provide a rubric
			$(call echo_t, "no rubric file for test case "$(test_case))
		fi
		$(eval score_file = $(repo_dir)/$(PROJECT).score)

		if [ -f $(repo_dir)/$(test_case).actual ]; then
			diff -i -s $(repo_dir)/$(test_case).actual $(TESTS_DIR)/$(test_case).expected >>$(LOG)
			if [ $$? -eq 0 ]; then
				# .actual == .expected
				$(call echo_nt, "PASS")
				$(eval rubric = $(file < $(rubric_file)))
				$(call echo_nt, " + "$(rubric) >> $(score_file))
			else
				# .actual != .expected
				$(call echo_nt, "FAIL")
				$(call echo_nt, " + 0" >> $(score_file))
			fi
		else
			# Program ran but no .actual. Seg fault?
			$(call echo_t, "no actual - did the program crash?")
			$(call echo_nt, " + 0" >> $(score_file))
		fi
		$(call echo_t, " for: "$(params))
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
	$(eval scores = $(file < $(score_file)))
	$(call echo_t, $(shell expr $(scores)))
