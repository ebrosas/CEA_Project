/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetLookupTable
*	Description: This stored procedure is used to fetch the data for the Schedule of Expenses
*
*	Date			Author		Rev. #		Comments:
*	29/05/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetScheduleOfExpenses
(
	@requisitionNo	VARCHAR(12)
)
AS
BEGIN

	SET NOCOUNT ON 

	--Get Financial Details
	SELECT a.RequisitionId, a.Amount, a.FiscalYear, a.[Quarter] 
	FROM dbo.Expense a WITH (NOLOCK) 
	WHERE RTRIM(a.RequisitionId) = CAST(@requisitionNo AS INT)
	ORDER By a.FiscalYear, a.[Quarter]

END 


/*	Debug:
	
	EXEC Projectuser.Pr_GetScheduleOfExpenses '20230012'		--Draft
	EXEC Projectuser.Pr_GetScheduleOfExpenses '20220046'	

*/