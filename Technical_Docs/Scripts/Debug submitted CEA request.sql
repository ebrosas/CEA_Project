--DECLARE	@ceaNo	VARCHAR(50) = '20230045'		--Draft
DECLARE	@ceaNo	VARCHAR(50) = '20230046'		--Submitted for Approval
--DECLARE	@ceaNo	VARCHAR(50) = '20200028'		--Rejected
--DECLARE	@ceaNo	VARCHAR(50) = '20200225'		--Closed



	--Get the requisition detail
	SELECT * FROM dbo.Requisition a WITH (NOLOCK)
	WHERE RTRIM(a.RequisitionNo) = @ceaNo

	SELECT * FROM dbo.RequisitionStatus a WITH (NOLOCK)
	WHERE a.RequisitionID = (SELECT RequisitionID FROM dbo.Requisition WHERE RTRIM(RequisitionNo) = @ceaNo)

	--Get the current workflow status
	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE a.ApprovalStatusID = 
	(
		SELECT y.ApprovalStatusID 
		FROM dbo.Requisition x WITH (NOLOCK)
			INNER JOIN dbo.RequisitionStatus y WITH (NOLOCK) ON x.RequisitionID = y.RequisitionID
		WHERE RTRIM(x.RequisitionNo) = @ceaNo
	)
		
	--Check JDE associated record
	SELECT a.ABAN8 AS CEANo, a.ABEFTB AS CommissionDate, LTRIM(RTRIM(a.ABALPH)) AS RequisitionDesc, a.ABUSER AS UserID, a.ABJOBN AS WorkstationID,
		a.ABUPMT AS TimeLastUpdated, Projectuser.ConvertFromJulian(a.ABUPMJ) AS DateUpdated,
		a.ABAT1 AS AddressType1,
		a.* 
	FROM Projectuser.sy_F0101 a WITH (NOLOCK)
	WHERE a.ABAN8 = CAST(@ceaNo AS FLOAT)

	--Get Schedule of Expenses
	SELECT * FROM dbo.Expense a WITH (NOLOCK)	
	WHERE a.RequisitionID = CAST(@ceaNo AS INT)

	--Get file attachments
	SELECT * FROM [dbo].[RequisitionAttachments] a WITH (NOLOCK)
	WHERE a.RequisitionID = (SELECT RequisitionID FROM dbo.Requisition WHERE RTRIM(RequisitionNo) = @ceaNo)

	--Get requisition approvers
	SELECT b.* 
	FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
		INNER JOIN dbo.ApprovalGroup b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
	WHERE a.RequisitionStatusID = 
	(
		SELECT RequisitionStatusID 
		FROM dbo.RequisitionStatus WITH (NOLOCK) 
		WHERE RequisitionID = (SELECT RequisitionID FROM dbo.Requisition WHERE RTRIM(RequisitionNo) = @ceaNo)
	)

/*	Debug:

	--Get all approval statuses
	SELECT * FROM dbo.ApprovalStatus a WITH (NOLOCK)

	BEGIN TRAN T1

	DELETE FROM [dbo].[RequisitionAttachments]
	WHERE RequisitionID = 4074

	DELETE FROM dbo.Expense
	WHERE RequisitionID = 20230016

	DELETE FROM dbo.Expense
	WHERE RequisitionID = CAST('20230015' AS INT)

	DELETE FROM dbo.Expense
	WHERE RTRIM(CAST(RequisitionID AS VARCHAR(50))) = '20230026' 


	ROLLBACK TRAN T1
	COMMIT TRAN T1

*/