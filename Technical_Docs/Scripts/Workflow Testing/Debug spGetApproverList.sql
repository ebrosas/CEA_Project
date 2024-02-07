DECLARE	@requisitionNo					VARCHAR(50) = '20210029',    
		@groupRountingSequence			INT = 5,
		@statusCode						VARCHAR(50) = 'SubmittedForApproval'
    
	DECLARE @requisitionID				INT,
			@submittedForApprovalID		INT,
            @inQueueID					INT,
            @minRoutingSequence			INT,
            @requisitionStatusID		NUMERIC

	--GET the requisition ID
	SELECT @requisitionID = a.RequisitionID
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE RTRIM(a.RequisitionNo) = @requisitionNo

	SELECT @submittedForApprovalID = a.ApprovalStatusID
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = @statusCode

	SELECT @inQueueID = ApprovalStatusID
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = 'AwaitingApproval'

	SELECT @requisitionStatusID = a.RequisitionStatusID
	FROM dbo.RequisitionStatus a WITH (NOLOCK)
	WHERE a.RequisitionID = @requisitionID

	SELECT @minRoutingSequence  = MIN(a.RoutingSequence)
	FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
	WHERE a.RequisitionStatusID = @requisitionStatusID 
		AND a.ApprovalStatusID = @inQueueID 
		AND GroupRountingSequence = @groupRountingSequence

	SELECT	@requisitionID AS requisitionID,
			@requisitionStatusID AS requisitionStatusID,
			@submittedForApprovalID AS submittedForApprovalID,
			@inQueueID AS inQueueID,
			@requisitionStatusID AS requisitionStatusID,
			@minRoutingSequence AS minRoutingSequence,
			@groupRountingSequence AS groupRountingSequence

    IF @minRoutingSequence IS NOT NULL
    BEGIN
	
   --     UPDATE dbo.RequisitionStatusDetail
   --     SET ApprovalStatusID = @submittedForApprovalID
   --     WHERE RequisitionStatusID = @requisitionStatusID 
			--AND ApprovalStatusID = @inQueueID 
			--AND GroupRountingSequence = @groupRountingSequence 
			--AND RoutingSequence = @minRoutingSequence

        IF EXISTS 
		(
			SELECT a.RequisitionStatusDetailID
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
                INNER JOIN dbo.ApprovalGroup b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
            WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND a.ApprovalStatusID = @submittedForApprovalID 
				AND a.GroupRountingSequence = @groupRountingSequence 
				AND a.RoutingSequence = @minRoutingSequence 
				AND RTRIM(b.ApprovalGroup) = 'Chairman'
        )
        BEGIN
		
			PRINT 'Goes here - with Chairman'

			SELECT	RTRIM(a.RequisitionNo) AS RequisitionNo,
					CAST(f.EmployeeNo AS INT) AS ApproverEmpNo,
					RTRIM(f.FullName) AS ApproverName,					
					LTRIM(RTRIM(ISNULL(g.EAEMAL, ''))) AS ApproverEmail, 					
					e.ApprovalStatus AS ApprovalStatus,
					RTRIM(a.RequisitionDescription) AS CEADescription
			FROM dbo.Requisition a WITH (NOLOCK)
				INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
				INNER JOIN dbo.RequisitionStatusDetail c WITH (NOLOCK) ON b.RequisitionStatusID = c.RequisitionStatusID
				INNER JOIN dbo.ApprovalGroup d WITH (NOLOCK) ON c.ApprovalGroupID = d.ApprovalGroupID 
				INNER JOIN dbo.ApprovalStatus e WITH (NOLOCK) ON b.ApprovalStatusID = e.ApprovalStatusID
				INNER JOIN dbo.ApplicationUser f WITH (NOLOCK) ON c.ApplicationUserID = f.ApplicationUserID
				LEFT JOIN Projectuser.sy_F01151 g WITH (NOLOCK) ON CAST(f.EmployeeNo AS INT) = CAST(g.EAAN8 AS INT) AND g.EAIDLN = 0 AND g.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(g.EAETP))) = 'E' 
			WHERE a.RequisitionID = @requisitionID
				AND c.ApprovalStatusID = @submittedForApprovalID 
				AND c.GroupRountingSequence = @groupRountingSequence 
				AND c.RoutingSequence = @minRoutingSequence 
				AND RTRIM(d.ApprovalGroup) <> 'Chairman'
            
			UNION

			SELECT	RTRIM(e.RequisitionNo) AS RequisitionNo,
					a.EmployeeNo AS ApproverEmpNo,
					RTRIM(a.FullName) AS ApproverName,
					LTRIM(RTRIM(ISNULL(d.EAEMAL, ''))) AS ApproverEmail, 					
					e.ApprovalStatus,
					e.CEADescription
			FROM dbo.ApplicationUser AS a WITH (NOLOCK)
				INNER JOIN dbo.ApprovalGroupAssignment AS b WITH (NOLOCK) ON b.ApplicationUserID = a.ApplicationUserID
				INNER JOIN dbo.ApprovalGroupType AS c WITH (NOLOCK) ON c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
				LEFT JOIN Projectuser.sy_F01151 d WITH (NOLOCK) ON CAST(a.EmployeeNo AS INT) = CAST(d.EAAN8 AS INT) AND d.EAIDLN = 0 AND d.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(d.EAETP))) = 'E' 
				OUTER APPLY
				(
					SELECT x.RequisitionNo, z.ApprovalStatus, RTRIM(x.RequisitionDescription) AS CEADescription 
					FROM dbo.Requisition x WITH (NOLOCK)
						INNER JOIN dbo.RequisitionStatus y WITH (NOLOCK) ON x.RequisitionID = y.RequisitionID
						INNER JOIN dbo.ApprovalStatus z WITH (NOLOCK) ON y.ApprovalStatusID = z.ApprovalStatusID
					WHERE RTRIM(x.RequisitionNo) = @requisitionNo
				) e
			WHERE RTRIM(c.ApprovalGroupType) = 'Secretary of CEO'

            UNION

            SELECT	(SELECT RequisitionNo FROM dbo.Requisition WITH (NOLOCK) WHERE RequisitionID = a.RequisitionID) AS RequisitionNo,
					ISNULL(e.SubstituteEmpNo, f.SubEmpNo) AS ApproverEmpNo,
					(SELECT FullName FROM dbo.ApplicationUser WHERE EmployeeNo = ISNULL(e.SubstituteEmpNo, f.SubEmpNo)) AS ApproverName,                   
					LTRIM(RTRIM(ISNULL(g.EAEMAL, ''))) AS ApproverEmail,                    
                   (SELECT ApprovalStatus FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE ApprovalStatusID = a.ApprovalStatusID) AS ApprovalStatus,				   
				   '' AS CEADescription
            FROM dbo.RequisitionStatus AS a WITH (NOLOCK)
                INNER JOIN dbo.RequisitionStatusDetail AS b WITH (NOLOCK) ON b.RequisitionStatusID = a.RequisitionStatusID 
				INNER JOIN dbo.ApprovalGroup AS c WITH (NOLOCK) ON c.ApprovalGroupID = b.ApprovalGroupID
                INNER JOIN dbo.ApplicationUser AS d WITH (NOLOCK) ON d.ApplicationUserID = b.ApplicationUserID
                LEFT JOIN Gen_Purpose.genuser.fnGetActiveSubstitutes('WFCEA', '') AS e ON e.WFFromEmpNo = d.EmployeeNo
                LEFT JOIN Projectuser.syLeaveRequisition AS f  WITH (NOLOCK) ON f.EmpNo = d.EmployeeNo AND RTRIM(f.LeaveType) = 'AL' 
					AND RTRIM(f.RequestStatusSpecialHandlingCode) = 'Closed' AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 126)) BETWEEN f.ActualLeaveStartDate AND f.ActualLeaveReturnDate - 1
				LEFT JOIN Projectuser.sy_F01151 g WITH (NOLOCK) ON ISNULL(e.SubstituteEmpNo, f.SubEmpNo) = CAST(g.EAAN8 AS INT) AND g.EAIDLN = 0 AND g.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(g.EAETP))) = 'E' 
             WHERE a.RequisitionID = @requisitionID 
				AND b.ApprovalStatusID = @submittedForApprovalID 
				AND b.GroupRountingSequence = @groupRountingSequence 
				AND b.RoutingSequence = @minRoutingSequence 
				AND RTRIM(c.ApprovalGroup) <> 'Chairman' 
				AND (e.SubstituteEmpNo IS NOT NULL OR f.SubEmpNo IS NOT NULL)
        END
        
		ELSE
        BEGIN
		
			PRINT 'Goes here - No Chairman'

			SELECT	RTRIM(a.RequisitionNo) AS RequisitionNo,
					CAST(f.EmployeeNo AS INT) AS ApproverEmpNo,
					RTRIM(f.FullName) AS ApproverName,					
					LTRIM(RTRIM(ISNULL(g.EAEMAL, ''))) AS ApproverEmail, 
					e.ApprovalStatus AS ApprovalStatus,
					RTRIM(a.RequisitionDescription) AS CEADescription					
			FROM dbo.Requisition a WITH (NOLOCK)
				INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
				INNER JOIN dbo.RequisitionStatusDetail c WITH (NOLOCK) ON b.RequisitionStatusID = c.RequisitionStatusID
				INNER JOIN dbo.ApprovalStatus e WITH (NOLOCK) ON b.ApprovalStatusID = e.ApprovalStatusID
				INNER JOIN dbo.ApplicationUser f WITH (NOLOCK) ON c.ApplicationUserID = f.ApplicationUserID
				LEFT JOIN Projectuser.sy_F01151 g WITH (NOLOCK) ON CAST(f.EmployeeNo AS INT) = CAST(g.EAAN8 AS INT) AND g.EAIDLN = 0 AND g.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(g.EAETP))) = 'E' 
			WHERE a.RequisitionID = @requisitionID
				--AND c.ApprovalStatusID = @submittedForApprovalID 
				AND c.GroupRountingSequence = @groupRountingSequence 
				AND c.RoutingSequence = @minRoutingSequence 
            
			UNION

			SELECT	RTRIM(a.RequisitionNo) AS RequisitionNo,
					CAST(f.EmployeeNo AS INT) AS ApproverEmpNo,
					RTRIM(f.FullName) AS ApproverName,					
					LTRIM(RTRIM(ISNULL(i.EAEMAL, ''))) AS ApproverEmail, 
					e.ApprovalStatus AS ApprovalStatus,
					RTRIM(a.RequisitionDescription) AS CEADescription
			FROM dbo.Requisition a WITH (NOLOCK)
				INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
				INNER JOIN dbo.RequisitionStatusDetail c WITH (NOLOCK) ON b.RequisitionStatusID = c.RequisitionStatusID
				INNER JOIN dbo.ApprovalStatus e WITH (NOLOCK) ON b.ApprovalStatusID = e.ApprovalStatusID
				INNER JOIN dbo.ApplicationUser f WITH (NOLOCK) ON c.ApplicationUserID = f.ApplicationUserID
				OUTER APPLY Projectuser.fnGetActiveSubstitute(f.EmployeeNo, 'WFCEA', '') g
				OUTER APPLY	
				(
					SELECT x.RequisitionNo AS LeaveNo, x.EmpNo, x.SubEmpNo, x.LeaveType 
					FROM Projectuser.syLeaveRequisition x WITH (NOLOCK)
					WHERE x.EmpNo = f.EmployeeNo
						AND RTRIM(x.LeaveType) = 'AL' 
						AND RTRIM(x.RequestStatusSpecialHandlingCode) = 'Closed' 
						AND CONVERT(datetime, CONVERT(varchar, GETDATE(), 126)) BETWEEN x.ActualLeaveStartDate AND x.ActualLeaveReturnDate - 1
				) h
				LEFT JOIN Projectuser.sy_F01151 i WITH (NOLOCK) ON ISNULL(g.SubstituteEmpNo, h.SubEmpNo) = CAST(i.EAAN8 AS INT) AND i.EAIDLN = 0 AND i.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(i.EAETP))) = 'E' 
			WHERE a.RequisitionID = @requisitionID 
				AND c.ApprovalStatusID = @submittedForApprovalID   
				AND c.GroupRountingSequence = @groupRountingSequence 
				AND c.RoutingSequence = @minRoutingSequence 
				AND
				(
					g.SubstituteEmpNo IS NOT NULL OR
					h.SubEmpNo IS NOT NULL
				)

    --        SELECT	(SELECT RequisitionNo  FROM dbo.Requisition WITH (NOLOCK)    WHERE RequisitionID    = a.RequisitionID) AS RequisitionNo,                  
				--	ISNULL(d.SubstituteEmpNo, e.SubEmpNo) AS ApproverEmpNo,
				--	(SELECT FullName FROM dbo.ApplicationUser WITH (NOLOCK) WHERE EmployeeNo = ISNULL(d.SubstituteEmpNo, e.SubEmpNo)) AS ApproverName,                   
				--	LTRIM(RTRIM(ISNULL(g.EAEMAL, ''))) AS ApproverEmail, 
				--   (SELECT ApprovalStatus FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE ApprovalStatusID = a.ApprovalStatusID) AS ApprovalStatus,                   
				--   '' AS CEADescription
    --         FROM dbo.RequisitionStatus AS a WITH (NOLOCK)
    --            INNER JOIN dbo.RequisitionStatusDetail AS b WITH (NOLOCK) ON b.RequisitionStatusID = a.RequisitionStatusID
    --            INNER JOIN dbo.ApplicationUser AS c WITH (NOLOCK) ON c.ApplicationUserID = b.ApplicationUserID                
				--OUTER APPLY Projectuser.fnGetActiveSubstitute(c.EmployeeNo, 'WFCEA', '') d
    --            LEFT JOIN Projectuser.syLeaveRequisition AS e WITH (NOLOCK) ON e.EmpNo = c.EmployeeNo AND RTRIM(e.LeaveType) = 'AL' AND RTRIM(e.RequestStatusSpecialHandlingCode) = 'Closed' 
				--	AND CONVERT(datetime, CONVERT(varchar, GETDATE(), 126)) BETWEEN e.ActualLeaveStartDate AND e.ActualLeaveReturnDate - 1
				--LEFT JOIN Projectuser.sy_F01151 g WITH (NOLOCK) ON ISNULL(d.SubstituteEmpNo, e.SubEmpNo) = CAST(g.EAAN8 AS INT) AND g.EAIDLN = 0 AND g.EARCK7 = 1 AND UPPER(LTRIM(RTRIM(g.EAETP))) = 'E' 
    --         WHERE a.RequisitionID = @requisitionID 
				--AND b.ApprovalStatusID = @submittedForApprovalID 
				--AND b.GroupRountingSequence = @groupRountingSequence 
				--AND b.RoutingSequence = @minRoutingSequence 
				--AND
    --               (
    --                   d.SubstituteEmpNo IS NOT NULL OR
    --                   e.SubEmpNo IS NOT NULL
    --               )
        END
    END

	ELSE 
	BEGIN

		SELECT	@requisitionNo AS RequisitionNo,
				0 AS ApproverEmpNo,
				NULL AS ApproverName,					
				NULL AS ApproverEmail, 					
				NULL AS ApprovalStatus,
				NULL AS CEADescription
    END 