/***********************************************************************************************************
Procedure Name 	: Capital Expenses Report for email sending
Purpose		: This Sp will fetch the details of detailed cea expenses, Request No.

Author		: Antony V.A (sql cmd Copied form the Application)
Date		: 14 MAr 2023
------------------------------------------------------------------------------------------------------------
Modification History:
	1. 
------------------------------------------------------------------------------------------------------------

************************************************************************************************************/

ALTER PROCEDURE Projectuser.spReport_CapitalExpenses
(
	@CostCenter				VARCHAR(20) = '',
	@ExpenditureType		VARCHAR(20) = '',
	@FromFiscalYear			INT = 0,
	@ToFiscalYear			INT = 0,
	@ProjectStatusId		VARCHAR(20) = '',
	@RequisitionStatusId	INT = 0
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

	IF ISNULL(@ProjectStatusId, '') = ''
		SET @ProjectStatusId = NULL

	IF ISNULL(@RequisitionStatusId, 0) = 0
		SET @RequisitionStatusId = NULL

	SELECT 
		d.RequisitionNo,
		a.ExpenditureType,
		a.ProjectNo,
		RTRIM(a.[Description]) AS ProjectDescription,
		a.CostCenter,
		RTRIM(k.CostCenterName) AS CostCenterName,
		LTRIM(RTRIM(i.RNDCTM)) AS DocumentType,
		a.ProjectAmount AS ProjectBudget,
		'0000' AS BatchNumber, --- Type BV as Batch Number   --- Need to change
		j.RMDOCM AS PaymentNo,
		convert(varchar,Projectuser.ConvertFromJulian(j.RMDMTJ), 103) AS PaymentDate,
		LTRIM(RTRIM(g.GLPO)) AS PurchaseOrderNo,
		g.GLLNID / 1000 AS PurchaseOrderLineNo,
		0000 ProjectDescription,      --- Need to change
		0000 RequisitionDescription,  --- Need to change
		cast(i.RNPAAP/1000 as varchar) PaymentActualPaidAmount,
		j.RMDOCM  PaymentNo,
		0000 AS VendorNo,   --- Need to change
		0000 AS Vendor		--- Need to change
	FROM dbo.Project a WITH (NOLOCK)
		INNER JOIN dbo.ProjectStatus b WITH (NOLOCK) ON a.ProjectID = b.ProjectID 
		INNER JOIN dbo.ApprovalStatus c WITH (NOLOCK) ON b.ProjectStatus = c.ApprovalStatusID 
		INNER JOIN dbo.Requisition d WITH (NOLOCK) ON a.ProjectNo = d.ProjectNo 
		INNER JOIN dbo.RequisitionStatus e WITH (NOLOCK) ON d.RequisitionID = e.RequisitionID 
		INNER JOIN dbo.ApprovalStatus f WITH (NOLOCK) ON e.ApprovalStatusID = f.ApprovalStatusID 
		INNER JOIN JDE_PRODUCTION.PRODDTA.F0911 g WITH (NOLOCK) ON d.RequisitionNo = g.GLSBL 
		INNER JOIN JDE_PRODUCTION.PRODDTA.F0411 h WITH (NOLOCK) ON g.GLDCT = h.RPDCT AND g.GLDOC = h.RPDOC AND g.GLSFX = h.RPSFX 
		LEFT JOIN JDE_PRODUCTION.PRODDTA.F0414 i WITH (NOLOCK) ON h.RPDCT = i.RNDCT AND h.RPDOC = i.RNDOC AND h.RPSFX = i.RNSFX 
		LEFT JOIN JDE_PRODUCTION.PRODDTA.F0413 j WITH (NOLOCK) ON i.RNPYID = j.RMPYID 
		INNER JOIN Projectuser.Master_CostCenter k WITH (NOLOCK) ON RTRIM(a.CostCenter) = RTRIM(k.CostCenter)
	WHERE g.GLPOST = 'P' AND g.GLSBLT = 'A' AND g.GLLT = 'AA' AND g.GLAID NOT IN ( '00012592', '00033278' ) AND i.RNDCTM <> 'PG'  
		AND (RTRIM(a.CostCenter) = @CostCenter OR @CostCenter IS NULL)
		AND (RTRIM(a.ExpenditureType) = @ExpenditureType OR @ExpenditureType IS NULL)
		AND (RTRIM(c.ApprovalStatus) = @ProjectStatusId OR @ProjectStatusId = 'All' OR @ProjectStatusId IS NULL)
		AND (a.FiscalYear >= @FromFiscalYear OR @FromFiscalYear IS NULL)
		AND (a.FiscalYear <= @ToFiscalYear OR @ToFiscalYear IS NULL)
		AND 
		(
			(@RequisitionStatusId = 0 AND f.approvalstatusid  IN (11, 15))       
			OR (@RequisitionStatusId = 11 AND f.approvalstatusid  IN (@RequisitionStatusId))
			OR (@RequisitionStatusId  = 15 AND f.approvalstatusid IN (@RequisitionStatusId))
			OR @RequisitionStatusId IS NULL
		)

	ORDER BY d.CreateDate DESC

END

/*	Debug:

	EXEC Projectuser.spReport_CapitalExpenses

*/