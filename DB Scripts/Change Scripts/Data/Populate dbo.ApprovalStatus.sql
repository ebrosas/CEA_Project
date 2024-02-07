
	--Get all approval statuses
	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)
	ORDER BY a.StatusCode

	SELECT DISTINCT a.StatusHandlingCode, a.StatusHandlingDesc FROM dbo.ApprovalStatus a WITH (NOLOCK)

	SELECT a.StatusHandlingCode, a.StatusHandlingDesc, a.StatusCode, a.ApprovalStatus
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusHandlingCode) = 'Open'
	ORDER BY a.StatusCode

/*
	
	BEGIN TRAN T1

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '120'	--Approved By Approver
	WHERE RTRIM(StatusCode) IN
	(
		'Approved',
		'ChairmanApproved'
	)

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '05'		--Waiting For Approval
	WHERE RTRIM(StatusCode) IN 
	(
		'AwaitingApproval',
		'SubmittedForApproval',
		'AwaitingChairmanApproval',
		'Submitted'
	)

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '101'	--Cancelled By User
	WHERE RTRIM(StatusCode) = 'Cancelled'

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '123'	--Closed by Approver
	WHERE RTRIM(StatusCode) IN
	(
		'Closed',
		'Completed'
	)
	
	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '605'	--Draft
	WHERE RTRIM(StatusCode) = 'Draft'

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '603'	--Reactivated
	WHERE RTRIM(StatusCode) = 'Reactivated'

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '122'	--Reassigned to Other Approver
	WHERE RTRIM(StatusCode) = 'Reassigned'

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '110'	--Rejected By Approver
	WHERE RTRIM(StatusCode) IN
	(
		'Rejected',
		'RejectedTmp'
	)

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '02'		--Request Sent
	WHERE RTRIM(StatusCode) IN
	(
		'Active'
	)

	--UPDATE dbo.ApprovalStatus
	--SET WFStatusCode = '300'		--Submitted for Approval
	--WHERE RTRIM(StatusCode) IN
	--(
	--	'Submitted'
	--)

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '600'		--Uploaded to OneWorld
	WHERE RTRIM(StatusCode) = 'UploadedToOneWorld'

	UPDATE dbo.ApprovalStatus
	SET WFStatusCode = '606'		--All Open Statuses
	WHERE RTRIM(StatusCode) = 'DraftAndSubmitted'


	--Code below is no longer required
	--Set "Open" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'Open',
		StatusHandlingDesc = 'Waiting for Approval'
	WHERE RTRIM(StatusCode) NOT IN 
	(
		'Cancelled',
		'Rejected',
		'RejectedTmp',
		'Approved',
		'ChairmanApproved',
		'Closed',
		'Completed',
		'Draft',
		'UploadedToOneWorld'		
	)

	--Set "Cancelled" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'Cancelled',
		StatusHandlingDesc = 'Cancelled'
	WHERE RTRIM(StatusCode) IN 
	(
		'Cancelled'
	)

	--Set "Rejected" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'Rejected',
		StatusHandlingDesc = 'Rejected'
	WHERE RTRIM(StatusCode) IN 
	(
		'Rejected',
		'RejectedTmp'
	)

	--Set "Approved" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'Approved',
		StatusHandlingDesc = 'Approved'
	WHERE RTRIM(StatusCode) IN 
	(
		'Approved',
		'ChairmanApproved'
	)

	--Set "Closed" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'Closed',
		StatusHandlingDesc = 'Closed'
	WHERE RTRIM(StatusCode) IN 
	(
		'Closed',
		'Completed'
	)

	--Set "Draft" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'Draft',
		StatusHandlingDesc = 'Draft'
	WHERE RTRIM(StatusCode) IN 
	(
		'Draft'		
	)

	--Set "UploadedToOneWorld" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'PostedJDE',
		StatusHandlingDesc = 'Uploaded to OneWorld'
	WHERE RTRIM(StatusCode) IN 
	(
		'UploadedToOneWorld'		
	)

	--Set "UploadedToOneWorld" status handling code
	UPDATE dbo.ApprovalStatus
	SET StatusHandlingCode = 'AllOpen',
		StatusHandlingDesc = 'All Open Statuses'
	WHERE RTRIM(StatusCode) IN 
	(
		'DraftAndSubmitted'		
	)

	ROLLBACK TRAN T1
	COMMIT TRAN T1

*/