import boto3
import os
import argparse

parser = argparse.ArgumentParser(description='Upload file to S3 with version and SHA')
parser.add_argument('--version', default=None)
parser.add_argument('--sha', default=None)
args = parser.parse_args()

if args.version is None:
    args.version = os.getenv('OPENSTUDIO_VERSION', 'latest')
if args.sha is None:
    args.sha = os.getenv('OPENSTUDIO_SHA', None)

def image_file_name_and_s3_key(basename, version, sha=None):
    name = '%s-%s-Singularity.simg' % (basename, version)
    if sha:
        name = '%s-%s.%s-Singularity.simg' % (basename, version, sha)
    s3_key = '%s/%s' % (version, name)

    return name, s3_key

############# Script ################
s3 = boto3.client('s3')
bucket_name = 'openstudio-builds'
filename = 'docker-openstudio.simg'
if os.path.exists(filename):
    new_name, s3_key = image_file_name_and_s3_key(filename, args.version, args.sha)
    data = open(filename, 'rb')
    s3.put_object(Bucket=bucket_name, Key=s3_key, Body=data)
