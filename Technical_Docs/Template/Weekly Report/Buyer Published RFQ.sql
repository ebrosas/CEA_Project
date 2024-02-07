DECLARE @startDate smalldatetime
DECLARE @endDate smalldatetime

SET @startDate	= '2013-11-01'
SET @endDate	= '2013-11-17'

SELECT DATEPART(mm, b.OrderTransactionDate), CONVERT(varchar(20), a.OrderBuyerEmpNo) + ' - ' + a.OrderBuyerEmpName AS OrderBuyer, COUNT(a.OrderNo) AS OrderTotalRFQ--, a.*
	FROM b2badminuser.OrderRequisitionTemp AS a INNER JOIN
		b2badminuser.F4301View AS b ON a.OrderNo = b.OrderDocNo
	WHERE b.OrderTransactionDate BETWEEN @startDate AND @endDate
	GROUP BY DATEPART(mm, b.OrderTransactionDate), a.OrderBuyerEmpNo, a.OrderBuyerEmpName
	ORDER BY DATEPART(mm, b.OrderTransactionDate), a.OrderBuyerEmpNo, a.OrderBuyerEmpName
