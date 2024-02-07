DECLARE	@costCenter	VARCHAR(12) = '5400'

	SELECT	a.ApprovalGroup,
			--@requisitionStatusID AS RequisitionStatusID,
			GETDATE() AS SubmittedDate,
			a.ApprovalGroupID,
			ISNULL(d.ApplicationUserID, c.EmpNo) AS ApplicationUserID,
			--@inQueueID AS ApprovalStatusID,
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
	WHERE RTRIM(a.CostCenter) = @costCenter
		AND RTRIM(a.ApprovalGroup) NOT IN 
		(
			'General Manager', 
			'Chief Executive Officer', 
			'Chairman'
		) 		
	ORDER BY a.ApprovalSequence	 