#!/usr/bin/env python3
import argparse
import subprocess
import time

if __name__ == '__main__':
   parser = argparse.ArgumentParser(description='AWS S3 sync looping')
   parser.add_argument('--interval', type=int, required=False,
                        default = 30, help='Execution interval (in second). Default is 30')
   parser.add_argument('--region', type=str, required=False,
                        default = 'us-west-2', help='AWS region of S3 bucket. Default is us-west-2')
   parser.add_argument('--source', type=str, required=True,
                        help='Source bucket/local file/directory')
   parser.add_argument('--dest', type=str, required=True,
                        help='Destination bucket/local file/directory')
   args = parser.parse_args()

   while True:
      print(f"Syncing files from {args.source} to {args.dest} ...")
      cmd = ['aws', '--region', args.region, 's3', 'sync', args.source, args.dest]
      subprocess.check_output(cmd, stderr=subprocess.STDOUT)
      time.sleep(args.interval)