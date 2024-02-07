/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_CapitalExpenseReport
*	Description: This stored procedure is used to fetch the data for the Capital Expense report
*
*	Date			Author		Rev. #		Comments:
*	03/07/2023		Ervin		1.0			Created
*	12/09/2023		eRVIN		1.1			Added "Item Type" field
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_CapitalExpenseReport
(
	@CostCenter			VARCHAR(20) = '',
	@ExpenditureType	VARCHAR(20) = '',
	@FromFiscalYear		INT = 0,
	@ToFiscalYear		INT = 0
)
AS
BEGIN

	SET NOCOUNT ON 

	IF ISNULL(@CostCenter, '') = ''
		SET @CostCenter = NULL

	IF ISNULL(@ExpenditureType, '') = ''
		SET @ExpenditureType = NULL

	IF ISNULL(@FromFiscalYear, 0) = 0
		SET @FromFiscalYear = NULL

	IF ISNULL(@ToFiscalYear, 0) = 0
		SET @ToFiscalYear = NULL

	SELECT  		
		d.RequisitionNo AS 'Request No',
		a.ExpenditureType AS 'Requisition Type',
		RTRIM(i.RequisitionCategory) AS 'Item Type',
		a.ProjectNo AS 'Project No',
		RTRIM(a.[Description]) AS 'Project',
		a.CostCenter AS 'Cost Center',
		RTRIM(g.CostCenterName) AS 'Cost Center Name',	
		h.DocumentType AS 'Document Type',
		a.ProjectAmount AS 'Project Budget',
		d.RequestedAmt AS 'Requested Budget',
		h.BatchNo AS 'Batch No',
		h.DocumentNo AS 'Doc Number',		
		CONVERT(VARCHAR, h.OrderDate, 103) AS 'G/L Date',
		h.OrderNumber AS 'Purchase Order', 
		h.[LineNo] AS 'Line Item',
		h.Description1,
		h.Description2,
		(h.POAmount + h.GLAmount) AS 'Amount BD',
		h.InvoiceNo AS 'Invoice Number',
		--h.PaymentActualPaidAmount AS ActualPaidAmount,
		--h.PaymentDate,
		h.VendorNo AS 'Vendor No', 
		h.VendorName AS 'Vendor',
		c.StatusCode AS 'Project Status',
		f.StatusCode AS 'Requisition Status',
		a.FiscalYear AS 'Fiscal Year'
	FROM dbo.Project a WITH (NOLOCK)
		INNER JOIN dbo.ProjectStatus b WITH (NOLOCK) ON a.ProjectID = b.ProjectID 
		INNER JOIN dbo.ApprovalStatus c WITH (NOLOCK) ON b.ProjectStatus = c.ApprovalStatusID 
		INNER JOIN dbo.Requisition d WITH (NOLOCK) ON a.ProjectNo = d.ProjectNo 
		INNER JOIN dbo.RequisitionStatus e WITH (NOLOCK) ON d.RequisitionID = e.RequisitionID 
		INNER JOIN dbo.ApprovalStatus f WITH (NOLOCK) ON e.ApprovalStatusID = f.ApprovalStatusID 
		INNER JOIN Projectuser.Master_CostCenter g WITH (NOLOCK) ON RTRIM(a.CostCenter) = RTRIM(g.CostCenter)
		CROSS APPLY
        (
			SELECT	a1.PDDOCO AS OrderNumber, 
					a1.PDLNID / 1000 AS [LineNo], 
					projectuser.ConvertFromJulian(a1.PDTRDJ) AS OrderDate, 
					b1.ABAN8 AS VendorNo,
					LTRIM(RTRIM(b1.ABALPH)) AS VendorName, 
					LTRIM(RTRIM(a1.PDDSC1)) AS Description1, 
					LTRIM(RTRIM(a1.PDDSC2)) AS Description2, 
					a1.PDAOPN / 1000 AS POAmount,
					0 AS GLAmount,
					LTRIM(RTRIM(a1.PDSBL)) AS CEANumber,
					NULL AS DocumentNo,
					NULL AS DocumentType,
					NULL AS BatchNo,
					NULL AS BatchType,
					NULL AS InvoiceNo,
					NULL AS PaymentActualPaidAmount,
					NULL AS PaymentDate
			FROM  Projectuser.sy_F4311 a1 WITH (NOLOCK)	
				LEFT JOIN Projectuser.sy_F0101 b1 WITH (NOLOCK) ON a1.PDAN8 = b1.ABAN8
				LEFT JOIN Projectuser.Master_CostCenter c1 WITH (NOLOCK) ON LTRIM(RTRIM(a1.PDMCU)) = RTRIM(c1.CostCenter)
			WHERE LTRIM(RTRIM(a1.PDDCTO)) = 'OP' 
				AND LTRIM(RTRIM(a1.PDLTTR)) <> '980' 
				AND a1.PDAOPN <> 0   
				AND LTRIM(RTRIM(a1.PDSBL)) = RTRIM(d.RequisitionNo)

			UNION 

			SELECT  (CASE WHEN ISNUMERIC(a1.GLPO) = 1 THEN CAST(a1.GLPO AS FLOAT) ELSE 0 END) AS OrderNumber, 
					(CASE WHEN ISNUMERIC(a1.GLJELN) = 1 THEN CAST(a1.GLJELN AS FLOAT) ELSE 0 END) AS [LineNo], 
					projectuser.ConvertFromJulian(GLDICJ) AS OrderDate, 
					b1.ABAN8 AS VendorNo,
					ISNULL(ABALPH, '') AS VendorName, 
					GLEXA AS Description1, 	
					GLEXR AS Description2, 
					0 AS POAmount, 
					GLAA / 1000 AS GLAmount, 
					LTRIM(RTRIM(GLSBL)) AS CEANumber,
					a1.GLDOC AS DocumentNo,
					a1.GLDCT AS DocumentType,
					a1.GLICU AS BatchNo,
					a1.GLICUT AS BatchType,
					d1.InvoiceNo,
					d1.PaymentActualPaidAmount,
					d1.PaymentDate
			FROM Projectuser.sy_F0911 a1 WITH (NOLOCK) 
				LEFT JOIN Projectuser.sy_F0101 b1 WITH (NOLOCK) ON a1.GLAN8 = b1.ABAN8
				LEFT JOIN Projectuser.Master_CostCenter c1 WITH (NOLOCK) ON LTRIM(RTRIM(a1.GLMCU)) = RTRIM(c1.CostCenter)
				OUTER APPLY
				(
					SELECT	LTRIM(RTRIM(y.RNDCTM)) AS DocumentType,
							x.RPVINV AS InvoiceNo,
							z.RMDOCM AS PaymentNo,
							y.RNPAAP / 1000 AS PaymentActualPaidAmount,
							CONVERT(VARCHAR, Projectuser.ConvertFromJulian(z.RMDMTJ), 103) AS PaymentDate
					FROM JDE_PRODUCTION.PRODDTA.F0411 x WITH (NOLOCK) 
						LEFT JOIN JDE_PRODUCTION.PRODDTA.F0414 y WITH (NOLOCK) ON x.RPDCT = y.RNDCT AND x.RPDOC = y.RNDOC AND x.RPSFX = y.RNSFX AND y.RNDCTM <> 'PG'  
						LEFT JOIN JDE_PRODUCTION.PRODDTA.F0413 z WITH (NOLOCK) ON y.RNPYID = z.RMPYID 
					WHERE x.RPDCT = a1.GLDCT 
						AND x.RPDOC = a1.GLDOC 
						AND x.RPSFX = a1.GLSFX 
				) d1
			WHERE LTRIM(RTRIM(a1.GLSBL)) = RTRIM(d.RequisitionNo)
				AND a1.GLPOST = 'P' AND a1.GLSBLT = 'A' AND a1.GLLT = 'AA' AND a1.GLAID NOT IN ( '00012592', '00033278' ) 
		) h
		LEFT JOIN dbo.RequisitionCategory i WITH (NOLOCK) ON RTRIM(d.CategoryCode1) = RTRIM(i.RequisitionCategoryCode)
	WHERE --RTRIM(c.StatusCode) = 'Active' AND														--Show active projects only
		LTRIM(RTRIM(g.GroupCode)) NOT IN ('S&M', 'ADM')										--Exclude admin cost centers
		AND RTRIM(f.StatusCode) NOT IN ('Completed', 'Rejected', 'Cancelled', 'Closed')			--Show active requisitions only
		AND (RTRIM(a.CostCenter) = @CostCenter OR @CostCenter IS NULL)
		AND (RTRIM(a.ExpenditureType) = @ExpenditureType OR @ExpenditureType IS NULL)
		AND (a.FiscalYear >= @FromFiscalYear OR @FromFiscalYear IS NULL)
		AND (a.FiscalYear <= @ToFiscalYear OR @ToFiscalYear IS NULL)
	ORDER BY a.FiscalYear, a.ProjectNo, d.RequisitionNo

END

/*	Debug:

	EXEC Projectuser.Pr_CapitalExpenseReport '2111'

*/
		

	