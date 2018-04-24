#!/usr/bin/env sh
#
# sht
# A posix-friendly tee hack emulating process substitution.
# Passes input from stdin to each command given as an argn.
# usage: sht [command] ...

# Initialize variables and create required files
init() {
    # Save current options and set 'errexit'
    local -
    set -e

    # Clear the variables we're going to use
    unset -v workdir 
    unset -v id_template
    unset -v argn

    # Set a trap to remove our files on exit
    trap 'rm -rf "$workdir"' EXIT

    # The directory that will hold our files
    workdir="$(mktemp -d -t "$$-XXXXXXXX")"

    # File ID format for hassle-free sorting
    id_template="%0${##}d"

    # argn counter to iterate over arguments
    argn=0

    # An extra pipe to avoid further subshells
    mkfifo "$workdir/#"
}

# Setup
init

# Start commands in the background, each with a dedicated pipe
while test "$argn" -lt $#; do

    # Generate an id for files pertaining to the current argument
    printf "$id_template\n" $((argn+1)) \
        & read -r argn

    # Start command in a subshell with dedicated pipe on stdin
    mkfifo "$workdir/-$argn" && {
        sh -c "${!argn}" < "$workdir/-$argn" > "$workdir/@$argn" \
            & continue
    }
done 3<> "$workdir/#" <&3 >&3

# tee stdin to our pipes and wait for our jobs to finish
tee "$workdir"/-* >/dev/null
wait

# Print the output
cat "$workdir"/@*

# Done.
exit
