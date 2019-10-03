var CLOUDFRONT_HOSTED_ZONE_ID = process.argv[4];
var config = {
  "Comment": "Alias to our bucket",
  "Changes": [
    {
        "Action": process.argv[5] ? "DELETE" : "UPSERT",
        "ResourceRecordSet": {
        "Name": process.argv[2], // process.argv[2].substr(0,process.argv[2].indexOf('.')),
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": CLOUDFRONT_HOSTED_ZONE_ID, // s3-website-us-west-2.amazonaws.com.
          "DNSName": process.argv[3], //'s3-website-us-west-2.amazonaws.com',//"DNS domain name for your CloudFront distribution, Amazon S3 bucket, Elastic Load Balancing load balancer, or another resource record set in this hosted zone", // http://staging.myroads.app.s3-website-us-west-2.amazonaws.com/#/
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}

console.log(JSON.stringify(config, null, 4))
