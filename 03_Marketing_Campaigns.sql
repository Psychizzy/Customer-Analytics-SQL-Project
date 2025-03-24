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
