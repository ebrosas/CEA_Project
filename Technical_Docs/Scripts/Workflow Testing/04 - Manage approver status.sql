DECLARE	@ceaNo	VARCHAR(50)	= '20230057'
	
	SELECT	c.EmployeeNo AS CurrentlyAssigneEmpNo, 
			c.FullName AS CurrentlyAssignedEmpName, 
			b.ApprovalStatus,
			a.* 
	FROM [dbo].[RequisitionStatusDetail] a
		INNER JOIN dbo.ApprovalStatus b ON a.ApprovalStatusID = b.ApprovalStatusID
		INNER JOIN dbo.ApplicationUser c WITH (NOLOCK) ON a.ApplicationUserID = c.ApplicationUserID
	WHERE a.RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = @ceaNo
			)
		)
	ORDER BY a.GroupRountingSequence, a.RoutingSequence

	SELECT	c.EmployeeNo AS CurrentlyAssigneEmpNo, 
			c.FullName AS CurrentlyAssignedEmpName, 
			b.ApprovalStatus,
			a.* 
	FROM [dbo].[RequisitionStatusDetail] a
		INNER JOIN dbo.ApprovalStatus b ON a.ApprovalStatusID = b.ApprovalStatusID
		INNER JOIN dbo.ApplicationUser c WITH (NOLOCK) ON a.ApplicationUserID = c.ApplicationUserID
	WHERE a.RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = @ceaNo
			)
		)
		AND a.ApplicationUserID = 334

	

/*	Data change:
	
	SELECT * FROM dbo.ApprovalStatus a

	BEGIN TRAN T1
	ROLLBACK TRAN T1
	COMMIT TRAN T1

	UPDATE dbo.RequisitionStatusDetail
	SET dbo.RequisitionStatusDetail.ApprovalStatusID = 5,	--(Notes: 2 = Submitted for Approval, 5 = Awaiting Approval, 8 = Rejected, 9 = In Queue, 10 = Cancelled, 20	= Reassigned, 21 = On Leave)
		dbo.RequisitionStatusDetail.ApproverComment = ''
	FROM dbo.RequisitionStatusDetail a
		INNER JOIN dbo.ApprovalStatus b ON a.ApprovalStatusID = b.ApprovalStatusID
		INNER JOIN dbo.ApplicationUser c WITH (NOLOCK) ON a.ApplicationUserID = c.ApplicationUserID
	WHERE a.RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = '20230047'
			)
		)
		AND a.ApplicationUserID IN (253)
		AND a.GroupRountingSequence = 1

	SELECT * FROM dbo.RequisitionStatusDetail
	WHERE RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = '20230047'
			)
		)
		AND ApplicationUserID = 178
		AND GroupRountingSequence = 2

	DELETE FROM dbo.RequisitionStatusDetail
	WHERE RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = '20230047'
			)
		)
		AND ApplicationUserID = 286
		AND GroupRountingSequence = 2
			
*/

/*	Remove approvers

	BEGIN TRAN T1

	DELETE FROM dbo.RequisitionStatusDetail
	WHERE RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = '20230047 '
			)
		)
		AND ApplicationUserID = 147

	DELETE FROM dbo.RequisitionStatusDetail
	WHERE RequisitionStatusID = 
		(
			SELECT RequisitionStatusID FROM [dbo].[RequisitionStatus]
			WHERE RequisitionID = 
			(
				SELECT RequisitionID FROM [dbo].[Requisition] 
				WHERE RTRIM(RequisitionNo) = '20230047'
			)
		)
		AND ApplicationUserID = 344
		AND RequisitionStatusDetailID = 52480

	ROLLBACK TRAN T1
	COMMIT TRAN T1

*/

/*	Debug:

	--Approval statuses
	SELECT * FROM  dbo.ApprovalStatus a 
	ORDER BY a.ApprovalStatusID

*/
