# Create inst with hibernate option
aws ec2 run-instances --image-id ami-0272362388eae**** --instance-type m5.large --block-device-mappings file://mapping.json --hibernation-options Configured=true --count 1 --key-name keypairsavedca

# Start instance
aws ec2 start-instances instance-id i-0e3db58cafde0****

# Terminate your EC2 instances
aws ec2 terminate-instances --instance-ids i-0e3db58cafde0****

# Delete volume
aws ec2 delete-volume --volume-id vol-04aadba4c020e****
