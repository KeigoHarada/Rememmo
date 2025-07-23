import Foundation
import MiniGit

struct RealGitService: GitServiceProtocol {
    private let fileManager = FileManager.default
    private var repoURL: URL {
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docURL.appendingPathComponent("test-repo")
    }
    private var credentialsFileURL: URL {
        repoURL.appendingPathComponent("credentials.json")
    }
    // repositoryは都度生成

    func fileTest(log: inout String) {
        let testURL = repoURL.appendingPathComponent("test-file.txt")
        do {
            let content = "テスト内容 \(Date())"
            try content.write(to: testURL, atomically: true, encoding: .utf8)
            log += "✅ ファイル作成成功: \(testURL.path)\n"
            let readContent = try String(contentsOf: testURL, encoding: .utf8)
            log += "✅ ファイル読み込み成功: \(readContent)\n"
        } catch {
            log += "❌ ファイル操作エラー: \(error)\n"
        }
        log += "=== ファイルテスト完了 ===\n\n"
    }

    func gitInit(log: inout String) {
        do {
            // 既存のディレクトリを削除
            if fileManager.fileExists(atPath: repoURL.path) {
                try fileManager.removeItem(at: repoURL)
                log += "既存ディレクトリを削除しました\n"
            }
            // 新しいディレクトリを作成
            try fileManager.createDirectory(at: repoURL, withIntermediateDirectories: true, attributes: nil)
            log += "ディレクトリを作成しました: \(repoURL.path)\n"
            // credentials.jsonファイルを作成（配列形式）
            let credentialsContent = "[]"
            try credentialsContent.write(to: credentialsFileURL, atomically: true, encoding: .utf8)
            log += "credentials.jsonファイルを作成しました\n"
            // MiniGitでリポジトリを作成
            let credentialsManager = CredentialsManager(credentialsFileUrl: credentialsFileURL)
            let repo = GitRepository(repoURL, credentialsManager)
            repo.create()
            log += "Gitリポジトリを作成しました（git init）\n"
            repo.open()
            log += "Gitリポジトリを開きました\n"
            // Git設定を追加
            let configPath = repoURL.appendingPathComponent(".git/config")
            let configContent = """
            [core]
            \trepositoryformatversion = 0
            \tfilemode = true
            \tbare = false
            \tlogallrefupdates = true
            \tignorecase = true
            \tprecomposeunicode = true
            
            [user]
            \tname = Rememmo User
            \temail = user@rememmo.local
            """
            try configContent.write(to: configPath, atomically: true, encoding: .utf8)
            log += "✅ Git設定を追加しました\n"
            if repo.hasRepo {
                log += "✅ リポジトリ作成成功: \(repoURL.path)\n"
            } else {
                log += "❌ リポジトリ作成失敗\n"
            }
        } catch {
            log += "❌ リポジトリ作成エラー: \(error)\n"
        }
        log += "=== Git Init テスト完了 ===\n\n"
    }

    func gitCommit(log: inout String) {
        let fileURL = repoURL.appendingPathComponent("test.txt")
        let content = "MiniGitテスト \(Date())"
        do {
            // ファイル作成
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            log += "ファイル作成: \(fileURL.lastPathComponent)\n"
            // MiniGitでリポジトリを開く
            let credentialsManager = CredentialsManager(credentialsFileUrl: credentialsFileURL)
            let repo = GitRepository(repoURL, credentialsManager)
            repo.open()
            // ステージング
            repo.stage("test.txt")
            log += "ステージング完了\n"
            // コミット
            repo.commit("テストコミット")
            log += "✅ コミット成功: テストコミット\n"
        } catch {
            log += "❌ コミットエラー: \(error)\n"
        }
        log += "=== Git Commit テスト完了 ===\n\n"
    }
}