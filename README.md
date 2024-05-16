## 概要

Amazon RDSでpg_tleの認証フックをを利用したログイン通知サンプル

## 詳細

PostgreSQL上で新規接続などで認証が行われ`cliantauth`がフックされた場合かつ認証が成功の場合、  
指定されたメールアドレスに対してそのユーザ名とログイン時刻を通知する。

## 前提

pg_tle 1.4.0に対応しているRDS for PostgreSQLが存在しておりVPCエンドポイントもしくはNAT GatewayでLambda関数が呼びし可能な状態となっている

## 作成されるリソース

- RDSに割り当てるためのIAMロール
- 実行されるAWS Lambda関数
- 上記より呼び出されるAmazon SNSトピック・サブスクリプション
- RDS内で拡張機能作成のために利用するSQL(pg_extention.sql)

## 環境セットアップ

### SAMによるデプロイ

```bash
sam build && sam deploy --parameter-overrides NotificationAddress={{your mail address}}
```

デプロイ後SNS利用のための確認通知が指定したアドレスに飛んでくるので承認する

### RDS手動セットアップ箇所

RDSに対して`CallLoginNotificationRdsRole`で作成されるIAMロールをLambda機能として割り当てる。

また割り当てられているパラメータグループに以下の設定を行う

|パラメータ|値|備考|
|-------|---|--|
|shared_preload_library|pg_tle, aws_lambda|既存パラメータがある場合そこへの追加|
|pgtle.enable_clientauth|on||
|rds.custom_dns_resolution|1|VPCエンドポイントを利用する場合(lambda関数実行用)|

パラメータグループ設定後にRDS再起動した後にDBに接続しスーパーユーザで`pg_extention.sql`の内容を実行する。

その後以下を実行し通知用の独自拡張機能を有効化する。

```sql
CREATE EXTENSION login_notification;
```

なお有効化後は動作確認が取れるまで既存のコネクションを切断せず保持すること。  
指定がうまくできていない場合DBに接続不可となる可能性がある。


## 動作確認

上記実行後にpsqlコマンド等で該当RDSに接続すると以下のようなメールが届く

メールサブジェクト: Logged in notification: {{login db user}}
メール本文: Logged in {{login db user}} in {{login time}}

## 備考

以下記事記載のために作成しされたサンプルとなりますのでこちらもご参照ください。

https://dev.classmethod.jp/articles/rds-for-postgresql-support-pg-tle1-4-0/