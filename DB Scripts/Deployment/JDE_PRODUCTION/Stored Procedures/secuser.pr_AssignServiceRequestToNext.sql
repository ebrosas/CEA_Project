/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.06.09 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			20-Mar-2016 4:15PM
	Modified the code to handle the new Invoice Requisition

	2.2					Ervin				31-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	2.3					Shoukhat			27-Feb-2020 4:15PM
	Modified the code to handle the new Employee Contract Renewal Requisition

	2.4					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_AssignServiceRequestToNext
(
	@reqType					INT,
	@reqTypeNo					INT,
	@actionType					INT,
	@appApproved				BIT,
	@currentDistMemRoutineSeq	INT OUTPUT,
	@actionActID				INT OUTPUT,
	@actStatusID				INT OUTPUT,
	@reqModifiedBy				INT,
	@retError					INT OUTPUT
)
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

	-- Define error codes
	DECLARE @RETURN_OK INT
	DECLARE @RETURN_ERROR INT

	SET @RETURN_OK		= 0
	SET @RETURN_ERROR	= -1

	-- Initialize output
	SET @retError = @RETURN_OK

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE INT
	DECLARE @REQUEST_TYPE_PR INT
	DECLARE @REQUEST_TYPE_TSR INT
	DECLARE @REQUEST_TYPE_PAF INT
	DECLARE @REQUEST_TYPE_EPA INT
	DECLARE @REQUEST_TYPE_CLRFRM INT
	DECLARE @REQUEST_TYPE_SIR INT
	DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT		-- ver2.1
	DECLARE @REQUEST_TYPE_PROBY INT		-- ver2.2
	DECLARE @REQUEST_TYPE_ECR INT		-- ver2.3
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 2.4

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19	-- ver 2.1
	SET @REQUEST_TYPE_PROBY		= 21	-- ver 2.2
	SET @REQUEST_TYPE_ECR		= 20	-- ver 2.3
	SET @REQUEST_TYPE_CEA		= 22	-- ver 2.4


	-- Define Action Type
	DECLARE @ACTION_TYPE_APPROVER INT
	DECLARE @ACTION_TYPE_SERVICE_PROVIDER INT

	SET @ACTION_TYPE_APPROVER			= 64
	SET @ACTION_TYPE_SERVICE_PROVIDER	= 65

	-- Define Approval Setting
	DECLARE @APPROVAL_PRIMARY TINYINT
	DECLARE @APPROVAL_AT_LEAST_ONE TINYINT
	DECLARE @APPROVAL_ALL_APPROVERS TINYINT

	SET @APPROVAL_PRIMARY		= 1
	SET @APPROVAL_AT_LEAST_ONE	= 2
	SET @APPROVAL_ALL_APPROVERS	= 3

	-- Declare necessary variables
	DECLARE @distMemDistListID INT
	DECLARE @distMemRoutineSeq INT

	DECLARE @currentDistMemApproval TINYINT
	DECLARE @currentDistMemStatusID INT
	DECLARE @assignNext BIT
	DECLARE @endActivity BIT
	DECLARE @reqStatusCode VARCHAR(10) = ''
	DECLARE @reqStatusHandlingCode VARCHAR(50) = ''

	-- Initialize outputs
	SET @actionActID	= 0
	SET @actStatusID	= 0

	-- Check the Action Type
	IF @actionType = @ACTION_TYPE_APPROVER
	BEGIN

		-- Check the Approval Setting and retrieve the Distribution List ID
		SELECT @currentDistMemApproval = a.CurrentDistMemApproval, @distMemDistListID = b.DistMemDistListID,
				@currentDistMemStatusID = a.CurrentDistMemStatusID
			FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK) INNER JOIN
				secuser.DistributionMember AS b WITH (NOLOCK) ON a.CurrentDistMemRefID = b.DistMemID
			WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
				a.CurrentDistMemActionType = @actionType AND a.CurrentDistMemEmpNo = @reqModifiedBy AND
				a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq

		IF (@currentDistMemApproval = @APPROVAL_PRIMARY AND @appApproved = 1) OR
			(@currentDistMemApproval = @APPROVAL_AT_LEAST_ONE AND @appApproved = 1)
		BEGIN

			-- Set the next current distribution member and increment the routine sequence
			SET @assignNext = 1
			SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq + 1

		END

		ELSE IF @currentDistMemApproval = @APPROVAL_ALL_APPROVERS AND @appApproved = 1
		BEGIN

			-- Check if no more current Approvers
			IF NOT EXISTS(SELECT a.CurrentDistMemEmpNo
				FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
				WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
					a.CurrentDistMemCurrent = 1)
			BEGIN

				-- Set the next current distribution member and increment the routine sequence
				SET @assignNext = 1
				SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq + 1

			END
		END

		ELSE IF (@currentDistMemApproval = @APPROVAL_PRIMARY OR
				@currentDistMemApproval = @APPROVAL_ALL_APPROVERS) AND @appApproved = 0
			SET @endActivity = 1

		ELSE IF @currentDistMemApproval = @APPROVAL_AT_LEAST_ONE
		BEGIN

			-- Check if no more current Approvers
			IF NOT EXISTS(SELECT a.CurrentDistMemEmpNo
				FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
				WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
					a.CurrentDistMemCurrent = 1)
				SET @endActivity = 1

		END
	END

	-- Retrieve the Activity ID
	SELECT @actionActID = a.ActionActID
		FROM secuser.ActivityAction AS a WITH (NOLOCK)
		WHERE a.ActionDistListID = @distMemDistListID

	-- Check if assigning to next approver / service provider  / validator
	IF @assignNext = 1
	BEGIN

		-- Retrieve the last Routine Sequence
		SELECT @distMemRoutineSeq = MAX(a.DistMemRoutineSeq)
			FROM secuser.DistributionMember AS a WITH (NOLOCK)
			WHERE a.DistMemDistListID = @distMemDistListID

		-- Check if last routine sequence
		IF @currentDistMemRoutineSeq > @distMemRoutineSeq
		BEGIN

			SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq - 1

			-- Reset all current distribution members
			UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 0
				WHERE CurrentDistMemReqType = @reqType AND CurrentDistMemReqTypeNo = @reqTypeNo

			-- Check for errors
			IF @@ERROR = @RETURN_OK
			BEGIN

				-- Update the Service Request
				IF @reqType = @REQUEST_TYPE_LEAVE
					UPDATE secuser.LeaveRequisitionWF SET LeaveReqStatusID = @currentDistMemStatusID
						WHERE LeaveNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_PR
					UPDATE secuser.PRRequisitionWF SET PRReqStatusID = @currentDistMemStatusID
						WHERE PRDocNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_TSR
					UPDATE secuser.TSRWF SET TSRReqStatusID = @currentDistMemStatusID
						WHERE TSRNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_PAF
					UPDATE secuser.PAFWF SET PAFReqStatusID = @currentDistMemStatusID
						WHERE PAFNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_EPA
					UPDATE secuser.EPAWF SET EPAReqStatusID = @currentDistMemStatusID
						WHERE EPANo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
					UPDATE secuser.ClearanceFormWF SET ClrFormStatusID = @currentDistMemStatusID
						WHERE ClrFormNo = @reqTypeNo

				ELSE IF @reqType = @REQUEST_TYPE_SIR
					UPDATE secuser.SIRWF SET SIRReqStatusID = @currentDistMemStatusID
						WHERE SIRNo = @reqTypeNo

				-- *** SAK 15-Apr-2015: Modified to handle the new Recruitment Request type
				ELSE IF @reqType = @REQUEST_TYPE_RR
					UPDATE secuser.RecruitmentRequisitionWF SET RRReqStatusID = @currentDistMemStatusID
						WHERE RRNo = @reqTypeNo
				
				-- *** ver 2.1 Start
				ELSE IF @reqType = @REQUEST_TYPE_IR
					UPDATE secuser.InvoiceRequisitionWF SET IRStatusID = @currentDistMemStatusID
						WHERE IRNo = @reqTypeNo
				-- *** ver 2.1 End

				-- *** ver 2.2 Start
				ELSE IF @reqType = @REQUEST_TYPE_PROBY
					UPDATE secuser.ProbationaryRequisitionWF SET PARStatusID = @currentDistMemStatusID
						WHERE PARRequisitionNo = @reqTypeNo
				-- *** ver 2.2 End
				
				ELSE IF @reqType = @REQUEST_TYPE_ECR -- *** ver 2.1 Start
					UPDATE secuser.EmployeeContractRenewalWF SET ECRStatusID = @currentDistMemStatusID
						WHERE ECRNo = @reqTypeNo -- *** ver 2.1 End

				ELSE IF @reqType = @REQUEST_TYPE_CEA -- *** ver 2.4 Start
				BEGIN

					--Get the status details
					SELECT	@reqStatusCode = RTRIM(a.UDCCode),
							@reqStatusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
					FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
					WHERE a.UDCUDCGID = 9 
						AND a.UDCID = @currentDistMemStatusID

					UPDATE secuser.CEAWF 
					SET CEAStatusID = @currentDistMemStatusID,
						CEAStatusCode = @reqStatusCode,
						CEAStatusHandlingCode = @reqStatusHandlingCode
					WHERE CEARequisitionNo = @reqTypeNo
				END 
				-- *** ver 2.4 End
				
				-- Check for errors
				IF @@ERROR = @RETURN_OK
				BEGIN

					-- Retrieve the Activity Status ID
					SELECT @actStatusID = a.UDCID
						FROM secuser.UserDefinedCode AS a
						WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'

					-- End the Activity Action
					EXEC pr_UpdateTransactionActivity @actionActID, @actStatusID, @reqModifiedBy, @retError OUTPUT

				END

				ELSE
					SET @retError = @RETURN_ERROR

			END

			ELSE
				SET @retError = @RETURN_ERROR
				
		END

		ELSE
		BEGIN

			-- Set the next Approver / Service Provider
			EXEC secuser.pr_SetCurrentDistributionMember @reqType, @reqTypeNo, @actionType,
				@distMemDistListID, @currentDistMemRoutineSeq, @reqModifiedBy, @retError OUTPUT

		END

		-- Update the Transaction Parameters
		IF @retError = @RETURN_OK 
			EXEC secuser.pr_UpdateAllTransactionParameters @reqType, @reqTypeNo, @reqModifiedBy, @retError OUTPUT

	END

	ELSE IF @endActivity = 1
	BEGIN

		-- Reset all current distribution members
		UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 0
			WHERE CurrentDistMemReqType = @reqType AND CurrentDistMemReqTypeNo = @reqTypeNo

		IF @@ERROR = @RETURN_OK
		BEGIN

			-- Update the Service Request
			EXEC secuser.pr_UpdateServiceRequestStatus @reqType, @reqTypeNo, @currentDistMemStatusID,
				@reqModifiedBy, @retError OUTPUT

			IF @retError = @RETURN_OK
			BEGIN

				-- Retrieve the Activity Status ID
				SELECT @actStatusID = a.UDCID
					FROM secuser.UserDefinedCode AS a
					WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'

				-- End the Activity Action
				EXEC secuser.pr_UpdateTransactionActivity @actionActID, @actStatusID, @reqModifiedBy, @retError OUTPUT

			END
		END

		ELSE
			SET @retError = @RETURN_ERROR

	END

END



