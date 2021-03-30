#!/bin/bash

# Write a script modify with the following syntax:
#
#   modify [-r] [-l|-u] <dir/file names...>
#   modify [-r] <sed pattern> <dir/file names...>
#   modify [-h]
#
#   modify_examples
#
# which will modify file names. The script is dedicated to lowerizing (-l)
# file names, uppercasing (-u) file names or internally calling sed
# command with the given sed pattern which will operate on file names.
# Changes may be done either with recursion (-r) or without it. Write a
# second script, named modify_examples, which will lead the tester of the
# modify script through the typical, uncommon and even incorrect scenarios
# of usage of the modify script.


help_prompt(){
    echo "
Usage: modify [OPTIONS] <dir/file names...>
       modify [-r|--recursive] [OPTIONS] <dir/file names...>

Options:
    -h, --help              Print usage
    -l, --lowerizing        Modifies lowerising letters in name
    -r, --recursive         Recursive mode for modify usage,
                            works on all subfolders of given directory,
                            works with all other commands
    -u, --uppercasing       Modifies uppercasing letters in name

        <sed pattern>       Uses sed command to modify the name of given directory,
                            Usage: modify sed [sed options] <dir/file names...>
"
}

handle_lowerizing(){
    local input=("$@")

    for filepath in ${input[@]}; do
        local dirpath=$(dirname "$filepath")
        local filename=$(basename "$filepath")
        local new_filename=$(echo "$filename" | tr A-Z a-z)
        overwrite $filepath $dirpath $new_filename
    done
}

handle_uppercasing(){
    local input=("$@")

    for filepath in ${input[@]}; do
        local dirpath=$(dirname "$filepath")
        local filename=$(basename "$filepath")
        local new_filename=$(echo "$filename" | tr a-z A-Z)
        overwrite $filepath $dirpath $new_filename
    done
}

handle_sed(){
    local input=("$@")
    echo "INPUT SED1 ${input[@]}"
    local pattern=${input[0]}
    local input=("${input[@]:1}")
    echo "INPUT SED2 ${input[@]}"

    for filepath in ${input[@]}; do
        local dirpath=$(dirname "$filepath")
        local filename=$(basename "$filepath")
        local new_filename=$(echo "$filename" | sed "$pattern")
        overwrite $filepath $dirpath $new_filename
    done
}

overwrite(){
    local filepath=$1
    local dirpath=$2
    local new_filename=$3
    local new_filepath="${dirpath}/${new_filename}"

    if [ -f "${filepath}" ]; then
        mv "$filepath" "$new_filepath"
    else
        echo "failed to modify, ${filepath} is not a correct filepath"
    fi
}

handle_recursive(){
    local input=("$@")
    echo "INPUT 1 ${input[@]}"
    handle_no_input ${input[0]}
    local action=${input[0]}
    local sed_pattern=""
    input=("${input[@]:1}")
    echo "INPUT 2 ${input[@]}"
    if [ "$action" = "sed" ]; then
        sed_pattern="${input[0]}"
        input=("${input[@]:1}")
    fi
    echo "INPUT 3 ${input[@]}"

    for directory in $input; do
        single_dir_recursive_execution $directory $action $sed_pattern
    done
    exit 0
}

single_dir_recursive_execution(){
    local dir_level=$1
    local action=$2
    local possible_sed_pattern=$3
    local directories_array=("$action")
    echo "DIR ARR ACTION ${directories_array[@]}"
    if [ -n "${possible_sed_pattern}" ]; then
        directories_array+=("$possible_sed_pattern")
    fi
    echo "DIR ARR ${directories_array[@]}"

    for element in "$dir_level"/*; do
        if [ -d "$element" ]; then
            single_dir_recursive_execution $element $action $possible_sed_pattern
        elif [ -f "$element" ]; then
            directories_array+=($element)
        else
            echo "there is no such directory nor file like ${element}"
            continue
        fi
    done
    choose_action ${directories_array[@]}
}

handle_exceptions(){
    handle_no_input $1
    handle_wrong_input $1
}

handle_no_input() {
    local input="$1"
    if [ -z $input ]; then
        echo "modify: no input"
        echo "See: modify --help"
        exit 1
    fi
}

handle_wrong_input(){
    local input="$1"
    if [ -n $input ]; then
        local input="$1"
        echo "modify: '$input' is not a modify option"
        exit 2
    fi
}

choose_action(){
    local input=("$@")
    local action=${input[0]}
    case $action in
        -r | --recursive) handle_recursive ${input[@]:1};;
        -h | --help) help_prompt;;
        -l | --lowerizing) handle_lowerizing ${input[@]:1};;
        -u | --uppercasing) handle_uppercasing ${input[@]:1};;
        sed) handle_sed ${input[@]:1};;
        *) handle_exceptions ${input[0]};;
    esac
}

args=("$@")
choose_action ${args[@]}
