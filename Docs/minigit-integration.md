# MiniGit統合手順書

## 概要

RememmoアプリにMiniGitパッケージを統合して、実際のGitリポジトリ操作を実装します。SOLID原則に従った設計を維持しながら、開発効率を向上させます。

## 前提条件

- Xcode 15.0以上
- iOS 17.0以上
- Swift 5.9以上

## 1. MiniGitパッケージの追加

### 1.1 Xcodeでパッケージを追加

1. **XcodeでRememmo.xcodeprojを開く**
2. **File → Add Package Dependencies**
3. **Search or Enter Package URL**に以下を入力：

   ```
   https://github.com/light-tech/MiniGit
   ```

4. **Add Package**をクリック
5. **Rememmo**ターゲットを選択して**Add Package**をクリック

### 1.2 パッケージの確認

Package.swiftに以下が追加されていることを確認：

```swift
dependencies: [
    .package(url: "https://github.com/light-tech/MiniGit", from: "1.0.0")
]
```

## 2. MemoGitServiceの更新

### 2.1 MiniGitインポートの追加

```swift
import Foundation
import SwiftData
import MiniGit
```

### 2.2 リポジトリ管理の追加

```swift
class MemoGitService: ObservableObject {
    private let modelContext: ModelContext
    private var repositories: [UUID: Repository] = [:]
    
    // ... 既存のコード ...
}
```

### 2.3 リポジトリ初期化メソッド

```swift
/// メモ用のGitリポジトリを初期化
func initializeRepository(for memo: Memo) throws {
    let repoPath = getMemoRepositoryPath(memoId: memo.id)
    
    // リポジトリが存在しない場合は初期化
    if !FileManager.default.fileExists(atPath: repoPath) {
        try createRepository(at: repoPath)
    }
    
    // リポジトリを開く
    let repository = Repository(path: repoPath)
    repository.open()
    repositories[memo.id] = repository
    
    // 初回コミットの作成
    if memo.currentCommitId == nil {
        try createInitialCommit(for: memo)
    }
}
```

### 2.4 Gitコミット機能の追加

```swift
/// Gitリポジトリにコミット
private func commitToGitRepository(for memo: Memo, message: String) throws {
    guard let repository = repositories[memo.id] else {
        throw GitError.repositoryNotFound
    }
    
    // メモファイルを更新
    let memoContent = createMemoContent(memo)
    try writeMemoFile(memoId: memo.id, content: memoContent)
    
    // 変更をステージング
    repository.add(pathspec: "memo.md")
    
    // Gitコミット
    repository.commit(message: message)
}
```

## 3. ファイル管理の実装

### 3.1 メモファイルの保存構造

```
Documents/
├── memos/
│   ├── {memo-id-1}/
│   │   ├── .git/                    # Gitリポジトリ
│   │   └── memo.md                  # メモファイル
│   ├── {memo-id-2}/
│   │   ├── .git/
│   │   └── memo.md
│   └── ...
```

### 3.2 メモファイルの形式

```markdown
# メモタイトル

メモの内容をここに記述します。

## 見出し2

- リスト項目1
- リスト項目2

**太字**や*斜体*も使用可能

---
作成日: 2025年1月1日 10:00
更新日: 2025年1月1日 12:00
```

## 4. SOLID原則の適用

### 4.1 Single Responsibility Principle (単一責任の原則)

- **MemoGitService**: Git操作のみに責任を持つ
- **Memo**: メモデータの管理のみに責任を持つ
- **MemoCommit**: コミット履歴の管理のみに責任を持つ

### 4.2 Open/Closed Principle (開放/閉鎖の原則)

- 新しいGit操作を追加する際は、既存のコードを変更せずに拡張可能
- プロトコルを使用して依存関係を抽象化

### 4.3 Liskov Substitution Principle (リスコフの置換原則)

- RepositoryクラスはMiniGitのRepositoryに置き換え可能
- エラーハンドリングは統一されたインターフェースを使用

### 4.4 Interface Segregation Principle (インターフェース分離の原則)

- 必要最小限のメソッドのみを公開
- 内部実装の詳細は隠蔽

### 4.5 Dependency Inversion Principle (依存関係逆転の原則)

- 高レベルモジュール（MemoGitService）は低レベルモジュール（MiniGit）に依存しない
- 抽象化されたインターフェースを通じて依存関係を管理

## 5. エラーハンドリング

### 5.1 GitErrorの定義

```swift
enum GitError: Error, LocalizedError {
    case repositoryNotFound
    case commitFailed
    case fileOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .repositoryNotFound:
            return "Gitリポジトリが見つかりません"
        case .commitFailed:
            return "コミットに失敗しました"
        case .fileOperationFailed:
            return "ファイル操作に失敗しました"
        }
    }
}
```

### 5.2 エラー処理の実装

```swift
do {
    try commitToGitRepository(for: memo, message: message)
} catch GitError.repositoryNotFound {
    print("リポジトリが見つかりません")
} catch GitError.commitFailed {
    print("コミットに失敗しました")
} catch {
    print("予期しないエラー: \(error)")
}
```

## 6. テスト

### 6.1 ビルドテスト

```bash
xcodebuild -project Rememmo.xcodeproj -scheme Rememmo -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### 6.2 機能テスト

1. **メモ作成**: 新規メモを作成し、Gitリポジトリが初期化されることを確認
2. **コミット**: メモを編集し、Gitコミットが作成されることを確認
3. **履歴表示**: コミット履歴が正しく表示されることを確認
4. **復元**: 過去のコミットから復元できることを確認

## 7. パフォーマンス最適化

### 7.1 リポジトリのキャッシュ

- メモリ内でリポジトリインスタンスをキャッシュ
- 不要になったリポジトリは適切にクリーンアップ

### 7.2 非同期処理

- 重いGit操作は非同期で実行
- UIのブロッキングを防ぐ

## 8. セキュリティ

### 8.1 ファイルアクセス

- アプリのDocumentsディレクトリ内でのみ操作
- 外部からのアクセスを制限

### 8.2 データ検証

- コミットメッセージの検証
- ファイル内容の整合性チェック

## 9. 今後の拡張

### 9.1 ブランチ機能

- 複数のブランチでの作業
- ブランチ間のマージ

### 9.2 リモートリポジトリ

- GitHub/GitLabとの連携
- クラウド同期

### 9.3 差分表示

- コミット間の差分表示
- 行単位での変更履歴

## 10. トラブルシューティング

### 10.1 よくある問題

1. **MiniGitモジュールが見つからない**
   - パッケージが正しく追加されているか確認
   - ターゲットに追加されているか確認

2. **ビルドエラー**
   - 依存関係の競合がないか確認
   - バージョンの互換性を確認

3. **Git操作エラー**
   - ファイルパーミッションを確認
   - ディスク容量を確認

### 10.2 デバッグ方法

```swift
// デバッグログの追加
print("リポジトリパス: \(repoPath)")
print("コミットメッセージ: \(message)")
```

## まとめ

MiniGitの統合により、Rememmoアプリは本格的なGit機能を獲得し、ユーザーはメモの変更履歴を詳細に管理できるようになります。SOLID原則に従った設計により、保守性と拡張性を確保し、将来の機能追加も容易になります。
