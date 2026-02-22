-- TASK 1 – Data Preprocessing & Cleaning
-- Remove duplicates
-- Standardize date formats
-- Standardize platform names
-- Ensure numeric fields correct
-- Split hashtags

-- 1. Check raw data duplicates
SELECT COUNT(*) FROM task_1_posts_dateset;
SELECT * FROM task_1_posts_dateset LIMIT 5; 
 
-- 2. Check and remove duplicates 
 SELECT 'POST ID', COUNT(*)
 FROM task_1_posts_dateset
 GROUP BY 'POST ID'
 HAVING COUNT(*) >1;  
 
 -- 3. STANDARDIZE PLATFORM NAMES
SELECT distinct PLATFORM FROM task_1_posts_dateset; -- check first the standardize format
 
SET SQL_SAFE_UPDATES = 0;
UPDATE task_1_posts_dateset
SET PLATFORM = Lower(trim(platform));
 
 -- 4. FIX DATE FORMAT
DESCRIBE task_1_posts_dateset;
   
SELECT 'Date' FROM task_1_posts_dateset LIMIT 5;
 
ALTER TABLE task_1_posts_dateset
CHANGE COLUMN `Date` post_date DATE;

UPDATE task_1_posts_dateset
SET post_date = STR_TO_DATE(post_date, '%d/%m/%Y');

-- 5. STEP 5 – HANDLE NULL VALUES
select 
SUM(Likes is null), SUM(Shares is null), SUM(Comments is null), SUM(Impressions is null),
SUM(reach is null), SUM(clicks is null)
FROM task_1_posts_dateset;

UPDATE task_1_posts_dateset SET Likes = 0 WHERE Likes IS NULL;
UPDATE task_1_posts_dateset SET Shares = 0 WHERE Shares IS NULL;
UPDATE task_1_posts_dateset SET Comments = 0 WHERE Comments IS NULL;
UPDATE task_1_posts_dateset SET Clicks = 0 WHERE Clicks IS NULL;
UPDATE task_1_posts_dateset SET Impressions = 0 WHERE Impressions IS NULL;
UPDATE task_1_posts_dateset SET reach = 0 WHERE reach IS NULL;

-- 6. ENSURE NUMERIC TYPES
DESCRIBE  task_1_posts_dateset; -- Check data type
-- if numbers are VARCHAR, convert
ALTER TABLE task_1_posts_dateset MODIFY Likes INT;
ALTER TABLE task_1_posts_dateset MODIFY Impressions INT;
-- etc etc--

-- 7. SPLIT HASHTAGS
-- This query is doing one job:
-- Taking comma-separated hashtags from one column, -- Breaking them into separate rows, -- Inserting them into post_hashtags
CREATE TABLE post_hashtags ( Post_ID VARCHAR(50), Hashtag VARCHAR(100) );

INSERT INTO post_hashtags (`Post_ID`, Hashtag)
SELECT `Post ID`, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(`Hashtags Used`, ',', numbers.n), ',', -1)) AS Hashtag
FROM task_1_posts_dateset
JOIN (
SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
) numbers
ON CHAR_LENGTH(`Hashtags Used`) - CHAR_LENGTH(REPLACE(`Hashtags Used`, ',', '')) >= numbers.n - 1;

-- Task 2- Engagement Analysis

-- 1. Calculate average engagement rate per platform: Engagement Rate = (Likes + Shares + Comments) / Impressions
SELECT platform, SUM(Likes + Shares + Comments) / SUM(Impressions) AS avg_engagement_rate
FROM task_1_posts_dateset
GROUP BY platform;

-- 2. Identify Top 10 Myntra posts with highest engagement.
SELECT `Post id`, platform, `post text`, (likes+shares+comments) as total_engagement
FROM task_1_posts_dateset
ORDER BY total_engagement DESC
LIMIT 10;

-- 3.Total Likes, Shares, Comments by Content Type & Platform: (Content Type × Platform):This replaces pivot table in SQL.
SELECT Platform, `Content Type`,
SUM(Likes + Shares + Comments) AS total_engagement
FROM task_1_posts_dateset
GROUP BY Platform, `Content Type`;

-- 4. Average clicks per hashtags
SELECT h.Hashtag, avg(p.clicks)  as avg_clicks
FROM task_1_posts_dateset p 
JOIN post_hashtags h 
ON p.`post id`= h.Post_ID
GROUP BY hashtag
ORDER BY avg_clicks DESC;

-- 5. Which hashtag generates the highest average engagement rate.
SELECT Hashtag,
AVG((Likes + Shares + Comments)/Impressions)
FROM task_1_posts_dateset p
JOIN post_hashtags h
ON p.`Post ID` = h.Post_ID
GROUP BY Hashtag; 

-- Task 3- Platform Analysis

-- 1. Identify and rank the platform with highest engagement (e.g., Twitter for announcements vs. YouTube for product demos).
WITH platform_engagement AS (
SELECT Platform, SUM(Likes + Shares + Comments) / SUM(Impressions) AS engagement_rate
FROM task_1_posts_dateset
GROUP BY Platform
)
SELECT *, RANK() OVER (ORDER BY engagement_rate DESC) AS platform_rank
FROM platform_engagement;

-- 2. Compare follower growth rates across platforms.
WITH platform_growth AS (
SELECT Platform, SUM(New_Followers - Unfollows) AS net_growth
FROM `2_engagement summary dataset`
GROUP BY Platform
)
SELECT *, RANK() OVER (ORDER BY net_growth DESC) AS growth_rank
FROM platform_growth;

-- 4. Compare Engagement vs. Ad Spend per platform.
WITH engagement_data AS (
SELECT Platform, SUM(Likes + Shares + Comments) AS total_engagement
FROM task_1_posts_dateset
GROUP BY Platform
),
spend_data AS (
SELECT Platform, SUM(Ad_Spend) AS total_spend
FROM `2_engagement summary dataset`
GROUP BY Platform
)
SELECT e.Platform, e.total_engagement, s.total_spend, e.total_engagement / NULLIF(s.total_spend,0) AS engagement_per_spend,
RANK() OVER (ORDER BY e.total_engagement / NULLIF(s.total_spend,0) DESC) AS efficiency_rank
FROM engagement_data e
JOIN spend_data s
ON e.Platform = s.Platform;

-- 5. Recommend platform strategy:
 -- ● Should Myntra focus on Twitter + YouTube (product announcements + demos) or maintain a multi-platform strategy?
 Myntra should maintain a multi-platform strategy, but with platform specialization — not equal budget allocation.
Reasoning:
If Twitter shows high engagement for announcements → use it for awareness & quick updates.
If YouTube shows stronger engagement depth or demo performance → use it for product storytelling.
If Instagram drives higher follower growth or engagement efficiency → it cannot be ignored.
Shifting focus only to Twitter + YouTube would:
❌ Reduce reach diversity
❌ Increase dependency risk
❌ Limit audience segmentation
Correct strategy:
YouTube → Product demos (conversion intent)
Twitter → Announcements & flash campaigns (real-time engagement)
Instagram → Awareness & influencer-driven engagement
Facebook (if relevant) → Broad reach & retargeting
So:
Maintain multi-platform presence, but optimize budget allocation based on engagement efficiency and growth performance.

-- Task 4- Hashtag & Content Strategy

-- 1. Identify most frequently used Myntra hashtags.
SELECT hashtag, COUNT(*) AS usage_count
FROM post_hashtags
GROUP BY Hashtag
ORDER BY usage_count DESC;

-- 2. Compare average performance of posts containing each hashtag.
SELECT h.Hashtag, AVG((p.Likes + p.Shares + p.Comments)/p.Impressions) AS avg_engagement_rate
FROM task_1_posts_dateset p
JOIN post_hashtags h
ON p.`Post ID` = h.Post_ID
GROUP BY h.Hashtag
ORDER BY avg_engagement_rate DESC;

-- 3. Compare content performance: ● Videos ● Images ● Carousels
SELECT  `Content Type`, AVG((Likes + Shares + Comments)/Impressions) AS avg_engagement_rate
FROM task_1_posts_dateset
WHERE `Content Type` IN ('Video', 'Image', 'Carousel')
GROUP BY `Content Type`
ORDER BY avg_engagement_rate DESC;

-- 4. Recommend content type priorities per platform (e.g., videos on YouTube, Wearables images on Instagram).
SELECT Platform, `Content Type`, AVG((Likes + Shares + Comments)/Impressions) AS avg_engagement_rate
FROM task_1_posts_dateset
GROUP BY Platform, `Content Type`
ORDER BY Platform DESC;

-- 5. Classify each post into High, Medium, or Low engagement categories based on its individual engagement rate.
SELECT `Post ID`, Platform, (Likes + Shares + Comments)/Impressions AS engagement_rate,
CASE
WHEN (Likes + Shares + Comments)/Impressions >= 0.08 THEN 'High'
WHEN (Likes + Shares + Comments)/Impressions >= 0.05 THEN 'Medium'
ELSE 'Low'
END AS engagement_category
FROM task_1_posts_dateset;

-- Task 5- Campaign Effectiveness

-- 1. Calculate:
-- ● Total & Average Impressions, Likes, Clicks per Campaign.
-- (+ → to add columns row-wise: Example: (Likes + Shares + Impressions) it won’t aggregate across rows — it will just add within a single row.

SELECT Campaign_Name,
SUM(Impressions) AS total_impressions, AVG(Impressions) AS avg_impressions,
SUM(Likes) AS total_likes, AVG(Likes) AS avg_likes,
SUM(Clicks) AS total_clicks, AVG(Clicks) AS avg_clicks
FROM task_1_posts_dateset
WHERE Campaign_Name IS NOT NULL
GROUP BY Campaign_Name
ORDER BY total_impressions DESC;

-- ● Compare Engagement uplift during vs. before campaigns (e.gFashionUpgrade).
WITH campaign_period AS (SELECT Campaign_Name, Start_Date, End_Date
FROM `3_campaign metadata dataset`
),
campaign_engagement AS (
SELECT p.Campaign_Name, AVG((p.Likes + p.Shares + p.Comments)/p.Impressions) AS avg_engagement
FROM task_1_posts_dateset p
JOIN campaign_period c
ON p.post_date BETWEEN c.Start_Date AND c.End_Date
GROUP BY p.Campaign_Name
)
SELECT *, RANK() OVER (ORDER BY avg_engagement DESC) AS campaign_rank
FROM campaign_engagement;

-- 2. Insights:
-- ● Which campaign had the highest ROI (engagement vs. spend)?
SELECT p.Campaign_Name, SUM(p.Likes + p.Shares + p.Comments) AS total_engagement,
c.Total_Budget,
SUM(p.Likes + p.Shares + p.Comments) / c.Total_Budget AS engagement_per_budget
FROM task_1_posts_dateset p
JOIN `3_campaign metadata dataset` c
ON p.Campaign_Name = c.Campaign_Name
GROUP BY p.Campaign_Name, c.Total_Budget
ORDER BY engagement_per_budget DESC;

-- ● Which campaign drove the strongest follower growth?
SELECT c.Campaign_Name,  SUM(e.New_Followers - e.Unfollows) AS net_growth
FROM `2_engagement summary dataset` e
JOIN `3_campaign metadata dataset` c
ON e.Week_Start_Date BETWEEN c.Start_Date AND c.End_Date
GROUP BY c.Campaign_Name
ORDER BY net_growth DESC;

-- Task 6- Follower Retention & Loyalty

-- 1. Analyze Week-over-Week Growth per platform.
SELECT Platform, Week_Start_Date, Total_Followers,Total_Followers - LAG(Total_Followers) 
OVER (PARTITION BY Platform ORDER BY Week_Start_Date) AS weekly_growth
FROM `2_engagement summary dataset`;
-- ------------------
SELECT Platform, Week_Start_Date, (New_Followers - Unfollows) AS weekly_net_growth
FROM `2_engagement summary dataset`
ORDER BY Platform, Week_Start_Date;

-- 2. Identify the peak week of follower gain.
SELECT Platform, Week_Start_Date, (New_Followers - Unfollows) AS weekly_net_growth
FROM `2_engagement summary dataset`
ORDER BY weekly_net_growth DESC
LIMIT 1;
-- ------------------
SELECT * FROM (
SELECT Platform, Week_Start_Date, (New_Followers - Unfollows) AS weekly_net_growth,
 RANK() OVER (PARTITION BY Platform ORDER BY (New_Followers - Unfollows) DESC) AS rnk
FROM `2_engagement summary dataset`
) t
WHERE rnk = 1;

-- 3. Use moving averages to smooth growth trends.
SELECT Platform, Week_Start_Date, (New_Followers - Unfollows) AS weekly_net_growth,
AVG(New_Followers - Unfollows) OVER (PARTITION BY Platform 
ORDER BY Week_Start_Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3week
FROM `2_engagement summary dataset`;

-- 4. Correlate ad spend vs. follower growth using scatter plots.
SELECT  Platform,  Week_Start_Date, (New_Followers - Unfollows) AS weekly_net_growth,
Ad_Spend
FROM `2_engagement summary dataset`;

-- Task 7- ADVANCED STRATEGIC INSIGHTS

-- 1.DIMINISHING RETURNS ANALYSIS: Check if increasing Ad Spend leads to proportionally lower engagement growth.
-- Goal: is to Check if increasing Ad Spend leads to proportionally lower engagement growth.
WITH weekly_engagement AS(
SELECT Platform, Week_Start_Date, SUM(Ad_Spend) AS weekly_spend
FROM `2_engagement summary dataset`
GROUP BY Platform, Week_Start_Date
),
weekly_growth AS (
SELECT Platform, Week_Start_Date, (New_Followers- Unfollows) AS weekly_net_growth
FROM `2_engagement summary dataset`
)
SELECT e.Platform, e.Week_Start_Date, e.weekly_spend, g.weekly_net_growth, g.weekly_net_growth / NULLIF(weekly_spend, 0)
AS growth_per_spend
FROM weekly_engagement e
JOIN weekly_growth g 
ON e.Platform= g.Platform
AND e.Week_Start_Date= g.Week_Start_Date
ORDER BY e.Platform, e.Week_Start_Date;

-- (If growth_per_spend declines as spend increases → diminishing returns.)

-- 2. PLATFORM LEVEL ENGAGEMENT EFFICIENCY CURVE (Per ₹): 
WITH engagement_data AS (
SELECT Platform, SUM(Likes + Shares + Comments) AS total_engagement
FROM task_1_posts_dateset
GROUP BY Platform
),
spend_data AS (
SELECT Platform, SUM(Ad_Spend) AS total_spend
FROM `2_engagement summary dataset`
GROUP BY Platform
)
SELECT e.Platform, e.total_engagement, s.total_spend, e.total_engagement / NULLIF(s.total_spend,0) AS engagement_per_spend
FROM engagement_data e
JOIN spend_data s
ON e.Platform = s.Platform
ORDER BY engagement_per_spend DESC;

-- 3. CAMPAIGN FATIGUE DETECTION: If same campaign over time shows declining engagement.
SELECT Campaign_Name, post_date, (Likes + Shares + Comments)/Impressions AS engagement_rate,
LAG((Likes + Shares + Comments)/Impressions) OVER(PARTITION BY Campaign_Name ORDER BY post_date)
AS previous_engagement
FROM task_1_posts_dateset
WHERE Campaign_Name IS NOT NULL; -- it would only show me the non null value & remove the nulls

-- 4. CONTENT FATIGUE DETECTION: If same content over time shows declining engagement.
SELECT`Content Type`, post_date, (Likes + Shares + Comments)/Impressions AS engagement_rate,
LAG((Likes + Shares + Comments)/Impressions) OVER(PARTITION BY `Content Type` ORDER BY post_date)
AS previous_engagement
FROM task_1_posts_dateset
WHERE `Content Type` IS NOT NULL;

-- 5.PLATFORM SPECIALIZATION STRATEGY: Classify platforms by strength.
WITH platform_metrics AS (
SELECT Platform, SUM(Likes + Shares + Comments)/SUM(Impressions) AS engagement_rate
FROM task_1_posts_dateset
GROUP BY Platform
)
SELECT Platform, engagement_rate,
CASE
WHEN engagement_rate >= 0.08 THEN 'High Engagement Platform'
WHEN engagement_rate >= 0.05 THEN 'Moderate Engagement Platform'
ELSE 'Low Engagement Platform'
END AS platform_category
FROM platform_metrics;