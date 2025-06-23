#!/bin/bash

# Define old and new values
NEW_NLB="E6ENV-WebServersNLB-3dc16ce9b4d9ca48.elb.us-east-1.amazonaws.com"
OLD_NLB="e6lb.dealerfire.com"
NEW_IP1="52.2.222.120"
NEW_IP2="34.206.154.172"
OLD_IP="136.179.129.162"

# Read domains from CSV
while IFS=, read -r domain; do
  [[ "$domain" == "domain" ]] && continue  # Skip header

  echo "Processing domain: $domain"

  # Get hosted zone ID
  ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$domain" --query "HostedZones[0].Id" --output text | cut -d'/' -f3)

  if [[ -z "$ZONE_ID" ]]; then
    echo "❌ No hosted zone found for $domain"
    continue
  fi

  # Get record sets
  RECORDS=$(aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID")

  # Check and update CNAME
  CNAME_NAME=$(echo "$RECORDS" | jq -r ".ResourceRecordSets[] | select(.Type==\"CNAME\" and .ResourceRecords[0].Value==\"$OLD_NLB\") | .Name")
  if [[ -n "$CNAME_NAME" ]]; then
    echo "🔁 Updating CNAME $CNAME_NAME to $NEW_NLB"
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$CNAME_NAME\",
          \"Type\": \"CNAME\",
          \"TTL\": 300,
          \"ResourceRecords\": [{\"Value\": \"$NEW_NLB\"}]
        }
      }]
    }"
  fi

# Check and update A record
  A_NAME=$(echo "$RECORDS" | jq -r ".ResourceRecordSets[] | select(.Type==\"A\" and (.ResourceRecords | map(.Value) | contains([\"$OLD_IP\"]))) | .Name")
  if [[ -n "$A_NAME" ]]; then
    echo "🔁 Updating A record $A_NAME to $NEW_IP1 and $NEW_IP2"
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$A_NAME\",
          \"Type\": \"A\",
          \"TTL\": 300,
          \"ResourceRecords\": [{\"Value\": \"$NEW_IP1\"}, {\"Value\": \"$NEW_IP2\"}]
        }
      }]
    }"
  fi

done < domains.csv