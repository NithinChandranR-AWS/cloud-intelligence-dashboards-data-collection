# Implementation Request: Cost Forecast Dashboard for CUDOS Framework

## Background

I've implemented an automated AWS Cost Explorer forecast data collection module in the data-collection repository, which collects forecast data and stores it in an Athena-compatible format. Now, I need to integrate this data into the dashboard framework for visualization.

## Data Collection Details

The data collection module collects the following:

- AWS Cost Explorer forecast data using the `get_cost_forecast` API
- Data is stored in S3 with the following path pattern:
  - `s3://{bucket}/cost-explorer-forecast/cost-explorer-forecast-data/payer_id={id}/year={year}/month={month}/day={day}/{yyyy-mm-dd}.json`
- An Athena table named `cost_explorer_forecast_data` is created with the following schema:

```
forecastdate: string
startdate: string
enddate: string
granularity: string (DAILY, MONTHLY, or YEARLY)
metric: string (BLENDED_COST, UNBLENDED_COST, etc.)
predictionintervallevel: int (confidence level, e.g., 85)
total: struct<amount:string, unit:string>
forecastresultsbytime: array<struct<
  meanvalue:string,
  predictionintervallowerbound:string,
  predictionintervalupperbound:string,
  timeperiod:struct<start:string, end:string>>>
```

- Partitioned by: `payer_id`, `year`, `month`, `day`

## Dashboard Requirements

Please implement a Cost Forecast Dashboard with the following features:

### 1. Main Cost Forecast Visualization

- A time series chart showing:
  - Actual cost from CUR data (historical)
  - Forecast mean values (future)
  - Upper and lower confidence intervals as a shaded area
- The chart should show at least 3 months of historical data and the forecast period
- User-selectable forecast granularity (DAILY, MONTHLY, YEARLY)
- User-selectable forecast metric (BLENDED_COST, UNBLENDED_COST, etc.)

### 2. Forecast Summary Section

- Total forecasted cost for the period
- Comparison with previous period (% change)
- Monthly breakdown of forecasted costs
- Confidence level indicator

### 3. Cost Trend Analysis

- Year-over-Year comparison chart (actual vs forecast)
- Month-over-Month growth rates
- Anomaly detection indicators on the forecast line

### 4. Cost Breakdown Section

- Forecast by account (for multi-account environments)
- Forecast trend by service (if service dimension is available)
- Forecast trend by tag (if tag dimension is available)

### 5. Interactive Controls

- Date range selector
- Confidence interval selector (show/hide or adjust level)
- Granularity selector (DAILY, MONTHLY, YEARLY)
- Cost metric selector
- Account filter (for multi-account environments)

## Integration Points

- The dashboard should be accessible from the main CUDOS navigation
- Include links to Cost Optimization recommendations and other relevant dashboards
- Make the dashboard available as a standalone dashboard and as embeddable components

## Example Queries

Here are example Athena queries that can be used as a starting point:

```sql
-- Latest forecast summary query
WITH latest_forecast AS (
  SELECT
    payer_id,
    MAX(date_parse(concat(year, month, day), '%Y%m%d')) as forecast_date
  FROM
    optimization_data.cost_explorer_forecast_data
  GROUP BY
    payer_id
)

SELECT
  f.payer_id,
  f.forecastdate,
  f.startdate,
  f.enddate,
  f.granularity,
  f.metric,
  f.predictionintervallevel,
  f.total.amount as total_amount,
  f.total.unit as currency_unit
FROM
  optimization_data.cost_explorer_forecast_data f
JOIN
  latest_forecast l ON f.payer_id = l.payer_id
  AND date_parse(concat(f.year, f.month, f.day), '%Y%m%d') = l.forecast_date
```

```sql
-- Forecast details by time period query
WITH latest_forecast AS (
  SELECT
    payer_id,
    MAX(date_parse(concat(year, month, day), '%Y%m%d')) as forecast_date
  FROM
    optimization_data.cost_explorer_forecast_data
  GROUP BY
    payer_id
)

SELECT
  f.payer_id,
  result.timeperiod.start as period_start,
  result.timeperiod.end as period_end,
  CAST(result.meanvalue AS decimal(20,2)) as mean_value,
  CAST(result.predictionintervallowerbound AS decimal(20,2)) as lower_bound,
  CAST(result.predictionintervalupperbound AS decimal(20,2)) as upper_bound,
  f.total.unit as currency_unit
FROM
  optimization_data.cost_explorer_forecast_data f
  CROSS JOIN UNNEST(f.forecastresultsbytime) as t(result)
JOIN
  latest_forecast l ON f.payer_id = l.payer_id
  AND date_parse(concat(f.year, f.month, f.day), '%Y%m%d') = l.forecast_date
ORDER BY
  f.payer_id, result.timeperiod.start
```

## Technical Considerations

- The dashboard should support different forecast periods (configurable in the data collection module)
- Ensure the dashboard refreshes when new forecast data is collected
- Implement caching for better performance
- Support for download in CSV or Excel format
- Support for different currencies

## Documentation Requirements

Please include documentation on:
- How to configure and deploy the dashboard
- How to interpret the forecast data
- How to customize the visualizations
- How to integrate with other dashboards

## Timeline

Please aim to complete this implementation within the next 2-3 weeks.
