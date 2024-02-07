/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.spChangeRequisitionStatus 
*	Description: This SP changes the current state of a Requisition
*
*	Date:			Author:		Rev.#:		Comments:
*	10/08/2008		Zaharan		1.0			Created
*	04/12/2022		Ervin		1.1			Fixed the bug that cause discrepancy in the CEA requisition status 
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.spChangeRequisitionStatus
(	
	@RequisitionNo		AS VARCHAR(12),
	@ActionType			AS VARCHAR(50),
	@EmpNo				AS INT,
	@Comment			AS VARCHAR(500)
)
As		
BEGIN 

	declare @NewStatusID 				as int
	declare @CurrentSequence			as int
	declare @RequisitionStatusID		as int
	declare @ApplicationUserID			as int
	declare @LastSubmittedDate			as datetime
	declare @GroupRountingSequence		as int
	declare @UploaderApprovalGroupID	as int
	declare @RequisitionID				as int
	declare @RejectorEmpNo				as int
	declare @POCount					as int
	declare @SysteAdminCount			as int
	declare @RejectStatusID				as int
	declare @CreatedByEmpNo				as int
	declare @CostCenter					as varchar(12)
	declare @CostCenterManagerEmpNo		as int
	declare @count						as int

	--Get the requisition id
	SELECT	@RequisitionID = RequisitionID, 
			@CreatedByEmpNo = CreatedByEmpNo 
	FROM dbo.Requisition a WITH (NOLOCK) 
	WHERE RTRIM(a.RequisitionNo) = RTRIM(@RequisitionNo)

	--Get applicationuser id
	SELECT @ApplicationUserID = ApplicationUserID 
	FROM dbo.ApplicationUser a WITH (NOLOCK) 
	WHERE a.EmployeeNo = @EmpNo

	--Get the requisition status id and current sequence
	SELECT	@RequisitionStatusID = a.RequisitionStatusID,
			@CurrentSequence = a.CurrentSequence 
	FROM dbo.RequisitionStatus a WITH (NOLOCK)  
	WHERE a.RequisitionID = @RequisitionID

	--Get last submitted date
	SELECT @LastSubmittedDate = a.SubmittedDate 
	FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
	WHERE a.RequisitionStatusID = @RequisitionStatusID

	--Reject status ID
	SELECT @RejectStatusID = a.ApprovalStatusID 
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = 'Rejected'
	
	--Get the cost ceter
	Select @CostCenter = RTRIM(a.CostCenter) 
	FROM dbo.Project a WITH (NOLOCK) 
	WHERE RTRIM(a.ProjectNo) = (SELECT RTRIM(ProjectNo) FROM dbo.Requisition WITH (NOLOCK) WHERE RTRIM(RequisitionNo) = RTRIM(@RequisitionNo))
	
	--Get the cost center manager
	SELECT TOP 1 @CostCenterManagerEmpNo = ManagerNo 
	FROM Projectuser.Master_CostCenter a WITH (NOLOCK) 
	WHERE RTRIM(CostCenter) = @CostCenter

	SET @POCount = 0
	SET @count = 0
	SET @SysteAdminCount = 0

	--The Requisition is currently in 'Reject' state, change to state 'Submitted for Approval'
	IF RTRIM(@ActionType) = 'ActivateRequisition'
	BEGIN 		
				
		--BUSINESS RULE 1. Only the Rejector can re-activate the Rejected Requisition.
		-------------------------------------------------------------------------------
		--Get the rejector empNo and Name
		SELECT TOP 1 @RejectorEmpNo = AU.EmployeeNo
		FROM dbo.ApplicationUser AU WITH (NOLOCK)
			INNER JOIN dbo.RequisitionStatusDetail RSD on RSD.ApplicationUserID = AU.ApplicationUserID
		WHERE RSD.ApprovalStatusID = @RejectStatusID
			AND RSD.RequisitionStatusID = @RequisitionStatusID
		ORDER BY RSD.RequisitionStatusDetailID		--Rev. #1.1

		--Check current user EmpNo with rejector empNo, if not same, then raise error.
		IF @RejectorEmpNo <> @EmpNo
		BEGIN
        
			RETURN -1;	--only rejector can reactivate the requisition
		END 

		--Get the requistion StatusID for 'Submitted for Approval'
		SELECT @NewStatusID = ApprovalStatusID 
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(StatusCode) = 'Reactivated'

		--Get the routing sequence of the rejected user (approval cannot go beyond this line, so its safe to get sequence from here)
		SELECT @GroupRountingSequence = GroupRountingSequence 
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
		WHERE RequisitionStatusID = @RequisitionStatusID
			AND ApprovalStatusID = (SELECT ApprovalStatusID FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE RTRIM(StatusCode) = 'Rejected')

		--Get the approvalgroup id though it is ignorant here
		SELECT TOP 1 @UploaderApprovalGroupID = ApprovalGroupID 
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK) 
		WHERE RequisitionStatusID = @RequisitionStatusID
			AND ApprovalStatusID = (SELECT ApprovalStatusID FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE RTRIM(StatusCode) = 'Rejected')

		--the rejected Requisition is activated and it should reflect in OneWorld
		--UPDATE JDE_PRODUCTION.PRODDTA.F0101_ADT // commented by Zaharan on 30th June 2009
		UPDATE JDE_PRODUCTION.PRODDTA.F0101	
		SET	ABAT1 = 'JA'	
		WHERE ABAN8 = @RequisitionNo

		SELECT @Comment = 'Re-activated - ' + @Comment
	End

	--The Requisition is currently in 'Submitted' or 'Approved' state, Change to state 'Cancel'	
	ELSE IF RTRIM(@ActionType) = 'RecallRequisition' 	
	BEGIN
			
		--:BUSINESS RULE 1. A requisition can be recalled if no PO's are raised.
		-------------------------------------------------------------------------------		
		--Check if the Requisition has any PO's. If there any, then cannot be recalled. Raise error.
		Declare @CEANumber as varchar(8)
		Declare @CEANumberTmp as int
	
		SELECT @CEANumberTmp = convert(int, OneWorldABNo) 
		FROM dbo.Requisition a WITH (NOLOCK) 
		WHERE RTRIM(a.RequisitionNo) = RTRIM(@RequisitionNo)

		SELECT @CEANumber = Projectuser.lpad(convert(varchar, @CEANumberTmp), 8, '0')
	
		SELECT @POCount = COUNT(*) 
		FROM Projectuser.PurchaseOrders_JDE a WITH (NOLOCK) 
		WHERE RTRIM(a.CEANumber) = RTRIM(@CEANumber)
	
		--Check the total PO for the current RequisitionNo, if not 0, then raise error.
		IF @POCount>0
		BEGIN
        
			return -2;	--there should be no PO's
		END 

		--:BUSINESS RULE 2. Only the creator or cost center manager or a system admin can recall a requisition
		-------------------------------------------------------------------------------		
		SELECT @count = 
		(
			SELECT count(*) FROM
			(
				SELECT 1 col1 FROM dbo.Requisition a WITH (NOLOCK) WHERE RTRIM(a.RequisitionNo) = RTRIM(@RequisitionNo) AND CreatedByEmpNo = @EmpNo
				
				UNION ALL
				SELECT 1 col1 FROM projectuser.Master_CostCenter a WITH (NOLOCK) WHERE RTRIM(a.CostCenter) = RTRIM(@CostCenter) AND a.ManagerNo = @EmpNo
				  
				UNION ALL
				SELECT 1 col1 
				FROM dbo.ApplicationUser AUB WITH (NOLOCK)
			 		INNER JOIN dbo.ApprovalGroupAssignment AGA WITH (NOLOCK) on AUB.ApplicationUserID = AGA.ApplicationUserID
					INNER JOIN dbo.ApprovalGroupDetail AGD on AGD.ApprovalGroupTypeID = AGA.ApprovalGroupTypeID
				WHERE RTRIM(AGD.UserGroupTypeCode) = 'Admin' 
					AND AUB.EmployeeNo = @EmpNo
			) tbl
		)

		IF @count<0
		BEGIN
        
			return -3; --The caller should be either an admin, secretary or cost center manager
		END 
	
		--Get the requistion StatusID for 'Cancelled'
		SELECT @NewStatusID = ApprovalStatusID 
		FROM dbo.ApprovalStatus a WITH (NOLOCK)  
		WHERE RTRIM(StatusCode) = 'Cancelled'

		--Once the Requisition is recalled, the sequencing should stop
		SELECT @GroupRountingSequence = -1

		--Get the approvalgroup id though it is ignorant here
		SELECT @UploaderApprovalGroupID = -1

		-- Added by NGF 2008.08.10 10:12
		-- Update the JDE also
		--UPDATE JDE_PRODUCTION.PRODDTA.F0101_ADT // commented by Zaharan on 30th June 2009
		UPDATE JDE_PRODUCTION.PRODDTA.F0101
		SET	ABAT1 = 'JR'	
		WHERE ABAN8 = @RequisitionNo

	END 

	--The Requisition is currently in 'Close' state, change to state 'Uploaded to OneWorld'
	ELSE IF RTRIM(@ActionType) = 'OpenRequisition' 	 
	BEGIN
			
		--:BUSINESS RULE 1. Only the Rejector can re-activate the Rejected Requisition.
		-------------------------------------------------------------------------------	
		-------Check if the current user is a System Admin, if not raise error---------
		SELECT @count = 
		(
			SELECT count(*) 
			FROM dbo.ApplicationUser AUB WITH (NOLOCK)
			 	INNER JOIN dbo.ApprovalGroupAssignment AGA WITH (NOLOCK) on AUB.ApplicationUserID = AGA.ApplicationUserID
				INNER JOIN dbo.ApprovalGroupDetail AGD WITH (NOLOCK) on AGD.ApprovalGroupTypeID = AGA.ApprovalGroupTypeID
			WHERE RTRIM(AGD.UserGroupTypeCode) = 'Admin' 
				AND AUB.EmployeeNo = @EmpNo
		) 

		IF @count > 0
		BEGIN
        
			return -4; --The caller should be a system admin
		END 

		--Get the requistion StatusID for 'UploadedToOneWorld'
		SELECT @NewStatusID = ApprovalStatusID 
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(StatusCode) = 'UploadedToOneWorld'

		--This is re-opened only to create PR's or similar purpose, but there wont be a sequencing!
		SELECT @GroupRountingSequence = -1

		--get the approvalgroup id though it is ignorant here
		SELECT @UploaderApprovalGroupID = -1
	END 

	--Insert Requisition status detail indicating the current action
	INSERT INTO RequisitionStatusDetail 
	(
		RequisitionStatusID, 
		SubmittedDate, 
		ApprovalGroupID, 
		ApplicationUserID, 
		ApprovalStatusID, 
		StatusDate, 
		RoutingSequence, 
		PermanentStatus, 
		ApproverComment, 
		GroupRountingSequence
	)
	VALUES  
	(
		@RequisitionStatusID, 
		@LastSubmittedDate, 
		@UploaderApprovalGroupID, 
		@ApplicationUserID, 
		@NewStatusID,
		GETDATE(), 
		1, 
		1, 
		@Comment, 
		@GroupRountingSequence
	)

	--Add another line for 'Submitted for Approval' if the Requisition is reactivated
	IF RTRIM(@ActionType) = 'ActivateRequisition'
	BEGIN 	

		--Get the requistion StatusID for 'Submitted for Approval'
		SELECT @NewStatusID = ApprovalStatusID 
		FROM dbo.ApprovalStatus a WITH (NOLOCK) 
		WHERE RTRIM(StatusCode) = 'Submitted'
	END 

	--Update the requisition status to reflect the new action
	Update dbo.RequisitionStatus
	SET ApprovalStatusID = @NewStatusID,
		CurrentSequence = @GroupRountingSequence
	WHERE RequisitionID = @RequisitionID

	--Add another line for 'Submitted for Approval' if the Requisition is reactivated
	IF RTRIM(@ActionType) = 'ActivateRequisition'
	BEGIN 	

		--Get the requistion StatusID for 'Submitted for Approval'
		SELECT @NewStatusID = ApprovalStatusID 
		FROM dbo.ApprovalStatus a WITH (NOLOCK) 
		WHERE RTRIM(StatusCode) = 'SubmittedForApproval'

		--Insert Requisition status detail indicating the current action
		INSERT  INTO dbo.RequisitionStatusDetail 
		(
			RequisitionStatusID, 
			SubmittedDate, 
			ApprovalGroupID, 
			ApplicationUserID, 
			ApprovalStatusID, 
			StatusDate, 
			RoutingSequence, 
			PermanentStatus, 
			ApproverComment, 
			GroupRountingSequence
		)
		Values 
		(
			@RequisitionStatusID, 
			@LastSubmittedDate, 
			@UploaderApprovalGroupID, 
			@ApplicationUserID, 
			@NewStatusID,
	 		GETDATE(), 
			1, 
			1, 
			'', 
			@GroupRountingSequence
		)
	END 

	RETURN 0

END 


/*	Debug:

	declare @return as int
	exec @return = spChangeRequisitionStatus '20072136', 'RecallRequisition', 10003479, 'test'

	print @return

*/









