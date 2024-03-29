#!/usr/bin/env bash

function semver_parse_into() {
    local RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
    # MAJOR
    eval $2="$(echo $1 | sed -e "s/${RE}/\1/")"
    # MINOR
    eval $3="$(echo $1 | sed -e "s/${RE}/\2/")"
    # MINOR
    eval $4="$(echo $1 | sed -e "s/${RE}/\3/")"
    # SPECIAL
    eval $5="$(echo $1 | sed -e "s/${RE}/\4/")"
}

function semver_eq() {
    local MAJOR_A=0
    local MINOR_A=0
    local PATCH_A=0
    local SPECIAL_A=0

    local MAJOR_B=0
    local MINOR_B=0
    local PATCH_B=0
    local SPECIAL_B=0

    semver_parse_into $1 MAJOR_A MINOR_A PATCH_A SPECIAL_A
    semver_parse_into $2 MAJOR_B MINOR_B PATCH_B SPECIAL_B

    if [ $MAJOR_A -ne $MAJOR_B ]; then return 1; fi
    if [ $MINOR_A -ne $MINOR_B ]; then return 1; fi
    if [ $PATCH_A -ne $PATCH_B ]; then return 1; fi
    if [[ "_$SPECIAL_A" != "_$SPECIAL_B" ]]; then return 1; fi

    return 0
}

# Is $1 < $2
function semver_lt() {
    local MAJOR_A=0
    local MINOR_A=0
    local PATCH_A=0
    local SPECIAL_A=0

    local MAJOR_B=0
    local MINOR_B=0
    local PATCH_B=0
    local SPECIAL_B=0

    semver_parse_into $1 MAJOR_A MINOR_A PATCH_A SPECIAL_A
    semver_parse_into $2 MAJOR_B MINOR_B PATCH_B SPECIAL_B

    if [ $MAJOR_A -lt $MAJOR_B ]; then return 0; fi
    if [[ $MAJOR_A -le $MAJOR_B  && $MINOR_A -lt $MINOR_B ]]; then return 0; fi
    if [[ $MAJOR_A -le $MAJOR_B  && $MINOR_A -le $MINOR_B && $PATCH_A -lt $PATCH_B ]]; then return 0; fi
    if [[ "_$SPECIAL_A"  == "_" ]] && [[ "_$SPECIAL_B"  == "_" ]] ; then return 1; fi
    if [[ "_$SPECIAL_A"  == "_" ]] && [[ "_$SPECIAL_B"  != "_" ]] ; then return 1; fi
    if [[ "_$SPECIAL_A"  != "_" ]] && [[ "_$SPECIAL_B"  == "_" ]] ; then return 0; fi
    if [[ "_$SPECIAL_A" < "_$SPECIAL_B" ]]; then return 0; fi

    return 1
}

function semver_gt() {
    semver_eq $1 $2
    local EQ=$?

    semver_lt $1 $2
    local LT=$?

    if [ $EQ -ne 0 ] && [ $LT -ne 0 ]; then
        return 0
    else
        return 1
    fi
}
