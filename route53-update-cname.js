var name = process.argv[2];
var value = process.argv[3];

var config = {
  "Comment": "CNAME update",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": name,
        "Type": "CNAME",
        "TTL": 60,
        "ResourceRecords": [{
          "Value": value
        }]
      }
    }
  ]
}

console.log(JSON.stringify(config, null, 4))
