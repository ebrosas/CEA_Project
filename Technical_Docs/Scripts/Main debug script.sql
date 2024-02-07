
	--Cost Center combo
	EXEC Projectuser.spGetReferenceData 0

	--Fiscal Year combo 
	EXEC Projectuser.spGetReferenceData 2

	--Expenditure Type combo 
	EXEC Projectuser.spGetReferenceData 1

	--Project Status combo 
	EXEC Projectuser.spGetReferenceData 4

	--Requisition Status combo 
	EXEC Projectuser.spGetReferenceData 3

	EXEC Projectuser.Pr_GetLookupTable

	--Get all projects (old logic)
	DECLARE	@return_value INT
	EXEC	@return_value = [Projectuser].[spGetProjects]
			@ProjectNo = NULL,
			@CostCenter = '7600',
			@ExpenditureType = NULL,
			@FiscalYear = 2022,
			@StatusCode = '',
			@KeyWords = NULL

	--Get all projects
	EXEC Projectuser.Pr_GetProjectList 2022, '', '7600'
	/*	Parameters:
		@fiscalYear			INT = 0,
		@projectNo			VARCHAR(12) = '',
		@costCenter			VARCHAR(12) = '',
		@expenditureType	VARCHAR(10) = '',
		@statusCode			VARCHAR(50) = '',
		@keywords			VARCHAR(50) = ''
	*/

	--Get project details
	EXEC Projectuser.spGetProjectForNewRequisition @ProjectNo = '2220210'	--Old logic
	EXEC Projectuser.Pr_GetProjectDetail '2220210'

	--Get project requisitions
	EXEC [Projectuser].[spGetRequisitions] '2220210', '', '', 0
    
	SELECT a.AccountID, * FROM [dbo].[Project] a WITH (NOLOCK)
	WHERE RTRIM(a.ProjectNo) = '2220210'

	SELECT Projectuser.AccountNo('2220210') AS AccountNo

	SELECT LTRIM(RTRIM(CostCenter)) + '.' + LTRIM(RTRIM(ObjectAccount)) + '.' + LTRIM(RTRIM(SujectAccount)) AS AccountNo 
	FROM Projectuser.Master_AccountID a WITH (NOLOCK)
	WHERE AccountID = '00016924'

	--Get CEA requisitions
	EXEC Projectuser.spGetRequisitions @ProjectNo = '',       -- varchar(12)
	                                   @CostCenter = '7600',      -- varchar(12)
	                                   @ExpenditureType = '', -- varchar(10)
	                                   @FiscalYear = 0,       -- smallint
	                                   @StatusCode = 'DraftAndSubmitted',      -- varchar(50)
	                                   @RequisitionNo = '',   -- varchar(12)
	                                   @FilterToUser = NULL,  -- bit
	                                   @EmployeeNo = 0,       -- int
	                                   @KeyWords = ''         -- varchar(50)

	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)
	--WHERE RTRIM(a.StatusCode) IN ('SubmittedForApproval')
	ORDER BY a.ApprovalStatus

	--Stored procedure used for fetching the data in "Requisition Status View"
	EXEC Projectuser.spGetRequisitionStatusDetail 4064

	--Populate the grid in "Expenses View" form
	EXEC [Projectuser].[spGetExpenses] '20220185'

	EXEC [Projectuser].[spGetRequisitionList] '20220046'

	--Get all application users
	SELECT * FROM dbo.ApplicationUser a WITH (NOLOCK)

	SELECT * FROM dbo.AppConfiguration a

	--Get all system administrators
	SELECT a.*
	FROM dbo.ApplicationUser a WITH (NOLOCK)
		INNER JOIN dbo.ApprovalGroupAssignment b WITH (NOLOCK) on a.ApplicationUserID = b.ApplicationUserID
		INNER JOIN dbo.ApprovalGroupDetail c on c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
	WHERE RTRIM(c.UserGroupTypeCode) = 'Admin' 

	--Get Chairman
	SELECT c.* 
	FROM [dbo].[ApprovalGroupAssignment] a
		INNER JOIN dbo.ApprovalGroup b ON a.ApprovalGroupID = b.ApprovalGroupID
		INNER JOIN dbo.ApplicationUser c ON a.ApplicationUserID = c.ApplicationUserID
	WHERE RTRIM(b.ApprovalGroup) = 'Chairman'

	SELECT DISTINCT a.ApprovalGroup FROM dbo.ApprovalGroup a ORDER BY a.ApprovalGroup

	--Get Item Category Approvers
	SELECT a.RequisitionCategoryCode, a.RequisitionCategory, b.EmployeeNo, b.* 
	FROM dbo.RequisitionCategory a WITH (NOLOCK)
		INNER JOIN dbo.ApplicationUserRequisitionCategory b WITH (NOLOCK) ON RTRIM(a.RequisitionCategoryCode) = RTRIM(b.RequisitionCategoryCode)
	ORDER BY a.RequisitionCategory

	--Get all required approvers
	SELECT * FROM dbo.ApprovalGroupType a
	WHERE ISNULL(a.IsMandatoryGroup, 0) = 1

	--Check CEA status to workflow status mapping
	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)
	ORDER BY a.StatusCode

	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)
	ORDER BY a.ApprovalStatusID

	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusHandlingCode) = 'Open'

	SELECT  * FROM Projectuser.UserDefinedCode a
	WHERE a.UDCUDCGID = 9
	ORDER BY CAST(a.UDCCode AS INT)

	SELECT DISTINCT a.UDCSpecialHandlingCode FROM Projectuser.UserDefinedCode a
	WHERE a.UDCUDCGID = 9
	ORDER BY a.UDCSpecialHandlingCode

	SELECT b.UDCSpecialHandlingCode, a.* 
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
		INNER JOIN Projectuser.UserDefinedCode b WITH (NOLOCK) ON RTRIM(a.WFStatusCode) = RTRIM(b.UDCCode) AND b.UDCUDCGID = 9
	WHERE b.UDCSpecialHandlingCode = 'Open'
	ORDER BY a.StatusCode

	EXEC Projectuser.spGetApproverList 4065, 2, 'SubmittedForApproval'

	SELECT Projectuser.GetNextSequence(3880, 2)

	SELECT LTRIM(RTRIM(ISNULL(f.EAEMAL, ''))) AS Email 
	FROM Projectuser.sy_F01151 f WITH (NOLOCK)
	WHERE CAST(f.EAAN8 AS INT) = 10003632 
		AND f.EAIDLN = 0 AND f.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(f.EAETP))) = 'E' 

	--NotifyCostCenterUsers() recipients
	EXEC [Projectuser].[spGetCostCenterEmailList] 3905

	--Used in NotifyEquipmentNoAssigners() method
	EXEC Projectuser.spGetEquipmentNoAssigners 3905

	SELECT * FROM dbo.EquipmentRoutingExpenditureType a

	--Get header approval statuses
	SELECT DISTINCT b.ApprovalStatusID, b.StatusCode, b.ApprovalStatus 
	FROM dbo.RequisitionStatus a WITH (NOLOCK)
		INNER JOIN dbo.ApprovalStatus b WITH (NOLOCK) ON a.ApprovalStatusID = b.ApprovalStatusID
	ORDER BY b.ApprovalStatusID

	Select StatusCode, ApprovalStatus 
	FROM dbo.ApprovalStatus
	Where StatusCode in ('Draft', 'Submitted', 'Rejected', 'Closed', 'DraftAndSubmitted')

	SELECT * FROM dbo.ApprovalStatus a
	
	

	