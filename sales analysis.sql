---INSPECTING DATA

SELECT * FROM dbo.sales_data_sample

---CHECKING UNIQUE VALUES

SELECT DISTINCT [STATUS] FROM dbo.sales_data_sample
SELECT DISTINCT [YEAR_ID] FROM dbo.sales_data_sample
SELECT DISTINCT [PRODUCTLINE] FROM dbo.sales_data_sample
SELECT DISTINCT [COUNTRY] FROM dbo.sales_data_sample
SELECT DISTINCT [DEALSIZE] FROM dbo.sales_data_sample
SELECT DISTINCT [TERRITORY] FROM dbo.sales_data_sample

---GROUPING SALES BY PRODUCTLINE

SELECT
   [PRODUCTLINE], SUM([SALES]) Revenue
   FROM [dbo].[sales_data_sample]
GROUP BY [PRODUCTLINE]
ORDER BY 2 desc

--- YEAR THE COMPANY MADE THE MOST SALES

SELECT
   [YEAR_ID] , SUM([SALES]) Revenue
   FROM [dbo].[sales_data_sample]
GROUP BY [YEAR_ID]
ORDER BY 2 desc

---DEALSIZE THAT GENERATED THE MOST REVENUE

SELECT
  [DEALSIZE] , SUM([SALES]) Revenue
   FROM [dbo].[sales_data_sample]
GROUP BY [DEALSIZE]
ORDER BY 2 desc

--- WHAT WAS THE BEST MONTH FOR SALES IN A SPECFIC YEAR? HOW MUCH WAS EARNED THAT MONTH?

SELECT
   [MONTH_ID], SUM([SALES]) Revenue, COUNT ([ORDERNUMBER]) Frequency
   FROM	 [dbo].[sales_data_sample]
   WHERE [YEAR_ID] = 2003--Change year to see the rest
GROUP BY [MONTH_ID]
ORDER BY 2 desc

---NOVEMBER SEEMS TO BE THE MONTH THAT GENERATES THE MOST REVENUE, WHAT PRODUCT SELLS THE MOST IN NOVEMBER?

SELECT
   [MONTH_ID], [PRODUCTLINE], SUM([SALES]) Revenue, COUNT ([ORDERNUMBER]) Frequency
   FROM	 [dbo].[sales_data_sample]
   WHERE [YEAR_ID] = 2003 AND MONTH_ID = 11 --Change year to see the rest
GROUP BY [MONTH_ID], [PRODUCTLINE]
ORDER BY 3 desc

--- WHO IS THE COMPANY'S BEST CUSTOMER?

DROP TABLE IF EXISTS #rfm
; with rfm as
(
SELECT 
   [CUSTOMERNAME],
   SUM ([SALES]) MonetaryValue,
   AVG ([SALES]) AvgMonetaryValue,
   COUNT ([ORDERNUMBER]) Frequency,
   MAX ([ORDERDATE]) LastOrderDate,
  (SELECT MAX([ORDERDATE]) FROM dbo.sales_data_sample) Max_Order_Date,
   DATEDIFF(DD, MAX ([ORDERDATE]), (SELECT MAX([ORDERDATE]) FROM dbo.sales_data_sample)) Recency
FROM dbo.sales_data_sample
GROUP BY [CUSTOMERNAME]
),
rfm_calc as 
(

SELECT r .*,
  NTILE (4) OVER (Order by Recency) rfm_recency,
  NTILE (4) OVER (Order by frequency) rfm_frequency,
  NTILE (4) OVER (Order by AvgMonetaryValue) rfm_monetary
  from rfm r
)
select c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
CAST( rfm_recency as varchar)+ CAST( rfm_frequency as Varchar)+ CAST( rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c

SELECT [CUSTOMERNAME] , rfm_recency, rfm_frequency, rfm_monetary,
CASE 
  WHEN rfm_cell_string in  (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'-- lost customers 
  WHEN rfm_cell_string in ( 133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away customers'
  WHEN rfm_cell_string in (311, 411, 331) then 'new customers'
  WHEN rfm_cell_string in ( 222,223, 233, 322) then 'potential customers'
  WHEN rfm_cell_string in ( 323,333,321,422,332,432) then 'active customers'
  WHEN rfm_cell_string in( 433, 434,443,444) then 'loyal customers'
  END rfm_segment
FROM #rfm


---WHAT PRODUCTS ARE MOST OFTEN SOLD TOGETHER?
---select * from [dbo].[sales_data_sample] WHERE [ORDERNUMBER] = 10411
SELECT DISTINCT [ORDERNUMBER] , stuff(

    (select ',' + [PRODUCTCODE]
    from [dbo].[sales_data_sample] p
    where [ORDERNUMBER] IN (

       SELECT [ORDERNUMBER]
       from (
         select [ORDERNUMBER] , COUNT (*) rn 
         FROM [dbo].[sales_data_sample]
          WHERE STATUS= 'SHIPPED'
          GROUP BY [ORDERNUMBER]
           )m
           where rn =2
		   )
         and p.ORDERNUMBER = s.ORDERNUMBER
         FOR XML PATH (''))

		  , 1,  1, '') ProductCodes
from [dbo].[sales_data_sample] s 
ORDER BY 2 desc