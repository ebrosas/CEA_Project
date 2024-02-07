DECLARE	@requisitionNo	INT = 20230141   

	--Get request details
	SELECT b.ProjectNo, b.CostCenter, b.FiscalYear, a.Description, a.RequisitionDescription,
		a.UseNewWF, b.ProjectType, a.UseNewWF, a.CategoryCode1 AS ItemCode, a.* 
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
	WHERE RTRIM(a.RequisitionNo) = CAST(@requisitionNo AS VARCHAR(50))

	--Get request status
	SELECT 
		b.CurrentSequence, b.RequisitionStatusID, 		
		c.ApprovalStatusID AS ApprovalStatusID_Header,
		b.ApprovalStatusID AS ApprovalStatusID_Detail, 
		c.GroupRountingSequence,
		c.RoutingSequence,
		B.RequisitionStatusID,
		c.RequisitionStatusDetailID,
		a.RequisitionNo, a.RequisitionID, 
		d.ApprovalGroup,  e.ApprovalStatus, e.StatusCode, e.StatusHandlingCode, 
		c.ApplicationUserID, c.IsAnonymousUser,
		f.EmpNo AS AssignedEmpNo, f.EmpName AS AssignedEmpName,		
		c.ApprovalStatusID,
		c.ApprovalGroupID, 
		c.ApplicationUserID,
		c.ApproverComment,
		e.* 
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
		INNER JOIN dbo.RequisitionStatusDetail c WITH (NOLOCK) ON b.RequisitionStatusID = c.RequisitionStatusID
		INNER JOIN dbo.ApprovalGroup d WITH (NOLOCK) ON c.ApprovalGroupID = d.ApprovalGroupID 
		INNER JOIN dbo.ApprovalStatus e WITH (NOLOCK) ON c.ApprovalStatusID = e.ApprovalStatusID
		--LEFT JOIN dbo.ApplicationUser f WITH (NOLOCK) ON c.ApplicationUserID = f.ApplicationUserID		
		OUTER APPLY
		(
			SELECT x.EmployeeNo AS EmpNo, x.FullName AS EmpName, x.ApplicationUserID 
			FROM dbo.ApplicationUser x WITH (NOLOCK)
			WHERE x.ApplicationUserID = c.ApplicationUserID

			UNION
            
			SELECT x.EmpNo, x.EmpName, x.EmpNo AS ApplicationUserID 
			FROM Projectuser.Vw_MasterEmployeeJDE x
			WHERE x.EmpNo = c.ApplicationUserID
				AND c.IsAnonymousUser = 1
		) f
	WHERE RTRIM(a.RequisitionNo) = CAST(@requisitionNo AS VARCHAR(50))
	ORDER BY c.GroupRountingSequence, c.RoutingSequence, c.IsAnonymousUser

	--Get workflow details
	SELECT a.CEADescription, * FROM Projectuser.sy_CEAWF a WITH (NOLOCK)
	WHERE a.CEARequisitionNo = @requisitionNo

	--Get workflow assigned person
	SELECT * FROM Projectuser.sy_CurrentDistributionMember a WITH (NOLOCK)
	WHERE a.CurrentDistMemReqTypeNo = @requisitionNo

	--Get routine history
	SELECT * FROM Projectuser.sy_History a WITH (NOLOCK)
	WHERE a.HistReqNo = @requisitionNo
		AND a.HistReqType = 22
	ORDER BY a.HistCreatedDate DESC

	--Get the current approval sequence
	SELECT a.CurrentSequence 
	FROM dbo.RequisitionStatus a WITH (NOLOCK)
	WHERE a.RequisitionID = (
		SELECT x.RequisitionID FROM dbo.Requisition x WITH (NOLOCK)
		WHERE RTRIM(x.RequisitionNo) = CAST(@requisitionNo AS VARCHAR(50))
	)


/*	Debug:

	exec [Projectuser].[spGetCEAAdministratorEmailList] 4114, 'Uploader'

	BEGIN TRAN T1

	DELETE FROM Projectuser.sy_CEAWF 
	WHERE CEARequisitionNo = 20230043

	DELETE FROM dbo.RequisitionStatusDetail
	WHERE RequisitionStatusDetailID BETWEEN 41181 AND 41184

	DELETE FROM dbo.RequisitionStatusDetail
	WHERE RequisitionStatusDetailID = 41191

	DELETE FROM Projectuser.sy_History 
	WHERE HistReqNo = 20230043
		AND HistReqType = (
			SELECT ReqTypeID FROM Projectuser.sy_RequestType x WITH (NOLOCK)
			WHERE RTRIM(x.ReqTypeCode) = 'CEAREQ'
		)

	UPDATE dbo.RequisitionStatus
    SET CurrentSequence = 1
	WHERE RequisitionStatusID = 10056

	UPDATE dbo.RequisitionStatus
    SET ApprovalStatusID = 3		--(Notes: 3 = Approved; 5 = Awaiting Approval)
	WHERE RequisitionStatusID = 9853

	UPDATE dbo.RequisitionStatusDetail
	SET ApprovalStatusID = 9
	WHERE RequisitionStatusDetailID IN 
	(
		40569,
		40571,
		40570
	)

	UPDATE dbo.RequisitionStatus 
	SET ApprovalStatusID = 5
	WHERE RequisitionStatusID = 10013

	ROLLBACK TRAN T1
	COMMIT TRAN T1

	EXEC Projectuser.spGetApproverList 4115, 1, 'SubmittedForApproval'

	--Get currently assigned person
	SELECT * FROM Projectuser.fnGetCEAAssignedPerson('20230053')

*/