# OD-S3-Uploader
serverless web-app that generates on-demand a limited-temporary-access file(s) uploader to AWS S3 for headless systems


## Introduction
This project builds a serverless application that generates a file uploader to
AWS S3 with temporary credentials using Simple Token Service (STS), Lambda, and
API Gateway serviced in a web application which provides a download link to
authorized users (using Cognito) of the generated uploader package. The install
package is a shell script specifically for headless systems with no browser access.

## Motivation
Oftentimes when a batch of server log files need to be sent externally, it becomes
a multi-stage process until the logs are in an analyst's hands.
For example,
1. an operations engineer goes to the server in question and aggregates
the logs
2. send to internal FTP server
3. 1 or 2 more steps until the analyst may or may not receive the data securely
4. analyst either does analysis on local system OR
5. securely uploads to the cloud where the analytics tools are (esp if data is large)

Ideally, it shouldn't be this complicated to send data and I thought I could
simplify the steps for the logs to reach into my S3 buckets securely with
auto-generated temporary credentials with strict IAM policies for limited access.

Also, I always wanted to build a serverless application and thought this would
be the perfect opportunity to build one!


## Design
![alt text](/assets/s3-uploader-arch.PNG)


## Usage
web-app
 * coming soon..

s3-uploader usage
 1. extract contents
 ```
 $ cd path/to/file/
 $ tar -xvzf s3-uploader.tar.gz
 ```
 2. give permissions to install/upload script
 ```
 $ chmod 755 install_uploader.sh
 ```
 3. execute script
 ```
 $ ./install_uploader.sh <log_directory> <log_wildcard> <target_s3_bucket>
 ```

## To do
 * front end static website
 * set up AWS cognito and integrate w/ web app
 * cloudformation for deployment
