/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_ChangeRequisitionStatus 
*	Description: This stored procedure is used to recall, activate, and re-open a CEA request
*
*	Date:			Author:		Rev.#:		Comments:
*	07/08/2023		Ervin		1.0			Created
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_ChangeRequisitionStatus
(	
	@requisitionNo		AS VARCHAR(12),
	@actionType			AS VARCHAR(50),
	@empNo				AS INT,
	@comments			AS VARCHAR(500),
	@rowsAffected		INT OUTPUT,
	@hasError			BIT OUTPUT,
	@retError			INT OUTPUT,
	@retErrorDesc		VARCHAR(200) OUTPUT
)
AS		
BEGIN 

	--Define constants
	DECLARE @CONST_RETURN_OK	INT = 0,
			@CONST_RETURN_ERROR	INT = -1

	DECLARE @newStatusID 				INT = 0,
			@currentSequence			INT = 0,
			@requisitionStatusID		INT = 0,
			@applicationUserID			INT = 0,
			@lastSubmittedDate			DATETIME = NULL,
			@groupRountingSequence		INT = 0,
			@uploaderApprovalGroupID	INT = 0,
			@requisitionID				INT = 0,
			@rejectorEmpNo				INT = 0,
			@poCount					INT = 0,
			@rejectStatusID				INT = 0,
			@createdByEmpNo				INT = 0,
			@costCenter					VARCHAR(12) = '',
			@ccManagerEmpNo				INT = 0,
			@isSystemAdmin				BIT = 0,
			@isCreator					BIT = 0,
			@isManager					BIT = 0

	--Get the requisition id
	SELECT	@requisitionID = a.RequisitionID, 
			@createdByEmpNo = a.CreatedByEmpNo 
	FROM dbo.Requisition a WITH (NOLOCK) 
	WHERE RTRIM(a.RequisitionNo) = RTRIM(@requisitionNo)

	--Get applicationuser id
	SELECT @applicationUserID = a.ApplicationUserID 
	FROM dbo.ApplicationUser a WITH (NOLOCK) 
	WHERE a.EmployeeNo = @empNo

	--Get the requisition status id and current sequence
	SELECT	@requisitionStatusID = a.RequisitionStatusID,
			@currentSequence = a.CurrentSequence 
	FROM dbo.RequisitionStatus a WITH (NOLOCK)  
	WHERE a.RequisitionID = @requisitionID
    
	--Get last submitted date
	SELECT @lastSubmittedDate = a.SubmittedDate 
	FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
	WHERE a.RequisitionStatusID = @requisitionStatusID

	--Reject status ID
	SELECT @rejectStatusID = a.ApprovalStatusID 
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = 'Rejected'
	
	--Get the cost ceter
	SELECT @costCenter = RTRIM(a.CostCenter) 
	FROM dbo.Project a WITH (NOLOCK) 
	WHERE RTRIM(a.ProjectNo) = (SELECT RTRIM(ProjectNo) FROM dbo.Requisition WITH (NOLOCK) WHERE RTRIM(RequisitionNo) = RTRIM(@requisitionNo))
	
	--Get the cost center manager
	IF ISNULL(@costCenter, '') <> ''
	BEGIN
    
		SELECT TOP 1 @ccManagerEmpNo = ManagerNo 
		FROM Projectuser.Master_CostCenter a WITH (NOLOCK) 
		WHERE RTRIM(CostCenter) = @costCenter
	END 

	--Check the employee is a System Administrator
	IF EXISTS 
	(
		SELECT 1
		FROM Projectuser.sy_DistributionMember a
			CROSS APPLY
			(
				SELECT * FROM Projectuser.sy_DistributionList
				WHERE UPPER(RTRIM(DistListCode)) = 'CEAADMIN'
					AND DistListID = a.DistMemDistListID 
			) b 
		WHERE a.DistMemEmpNo = @empNo
	)
	SET @isSystemAdmin = 1

	--Check if the employee is the one who has created the request
	IF EXISTS
    (
		SELECT 1 FROM dbo.Requisition a WITH (NOLOCK) 
		WHERE RTRIM(a.RequisitionNo) = RTRIM(@requisitionNo) 
			AND a.CreatedByEmpNo = @empNo
	)
	SET @isCreator = 1

	--Check if the employee is the Cost Center Manager
	IF EXISTS
    (
		SELECT 1 FROM Projectuser.Master_CostCenter a WITH (NOLOCK) 
		WHERE RTRIM(a.CostCenter) = RTRIM(@costCenter) 
			AND a.ManagerNo = @empNo
	)
	SET @isManager = 1

	SET @poCount = 0

	--The Requisition is currently in 'Reject' state, change to state 'Submitted for Approval'
	IF RTRIM(@actionType) = 'ActivateRequisition'
	BEGIN 		
				
		--BUSINESS RULE 1. Only the Rejector can re-activate the Rejected Requisition.
		-------------------------------------------------------------------------------
		--Get the rejector empNo and Name
		SELECT TOP 1 @rejectorEmpNo = a.EmployeeNo
		FROM dbo.ApplicationUser a WITH (NOLOCK)
			INNER JOIN dbo.RequisitionStatusDetail b WITH (NOLOCK) on b.ApplicationUserID = a.ApplicationUserID
		WHERE b.ApprovalStatusID = @rejectStatusID
			AND b.RequisitionStatusID = @requisitionStatusID
		ORDER BY b.RequisitionStatusDetailID		

		--Check current user EmpNo with rejector empNo, if not same, then raise error.
		IF @rejectorEmpNo <> @empNo AND @isSystemAdmin = 0
		BEGIN
        
			SELECT	@hasError = 1,
					@retError = -3,
					@retErrorDesc = 'Only the person who has rejected the requisition or the System Administrator is allowed to reactivate it.'
		END 

		IF @hasError = 0
		BEGIN
        
			--Get the requistion StatusID for 'Submitted for Approval'
			SELECT @newStatusID = ApprovalStatusID 
			FROM dbo.ApprovalStatus a WITH (NOLOCK)
			WHERE RTRIM(StatusCode) = 'Reactivated'

			--Get the routing sequence of the rejected user (approval cannot go beyond this line, so its safe to get sequence from here)
			SELECT @groupRountingSequence = GroupRountingSequence 
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE RequisitionStatusID = @requisitionStatusID
				AND ApprovalStatusID = (SELECT ApprovalStatusID FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE RTRIM(StatusCode) = 'Rejected')

			--Get the approvalgroup id though it is ignorant here
			SELECT TOP 1 @uploaderApprovalGroupID = ApprovalGroupID 
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK) 
			WHERE RequisitionStatusID = @requisitionStatusID
				AND ApprovalStatusID = (SELECT ApprovalStatusID FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE RTRIM(StatusCode) = 'Rejected')

			--The rejected Requisition is activated and it should reflect in OneWorld
			UPDATE Projectuser.sy_F0101	
			SET	ABAT1 = 'JA'	
			WHERE ABAN8 = @requisitionNo

			--Get the number of affected rows
			SELECT @rowsAffected = @@ROWCOUNT

			SELECT @comments = 'Re-activated - ' + @comments
		END 
	END

	--The requisition is currently in 'Submitted' or 'Approved' state, so change it to 'Cancel' state
	ELSE IF RTRIM(@actionType) = 'RecallRequisition' 	
	BEGIN
		
		--:BUSINESS RULE 1. A requisition can be recalled if no PO's are raised.
		-------------------------------------------------------------------------------		
		--Check if the Requisition has any PO's. If there any, then cannot be recalled. Raise error.
		SELECT @poCount = COUNT(*) 
		FROM Projectuser.Vw_PurchaseOrderJDE a WITH (NOLOCK) 
		WHERE RTRIM(a.CEANumber) = RTRIM(@requisitionNo)
	
		--Check the total PO for the current RequisitionNo, if not 0, then raise error.
		IF @poCount > 0
		BEGIN
        
			SELECT	@hasError = 1,
					@retError = -2,
					@retErrorDesc = 'This requisition already contains POs hence cannot be recalled.'
		END 

		--:BUSINESS RULE 2. Only the creator or cost center manager or a system admin can recall a requisition
		-------------------------------------------------------------------------------		
		IF @isCreator = 0 AND @isManager = 0 AND @isSystemAdmin = 0
		BEGIN
        
			SELECT	@hasError = 1,
					@retError = -3,
					@retErrorDesc = 'Only the Secretary, Cost Center Manager, or the System Administrator can recall this requisition.'
		END 
	
		IF @hasError = 0
		BEGIN
        
			--Get the requistion StatusID for 'Cancelled'
			SELECT @newStatusID = ApprovalStatusID 
			FROM dbo.ApprovalStatus a WITH (NOLOCK)  
			WHERE RTRIM(StatusCode) = 'Cancelled'

			--Once the Requisition is recalled, the sequencing should stop
			SELECT @groupRountingSequence = -1

			--Get the approvalgroup id though it is ignorant here
			SELECT @uploaderApprovalGroupID = -1

			-- Added by NGF 2008.08.10 10:12
			-- Update the JDE also
			UPDATE Projectuser.sy_F0101
			SET	ABAT1 = 'JR'	
			WHERE ABAN8 = @requisitionNo

			--Get the number of affected rows
			SELECT @rowsAffected = @@ROWCOUNT

		END 
	END 

	--The Requisition is currently in 'Close' state, change to state 'Uploaded to OneWorld'
	ELSE IF RTRIM(@actionType) = 'OpenRequisition' 	 
	BEGIN
			
		--:BUSINESS RULE 1. Only the System Administrator can re-open a closed requisition.
		-------------------------------------------------------------------------------	
		IF @isSystemAdmin = 0
		BEGIN
        
			SELECT	@hasError = 1,
					@retError = -4,
					@retErrorDesc = 'Only the System Administrator is allowed to re-open a closed requisition.'
		END 

		IF @hasError = 0
		BEGIN
        
			--Get the requistion StatusID for 'UploadedToOneWorld'
			SELECT @newStatusID = ApprovalStatusID 
			FROM dbo.ApprovalStatus a WITH (NOLOCK)
			WHERE RTRIM(StatusCode) = 'UploadedToOneWorld'

			--This is re-opened only to create PR's or similar purpose, but there wont be a sequencing!
			SELECT @groupRountingSequence = -1

			--get the approvalgroup id though it is ignorant here
			SELECT @uploaderApprovalGroupID = -1

			--Set the number of affected rows to 1
			SELECT @rowsAffected = 1
		END 
	END 

	IF @hasError = 0 AND @rowsAffected > 0
	BEGIN
    
		--Insert Requisition status detail indicating the current action
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
			ApproverComment, 
			GroupRountingSequence
		)
		VALUES  
		(
			@requisitionStatusID, 
			@lastSubmittedDate, 
			@uploaderApprovalGroupID, 
			@applicationUserID, 
			@newStatusID,
			GETDATE(), 
			1, 
			1, 
			@comments, 
			@groupRountingSequence
		)				

		--Add another line for 'Submitted for Approval' if the Requisition is reactivated
		IF RTRIM(@actionType) = 'ActivateRequisition'
		BEGIN 	

			--Get the requistion StatusID for 'Submitted for Approval'
			SELECT @newStatusID = ApprovalStatusID 
			FROM dbo.ApprovalStatus a WITH (NOLOCK) 
			WHERE RTRIM(a.StatusCode) = 'Submitted'
		END 

		--Update the requisition status to reflect the new action
		Update dbo.RequisitionStatus
		SET ApprovalStatusID = @newStatusID,
			CurrentSequence = @groupRountingSequence
		WHERE RequisitionID = @requisitionID

		--Add another line for 'Submitted for Approval' if the Requisition is reactivated
		IF RTRIM(@actionType) = 'ActivateRequisition'
		BEGIN 	

			--Get the requistion StatusID for 'Submitted for Approval'
			SELECT @newStatusID = ApprovalStatusID 
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
				@requisitionStatusID, 
				@lastSubmittedDate, 
				@uploaderApprovalGroupID, 
				@applicationUserID, 
				@newStatusID,
	 			GETDATE(), 
				1, 
				1, 
				'', 
				@groupRountingSequence
			)
		END 
	END 

END 


/*	Debug:

PARAMETERS:
	@requisitionNo		AS VARCHAR(12),
	@actionType			AS VARCHAR(50),
	@empNo				AS INT,
	@comments			AS VARCHAR(500),
	@rowsAffected		INT OUTPUT,
	@hasError			BIT OUTPUT,
	@retError			INT OUTPUT,
	@retErrorDesc		VARCHAR(200) OUTPUT


	DECLARE	@return_value int,
			@rowsAffected int,
			@hasError bit,
			@retError int,
			@retErrorDesc varchar(200)

	EXEC	@return_value = [Projectuser].[Pr_ChangeRequisitionStatus]
			@requisitionNo = N'20200029',
			@actionType = N'ActivateRequisition',
			@empNo = 10003512,
			@comments = N'Test reactivating rejected CEA',
			@rowsAffected = @rowsAffected OUTPUT,
			@hasError = @hasError OUTPUT,
			@retError = @retError OUTPUT,
			@retErrorDesc = @retErrorDesc OUTPUT

	SELECT	@rowsAffected as N'@rowsAffected',
			@hasError as N'@hasError',
			@retError as N'@retError',
			@retErrorDesc as N'@retErrorDesc'

	EXEC Projectuser.Pr_ChangeRequisitionStatus '20230039', 'RecallRequisition', 10003512, 'Test recall'								--Recall request
	EXEC Projectuser.Pr_ChangeRequisitionStatus '20200029', 'ActivateRequisition', 10003512, 'Test reactivating rejected CEA', 0, 		--Reactivate request


*/









