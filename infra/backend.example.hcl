bucket         = "one-click-tfstate-c55wiejq"
key            = "terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "one-click-tf-locks"
kms_key_id     = "arn:aws:kms:us-east-1:825982271549:key/0ff12a65-abf1-4edd-9a10-fd80c7cb2bfe"

# Recommended extras
acl            = "private"
workspace_key_prefix = "envs"
