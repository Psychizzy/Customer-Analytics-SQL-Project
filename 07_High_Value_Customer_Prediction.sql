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