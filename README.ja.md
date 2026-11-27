<img alt="ak" src="./assets/logo/logo-light.svg" width="200">

# ak

[English](README.md) · [Tiếng Việt](README.vi.md) · **日本語**

複数のプロジェクトで同じワークフローを使えます。`ak` にタスクを渡すと、
要件の理解、実装、検証、引き渡しまで進めます。初回はリポジトリを調べ、
普段の作業ルールを確認します。次回以降は同じプロジェクトフォームを再利用します。

**[操作デモとインストール手順](docs/catalog.html)**（ベトナム語）

## はじめに

```bash
git clone https://github.com/vantrong2405/dev-workflow.git ak
cd ak
bash install.sh --codex
```

利用するホストに合わせて `--claude`、`--cursor`、`--codex`、`--agy` を選択します。
対象のリポジトリを開き、`/ak` にタスクを渡すか、スキル選択画面で ak の start を選びます。

```text
/ak CSV エクスポートに現在のフィルターを反映する
/ak TICKET-123 https://tracker.example/TICKET-123
/ak TICKET-123 リリース準備 --ship
```

初回は作業ルールの案を確認するか、質問をスキップできます。通常のタスクは
変更と検証結果の引き渡しまで進みます。リリース準備まで行う場合は `--ship` を
指定してください。push、merge、deploy には明示的な権限が必要です。

[利用ガイド](docs/USER-GUIDE.ja.md) · [インストールと更新](docs/INSTALL.md) · [構成](STRUCTURE.md) · [ステージ契約](references/stage-contract.md)

[MIT ライセンス](LICENSE)
