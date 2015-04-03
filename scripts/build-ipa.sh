#!/bin/bash

#
# ビルドしてipaファイルを作成する
#

declare -r SCRIPT_NAME=${0##*/}

print_usage()
{
    cat << EOF
Usage:
1st form:
  $SCRIPT_NAME [-o OUTPUT_PATH] [-c CONFIGURATION] [-m PROVISIONING_FILE_DIR] -d DEVELOPER_NAME -a APPNAME -p PROVISIONING_FILE -s XCODE_SCHEME -w XCODE_WORKSPACE

2nd form:
  $SCRIPT_NAME [-o OUTPUT_PATH] [-c CONFIGURATION] [-m PROVISIONING_FILE_DIR] -d DEVELOPER_NAME -a APPNAME -p PROVISIONING_FILE -t XCODE_TARGET

Build iOS project and create ipa file. Use 1st form to build iOS project with CocoaPods. Use 2nd form to build iOS project without CocoaPods.

  -o OUTPUT_PATH        Output path (default: \$PWD/build)
  -c CONFIGURATION      Build configuration (default: Release)
  -d DEVELOPER_NAME     Identity in Keychanin
  -a APPNAME            iOS application name
  -p PROVISIONING_FILE  mobileprovision file name
  -m PROVISIONING_FILE_DIR mobileprovision file directory (default: \$HOME/Library/MobileDevice/Provisioning Profiles)
  -s XCODE_SCHEME       Xcode scheme(build target name)
  -w XCODE_WORKSPACE    Xcode workspace name
  -t XCODE_TARGET       Xcode target
  -h                    display this help and exit

Examples
  $SCRIPT_NAME -o \$PWD/build -d "iPhone Distribution: FaithCreates Inc." -a CircleCI-Sample -p 6d7927d4-5e5d-4d32-b4bc-111111111111.mobileprovision -s CircleCI-Sample -w CircleCI-Sample.xcworkspace

  $SCRIPT_NAME -o \$PWD/build -d "iPhone Distribution: FaithCreates Inc." -a CircleCI-Sample -p 6d7927d4-5e5d-4d32-b4bc-111111111111.mobileprovision -t CircleCI-Sample
EOF
}

print_error()
{
    echo "$SCRIPT_NAME: $*" 1>&2
    echo "Try \`-h' option for more information." 1>&2
}

main()
{
    local output_path="$PWD/build"
    local developer_name=''
    local appname=''
    local provisioning_file=''
    local provisioning_file_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
    local xcode_scheme=''
    local xcode_workspace=''
    local xcode_target=''
    local configuration='Release'

    local option
    local OPTARG
    local OPTIND
    while getopts ':o:c:d:a:p:m:s:w:t:h' option; do
        case $option in
        o)
            output_path=$OPTARG
            ;;
        c)
            configuration=$OPTARG
            ;;
        d)
            developer_name=$OPTARG
            ;;
        a)
            appname=$OPTARG
            ;;
        p)
            provisioning_file=$OPTARG
            ;;
        m)
            provisioning_file_dir=$OPTARG
            ;;
        s)
            xcode_scheme=$OPTARG
            ;;
        w)
            xcode_workspace=$OPTARG
            ;;
        t)
            xcode_target=$OPTARG
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

    if [ -z "$output_path" ]; then
        print_error 'you must specify output_path'
        return 1
    fi

    if [ -z "$configuration" ]; then
        print_error 'you must specify configuration'
        return 1
    fi

    if [ -z "$developer_name" ]; then
        print_error 'you must specify developer_name'
        return 1
    fi

    if [ -z "$appname" ]; then
        print_error 'you must specify appname'
        return 1
    fi

    if [ -z "$provisioning_file" ]; then
        print_error 'you must specify provisioning_file'
        return 1
    fi

    if [ -z "$provisioning_file_dir" ]; then
        print_error 'you must specify provisioning_file_dir'
        return 1
    fi

    # 1st formの場合、xcode_schemeは空でない、xcode_workspaceは空でない、xcode_targetは空
    # 2nd formの場合、xcode_schemeは空、xcode_workspaceは空、xcode_targetは空でない
    if [ -n "$xcode_target" ]; then
      # 2nd formの場合
      # if [ -n "$xcode_target" ]; then
      if [ -n "$xcode_scheme" ]; then
          print_error "you don't need to specify both xcode_target and xcode_scheme"
          return 1
      fi

      if [ -n "$xcode_workspace" ]; then
          print_error "you don't need to specify both xcode_target xcode_workspace"
          return 1
      fi
    else
      # 1st formの場合
      if [ -z "$xcode_scheme" ]; then
          print_error 'you must specify xcode_scheme or xcode_target'
          return 1
      fi

      if [ -z "$xcode_workspace" ]; then
          print_error 'you must specify xcode_workspace or xcode_target'
          return 1
      fi
    fi

    # 末尾の/を取り除きます
    # ただし、"/"である場合はそのままとします
    if [ "$provisioning_file_dir" != "/" ]; then
        provisioning_file_dir="${provisioning_file_dir%/}"
    fi

    local provisioning_profile_path="${provisioning_file_dir}/$provisioning_file"

    # Archive
    if [ -n "$xcode_target" ]; then
      # workspace指定なしの場合
      xcodebuild \
        -target "$xcode_target" \
        -configuration "$configuration" \
        clean build \
        CODE_SIGN_IDENTITY="$developer_name" \
        CONFIGURATION_BUILD_DIR="$output_path"
    else
      # workspace指定ありの場合
      xcodebuild \
        -scheme "$xcode_scheme" \
        -workspace "$xcode_workspace" \
        -configuration "$configuration" \
        clean build \
        CODE_SIGN_IDENTITY="$developer_name" \
        CONFIGURATION_BUILD_DIR="$output_path"
    fi

    if [ "$?" -ne 0 ]; then
        print_error 'fail to archive'
        return 1
    fi

    # Signing
    xcrun -log -sdk iphoneos PackageApplication \
      "${output_path}/${appname}.app" \
      -o "${output_path}/${appname}.ipa" \
      -sign "$developer_name" \
      -embed "$provisioning_profile_path"

    # 作成したipaファイルのパス = ${output_path}/${appname}.ipa
}

main "$@"

