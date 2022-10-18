####################################
# EventBridge Role
####################################
data "aws_iam_policy_document" "assume_event_bridge" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_event_bridge" {
  statement {
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = ["${aws_codepipeline.static_hosting.arn}"]
  }
}

resource "aws_iam_role" "event_bridge_static_hosting" {
  name               = "${var.prefix}-event-bridge-static-hosting"
  assume_role_policy = data.aws_iam_policy_document.assume_event_bridge.json
}

resource "aws_iam_policy" "event_bridge_static_hosting" {
  name = "${var.prefix}-event-bridge-static-hosting"
  policy = data.aws_iam_policy_document.policy_event_bridge.json
}

resource "aws_iam_role_policy_attachment" "event_bridge_static_hosting" {
  role = aws_iam_role.event_bridge_static_hosting.name
  policy_arn = aws_iam_policy.event_bridge_static_hosting.arn
}

####################################
# EventBridge Rule
####################################
resource "aws_cloudwatch_event_rule" "static_hosting" {
  name = "${var.prefix}-static-hosting"

  event_pattern = templatefile("./file/event_pattern.json", {
    codecommit_arn : aws_codecommit_repository.static_hosting.arn
  })
}

resource "aws_cloudwatch_event_target" "static_hosting" {
  rule     = aws_cloudwatch_event_rule.static_hosting.name
  arn      = aws_codepipeline.static_hosting.arn
  role_arn = aws_iam_role.event_bridge_static_hosting.arn
}