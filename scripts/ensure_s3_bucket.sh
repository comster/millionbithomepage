#!/bin/bash

ACM_REGION="us-east-1"

function validate_cert() {
    # echo "validate_cert"
    # echo "$1"
    # echo "$ACM_REGION"
    
    DNS_NAME=$(aws acm describe-certificate --certificate-arn $1 --region $ACM_REGION | jq -r .Certificate.DomainValidationOptions[0].ResourceRecord.Name)
    DNS_VALUE=$(aws acm describe-certificate --certificate-arn $1 --region $ACM_REGION | jq -r .Certificate.DomainValidationOptions[0].ResourceRecord.Value)
    
    # echo $DNS_NAME
    # echo $DNS_VALUE
    
    node route53-update-cname.js "$DNS_NAME" "$DNS_VALUE" > ./route-53-update-cname.json
    
    # echo "Update Route53 hosted zone $ROUTE_53_HOSTED_ZONE_ID CNAME"
    # cat ./route-53-update-cname.json
    
    # Upsert the Route 53 A record alias
    UPDATED_CNAME_RESULT=$(aws route53 change-resource-record-sets --hosted-zone-id $ROUTE_53_HOSTED_ZONE_ID --change-batch file://route-53-update-cname.json)
    
    while [ "$CERT_STATUS" == "PENDING_VALIDATION" ]
    do
      CERT_STATUS=$(aws acm describe-certificate --certificate-arn $1 --region $ACM_REGION | jq -r .Certificate.Status)
      sleep 10
    done
}

function ensure_cert() {
    # echo "Ensure certificate for $1"
    DOMAIN_BASE=$(echo $1 | grep -o '[^.]*\.[^.]*$')
    # ACM_REGION="us-east-1"
    # echo "Wildcard certificate for $DOMAIN_BASE"
    # aws acm list-certificates --max-items 10 --region $ACM_REGION --query CertificateSummaryList[].[CertificateArn,DomainName] --output text | grep $DOMAIN_BASE | cut -f1
    AWS_ACM_ARN=$(aws acm list-certificates --max-items 10 --region $ACM_REGION --query CertificateSummaryList[].[CertificateArn,DomainName] --output text | grep $DOMAIN_BASE | cut -f1)
    # echo $AWS_ACM_ARN
    if [ -z $AWS_ACM_ARN ]; then
        # echo "Creating certificate"
        AWS_ACM_ARN=$(aws acm request-certificate --domain-name "*.$DOMAIN_BASE" --subject-alternative-names "$DOMAIN_BASE" --validation-method DNS --region $ACM_REGION --output text)
        sleep 10
    fi
    
    validate_cert "$AWS_ACM_ARN"
    
    echo $AWS_ACM_ARN
}

function do_configure() {
    
    # Set the S3 bucket as a website
    aws s3 website s3://$1/ --index-document index.html --error-document 500.html
    
    # Set the Cors config for the bucket
    aws s3api put-bucket-cors --bucket "$1" --cors-configuration file://cors_config.json
    
    # Ensure there is a cloudfront distribution
    DIST_ID=`aws cloudfront list-distributions | jq -r --arg DOMAIN_CONTAIN "$1" '.DistributionList.Items[] | select(any(.Aliases.Items; index($DOMAIN_CONTAIN)) ) | .DomainName'`
    
    if [ -z $DIST_ID ]; then
        echo "CloudFront Distribution not found!"
        
        AWS_ACM_ARN=$(ensure_cert $1)
        
        echo "Creating with cert $AWS_ACM_ARN"
        
        node cloudfront-config.js "$1" "$AWS_ACM_ARN" > ./cloudfront-config.json
        
        cat ./cloudfront-config.json
        
        DIST_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json | jq -r .Distribution.DomainName)
        
        echo "CloudFront Distribution created with DomainName: $DIST_ID"
        
    else
        echo "CloudFront Distribution DomainName: $DIST_ID"
        
        DISTRIBUTION_ID=`aws cloudfront list-distributions | jq -r --arg DOMAIN_CONTAIN "$1" '.DistributionList.Items[] | select(any(.Aliases.Items; index($DOMAIN_CONTAIN)) ) | .Id'`
        
        aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'
    fi
    
    CLOUDFRONT_HOSTED_ZONE_ID="Z2FDTNDATAQYW2"
    
    # write the configuration in json format using node to massage variables from the env
    node route-53-change-resource-record-sets.js "$1" "$DIST_ID" "$CLOUDFRONT_HOSTED_ZONE_ID" > ./route-53-change-resource-record-sets.json
    
    echo "Update Route 53 hosted zone $ROUTE_53_HOSTED_ZONE_ID"
    
    cat ./route-53-change-resource-record-sets.json
    
    # Upsert the Route 53 A record alias
    aws route53 change-resource-record-sets --hosted-zone-id $ROUTE_53_HOSTED_ZONE_ID --change-batch file://route-53-change-resource-record-sets.json
}

if aws s3 ls "s3://$1" 2>&1 | grep -q 'NoSuchBucket'
then

    echo "Setup bucket for web hosting $1"

    aws s3api create-bucket --bucket "$1" --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2 --acl "public-read"
    
    do_configure "$1"

else

    echo "Bucket already exists"
    
    do_configure "$1"

fi