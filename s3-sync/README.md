# S3-sync

A simple Python3 app to loop the `aws s3 sync` command.
Suitable for automatic config files update for infrastructure.

## Getting started

You need AWS access configuring correctly:
- Static AWS credential
- Environment variables
- IAM instance profile

To see usage:
```sh
./s3-sync.py help
```

Docker work:
```sh
docker build -t s3-sync:0.0.1 .

docker run -it s3-sync:0.0.1 --source=s3://example-bucket/abc --dest=/tmp/abc
```

## Maintainer:
- Luan Tran - @minhluantran017