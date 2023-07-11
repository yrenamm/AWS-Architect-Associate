###########Set up###########

# Get the aws cli
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

# Configure
https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html

# Test to make sure you have version 2 of the aws cli installed
aws elbv2 help

# Get the AMI id of the free tier eligible AMI: ami-0272362388eae3591
# List your VPCs
aws ec2 describe-vpcs

# Create an environment variable for your VPC
export VPC=vpc-492aea2evpc-0739d968ce911****

# Use a key pair from your existing key pairs
keypairsavedca.pem

# Create your security group
aws ec2 create-security-group --group-name MyALBSecurityGroup --description "My ALB security group"
aws ec2 create-security-group --group-name MyALBSecurityGroup --description "My ALB security group" --vpc-id vpc-492aea2evpc-0739d968ce911****

# Set environment variable for your security group
export SGID=sg-04427c5594f4d****

# Get your local IP Address
curl https://checkip.amazonaws.com

# Set an environment variable for you ip address
export IPADD=35.182.**.**

# Add ssh and HTTP rules to you inbound rules
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 22 --cidr $IPADD/32
aws ec2 authorize-security-group-ingress --group-id $SGID --protocol tcp --port 80 --cidr 0.0.0.0/0

# Create your subnets
# VPC CIDR 172.31.0.0/16
# aws ec2 create-subnet --vpc-id $VPC --availability-zone-id use1-az1 --cidr-block 172.31.128.0/20
# aws ec2 create-subnet --vpc-id $VPC --availability-zone-id use1-az2 --cidr-block 172.31.192.0/20

# List AZ in the region:
aws ec2 describe-availability-zones --region ca-central-1 --query 'AvailabilityZones[].ZoneId'

aws ec2 create-subnet --vpc-id $VPC --availability-zone-id cac1-az1 --cidr-block 172.31.128.0/20
aws ec2 create-subnet --vpc-id $VPC --availability-zone-id cac1-az2 --cidr-block 172.31.192.0/20

# Create environment variables for your subnets
export AZ1SUB=subnet-05360d7c4734d****
export AZ2SUB=subnet-0ffd9fcd47685****

# Create your EC2 instances using the AMI id of ami-0272362388eae3591 (the free tier eligible AMI), 
# two in each subnet; one for the video server and the other for the web server
aws ec2 run-instances --image-id ami-0272362388eae3591 \
      --instance-type t2.micro --count 1 --subnet-id $AZ1SUB \
      --key-name keypairsavedca --security-group-ids $SGID \
      --associate-public-ip-address --user-data file://userdata-video-server-1.txt
aws ec2 run-instances --image-id ami-0272362388eae3591 \
      --instance-type t2.micro --count 1 --subnet-id $AZ2SUB \
      --key-name keypairsavedca --security-group-ids $SGID \
      --associate-public-ip-address --user-data file://userdata-video-server-2.txt
aws ec2 run-instances --image-id ami-0272362388eae3591 \
      --instance-type t2.micro --count 1 --subnet-id $AZ1SUB \
      --key-name keypairsavedca --security-group-ids $SGID \
      --associate-public-ip-address --user-data file://userdata-web-server-1.txt
aws ec2 run-instances --image-id ami-0272362388eae3591 \
      --instance-type t2.micro --count 1 --subnet-id $AZ2SUB \
      --key-name keypairsavedca --security-group-ids $SGID \
      --associate-public-ip-address --user-data file://userdata-web-server-2.txt
	  
# Create environment variables for your EC2 instances
export VIDSERV1=i-05c54387549f2****
export VIDSERV2=i-0c813feb92334****
export WEBSERV1=i-09fa710127171****
export WEBSERV2=i-0ff5d2ae0e55f****

# Tage your instances with names
aws ec2 create-tags --resources $VIDSERV1 --tags Key="Name",Value="Video Server #1"
aws ec2 create-tags --resources $VIDSERV2 --tags Key="Name",Value="Video Server #2"
aws ec2 create-tags --resources $WEBSERV1 --tags Key="Name",Value="Web Server #1"
aws ec2 create-tags --resources $WEBSERV2 --tags Key="Name",Value="Web Server #2"

#Create your Video Load Balancer
aws elbv2 create-load-balancer --name MyALB --subnets $AZ1SUB $AZ2SUB --security-groups $SGID

# Create environment variables for your ALB ARN and DNS name
export ALBARN=arn:aws:elasticloadbalancing:ca-central-1:38487460****:loadbalancer/app/MyALB/a06802a6fb05****
export ALBDNS=MyALB-135256****.ca-central-1.elb.amazonaws.com

# Create your Target Groups
aws elbv2 create-target-group --name VideoTargets --protocol HTTP --port 80 --vpc-id $VPC
aws elbv2 create-target-group --name WebTargets --protocol HTTP --port 80 --vpc-id $VPC

# Create environment variables for your target group ARNs
export VIDTGARN=arn:aws:elasticloadbalancing:ca-central-1:38487460****:targetgroup/VideoTargets/2fa3375b5b85****
export WEBTGARN=arn:aws:elasticloadbalancing:ca-central-1:38487460****:targetgroup/WebTargets/f0e3786670e6****

# Register your EC2 instances with your Target Groups
aws elbv2 register-targets --target-group-arn $VIDTGARN --targets Id=$VIDSERV1 Id=$VIDSERV2
aws elbv2 register-targets --target-group-arn $WEBTGARN --targets Id=$WEBSERV1 Id=$WEBSERV2

# Create a listener for your ALB and give it a default Target Group of the web target group
aws elbv2 create-listener --load-balancer-arn $ALBARN --protocol HTTP \
      --port 80 --default-actions Type=forward,TargetGroupArn=$WEBTGARN
	  
# Create an environment variable for your listener ARN
export LISTARN=arn:aws:elasticloadbalancing:ca-central-1:38487460****:listener/app/MyALB/a06802a6fb05****/f2d7adfb64de****

# Verify the health of your targets in each Target Group
aws elbv2 describe-target-health --target-group-arn $VIDTGARN
aws elbv2 describe-target-health --target-group-arn $WEBTGARN

# Add path-based routing
aws elbv2 create-rule \
      --listener-arn $LISTARN \
      --priority 5 \
      --conditions file://conditions-pattern.json \
      --actions Type=forward,TargetGroupArn=$VIDTGARN

# Get your listener arns
aws elbv2 describe-rules --listener-arn $LISTARN

# Create environment variables for your rule ARNs
export VIDRULEARN=arn:aws:elasticloadbalancing:ca-central-1:38487460****:listener-rule/app/MyALB/a06802a6fb05****/f2d7adfb64de****/ae61212eddf1****


###########Test###########
echo $ALBDNS
MyALB-1352567868.ca-central-1.elb.amazonaws.com

# in browser to test default route:
http://myalb-1352567868.ca-central-1.elb.amazonaws.com/
# in browser to test video servers
http://myalb-1352567868.ca-central-1.elb.amazonaws.com/vid/


###########Clean up###########

# Delete your listener rules
aws elbv2 delete-rule --rule-arn $VIDRULEARN
aws elbv2 delete-rule --rule-arn $WEBRULEARN
# Delete your listener
aws elbv2 delete-listener --listener-arn $LISTARN

# Delete your Target Groups
aws elbv2 delete-target-group --target-group-arn $VIDTGARN
aws elbv2 delete-target-group --target-group-arn $WEBTGARN

# Delete your ALB
aws elbv2 delete-load-balancer --load-balancer-arn $ALBARN

# Terminate your EC2 instances
aws ec2 terminate-instances --instance-ids $VIDSERV1 $VIDSERV2 $WEBSERV1 $WEBSERV2

# Delete your subnets
aws ec2 delete-subnet --subnet-id $AZ1SUB
aws ec2 delete-subnet --subnet-id $AZ2SUB

# Delete your security group
aws ec2 delete-security-group --group-id $SGID

