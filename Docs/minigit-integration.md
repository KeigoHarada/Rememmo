# MiniGit 統合ガイド

## 概要

RememmoアプリでMiniGitを使用してGitリポジトリの作成とコミットを行う実装例。

## 必要な依存関係

### 1. パッケージの追加

Xcodeで以下のパッケージを追加：

- **URL**: `https://github.com/light-tech/MiniGit`
- **バージョン**: `main` ブランチ

### 2. ターゲットへの追加

- Rememmoターゲットに `MiniGit` パッケージを追加
- **Frameworks, Libraries, and Embedded Content** で `Embed & Sign` に設定

## 実装例

### 基本的なインポート

```swift
import SwiftUI
import MiniGit
```

### 状態管理

```swift
@State private var repository: GitRepository?
@State private var repoURL: URL?
@State private var userName: String = "Rememmo User"
@State private var userEmail: String = "user@rememmo.local"
```

### リポジトリ作成

```swift
private func createRepository() {
    let fileManager = FileManager.default
    let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let repoURL = docURL.appendingPathComponent("test-repo")
    
    do {
        // 既存ディレクトリを削除
        if fileManager.fileExists(atPath: repoURL.path) {
            try fileManager.removeItem(at: repoURL)
        }
        
        // 新しいディレクトリを作成
        try fileManager.createDirectory(at: repoURL, withIntermediateDirectories: true, attributes: nil)
        
        // credentials.jsonファイルを作成（重要：配列形式）
        let credentialsFileURL = repoURL.appendingPathComponent("credentials.json")
        let credentialsContent = "[]"  // 空の配列
        try credentialsContent.write(to: credentialsFileURL, atomically: true, encoding: .utf8)
        
        // MiniGitでリポジトリを作成
        let credentialsManager = CredentialsManager(credentialsFileUrl: credentialsFileURL)
        let repo = GitRepository(repoURL, credentialsManager)
        
        // git init を実行
        repo.create()
        
        // リポジトリを開く
        repo.open()
        
        // Git設定を追加
        try setupGitConfiguration(repo: repo)
        
        // 成功確認
        if repo.hasRepo {
            repository = repo
        }
    } catch {
        print("エラー: \(error)")
    }
}
```

### Git設定の追加

```swift
private func setupGitConfiguration(repo: GitRepository) throws {
    let configPath = repoURL!.appendingPathComponent(".git/config")
    
    let configContent = """
    [core]
    \trepositoryformatversion = 0
    \tfilemode = true
    \tbare = false
    \tlogallrefupdates = true
    \tignorecase = true
    \tprecomposeunicode = true
    
    [user]
    \tname = \(userName)
    \temail = \(userEmail)
    """
    
    try configContent.write(to: configPath, atomically: true, encoding: .utf8)
}
```

### ファイルのコミット

```swift
private func commitFile() {
    guard let repo = repository, repo.hasRepo, let repoURL = repoURL else {
        return
    }
    
    let fileURL = repoURL.appendingPathComponent("test.txt")
    let content = "MiniGitテスト \(Date())"
    
    do {
        // ファイル作成
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // ステージング
        repo.stage("test.txt")
        
        // コミット
        repo.commit("テストコミット")
    } catch {
        print("コミットエラー: \(error)")
    }
}
```

## 重要なポイント

### 1. CredentialsManager の設定

- `credentialsFileUrl` には**ファイルパス**を渡す（ディレクトリパスではない）
- `credentials.json` の内容は**配列形式** `[]` にする
- 辞書形式 `{"credentials": []}` は使わない

### 2. エラーハンドリング

よくあるエラーと対処法：

#### "Is a directory" エラー

```swift
// ❌ 間違い
let credentialsManager = CredentialsManager(credentialsFileUrl: repoURL)

// ✅ 正しい
let credentialsFileURL = repoURL.appendingPathComponent("credentials.json")
let credentialsManager = CredentialsManager(credentialsFileUrl: credentialsFileURL)
```

#### "No such file or directory" エラー

```swift
// credentials.jsonファイルを事前に作成
let credentialsContent = "[]"
try credentialsContent.write(to: credentialsFileURL, atomically: true, encoding: .utf8)
```

#### "typeMismatch" エラー

```swift
// ❌ 間違い（辞書形式）
let credentialsContent = """
{
    "credentials": []
}
"""

// ✅ 正しい（配列形式）
let credentialsContent = """
[]
"""
```

### 3. ファイルパスの注意点

- ディレクトリとファイルを混同しない
- `FileManager` でディレクトリを作成
- ファイル操作は個別のファイルパスを使用

## テスト手順

1. **ファイルテスト** - 基本的なファイル操作の確認
2. **Git Init** - リポジトリの作成と初期化
3. **Git Commit** - ファイルのステージングとコミット
4. **ログクリア** - ログのリセット

## トラブルシューティング

### MiniGitモジュールが見つからない場合

1. Xcodeでプロジェクトを開く
2. **File** → **Add Package Dependencies...**
3. URL: `https://github.com/light-tech/MiniGit`
4. ターゲットに追加して **Embed & Sign** に設定

### ビルドエラーが続く場合

1. **Product** → **Clean Build Folder**
2. **Window** → **Organizer** → **Projects** → **Delete Derived Data**
3. シミュレーターを再起動

## 参考リンク

- [MiniGit GitHub](https://github.com/light-tech/MiniGit)
- [Swift Package Manager](https://developer.apple.com/documentation/swift_packages)
