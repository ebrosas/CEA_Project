/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetLookupTable
*	Description: This stored procedure returns multiple result sets to populate the combo box list items
*
*	Date			Author		Rev. #		Comments:
*	27/04/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetExpenses
(
	@requisitionNo	VARCHAR(12)
)
AS
BEGIN

	SET NOCOUNT ON 

	DECLARE @ceaNumber 		VARCHAR(8),
			@requestedAmt 	NUMERIC(18,3),
			@poTotal 		NUMERIC(18,3),
			@glTotal 		NUMERIC(18,3)

	SELECT	@requestedAmt = a.RequestedAmt,
			@ceaNumber = Projectuser.lpad(CONVERT(VARCHAR, CAST(a.OneWorldABNo AS INT)), 8, '0')  
	FROM  dbo.Requisition a WITH (NOLOCK)
	WHERE a.RequisitionNo = @requisitionNo

	SELECT  a.CEANumber,
			a.CostCenter, 
			a.CostCenterName,
			a.OrderNumber, 
			a.OrderDate,
			a.[LineNo], 
			a.Description1, 
			a.Description2,	 
			a.Vendor,  
			CAST(a.Quantity AS NUMERIC(10,2)) AS Quantity,  
			a.CurrencyCode, 
			CAST(CASE WHEN a.CurrencyCode IN ('JPY', 'ITL') THEN a.CurrencyAmount ELSE a.CurrencyAmount END AS NUMERIC(18,2)) AS CurrencyAmount,
			CAST(a.POAmount AS NUMERIC(18,3)) AS POAmount,
			CAST(a.GLAmount AS NUMERIC(18,3)) AS GLAmount,
			ISNULL(CAST(a.POAmount AS NUMERIC(18,3)), 0) + ISNULL(CAST(a.GLAmount AS NUMERIC(18,3)), 0) AS LineTotal,
			@requestedAmt AS RequestedAmt,
			b.POTotal,
			b.GLTotal,
			@requestedAmt - (ISNULL(b.POTotal, 0) + ISNULL(b.GLTotal, 0)) AS Balance,
			((ISNULL(b.POTotal, 0) + ISNULL(b.GLTotal, 0)) / @requestedAmt) * 100  AS PercentageUsed
	FROM Projectuser.Vw_ExpenseDetails a 
		OUTER APPLY
		(
			SELECT	CAST(SUM(POAmount) AS NUMERIC(18,3)) AS POTotal, 
					CAST(SUM(GLAmount) AS NUMERIC(18,3)) AS GLTotal 
			FROM Projectuser.Vw_ExpenseDetails  
			WHERE CEANumber = a.CEANumber
		) b
	WHERE a.CEANumber = @ceaNumber 
	ORDER BY OrderNumber, [LineNo]

END 

/*	Debug:

	EXEC Projectuser.Pr_GetExpenses '20220046'
	EXEC Projectuser.Pr_GetExpenses '20220029'		--Live

*/

