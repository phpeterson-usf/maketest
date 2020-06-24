# maketest
1. Automated testing for command-line projects in GitHub Classroom
2. `maketest` can clone repos, build them, run with predetermined input and output, 
and score the results vs. your rubric
3. To get started, clone `maketest` onto your machine and `cd` into it

## Requirements
1. Student projects must be callable from the command line, and print their results to `stdout`
2. Student executables must have the same name as the `PROJECT` (see below)
2. If written in C, your projects must take input via `argc` and `argv`, not via `stdin`. 
Could be enhanced to do this if needed.
3. You must use GNU make 4.2 or later. This is current on Raspberry Pi OS, but macOS installs 
make 3.6 by default. If you're running this on macOS, you might need to `brew install make` 
but I haven't tested `maketest` on macOS

## Usage 
1. You'll want to use the `make` flags `-s` (silent) and `-k` (keep going past errors)
2. There is a a `clean` target which removes the `.actual`, `.score`, and `.log` files. You'll
want to use the `clean` target between test runs to get the correct score.

### Usage for Students
1. If your project is in `/home/pi/project02-phpeterson` you can test it by saying (from the 
`maketest` directory) 
`make -s -k PROJECT=project02 DIR=/home/pi/project02-phpeterson` (replacing `phpeterson` with 
your GitHub ID)
2. That will build your project, run it with the given test cases, showing you pass/fail, 
and score vs. rubric

### Usage for Teachers
1. `maketest` expects to find `make` variables for `ORG`, `PROJECT`, and `STUDENTS` as they are 
shown in GitHub Classroom. You can specify these on the command line 
(e.g. `make clone -s -k ORG=cs315-20s PROJECT=project02 STUDENTS="phil greg"`), or change 
the `Makefile` by hand
2. For the `clone` target, `maketest` will clone all of the student repos before building, 
running, and testing them
3. To clone the repos, you must be authenticated to GitHub as a teacher for the GitHub Classroom 
Organization
4. The first/default `make` target is `test` so `make -s -k PROJECT=project02` is equivalent to 
`make test -s -k PROJECT=project02`

## Testing and Scoring

### Test Case Library
1. `tests/` contains a directory for each `PROJECT`
2. Test cases are given by a `.input` file and a `.expected` file
3. Each test case has a prefix linking the input to the expected output. For example, the output 
from `1.input` will be checked against `1.expected`. You must use the same prefix on the input 
and expected files.
4. The `Makefile` feeds the contents of each of the `.input` files to each student's executable, 
and records the output in a `.actual` file in the student's directory. So `1.input` generates 
`1.actual` and `1.actual` is diff'd against `1.expected`
5. Fow now we're using `diff` so the output has to really match. 
Something more flexible would be a good enhancement.

### Score vs. Rubric
1. `tests/$(PROJECT)` can contain a `.rubric` file for each test case
2. If a student's project passes a test case (i.e. `1.actual` matches `1.expected`) then the 
contents of `1.rubric` are accumulated into `$(PROJECT).score` in each student's directory, 
and the sum of the scores is reported in `maketest` output

## How does it work?
1. `maketest` is itself a `Makefile` and everything it does is a list of targets
2. The trick is to build lists of unique target names using the suffixes you can see. 
That part is a little gnarly, but it  makes the recipes pretty simple
3. There are variables and recipes for cloning, building, running, and diffing
4. There is a log file in `./$(PROJECT).log` with all the gory details. Can be useful for 
finding bugs, either mine or the students!
