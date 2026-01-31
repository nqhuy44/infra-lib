# AWS S3 Bucket Module

...

## Public Access Handling

This module automatically manages the S3 bucket-level **Block Public Access** settings to avoid manual AWS Console steps when you want a public bucket (for example, for static website hosting).

- **If you set `acl = "public-read"` or `acl = "public-read-write"`:**  
  The module will automatically disable all bucket-level public access block settings before applying the ACL or a public bucket policy.  
  This ensures Terraform can successfully create a public bucket without requiring you to manually disable "Block all public access" in the AWS Console.

- **If you set a private ACL or do not specify a public ACL:**  
  The module applies your chosen Block Public Access settings after the ACL/policy, ensuring the bucket is locked down as you want.

- **Account-level Block Public Access:**  
  This module does **not** manage account-level S3 public access block settings.  
  If your AWS account has account-level public access block enabled, public ACLs or public policies will still be blocked by AWS, regardless of bucket-level settings.

### Example: Public Static Website Bucket

```hcl
module "website_bucket" {
  source = "../../modules/s3"

  bucket_name = "my-static-website"

  # Allow public access for website
  block_public_access      = false
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false

  object_ownership = "BucketOwnerPreferred"
  acl              = "public-read"

  website_enabled        = true
  website_index_document = "index.html"
  website_error_document = "error.html"

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-static-website/*"
      }
    ]
  })

  event_notifications = [
    {
      lambda_function = {
        arn           = aws_lambda_function.file_processor.arn
        events        = ["s3:ObjectCreated:*"]
        filter_prefix = "uploads/"
        filter_suffix = ".csv"
      }
    },
    {
      queue = {
        arn           = aws_sqs_queue.file_events.arn
        events        = ["s3:ObjectRemoved:*"]
        filter_suffix = ".log"
      }
    },
    {
      topic = {
        arn    = aws_sns_topic.bucket_notifications.arn
        events = ["s3:ObjectCreated:Put"]
      }
    }
  ]

  tags = {
    Environment = "production"
    Service     = "website"
  }
}
```

**No manual console steps are required.**  
The module will automatically relax the bucket-level Block Public Access settings before applying the public ACL or policy.

---

## Choosing the Right `object_ownership` Setting

(Keep your existing explanation here.)

---

## Notes

- If you use `BucketOwnerEnforced`, do **not** set a public ACL—AWS will return an error.
- For public buckets, always use `object_ownership = "BucketOwnerPreferred"` and `acl = "public-read"` or `"public-read-write"`.

---

## Changelog

- **[vNext]**: Module now automatically disables bucket-level Block Public Access when a public ACL is requested, removing the need for manual AWS Console changes for public buckets.

...