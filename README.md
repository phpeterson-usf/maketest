# maketest
Automated testing for command-line projects in GitHub Classroom

## Usage 
1. `maketest` is a makefile-based approach to pulling, building, and testing actual output vs. expected
2. `tests/` contains a library of test cases by project
3. You'll probably want to use the `make` flags `-s` (silent) and `-k` (keep going past errors)
4. Clone `maketest` onto your machine and `cd` into it

### Students
1. If your project is in `/home/pi/project02` you can test it my saying (still from the `maketest` directory) 
`make -s -k DIR=/home/pi/project02-phpeterson` (replacing `phpeterson` with your GitHub ID)
2. That will build your project, run it with the given test cases, showing you pass/fail

### Teachers
1. `maketest` expects to find `make` variables for `ORG`, `PROJECT`, and `STUDENTS` as they are shown in GitHub Classroom. 
You can specify these on the command line (e.g. `make -s -k ORG=cs315-20s PROJECT=project02 STUDENTS="phil greg"`), or change the `Makefile` by hand
2. You can say `make -s -k MODE=teacher` and that will clone the students' repos, build them all, run them all with the
given test cases, and show you pass fail for each repo for each test case.
3. To clone the repos, you must be authenticated to GitHub as a teacher for the GitHub Classroom Organization

## Requirements
1. Student projects must be callable from the command line, and print their results to `stdout`
2. If written in C, your projects must take input via `argc` and `argv`, not via `stdin`. Could be enhanced to do this if needed.
3. You must use GNU make 4.2 or later. This is current on Raspberry Pi OS, but macOS installs make 3.6 by default. 
If you're running this on a Mac, you might need to `brew install make` but I haven't tested `maketest` on macOS

## Test Case Library
1. `tests/` contains a directory for each `$(PROJECT)`
2. Test cases are given by a `.input` file and a `.expected` file
3. Each test case has a prefix linking the input to the expected output. e.g. the output from `1.input` will be checked against `1.expected`. 
I think any prefix would work but you must use the same prefix on the input and expected files.
4. The `Makefile` feeds the contents of each of the `.input` files to each student's executable, and records the output 
in a `.actual` file in the student's directory. So `1.input` generates `1.actual` and `1.actual` is diff'd against `1.expected`
5. Fow now we're using `diff` so the output has to really match. Something more flexible would be a good enhancement.

## How does it work?
1. `maketests` is itself a `Makefile` and everything it does is a list of targets
2. The trick is to build lists of unique target names using the suffixes you can see. That part is a little gnarly,
but it  makes the recipes pretty simple
3. There are variables and recipes for cloning, building, running, and diffing
4. There is a log file in `./$(PROJECT).log` with all the gory details. Can be useful for finding bugs, either mine or the students!
5. There is a a `clean` target which removes everything in `./$(GITHUB)`, and the log files
