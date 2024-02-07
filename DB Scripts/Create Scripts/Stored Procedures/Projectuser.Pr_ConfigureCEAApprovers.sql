/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_ConfigureCEAApprovers
*	Description: This stored procedure is used to populate the CEA request approver information
*
*	Date			Author		Rev. #		Comments:
*	23/07/2023		Ervin		1.0			Created
*
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_ConfigureCEAApprovers
(
    @requisitionID int
)
AS
BEGIN

    DECLARE @approvalCostCenter		VARCHAR(12) = '',
			@requisitionStatusID	INT = 0,
            @inQueueID				INT = 0,
			@requestedAmt			NUMERIC(18,3) = 0,
            @projectType			VARCHAR(20) = '',
			@originatorID			INT = 0,
			@categoryApproverID		INT = 0,
			@assignedEmpNo			INT = NULL,
			@assignedEmpName		VARCHAR(100) = NULL,
			@assignedEmpEmail		VARCHAR(50) = NULL,
			@maxSequenceNo			INT = 0 

    SELECT @approvalCostCenter = RTRIM(a.CostCenter)
    FROM dbo.ApplicationUser a WITH (NOLOCK)
        INNER JOIN dbo.Requisition b WITH (NOLOCK) ON b.OriginatorEmpNo = a.EmployeeNo 
    WHERE b.RequisitionID = @requisitionID 
		AND a.CostCenter IN ('3250', '5200', '5300', '5400', '5500')

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

    INSERT INTO dbo.RequisitionStatusDetail 
	(
        RequisitionStatusID,
        SubmittedDate,
        ApprovalGroupID,
        ApplicationUserID,
        ApprovalStatusID,
        StatusDate,
        RoutingSequence,
        PermanentStatus,
        GroupRountingSequence,
		AssignedEmpNo,
		AssignedEmpName,
		AssignedEmpEmail,
		IsAnonymousUser
    )
	SELECT	@requisitionStatusID,
			GETDATE() ,
			a.ApprovalGroupID,
			c.EmpNo,	--ISNULL(d.ApplicationUserID, c.EmpNo) AS ApplicationUserID,		--(Notes: Save the employee no. to the "ApplicationUserID" field for request which uses the new worklfow)
			@inQueueID,
			NULL,
			ISNULL(d.[Sequence], 0) AS RoutingSequence,
			ISNULL(d.PermanentStatus, 0) AS PermanentStatus,
			a.ApprovalSequence,
			c.EmpNo,
			c.EmpName,
			c.EmpEmail,
			1 AS IsAnonymousUser	--CASE WHEN ISNULL(d.ApplicationUserID, 0) = 0 THEN 1 ELSE 0 END 
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

    SELECT @requestedAmt = a.RequestedAmt
    FROM dbo.Requisition a WITH (NOLOCK)
    WHERE a.RequisitionID = @requisitionID

    SELECT @projectType = RTRIM(y.ProjectType)
    FROM dbo.Requisition x  WITH (NOLOCK)
		INNER JOIN dbo.Project y  WITH (NOLOCK) ON x.ProjectNo = y.ProjectNo
    WHERE x.RequisitionID = @requisitionID

	--PRINT '@projectType: ' + @projectType
	--PRINT '@requestedAmt: ' + CAST(@requestedAmt AS VARCHAR(20))
		
	IF @projectType = 'Budgeted'
	BEGIN

		IF @requestedAmt > 20000
		BEGIN

			--Get the current maximum sequence no.
			SELECT @maxSequenceNo = MAX(a.GroupRountingSequence) + 1
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = (
				SELECT y.RequisitionStatusID FROM dbo.RequisitionStatus y WITH (NOLOCK)
				WHERE y.RequisitionID = @requisitionID
			)
		
			--Add the CEO to the approver's list
			INSERT INTO dbo.RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence,
				AssignedEmpNo,
				AssignedEmpName,
				AssignedEmpEmail,
				IsAnonymousUser
			)
			SELECT	@requisitionStatusID,
					GETDATE() ,
					a.ApprovalGroupID,
					c.EmpNo,	--ISNULL(d.ApplicationUserID, 0),		--(Notes: Save the employee no. to the "ApplicationUserID" field for request which uses the new worklfow)
					@inQueueID,
					NULL,
					ISNULL(d.[Sequence], 0) AS RoutingSequence,
					ISNULL(d.PermanentStatus, 0) AS PermanentStatus,
					ISNULL(@maxSequenceNo, 0), --a.ApprovalSequence,
					c.EmpNo,
					c.EmpName,
					c.EmpEmail,
					1 AS IsAnonymousUser	--CASE WHEN ISNULL(d.ApplicationUserID, 0) = 0 THEN 1 ELSE 0 END 
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
				AND RTRIM(a.ApprovalGroup) = 'Chief Executive Officer' 							
		END

		IF @requestedAmt > 100000
		BEGIN

			--Get the current maximum sequence no.
			SELECT @maxSequenceNo = MAX(a.GroupRountingSequence) + 1
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = (
				SELECT y.RequisitionStatusID FROM dbo.RequisitionStatus y WITH (NOLOCK)
				WHERE y.RequisitionID = @requisitionID
			)

			--Add the Chairman to the approver's list
			INSERT INTO dbo.RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence,
				AssignedEmpNo,
				AssignedEmpName,
				AssignedEmpEmail,
				IsAnonymousUser
			)
			SELECT	@requisitionStatusID,
					GETDATE() ,
					a.ApprovalGroupID,
					c.EmpNo,	--ISNULL(d.ApplicationUserID, 0),		--(Notes: Save the employee no. to the "ApplicationUserID" field for request which uses the new worklfow)
					@inQueueID,
					NULL,
					ISNULL(d.[Sequence], 0) AS RoutingSequence,
					ISNULL(d.PermanentStatus, 0) AS PermanentStatus,
					ISNULL(@maxSequenceNo, 0),	--a.ApprovalSequence,
					c.EmpNo,
					c.EmpName,
					c.EmpEmail,
					1 AS IsAnonymousUser	--CASE WHEN ISNULL(d.ApplicationUserID, 0) = 0 THEN 1 ELSE 0 END 
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
				AND RTRIM(a.ApprovalGroup) = 'Chairman' 							
		END
	END

	ELSE IF @projectType = 'NonBudgeted'
	BEGIN

		IF @requestedAmt > 5000
		BEGIN

			--Get the current maximum sequence no.
			SELECT @maxSequenceNo = MAX(a.GroupRountingSequence) + 1
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = (
				SELECT y.RequisitionStatusID FROM dbo.RequisitionStatus y WITH (NOLOCK)
				WHERE y.RequisitionID = @requisitionID
			)

			--Add the CEO to the approver's list
			INSERT INTO dbo.RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence,
				AssignedEmpNo,
				AssignedEmpName,
				AssignedEmpEmail,
				IsAnonymousUser
			)
			SELECT	@requisitionStatusID,
					GETDATE() ,
					a.ApprovalGroupID,
					c.EmpNo,	--ISNULL(d.ApplicationUserID, 0),		--(Notes: Save the employee no. to the "ApplicationUserID" field for request which uses the new worklfow)					
					@inQueueID,
					NULL,
					ISNULL(d.[Sequence], 0) AS RoutingSequence,
					ISNULL(d.PermanentStatus, 0) AS PermanentStatus,
					ISNULL(@maxSequenceNo, 0),	--a.ApprovalSequence,
					c.EmpNo,
					c.EmpName,
					c.EmpEmail,
					1 AS IsAnonymousUser	--CASE WHEN ISNULL(d.ApplicationUserID, 0) = 0 THEN 1 ELSE 0 END  
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
				AND RTRIM(a.ApprovalGroup) = 'Chief Executive Officer' 							
		END

		IF @requestedAmt > 50000
		BEGIN

			--Get the current maximum sequence no.
			SELECT @maxSequenceNo = MAX(a.GroupRountingSequence) + 1
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = (
				SELECT y.RequisitionStatusID FROM dbo.RequisitionStatus y WITH (NOLOCK)
				WHERE y.RequisitionID = @requisitionID
			)

			--Add the Chairman to the approver's list
			INSERT INTO dbo.RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence,
				AssignedEmpNo,
				AssignedEmpName,
				AssignedEmpEmail,
				IsAnonymousUser
			)
			SELECT	@requisitionStatusID,
					GETDATE() ,
					a.ApprovalGroupID,
					c.EmpNo,	--ISNULL(d.ApplicationUserID, 0),		--(Notes: Save the employee no. to the "ApplicationUserID" field for request which uses the new worklfow)
					@inQueueID,
					NULL,
					ISNULL(d.[Sequence], 0) AS RoutingSequence,
					ISNULL(d.PermanentStatus, 0) AS PermanentStatus,
					ISNULL(@maxSequenceNo, 0),	--a.ApprovalSequence,
					c.EmpNo,
					c.EmpName,
					c.EmpEmail,
					1 AS IsAnonymousUser	--CASE WHEN ISNULL(d.ApplicationUserID, 0) = 0 THEN 1 ELSE 0 END 
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
				AND RTRIM(a.ApprovalGroup) = 'Chairman' 							
		END
	END

	/*****************************************************************
		Commented the old code in fetching the Originator 
	******************************************************************/
	/*
	SELECT	@originatorID = a.ApplicationUserID,
			@assignedEmpNo = b.OriginatorEmpNo,
			@assignedEmpName = RTRIM(c.EmpName),
			@assignedEmpEmail = RTRIM(c.EmpEmail)
    FROM dbo.ApplicationUser AS a WITH (NOLOCK)
        INNER JOIN dbo.Requisition AS b WITH (NOLOCK) ON b.OriginatorEmpNo = a.EmployeeNo
		INNER JOIN Projectuser.Vw_MasterEmployeeJDE c ON b.OriginatorEmpNo = c.EmpNo
    WHERE b.RequisitionID = @requisitionID
	*****************************************************************/

	SELECT	@originatorID = a.OriginatorEmpNo,
			@assignedEmpNo = a.OriginatorEmpNo,
			@assignedEmpName = RTRIM(b.EmpName),
			@assignedEmpEmail = RTRIM(b.EmpEmail) 
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN Projectuser.Vw_MasterEmployeeJDE b ON a.OriginatorEmpNo = b.EmpNo
	WHERE a.RequisitionID = @requisitionID

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
		
			IF EXISTS
            (
				SELECT 1
				FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
					INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
					INNER JOIN dbo.ApprovalGroupType AS c WITH (NOLOCK) ON c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
				WHERE a.RequisitionStatusID = @requisitionStatusID 
					AND RTRIM(b.CostCenter) = @approvalCostCenter 
					AND c.IsCostCenterSpecific = 1
			)
			BEGIN
            
				--Add the Originator to the approver's list and set the approval group type to "Superintendent"
				INSERT INTO dbo.RequisitionStatusDetail 
				(
					RequisitionStatusID,
					SubmittedDate,
					ApprovalGroupID,
					ApplicationUserID,
					ApprovalStatusID, 
					StatusDate,
					RoutingSequence,
					PermanentStatus,
					GroupRountingSequence,
					AssignedEmpNo,
					AssignedEmpName,
					AssignedEmpEmail,
					IsAnonymousUser
				)
				SELECT TOP 1
					a.RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					@assignedEmpNo,		--@originatorID,
					@inQueueID,
					null,
					0,
					1,
					a.GroupRountingSequence,
					@assignedEmpNo,
					@assignedEmpName,
					@assignedEmpEmail,
					1 AS IsAnonymousUser
				FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
					INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
					INNER JOIN dbo.ApprovalGroupType AS c WITH (NOLOCK) ON c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
				WHERE a.RequisitionStatusID = @requisitionStatusID 
					AND RTRIM(b.CostCenter) = @approvalCostCenter 
					AND c.IsCostCenterSpecific = 1
			END 
		END
	END 

	/****************************************************************************************
	Old logic commented
	SELECT	@categoryApproverID = a.ApplicationUserID,
			@assignedEmpNo = a.EmployeeNo,
			@assignedEmpName = RTRIM(d.EmpName),
			@assignedEmpEmail = RTRIM(d.EmpEmail)
    FROM dbo.ApplicationUser AS a WITH (NOLOCK) 
        INNER JOIN dbo.ApplicationUserRequisitionCategory AS b WITH (NOLOCK) ON b.EmployeeNo = a.EmployeeNo
        INNER JOIN dbo.Requisition AS c WITH (NOLOCK) ON RTRIM(c.CategoryCode1) = RTRIM(b.RequisitionCategoryCode)
		INNER JOIN Projectuser.Vw_MasterEmployeeJDE d ON a.EmployeeNo = d.EmpNo
    WHERE c.RequisitionID = @requisitionID
	*************************************************************************************/

	SELECT	@categoryApproverID = c.EmpNo,
			@assignedEmpNo = c.EmpNo,
			@assignedEmpName = RTRIM(c.EmpName),
			@assignedEmpEmail = RTRIM(c.EmpEmail) 
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.ApplicationUserRequisitionCategory b WITH (NOLOCK) ON RTRIM(a.CategoryCode1) = RTRIM(b.RequisitionCategoryCode)
		CROSS APPLY
		(
			SELECT * FROM Projectuser.fnGetWFActionMember(RTRIM(b.DistGroupCode), '', 0)
		) c
	WHERE a.RequisitionID = @requisitionID

	IF ISNULL(@categoryApproverID, 0) > 0		--Rev. #1.1
	BEGIN
    
		--Only add Item Category Approver in the list if it still does not exist
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

			IF EXISTS
            (
				SELECT 1
				FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
					INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
				WHERE a.RequisitionStatusID = @requisitionStatusID 
					AND RTRIM(b.CostCenter) = @approvalCostCenter 
					AND b.ApprovalGroupTypeID = 
						(
							SELECT CategoryApproverGroupTypeID
							FROM dbo.AppConfiguration WITH (NOLOCK)
						)
			)
			BEGIN

				--Add the Item Category Approver to the list and set the approval group type to "Manager"
				INSERT INTO dbo.RequisitionStatusDetail 
				(
					RequisitionStatusID,
					SubmittedDate,
					ApprovalGroupID,
					ApplicationUserID,
					ApprovalStatusID,
					StatusDate,
					RoutingSequence,
					PermanentStatus,
					GroupRountingSequence,
					AssignedEmpNo,
					AssignedEmpName,
					AssignedEmpEmail,
					IsAnonymousUser
				)
				SELECT	TOP 1
						a.RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						@assignedEmpNo,		--@categoryApproverID, 
						@inQueueID,
						null,
						@MaxRoutingSequence,
						1,
						a.GroupRountingSequence,
						@assignedEmpNo,
						@assignedEmpName,
						@assignedEmpEmail,
						1 AS IsAnonymousUser
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
	END 

END

/*	Debug:

	EXEC Projectuser.Pr_ConfigureCEAApprovers 4118

*/
