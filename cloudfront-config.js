var arg_two = process.argv[2];
var cert_arn = process.argv[3];
var config = {
  "CallerReference": process.argv[2],
  "Comment": process.argv[2],
  "Aliases": {
    "Items": [
      process.argv[2]
    ],
    "Quantity": 1
  },
  "DefaultRootObject": "index.html",
   "Origins": {
    "Items": [
      {
        "S3OriginConfig": {
          "OriginAccessIdentity": ""
        },
        "Id": "S3-"+process.argv[2],
        "DomainName": process.argv[2]+".s3.amazonaws.com"
      }
    ],
    "Quantity": 1
  },
  "DefaultCacheBehavior": {
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "TargetOriginId": "S3-"+process.argv[2],
    "ViewerProtocolPolicy": "redirect-to-https",
    "ForwardedValues": {
      "Headers": {
        "Quantity": 0
      },
      "Cookies": {
        "Forward": "none"
      },
      "QueryString": false
    },
    "SmoothStreaming": false,
    "AllowedMethods": {
      "Items": [
        "HEAD",
        "GET"
      ],
      "CachedMethods": {
        "Items": [
          "HEAD",
          "GET"
        ],
        "Quantity": 2
      },
      "Quantity": 2
    },
    "MinTTL": 0
  },
  "CacheBehaviors": {
    "Quantity": 0
  },
  "Logging": {
    "Enabled": false,
    "IncludeCookies": true,
    "Bucket": "",
    "Prefix": ""
  },
  "PriceClass": "PriceClass_All",
  "Enabled": true,
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": false,
    // "IAMCertificateId": "string",
    "ACMCertificateArn": cert_arn,
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.1_2016",
    // "Certificate": "string",
    "CertificateSource": "acm"
  }
}

console.log(JSON.stringify(config, null, 4))