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