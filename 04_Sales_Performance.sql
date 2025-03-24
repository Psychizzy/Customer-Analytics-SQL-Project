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