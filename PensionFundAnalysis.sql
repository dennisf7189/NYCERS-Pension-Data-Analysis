
--How many records are in the table?
 SELECT COUNT(*) AS count_records
 FROM [nycers_data_project].[dbo].[nycers_holdings];
--What asset classes are the most common in this pension portfolio?
 SELECT asset_class, COUNT(*)
 FROM [nycers_data_project].[dbo].[nycers_holdings]
 GROUP BY asset_class;

--What is the total market value of all holdings?
 SELECT SUM(CAST(base_market_value AS money))
 FROM nycers_data_project.dbo.nycers_holdings;

--Which security has given the pension the most gains and the most losses?
 SELECT COUNT(security_name), security_name, SUM(CAST(base_market_value as money)), SUM(CAST(base_unrealized_gain_loss as money))
 FROM [nycers_data_project].[dbo].[nycers_holdings]
 GROUP BY security_name
 ORDER BY SUM(CAST(base_unrealized_gain_loss as money)) desc;

--Top holdings by base total cost?
 SELECT security_name, investment_type_name, SUM(CAST(base_total_cost AS money)) 
 FROM nycers_data_project.dbo.nycers_holdings
 GROUP BY security_name, investment_type_name
 ORDER BY SUM(CAST(base_total_cost AS money)) desc;

--Compare gains/losses by asset class:
 SELECT asset_class, SUM(CAST(base_unrealized_gain_loss AS money))
 FROM nycers_data_project.dbo.nycers_holdings
 GROUP BY asset_class


--Which issuers have the highest average base market value per holding?
 SELECT security_name, COUNT(security_name), AVG(CAST(base_market_value as money))
 FROM nycers_data_project.dbo.nycers_holdings
 GROUP BY security_name
 ORDER BY AVG(CAST(base_market_value AS money)) desc


--SELECT asset_class, SUM(CAST(base_market_value AS money))
 FROM nycers_data_project.dbo.nycers_holdings
 GROUP BY asset_class;

--Rank holdings in each asset class by base market value
 WITH ranked AS (SELECT *, DENSE_RANK() OVER(PARTITION BY asset_class ORDER BY CAST(base_market_value AS money) desc) AS ranked_holding
 FROM nycers_data_project.dbo.nycers_holdings) 
 SELECT *
 FROM ranked
 WHERE ranked_holding <=5;
  I decided to use the market value of each individual transaction. I already did the highest market value for each asset class aggregated in the query above.


--Find the total market value of each country's investments and the gain/loss.
SELECT DISTINCT [trade_country_name], SUM(CAST(base_market_value AS money)) AS 'base_market_value', 
SUM(CAST(base_unrealized_gain_loss AS money)) AS 'base_unrealized_gain_loss', ROUND(SUM(CAST(base_unrealized_gain_loss AS numeric)) / NULLIF(SUM(CAST(base_market_value AS numeric)), 0), 2) * 100
  FROM [nycers_data_project].[dbo].[nycers_holdings]
  GROUP BY trade_country_name
  ORDER BY SUM(CAST(base_unrealized_gain_loss AS money)) desc



--Find all holdings where the unrealized gain/loss is more than 20% of the total cost.
WITH aggregated_holdings AS (SELECT security_name, SUM(CAST(base_total_cost As money)) AS base_total_cost, SUM(CAST(base_unrealized_gain_loss As money)) AS base_unrealized_gain_loss
								FROM nycers_data_project.dbo.nycers_holdings
								GROUP BY security_name)

SELECT security_name, CASE WHEN CAST(base_total_cost AS money) = 0
						   THEN NULL
						   ELSE CAST(base_unrealized_gain_loss AS money)/CAST(base_total_cost AS money) END
FROM aggregated_holdings
WHERE CASE WHEN CAST(base_total_cost AS money) = 0
						   THEN NULL
						   ELSE CAST(base_unrealized_gain_loss AS money)/CAST(base_total_cost AS money) END >=0.2
						   ORDER BY CASE WHEN CAST(base_total_cost AS money) = 0
						   THEN NULL
						   ELSE CAST(base_unrealized_gain_loss AS money)/CAST(base_total_cost AS money) END DESC;




--Which 5 issuers have the highest average base market value per holding?

SELECT [security_name]
      ,AVG(CAST([base_market_value] AS money)) AS 'Average Base Market Value'
  FROM [nycers_data_project].[dbo].[nycers_holdings]
  GROUP BY security_name
  ORDER BY AVG(CAST([base_market_value] AS money)) desc


--Rank holdings within each asset class by base market value.

WITH ranked_holdings_asset_class AS (SELECT *, RANK() OVER(PARTITION BY asset_class ORDER BY CAST(base_market_value AS money) DESC) AS rank_within_class
FROM dbo.nycers_holdings)
SELECT *
FROM ranked_holdings_asset_class
WHERE rank_within_class<=5;
--

--Identify Securities With the Highest Unrealized Loss
SELECT 
    security_name,
    SUM(CAST(base_unrealized_gain_loss AS money)) AS total_unrealized_loss
FROM nycers_holdings
GROUP BY security_name
HAVING SUM(CAST(base_unrealized_gain_loss AS money)) < 0
ORDER BY total_unrealized_loss ASC;


--Find the Investment Type With the Worst Average Performance
SELECT AVG(CAST([base_market_value] AS money))
      
      ,[investment_type_name]
      
  FROM [nycers_data_project].[dbo].[nycers_holdings]
  GROUP BY investment_type_name
  ORDER  BY AVG(CAST([base_market_value] AS money))

-- Rank Securities by Total Market Value Within Each Investment Type
  SELECT 
    security_name,
    investment_type_name,
    SUM(CAST(base_market_value AS money)) AS total_market_value,
    RANK() OVER (PARTITION BY investment_type_name ORDER BY SUM(CAST(base_market_value AS money)) DESC) AS market_rank
FROM nycers_holdings
GROUP BY security_name, investment_type_name;

--
 Analyze Performance by Maturity Date (Long-Term vs Short-Term Investments)
  Long term is 5 years or longer, short term is 5 years or shorter.

SELECT COUNT(*), CASE WHEN CAST(maturity_date AS date) > DATEADD(year, 5, GETDATE()) THEN 'Long Term'
						ELSE 'Short Term' END, SUM(CAST(base_market_value AS money))
  FROM [nycers_data_project].[dbo].[nycers_holdings]
  GROUP  BY CASE WHEN CAST(maturity_date AS date) > DATEADD(year, 5, GETDATE()) THEN 'Long Term'
						ELSE 'Short Term' END

--What Percentage of the Portfolio is Invested in Equities vs Bonds?
SELECT asset_class, SUM(CAST(base_market_value AS money))/(SELECT SUM(CAST(basE_market_value AS money)) FROM [nycers_data_project].[dbo].[nycers_holdings]) AS 'Percentage of Market Value', SUM(CAST(base_market_value AS money)) AS 'Base Market Value'
FROM [nycers_data_project].[dbo].[nycers_holdings]
GROUP BY asset_class
--Total Accrued Interest by Maturity Year
SELECT YEAR([maturity_date]) AS 'Maturity Year'
      ,MAX(CAST([interest_rate] AS float)) AS 'interest rate'
      ,SUM(CAST([base_accrued_interest] AS money)) AS 'Accrued Interest'
  FROM [nycers_data_project].[dbo].[nycers_holdings]
  GROUP BY Year(maturity_date)
  ORDER BY year(maturity_date)
--Create a View for Top 10 Securities by Market Value
CREATE VIEW Top10SecuritiesByMarketValue AS
SELECT TOP 10
    security_name,
    SUM(CAST(base_market_value AS money)) AS total_market_value
FROM nycers_holdings
GROUP BY security_name
ORDER BY total_market_value DESC;

-- Find the variance in gains/losses in specific industries.
SELECT [minor_industry_name], VAR(CAST(base_unrealized_gain_loss AS money)) AS 'Variance in unrealized gain/loss'
  FROM [nycers_data_project].[dbo].[nycers_holdings]
  GROUP BY minor_industry_name
  ORDER  BY 2 desc;
