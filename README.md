# はじめに

[OACを利用したCloudFront + S3の静的ウェブサイトをTerraformで作成してみた　〜CodePipelineを添えて〜](https://dev.classmethod.jp/etc/cloudfront-s3-pi…erraform-oveview/)のサンプルコードが格納されたリポジトリです。

詳しくはブログをご覧いただければと思います。

# 構成図

<img src="/img/cloudfront_s3_pipeline.png">

# 設定方法

`git clone`でクローン後、`terraform.tfvars`ファイルまたは、`provider.tf`で`prefix`を入力してください。
入力しない場合、`terraform`コマンド時にプロンプトで入力を求められます。

## 作成
```bash
# terraformの実行
terraform init
terraform apply
```

## 削除
```bash
# terraformの実行
terraform destroy
```