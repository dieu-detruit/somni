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

## CodemagicとTestFlight

既存watch-climberと同じApp Store Connect連携名`brain-dump`を参照します。

1. Codemagicにこの公開リポジトリを追加し、ルートの`codemagic.yaml`を選択。
2. チームのApp Store Connect連携`brain-dump`が利用可能であることを確認。
3. Code signing identitiesで上記2つのBundle IDのApp Store用Provisioning Profileを取得。iPhone側はHealthKit capabilityを有効にしたプロファイルが必要です。
4. App Store ConnectでSomnioのBundle IDとInternalテスターグループを確認。
5. 最初に`somnio-check`、次に`somnio-testflight`を実行。

`v*`タグをpushすると、CodemagicのWebhook設定後はTestFlightワークフローが起動します。ビルド番号にはCodemagicのプロジェクトビルドカウンター＋1を使います。配信先の既存ビルド番号を超える必要があります。

GitHub Actionsは署名なし検証用です。署名・TestFlight配信はCodemagicが行います。GitHubのrepository secretsは他リポジトリやCodemagicへ自動継承されません。この構成はCodemagic上の既存連携と署名設定を利用し、秘密鍵をGitへ保存しません。

## 少しずつ改善する使い方

最初は小さな音で好みの設定を数晩使い、朝に休息感を記録します。寝る時刻や睡眠時間が大きく違う夜は単純比較せず、設定は一度にひとつずつ変えると振り返りやすくなります。Watchの深睡眠時間だけを最大化せず、本人の翌朝の感覚を中心に考えます。

## 調査と設計

- [初版設計](docs/superpowers/specs/2026-11-03-somni-design.md)
- [実装計画](docs/superpowers/plans/2026-11-03-somnio.md)
