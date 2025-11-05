# How to Enable Bucket List View in AWS Console

## Current Issue
The IAM user `teriyaki-chasers-s3-uploader` can access the bucket directly but cannot see it in the S3 bucket list page because it lacks `s3:ListAllMyBuckets` permission.

## Solution: Update IAM Policy

### Step 1: Log in to AWS Console
1. Go to: https://339712839005.signin.aws.amazon.com/console
2. Log in with an **administrator account** (not the IAM user) or root account
3. You need admin permissions to modify IAM policies

### Step 2: Navigate to IAM
1. Search for "IAM" in the AWS services search bar
2. Click on "IAM" (Identity and Access Management)

### Step 3: Find the User Policy
1. In the left sidebar, click **"Users"**
2. Search for or click on: `teriyaki-chasers-s3-uploader`
3. Click on the **"Permissions"** tab
4. Find the policy attached to this user (it might be an inline policy or a managed policy)

### Step 4: Update the Policy
If it's an **inline policy**, click "Edit" and replace the JSON with the updated policy below.

If it's a **managed policy**, you'll need to create a new inline policy or update the managed policy.

### Updated IAM Policy JSON (with ListAllMyBuckets enabled)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListAllBuckets",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowS3BucketAccess",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:HeadBucket"
            ],
            "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media"
        },
        {
            "Sid": "AllowS3UploadDelete",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:GetObjectAcl"
            ],
            "Resource": "arn:aws:s3:::teriyaki-chasers-wildlife-media/*"
        }
    ]
}
```

### What Changed?
Added a new statement at the top:
```json
{
    "Sid": "AllowListAllBuckets",
    "Effect": "Allow",
    "Action": [
        "s3:ListAllMyBuckets"
    ],
    "Resource": "*"
}
```

This grants permission to list all buckets in the AWS account (required for the S3 console bucket list page).

### Step 5: Test
1. Log out and log back in as `teriyaki-chasers-s3-uploader`
2. Go to: https://s3.console.aws.amazon.com/s3/buckets?region=us-east-2
3. You should now be able to see the bucket list (or at least not get "Access Denied")

## Alternative: Using AWS CLI (if you have CLI access)

If you have AWS CLI configured with admin credentials:

```bash
# Get current policy
aws iam get-user-policy --user-name teriyaki-chasers-s3-uploader --policy-name <policy-name>

# Update policy (save the JSON above to policy.json first)
aws iam put-user-policy \
    --user-name teriyaki-chasers-s3-uploader \
    --policy-name S3BucketAccessPolicy \
    --policy-document file://policy.json
```

## Security Note
Adding `s3:ListAllMyBuckets` with `Resource: "*"` allows the user to see all bucket names in the account (though they can only access the ones they have permissions for). This is generally safe but increases visibility slightly.

