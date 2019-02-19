require 'json'
require 'aws-sdk-core'
require 'aws-sdk-s3'
require 'aws-sdk-iam'

def lambda_handler(event:, context:)
    # main
    region = 'us-west-2'
    user_name = 's3putuser'

    #Identify the IAM user that is allowed to list Amazon S3 bucket items for an hour.
    user = get_user(region, user_name, true)

    # Create a new Amazon STS client and get temporary credentials. This uses a role that was already created.
    creds = Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new(region: region),
      role_arn: "arn:aws:iam::<<AWS_account_id>>:role/s3PUT",
      role_session_name: "assumerole-s3-list",
      duration_seconds: 900
    )

    ## write config file.
    file = File.open("/tmp/credentials", "w")
    file.puts "[s3uploader]"
    file.puts "aws_access_key_id = " + creds.credentials.access_key_id
    file.puts "aws_secret_access_key = " + creds.credentials.secret_access_key
    file.puts "aws_session_token = " + creds.credentials.session_token
    file.close

    ## download the config and s3-uploader.sh script
    s3 = Aws::S3::Resource.new(region: 'us-west-2')
    script_bucket = '<<source-bucket>>'

    filename = 'config'
    fileobj = s3.bucket(script_bucket).object(filename)
    fileobj.get(response_target: '/tmp/'+filename)

    filename2 = 'install_uploader.sh'
    fileobj2 = s3.bucket(script_bucket).object(filename2)
    fileobj2.get(response_target: '/tmp/'+filename2)


    ## compress and upload
    system('tar -cvzf /tmp/s3-uploader.tar.gz /tmp/*')
    filename = '/tmp/s3-uploader.tar.gz'
    bucket = '<<destination-bucket>>'

    # Get just the file name
    name = File.basename(filename)
    # Create the object to upload
    obj = s3.bucket(bucket).object(name)
    # Upload it
    obj.upload_file(filename)


    ## create a temporary download link for the package
    s3_client = Aws::S3::Client.new
    @download = Aws::S3::Object.new(
        key: name, bucket_name: bucket, client: s3_client).presigned_url(:get, expires_in: 60 * 15
    )
end

$debug = false

def print_debug(s)
  if $debug
    puts s
  end
end


def get_user(region, user_name, create)
    user = nil
    iam = Aws::IAM::Client.new(region: 'us-west-2')

    begin
      user = iam.create_user(user_name: user_name)
      iam.wait_until(:user_exists, user_name: user_name)
      print_debug("Created new user #{user_name}")
    rescue Aws::IAM::Errors::EntityAlreadyExists
      print_debug("Found user #{user_name} in region #{region}")
    end
end
