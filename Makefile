# maketest -- This Makefile can pull, build, and test projects from GitHub Classroom

# Allow USERS, PROJECT, and ORG to be specified on the command line, e.g.
# make USERS="ankitakhatri chelseaxkaye" PROJECT=project03
ifndef $(USERS)
	USERS=ankitakhatri chelseaxkaye chih98 dmoy2 dsamia25 gaokevin1 glatif1 kai-eiji mushi14 nljones4 phcarbajal pkmohabir1 rakesh-raju ravipat98 serenapang xli149
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

.ONESHELL: # make cd work

all: create_dir $(USERS)

# Build a directory hierarchy, e.g. output/cs315-20s/project03/phpeterson-usf
EXPECTED = $(PWD)/expected/$(PROJECT).expected
OUTDIR = "output"/$(ORG)/$(PROJECT)
create_dir:
	@mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)

# clone is a callable function which pulls the repo if it doesn't already exist
clone = \
	if [ ! -d $@ ]; then \
		git clone $(GIT_FLAGS) https://github.com/$(ORG)/$(PROJECT)-$(1) $(1); \
	fi

# build is a callable function which builds the project executable if it doesn't already exist
build = \
	cd $(1); \
	if [ -f Makefile ]; then \
		make >>$(LOG) 2>>$(LOG); \
	else \
		gcc -o nt nt.c >>$(LOG) 2>>$(LOG); \
	fi

# test is a callable function which runs the project executable and compares
# its output to the expected output
test = \
	if [ -x nt ]; then \
		./nt 0b1010 > $(PROJECT).actual; \
		diff -s $(PROJECT).actual $(EXPECTED) >>$(LOG); \
		if [ $$? -eq 0 ]; then \
			echo "Passed"; \
		else \
			echo "Failed"; \
		fi \
	else \
		echo "No Executable"; \
	fi 
	
# $(USERS) is using the list of students as a list of make targets
# so $@ is one student's name out of the list that make processes
# Cool feature: you can test one student, or they can test themselves, 
# e.g. make phpeterson
$(USERS):
	@cd $(OUTDIR)
	echo -n $@": " 
	echo "\nUSER:"$@ >> $(LOG)
	$(call clone,$@)
	$(call build,$@)
	$(call test,$@)
