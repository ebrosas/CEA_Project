DECLARE	@requisitionID INT = 4132

    DECLARE @approvalCostCenter		VARCHAR(12) = '',
			@requisitionStatusID	INT = 0,
            @inQueueID				INT = 0,
			@requestedAmt			NUMERIC(18,3) = 0,
            @projectType			VARCHAR(20) = '',
			@originatorID			INT = 0,
			@categoryApproverID		INT = 0,
			@assignedEmpNo			INT = NULL,
			@assignedEmpName		VARCHAR(100) = NULL,
			@assignedEmpEmail		VARCHAR(50) = NULL 

    SELECT @approvalCostCenter = RTRIM(a.CostCenter)
    FROM dbo.ApplicationUser a WITH (NOLOCK)
        INNER JOIN dbo.Requisition b WITH (NOLOCK) ON b.OriginatorEmpNo = a.EmployeeNo 
    WHERE b.RequisitionID = @requisitionID 
		AND a.CostCenter IN ('3250', '5200', '5300', '5400')

    IF ISNULL(@approvalCostCenter, '') = ''
    BEGIN

        SELECT @approvalCostCenter = RTRIM(a.CostCenter)
        FROM dbo.Project AS a WITH (NOLOCK)
            INNER JOIN dbo.Requisition AS b WITH (NOLOCK) ON RTRIM(b.ProjectNo) = RTRIM(a.ProjectNo)
         WHERE b.RequisitionID = @requisitionID
    END


	SELECT @requisitionStatusID = a.RequisitionStatusID 
    FROM dbo.RequisitionStatus a WITH (NOLOCK) 
    WHERE a.RequisitionID = @requisitionID

    SELECT @inQueueID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'AwaitingApproval'

 --   INSERT INTO dbo.RequisitionStatusDetail 
	--(
 --       RequisitionStatusID,
 --       SubmittedDate,
 --       ApprovalGroupID,
 --       ApplicationUserID,
 --       ApprovalStatusID,
 --       StatusDate,
 --       RoutingSequence,
 --       PermanentStatus,
 --       GroupRountingSequence,
	--	AssignedEmpNo,
	--	AssignedEmpName,
	--	AssignedEmpEmail,
	--	IsApplicationUser
 --   )
	SELECT	a.ApprovalGroup,
			@requisitionStatusID AS RequisitionStatusID,
			GETDATE() AS SubmittedDate,
			a.ApprovalGroupID,
			ISNULL(d.ApplicationUserID, c.EmpNo) AS ApplicationUserID,
			@inQueueID AS ApprovalStatusID,
			NULL AS StatusDate,
			ISNULL(d.[Sequence], 0) AS RoutingSequence,
			ISNULL(d.PermanentStatus, 0) AS PermanentStatus,
			a.ApprovalSequence,
			c.EmpNo,
			c.EmpName,
			c.EmpEmail,
			CASE WHEN ISNULL(d.ApplicationUserID, 0) > 0 THEN 1 ELSE 0 END AS IsApplicationUser,
			b.DistGroupCode
	FROM dbo.ApprovalGroup a WITH (NOLOCK)
		INNER JOIN dbo.ApprovalGroupType b WITH (NOLOCK) ON a.ApprovalGroupTypeID = b.ApprovalGroupTypeID
		OUTER APPLY
		(
			SELECT x.EmpNo AS EmpNo, RTRIM(x.EmpName) AS EmpName, RTRIM(x.EmpEmail) AS EmpEmail
			FROM Projectuser.fnGetWFActionMember(RTRIM(b.DistGroupCode), RTRIM(a.CostCenter), 0) x
		) c
		OUTER APPLY 
		(
			SELECT x.ApplicationUserID, x.[Sequence], x.PermanentStatus
			FROM dbo.ApprovalGroupAssignment x WITH (NOLOCK)
			WHERE 
			(
				(a.ApprovalGroupID = x.ApprovalGroupID AND x.PermanentStatus = 0) 
				OR (a.ApprovalGroupTypeID = x.ApprovalGroupTypeID AND x.ApprovalGroupID = -1 AND x.PermanentStatus = 1)
			)
		) d
	WHERE RTRIM(a.CostCenter) = @approvalCostCenter
		AND RTRIM(a.ApprovalGroup) NOT IN 
		(
			'General Manager', 
			'Chief Executive Officer', 
			'Chairman'
		) 		
	ORDER BY a.ApprovalSequence	 

	--Get Item Category Approver
	SELECT	a.ApplicationUserID AS CategoryApproverID,
			a.EmployeeNo AS AssignedEmpNo,
			RTRIM(d.EmpName) AS AssignedEmpName,
			RTRIM(d.EmpEmail) AS AssignedEmpEmail
    FROM dbo.ApplicationUser AS a WITH (NOLOCK) 
        INNER JOIN dbo.ApplicationUserRequisitionCategory AS b WITH (NOLOCK) ON b.EmployeeNo = a.EmployeeNo
        INNER JOIN dbo.Requisition AS c WITH (NOLOCK) ON RTRIM(c.CategoryCode1) = RTRIM(b.RequisitionCategoryCode)
		LEFT JOIN Projectuser.Vw_MasterEmployeeJDE d ON a.EmployeeNo = d.EmpNo
    WHERE c.RequisitionID = @requisitionID

	--SELECT * FROM dbo.ApplicationUserRequisitionCategory a

	