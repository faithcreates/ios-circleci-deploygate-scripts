#!/bin/bash

main()
{
    local keychain_password=circleci
    local certificates_dir=$1
    local p12_file_password=$2

    security create-keychain -p "$keychain_password" ios-build.keychain
    security import "${certificates_dir}/apple.cer" -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
    security import "${certificates_dir}/dist.cer" -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
    security import "${certificates_dir}/dist.p12" -k ~/Library/Keychains/ios-build.keychain -P "$p12_file_password" -T /usr/bin/codesign
    security list-keychain -s ~/Library/Keychains/ios-build.keychain
    security unlock-keychain -p "$keychain_password" ~/Library/Keychains/ios-build.keychain

    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp "${certificates_dir}"/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
}

main "./certificates" "$P12_FILE_PASSWORD"

