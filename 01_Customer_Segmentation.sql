-- Customer Segmentation (Manual Clustering Approach) We’ll divide customers into 4 equal spending groups (quartiles)

-- Recency Ranking
SELECT CustomerID, Recency,
CASE 
WHEN Recency <= 30 THEN 'Active'  -- Purchased recently
WHEN Recency BETWEEN 31 AND 90 THEN 'Moderate'  -- Mid-term customers
ELSE 'Inactive'  -- Haven't purchased in a long time
END AS RecencySegment
FROM fooddb;

       -- Spending ranking
with spendingRank as(
SELECT 
CustomerID,
MntTotal,
NTILE(4) OVER (ORDER BY MntTotal DESC) AS SpendingSegment
FROM fooddb)
select CustomerID, MntTotal,
    CASE 
WHEN SpendingSegment = 1 THEN 'High Spender'  -- Top 25% of spenders
WHEN SpendingSegment IN (2,3) THEN 'Medium Spender'  -- Middle 50%
ELSE 'Low Spender'  -- Bottom 25%
END AS SpendingCategory
FROM SpendingRank;


-- Combining Spending & Recency Segments

WITH spendingRank as (
SELECT 
CustomerID,
MntTotal,
NTILE(4) OVER (ORDER BY MntTotal DESC) AS SpendingSegment
FROM fooddb)
select s.CustomerID, MntTotal, R.Recency,
case
-- High Spenders (Top 25%)
 when s.SpendingSegment = 1 and R.Recency <=30 then "VIP COSTUMER"
 when s.SpendingSegment = 1 and R.Recency between 31 and 90 then "loyal but fading"
 when s.SpendingSegment = 1 and R.Recency > 90 then "lost VIP CUSTOMER"
-- Medium Spenders (Middle 50%)
when s.SpendingSegment in (2,3) and R.Recency <= 30 then "Regular Customer"
when s.SpendingSegment in (2,3) and R.Recency between 31 and 90 then "Potential churn"
when s.SpendingSegment in (2,3) and R.Recency > 90 then "AT RISK CUSTOMER"
-- Low Spenders (Bottom 25%)
 when s.SpendingSegment = 4 and R.Recency <=30 then "Occasional Buyer"
 else "DORMANT CUSTOMER"
 end as customer_Category
 from spendingRank s
 join (select CustomerID, Recency from fooddb) r on s.CustomerID = r.CustomerID;
 
 
 -- Customer Purchase Behavior Analysis
CREATE TEMPORARY TABLE CustomerSegments AS 
WITH spendingRank AS (
    SELECT 
        CustomerID,
        MntTotal,
        NTILE(4) OVER (ORDER BY MntTotal DESC) AS SpendingSegment
    FROM fooddb
)
SELECT 
    s.CustomerID,
    s.MntTotal,
    r.Recency,
    CASE 
        WHEN s.SpendingSegment = 1 AND r.Recency <= 30 THEN 'VIP Customer'
        WHEN s.SpendingSegment = 1 AND r.Recency BETWEEN 31 AND 90 THEN 'Loyal But Fading'
        WHEN s.SpendingSegment = 1 AND r.Recency > 90 THEN 'Lost High-Value'
        WHEN s.SpendingSegment IN (2,3) AND r.Recency <= 30 THEN 'Regular Buyer'
        WHEN s.SpendingSegment IN (2,3) AND r.Recency BETWEEN 31 AND 90 THEN 'Potential Churn'
        WHEN s.SpendingSegment IN (2,3) AND r.Recency > 90 THEN 'At-Risk Customer'
        WHEN s.SpendingSegment = 4 AND r.Recency <= 30 THEN 'Occasional Buyer'
        ELSE 'Dormant Customer'
    END AS CustomerCategory
FROM spendingRank s
JOIN (
    SELECT CustomerID, Recency FROM fooddb
) r ON s.CustomerID = r.CustomerID;

SELECT * FROM CustomerSegments;

-- Product Category Preferences by Customer Type

select c.CustomerCategory,
avg(MntWines) as avg_wine_spending,
avg(MntMeatProducts) as avg_meatprodct_spending,
avg(MntFishProducts) as avg_fishProduct_spending,
avg(MntSweetProducts) as avg_sweetproduct_spending,
avg(MntGoldProds) as avg_goldprod_spending
from CustomerSegments c
join fooddb f
on c.CustomerID = f.CustomerID
group by CustomerCategory
order by avg_wine_spending;

-- Purchase channel by customer Category
select c.CustomerCategory,
avg(NumWebPurchases) as avg_web_purchase,
avg(NumCatalogPurchases) as avg_catalog_purchase,
avg(NumStorePurchases) as avg_store_purchase,
avg(NumDealsPurchases) as avg_Deal_Purchase
from CustomerSegments c
join fooddb f
on c.CustomerID = f.CustomerID
group by CustomerCategory
order by avg_web_purchase;