/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_UpdateApproverList
*	Description: This stored procedure is used to update the approver list
*
*	Date			Author		Rev. #		Comments:
*	11/09/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_UpdateApproverList 
(
	@requisitionNo			VARCHAR(50),    
    @sequenceNo				INT,
    @statusCode				VARCHAR(50),
	@retError				INT OUTPUT
)
AS
BEGIN

	-- Define error codes
	DECLARE @RETURN_OK		INT = 0
	DECLARE @RETURN_ERROR	INT = -1

	-- Initialize output
	SELECT @retError = @RETURN_OK

    DECLARE @requisitionID					INT = 0,
			@inQueueID						INT = 0,
			@submittedForApprovalID			INT = 0,
			@requisitionStatusID			NUMERIC = 0,
			@minRoutingSequence				INT = 0

	SELECT	@requisitionID = a.RequisitionID,
			@requisitionStatusID = b.RequisitionStatusID
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
	WHERE RTRIM(a.RequisitionNo) = @requisitionNo

	SELECT @submittedForApprovalID = a.ApprovalStatusID
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = LTRIM(RTRIM(@statusCode))

	SELECT @inQueueID = ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'AwaitingApproval'

    SELECT @RequisitionStatusID = RequisitionStatusID
    FROM dbo.RequisitionStatus a WITH (NOLOCK)
    WHERE a.RequisitionID = @requisitionID

    SELECT @minRoutingSequence  = MIN(a.RoutingSequence)
    FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
    WHERE a.RequisitionStatusID = @requisitionStatusID 
		AND a.ApprovalStatusID = @inQueueID 
		AND a.GroupRountingSequence = @sequenceNo

	IF ISNULL(@minRoutingSequence, 0) > 0
    BEGIN

		UPDATE dbo.RequisitionStatusDetail
        SET ApprovalStatusID = @submittedForApprovalID
        WHERE RequisitionStatusID = @requisitionStatusID 
			AND ApprovalStatusID = @InQueueID 
			AND GroupRountingSequence = @sequenceNo 
			AND RoutingSequence = @minRoutingSequence

		-- Check for errors
		IF @@ERROR <> @RETURN_OK
			SELECT @retError = @RETURN_ERROR
	END 
	
END 

/*	Debug:

	DECLARE	@return_value int,
			@retError int

	SELECT	@retError = 0

	EXEC	@return_value = [Projectuser].[Pr_UpdateApproverList]
			@requisitionNo = N'20230055',
			@sequenceNo = 1,
			@statusCode = N'SubmittedForApproval',
			@retError = @retError OUTPUT

	SELECT	@retError as N'@retError'


*/