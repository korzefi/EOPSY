#!/bin/bash

ensure_launch_modify_folder(){
    if ! [ -f "modify.sh" ]; then
        echo "Please launch it from folder when the modify.sh is"
        exit 1
    fi
}

check_if_exist(){
    local test_name=$1
    local name=$2
    if [ -e $name ]; then
        echo "${test_name} PASSED: file/dir ${name} exists"
    else
        echo "${test_name} FAILED: file/dir ${name} does not exist"
    fi
}

test_not_existing(){
    # given
    touch not_existing_file
    rm not_existing_file

    # when
    $(bash modify.sh -l "not_existing_file" 2>&1 >/dev/null)
    $(bash modify.sh -u "not_existing_file" 2>&1 >/dev/null)
    $(bash modify.sh -r -l "not_existing_file" 2>&1 >/dev/null)
    $(bash modify.sh -r -u "not_existing_file" 2>&1 >/dev/null)

    # then
    if [ -e "not_existing_file" ]; then
        echo "test_not_existing FAILED"
    elif [ -e "NOT_EXISTING_FILE" ]; then
        echo "test_not_existing FAILED"
    else
        echo "test_not_existing PASSED"
    fi
}

test_no_argument(){
    # given
    local expected_prompt="modify: no input
See: modify --help"

    # when
    local current=$(bash modify.sh 2>&1)

    # then
    if [ "$current" = "$expected_prompt" ]; then
        echo "test_no_argument  PASSED"
    else
        echo "test_no_argument  FAILED"
    fi
}

test_uppercasing(){
    # given
    touch test1
    touch Test2.c
    touch TEST3
    mkdir test_dir
    touch test_dir/test4

    # when
    $(bash modify.sh -u test1 Test2.c TEST3 test_dir/test4 2>&1 >/dev/null)

    #then
    check_if_exist "test_uppercasing1" "TEST1"
    check_if_exist "test_uppercasing2" "TEST2.C"
    check_if_exist "test_uppercasing3" "TEST3"
    check_if_exist "test_uppercasing4" "test_dir/TEST4"

    # cleanup
    rm TEST1
    rm TEST2.C
    rm TEST3
    rm -r test_dir
}

test_lowercasing(){
    # given
    touch TEST1
    touch Test2.c
    touch test3
    mkdir test_dir
    touch test_dir/TEST4

    # when
    $(bash modify.sh -l TEST1 Test2.c test3 test_dir/TEST4 2>&1 >/dev/null)

    #then
    check_if_exist "test_lowercasing1" "test1"
    check_if_exist "test_lowercasing2" "test2.c"
    check_if_exist "test_lowercasing3" "test3"
    check_if_exist "test_lowercasing4" "test_dir/test4"

    # cleanup
    rm test1
    rm test2.c
    rm test3
    rm -r test_dir
}

test_sed(){
    # given
    touch test_sed_failed
    touch test_sed_diff
    touch test_failed
    local sed_pattern="s/failed/passed/g"

    # when
    $(bash modify.sh sed "${sed_pattern}" "test_sed_failed" "test_sed_diff" "test_failed" 2>&1 >/dev/null)

    #then
    check_if_exist "test_sed" "test_sed_passed"
    check_if_exist "test_sed" "test_sed_diff"
    check_if_exist "test_sed" "test_passed"

    # cleanup
    rm test_sed_passed
    rm test_sed_diff
    rm test_passed
}

test_recursive_lowerising(){
    # given
    mkdir test1_dir
    touch test1_dir/TEST1
    touch test1_dir/Test2.c
    touch test1_dir/test3
    mkdir test1_dir/test_dir
    touch test1_dir/test_dir/TEST4
    mkdir test1_dir/test_dir/test2_dir
    touch test1_dir/test_dir/test2_dir/TEST5

    # when
    $(bash modify.sh -r -l test1_dir 2>&1 >/dev/null)

    #then
    check_if_exist "test_recursive_lowerising1" "test1_dir/test1"
    check_if_exist "test_recursive_lowerising2" "test1_dir/test2.c"
    check_if_exist "test_recursive_lowerising3" "test1_dir/test3"
    check_if_exist "test_recursive_lowerising4" "test1_dir/test_dir/test4"
    check_if_exist "test_recursive_lowerising4" "test1_dir/test_dir/test2_dir/test5"

    # cleanup
    sleep 0.5 && rm -r test1_dir
}

test_recursive_uppercasing(){
    # given
    mkdir test1_dir
    touch test1_dir/test1
    touch test1_dir/Test2.c
    touch test1_dir/TEST3
    mkdir test1_dir/test_dir
    touch test1_dir/test_dir/test4
    mkdir test1_dir/test_dir/test2_dir
    touch test1_dir/test_dir/test2_dir/test5

    # when
    $(bash modify.sh -r -u test1_dir 2>&1 >/dev/null)

    #then
    check_if_exist "test_recursive_uppercasing1" "test1_dir/TEST1"
    check_if_exist "test_recursive_uppercasing2" "test1_dir/TEST2.C"
    check_if_exist "test_recursive_uppercasing3" "test1_dir/TEST3"
    check_if_exist "test_recursive_uppercasing4" "test1_dir/test_dir/TEST4"
    check_if_exist "test_recursive_uppercasing5" "test1_dir/test_dir/test2_dir/TEST5"

    # cleanup
    sleep 0.5 && rm -r test1_dir
}

test_recursive_sed(){
    # given
    mkdir test1_dir
    touch test1_dir/test_failed
    touch test1_dir/Test2.c
    touch test1_dir/TEST3
    mkdir test1_dir/test_dir
    touch test1_dir/test_dir/test_sed_failed
    mkdir test1_dir/test_dir/test2_dir
    touch test1_dir/test_dir/test2_dir/test_passed
    local sed_pattern="s/failed/passed/g"

    # when
    $(bash modify.sh -r sed "${sed_pattern}" test1_dir 2>&1 >/dev/null)

    #then
    check_if_exist "test_recursive_sed" "test1_dir/test_passed"
    check_if_exist "test_recursive_sed" "test1_dir/Test2.c"
    check_if_exist "test_recursive_sed" "test1_dir/TEST3"
    check_if_exist "test_recursive_sed" "test1_dir/test_dir/test_sed_passed"
    check_if_exist "test_recursive_sed" "test1_dir/test_dir/test2_dir/test_passed"

    # cleanup
    sleep 0.5 && rm -r test1_dir
}

ensure_launch_modify_folder
test_not_existing
test_no_argument
test_uppercasing
test_lowercasing
test_sed
test_recursive_lowerising
test_recursive_uppercasing
test_recursive_sed
