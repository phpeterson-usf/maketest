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

all: create_dir run_one_user

# Build a directory hierarchy, e.g. output/cs315-20s/project03/phpeterson-usf
EXPECTED = $(PWD)/expected/$(PROJECT).expected
OUTDIR = "output/"/$(ORG)/$(PROJECT)
create_dir:
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)

# Clone, build, run, test for each user in USERS
run_one_user:
	@cd $(OUTDIR)
	$(foreach USER, $(USERS),
		echo ""
		echo "*****" $(USER) "*****"

		# Pull the repo if it doesn't already exist
		if [ ! -d $(USER) ]; then
			echo -n "Cloning... "
			git clone $(GIT_FLAGS) https://github.com/$(ORG)/$(PROJECT)-$(USER) $(USER) 1>>$(LOG)
		fi
		@cd $(USER)
		
		# Run the Makefile if there is one
		echo -n "Building... "
		if [ -f Makefile ]; then
			make 1>>$(LOG)
		else
			gcc -o nt nt.c 1>>$(LOG)
		fi
		
		# Run the the executable if it was built
		if [ -f nt ]; then
			./nt 0b1010 > $(PROJECT).actual
		else
			echo "No executable"
		fi

		# Diff the executable's actual output with the expected output
		if [ -f $(PROJECT).actual ]; then
			diff -s $(PROJECT).actual $(EXPECTED) 1>>$(LOG)
			if [ $$? -eq 0 ]; then
				echo "Identical"
			else
				echo "NOT identical"
			fi
		else
			echo "No actual output"
		fi
		@cd ..
	)

