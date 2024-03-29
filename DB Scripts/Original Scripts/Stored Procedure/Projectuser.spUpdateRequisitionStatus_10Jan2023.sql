USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spUpdateRequisitionStatus]    Script Date: 10/01/2023 12:31:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.spUpdateRequisitionStatus 
*	Description: This SP is used to upload and close a CEA request to JDE
*
*	Date:			Author:		Rev.#:		Comments:
*	09/05/2007		Zaharan		1.0			Created
*	04/12/2022		Ervin		1.1			Fixed the bug that cause discrepancy in the CEA requisition status.  
*******************************************************************************************************************************************************************/

ALTER PROCEDURE [Projectuser].[spUpdateRequisitionStatus]
(	
	@StatusCode			VARCHAR(50),
	@RequisitionID		INT,	
	@EmpNo				INT,
	@ApproverComment	VARCHAR(500)
) 
AS
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK			INT = 0,
			@CONST_RETURN_ERROR			INT = -1

	DECLARE	@hasError					BIT = 0,
			@retError					INT = @CONST_RETURN_OK,
			@rowsAffected				INT = 0,
			@retErrorDesc				VARCHAR(200) = ''	

	DECLARE @StatusID 					INT,
			@CurrentSequence			INT,
			@RequisitionStatusID		INT,
			@ApplicationUserID			INT,
			@LastSubmittedDate			DATETIME,
			@GroupRountingSequence		INT,
			@UploaderApprovalGroupID	INT

	BEGIN TRY

		--Get the requistion StatusID
		SELECT @StatusID = ApprovalStatusID 
		FROM dbo.ApprovalStatus a WITH (NOLOCK) 
		WHERE RTRIM(StatusCode) = RTRIM(@StatusCode)

		--Get applicationuser id
		SELECT @ApplicationUserID = a.ApplicationUserID 
		FROM dbo.ApplicationUser a WITH (NOLOCK) 
		WHERE a.EmployeeNo = @EmpNo

		--Get the requisition status id and current sequence
		SELECT	@RequisitionStatusID = a.RequisitionStatusID,
				@CurrentSequence = a.CurrentSequence  
		FROM dbo.RequisitionStatus a WITH (NOLOCK) 
		WHERE a.RequisitionID = @RequisitionID

		--Get the submission date and routing sequence
		SELECT @LastSubmittedDate = a.SubmittedDate 
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK) 
		WHERE a.RequisitionStatusID = @RequisitionStatusID

		--Get the routing sequence
		SELECT @GroupRountingSequence = MAX(GroupRountingSequence) 
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK) 
		WHERE RequisitionStatusID = @RequisitionStatusID
	
		--Increment the sequence number
		SET @GroupRountingSequence = @GroupRountingSequence + 1

		--Get the approval group id
		SELECT TOP 1 @UploaderApprovalGroupID = a.ApprovalGroupID
		FROM dbo.ApprovalGroup a WITH (NOLOCK)
			INNER JOIN dbo.ApprovalGroupDetail b WITH (NOLOCK) on b.approvalgrouptypeid = a.approvalgrouptypeid
		WHERE UPPER(RTRIM(b.UserGroupTypeCode)) = 'UPLOADER' 

		IF NOT EXISTS
        (
			SELECT 1 FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = (SELECT RequisitionStatusID FROM dbo.RequisitionStatus WITH (NOLOCK) WHERE RequisitionID = @RequisitionID)
				AND a.ApprovalStatusID = @StatusID
		)
		BEGIN
        
			--Insert Requisition status detail statuses
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
				@StatusID,
				GETDATE(), 
				1, 
				1, 
				@ApproverComment, 
				@GroupRountingSequence
			)

			SELECT @rowsAffected = @@ROWCOUNT
		END 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@retError = @CONST_RETURN_ERROR,
					@hasError = 1
		END
		ELSE
        BEGIN 

			--Update the requisition status
			UPDATE dbo.RequisitionStatus
			SET ApprovalStatusID = @StatusID,
				CurrentSequence = @GroupRountingSequence
			WHERE RequisitionID = @RequisitionID
		END 

	END TRY
	BEGIN CATCH

		--Capture the error
		SELECT	@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
				@retErrorDesc = ERROR_MESSAGE(),
				@hasError = 1

	END CATCH
	
END 

/*	Debug:

PARAMETERS:
	@StatusCode			VARCHAR(50),
	@RequisitionID		INT,	
	@EmpNo				INT,
	@ApproverComment	VARCHAR(500)	

	EXEC Projectuser.spUpdateRequisitionStatus 'UploadedToOneWorld', 4252, 10003674, 'Requisition uploaded to OneWorld.'

*/










