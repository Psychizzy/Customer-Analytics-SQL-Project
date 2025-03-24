use market_db;
describe fooddb;
select * from fooddb
limit 5;
alter table fooddb ADD COLUMN CustomerID INT AUTO_INCREMENT PRIMARY KEY;

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

-- Customer Retention & Churn Prediction
/*we want to answeer the following 
Which customers are at risk of leaving (churn)?
What factors contribute to customer retention?
Which customer segments are more loyal?
*/

-- Identify At-Risk & Churned Customers
SELECT 
    CustomerID,
    Recency,
    MntTotal,
    TotalPurchases,
    CASE
        WHEN Recency > 90 AND TotalPurchases <= 3 THEN "Churn Cus"
        WHEN Recency > 90 THEN "At Risk Cus" 
        ELSE "Active"
    END AS Customer_status
FROM (
    SELECT 
        CustomerID,
        Recency,
        MntTotal,
        (NumStorePurchases + NumWebPurchases + NumCatalogPurchases) AS TotalPurchases
    FROM fooddb
) AS t
ORDER BY Recency DESC;

-- churn customer and churn rate by customer category

WITH CustomerChurn AS (
SELECT 
c.CustomerCategory,
COUNT(*) AS TotalCustomers,
SUM(CASE WHEN f.Recency > 90 THEN 1 ELSE 0 END) AS ChurnedCustomers
FROM CustomerSegments c
JOIN fooddb f ON c.CustomerID = f.CustomerID
GROUP BY c.CustomerCategory
)
SELECT CustomerCategory, TotalCustomers, ChurnedCustomers, ROUND((ChurnedCustomers / TotalCustomers) * 100, 2) AS ChurnRate
FROM CustomerChurn
ORDER BY ChurnRate DESC;

-- income imfluence on churn rate or customer retention

select 
case 
when income < 30000 then "low income"
when income between 30000 and 90000 then "middle income"
else "higher income"
end as income_category,
avg(MntTotal) as AvgSpending,
avg(NumStorePurchases + NumWebPurchases + NumCatalogPurchases) as AvgPurchases,
avg(Recency) as AvgRecency,
SUM(case when Recency > 90 then 1 else 0 end) as ChurnedCustomers,
COUNT(*) AS TotalCustomers,
ROUND((SUM(CASE WHEN Recency > 90 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS ChurnRate
FROM fooddb
GROUP BY income_category
ORDER BY ChurnRate DESC;


with spendingChurn as (
select 
case
when MntTotal < 500 then "low spender"
when MntTotal between 500 AND 1500 then "middle spender"
else "higher spender"
end  as spending_category,
count(*) as totalCustomer,
SUM(CASE WHEN cs.Customer_status = 'Churn Cus' THEN 1 ELSE 0 END) AS ChurnedCustomers
 FROM fooddb f
    JOIN ( SELECT CustomerID,
CASE 
WHEN Recency > 90 AND TotalPurchases <= 3 THEN "Churn Cus"
WHEN Recency > 90 THEN "At Risk Cus"
ELSE "Active"
END AS Customer_status
FROM (SELECT CustomerID, Recency, MntTotal,
(NumStorePurchases + NumWebPurchases + NumCatalogPurchases) AS TotalPurchases
FROM fooddb
) AS t
) cs ON f.CustomerID = cs.CustomerID
GROUP BY spending_category
)
SELECT 
    spending_category,
    totalCustomer,
    ChurnedCustomers,
    ROUND((ChurnedCustomers / totalCustomer) * 100, 2) AS ChurnRate
FROM SpendingChurn
ORDER BY ChurnRate DESC;

-- Marketing Campaign Effectiveness
-- Overall Campaign Performance
SELECT 
    COUNT(*) AS TotalCustomers,
    SUM(AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5) AS TotalAccepted,
    ROUND((SUM(AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5) / (COUNT(*) * 5)) * 100, 2) AS CampaignSuccessRate
FROM fooddb;

-- which Spenders category Accept More Campaigns?
SELECT 
CASE 
WHEN MntTotal < 500 THEN 'Low Spender'
WHEN MntTotal BETWEEN 500 and 1500 THEN 'Medium Spender'
ELSE 'High Spender'
END AS Spending_category,
avg(AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5) AS TotalCampaignsAccepted
FROM fooddb
GROUP BY Spending_category
ORDER BY TotalCampaignsAccepted DESC;

-- Campaign Engagement by Customer Segment
SELECT 
    c.CustomerCategory,
    COUNT(f.CustomerID) AS TotalCustomers,
    ROUND(avg(f.AcceptedCmp1 + f.AcceptedCmp2 + f.AcceptedCmp3 + f.AcceptedCmp4 + f.AcceptedCmp5), 2) AS AvgCampaignsAccepted
FROM CustomerSegments c
JOIN fooddb f ON c.CustomerID = f.CustomerID
GROUP BY c.CustomerCategory
ORDER BY AvgCampaignsAccepted DESC;

select 
    c.CustomerCategory,
ROUND(AVG(f.AcceptedCmp1) * 100, 2) AS Campaign1_Acceptance,
ROUND(AVG(f.AcceptedCmp2) * 100, 2) AS Campaign2_Acceptance,
ROUND(AVG(f.AcceptedCmp3) * 100, 2) AS Campaign3_Acceptance,
ROUND(AVG(f.AcceptedCmp4) * 100, 2) AS Campaign4_Acceptance,    
ROUND(AVG(f.AcceptedCmp5) * 100, 2) AS Campaign5_Acceptance
from CustomerSegments c
join fooddb f ON c.CustomerID = f.CustomerID
group by c.CustomerCategory
order by Campaign3_Acceptance DESC;


-- Sales Analysis
-- Sales Performance by Purchase Channels
/*Goal: Find out whether customers prefer web, store, 
or catalog purchases so businesses can optimize sales strategies.
*/ -- Which Channel is Used the Most?

select round(avg(NumDealsPurchases),2) as Avg_NumDealsPurchases,
round(avg(NumWebPurchases),2) as avg_NumWebPurchases,
round(avg(NumCatalogPurchases),2) as avg_NumCatalogPurchases,
round(avg(NumStorePurchases),2) as avg_NumStorePurchases
from fooddb;

-- Purchase Channel Preference by Customer Segment

select c.CustomerCategory,
 round(avg(NumDealsPurchases),2) as Avg_NumDealsPurchases,
round(avg(NumWebPurchases),2) as avg_NumWebPurchases,
round(avg(NumCatalogPurchases),2) as avg_NumCatalogPurchases,
round(avg(NumStorePurchases),2) as avg_NumStorePurchases
from CustomerSegments as c
join fooddb as f on c.CustomerID = f.CustomerID
group by c.CustomerCategory
order by avg_NumWebPurchases desc;

-- Which Channel Drives the Most Revenue?

select round(sum(NumDealsPurchases * MntTotal) / sum(NumDealsPurchases), 2) as RevenuePerDealsPurchases,
round(sum(NumWebPurchases * MntTotal) / sum(NumWebPurchases), 2) as RevenuePerWebPurchase,
round(sum(NumCatalogPurchases * MntTotal) / sum(NumCatalogPurchases), 2) as RevenuePerCatalogPurchase,
round(sum(NumStorePurchases * MntTotal) / sum(NumStorePurchases), 2) as RevenuePerStorePurchase
from fooddb;

-- RFM Analysis (Recency, Frequency, Monetary)
select CustomerID, Recency,
(NumWebPurchases + NumCatalogPurchases + NumStorePurchases) AS Frequency,
MntTotal AS Monetary,
NTILE(4) OVER (ORDER BY Recency ASC) AS RecencyScore,  -- Lower recency is better
NTILE(4) OVER (ORDER BY (NumWebPurchases + NumCatalogPurchases + NumStorePurchases) DESC) AS FrequencyScore,
NTILE(4) OVER (ORDER BY MntTotal DESC) AS MonetaryScore
FROM fooddb;  /* This analysis categorizes customers based on Recency (last purchase date), Frequency (number of purchases), and Monetary (total spending).
Businesses use RFM scores to identify their most valuable customers and optimize marketing.*/

-- Cross-Sell & Product Affinity Analysis
/* this Identifies popular product combinations
If a customer bought at least the "min" value of a product, they qualify as a buyer.
We focus on strong affinities (people buying both products together).*/

select 
case
when MntWines >=3 and MntMeatProducts >=6 then "wine & meat"
when MntWines >= 3 and MntSweetProducts >= 1 then "Wine & Sweets"
when MntFishProducts >= 1 and MntMeatProducts >= 6 then "Fish & Meat"
when MntGoldProds >= 3 and MntWines >= 3 then "Gold & Wine Buyers"
when MntFruits >= 1 and MntSweetProducts >= 1 then "Fruits & Sweets"
else "Others"
end as ProductCombination,
count(*) as TotalCustomers
from fooddb
group by ProductCombination
order by TotalCustomers desc;

-- High-Value Customer Prediction
/* -- Prediction of which customers will become high-value in the future
Businesses can invest in keeping these customers engaged */
    
create temporary table FutureCustomer as 
select
CustomerID,
MntTotal,
Recency,
(NumWebPurchases + NumCatalogPurchases + NumStorePurchases) as Frequency
from fooddb;
select
case
when Recency < 30 and Frequency > 5 and MntTotal > 1000 then 'Potential VIP'
ELSE 'Regular Customer'
END AS CustomerPrediction,
count(*) as TotalCustomers
from FutureCustomer
GROUP BY CustomerPrediction;    
  
  
  
-- Customer Lifetime Value (CLV) Estimation
SELECT CustomerID, MntTotal,
(MntTotal / (NumWebPurchases + NumCatalogPurchases + NumStorePurchases)) AS AvgSpendPerOrder,
(MntTotal / Recency) AS SpendPerDay,
ROUND((MntTotal * 12) / Recency, 2) AS AnnualizedCLV  -- Predicts yearly value
FROM fooddb
ORDER BY AnnualizedCLV DESC; 
/*Estimates how much revenue a customer will bring over time/*