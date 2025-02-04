resource "aws_iam_policy" "eks_policy" {
  name        = "EKS-Policy"
  description = "Policy to allow Actions for EKS"
  policy      = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowEC2"
        Effect   = "Allow",
        Action   = [
          "ec2:CreateVolume",
          "ec2:CreateTags",
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:ModifyVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications"
        ],
        Resource = "*"
      },
      {
        "Sid": "AllowECR",
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowRout53",
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZonesByName",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange"
        ],
        "Resource": "*"
      }
    ]
  })
}