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