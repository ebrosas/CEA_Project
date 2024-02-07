/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.06.09 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			20-Mar-2016 3:30PM
	Modified the code to handle Invoice Requisition

	2.2					Ervin				17-Feb-2019 02:43 PM
	Refactored the code to enhance data retrieval performance

	2.3					EOB					31-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	2.4					Shoukhat			25-Feb-2020 3:30PM
	Modified the code to handle Employee Contract Renewal Requisition

	2.5					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_ValidateServiceRequest
(
	@reqType INT,
	@reqTypeNo INT,
	@actID INT OUTPUT,
	@actStatusID INT OUTPUT,
	@reqStatusID INT OUTPUT,
	@reqStatusCode VARCHAR(10) OUTPUT,
	@currentDistMemRoutineSeq INT OUTPUT,
	@reqModifiedBy INT,
	@reqModifiedName VARCHAR(50),
	@retError INT OUTPUT
)
AS
BEGIN

	-- Define error codes
	DECLARE @RETURN_OK int
	DECLARE @RETURN_ERROR int

	SET @RETURN_OK		= 0
	SET @RETURN_ERROR	= -1

	-- Initialize output
	SET @retError = @RETURN_OK

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE int
	DECLARE @REQUEST_TYPE_PR int
	DECLARE @REQUEST_TYPE_TSR int
	DECLARE @REQUEST_TYPE_PAF int
	DECLARE @REQUEST_TYPE_EPA int
	DECLARE @REQUEST_TYPE_CLRFRM int
	DECLARE @REQUEST_TYPE_SIR int
	DECLARE @REQUEST_TYPE_RR INT		-- ver 2.0
    DECLARE @REQUEST_TYPE_IR INT		-- ver 2.1
	DECLARE @REQUEST_TYPE_PROBY INT		-- ver 2.3
	DECLARE @REQUEST_TYPE_ECR INT		-- ver 2.4
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 2.5

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18	-- ver 2.0
	SET @REQUEST_TYPE_IR		= 19	-- ver 2.1
	SET @REQUEST_TYPE_ECR		= 20	-- ver 2.4
	SET @REQUEST_TYPE_PROBY		= 21	-- ver 2.3
	SET @REQUEST_TYPE_CEA		= 22	-- ver 2.5

	SET XACT_ABORT ON

	-- Checks if the validator is still part of the current list
	IF NOT EXISTS(SELECT a.CurrentDistMemEmpNo
					FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
					WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
						a.CurrentDistMemCurrent = 1 AND a.CurrentDistMemEmpNo = @reqModifiedBy)
	BEGIN

		SET XACT_ABORT OFF
		RETURN

	END

	-- Action Validator Type
	DECLARE @SERV_ROLE_VALIDATOR int
	SELECT @SERV_ROLE_VALIDATOR = a.UDCID
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'VAL'

	-- Declare necessary variables
	DECLARE @currentDistMemID int
	DECLARE @currentDistMemActionType int
	DECLARE @currentDistMemApproval tinyint

	DECLARE @distMemDistListID int

	DECLARE @historyDate datetime
	DECLARE @reqStatusDesc varchar(300)
	DECLARE @reqStatHandlingCode VARCHAR(50) = ''

	DECLARE @assignNext bit
	DECLARE @endActivity bit
	-- End of necessary variables

	-- Checks if Activity ID is NULL
	IF @actID IS NULL
		SET @actID = 0

	-- Retrieve Status
	SELECT	@reqStatusID = a.UDCID, @reqStatusCode = a.UDCCode,
			@reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1,
			@reqStatHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
	FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
	WHERE a.UDCUDCGID = 9 AND a.UDCCode = '130'

	-- Add History Routine Record
	SET @historyDate = DATEADD(ss, -1, GETDATE())
	SET @reqStatusDesc = @reqStatusDesc + ' (' + @reqModifiedName + ')'

	EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @reqStatusDesc,
		@reqModifiedBy, @reqModifiedName, @historyDate, @retError output

	IF @retError = @RETURN_OK
	BEGIN

		-- Checks the routine sequence
		IF @currentDistMemRoutineSeq < 1
			SET @currentDistMemRoutineSeq = 1

		-- Retrieve the current validator information
		SELECT @currentDistMemID = a.CurrentDistMemID, @currentDistMemActionType = a.CurrentDistMemActionType,
				@currentDistMemApproval = a.CurrentDistMemApproval, @distMemDistListID = b.DistMemDistListID,
				@actID = c.ActionActID,
				@actStatusID = d.ActStatusID
			FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK) INNER JOIN
				secuser.DistributionMember AS b WITH (NOLOCK) ON a.CurrentDistMemRefID = b.DistMemID INNER JOIN
				secuser.ActivityAction AS c WITH (NOLOCK) ON b.DistMemDistListID = c.ActionDistListID INNER JOIN
				secuser.TransActivity AS d WITH (NOLOCK) ON c.ActionActID = d.ActID
			WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
				a.CurrentDistMemEmpNo = @reqModifiedBy AND a.CurrentDistMemCurrent = 1 AND
				a.CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq AND
				a.CurrentDistMemActionType = @SERV_ROLE_VALIDATOR

		-- Update the status of the Current Distribution Member
		UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 0, CurrentDistMemStatusID = @reqStatusID,
				CurrentDistMemModifiedBy = @reqModifiedBy, CurrentDistMemModifiedDate = GETDATE()
			WHERE CurrentDistMemID = @currentDistMemID

		-- Check for errors
		IF @@ERROR = @RETURN_OK
		BEGIN

			-- Assign to next
			SET @assignNext = 1

			-- Checks if more than one validator for each routine
			IF @currentDistMemApproval = 3
			BEGIN

				-- Checks the request type
				IF @reqType = @REQUEST_TYPE_CLRFRM
				BEGIN

					-- Checks if validated already
					IF EXISTS(SELECT a.ClrFormNo
								FROM secuser.ClearanceFormWF AS a WITH (NOLOCK)
								WHERE a.ClrFormNo = @reqTypeNo AND a.ClrFormValidated = 1)
					BEGIN

						-- Checks if there's still some validators within the checklist group
						EXEC secuser.pr_CheckListDistributionMemberApprover @reqType, @reqTypeNo, @currentDistMemRoutineSeq,
							@currentDistMemID, @reqModifiedBy, @retError output

						-- Checks for error
						IF @retError = @RETURN_OK
						BEGIN

							-- Checks if there's assigned person
							IF EXISTS(SELECT a.CurrentDistMemEmpNo
										FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
										WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
											a.CurrentDistMemCurrent = 1)
								SET @assignNext = 0

						END
					END
				END
			END

			-- Checks if to assign to next
			IF @retError = @RETURN_OK AND @assignNext = 1
			BEGIN

				-- Increment routine sequence
				SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq + 1

				-- Checks if there's another validator
				IF EXISTS(SELECT b.DistMemEmpNo
							FROM secuser.ActivityAction AS a WITH (NOLOCK) INNER JOIN
								secuser.DistributionMember AS b WITH (NOLOCK) ON a.ActionDistListID = b.DistMemDistListID INNER JOIN
								secuser.TransActivity AS c WITH (NOLOCK) ON a.ActionActID = c.ActID INNER JOIN
								secuser.ProcessWF AS d WITH (NOLOCK) ON c.ActProcessID = d.ProcessID
							WHERE d.ProcessReqType = @reqType AND d.ProcessReqTypeNo = @reqTypeNo AND
								a.ActionActID = @actID AND b.DistMemRoutineSeq = @currentDistMemRoutineSeq)
				BEGIN

					-- Set the next Validator
					EXEC secuser.pr_SetCurrentDistributionMember @reqType, @reqTypeNo, @currentDistMemActionType,
						@distMemDistListID, @currentDistMemRoutineSeq, @reqModifiedBy, @retError output

				END

				-- End the Activity
				ELSE
				BEGIN

					SET @endActivity = 1
					SET @currentDistMemRoutineSeq = @currentDistMemRoutineSeq - 1

				END

				-- Check if end of activity
				IF @endActivity = 1
				BEGIN

					-- Update all current distribution members
					UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 0
						WHERE CurrentDistMemReqType = @reqType AND CurrentDistMemReqTypeNo = @reqTypeNo AND
							--CurrentDistMemRoutineSeq = @currentDistMemRoutineSeq AND
							CurrentDistMemActionType = @currentDistMemActionType

					-- Check for errors
					IF @@ERROR = @RETURN_OK
					BEGIN

						-- Update the Service Request
						IF @reqType = @REQUEST_TYPE_LEAVE
							UPDATE secuser.LeaveRequisitionWF SET LeaveReqStatusID = @reqStatusID, LeaveReqStatusCode = @reqStatusCode,
									LeaveModifiedBy = @reqModifiedBy, LeaveModifiedName = @reqModifiedName,
									LeaveModifiedEmail = '', LeaveModifiedDate = GETDATE()
								WHERE LeaveNo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_PR
							UPDATE secuser.PurchaseRequisitionWF SET PRReqStatusID = @reqStatusID, PRReqStatusCode = @reqStatusCode,
									PRModifiedBy = @reqModifiedBy, PRModifiedName = @reqModifiedName,
									PRModifiedEmail = '', PRModifiedDate = GETDATE()
								WHERE PRDocNo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_TSR
							UPDATE secuser.TSRWF SET TSRReqStatusID = @reqStatusID, TSRReqStatusCode = @reqStatusCode,
									TSRModifiedBy = @reqModifiedBy, TSRModifiedName = @reqModifiedName,
									TSRModifiedEmail = '', TSRModifiedDate = GETDATE()
								WHERE TSRNo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_PAF
							UPDATE secuser.PAFWF SET PAFReqStatusID = @reqStatusID, PAFReqStatusCode = @reqStatusCode,
									PAFModifiedBy = @reqModifiedBy, PAFModifiedName = @reqModifiedName,
									PAFModifiedEmail = '', PAFModifiedDate = GETDATE()
								WHERE PAFNo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_EPA
							UPDATE secuser.EPAWF SET EPAReqStatusID = @reqStatusID, EPAReqStatusCode = @reqStatusCode,
									EPAModifiedBy = @reqModifiedBy, EPAModifiedName = @reqModifiedName,
									EPAModifiedEmail = '', EPAModifiedDate = GETDATE()
								WHERE EPANo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
							UPDATE secuser.ClearanceFormWF SET ClrFormStatusID = @reqStatusID, ClrFormStatusCode = @reqStatusCode,
									ClrFormModifiedBy = @reqModifiedBy,  ClrFormModifiedName= @reqModifiedName,
									ClrFormModifiedEmail = '', ClrFormModifiedDate = GETDATE()
								WHERE ClrFormNo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_SIR
							UPDATE secuser.SIRWF SET SIRReqStatusID = @reqStatusID, SIRReqStatusCode = @reqStatusCode,
									SIRModifiedBy = @reqModifiedBy, SIRModifiedName = @reqModifiedName,
									SIRModifiedEmail = '', SIRModifiedDate = GETDATE()
								WHERE SIRNo = @reqTypeNo

						ELSE IF @reqType = @REQUEST_TYPE_RR
						BEGIN
							DECLARE @recruiterName varchar(100)
							DECLARE @isEscalated bit

							-- Check if recruitment was escalated
							SELECT @isEscalated = RRIsEscalated 
							FROM secuser.RecruitmentRequisitionWF WITH (NOLOCK)
							WHERE RRNo = @reqTypeNo

							-- Get the assigned recruitor name
							SELECT @recruiterName = RRIntRecruiterName 
							FROM secuser.RecruitmentRequisitionWF WITH (NOLOCK)
							WHERE RRNo = @reqTypeNo

							-- Retrieve Status
							SELECT @reqStatusID = a.UDCID, @reqStatusCode = a.UDCCode,
									@reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1
								FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
								WHERE a.UDCUDCGID = 9 AND a.UDCCode = '310'

							-- Add History Routine Record
							SET @historyDate = DATEADD(ss, -1, GETDATE())
							SET @reqStatusDesc = @reqStatusDesc + ' - ' + @recruiterName

							EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @reqStatusDesc,
								@reqModifiedBy, @reqModifiedName, @historyDate, @retError output

							IF @@ERROR = @RETURN_OK
							BEGIN
								UPDATE secuser.RecruitmentRequisitionWF SET RRReqStatusID = @reqStatusID, RRReqStatusCode = @reqStatusCode,
										RRModifiedBy = @reqModifiedBy, RRModifiedName = @reqModifiedName,
										RRModifiedEmail = (SELECT EmpEmail FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy), RRModifiedDate = GETDATE()
								WHERE RRNo = @reqTypeNo
							END
							ELSE
								SET @retError = @RETURN_ERROR
						END
						
						-- ver2.1 Start
						ELSE IF @reqType = @REQUEST_TYPE_IR
							-- Update the workflow table
							UPDATE secuser.InvoiceRequisitionWF 
								SET IRStatusID = @reqStatusID, IRStatusCode = @reqStatusCode,
									IRLastModifiedByEmpNo = @reqModifiedBy, IRLastModifiedByEmpName =  @reqModifiedName, 
									IRLastModifiedByEmpEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy), 
									IRLastModifiedDate = GETDATE()
							WHERE IRNo = @reqTypeNo
						-- ver2.1 End

						-- ver2.3 Start
						ELSE IF @reqType = @REQUEST_TYPE_PROBY
						BEGIN
                        
							-- Update the workflow table
							UPDATE secuser.ProbationaryRequisitionWF 
							SET PARStatusID = @reqStatusID, 
								PARStatusCode = @reqStatusCode,
								PARLastModifiedByEmpNo = @reqModifiedBy, 
								PARLastModifiedByEmpName =  @reqModifiedName, 
								PARLastModifiedByEmpEmail = secuser.fnGetEmployeeEmail(@reqModifiedBy), 
								PARLastModifiedDate = GETDATE()
							WHERE PARRequisitionNo = @reqTypeNo
						END 
						-- ver2.3 End

						-- ver2.4 Start
						ELSE IF @reqType = @REQUEST_TYPE_ECR
							-- Update the workflow table
							UPDATE secuser.EmployeeContractRenewalWF 
								SET ECRStatusID = @reqStatusID, ECRStatusCode = @reqStatusCode,
									ECRLastModifiedBy = @reqModifiedBy, ECRLastModifiedDate = GETDATE()
							WHERE ECRNo = @reqTypeNo
						-- ver2.4 End

						-- ver2.5 Start
						ELSE IF @reqType = @REQUEST_TYPE_CEA
							-- Update the workflow table
							UPDATE secuser.CEAWF 
							SET CEAStatusID = @reqStatusID, 
								CEAStatusCode = @reqStatusCode,
								CEAStatusHandlingCode = @reqStatHandlingCode,
								CEAModifiedBy = @reqModifiedBy, 
								CEAModifiedName = @reqModifiedName,
								CEAModifiedEmail = secuser.fnGetEmployeeEmail(@reqModifiedBy), 
								CEAModifiedDate = GETDATE()
							WHERE CEARequisitionNo = @reqTypeNo
						-- ver2.5 End

						-- Checks for errors
						IF @@ERROR = @RETURN_OK
						BEGIN

							-- Retrieve the Activity Status ID
							SELECT @actStatusID = a.UDCID
								FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
								WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'

							-- End the Activity Action
							EXEC secuser.pr_UpdateTransactionActivity @actID OUTPUT, @actStatusID, @reqModifiedBy,
								@retError OUTPUT

							-- Set current routine sequence to -1
							SET @currentDistMemRoutineSeq = -1

						END

						ELSE
							SET @retError = @RETURN_ERROR

					END

					ELSE
						SET @retError = @RETURN_ERROR

				END

				-- Update all parameters
				ELSE IF @retError = @RETURN_OK
					EXEC secuser.pr_UpdateAllTransactionParameters @reqType, @reqTypeNo, @reqModifiedBy, @retError OUTPUT

			END
		END

		ELSE
			SET @retError = @RETURN_ERROR

	END

	SET XACT_ABORT OFF

END



