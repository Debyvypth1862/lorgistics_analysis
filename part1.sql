-- Q1: How to find out is the average, median and 90th percentile transit time (in days) of all domestics
trade lanes in 2024?
SELECT
  AVG(EXTRACT(EPOCH FROM (final_delivery_date - picked_up_date)) / 86400) AS avg_transit_days,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (final_delivery_date - picked_up_date)) / 86400) AS median_transit_days,
  PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (final_delivery_date - picked_up_date)) / 86400) AS p90_transit_days
FROM parcel_table
WHERE is_delivered = TRUE
  AND origin_country = destination_country
  AND EXTRACT(YEAR FROM picked_up_date) = 2024;

-- Q2: What is the max transit time (in days) and how many parcels has this transit time?
WITH transit AS (
  SELECT
    parcel_id,
    EXTRACT(EPOCH FROM (final_delivery_date - picked_up_date)) / 86400 AS transit_days
  FROM parcel_table
  WHERE is_delivered = TRUE
    AND origin_country = destination_country
    AND EXTRACT(YEAR FROM picked_up_date) = 2024
)
SELECT
  MAX(transit_days) AS max_transit_days,
  COUNT(*) AS parcel_count_with_max_transit
FROM transit
WHERE transit_days = (SELECT MAX(transit_days) FROM transit);

-- Q3: Pick the top 2 carriers in terms of volume that is operating in each trade lane.
WITH ranked_carriers AS (
  SELECT
    origin_country,
    destination_country,
    carrier_name,
    COUNT(*) AS parcel_count,
    ROW_NUMBER() OVER (PARTITION BY origin_country, destination_country ORDER BY COUNT(*) DESC) AS rank
  FROM parcel_table
  GROUP BY origin_country, destination_country, carrier_name
)
SELECT
  origin_country,
  destination_country,
  carrier_name,
  parcel_count
FROM ranked_carriers
WHERE rank <= 2;

-- Q4: How to find out parcels that is delivered but has no record in log table?
SELECT
  p.parcel_id
FROM parcel_table p
LEFT JOIN (
    SELECT DISTINCT parcel_id FROM log_table
) l ON p.parcel_id = l.parcel_id
WHERE p.is_delivered = TRUE
  AND l.parcel_id IS NULL;

-- Q5: Parcels with Different Carrier Names, Concatenated into `list_of_carrier`
WITH multi_carriers AS (
  SELECT
    parcel_id,
    ARRAY_AGG(DISTINCT carrier_name ORDER BY carrier_name) AS carrier_list
  FROM parcel_table
  GROUP BY parcel_id
  HAVING COUNT(DISTINCT carrier_name) > 1
)
SELECT
  parcel_id,
  ARRAY_TO_STRING(carrier_list, '; ') AS list_of_carrier
FROM multi_carriers;
