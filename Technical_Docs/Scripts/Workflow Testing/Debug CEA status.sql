DECLARE @ceaNo	VARCHAR(50) = '20230104'

	SELECT a.CreatedByEmpNo, a.OriginatorEmpNo, a.UseNewWF, a.* 
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE RTRIM(a.RequisitionNo) = @ceaNo

	SELECT b.ApprovalStatus, b.StatusCode, b.StatusHandlingCode, a.ApprovalStatusID, a.* 
	FROM dbo.RequisitionStatus a WITH (NOLOCK)
		INNER JOIN dbo.ApprovalStatus b WITH (NOLOCK) ON a.ApprovalStatusID = b.ApprovalStatusID
	WHERE a.RequisitionID = (
		SELECT x.RequisitionID FROM dbo.Requisition x WITH (NOLOCK)
		WHERE RTRIM(x.RequisitionNo) = @ceaNo
	)

	SELECT a.RequisitionStatusID, a.RequisitionStatusDetailID, a.GroupRountingSequence, a.RoutingSequence, b.ApprovalStatusID, b.ApprovalStatus, b.Description, b.StatusCode, b.StatusHandlingCode, a.* 
	FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
		INNER JOIN dbo.ApprovalStatus b WITH (NOLOCK) ON a.ApprovalStatusID = b.ApprovalStatusID
	WHERE a.RequisitionStatusID = (
		SELECT y.RequisitionStatusID FROM dbo.RequisitionStatus y WITH (NOLOCK)
		WHERE y.RequisitionID = (
			SELECT x.RequisitionID FROM dbo.Requisition x WITH (NOLOCK)
			WHERE RTRIM(x.RequisitionNo) = @ceaNo
		)
	)
	ORDER BY a.GroupRountingSequence, a.RoutingSequence

/*
	
	SELECT * FROM dbo.ApprovalStatus a
	
	SELECT * FROM Projectuser.fnGetWFActionMember('', '', 10003632)

	BEGIN TRAN T1

	--Set the current approval sequence
	UPDATE dbo.RequisitionStatus
	SET CurrentSequence = 6
	WHERE RequisitionStatusID = 9853

	--Set status to "Approved"
	UPDATE dbo.RequisitionStatusDetail
	SET ApprovalStatusID = 3		--(Notes: 3 = Approved; 5 = Awaiting Approval)
	WHERE RequisitionStatusDetailID = 39294

	--Set the current active approver
	UPDATE dbo.RequisitionStatusDetail
	SET ApprovalStatusID = 5		--(Notes: 3 = Approved; 5 = Awaiting Approval)
	WHERE RequisitionStatusDetailID = 39295

	COMMIT TRAN T1

*/
