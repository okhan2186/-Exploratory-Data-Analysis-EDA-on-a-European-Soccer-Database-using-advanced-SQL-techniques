Count the categories:
-- Count rows with each priority 
SELECT priority,count(*)
  from evanston311
 group by priority;
 
-- Find values of zip that appear in at least 100 rows
-- Also get the count of each value
SELECT zip, count(*)
  FROM evanston311
 GROUP BY zip
HAVING count(*)>=100; 

-- Find values of source that appear in at least 100 rows
-- Also get the count of each value
SELECT source,count(*)
  FROM evanston311
 group by source
 having count(*)>=100;
 
 -- Find the 5 most common values of street and the count of each
SELECT street, count(*)
  FROM evanston311
 group by street
 order by count(*) desc 
 limit 5;
 
 
Spotting character data problems: There are sometimes extra spaces at the beginning and end of values


Trimming:
SELECT distinct street,
       -- Trim off unwanted characters from street
       trim(street, '0123456789 #/.') AS cleaned_street
  FROM evanston311
 ORDER BY street;
 
 
 Exploring unstructured text:
 -- Count rows
SELECT count(*)
  FROM evanston311
 -- Where description includes trash or garbage
 WHERE description ilike '%trash%'
    or description ilike '%garbage%';
    
  -- Select categories containing Trash or Garbage
SELECT category
  FROM evanston311
 -- Use LIKE
 WHERE category like '%Trash%'
    or category like '%Garbage%';
    
 -- Count rows
SELECT count(*)
  FROM evanston311 
 -- description contains trash or garbage
 WHERE (description ilike '%trash%'
    OR description ilike '%garbage%') 
 -- category does not contain trash or garbage
   AND category NOT LIKE '%Trash%'
   AND category NOT LIKE '%Garbage%';
   
  -- Count rows with each category
SELECT category, count(*)
  FROM evanston311 
 WHERE (description ILIKE '%trash%'
    OR description ILIKE '%garbage%') 
   AND category NOT LIKE '%Trash%'
   AND category NOT LIKE '%Garbage%'
 -- What are you counting?
 GROUP BY category
 --- order by most frequent values
 ORDER BY count(*) desc
 LIMIT 10;
 
 
 Concatenate strings:
-- Concatenate house_num, a space, and street
-- and trim spaces from the start of the result
SELECT ltrim(concat(house_num,' ',street)) AS address
  FROM evanston311;
  
  
 Split strings on a delimiter:
 -- Select the first word of the street value
SELECT split_part(street,' ',1) AS street_name, 
       count(*)
  FROM evanston311
 GROUP BY street_name
 ORDER BY count DESC
 LIMIT 20;
 
 
 Shorten long strings:
 -- Select the first 50 chars when length is greater than 50
SELECT CASE WHEN length(description) > 50
            THEN left(description, 50) || '...'
       -- otherwise just select description
       ELSE description
       END
  FROM evanston311
 -- limit to descriptions that start with the word I
 WHERE description like 'I %'
 ORDER BY description;
 
 
 Create an "other" category with CASE WHEN:
-- 2) Use a case when statement to group zip codes 
-- with zipcount less than 100 in an 'other' category
SELECT CASE WHEN zipcount < 100 THEN 'other' 
       -- Cases where count is at least 100 
       -- should remain the same zip value
       ELSE zip
       -- End the statement and name the column created
       -- by the case when statement
       END AS zip_recoded,
       -- 3) Sum counts by recoded zip codes to get the total 
       -- for the other category
       SUM(zipcount) AS zipsum
  -- 1) Write the subquery to get each zip code 
  -- and the count of requests as zipcount
  FROM (SELECT zip, count(*)  AS zipcount
          FROM evanston311
         GROUP BY zip) AS fullcounts
 -- 4a) Group by the recoded zip code column
 GROUP BY zip_recoded
 -- 4b) Order so that most frequent recoded zip codes are first
 ORDER BY zipsum desc;


Group and recode values:
-- Fill in the command below with the name of the temp table
DROP TABLE IF EXISTS recode;
-- Create and name the temporary table
CREATE temp table recode AS
-- Write the select query to generate the table 
-- with distinct values of category and standardized values
  SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
    -- What table are you selecting the above values from?
    FROM evanston311;
-- Look at a few values before the next step
SELECT DISTINCT standardized 
  FROM recode
 WHERE standardized LIKE 'Trash%Cart'
    OR standardized LIKE 'Snow%Removal%';
    
-- Code from previous step
DROP TABLE IF EXISTS recode;
CREATE TEMP TABLE recode AS
  SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
    FROM evanston311;
-- Update to group trash cart values
UPDATE recode 
   SET standardized='Trash Cart' 
 WHERE standardized like 'Trash%Cart';
-- Update to group snow removal values
UPDATE recode 
   set standardized='Snow Removal' 
 WHERE standardized like 'Snow%Removal%';
-- Examine effect of updates
SELECT DISTINCT standardized 
  FROM recode
 WHERE standardized LIKE 'Trash%Cart'
    OR standardized LIKE 'Snow%Removal%';
    
   SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
    FROM evanston311;
UPDATE recode SET standardized='Trash Cart' 
 WHERE standardized LIKE 'Trash%Cart';
UPDATE recode SET standardized='Snow Removal' 
 WHERE standardized LIKE 'Snow%Removal%';
-- Update to group unused/inactive values
UPDATE recode
   SET standardized='UNUSED' 
 WHERE standardized IN ('THIS REQUEST IS INACTIVE...Trash Cart', 
                '(DO NOT USE) Water Bill',
               'DO NOT USE Trash', 
               'NO LONGER IN USE');
-- Examine effect of updates
SELECT DISTINCT standardized 
  FROM recode
 ORDER BY standardized;
 
 -- Code from previous step
DROP TABLE IF EXISTS recode;
CREATE TEMP TABLE recode AS
  SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
  FROM evanston311;
UPDATE recode SET standardized='Trash Cart' 
 WHERE standardized LIKE 'Trash%Cart';
UPDATE recode SET standardized='Snow Removal' 
 WHERE standardized LIKE 'Snow%Removal%';
UPDATE recode SET standardized='UNUSED' 
 WHERE standardized IN ('THIS REQUEST IS INACTIVE...Trash Cart', 
               '(DO NOT USE) Water Bill',
               'DO NOT USE Trash', 'NO LONGER IN USE');
-- Select the recoded categories and the count of each
SELECT standardized, count(*)
-- From the original table and table with recoded values
  FROM evanston311 
       left JOIN recode  
       -- What column do they have in common?
       ON  evanston311.category=recode.category
 -- What do you need to group by to count?
 GROUP BY standardized
 -- Display the most common val values first
 ORDER BY count desc;
 
 
 Create a table with indicator variables:
 -- To clear table if it already exists
DROP TABLE IF EXISTS indicators;
-- Create the indicators temp table
CREATE TEMP TABLE indicators AS
  -- Select id
  SELECT id, 
         -- Create the email indicator (find @)
         CAST (description LIKE '%@%' AS integer) AS email,
         -- Create the phone indicator
         CAST (description LIKE '%___-___-____%' AS integer) AS phone 
    -- What table contains the data? 
    FROM evanston311;
-- Inspect the contents of the new temp table
SELECT *
  FROM indicators;
  
  -- To clear table if it already exists
DROP TABLE IF EXISTS indicators;
-- Create the temp table
CREATE TEMP TABLE indicators AS
  SELECT id, 
         CAST (description LIKE '%@%' AS integer) AS email,
         CAST (description LIKE '%___-___-____%' AS integer) AS phone 
    FROM evanston311;
  
-- Select the column you'll group by
SELECT priority,
       -- Compute the proportion of rows with each indicator
       sum(email)/count(*)::numeric AS email_prop, 
       sum(phone)/count(*)::numeric AS phone_prop
  -- Tables to select from
  FROM evanston311
       left JOIN indicators
       -- Joining condition
       ON evanston311.id=indicators.id
 -- What are you grouping by?
 GROUP BY priority;



Division:
-- Select average revenue per employee by sector
SELECT sector, 
       avg(revenues/employees::numeric) AS avg_rev_employee
  FROM fortune500
 GROUP BY sector
 -- Use the column alias to order the results
 ORDER BY avg_rev_employee;
 
 
 Explore with division:
 -- Divide unanswered_count by question_count
SELECT unanswered_count/question_count::numeric AS computed_pct, 
       -- What are you comparing the above quantity to?
       unanswered_pct
  FROM stackoverflow
 -- eliminate rows where question_count is not 0
 WHERE question_count != 0
 Limit 10;
 
 
Summarize numeric columns:
-- Select min, avg, max, and stddev of fortune500 profits
SELECT min(profits),
       avg(profits),
       max(profits),
       stddev(profits)
  FROM fortune500;
  
  -- Select min, avg, max, and stddev of fortune500 profits
SELECT min(profits),
       avg(profits),
       max(profits),
       stddev(profits)
  FROM fortune500
  group by sector
  order by avg;
 
 
 Summarize group statistics:
 -- Compute standard deviation of maximum values
SELECT stddev(maxval),
	   -- min
       min(maxval),
       -- max
       max(maxval),
       -- avg
       avg(maxval)
  -- Subquery to compute max of question_count by tag
  FROM (SELECT max(question_count) AS maxval
          FROM stackoverflow
         -- Compute max by...
         GROUP BY tag) AS max_results; -- alias for subquery
         
   
Truncate:
-- Truncate employees
SELECT trunc(employees,- 5) AS employee_bin,
       -- Count number of companies with each truncated value
       count(*)
  FROM fortune500
 -- Use alias to group
 GROUP BY employee_bin
 -- Use alias to order
 ORDER BY employee_bin;
 
 -- Truncate employees
SELECT trunc(employees, -4) AS employee_bin,
       -- Count number of companies with each truncated value
       count(*)
  FROM fortune500
 -- Limit to which companies?
 WHERE employees < 100000
 -- Use alias to group
 GROUP BY employee_bin
 -- Use alias to order
 ORDER BY employee_bin;


Generate series:
-- Select the min and max of question_count
SELECT min(question_count), 
       max(question_count)
  -- From what table?
  FROM stackoverflow
 -- For tag dropbox
 where tag='dropbox';
 
 -- Create lower and upper bounds of bins
SELECT generate_series(2200, 3050, 50) AS lower,
       generate_series(2250, 3100, 50) AS upper;
       
-- Bins created in previous step
WITH bins AS (
      SELECT generate_series(2200, 3050, 50) AS lower,
             generate_series(2250, 3100, 50) AS upper),
     -- subset stackoverflow to just tag dropbox
     dropbox AS (
      SELECT question_count 
        FROM stackoverflow
       WHERE tag='dropbox') 
-- select columns for result
SELECT lower, upper, count(question_count) 
  -- from bins created above
  FROM bins
       -- join to dropbox and keep all rows from bins
       left JOIN dropbox
       -- Compare question_count to lower and upper
         ON question_count >= lower 
        AND question_count <  upper
 -- Group by lower and upper to count values in each bin
 GROUP BY lower, upper
 -- Order by lower to put bins in order
 ORDER BY lower;
 
 
 Correlation:
 -- Correlation between revenues and profit
SELECT corr(revenues,profits) AS rev_profits,
	   -- Correlation between revenues and assets
       corr(revenues,assets) AS rev_assets,
       -- Correlation between revenues and equity
       corr(revenues,equity) AS rev_equity 
  FROM fortune500;
  
  
Mean and Median:
-- What groups are you computing statistics by?
SELECT sector,
       -- Select the mean of assets with the avg function
       avg(assets) AS mean,
       -- Select the median
       percentile_disc(0.5) within group (order by assets) AS median
  FROM fortune500
 -- Computing statistics for each what?
 GROUP BY sector
 -- Order results by a value of interest
 ORDER BY mean;
 
 
Create a temp table:
 -- To clear table if it already exists;
-- fill in name of temp table
DROP TABLE IF EXISTS profit80;
-- Create the temporary table
create temp table profit80 AS 
  -- Select the two columns you need; alias as needed
  SELECT sector, 
         percentile_disc(0.8) within group (order by profits) AS pct80
    -- What table are you getting the data from?
    from fortune500
   -- What do you need to group by?
   group by sector;   
-- See what you created: select all columns and rows 
-- from the table you created
SELECT * 

-- Code from previous step
DROP TABLE IF EXISTS profit80;
CREATE TEMP TABLE profit80 AS
  SELECT sector, 
         percentile_disc(0.8) WITHIN GROUP (ORDER BY profits) AS pct80
    FROM fortune500 
   GROUP BY sector;
-- Select columns, aliasing as needed
SELECT title, fortune500.sector, 
       profits, profits/pct80 AS ratio
-- What tables do you need to join?  
  FROM fortune500 
       LEFT JOIN profit80
-- How are the tables joined?
       ON fortune500.sector=profit80.sector
-- What rows do you want to select?
 WHERE profits > pct80;
 
 
Create a temp table to simplify a query:
-- To clear table if it already exists
DROP TABLE IF EXISTS startdates;

-- Create temp table syntax
CREATE temp table startdates AS
-- Compute the minimum date for each what?
SELECT tag,
       min(date) AS mindate
  FROM stackoverflow
 -- What do you need to add to get a date for each tag?
 group by tag;
 
 -- Look at the table you created
 SELECT * 
   FROM startdates;
   
  -- To clear table if it already exists
DROP TABLE IF EXISTS startdates;

CREATE TEMP TABLE startdates AS
SELECT tag, min(date) AS mindate
  FROM stackoverflow
 GROUP BY tag;
 
-- Select tag and mindate
SELECT startdates.tag, 
       mindate, 
       -- Select question count on the first and last days
	   a.question_count AS min_date_question_count,
       b.question_count AS max_date_question_count,
       -- Compute the difference of above 
       b.question_count - a.question_count AS change
  -- Join startdates and one copy of stackoverflow
  FROM startdates
       INNER JOIN stackoverflow AS a
          ON startdates.tag=a.tag
         -- Condition for matching mindate
         AND startdates.mindate=a.date
       -- Join other copy of stackoverflow
       INNER JOIN stackoverflow AS b
          ON startdates.tag=b.tag
         -- Condition for matching last date
         AND b.date='2018-09-25';
         
         
Insert into a temp table:
DROP TABLE IF EXISTS correlations;
-- Create temp table 
create temp table correlations AS
-- Select each correlation
SELECT 'profits'::varchar AS measure,
       -- Compute correlations
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;
  
 DROP TABLE IF EXISTS correlations;
CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;
-- Add a row for profits_change
-- Insert into what table?
INSERT INTO correlationS
-- Follow the pattern of the select statement above
-- Using profits_change instead of profits
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;
INSERT INTO correlations
-- Repeat the above, but for revenues_change
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;
  
  DROP TABLE IF EXISTS correlations;
CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;
INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;
INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;
-- Select each column, rounding the correlations
SELECT measure, 
      round(profits::numeric,2) AS profits,
       round(profits_change::numeric,2) AS profits_change,
       round(revenues_change::numeric,2) AS revenues_change
  FROM correlations;
  
  
Explore table sizes: stackoverflow has the most rows; fortune500 has the most columns


Count missing values:
-- Select the count of the number of rows
SELECT count(*)
  FROM fortune500;
  
 -- Select the count of ticker, 
-- subtract from the total number of rows, 
-- and alias as missing
SELECT count(*) - count(ticker) AS missing
  FROM fortune500;
  
--Select the count of profits_change, 
-- subtract from total number of rows, and alias as missing
select count(*)-count(profits_change) as missing
from fortune500

-- Select the count of industry, 
-- subtract from total number of rows, and alias as missing
select count(*)-count(industry) as missing
from fortune500


Join tables
SELECT company.name
-- Table(s) to select from
  FROM company
       inner join fortune500
       on company.ticker=fortune500.ticker;
       
       
Foreign keys:stackoverflow.tag contains duplicate values


Read an entity relationship diagram:
-- Count the number of tags with each type
SELECT type, count(tag) AS count
  FROM tag_type
 -- To get the count for each type, what do you need to do?
 group by type
 -- Order the results with the most common
 -- tag types listed first
 order by count desc;
 
--- Select the 3 columns desired
SELECT company.name, tag_type.tag, tag_type.type
  FROM company
  	   -- Join to the tag_company table
       inner JOIN tag_company 
       ON company.id = tag_company.company_id
       -- Join to the tag_type table
       inner JOIN tag_type
       ON tag_company.tag = tag_type.tag
  -- Filter to most common type
  WHERE type='cloud';
  
Coalesce:
-- Use coalesce
SELECT coalesce(industry, sector, 'Unknown') AS industry2,
       -- Don't forget to count!
       count(*) 
  FROM fortune500 
-- Group by what? (What are you counting by?)
 GROUP BY industry2
-- Order results to see most common first
 order by count desc
-- Limit results to get just the one value you want
 limit 1;
 
 
Coalesce with a self-join:
SELECT company_original.name, title, rank
  -- Start with original company information
  FROM company AS company_original
       -- Join to another copy of company with parent
       -- company information
	   LEFT JOIN company AS company_parent
       ON company_original.parent_id = company_parent.id 
       -- Join to fortune500, only keep rows that match
       inner JOIN fortune500 
       -- Use parent ticker if there is one, 
       -- otherwise original ticker
       ON coalesce(company_original.ticker, 
                   company_parent.ticker) = 
             fortune500.ticker
 -- For clarity, order by rank
 ORDER BY rank; 
 
 
Effects of casting:
-- Select the original value
SELECT profits_change, 
	   -- Cast profits_change
       CAST(profits_change as integer) AS profits_change_int
  FROM fortune500;
  
  --Divide 10 by 3
SELECT 10/3, 
       -- Divide 10 cast as numeric by 3
       10::numeric/3;
       
SELECT '3.2'::numeric,
       '-123'::numeric,
       '1e3'::numeric,
       '1e-3'::numeric,
       '02314'::numeric,
       '0002'::numeric;
       
  
Summarize the distribution of numeric values:
-- Select the count of each value of revenues_change
SELECT revenues_change,count(*)
  FROM fortune500
 group by revenues_change
 -- order by the values of revenues_change
 ORDER BY revenues_change;
 
-- Select the count of each revenues_change integer value
SELECT revenues_change::integer, count(*)
  FROM fortune500
 group by revenues_change::integer
 -- order by the values of revenues_change
 ORDER BY revenues_change;
 
 -- Count rows 
SELECT count(*)
  FROM fortune500
 -- Where...
 WHERE revenues_change > 0;


Which date format below conforms to the ISO 8601 standard?:June 15, 2018 3:30pm


Date comparisons:
-- Count requests created on January 31, 2017
SELECT count(*) 
  FROM evanston311
 WHERE date_created::date = '2017-01-31';
 
 -- Count requests created on February 29, 2016
SELECT count(*)
  FROM evanston311 
 WHERE date_created >= '2016-02-29' 
   AND date_created < '2016-03-01';
   
-- Count requests created on March 13, 2017
SELECT count(*)
  FROM evanston311
 WHERE date_created >= '2017-03-13'
   AND date_created < '2017-03-13'::date +1;
   
   
Date arithmetic:
-- Subtract the min date_created from the max
SELECT max(date_created)-min(date_created)
  FROM evanston311;
  
-- How old is the most recent request?
SELECT now()-max(date_created)
  FROM evanston311;
  
 -- Add 100 days to the current timestamp
SELECT now()+'100 days'::interval;

-- Select the current timestamp, 
-- and the current timestamp + 5 minutes
SELECT now()+'5 minutes'::interval;


Completion time by category:
-- Select the category and the average completion time by category
SELECT category, 
       avg(date_completed-date_created) AS completion_time
  FROM evanston311
  group by category
 -- Order the results
 ORDER BY completion_time desc;
 
 
Date parts:
-- Extract the month from date_created and count requests
SELECT date_part('month',date_created) AS month, 
       count(*)
  FROM evanston311
 -- Limit the date range
 WHERE date_created >= '2016-01-01'
   AND date_created < '2018-01-01'
 -- Group by what to get monthly counts?
 GROUP BY month;
 
 -- Get the hour and count requests
SELECT date_part('hour',date_created) AS hour,
       count(*)
  FROM evanston311
 GROUP BY hour
 -- Order results to select most common
 ORDER BY count desc
 LIMIT 1;
 
-- Count requests completed by hour
SELECT date_part('hour',date_completed) AS hour,
       count(*)
  FROM evanston311
 group by hour
 order by count;
 
 
 Variation by day of week:
 -- Select name of the day of the week the request was created 
SELECT to_char(date_created, 'day') AS day, 
       -- Select avg time between request creation and completion
       avg(date_completed -date_created) AS duration
  FROM evanston311 
 -- Group by the name of the day of the week (use the alias) and 
 -- integer value of day of week 
 GROUP BY day, EXTRACT(dow from date_created)
 -- Order by integer value of the day of the week
 ORDER BY EXTRACT(dow from date_created);
 
 
 Date truncation:
 -- Aggregate daily counts by month
SELECT date_trunc('month',day) AS month,
       avg(count)
  -- Subquery to compute daily counts
  FROM (SELECT date_trunc('day',date_created) AS day,
               count(*) AS count
          FROM evanston311
         GROUP BY day) AS daily_count
 GROUP BY month
 ORDER BY month;
 
 
 Find missing dates:
 SELECT day
-- Subquery to generate all dates
-- from min to max date_created
  FROM (SELECT generate_series(min(date_created),
                               max(date_created),
                               '1 day')::date AS day
          -- What table is date_created in?
          FROM evanston311) AS all_dates
-- Select dates (day from above) that are NOT IN the subquery
 WHERE day not in  
       -- Subquery to select all date_created values as dates
       (SELECT date_created::date
          FROM evanston311);
          
       
Custom aggregation periods:
-- Generate 6 month bins covering 2016-01-01 to 2018-06-30
-- Create lower bounds of bins
SELECT generate_series('2016-01-01',  -- First bin lower value
                       '2018-01-01',  -- Last bin lower value
                       '6 months'::interval) AS lower,
-- Create upper bounds of bins
       generate_series('2016-07-01',  -- First bin upper value
                       '2018-07-01',  -- Last bin upper value
                       '6 months'::interval) AS upper;
                    
-- Count number of requests made per day 
SELECT day, count(date_created) AS count
-- Use a daily series from 2016-01-01 to 2018-06-30 
-- to include days with no requests
  FROM (SELECT generate_series('2016-01-01',  -- series start date
                               '2018-06-30',  -- series end date
                               '1 day'::interval)::date AS day) AS daily_series
       LEFT JOIN evanston311
       -- match day from above (which is a date) to date_created
       ON day = date_created::date
 GROUP BY day;
 
-- Bins from Step 1
WITH bins AS (
	 SELECT generate_series('2016-01-01',
                            '2018-01-01',
                            '6 months'::interval) AS lower,
            generate_series('2016-07-01',
                            '2018-07-01',
                            '6 months'::interval) AS upper),
-- Daily counts from Step 2
     daily_counts AS (
     SELECT day, count(date_created) AS count
       FROM (SELECT generate_series('2016-01-01',
                                    '2018-06-30',
                                    '1 day'::interval)::date AS day) AS daily_series
            LEFT JOIN evanston311
            ON day = date_created::date
      GROUP BY day)
-- Select bin bounds and median of count
SELECT lower, 
       upper, 
       percentile_disc(0.5) WITHIN GROUP (ORDER BY count) AS median
-- Join bins and daily_counts
  FROM bins
       LEFT JOIN daily_counts
-- Where the day is between the bin bounds
       ON day >= lower
          AND day < upper
-- Group by bin bounds
 GROUP BY lower, upper
 ORDER BY lower;
 
 
Monthly average with missing dates:
--generate series with all days from 2016-01-01 to 2018-06-30
WITH all_days AS 
     (SELECT generate_series('2016-01-01',
                             '2018-06-30',
                             '1 day'::interval) AS date),
     -- Subquery to compute daily counts
     daily_count AS 
     (SELECT date_trunc('day', date_created) AS day,
             count(*) AS count
        FROM evanston311
       GROUP BY day)
-- Aggregate daily counts by month using date_trunc
SELECT date_trunc('month',date) AS month,
       -- Use coalesce to replace NULL count values with 0
       avg(coalesce(count, 0)) AS average
  FROM all_days
       LEFT JOIN daily_count
       -- Joining condition
       ON all_days.date=daily_count.day
 GROUP BY month
 ORDER BY month; 
 
 
Longest gap:
-- Compute the gaps
WITH request_gaps AS (
        SELECT date_created,
               -- lead or lag
               lag(date_created) OVER (order by date_created) AS previous,
               -- compute gap as date_created minus lead or lag
               date_created - lag(date_created) OVER (order by date_created) AS gap
          FROM evanston311)
-- Select the row with the maximum gap
SELECT *
  FROM request_gaps
-- Subquery to select maximum gap from request_gaps
 WHERE gap = (SELECT max(gap)
                FROM request_gaps);
                
 
Rats!
-- Truncate the time to complete requests to the day
SELECT date_trunc('day',date_completed-date_created) AS completion_time,
-- Count requests with each truncated time
       count(*)
  FROM evanston311
-- Where category is rats
 WHERE category = 'Rodents- Rats'
-- Group and order by the variable of interest
 GROUP BY completion_time
 ORDER BY completion_time;
 
 SELECT category, 
       -- Compute average completion time per category
       avg(date_completed-date_created) AS avg_completion_time
  FROM evanston311
-- Where completion time is less than the 95th percentile value
 WHERE (date_completed-date_created) < 
-- Compute the 95th percentile of completion time in a subquery
         (SELECT percentile_disc(0.95) WITHIN GROUP (order by date_completed-date_created)
            FROM evanston311)
 GROUP BY category
-- Order the results
 ORDER BY avg_completion_time DESC;
 
-- Compute correlation (corr) between 
-- avg_completion time and count from the subquery
SELECT corr(avg_completion, count)
  -- Convert date_created to its month with date_trunc
  FROM (SELECT date_trunc('month', date_created) AS month, 
               -- Compute average completion time in number of seconds           
               avg(EXTRACT(epoch FROM date_completed - date_created)) AS avg_completion, 
               -- Count requests per month
               count(*) AS count
          FROM evanston311
         -- Limit to rodents
         WHERE category='Rodents- Rats' 
         -- Group by month, created above
         GROUP BY month) 
         -- Required alias for subquery 
         AS monthly_avgs;
         
-- Compute monthly counts of requests created
WITH created AS (
       SELECT date_trunc('month',date_created) AS month,
              count(*) AS created_count
         FROM evanston311
        WHERE category='Rodents- Rats'
        GROUP BY month),
-- Compute monthly counts of requests completed
      completed AS (
       SELECT date_trunc('month',date_completed) AS month,
              count(*) AS completed_count
         FROM evanston311
        WHERE category='Rodents- Rats'
        GROUP BY month)
-- Join monthly created and completed counts
SELECT created.month, 
       created_count, 
       completed_count
  FROM created
       INNER JOIN completed
       ON created.month=completed.month
 ORDER BY created.month;
  
