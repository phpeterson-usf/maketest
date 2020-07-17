# maketest
1. Automated testing for command-line projects in GitHub Classroom
1. `maketest` can clone repos, build them, run with predetermined input and output, 
and score the results vs. your rubric
1. To get started, clone `maketest` onto your machine and `cd` into it

## Requirements
1. Student projects must be callable from the command line, and print their results to `stdout`
1. Student projects must have a `Makefile` to build them
1. The `Makefile` must generate an executable with the same name as the `PROJECT` (see below)
1. If written in C, your projects must take input via `argc` and `argv`, not via `stdin`
1. You must use GNU `make 4.2` or later. This is current on Raspberry Pi OS, but macOS installs 
`make` 3.6 by default. If you're running this on macOS, you might need to `brew install make` 
but I haven't tested `maketest` on macOS

## Usage 

1. Remember to run the `maketest` commands from the `maketest/` directory
1. You may want to use the `make` flags `-s` (silent) and `-k` (keep going past errors). You can
combine the flags, e.g. `make -ks`
1. `maketest` expects to find `make` variables for `ORG` and `PROJECT` as they are 
shown in GitHub Classroom. In this README I use examples from the Spring 2020 class but you should
substitute the `ORG` and `PROJECT` values for your class. You can specify these variables in one
of three places, based on your preference
    1. On the command line
        <pre><code>make test -ks ORG=cs315-20s PROJECT=project02</code></pre>
    1. In the `Makefile` by editing the variables manually
        <pre><code>make test -ks</code></pre>
    1. In your shell environment. You can use the `-e` flag to tell `make` to get its variables
    from the environment
        <pre><code> export ORG=cs315-20s PROJECT=project02 STUDENTS="phpeterson-usf gdbenson"
        make test -eks</code></pre>

### Usage for Students
1. In addition to the `ORG` and `PROJECT` variables, students must define a `DIR` variable
which contains the local filesystem path to your project
1. To test your pre-existing repo (without cloning)
    <pre><code>make -ks PROJECT=project04 DIR=../project04-phpeterson-usf</code></pre>
1. You should see output which looks like this
    <pre><code> build: ../project04-phpeterson-usf/
      run: ../project04-phpeterson-usf/ PASS for: -f quadratic -a 2,4,8,16
      run: ../project04-phpeterson-usf/ PASS for: -f fib_iter -a 20
      run: ../project04-phpeterson-usf/ FAIL for: -f find_max -a 2,-4,28,16
    score: ../project04-phpeterson-usf/ 10</code></pre>
1. To test the project with a new/clean repo (as the instructor will), you can run the `clone` 
and `test` targets
    <pre><code>make -ks clone test PROJECT=project04 ORG=cs315-20s STUDENTS=phpeterson-usf</code></pre>

### Usage for Instructors
1. In addition to the `ORG` and `PROJECT` variables, instructors must define `STUDENTS` which 
contains a list of students' GitHub IDs. You may wish to do that in the `Makefile` or your 
environment, since the long list is static throughout the school term.
1. To clone all the student repos, use the `clone` target (assuming your are logged in to 
GitHub Classroom as a teacher for the Organization)
    <pre><code>make -ks clone ORG=cs315-20s PROJECT=project02 STUDENTS="phpeterson-usf gdbenson"</code></pre> 
1. To build, run, test, and score the repos, use the `test` target (pro tip: `test` is
    the default target so you can omit `test` if you like)
    <pre><code>make -ks test ORG=cs315-20s PROJECT=project02 STUDENTS="phpeterson-usf gdbenson"</code></pre>
1. To pull new changes since you cloned the repos, use the `pull` target
    <pre><code>make -ks pull ORG=cs315-20s PROJECT=project02 STUDENTS="phpeterson-usf gdbenson"</code></pre>

## Testing and Scoring

### For Students
1. When you run `make test -eks DIR=../project02` (for example), `maketest` will
run the test cases for your `project02` solution. 
1. This will generate a `.actual` file and a `.score` file in your directory 
for each test case. Your output must match the expected output case-insensitively.
1. The overall project rubric contains some portion for automated testing. The
automated testing portion of the rubric is the sum of the scores for the test
cases specified by the instructor.
1. Since a clean repo does not contain build artifacts (like your `.o` files), 
you should not commit `.actual` or `.score` files to your repo. You may wish to 
remove them before committing using `rm *.actual *.score` 

### For Instructors
1. In `maketest/tests/` you should create a directory for each `PROJECT`
1. In each `PROJECT` directory, you should create test cases. A test case is
defined by three text files. For test case `foo`, you should create:
    1. `foo.input` containing the command line arguments (not including the 
    executable name) you wish to test. The format of the arguments is yours to 
    decide, but students must parse the format you specify. I'm using `getopt` 
    style arguments
        <pre><code>-f quadratic -a 1,2,3,4</code></pre> 
    1. `foo.expected` containing the output (to `stdout` you expect for `foo.input`
    1. `foo.rubric` containing the number of points earned when the student's
    `foo.actual` output matches (via `diff -i`) your `foo.expected`

## How does it work?
1. `maketest` is itself a `Makefile` and everything it does is a list of targets
1. The approach is to build lists of unique target names using a unique suffix for
each phase (clone, pull, clean, build, run, score)
1. There is a target for each test case for each phase for each student, so the target lists
are pretty long
1. However, since `make` loops over the target lists automatically, the recipes for each phase
can be relatively simple
1. There is a log file in `./$(PROJECT).log` with all the gory details. Can be useful for 
finding bugs, either mine or the students!
