DECLARE	@requisitionID INT = 4074

    DECLARE @approvalCostCenter		VARCHAR(12) = '',
			@requisitionStatusID	INT = 0,
            @inQueueID				INT = 0,
			@requestedAmt			NUMERIC(18,3) = 0,
            @projectType			VARCHAR(20) = '',
			@originatorID			INT = 0,
			@categoryApproverID		INT = 0

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

	SELECT @approvalCostCenter AS ApprovalCostCenter

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
 --       GroupRountingSequence
 --   )
    SELECT	@requisitionStatusID AS RequisitionStatusID,
			getdate() AS CurrentDate,
			a.ApprovalGroupID,
			b.ApplicationUserID,
			@inQueueID AS InQueueID,
			null,
			b.Sequence,
			b.PermanentStatus,
			a.ApprovalSequence
	FROM dbo.ApprovalGroup as a WITH (NOLOCK),
		dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
	WHERE RTRIM(a.CostCenter) = @approvalCostCenter 
		AND RTRIM(a.ApprovalGroup) NOT IN 
		(
			'General Manager', 
			'Chief Executive Officer', 
			'Chairman'
		) 
		AND
		(
			(a.ApprovalGroupID = b.ApprovalGroupID AND b.PermanentStatus = 0) 
			OR (a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND b.ApprovalGroupID = -1 AND b.PermanentStatus = 1)
		)

    SELECT @requestedAmt = a.RequestedAmt
    FROM dbo.Requisition a WITH (NOLOCK)
    WHERE a.RequisitionID = @requisitionID

    SELECT @projectType = RTRIM(y.ProjectType)
    FROM dbo.Requisition x  WITH (NOLOCK)
		INNER JOIN dbo.Project y  WITH (NOLOCK) ON x.ProjectNo = y.ProjectNo
    WHERE x.RequisitionID = @requisitionID

	IF @projectType = 'Budgeted'
	BEGIN

		IF @requestedAmt > 20000
		BEGIN

			--Add the CEO to the approver's list
			--INSERT INTO dbo.RequisitionStatusDetail 
			--(
			--	RequisitionStatusID,
			--	SubmittedDate,
			--	ApprovalGroupID,
			--	ApplicationUserID,
			--	ApprovalStatusID,
			--	StatusDate,
			--	RoutingSequence,
			--	PermanentStatus,
			--	GroupRountingSequence
			--)
			SELECT	@requisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@inQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @approvalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chief Executive Officer' 
				AND
				(
					(a.ApprovalGroupID = b.ApprovalGroupID AND b.PermanentStatus = 0) 
					OR (a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND b.ApprovalGroupID = -1 AND b.PermanentStatus = 1)
				)
		END

		IF @requestedAmt > 100000
		BEGIN

			--Add the Chairman to the approver's list
			--INSERT INTO dbo.RequisitionStatusDetail 
			--(
			--	RequisitionStatusID,
			--	SubmittedDate,
			--	ApprovalGroupID,
			--	ApplicationUserID,
			--	ApprovalStatusID,
			--	StatusDate,
			--	RoutingSequence,
			--	PermanentStatus,
			--	GroupRountingSequence
			--)
			SELECT	@requisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@inQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @approvalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chairman' 
				AND
				(
					(a.ApprovalGroupID = b.ApprovalGroupID AND b.PermanentStatus = 0) 
					OR (a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND b.ApprovalGroupID = -1 AND b.PermanentStatus = 1)
				)
		END
	END

	ELSE IF @projectType = 'NonBudgeted'
	BEGIN

		IF @requestedAmt > 5000
		BEGIN

			--Add the CEO to the approver's list
			--INSERT INTO dbo.RequisitionStatusDetail 
			--(
			--	RequisitionStatusID,
			--	SubmittedDate,
			--	ApprovalGroupID,
			--	ApplicationUserID,
			--	ApprovalStatusID,
			--	StatusDate,
			--	RoutingSequence,
			--	PermanentStatus,
			--	GroupRountingSequence
			--)
			SELECT	@requisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@inQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @approvalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chief Executive Officer' 
				AND
				(
					(a.ApprovalGroupID = b.ApprovalGroupID AND b.PermanentStatus = 0) 
					OR (a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND b.ApprovalGroupID = -1 AND b.PermanentStatus = 1)
				)
		END

		IF @requestedAmt > 50000
		BEGIN

			--Add the Chairman to the approver's list
			--INSERT INTO dbo.RequisitionStatusDetail 
			--(
			--	RequisitionStatusID,
			--	SubmittedDate,
			--	ApprovalGroupID,
			--	ApplicationUserID,
			--	ApprovalStatusID,
			--	StatusDate,
			--	RoutingSequence,
			--	PermanentStatus,
			--	GroupRountingSequence
			--)
			SELECT	@requisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@inQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @approvalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chairman' 
				AND
				(
					(a.ApprovalGroupID = b.ApprovalGroupID AND b.PermanentStatus = 0) 
					OR (a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND b.ApprovalGroupID = -1 AND b.PermanentStatus = 1)
				)
		END
	END

	SELECT @originatorID = a.ApplicationUserID
    FROM dbo.ApplicationUser AS a WITH (NOLOCK)
        INNER JOIN dbo.Requisition AS b WITH (NOLOCK) ON b.OriginatorEmpNo = a.EmployeeNo
    WHERE b.RequisitionID = @requisitionID

	IF ISNULL(@originatorID, 0) > 0		
	BEGIN
    
		IF NOT EXISTS 
		(
			SELECT RequisitionStatusDetailID
			FROM dbo.RequisitionStatusDetail a  WITH (NOLOCK)
			WHERE RequisitionStatusID = @requisitionStatusID 
				AND ApplicationUserID = @originatorID
		)
		BEGIN

			--Add the Originator to the approver's list
			--INSERT INTO dbo.RequisitionStatusDetail 
			--(
			--	RequisitionStatusID,
			--	SubmittedDate,
			--	ApprovalGroupID,
			--	ApplicationUserID,
			--	ApprovalStatusID, 
			--	StatusDate,
			--	RoutingSequence,
			--	PermanentStatus,
			--	GroupRountingSequence
			--)
			SELECT TOP 1
				a.RequisitionStatusID,
				getdate(),
				a.ApprovalGroupID,
				@originatorID,
				@inQueueID,
				null,
				0,
				1,
				a.GroupRountingSequence
			FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
				INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
				INNER JOIN dbo.ApprovalGroupType AS c WITH (NOLOCK) ON c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
			WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND RTRIM(b.CostCenter) = @approvalCostCenter 
				AND c.IsCostCenterSpecific = 1
		END
	END 

	SELECT @categoryApproverID = a.ApplicationUserID
    FROM dbo.ApplicationUser AS a WITH (NOLOCK) 
        INNER JOIN dbo.ApplicationUserRequisitionCategory AS b WITH (NOLOCK) ON b.EmployeeNo = a.EmployeeNo
        INNER JOIN dbo.Requisition AS c WITH (NOLOCK) ON RTRIM(c.CategoryCode1) = RTRIM(b.RequisitionCategoryCode)
    WHERE c.RequisitionID = @requisitionID

	IF ISNULL(@categoryApproverID, 0) > 0		--Rev. #1.1
	BEGIN
    
		IF NOT EXISTS 
		(
			SELECT RequisitionStatusDetailID
			FROM dbo.RequisitionStatusDetail a  WITH (NOLOCK)
			WHERE RequisitionStatusID = @requisitionStatusID 
				AND ApplicationUserID = @categoryApproverID
		)
		BEGIN

			DECLARE @MaxRoutingSequence int

			SELECT @MaxRoutingSequence = MAX(a.RoutingSequence) + 1
			FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
				INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
			WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND RTRIM(b.CostCenter) = @approvalCostCenter 
				AND b.ApprovalGroupTypeID = 
					(
						SELECT CategoryApproverGroupTypeID
						FROM dbo.AppConfiguration WITH (NOLOCK)
					)

			--Add Item Category approver to the list
			--INSERT INTO dbo.RequisitionStatusDetail 
			--(
			--	RequisitionStatusID,
			--	SubmittedDate,
			--	ApprovalGroupID,
			--	ApplicationUserID,
			--	ApprovalStatusID,
			--	StatusDate,
			--	RoutingSequence,
			--	PermanentStatus,
			--	GroupRountingSequence
			--)
			SELECT	TOP 1
					a.RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					@categoryApproverID, 
					@inQueueID,
					null,
					@MaxRoutingSequence,
					1,
					a.GroupRountingSequence
			FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
				INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
			WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND RTRIM(b.CostCenter) = @approvalCostCenter 
				AND b.ApprovalGroupTypeID = 
					(
						SELECT CategoryApproverGroupTypeID
						FROM dbo.AppConfiguration WITH (NOLOCK)
					)
		END
	END 