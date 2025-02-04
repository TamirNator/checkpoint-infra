#!/bin/bash

# Set AWS Variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
AWS_REGION="eu-west-1"
OIDC_PROVIDER="token.actions.githubusercontent.com"
IAM_ROLE_NAME="TamirGitHubOIDC"
TRUST_POLICY_FILE="trust-policy.json"

echo "🔹 AWS Account ID: $AWS_ACCOUNT_ID"
echo "🔹 AWS Region: $AWS_REGION"
echo "🔹 IAM Role Name: $IAM_ROLE_NAME"

# Step 1: Ensure the required JSON policy files exist
if [[ ! -f "$TRUST_POLICY_FILE" ]]; then
  echo "❌ ERROR: Trust policy file ($TRUST_POLICY_FILE) not found!"
  exit 1
fi

# Step 2: Create OIDC Provider if not exists
echo "🔹 Checking if OIDC Provider exists..."
EXISTING_PROVIDER=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[*].Arn" --output text | grep "$OIDC_PROVIDER" || echo "not-found")

if [[ "$EXISTING_PROVIDER" == "not-found" ]]; then
  echo "✅ Creating OIDC Provider..."
  aws iam create-open-id-connect-provider \
    --url "https://$OIDC_PROVIDER" \
    --thumbprint-list $(curl -s https://$OIDC_PROVIDER/.well-known/openid-configuration | jq -r '.jwks_uri' | xargs curl -s | jq -r '.keys[0].x5c[0]' | openssl x509 -fingerprint -noout -sha1 | awk -F'=' '{print $2}' | sed 's/://g') \
    --client-id-list "sts.amazonaws.com"
  echo "✅ OIDC Provider created successfully."
else
  echo "✅ OIDC Provider already exists: $EXISTING_PROVIDER"
fi

# Step 3: Create or Update IAM Role with Trust Policy
echo "🔹 Checking if IAM Role exists..."
EXISTING_ROLE=$(aws iam get-role --role-name "$IAM_ROLE_NAME" --query "Role.Arn" --output text 2>/dev/null || echo "not-found")

if [[ "$EXISTING_ROLE" == "not-found" ]]; then
  echo "✅ Creating IAM Role: $IAM_ROLE_NAME..."
  ROLE_ARN=$(aws iam create-role \
    --role-name "$IAM_ROLE_NAME" \
    --assume-role-policy-document file://$TRUST_POLICY_FILE \
    --query "Role.Arn" --output text)
  echo "✅ IAM Role created successfully: $ROLE_ARN"
else
  echo "✅ IAM Role already exists: $EXISTING_ROLE"
  ROLE_ARN=$EXISTING_ROLE

  # Update existing role with the new Trust Policy
  aws iam update-assume-role-policy \
    --role-name "$IAM_ROLE_NAME" \
    --policy-document file://$TRUST_POLICY_FILE
  echo "✅ IAM Trust Policy updated successfully."
fi

# Step 4: Attach Policies from oidc/ directory (excluding trust-policy.json)
echo "🔹 Attaching policies to role: $IAM_ROLE_NAME..."
for POLICY_FILE in ./*.json; do
  if [[ "$(basename "$POLICY_FILE")" == "trust-policy.json" ]]; then
    continue
  fi

  POLICY_NAME=$(basename "$POLICY_FILE" .json)
  POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME"

  # Check if policy exists
  POLICY_EXISTS=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

  if [[ -z "$POLICY_EXISTS" ]]; then
    echo "✅ Creating IAM Policy: $POLICY_NAME..."
    POLICY_ARN=$(aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://$POLICY_FILE --query "Policy.Arn" --output text)
  else
    echo "✅ IAM Policy already exists: $POLICY_ARN"
  fi

  # Attach policy to role
  aws iam attach-role-policy --role-name "$IAM_ROLE_NAME" --policy-arn "$POLICY_ARN"
  echo "✅ Attached $POLICY_ARN to role $IAM_ROLE_NAME"
done

# Step 5: Verify IAM Role and Policies
echo "🔹 Verifying IAM Role..."
aws iam get-role --role-name "$IAM_ROLE_NAME"

echo "🔹 Verifying attached policies..."
aws iam list-attached-role-policies --role-name "$IAM_ROLE_NAME"

echo "✅ OIDC setup is complete!"
echo "🎯 Use the following IAM Role ARN in GitHub Actions:"
echo "$ROLE_ARN"