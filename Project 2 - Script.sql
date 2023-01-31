--Project number 2

--Write a query that displays the information about products that were not purchased in the order table:
SELECT p.ProductID
		,p.Name
		,p.Color
		,p.ListPrice
		,p.Size
FROM production.Product p 
	LEFT JOIN sales.SalesOrderDetail s
		ON p.ProductID=s.ProductID
	LEFT JOIN sales.SalesOrderHeader o
		ON o.SalesOrderID=s.SalesOrderID
WHERE o.OrderDate is null


--Write a query that displays information about customers who have not placed any orders:
SELECT c.CustomerID
		--,p.LastName
		,isnull(p.lastname, 'Unknown') as CustomerUnknown
FROM sales.SalesOrderHeader o
	RIGHT JOIN sales.Customer c
		ON o.CustomerID= c.CustomerID 
	LEFT JOIN person.Person p
		ON c.PersonID=p.BusinessEntityID
WHERE o.OrderDate is null
ORDER BY c.CustomerID

-- Write a query that displays the details of the 10 customers who made the most orders:
SELECT DISTINCT TOP 10 o.CustomerID
						,p.FirstName
						,p.LastName
						,COUNT(*) over(partition by o.customerid)
FROM sales.SalesOrderHeader o
	INNER JOIN sales.Customer c
		ON o.CustomerID=c.CustomerID
	INNER JOIN Person.Person p
		ON c.PersonID=p.BusinessEntityID
ORDER BY 4 DESC

--Write a query that displays information about employees and their roles and the number of employees that have the same position:
SELECT p.FirstName
		,p.LastName
		,e.JobTitle
		,e.HireDate
		,COUNT(*) over(partition by e.JobTitle)
FROM HumanResources.Employee e
	JOIN Person.Person p
		ON e.BusinessEntityID=p.BusinessEntityID
ORDER BY e.JobTitle

--Write a query that shows for each customer the date of the last order they made and the date of the order before the last one they made:

SELECT tbl2.SalesOrderID
		,tbl2.CustomerID
		,p.LastName
		,p.FirstName
		,tbl2.OrderDate 'LastOrder'
		,tbl2.PreviousOrder
FROM							(SELECT *
								FROM (SELECT o.SalesOrderID
											,o.CustomerID
											,o.OrderDate
											,RANK()OVER(PARTITION BY o.customerid order by o.orderdate desc) as rnk
											,LAG(o.orderdate,1) over(partition by o.customerid order by o.orderdate) as PreviousOrder
										FROM sales.SalesOrderHeader o)tbl1
								WHERE rnk=1 )tbl2
JOIN sales.Customer c 
ON tbl2.CustomerID=c.CustomerID
JOIN Person.Person p
ON c.PersonID=p.BusinessEntityID
Order By c.PersonID
GO

--Write a query that displays the sum of products in the most expensive order each year. Please display which customers these orders belong to: 

SELECT tbl2.Year
		,tbl2.SalesOrderID
		,tbl2.LastName
		,tbl2.FirstName
		,tbl2.Total
FROM	(SELECT ROW_NUMBER() OVER(PARTITION BY tbl.Year ORDER BY tbl.Total DESC) as "Rnk"
				,*
		FROM	(SELECT YEAR(oh.OrderDate) as "Year"
						,oh.SalesOrderID
						,p.LastName
						,p.FirstName
						,SUM(od.UnitPrice*(1-od.UnitPriceDiscount)* od.OrderQty) OVER(PARTITION BY oh.SalesOrderID) as "Total"
				FROM Sales.SalesOrderDetail od 
					JOIN Sales.SalesOrderHeader oh
						ON od.SalesOrderID=oh.SalesOrderID
					JOIN Sales.Customer c
						ON oh.CustomerID=c.CustomerID
					JOIN Person.Person p
						ON c.PersonID=p.BusinessEntityID)tbl
		)tbl2
WHERE tbl2.Rnk=1

--Display using a matrix the number of orders made in each month of the year:

SELECT Month,[2011],[2012],[2013],[2014]
FROM	 (SELECT SalesOrderID
					,MONTH(OrderDate) as "Month"
					,YEAR(OrderDate) as "Year"
		FROM Sales.SalesOrderHeader)tbl
PIVOT(COUNT(SalesOrderID) FOR YEAR IN ([2011],[2012],[2013],[2014])	)pvt
ORDER BY Month

--Write a query that displays the amount of products on order for each month of the year and also the cumulative amount.
--Pay attention to the visibility of the report. A line highlighting the year's summary must be presented:
   
WITH tbl_price
AS
(
SELECT YEAR(oh.OrderDate) as "Year"
		,MONTH(oh.OrderDate) as "Month"
		,CAST(SUM(od.LineTotal) as NUMERIC(20,2)) as Sum_Price
FROM Sales.SalesOrderHeader oh 
	JOIN Sales.SalesOrderDetail od
		ON oh.SalesOrderID=od.SalesOrderID
GROUP BY YEAR(oh.OrderDate), MONTH(oh.OrderDate)
)
SELECT YEAR
		,CAST(Month as char) as "Month"
		,Sum_Price
		,SUM(Sum_Price) OVER(PARTITION BY Year ORDER BY Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as "Money"
FROM tbl_price

UNION

SELECT Year
		,'grand_total'
		,null
		,CAST(SUM(Sum_Price) AS NUMERIC(20,2)) as Money
FROM tbl_price
GROUP BY Year
ORDER BY Year, Money

--Write a query that displays employees in the order they were hired in each department from the newest employee to the oldest employee:

SELECT  dep.Name as "DepartmentName"
		,e.BusinessEntityID as "EmployeeID"
		,p.FirstName+' '+p.LastName as "Employee'sFullName"
		,e.HireDate
		,DATEDIFF(MM,e.HireDate, GETDATE()) as "Seniority"
		,LAG(p.FirstName+' '+p.LastName)OVER(PARTITION BY dep.Name ORDER BY e.HireDate) as "PreviousEmpName"
		,LAG(e.HireDate)OVER(PARTITION BY dep.Name ORDER BY e.HireDate) as "PreviousEmpHDate"
		,DATEDIFF(DD,LAG(e.HireDate)OVER(PARTITION BY dep.Name ORDER BY e.HireDate),e.HireDate) as "DiffDays"
FROM HumanResources.Employee e RIGHT JOIN HumanResources.EmployeeDepartmentHistory deph
						ON e.BusinessEntityID=deph.BusinessEntityID
				JOIN Person.Person p
						ON e.BusinessEntityID=p.BusinessEntityID
				JOIN HumanResources.Department dep
						ON deph.DepartmentID=dep.DepartmentID
WHERE deph.EndDate is null
ORDER BY dep.Name,e.BusinessEntityID DESC

--Write a query showing the details of employees who work in the same department and were hired on the same date:

SELECT DISTINCT e.HireDate 	
				,dep.DepartmentID 
				,STRING_AGG(CAST(p.BusinessEntityID as nvarchar)+' '+CAST(p.LastName as nvarchar)+' '+CAST(p.FirstName as nvarchar), ',')
					WITHIN GROUP (ORDER BY e.HireDate) as "a"
FROM HumanResources.Employee e INNER JOIN HumanResources.EmployeeDepartmentHistory deph
					ON e.BusinessEntityID=deph.BusinessEntityID
					INNER JOIN HumanResources.Department dep
					ON deph.DepartmentID=dep.DepartmentID
					INNER JOIN Person.Person p
					ON e.BusinessEntityID=p.BusinessEntityID
WHERE deph.EndDate is null
GROUP BY e.HireDate, dep.DepartmentID
ORDER BY e.HireDate desc