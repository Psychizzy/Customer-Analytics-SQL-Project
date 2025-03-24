-- High-Value Customer Prediction
-- Customer Lifetime Value (CLV) Estimation
SELECT CustomerID, MntTotal,
(MntTotal / (NumWebPurchases + NumCatalogPurchases + NumStorePurchases)) AS AvgSpendPerOrder,
(MntTotal / Recency) AS SpendPerDay,
ROUND((MntTotal * 12) / Recency, 2) AS AnnualizedCLV  -- Predicts yearly value
FROM fooddb
ORDER BY AnnualizedCLV DESC; 
/*Estimates how much revenue a customer will bring over time/*