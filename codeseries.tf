####################################
# CodeCommit Repository
####################################
resource "aws_codecommit_repository" "static_hosting" {
  repository_name = "${var.prefix}-static-hosting-repo"
  default_branch = "main"
}

####################################
# CodeCommit Pipeline
####################################
data "aws_iam_policy_document" "assume_codepipeline" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [ "codepipeline.amazonaws.com" ]
    }
    actions = [ "sts:AssumeRole" ]
  }
}

data "aws_iam_policy_document" "policy_codepipeline" {
  version = "2012-10-17"

  statement {
    sid = "CodeCommit"
    effect = "Allow"
    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive"
    ]
    resources = [ aws_codecommit_repository.static_hosting.arn ]
  }

  # S3への読み書き
  # https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/reference_policies_examples_s3_rw-bucket.html
  statement {
    sid = "ListObjectsInBucket"
    effect = "Allow"
    actions = [ "s3:ListBucket" ]
    resources = [
      aws_s3_bucket.static_hosting.arn,
      aws_s3_bucket.static_hosting_artifact.arn,
    ]
  }

  statement {
    sid = "AllObjectActions"
    effect = "Allow"
    actions = [ "s3:*Object" ]
    resources = [
      "${aws_s3_bucket.static_hosting.arn}/*",
      "${aws_s3_bucket.static_hosting_artifact.arn}/*",
    ]
  }

  statement {
    sid = "KMS"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = [
      aws_kms_key.static_hosting.arn,
      aws_kms_key.static_hosting_artifact.arn,
    ]
  }
}

resource "aws_iam_role" "codepipeline_static_hosting" {
  name = "${var.prefix}-codepipeline-static-hosting"
  assume_role_policy = data.aws_iam_policy_document.assume_codepipeline.json
}

resource "aws_iam_policy" "codepipeline_static_hosting" {
  name = "${var.prefix}-codepipeline-static-hosting"
  policy = data.aws_iam_policy_document.policy_codepipeline.json
}

resource "aws_iam_role_policy_attachment" "codepipeline_static_hosting" {
  role = aws_iam_role.codepipeline_static_hosting.name
  policy_arn = aws_iam_policy.codepipeline_static_hosting.arn
}

resource "aws_codepipeline" "static_hosting" {
  name = "${var.prefix}-static-hosting"
  role_arn = aws_iam_role.codepipeline_static_hosting.arn
  artifact_store {
    location = aws_s3_bucket.static_hosting_artifact.bucket
    type = "S3"
  }

  stage {
    name = "Source"
    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = 1
      output_artifacts = [ "source_output" ]
      configuration = {
        RepositoryName = aws_codecommit_repository.static_hosting.repository_name
        BranchName = aws_codecommit_repository.static_hosting.default_branch
        OutputArtifactFormat = "CODE_ZIP"
      }
      run_order = 1
    }
  }

  stage {
    name = "Deploy"
    action {
      name = "Deploy"
      category = "Deploy"
      owner = "AWS"
      provider = "S3"
      version = 1
      configuration = {
        BucketName = aws_s3_bucket.static_hosting.bucket
        Extract = "true"
      }
      input_artifacts = [ "source_output" ]
      run_order = 1
    }
  }
}

