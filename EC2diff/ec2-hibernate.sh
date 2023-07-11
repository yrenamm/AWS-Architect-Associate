# Create inst with hibernate option
aws ec2 run-instances --image-id ami-0272362388eae3591 --instance-type m5.large --block-device-mappings file://mapping.json --hibernation-options Configured=true --count 1 --key-name keypairsavedca

# Terminate your EC2 instances
aws ec2 terminate-instances --instance-ids i-049fca92aca8a78fd

# Delete volume
aws ec2 delete-volume --volume-id vol-04aadba4c020e335c