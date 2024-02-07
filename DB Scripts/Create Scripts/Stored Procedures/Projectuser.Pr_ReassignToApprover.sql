/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_ReassignToApprover
*	Description: This stored procedure is used for reassigning CEA request to another approver
*
*	Date			Author		Rev. #		Comments:
*	31/10/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_ReassignToApprover 
(
	@requisitionNo			VARCHAR(12),
    @reassignedByEmpNo		INT,
    @reassignedToEmpNo		INT,
	@justification			VARCHAR(500),
	@rowsAffected			INT OUTPUT,
	@hasError				BIT OUTPUT,
	@retError				INT OUTPUT,
	@retErrorDesc			VARCHAR(200) OUTPUT
)
AS
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK	INT = 0,
			@CONST_RETURN_ERROR	INT = -1

	DECLARE @reassignedToID				INT,
            @reassignedToFullName		VARCHAR(50),
            @requisitionStatusID		INT,
            @reassignedByID				INT,
            @reassignedByFullName		VARCHAR(50),
            @submittedForApprovalID		INT,
            @reassignedID				INT,
			@useNewWF					BIT 

	--Initialize output parameters
	SELECT	@rowsAffected = 0,
			@hasError = 0,
			@retError = 0,
			@retErrorDesc = ''

    SELECT	@reassignedToID = ISNULL(a.ApplicationUserID, 0),
			@reassignedToFullName = RTRIM(a.FullName)
    FROM dbo.ApplicationUser a WITH (NOLOCK)
    WHERE EmployeeNo = @reassignedToEmpNo

    SELECT	@requisitionStatusID = b.RequisitionStatusID,
			@useNewWF = ISNULL(a.UseNewWF, 0)
    FROM dbo.Requisition a WITH (NOLOCK)
        INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionID = b.RequisitionID
    WHERE RTRIM(a.RequisitionNo) = @requisitionNo

    SELECT	@reassignedByID = a.ApplicationUserID,
			@reassignedByFullName = a.FullName
    FROM dbo.ApplicationUser a WITH (NOLOCK)
    WHERE a.EmployeeNo = @reassignedByEmpNo

    SELECT @submittedForApprovalID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'SubmittedForApproval'

    SELECT @reassignedID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'Reassigned'

	IF @useNewWF = 0		--CEA request was created using the old system
	BEGIN
    
		--IF @reassignedToID = 0
		--BEGIN

		--	SELECT	@hasError = 1,
		--			@retError = -2,
		--			@retErrorDesc = 'The reassigned approver does not have access to use the system.'
  --      END 

		IF @hasError = 0
		BEGIN

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
			SELECT	RequisitionStatusID,
					GETDATE(),
					ApprovalGroupID,
					@reassignedToID,
					ApprovalStatusID,
					null,
					RoutingSequence,
					PermanentStatus,
					'No Comment',
					GroupRountingSequence
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND a.ApplicationUserID = @reassignedByID 
				AND a.ApprovalStatusID = @submittedForApprovalID

			IF @@ERROR <> @CONST_RETURN_OK
				SELECT @retError = @CONST_RETURN_ERROR

			--Get the number of affected rows
			SELECT @rowsAffected = @@ROWCOUNT

			IF @retError = @CONST_RETURN_OK
			BEGIN
            
				UPDATE dbo.RequisitionStatusDetail
				SET ApprovalStatusID = @reassignedID,
					StatusDate = GETDATE(),
					ApproverComment = CASE WHEN ISNULL(@justification, '') <> ''
						THEN 'Reassigned to ' + @reassignedToFullName + ' by ' + @reassignedByFullName + ' due to the following reasons: ' + RTRIM(@justification)
						ELSE 'Reassigned to ' + @reassignedToFullName + ' by ' + @reassignedByFullName
						END 
				FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
				WHERE a.RequisitionStatusID = @requisitionStatusID 
					AND a.ApplicationUserID = @reassignedByID 
					AND a.ApprovalStatusID = @submittedForApprovalID

				DELETE dbo.RequisitionStatusDetail
				FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
				WHERE EXISTS 
					(
						SELECT x.RequisitionStatusDetailID
						FROM RequisitionStatusDetail x WITH (NOLOCK)
						WHERE x.RequisitionStatusID = a.RequisitionStatusID 
							AND x.ApplicationUserID = a.ApplicationUserID 
							AND x.GroupRountingSequence > a.GroupRountingSequence
					) 
					AND a.RequisitionStatusID = @requisitionStatusID

				DELETE dbo.RequisitionStatusDetail
				FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
				WHERE EXISTS 
					(
						SELECT x.RequisitionStatusDetailID
						FROM RequisitionStatusDetail x WITH (NOLOCK)
						WHERE x.RequisitionStatusID = a.RequisitionStatusID 
							AND x.ApplicationUserID = a.ApplicationUserID 
							AND x.ApprovalGroupID > a.ApprovalGroupID
					) 
					AND a.RequisitionStatusID = @requisitionStatusID
			END 
			ELSE
            BEGIN

				SELECT	@hasError = 1,
						@retError = -3,
						@retErrorDesc = 'Unable to create reassignment database transaction record.'
            END 
		END 
	END 

	ELSE 
	BEGIN

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
			GroupRountingSequence,
			IsAnonymousUser,
			AssignedEmpNo,
			AssignedEmpName,
			AssignedEmpEmail
		)
		SELECT	RequisitionStatusID,
				GETDATE(),
				ApprovalGroupID,
				@reassignedToEmpNo,
				ApprovalStatusID,
				null,
				RoutingSequence,
				PermanentStatus,
				@justification,
				GroupRountingSequence,
				1 AS IsAnonymousUser,
				b.EmpNo,
				b.EmpName,
				b.EmpEmail
		FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			OUTER APPLY
			(
				SELECT x.EmpNo, x.EmpName, x.EmpEmail 
				FROM projectuser.Vw_MasterEmployeeJDE x
				WHERE x.EmpNo = @reassignedToEmpNo
			) b
		WHERE a.RequisitionStatusID = @requisitionStatusID 
			AND a.ApplicationUserID = @reassignedByEmpNo 
			AND a.ApprovalStatusID = @submittedForApprovalID

		IF @@ERROR <> @CONST_RETURN_OK
			SELECT @retError = @CONST_RETURN_ERROR

		--Get the number of affected rows
		SELECT @rowsAffected = @@ROWCOUNT

		IF @retError = @CONST_RETURN_OK
		BEGIN
            
			UPDATE dbo.RequisitionStatusDetail
			SET ApprovalStatusID = @reassignedID,
				StatusDate = GETDATE(),
				ApproverComment = CASE WHEN ISNULL(@justification, '') <> ''
						THEN 'Reassigned to ' + @reassignedToFullName + ' by ' + @reassignedByFullName + ' due to the following reasons: ' + RTRIM(@justification)
						ELSE 'Reassigned to ' + @reassignedToFullName + ' by ' + @reassignedByFullName
						END 
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = @requisitionStatusID 
				AND a.ApplicationUserID = @reassignedByEmpNo 
				AND a.ApprovalStatusID = @submittedForApprovalID

			DELETE dbo.RequisitionStatusDetail
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE EXISTS 
				(
					SELECT x.RequisitionStatusDetailID
					FROM RequisitionStatusDetail x WITH (NOLOCK)
					WHERE x.RequisitionStatusID = a.RequisitionStatusID 
						AND x.ApplicationUserID = a.ApplicationUserID 
						AND x.GroupRountingSequence > a.GroupRountingSequence
				) 
				AND a.RequisitionStatusID = @requisitionStatusID

			DELETE dbo.RequisitionStatusDetail
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE EXISTS 
				(
					SELECT x.RequisitionStatusDetailID
					FROM RequisitionStatusDetail x WITH (NOLOCK)
					WHERE x.RequisitionStatusID = a.RequisitionStatusID 
						AND x.ApplicationUserID = a.ApplicationUserID 
						AND x.ApprovalGroupID > a.ApprovalGroupID
				) 
				AND a.RequisitionStatusID = @requisitionStatusID
		END 
		ELSE
        BEGIN

			SELECT	@hasError = 1,
					@retError = -3,
					@retErrorDesc = 'Unable to create reassignment database transaction record.'
        END 
	END 

END 

/*	Debug:

	DECLARE	@return_value int,
			@rowsAffected int,
			@hasError bit,
			@retError int,
			@retErrorDesc varchar(200)

	SELECT	@rowsAffected = 0

	EXEC	@return_value = [Projectuser].[Pr_ReassignToApprover]
			@requisitionNo = N'20230134',
			@reassignedByEmpNo = 10003632,
			@reassignedToEmpNo = 10003656,
			@justification = N'test reassignment',
			@rowsAffected = @rowsAffected OUTPUT,
			@hasError = @hasError OUTPUT,
			@retError = @retError OUTPUT,
			@retErrorDesc = @retErrorDesc OUTPUT

	SELECT	@rowsAffected as N'@rowsAffected',
			@hasError as N'@hasError',
			@retError as N'@retError',
			@retErrorDesc as N'@retErrorDesc'

*/
