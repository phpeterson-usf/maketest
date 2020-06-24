# maketest -- This Makefile can pull, build, and test projects from GitHub Classroom
#             Relies heavily on extensions in GNU make 4.2 and later


# Allow STUDENTS, PROJECT, and ORG to be specified on the command line, e.g.
# make STUDENTS="ankitakhatri chelseaxkaye" PROJECT=project03
# These names must match what you set up in GitHub Classroom
ifndef $(STUDENTS)
	STUDENTS = ankitakhatri chelseaxkaye chih98 dmoy2 dsamia25 gaokevin1 glatif1 \
	kai-eiji mushi14 nljones4 phcarbajal pkmohabir1 rakesh-raju ravipat98 serenapang xli149
endif

ifndef $(PROJECT)
	PROJECT = project02
endif

ifndef $(ORG)
	ORG = cs315-20s
endif

ifndef $(EXECUTABLE)
	EXECUTABLE = $(PROJECT)
endif

TESTS_DIR = $(PWD)/tests/$(PROJECT)
LOG = $(PWD)/$(PROJECT).log
GITHUB = github.com

# Allow DIRECTORIES to be overridden by MODE=student below. It's here for an arcane make syntax reason
$(foreach s, $(STUDENTS), $(eval DIRECTORIES += $(GITHUB)/$(ORG)/$(PROJECT)-$(s)))
ifndef MODE
	# In student mode, we only need one directory
	MODE = student
	DIRECTORIES = $(DIR)
endif

# Set up these make targets for the clone, build, and test phase
# My approach relies on these target suffixes to generate unique targets
CLONE_SUFFIX = __clone__
$(foreach d, $(DIRECTORIES), $(eval CLONE_TARGETS += $(d)/$(CLONE_SUFFIX)))

BUILD_SUFFIX = __build__
$(foreach d, $(DIRECTORIES), $(eval BUILD_TARGETS += $(d)/$(BUILD_SUFFIX)))

RUN_SUFFIX = __run__
$(foreach d, $(DIRECTORIES), $(foreach i, $(wildcard $(TESTS_DIR)/*.input), \
	$(eval RUN_TARGETS += $(d)/$(notdir $(i))$(RUN_SUFFIX))))

DIFF_SUFFIX = __diff__
$(foreach d, $(DIRECTORIES), $(foreach i, $(wildcard $(TESTS_DIR)/*.input), \
	$(eval DIFF_TARGETS += $(d)/$(notdir $(i))$(DIFF_SUFFIX))))

SCORE_SUFFIX = __score__
$(foreach d, $(DIRECTORIES), $(eval SCORE_TARGETS += $(d)/$(SCORE_SUFFIX)))

# Set up different targets for student mode vs. teacher mode
STUDENT_TARGETS = $(BUILD_TARGETS) $(RUN_TARGETS) $(DIFF_TARGETS) $(SCORE_TARGETS)
ifneq ($(MODE), teacher)
	# In student mode, we run and test a single preexisting directory 
	MODE_TARGETS = $(STUDENT_TARGETS)
else
	# In teacher mode, we clone all the repos, and run and test them all
	MODE_TARGETS = $(CLONE_TARGETS) $(STUDENT_TARGETS)
endif

.ONESHELL:  # grumble

all: $(MODE_TARGETS)

# Clean just removes the artifact files
# If you want to remove the repo/s you can do that yourself
clean:
ifeq ($(MODE), student)
	rm -rf $(DIR)/*.actual $(DIR)/$(PROJECT).score
else
	$(shell find . -name *.actual -exec rm {} \;)
	$(shell find . -name *.score -exec rm {} \;)
endif
	rm -rf *.log

# This target runs the clone out of github classroom using its URL format
$(CLONE_TARGETS):
	$(eval repo_path = $(subst $(CLONE_SUFFIX),,$@))
	$(eval repo_dir = $(PWD)/$(repo_path))
	@echo "clone: "$(repo_path) | tee -a $(LOG)

	if [ ! -d $(repo_dir) ]; then
		git clone https://$(repo_path) $(repo_dir) 2>>$(LOG)
	fi

# This target makes each of the student projects
$(BUILD_TARGETS):
	$(eval repo_dir = $(subst $(BUILD_SUFFIX),,$@))
	echo "build: "$(repo_dir) | tee -a $(LOG)

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
	echo "  run: "$(repo_dir)" with params: "$(params) | tee -a $(LOG)

	if [ -x $(repo_dir)/$(EXECUTABLE) ]; then
		$(repo_dir)/$(EXECUTABLE) $(params) > $(repo_dir)/$(test_case).actual
	else
		echo "no executable" | tee -a $(LOG)
	fi

# This target runs diff on each .actual result to compare it with the .expected file in $(TESTS_DIR)
$(DIFF_TARGETS):
	$(eval nodiff = $(subst $(DIFF_SUFFIX),,$@))
	$(eval repo_dir = $(dir $(nodiff)))
	$(eval test_case = $(basename $(notdir $(nodiff))))
	echo -n " diff: "$(repo_dir)" test case "$(test_case)": " | tee -a $(LOG)

	$(eval rubric_file = $(TESTS_DIR)/$(test_case).rubric)
	if [ ! -f $(rubric_file) ]; then
		echo "no rubric file" | tee -a $(LOG)
	fi
	$(eval score_file = $(repo_dir)/$(PROJECT).score)

	if [ -f $(repo_dir)/$(test_case).actual ]; then
		diff -s $(repo_dir)/$(test_case).actual $(TESTS_DIR)/$(test_case).expected >>$(LOG)
		if [ $$? -eq 0 ]; then
			echo "pass!" | tee -a $(LOG)
			$(eval rubric = $(file < $(rubric_file)))
			echo -n " + "$(rubric) >> $(score_file) | tee -a $(LOG)
		else
			echo "fail" | tee -a $(LOG)
			echo -n " + 0" >> $(score_file) | tee -a $(LOG)
		fi
	else
		echo "no actual" | tee -a $(LOG)
		echo -n " + 0" >> $(score_file) | tee -a $(LOG)
	fi

# This target runs shell expr to add up the accumulated rubric scores for each test case
$(SCORE_TARGETS):
	$(eval repo_dir = $(subst $(SCORE_SUFFIX),,$@))
	echo -n "score: "$(repo_dir)" " | tee -a $(LOG)

	$(eval score_file = $(repo_dir)/$(PROJECT).score)
	$(eval scores = $(file < $(score_file)))
	echo $(shell expr $(scores)) | tee -a $(LOG)
