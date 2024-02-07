/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetLookupTable
*	Description: This stored procedure returns multiple result sets to populate the combo box list items
*
*	Date			Author		Rev. #		Comments:
*	28/02/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetLookupTable
(
	@objectCode		VARCHAR(20) = ''
)
AS
BEGIN
	
	SET NOCOUNT ON 
		
	IF RTRIM(ISNULL(@objectCode, '')) = ''
	BEGIN
    
		--1). Fiscal Year list
		SELECT DISTINCT 
			a.FiscalYear AS FiscalYearValue, 
			CAST(a.FiscalYear AS VARCHAR(4)) AS FiscalYearDesc
		FROM dbo.Project a WITH (NOLOCK)
		ORDER BY a.FiscalYear

		--2). Cost Center list
		SELECT	a.CostCenter, 
				RTRIM(a.CostCenter) + ' - ' + RTRIM(Projectuser.fnRemoveSpecialChar(a.CostCenterName)) AS  CostCenterName
		FROM Projectuser.Master_CostCenter a WITH (NOLOCK) 
		ORDER BY a.CostCenter

		--3). Project Status list
		SELECT  a.StatusCode, 
				a.ApprovalStatus 
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(a.StatusCode) IN ('Active', 'Closed', 'Cancelled') 
		ORDER BY a.ApprovalStatus

		--4). Expenditure Type list
		SELECT  a.DetailRefCode, 
				a.DetailRefCodeDescription 
		FROM Projectuser.MasterDetailReference a WITH (NOLOCK)
		WHERE RTRIM(a.MasterCode) = 'ExpenditureType' 
			AND a.IsDeleted = 0 
		ORDER BY a.SortOrder, a.DetailRefCodeDescription

		--5). Expense Types
		SELECT	RTRIM(a.UDCCode) AS ExpenditureTypeCode,  
				RTRIM(a.UDCDesc1) AS ExpenditureTypeDesc
		FROM Projectuser.UserDefinedCode a WITH (NOLOCK)
			INNER JOIN Projectuser.UserDefinedCodeGroup b WITH (NOLOCK) ON a.UDCUDCGID = b.UDCGID
		WHERE RTRIM(b.UDCGCode) = 'EXPDTRTYPE'
		ORDER BY a.UDCAmount

		--6). Requisition Status
		SELECT	a.StatusCode, 
				RTRIM(a.ApprovalStatus) AS StatusDescription 
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(a.StatusCode) IN ('Draft', 'Submitted', 'Rejected', 'Cancelled', 'Closed', 'DraftAndSubmitted', 'Approved', 'UploadedToOneWorld')

		--SELECT * FROM
		--(
		--	SELECT	DISTINCT
		--			RTRIM(b.UDCSpecialHandlingCode) AS  StatusCode,
		--			RTRIM(b.UDCSpecialHandlingCode) AS  StatusDescription
		--	FROM dbo.ApprovalStatus a WITH (NOLOCK)
		--		INNER JOIN Projectuser.UserDefinedCode b WITH (NOLOCK) ON RTRIM(a.WFStatusCode) = RTRIM(b.UDCCode) AND b.UDCUDCGID = 9
		--	WHERE RTRIM(b.UDCSpecialHandlingCode) <> 'Open'
		--) x
		--ORDER BY x.StatusDescription	

		--7). Pending Approval Types
		SELECT	RTRIM(a.UDCCode) AS ApprovalCode,  
				RTRIM(a.UDCDesc1) AS ApprovalDescription
		FROM Projectuser.UserDefinedCode a WITH (NOLOCK)
			INNER JOIN Projectuser.UserDefinedCodeGroup b WITH (NOLOCK) ON a.UDCUDCGID = b.UDCGID
		WHERE RTRIM(b.UDCGCode) = 'APVTYPES'
			AND RTRIM(a.UDCField) = 'Active'
		ORDER BY a.UDCAmount
	END 

	ELSE 
    BEGIN

		IF @objectCode = 'CEAREQUISITION'		--Load datasource for all comboboxes in CEA Requisition form
		BEGIN

			--Get Cost Center list
			SELECT	a.CostCenter, 
					RTRIM(a.CostCenter) + ' - ' + RTRIM(Projectuser.fnRemoveSpecialChar(a.CostCenterName)) AS  CostCenterName
			FROM Projectuser.Master_CostCenter a WITH (NOLOCK) 
			ORDER BY a.CostCenter

			--Get fiscal years
			SELECT DISTINCT 
				a.FiscalYear AS FiscalYearValue, 
				CAST(a.FiscalYear AS VARCHAR(4)) AS FiscalYearDesc
			FROM dbo.Project a WITH (NOLOCK)
			ORDER BY a.FiscalYear

			--Get Item Types
			SELECT DISTINCT 
				a.RequisitionCategoryID, 
				a.RequisitionCategoryCode, 
				a.RequisitionCategory
			FROM dbo.RequisitionCategory a WITH (NOLOCK)
			ORDER BY a.RequisitionCategory

			--Get Expense Types
			SELECT	RTRIM(a.UDCCode) AS ExpenditureTypeCode,  
					RTRIM(a.UDCDesc1) AS ExpenditureTypeDesc
			FROM Projectuser.UserDefinedCode a WITH (NOLOCK)
				INNER JOIN Projectuser.UserDefinedCodeGroup b WITH (NOLOCK) ON a.UDCUDCGID = b.UDCGID
			WHERE RTRIM(b.UDCGCode) = 'EXPDTRTYPE'
			ORDER BY a.UDCAmount

			--Get Plant Locations
			SELECT a.CostCenter, a.CostCenterName
			FROM Projectuser.Master_CostCenter a WITH (NOLOCK)
			WHERE RTRIM(a.CostCenterType) = 'AL'
			ORDER BY a.CostCenter

			--Get Fiscal Year for Schedule of Expenses
			SELECT	YEAR(GETDATE()) AS ExpenseYear
			UNION 
			SELECT YEAR(GETDATE()) + 1 AS ExpenseYear
			UNION 
			SELECT YEAR(GETDATE()) + 2 AS ExpenseYear
			UNION 
			SELECT YEAR(GETDATE()) + 3 AS ExpenseYear
			UNION 
			SELECT YEAR(GETDATE()) + 4 AS ExpenseYear

			--Get Quarters for Schedule of Expenses
			SELECT	'Q1' AS ExpenseQuarter
			UNION 
			SELECT	'Q2' AS ExpenseQuarter
			UNION 
			SELECT	'Q3' AS ExpenseQuarter
			UNION 
			SELECT	'Q4' AS ExpenseQuarter

			--Get all CEA Administrators
			SELECT * FROM Projectuser.fnGetWFActionMember('CEAADMIN', 'ALL', 0)	
        END 
    END 

END 

/*	Debug:

	EXEC Projectuser.Pr_GetLookupTable
	EXEC Projectuser.Pr_GetLookupTable 'CEAREQUISITION'

*/