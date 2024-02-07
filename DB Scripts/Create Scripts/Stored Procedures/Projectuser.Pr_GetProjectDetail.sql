/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetProjectDetail2
*	Description: This stored procedure returns the list of all projects
*
*	Date			Author		Rev. #		Comments:
*	19/03/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetProjectDetail
(
	@projectNo	VARCHAR(12) = ''
)
AS 
BEGIN
	
	SET NOCOUNT ON 

	SELECT	a.ProjectID,
			a.ProjectNo, 
			CONVERT(INT, a.FiscalYear) AS FiscalYear, 
			a.ExpectedProjectDate, 
			CAST(a.CompanyCode AS INT) AS CompanyCode, 
			a.CostCenter,
			b.CostCenterName,
			c.ExpenseTypeDesc AS ExpenditureType,
			a.[Description] AS 'Description', 
			a.DetailDescription, 	
			Projectuser.AccountNo(@projectNo) AS AccountNo,
			a.ProjectAmount, 
			Projectuser.ProjectUsedAmt(@projectNo) AS UsedAmount,
			Projectuser.ProjectBalanceAmt(@projectNo) BalanceAmount,
			d.ApprovalStatus AS ProjectStatus,
			d.StatusAuthor,
			d.Comment,
			d.BudgetStatus,			
			e.AdditionalAmount,
			a.ExpenditureType AS ExpenditureTypeCode, 
			a.AccountCode, 
			a.ObjectCode, 
			a.SubjectCode		
	FROM dbo.Project a WITH (NOLOCK)
		LEFT JOIN Projectuser.Master_CostCenter b WITH (NOLOCK) ON RTRIM(a.CostCenter) = RTRIM(b.CostCenter)
		LEFT JOIN 	
		(
			SELECT	RTRIM(x.UDCCode) AS ExpenseTypeCode, 
					RTRIM(x.UDCDesc1) AS ExpenseTypeDesc 
			FROM Projectuser.UserDefinedCode x WITH (NOLOCK)
				INNER JOIN Projectuser.UserDefinedCodeGroup y WITH (NOLOCK) ON x.UDCUDCGID = y.UDCGID	
			WHERE RTRIM(y.UDCGCode) = 'EXPTYP'
		) c ON RTRIM(a.ExpenditureType) = c.ExpenseTypeCode
		OUTER APPLY
		(
			SELECT x.ApprovalStatus, y.CreateBy AS StatusAuthor, y.Comment,
				CASE WHEN ISNULL(y.NonBudgeted, 0) = 0 THEN 'Budgeted' ELSE 'Non-Budgeted' END AS BudgetStatus,
				y.ProjectID,
				y.StatusDate
			FROM dbo.ApprovalStatus x WITH (NOLOCK)
				INNER JOIN dbo.ProjectStatus y WITH (NOLOCK) ON x.ApprovalStatusID = y.ProjectStatus
			WHERE y.ProjectID = a.ProjectID			
				 AND y.StatusDate= (SELECT MAX(StatusDate) FROM ProjectStatus WHERE ProjectID = a.ProjectID)	
		) d 
		OUTER APPLY
		(
			SELECT SUM(x.AdditionalBudgetAmt) AS AdditionalAmount
			FROM dbo.Requisition x WITH (NOLOCK) 
			WHERE RTRIM(x.ProjectNo) = RTRIM(a.ProjectNo)
		) e
	WHERE LTRIM(RTRIM(a.ProjectNo)) = LTRIM(RTRIM(@projectNo))

END 

/*	Debug:

	EXEC Projectuser.Pr_GetProjectDetail '2220338'
	EXEC Projectuser.Pr_GetProjectDetail '2220215'
	

*/