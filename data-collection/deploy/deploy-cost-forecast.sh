#!/bin/bash

# AWS Cost Explorer Forecast Data Collection Deployment Script
# This script automates the deployment of the AWS Cost Explorer Forecast Data Collection infrastructure

set -e

# Default values
STACK_NAME="CID-CostForecast"
REGION=$(aws configure get region)
TIMEPERIOD=90
GRANULARITY="MONTHLY"
PREDICTION_INTERVAL_LEVEL=85
METRIC="BLENDED_COST"
SCHEDULE="rate(1 day)"
S3_BUCKET_PREFIX="cid-data-"
DATABASE_NAME="optimization_data"
RESOURCE_PREFIX="CID-DC-"
MANAGEMENT_ACCOUNT_ID=""
MANAGEMENT_ROLE="Lambda-Assume-Role-Management-Account"
MULTI_ACCOUNT_ROLE="Optimization-Data-Multi-Account-Role"

function display_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Deploy AWS Cost Explorer Forecast Data Collection Module"
  echo ""
  echo "Options:"
  echo "  -h, --help                           Show this help message"
  echo "  -s, --stack-name NAME               Set the CloudFormation stack name (default: $STACK_NAME)"
  echo "  -r, --region REGION                 AWS region to deploy to (default: $REGION)"
  echo "  -m, --management-account ID         AWS Management (Payer) Account ID (required)"
  echo "  -t, --timeperiod DAYS               Number of days for cost forecast (1-364, default: $TIMEPERIOD)"
  echo "  -g, --granularity GRANULARITY       Forecast granularity (DAILY|MONTHLY|YEARLY, default: $GRANULARITY)"
  echo "  -p, --prediction-level LEVEL        Prediction interval level (1-99, default: $PREDICTION_INTERVAL_LEVEL)"
  echo "  -c, --cost-metric METRIC            Cost metric (BLENDED_COST|UNBLENDED_COST|AMORTIZED_COST|NET_UNBLENDED_COST|NET_AMORTIZED_COST, default: $METRIC)"
  echo "  -e, --schedule SCHEDULE             Schedule for data collection (default: $SCHEDULE)"
  echo "  -b, --bucket-prefix PREFIX          S3 bucket prefix (default: $S3_BUCKET_PREFIX)"
  echo "  -d, --database-name NAME            Athena database name (default: $DATABASE_NAME)"
  echo "  -x, --resource-prefix PREFIX        Resource prefix (default: $RESOURCE_PREFIX)"
  echo "  -a, --management-role ROLE          Management account role name (default: $MANAGEMENT_ROLE)"
  echo "  -u, --multi-account-role ROLE       Multi-account role name (default: $MULTI_ACCOUNT_ROLE)"
  echo ""
  echo "Example:"
  echo "  $0 -m 123456789012 -r us-east-1 -t 120 -g MONTHLY"
  echo ""
}

function validate_params() {
  if [ -z "$MANAGEMENT_ACCOUNT_ID" ]; then
    echo "ERROR: Management Account ID is required."
    display_help
    exit 1
  fi

  # Validate timeperiod
  if [ "$TIMEPERIOD" -lt 1 ] || [ "$TIMEPERIOD" -gt 364 ]; then
    echo "ERROR: Timeperiod must be between 1 and 364 days."
    exit 1
  fi

  # Validate granularity
  if [[ ! "$GRANULARITY" =~ ^(DAILY|MONTHLY|YEARLY)$ ]]; then
    echo "ERROR: Granularity must be one of: DAILY, MONTHLY, YEARLY."
    exit 1
  fi

  # Validate prediction interval level
  if [ "$PREDICTION_INTERVAL_LEVEL" -lt 1 ] || [ "$PREDICTION_INTERVAL_LEVEL" -gt 99 ]; then
    echo "ERROR: Prediction interval level must be between 1 and 99."
    exit 1
  fi

  # Validate cost metric
  if [[ ! "$METRIC" =~ ^(BLENDED_COST|UNBLENDED_COST|AMORTIZED_COST|NET_UNBLENDED_COST|NET_AMORTIZED_COST)$ ]]; then
    echo "ERROR: Cost metric must be one of: BLENDED_COST, UNBLENDED_COST, AMORTIZED_COST, NET_UNBLENDED_COST, NET_AMORTIZED_COST."
    exit 1
  fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      display_help
      exit 0
      ;;
    -s|--stack-name)
      STACK_NAME="$2"
      shift 2
      ;;
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -m|--management-account)
      MANAGEMENT_ACCOUNT_ID="$2"
      shift 2
      ;;
    -t|--timeperiod)
      TIMEPERIOD="$2"
      shift 2
      ;;
    -g|--granularity)
      GRANULARITY="$2"
      shift 2
      ;;
    -p|--prediction-level)
      PREDICTION_INTERVAL_LEVEL="$2"
      shift 2
      ;;
    -c|--cost-metric)
      METRIC="$2"
      shift 2
      ;;
    -e|--schedule)
      SCHEDULE="$2"
      shift 2
      ;;
    -b|--bucket-prefix)
      S3_BUCKET_PREFIX="$2"
      shift 2
      ;;
    -d|--database-name)
      DATABASE_NAME="$2"
      shift 2
      ;;
    -x|--resource-prefix)
      RESOURCE_PREFIX="$2"
      shift 2
      ;;
    -a|--management-role)
      MANAGEMENT_ROLE="$2"
      shift 2
      ;;
    -u|--multi-account-role)
      MULTI_ACCOUNT_ROLE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      display_help
      exit 1
      ;;
  esac
done

# Validate parameters
validate_params

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

echo "========================================================"
echo "AWS Cost Explorer Forecast Data Collection Deployment"
echo "========================================================"
echo "Stack Name             : $STACK_NAME"
echo "Region                 : $REGION"
echo "Management Account ID  : $MANAGEMENT_ACCOUNT_ID"
echo "Timeperiod             : $TIMEPERIOD days"
echo "Granularity            : $GRANULARITY"
echo "Prediction Level       : $PREDICTION_INTERVAL_LEVEL"
echo "Cost Metric            : $METRIC"
echo "Schedule               : $SCHEDULE"
echo "S3 Bucket Prefix       : $S3_BUCKET_PREFIX"
echo "Database Name          : $DATABASE_NAME"
echo "Resource Prefix        : $RESOURCE_PREFIX"
echo "Management Role        : $MANAGEMENT_ROLE"
echo "Multi-Account Role     : $MULTI_ACCOUNT_ROLE"
echo "========================================================"
echo ""

# Get confirmation
read -p "Do you want to proceed with the deployment? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Deployment cancelled."
  exit 0
fi

# Deploy the stack
echo "Deploying Cost Explorer Forecast Data Collection stack..."
aws cloudformation deploy \
  --template-file "$SCRIPT_DIR/module-cost-explorer-forecast.yaml" \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ManagementAccountID="$MANAGEMENT_ACCOUNT_ID" \
    ManagementAccountRole="$MANAGEMENT_ROLE" \
    MultiAccountRoleName="$MULTI_ACCOUNT_ROLE" \
    DestinationBucket="$S3_BUCKET_PREFIX" \
    ResourcePrefix="$RESOURCE_PREFIX" \
    DatabaseName="$DATABASE_NAME" \
    Schedule="$SCHEDULE" \
    ForecastTimeperiod="$TIMEPERIOD" \
    ForecastGranularity="$GRANULARITY" \
    ForecastPredictionIntervalLevel="$PREDICTION_INTERVAL_LEVEL" \
    ForecastMetric="$METRIC" \
    CFNSourceBucket="aws-managed-cost-intelligence-dashboards"

if [ $? -eq 0 ]; then
  echo "========================================================"
  echo "Deployment successful!"
  echo "The Cost Explorer Forecast Data Collection stack has been deployed."
  echo ""
  echo "To integrate this with the main CloudFormation template,"
  echo "add the 'IncludeCostForecastModule' parameter to your"
  echo "deploy-data-collection.yaml deployment."
  echo "========================================================"
else
  echo "========================================================"
  echo "Deployment failed. Please check the CloudFormation console for details."
  echo "========================================================"
  exit 1
fi

exit 0
