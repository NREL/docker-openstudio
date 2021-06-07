import boto3
import os
import argparse


def image_file_name_and_s3_key(basename, version, sha=None):
    name = '%s-%s-Singularity.simg' % (basename, version)
    if sha:
        name = '%s-%s.%s-Singularity.simg' % (basename, version, sha)
    s3_key = '%s/%s' % (version, name)

    return s3_key


def main():
    print("Starting upload_s3.py")
    parser = argparse.ArgumentParser(description='Upload file to S3 with version and SHA')
    parser.add_argument('--version', default=None)
    parser.add_argument('--sha', default=None)
    args = parser.parse_args()

    if args.version is None:
        args.version = os.getenv('OPENSTUDIO_VERSION', 'latest')
    if args.sha is None:
        args.sha = os.getenv('OPENSTUDIO_SHA', None)

    print(args)
    ############# Script ################
    s3 = boto3.client('s3')
    bucket_name = 'openstudio-builds'
    filename = 'docker-openstudio.simg'
    if os.path.exists(filename):
        s3_key = image_file_name_and_s3_key('OpenStudio', args.version, args.sha)
        print("Uploading %s to %s" % (filename, s3_key))
        data = open(filename, 'rb')
        s3.put_object(Bucket=bucket_name, Key=s3_key, Body=data)


if __name__ == '__main__':
    main()
