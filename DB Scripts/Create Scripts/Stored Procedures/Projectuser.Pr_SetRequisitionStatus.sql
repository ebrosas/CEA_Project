/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_Requisition_CUD
*	Description: This stored procedure is used to set the requisition approval status
*
*	Date			Author		Rev. #		Comments:
*	25/07/2023		Ervin		1.0			Created
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_SetRequisitionStatus 
(
    @requisitionID			INT,
    @nextSequence			INT OUTPUT
)
AS
BEGIN

    DECLARE @currentSequence				INT,
            @requisitionStatusID			NUMERIC,
            @approvalGroup					VARCHAR(100),
            @awaitingChairmanApprovalID		INT,
            @awaitingCEOApprovalID			INT,
            @submittedID					INT,
			@rowsAffected					INT = 0

	SELECT	@currentSequence = a.CurrentSequence,
			@requisitionStatusID = RequisitionStatusID
    FROM dbo.RequisitionStatus a WITH (NOLOCK)
    WHERE a.RequisitionID = @requisitionID

    SELECT @nextSequence = Projectuser.GetNextSequence(@requisitionID, @currentSequence)

    SELECT TOP 1 @approvalGroup = b.ApprovalGroup
    FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
        INNER JOIN dbo.ApprovalGroup b WITH (NOLOCK) ON a.ApprovalGroupID = b.ApprovalGroupID 
    WHERE a.RequisitionStatusID = @requisitionStatusID 
		AND a.GroupRountingSequence = @nextSequence

    SELECT @awaitingChairmanApprovalID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'AwaitingChairmanApproval'

    SELECT @awaitingCEOApprovalID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'AwaitingCEOApproval'

    SELECT @submittedID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'Submitted'

    UPDATE dbo.RequisitionStatus
    SET CurrentSequence = @nextSequence,
		ApprovalStatusID = (
								CASE WHEN @approvalGroup = 'Chairman' THEN @awaitingChairmanApprovalID
									WHEN @approvalGroup = 'CEO' THEN @awaitingCEOApprovalID
									ELSE @submittedID
								END
							)
    WHERE RequisitionStatusID = @requisitionStatusID

	--Get the number of affected rows
	SELECT @rowsAffected = @@rowcount

	IF @rowsAffected > 0
	BEGIN

		DECLARE @submittedForApprovalID INT,
				@inQueueID              INT,
				@minRoutingSequence     INT

		SELECT @submittedForApprovalID = a.ApprovalStatusID
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(a.StatusCode) = 'SubmittedForApproval'

		SELECT @inQueueID = a.ApprovalStatusID
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(a.StatusCode) = 'AwaitingApproval'
		
		SELECT @minRoutingSequence  = MIN(a.RoutingSequence)
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
		WHERE a.RequisitionStatusID = @requisitionStatusID 
			AND a.ApprovalStatusID = @inQueueID 
			AND a.GroupRountingSequence = @nextSequence

		--IF ISNULL(@minRoutingSequence, 0) > 0
		--BEGIN

			--Set the status of the current approver to "Awaiting Approval"
			UPDATE dbo.RequisitionStatusDetail
            SET ApprovalStatusID = @submittedForApprovalID
			WHERE RequisitionStatusID = @RequisitionStatusID 
				AND ApprovalStatusID = @InQueueID 
				AND GroupRountingSequence = @nextSequence 
				AND RoutingSequence = @minRoutingSequence
		--END 
    END 

END 

/*	Debug:

	EXEC Projectuser.Pr_SetRequisitionStatus 4116, 0

PARAMETERS:
	@requisitionID			INT,
    @nextSequence			INT OUTPUT

*/