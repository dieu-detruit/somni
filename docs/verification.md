# 検証記録

2026-11-03、アプリソース 4e93319。

- GitHub Actions macOSで共有ロジック12件のテスト成功。
- iPhoneアプリと埋め込みWatchアプリの署名なしReleaseアーカイブ成功。
- アーカイブのBundle ID、Watch companion関係、バージョン一致の検証成功。
- 検証: https://github.com/dieu-detruit/somni/actions/runs/41479430781
- 既存SecretsによるSomnioのApp Store Connect確認、HealthKit capability、両Bundle IDの署名ファイル取得成功（前回の配信試行で確認）。
- TestFlight配信: https://github.com/dieu-detruit/brain-dump/actions/runs/41479439251 （この記録作成時は実行待ち）

実機の音の聞こえ方、ロック・通話・音声ルート変更、Watch通信、一晩の電池消費、HealthKitの実データ取得は未検証。

レビューで見つかった朝の日付更新、オフライン評価の保存、削除時のバックアップ除去を修正。再レビューで対象指摘の解消を確認。
