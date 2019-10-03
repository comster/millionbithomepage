#!/bin/bash

function do_delete() {
    
    aws s3 rb s3://$1 --force
    
    # Delete route 53 
    # write the configuration in json format using node to massage variables from the env
    node route-53-change-resource-record-sets.js "$1" cloudfront_url_here rm > ./route-53-change-resource-record-sets.json
    
    echo "Update Route 53 hosted zone $ROUTE_53_HOSTED_ZONE_ID, and remove A record."
    
    cat ./route-53-change-resource-record-sets-rm.json
    
    aws route53 change-resource-record-sets --hosted-zone-id $ROUTE_53_HOSTED_ZONE_ID --change-batch file://route-53-change-resource-record-sets-rm.json
}

if aws s3 ls "s3://$1" 2>&1 | grep -q 'NoSuchBucket'
then

    echo "Bucket does not exist $1"

else

    echo "Deleting bucket $1"
    
    do_delete "$1"

fi