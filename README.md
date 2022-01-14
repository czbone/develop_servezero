# ServeZero - マルチドメインホスティングシステム

**ステータス(現在開発中)**

複数のWebアプリケーションをマルチドメインで運用できるホスティングシステムです。システムは１台のサーバ上で稼働します。  
WebアプリケーションはDockerコンテナ上で運用されます。

## 運用できるWebアプリケーション

LEMP(Nginx + MariaDb + PHP)型のWebアプリケーションが運用できます。  
WordPressなどの「スクリプト言語+DB」タイプのCMSの対応が初期目標です。

## 対象OS
- CentOS Linux v8
- Rocky Linux v8
- Alma Linux v8

## ライセンス

[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)

# インストール
新規にOSをインストールしたサーバに`root`でログインし、以下の１行のコマンドをそのままコピーして実行します。  
インストール完了後、サーバを再起動します。

## 実行コマンド
```
curl https://raw.githubusercontent.com/czbone/develop_servezero/master/script/build_env.sh | bash
```

# 関連プロジェクト

- システム管理用Webアプリケーション(https://github.com/czbone/develop_servezero_app )
