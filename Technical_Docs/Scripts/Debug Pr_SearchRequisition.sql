DECLARE	@projectNo			VARCHAR(12) = '',	
		@requisitionNo		VARCHAR(12) = '',		
		@expenditureType	VARCHAR(10) = '',	
		@fiscalYear			SMALLINT = 0,
		@statusCode			VARCHAR(50) = '',
		@costCenter			VARCHAR(12) = '',	
		@empNo				INT = 10003323,
		@approvalType		VARCHAR(10) = 'ASGNTOME',	
		@keyWords			VARCHAR(50) = '',
		@startDate			DATETIME = NULL,
		@endDate			DATETIME = NULL		 

	DECLARE @approvalStatusID	INT = 0,
			@applicationUserID	INT = 0

	--Validate parameters
	IF ISNULL(@projectNo, '') = ''
		SET @projectNo = NULL

	IF ISNULL(@requisitionNo, '') = ''
		SET @requisitionNo = NULL

	IF ISNULL(@expenditureType, '') = ''
		SET @expenditureType = NULL

	IF ISNULL(@statusCode, '') = ''
		SET @statusCode = NULL

	IF ISNULL(@costCenter, '') = ''
		SET @costCenter = NULL

	IF ISNULL(@empNo, 0) > 0
	BEGIN
		
		SELECT @applicationUserID = CAST(a.ApplicationUserID AS INT)
		FROM dbo.ApplicationUser a WITH (NOLOCK) 
		WHERE a.EmployeeNo = @empNo
    END 
	ELSE 
		SET @empNo = NULL

	IF ISNULL(@approvalType, '') = ''
		SET @approvalType = NULL 

	IF ISNULL(@keyWords, '') = ''
		SET @keyWords = NULL

	IF ISNULL(@fiscalYear, 0) = 0
		SET @fiscalYear = NULL

	SELECT * FROM dbo.ApplicationUser WITH (NOLOCK) WHERE EmployeeNo = @empNo

	SELECT x.ApprovalStatusID 
	FROM dbo.ApprovalStatus x WITH (NOLOCK) 
	WHERE RTRIM(x.StatusCode) IN ('SubmittedForApproval')

	SELECT	DISTINCT 
			d.StatusHandlingCode, d.StatusHandlingDesc,
			h.AssignedToEmpNo, h.AssignedToEmpName,
				e.ApprovalStatusID,
				e.ApplicationUserID,
				d.ApprovalStatusID,
				a.RequisitionID, 
				a.ProjectNo, 
				b.FiscalYear,
				a.RequisitionNo, 
				a.RequestDate AS RequisitionDate, 
				a.[Description], 
				a.DateofComission, 
				a.RequestedAmt AS Amount,
				RTRIM(g.CostCenterName) AS Plant,
				d.ApprovalStatus AS [Status],
				b.CostCenter,
				b.CompanyCode,
	 			b.ObjectCode,
				b.SubjectCode,
				b.AccountCode,
				d.StatusCode,
				--@RequisitionTotal, 
				Projectuser.RequisitionUsedAmt(a.RequisitionNo) AS UsedAmount,
				a.CreatedByEmpNo,
				a.CreateBy AS CreatedByEmpName,
				a.CreateDate
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
			INNER Join dbo.RequisitionStatus c WITH (NOLOCK) on a.RequisitionID = c.RequisitionID
			INNER Join dbo.ApprovalStatus d WITH (NOLOCK) on d.ApprovalStatusID = c.ApprovalStatusID
			INNER Join dbo.RequisitionStatusDetail e WITH (NOLOCK) on c.RequisitionStatusID = e.RequisitionStatusID
			INNER Join dbo.Requisition f WITH (NOLOCK) On f.RequisitionID = c.RequisitionID
			LEFT JOIN Projectuser.Master_CostCenter g WITH (NOLOCK) ON RTRIM(g.CostCenter) = RTRIM(a.PlantLocationID) AND RTRIM(g.CostCenterType) = 'AL'
			CROSS APPLY 
			(
				SELECT x.EmployeeNo AS AssignedToEmpNo, RTRIM(x.FullName) AS AssignedToEmpName, RTRIM(x.CostCenter) AS AssignedToCostCenter 
				FROM dbo.ApplicationUser x WITH (NOLOCK)
				WHERE x.EmployeeNo = @empNo
			) h
		WHERE 
			--(RTRIM(f.RequisitionNo) = LTRIM(RTRIM(@requisitionNo)) OR @requisitionNo IS NULL)
			--AND (RTRIM(f.ProjectNo) = @projectNo OR @projectNo IS NULL)
			--AND (RTRIM(b.ExpenditureType) = @expenditureType OR @expenditureType IS NULL)
			--AND (RTRIM(d.StatusCode) = @statusCode OR @statusCode IS NULL)
			--AND (RTRIM(b.CostCenter) = @costCenter OR @costCenter IS NULL)
			--AND (b.FiscalYear = @fiscalYear OR @fiscalYear IS NULL)
			--AND 
			(
				e.ApplicationUserID =  (SELECT ApplicationUserID FROM dbo.ApplicationUser WITH (NOLOCK) WHERE EmployeeNo = @empNo) AND @empNo IS NOT NULL
			)
			AND d.StatusHandlingCode = 'Open'
			AND e.ApprovalStatusID IN
			(
				SELECT x.ApprovalStatusID 
				FROM dbo.ApprovalStatus x WITH (NOLOCK) 
				--WHERE RTRIM(x.ApprovalStatus) IN ('AwaitingApproval')
				WHERE RTRIM(x.StatusCode) IN ('SubmittedForApproval')
			)	 
			--AND 
			--(
			--	UPPER(RTRIM(a.[Description])) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
			--	OR UPPER(RTRIM(a.RequisitionDescription)) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
			--	OR UPPER(RTRIM(a.Reason)) LIKE '%' + UPPER(RTRIM(@keyWords)) + '%'
			--	OR @keyWords IS NULL 
			--)
			--AND 
			--(
			--	(a.RequestDate BETWEEN @startDate AND @endDate AND @startDate IS NOT NULL AND @endDate IS NOT NULL)
			--	OR (@startDate IS NULL AND @endDate IS NULL)
			--)
		ORDER BY a.RequisitionNo DESC  