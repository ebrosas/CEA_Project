/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_ApproveRequisition
*	Description: This stored procedure is used to process the approval of the CEA requisition
*
*	Date			Author		Rev. #		Comments:
*	07/09/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_ApproveRequisition 
(
	@requisitionNo			VARCHAR(50),    
    @empNo					INT,
    @statusCode				VARCHAR(50),
    @approvalComments		VARCHAR(512),
    @nextSequence			INT OUTPUT,
	@retError				INT OUTPUT,
	@approverEmail			VARCHAR(1000) OUTPUT
)
AS
BEGIN

	-- Define error codes
	DECLARE @RETURN_OK		INT = 0
	DECLARE @RETURN_ERROR	INT = -1

	-- Initialize output
	SELECT @retError = @RETURN_OK

    DECLARE @requisitionID					INT = 0,
			@requisitionStatusDetailID		NUMERIC = 0,
            @requisitionStatusID			NUMERIC = 0,
            @applicationUserID				INT = 0,
            @submittedForApprovalID			INT = 0,
            @approvalStatusID				NUMERIC = 0,
			@useNewWF						BIT = 0

	SELECT	@requisitionID = a.RequisitionID,
			@requisitionStatusID = b.RequisitionStatusID,
			@useNewWF = ISNULL(a.UseNewWF, 0)
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
	WHERE RTRIM(a.RequisitionNo) = @requisitionNo

	SELECT @submittedForApprovalID = a.ApprovalStatusID
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = 'SubmittedForApproval'

	SELECT @approvalStatusID = ApprovalStatusID
	FROM dbo.ApprovalStatus a WITH (NOLOCK)
	WHERE RTRIM(a.StatusCode) = @statusCode

	--Get the email address of all persons who have approved the CEA upto this point
	IF ISNUMERIC(@requisitionNo) = 1
		SELECT @approverEmail = Projectuser.fnGetApproverEmail(CAST(@requisitionNo AS INT))

	IF @useNewWF = 1
	BEGIN
    
		SET @applicationUserID = @empNo

		SELECT @requisitionStatusDetailID = RequisitionStatusDetailID
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
		WHERE a.RequisitionStatusID = @requisitionStatusID 
			AND (ApplicationUserID = @empNo AND a.IsAnonymousUser = 1)
			AND ApprovalStatusID = @submittedForApprovalID
	END 
	ELSE BEGIN
		
		SELECT @applicationUserID = a.ApplicationUserID
		FROM dbo.ApplicationUser a WITH (NOLOCK)
		WHERE a.EmployeeNo = @empNo

		SELECT @requisitionStatusDetailID = a.RequisitionStatusDetailID
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
		WHERE a.RequisitionStatusID = @requisitionStatusID 
			AND ApplicationUserID   = @applicationUserID 
			AND ApprovalStatusID    = @submittedForApprovalID
    END 

    DECLARE @awaitingChairmanApprovalID  numeric
    
	IF ISNULL(@requisitionStatusDetailID, 0) > 0
    BEGIN

        UPDATE dbo.RequisitionStatusDetail
        SET ApprovalStatusID = @approvalStatusID,
            ApproverComment  = @approvalComments,
            StatusDate = GETDATE()
         WHERE RequisitionStatusDetailID = @requisitionStatusDetailID

		 IF @@ERROR <> @RETURN_OK
			SELECT @retError = @RETURN_ERROR
    END
    ELSE BEGIN

        DECLARE @requisitionApprovalStatusID NUMERIC 

        SELECT @requisitionApprovalStatusID = ApprovalStatusID
        FROM dbo.RequisitionStatus a WITH (NOLOCK)
        WHERE a.RequisitionID = @requisitionID

        SELECT @awaitingChairmanApprovalID = ApprovalStatusID
        FROM dbo.ApprovalStatus a WITH (NOLOCK)
        WHERE RTRIM(a.StatusCode) = 'AwaitingChairmanApproval'

        IF @requisitionApprovalStatusID = @awaitingChairmanApprovalID
        BEGIN

			IF @useNewWF = 1
			BEGIN
            
				--Assign the workflow action member to @applicationUserID
				SELECT @applicationUserID = b.EmpNo
				FROM dbo.ApprovalGroupType a WITH (NOLOCK)
					CROSS APPLY
					(
						SELECT * FROM Projectuser.fnGetWFActionMember(RTRIM(a.DistGroupCode),'', 0) x
					) b
				WHERE RTRIM(a.ApprovalGroupType) = 'Chairman' 
			END
			ELSE BEGIN

				SELECT TOP 1 @applicationUserID = a.ApplicationUserID
				FROM dbo.ApprovalGroupAssignment a WITH (NOLOCK)
					INNER JOIN ApprovalGroupType b  WITH (NOLOCK) ON a.ApprovalGroupTypeID = b.ApprovalGroupTypeID
				WHERE RTRIM(b.ApprovalGroupType) = 'Chairman'
            END 
        END

        ELSE
        BEGIN

			SELECT @applicationUserID = b.ApplicationUserID
            FROM dbo.RequisitionStatusDetail a  WITH (NOLOCK)
                --INNER JOIN dbo.ApplicationUser b WITH (NOLOCK) ON b.ApplicationUserID = a.ApplicationUserID
				CROSS APPLY
				(
					SELECT x.EmployeeNo AS EmpNo, x.FullName AS EmpName, x.ApplicationUserID 
					FROM dbo.ApplicationUser x WITH (NOLOCK)
					WHERE x.ApplicationUserID = a.ApplicationUserID

					UNION
            
					SELECT x.EmpNo, x.EmpName, x.EmpNo AS ApplicationUserID 
					FROM Projectuser.Vw_MasterEmployeeJDE x
					WHERE x.EmpNo = a.ApplicationUserID
						AND a.IsAnonymousUser = 1
				) b
                LEFT JOIN Gen_Purpose.genuser.fnGetActiveSubstitutes('WFCEA', '') AS c ON c.WFFromEmpNo = b.EmpNo
                LEFT JOIN Projectuser.syLeaveRequisition d WITH (NOLOCK) ON d.EmpNo = b.EmpNo AND RTRIM(d.LeaveType) = 'AL' AND RTRIM(d.RequestStatusSpecialHandlingCode) = 'Closed' AND CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 126)) BETWEEN d.ActualLeaveStartDate AND d.ActualLeaveReturnDate - 1
             WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND a.ApprovalStatusID = @submittedForApprovalID 
				AND (c.SubstituteEmpNo IS NOT NULL OR d.SubEmpNo IS NOT NULL) 
				AND ISNULL(c.SubstituteEmpNo, d.SubEmpNo) = @empNo
        END

        UPDATE dbo.RequisitionStatusDetail
        SET ApprovalStatusID = @approvalStatusID,
            ApproverComment = @approvalComments,
            StatusDate = GETDATE()
        WHERE RequisitionStatusID = @requisitionStatusID 
			AND ApplicationUserID = @applicationUserID 
			AND ApprovalStatusID = @submittedForApprovalID

		IF @@ERROR <> @RETURN_OK
			SELECT @retError = @RETURN_ERROR
    END
    
    IF @statusCode = 'Rejected'
    BEGIN

       DECLARE @requestedAmt NUMERIC(18,3)

		SELECT @requestedAmt = a.RequestedAmt
		FROM dbo.Requisition a WITH (NOLOCK)
		WHERE a.RequisitionID = @requisitionID

		UPDATE dbo.RequisitionStatus
		SET ApprovalStatusID = @approvalStatusID,
			[Description] = CONVERT(VARCHAR, @requestedAmt) + 'BD requisition was rejected.',
			LastUdatedDate   = GETDATE()
		WHERE RequisitionID = @requisitionID

		-- Check for errors
		IF @@ERROR = @RETURN_OK
		BEGIN

			UPDATE Projectuser.sy_F0101
			SET ABAT1 = 'JR'
			WHERE ABAN8 = @requisitionNo

			SELECT @nextSequence = -3
		END
		ELSE
			SELECT @retError = @RETURN_ERROR
    END

    ELSE
    BEGIN

        DECLARE @inQueueID INT = 0

		SELECT @inQueueID = ApprovalStatusID
		FROM dbo.ApprovalStatus a WITH (NOLOCK)
		WHERE RTRIM(a.StatusCode) = 'AwaitingApproval'

        IF NOT EXISTS 
		(
			SELECT 1
            FROM dbo.RequisitionStatusDetail a  WITH (NOLOCK)
            WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND a.ApprovalStatusID = @inQueueID
        )
        BEGIN
        
            UPDATE dbo.RequisitionStatus
            SET ApprovalStatusID = @approvalStatusID,
                LastUdatedDate   = GETDATE()
            WHERE RequisitionID = @requisitionID

			-- Check for errors
			IF @@ERROR = @RETURN_OK
			BEGIN

			    SET @nextSequence = -2
			END
			ELSE	
				SELECT @retError = @RETURN_ERROR
        END

        ELSE
        BEGIN

            DECLARE @currentSequence int

			SELECT @currentSequence = a.CurrentSequence 
			FROM dbo.RequisitionStatus a WITH (NOLOCK)
			WHERE a.RequisitionID = @requisitionID

            IF NOT EXISTS 
			(
				SELECT RequisitionStatusDetailID
                FROM dbo.RequisitionStatusDetail
                WHERE RequisitionStatusID = @requisitionStatusID 
					AND ApprovalStatusID = @inQueueID 
					AND GroupRountingSequence = @currentSequence
            )
            BEGIN

                SET @nextSequence = Projectuser.fnGetNextSequence(@requisitionID, @currentSequence)

                DECLARE @approvalGroup				VARCHAR(100),
                        @awaitingCEOApprovalID		INT,
                        @submittedID				int

                SELECT TOP 1 @approvalGroup = b.ApprovalGroup
                FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
                    INNER JOIN dbo.ApprovalGroup b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
                WHERE a.RequisitionStatusID = @requisitionStatusID 
					AND a.GroupRountingSequence = @nextSequence

                IF @awaitingChairmanApprovalID IS NULL
				BEGIN
                
                    SELECT @awaitingChairmanApprovalID = ApprovalStatusID
                    FROM dbo.ApprovalStatus a WITH (NOLOCK)
                     WHERE RTRIM(a.StatusCode) = 'AwaitingChairmanApproval'
				END 

                SELECT @awaitingCEOApprovalID = ApprovalStatusID
                FROM dbo.ApprovalStatus a  WITH (NOLOCK)
                WHERE RTRIM(a.StatusCode) = 'AwaitingCEOApproval'

                SELECT @submittedID = ApprovalStatusID
                FROM dbo.ApprovalStatus a  WITH (NOLOCK)
                WHERE RTRIM(a.StatusCode) = 'Submitted'

                UPDATE dbo.RequisitionStatus
                SET CurrentSequence = @nextSequence,
                    ApprovalStatusID = (
                        CASE
                            WHEN @approvalGroup = 'Chairman' THEN @awaitingChairmanApprovalID
                            WHEN @approvalGroup = 'CEO' THEN @awaitingCEOApprovalID
                            ELSE @submittedID
                        END
                    )
                WHERE RequisitionStatusID = @requisitionStatusID

				IF @@ERROR <> @RETURN_OK
					SELECT @retError = @RETURN_ERROR
            END
            ELSE
            BEGIN

                SET @nextSequence = @currentSequence
            END
        END
    END

END 