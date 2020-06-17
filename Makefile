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

ifndef $(LOG)
	LOG := $(PWD)/$(PROJECT).log
endif

ifndef $(EXECUTABLE)
	EXECUTABLE = nt # TODO: need an abstraction. maybe EXECUTABLE should be the project name?
endif

# Build a directory hierarchy, e.g. output/cs315-20s/project03/phpeterson-usf
EXPECTED = $(PWD)/expected/$(PROJECT)/
PROJ_DIR = output/$(ORG)/$(PROJECT)

# Set up these make targets for the clone, build, and test phase
# My approach relies on these kludgey names to generate unique targets

# e.g. CLONE_TARGETS=phil.clone greg.clone 
$(foreach s, $(STUDENTS), $(eval CLONE_TARGETS += $(s).clone))

# e.g. BUILD_TARGETS=phil.build greg.build
$(foreach s, $(STUDENTS), $(eval BUILD_TARGETS += $(s).build))

# e.g. RUN_TARGETS=phil.run/1.input phil.run/2.input greg.run/1.input greg.run/2.input
$(foreach s, $(STUDENTS), $(foreach i, $(wildcard $(EXPECTED)/*.input), \
	$(eval RUN_TARGETS += $(s)/$(notdir $(i)).run)))

# e.g. DIFF_TARGETS=phil.diff/1.input phil.diff/2.input greg.diff/1.input greg.diff/2.input
$(foreach s, $(STUDENTS), $(foreach i, $(wildcard $(EXPECTED)/*.input), \
	$(eval DIFF_TARGETS += $(s)/$(notdir $(i)).diff)))

.ONESHELL: # make cd work
.PHONY: all clean proj_dir
all: proj_dir $(CLONE_TARGETS) $(BUILD_TARGETS) $(RUN_TARGETS) $(DIFF_TARGETS)

proj_dir:
	@mkdir -p $(PROJ_DIR)

clean:
	rm -rf $(PROJ_DIR)
	rm -rf $(LOG)

# This target runs the clone out of github classroom using its URL format
$(CLONE_TARGETS):
	$(eval student = $(subst .clone,,$@))
	cd $(PROJ_DIR)
	echo "clone: "$(student) | tee -a $(LOG)

	if [ ! -d $(student) ]; then
		git clone --quiet https://github.com/$(ORG)/$(PROJECT)-$(student) $(student)
	fi

# This target makes each of the student projects
$(BUILD_TARGETS):
	$(eval student = $(subst .build,,$@))
	cd $(PROJ_DIR)/$(student)
	echo "build: "$(student) | tee -a $(LOG)

	if [ -f Makefile ]; then
		make 1>>$(LOG) 2>>$(LOG)
	else
		gcc -o $(EXECUTABLE) nt.c 1>>$(LOG) 2>>$(LOG) # assumption if no Makefile
	fi

# This target runs the student's executable once for each test case, generating a .actual file
$(RUN_TARGETS):
	$(eval norun = $(subst .run,,$@))
	$(eval student = $(subst /,,$(dir $(norun))))
	cd $(PROJ_DIR)/$(student)
	$(eval infile = $(notdir $(norun)))
	$(eval params = $(file < $(EXPECTED)/$(infile)))
	$(eval testnum = $(basename $(infile)))
	echo "run: "$(student)" with params: "$(params) | tee -a $(LOG)

	if [ -x $(EXECUTABLE) ]; then
		./$(EXECUTABLE) $(params) > ./$(testnum).actual
	else
		echo "no executable"
	fi

# This target runs diff on each .actual result to compare it with the .expected file in expected/$(PROJECT)
$(DIFF_TARGETS):
	$(eval nodiff = $(subst .diff,,$@))
	$(eval student = $(subst /,,$(dir $(nodiff))))
	cd $(PROJ_DIR)/$(student)
	$(eval testnum = $(basename $(notdir $(nodiff))))
	$(eval actual = $(testnum).actual)
	echo -n "diff: "$(student)" expected vs "$(actual)

	if [ -f $(actual) ]; then
		diff -s $(actual) $(EXPECTED)/$(testnum).expected >>$(LOG)
		if [ $$? -eq 0 ]; then
			echo ": pass!"
		else
			echo ": fail"
		fi
	else
		echo ": no actual"
	fi
