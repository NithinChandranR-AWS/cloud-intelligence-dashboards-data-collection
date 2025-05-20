# AWS Cost Explorer Forecast Data Collection Module

## Overview

The Cost Explorer Forecast Data Collection module automates the collection of AWS Cost Explorer forecast data for the CUDOS framework. This module allows users to gather cost forecasting information from AWS Cost Explorer API and store it in a format compatible with Athena and QuickSight, enabling cost forecast dashboards and analysis.

## Features

- Automated collection of AWS Cost Explorer forecast data
- Configurable forecast period, granularity, confidence level, and metrics
- Daily scheduled data collection (configurable)
- Storage in both raw and Athena-compatible formats
- Seamless integration with the CUDOS framework

## Deployment Options

There are three ways to deploy the Cost Explorer Forecast Data Collection:

### Option 1: Standalone Deployment (Using the deployment script)

```bash
# Grant execution permissions to the script
chmod +x deploy-cost-forecast.sh

# Deploy with default parameters
./deploy-cost-forecast.sh -m 123456789012

# Deploy with custom parameters
./deploy-cost-forecast.sh -m 123456789012 -t 120 -g DAILY -p 90 -c UNBLENDED_COST -e "rate(1 day)"
```

### Option 2: Standalone Deployment (Using AWS CloudFormation directly)

```bash
aws cloudformation deploy \
  --template-file module-cost-explorer-forecast.yaml \
  --stack-name CID-CostForecast \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ManagementAccountID="123456789012" \
    ForecastTimeperiod=90 \
    ForecastGranularity=MONTHLY \
    ForecastPredictionIntervalLevel=85 \
    ForecastMetric=BLENDED_COST
```

### Option 3: Deployment via Main CloudFormation Template

Enable the Cost Explorer Forecast module in the main CloudFormation template by setting `IncludeCostForecastModule` to `yes` when deploying or updating the stack:

```bash
aws cloudformation deploy \
  --template-file deploy-data-collection.yaml \
  --stack-name CID-DataCollection \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ManagementAccountID="123456789012" \
    IncludeCostForecastModule=yes
```

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| ManagementAccountID | AWS Management (Payer) Account ID | - | Yes |
| ForecastTimeperiod | Number of days for which the forecast is requested (1-364) | 90 | No |
| ForecastGranularity | Granularity of the forecast (DAILY, MONTHLY, YEARLY) | MONTHLY | No |
| ForecastPredictionIntervalLevel | The confidence level for the prediction intervals (1-99) | 85 | No |
| ForecastMetric | Which metric Cost Explorer uses to create your forecast | BLENDED_COST | No |
| Schedule | EventBridge schedule to trigger the data collection | rate(1 day) | No |

## Available Metrics

- BLENDED_COST
- UNBLENDED_COST
- AMORTIZED_COST
- NET_UNBLENDED_COST
- NET_AMORTIZED_COST

## Testing

After deploying the module, you can verify that it's working correctly:

1. Check the S3 bucket for collected forecast data:
   ```bash
   aws s3 ls s3://cid-data-[YOUR-ACCOUNT-ID]/cost-explorer-forecast/cost-explorer-forecast-data/payer_id=[MGMT-ACCOUNT-ID]/year=YYYY/month=MM/day=DD/
   ```

2. Execute an Athena query to view the forecast data:
   ```sql
   SELECT * FROM optimization_data.cost_explorer_forecast_data LIMIT 10;
   ```

3. Execute the predefined Athena query to get the forecast summary:
   ```bash
   aws athena get-named-query --named-query-id [QUERY-ID] # Find the ID in the AWS console
   ```

4. Trigger the data collection manually through the Step Function console to verify the collection process.

## Troubleshooting

- **No data in S3 bucket:** Verify that the IAM roles have proper permissions to access AWS Cost Explorer API and write to S3.
- **Lambda function fails:** Check CloudWatch Logs for error messages.
- **Empty results in Athena:** Ensure that the Glue crawler has been triggered and the table exists in the Glue Data Catalog.

## Integration with Other Dashboards

The collected forecast data is available in the Athena database and can be queried by any dashboard in the CUDOS framework. QuickSight dashboards can be created to visualize and analyze the forecast data.
