# maketest -- This Makefile can pull, build, and test projects from GitHub Classroom

# Allow STUDENTS, PROJECT, and ORG to be specified on the command line, e.g.
# make STUDENTS="ankitakhatri chelseaxkaye" PROJECT=project03
ifndef $(STUDENTS)
	STUDENTS=ankitakhatri chelseaxkaye chih98 dmoy2 dsamia25 gaokevin1 glatif1 kai-eiji mushi14 nljones4 phcarbajal pkmohabir1 rakesh-raju ravipat98 serenapang xli149
endif

ifndef $(PROJECT)
	PROJECT=project02
endif

ifndef $(ORG)
	ORG=cs315-20s
endif

ifndef $(LOG)
	LOG=/dev/null
	GIT_FLAGS=--quiet
endif

# Set up these make targets for the clone, build, and test phase
# My approach relies on these kludgey names to generate unique targets
$(foreach s, $(STUDENTS), $(eval CLONE_TARGETS += $(s).clone))
$(foreach s, $(STUDENTS), $(eval BUILD_TARGETS += $(s).build))
$(foreach s, $(STUDENTS), $(eval TEST_TARGETS += $(s).test))

.ONESHELL: # make cd work
.PHONY: all clean proj_dir
all: proj_dir $(CLONE_TARGETS) $(BUILD_TARGETS) $(TEST_TARGETS)

# Build a directory hierarchy, e.g. output/cs315-20s/project03/phpeterson-usf
EXPECTED = $(PWD)/expected/$(PROJECT).expected
PROJ_DIR = output/$(ORG)/$(PROJECT)
proj_dir:
	@mkdir -p $(PROJ_DIR)

clean:
	rm -rf $(PROJ_DIR)

# This target runs the clone out of github classroom using its URL format
$(CLONE_TARGETS):
	$(eval student=$(subst .clone,,$@))
	cd $(PROJ_DIR)
	if [ ! -d $(student) ]; then
		git clone $(GIT_FLAGS) https://github.com/$(ORG)/$(PROJECT)-$(student) $(student)
	fi

# This target makes each of the student projects
$(BUILD_TARGETS):
	$(eval student=$(subst .build,,$@))
	cd $(PROJ_DIR)/$(student)
	if [ -f Makefile ]; then
		make
	else
		gcc -o nt nt.c
	fi

# This target tests each of the student projects, comparing actual output to expected
$(TEST_TARGETS):
	$(eval student=$(subst .test,,$@))
	cd $(PROJ_DIR)/$(student)
	echo -n $(student)": "
	if [ -x nt ]; then
		./nt 0b1010 >$(PROJECT).actual
		if [ -f $(PROJECT).actual ]; then
			diff -s $(PROJECT).actual $(EXPECTED) >>$(LOG)
			if [ $$? -eq 0 ]; then
				echo "pass!"
			else
				echo "fail"
			fi
		else
			echo "no output"
		fi
	else
		echo "no executable"
	fi
	
