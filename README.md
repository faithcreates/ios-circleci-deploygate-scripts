# ios-circleci-deploygate-scripts
## これは何?
iOSアプリケーションを[CircleCI](https://circleci.com/)でビルドして[DeployGate](https://deploygate.com/)でアドホックビルドを配布するための手順、設定ファイル、シェルスクリプトをまとめています。

## ファイル一覧

|ファイル|内容|
|:-------|:---|
|certificates|ipaファイルを作成するために必要になる証明書、プロビジョニングファイルの見本|
|circle_sample_xcodeproj.yml|CocoaPodsを使用しない場合のcircle.ymlの見本|
|circle_sample_xcworkspace.yml|CocoaPodsを使用する場合のcircle.ymlの見本|
|scripts|ビルドするためのシェルスクリプト|

## 手順

1. CircleCIの設定
2. 証明書、プロビジョニングファイル作成
3. circle.yml作成
4. 環境変数の設定
5. deploy.shの修正

## 1. CircleCIの設定
CircleCIにログインして、Project Setting -&gt; Experimental Settings の Build iOS projectをONにします。

## 2. 証明書、プロビジョニングファイル作成
以下のプロビジョニングファイルを作成します。

- &lt;PROFILE_UUID&gt;.mobileprovision


Appleの「Certificates, Identifiers &amp; Profiles」サイトからアドホックビルド用のプロビジョニングファイルをダウンロードします。
ファイル名は「&lt;PROFILE_UUID&gt;.mobileprovision」という形式とします。PROFILE_UUIDは、mobileprovisionファイルを開いて以下の箇所を確認します。

```
<key>UUID</key>
<string>xxxxxxxxxx-11111-0000-xxxx-111111111</string>
```

以下の証明書を作成します。

- apple.cer
- dist.cer
- dist.p12

### apple.cer
キーチェーンで"Apple Worldwide Developer Relations Certification Authority"という項目を選び、書き出します。出力するフォーマットとしては「証明書 (.cer)」を選びます。

### dist.cer
使用するプロビジョニングファイルに対応している証明書をキーチェーンで選び、書き出します。出力するフォーマットとしては「証明書 (.cer)」を選びます。

### dist.p12
使用するプロビジョニングファイルに対応している証明書をキーチェーンで選び、書き出します。出力するフォーマットとしては「個人情報交換 (.p12)」を選びます。書き出しのときにパスワードを設定します。このパスワードは後で使用するので覚えておきます。

作成した証明書、プロビジョニングファイルはcertificatesディレクトリ以下に配置します。

## 3. circle.yml作成
circle.ymlを作成します。CocoaPodsを使用しない(.xcodeprojを使用する)場合はcircle_sample_xcodeproj.yml、CocoaPodsを使用する(.xcworkspaceを使用する)場合はcircle_sample_xcworkspace.ymlを元にして作成します。

「machine: environment:」の箇所は以下の表を参考に値を設定します。

|変数名|内容|設定例|
|:-----|:---|:-----|
|XCODE_WORKSPACE|Xcodeのworkspace名|CircleCI-Sample.xcworkspace|
|XCODE_SCHEME|Xcodeのビルド対象スキーム名|CircleCI-Sample|
|XCODE_PROJECT|Xcodeのプロジェクト名|CircleCI-Sample.xcodeproj|
|XCODE_TARGET|Xcodeのビルドターゲット名|CircleCI-Sample|
|APPNAME|アプリケーション名|CircleCI-Sample|
|DEPLOYGATE_USER_NAME|deploygateユーザ名|XXX|
|DEVELOPER_NAME|キーチェーンの証明書の「通称」|"iPhone Distribution: XXX (CTQDM00000)"|
|PROFILE_NAME|プロビジョニングファイル名|"650f2f4c-f93d-40c2-b91a-1111111111.mobileprovision"|

## 4. 環境変数の設定
CircleCIのWeb画面で、以下のふたつの環境変数を設定します。

- DEPLOYGATE_API_TOKEN
- P12_FILE_PASSWORD

DEPLOYGATE_API_TOKENは、deploygateのAPI keyです。[https://deploygate.com/settings](https://deploygate.com/settings)から確認できます。

P12_FILE_PASSWORDは、p12ファイルを書き出したときに指定したパスワードです。

## 5. deploy.shの修正

CocoaPodsを使うかどうかによってビルド方法が変わるので、scripts/deploy.shを修正します。

### CocoaPodsを使う場合の例

```
./scripts/build-ipa.sh \
    -d "$DEVELOPER_NAME" -a "$APPNAME" \
    -p "$PROFILE_NAME" \
    -s "$XCODE_SCHEME" \
    -w "$XCODE_WORKSPACE" \
    -c "$config" \
    -o "$output_path"
```

### CocoaPodsを使わない場合の例

```
./scripts/build-ipa.sh \
    -d "$DEVELOPER_NAME" -a "$APPNAME" \
    -p "$PROFILE_NAME" \
    -t "$XCODE_TARGET" \
    -c "$config" \
    -o "$output_path"
```

## その他
このビルドスクリプトでは、XcodeのConfigurationごとにAdhocビルドを作成するようになっています。ConfigurationごとにアプリのBundleIDを変更して、一度に複数のAdhocビルドを作成することを想定しています。

標準ではConfigurationとしてReleaseを指定してビルドします。それを変更するには、scripts/deploy.shの以下の箇所を変更します。

```
configuration_list=("Release")
```

ここにビルドしたいConfigurationを書きます。例えば「Release」「Adhoc」というふたつのConfigurationでビルドするときは次のように設定します。

```
configuration_list=("Release" "Adhoc")
```

この設定の場合、ReleaseとAdhocでそれぞれAdhocビルドを作成してdeploygateにデプロイします。

## 参考
- [Test iOS applications - CircleCI](https://circleci.com/docs/ios)
- [DeployGate API](https://deploygate.com/docs/api)
- [infolens/CircleCI-iOS-TestFlight-Sample](https://github.com/infolens/CircleCI-iOS-TestFlight-Sample)

