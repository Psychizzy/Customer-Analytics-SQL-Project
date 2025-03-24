-- RFM Analysis (Recency, Frequency, Monetary)
select CustomerID, Recency,
(NumWebPurchases + NumCatalogPurchases + NumStorePurchases) AS Frequency,
MntTotal AS Monetary,
NTILE(4) OVER (ORDER BY Recency ASC) AS RecencyScore,  -- Lower recency is better
NTILE(4) OVER (ORDER BY (NumWebPurchases + NumCatalogPurchases + NumStorePurchases) DESC) AS FrequencyScore,
NTILE(4) OVER (ORDER BY MntTotal DESC) AS MonetaryScore
FROM fooddb;  /* This analysis categorizes customers based on Recency (last purchase date), Frequency (number of purchases), and Monetary (total spending).
Businesses use RFM scores to identify their most valuable customers and optimize marketing.*/
