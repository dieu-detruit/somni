# Somnio

翌朝の「疲れが取れた」を少しずつ増やすための、iPhone睡眠音声とApple Watchの朝の記録。

iPhoneで環境音・モノラルビートを再生し、翌朝に休息感、寝つき、Apple Watchが記録した睡眠を振り返ります。音声の研究には肯定的な結果と否定的な結果があります。自分の記録から合う設定を探すための初版です。

- SwiftUI / iOS 17以上 / watchOS 10以上
- Bundle ID: `com.takafumi.somni` / `com.takafumi.somni.watchkit`
- Apple Team ID: `XLVLA9AY6A`
- 端末内保存。アカウント、広告、サーバーへの健康データ送信なし。
- Watchの標準睡眠記録をHealthKitで取得。夜間の独自リアルタイム睡眠判定は行いません。

## 開発

MacでXcodeとXcodeGenを用意します。

```sh
brew install xcodegen
swift test
xcodegen generate
open Somnio.xcodeproj
```

`Somnio`スキームでiPhoneへインストール。署名チームを選び、Watchへのコンパニオンインストールを有効にしてください。睡眠記録の読み取りはアプリから要求します。Watch側ではAppleの睡眠記録を有効にして装着してください。

```sh
bash scripts/check.sh
```

共有ロジックのテストと署名なしのiPhone + Watchアーカイブを検証します。実機の音声ルート、通話割り込み、HealthKitデータ同期、Watchのオフライン入力は実機検証が必要です。

## TestFlight配信

watch-climberと同じく、**GitHub ActionsのmacOSランナー + codemagic-cli-tools**を使います。Codemagic Webサービスへの登録は不要です。

署名用Secretsが既にある `dieu-detruit/brain-dump` の `ci/somnio-testflight` ブランチで、Somnio専用ワークフローを実行します。ソースはこの公開リポジトリの固定コミットからcheckoutし、既存のApp Store Connect APIキーと証明書を再利用します。iPhoneのHealthKit capabilityと両ターゲットのProvisioning Profileを取得してアーカイブし、TestFlightへアップロード、Appleの処理完了を照会します。ユーザー設定済みの内部テスター自動配信を利用します。

- 配信ワークフローの控え: `ci/somnio-testflight.yml`
- [実際の配信ワークフロー](https://github.com/dieu-detruit/brain-dump/blob/ci/somnio-testflight/.github/workflows/somnio-testflight.yml)
- ビルド番号: GitHub run number + run attempt
- 更新時はコードの検証後、配信ワークフローのcheckout refを新しいコミットSHAへ更新します。
- 秘密値は既存リポジトリ内だけで使用し、このリポジトリへコピーしません。

このリポジトリのGitHub Actionsは署名なし検証用です。`codemagic.yaml`は将来Codemagic Webサービスを使う場合の代替設定として保持していますが、現在の配信経路では使いません。

## 少しずつ改善する使い方

最初は小さな音で好みの設定を数晩使い、朝に休息感を記録します。寝る時刻や睡眠時間が大きく違う夜は単純比較せず、設定は一度にひとつずつ変えると振り返りやすくなります。Watchの深睡眠時間だけを最大化せず、本人の翌朝の感覚を中心に考えます。

## 調査と設計

- [初版設計](docs/superpowers/specs/2026-11-03-somni-design.md)
- [実装計画](docs/superpowers/plans/2026-11-03-somnio.md)
