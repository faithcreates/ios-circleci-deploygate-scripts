#!/bin/bash

#
# deploygate.comにipaファイルをアップロードする
#

declare -r SCRIPT_NAME=${0##*/}

print_usage()
{
    cat << EOF
Usage: $SCRIPT_NAME -u USER_NAME -t TOKEN [-m MESSAGE] IPA_PATH
Upload ipa file to deploygate.com

  -u USER_NAME deploygate user name
  -t TOKEN     deploygate API token
  -h           display this help and exit
EOF
}

print_error()
{
    echo "$SCRIPT_NAME: $*" 1>&2
    echo "Try \`-h' option for more information." 1>&2
}

main()
{
    local user_name=''
    local api_token=''
    local file_path=''
    local message=''

    local option
    local OPTARG
    local OPTIND
    while getopts ':u:t:m:h' option; do
        case $option in
        u)
            user_name=$OPTARG
            ;;
        t)
            api_token=$OPTARG
            ;;
        m)
            message=$OPTARG
            ;;
        h)
            print_usage
            return 0
            ;;
        :)  #オプション引数欠如
            print_error "option requires an argument -- $OPTARG"
            return 1
            ;;
        *)  #不明なオプション
            print_error "invalid option -- $OPTARG"
            return 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    file_path=$1

    if [ -z "$user_name" ]; then
        print_error 'you must specify user name'
        return 1
    fi

    if [ -z "$api_token" ]; then
        print_error 'you must specify api token'
        return 1
    fi

    if [ -z "$file_path" ]; then
        print_error 'you must specify file path'
        return 1
    fi

    curl \
      -F file="@${file_path}" \
      -F "token=${api_token}" \
      -F message="${message}" \
      -F disable_notify=yes \
      "https://deploygate.com/api/users/${user_name}/apps"
}

main "$@"

