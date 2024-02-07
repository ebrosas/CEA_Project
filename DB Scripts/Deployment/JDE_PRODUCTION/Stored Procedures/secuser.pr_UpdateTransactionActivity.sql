/************************************************************************************************************

Stored Procedure Name	:	pr_UpdateTransactionActivity
Description				:	This stored procedure updates the current transaction activity and set the
							next activity from the Process Workflow.

							This SP is part of the Transaction Workflow that can be used from different
							projects.

Created By				:	Noel G. Francisco
Date Created			:	04 December 2007

Parameters
	@actID					:	The Activity ID of the current activity process
	@actStatusID			:	The Activity Status to be set for the current activity
	@actCreatedModifiedBy	:	The employee no. of the user that calls this SP

	@retError				:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2007.12.04 08:09
	Created

	2.0					NGF					2008.03.31 12:18
	Include the owner in calling Tables, SPs and Views

	2.1					NGF					2008.03.31 12:43
	Update other activities that have skipped

	2.2					NGF					2008.04.28 09:24
	Set the initial status of the request if action is a validator

	2.3					NGF					2008.05.01 11:32
	Added the auto approval for the action activity

	2.4					NGF					2008.07.02 10:27
	Added handling on bypassing and the new cost center approval

	2.5					NGF					2008.08.12 15:20
	Added the Cash Advance Request functionality

	2.6					NGF					2011.10.02 11:41
	Added necessary execution for TSR

	2.7					EOB					2019.02.17 02:40 PM
	Refactored the code to enhance data retrieval performance

	2.8					EOB					31-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	2.9					Shoukhat			25-Feb-2020 01:25PM
    Implemented the Employee Contract Renewal Request

	3.0					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
************************************************************************************************************/

ALTER PROCEDURE secuser.pr_UpdateTransactionActivity
(
	@actID					INT output,
	@actStatusID			INT,
	@actCreatedModifiedBy	INT,
	@retError				INT OUTPUT
)
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

	-- Define error codes
	DECLARE @RETURN_OK int
	DECLARE @RETURN_ERROR int

	SELECT @RETURN_OK			= 0
	SELECT @RETURN_ERROR		= -1

	-- Initialize output
	SELECT @retError = @RETURN_OK

	-- Define the Activity Types
	DECLARE @ACTIVITY_TYPE_ACTION int
	DECLARE @ACTIVITY_TYPE_CONDITION int
	DECLARE @ACTIVITY_TYPE_FUNCTION int
	DECLARE @ACTIVITY_TYPE_PROCESS int
	DECLARE @ACTIVITY_TYPE_SENDMAIL int

	SELECT @ACTIVITY_TYPE_ACTION	= 1
	SELECT @ACTIVITY_TYPE_CONDITION	= 2
	SELECT @ACTIVITY_TYPE_FUNCTION	= 3
	SELECT @ACTIVITY_TYPE_PROCESS	= 4
	SELECT @ACTIVITY_TYPE_SENDMAIL	= 5

	-- Define the Action Service Roles
	DECLARE @SERV_ROLE_APPROVER int
	DECLARE @SERV_ROLE_PROVIDER int
	DECLARE @SERV_ROLE_VALIDATOR int

	SELECT @SERV_ROLE_APPROVER = a.UDCID
		FROM secuser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'APP'

	SELECT @SERV_ROLE_PROVIDER = a.UDCID
		FROM secuser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'SERVPROV'

	SELECT @SERV_ROLE_VALIDATOR = a.UDCID
		FROM secuser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'VAL'

	-- Define Request Type
	DECLARE @REQUEST_TYPE_LEAVE int
	DECLARE @REQUEST_TYPE_PR int
	DECLARE @REQUEST_TYPE_TSR int
	DECLARE @REQUEST_TYPE_PAF int
	DECLARE @REQUEST_TYPE_EPA int
	DECLARE @REQUEST_TYPE_CLRFRM INT
    DECLARE @REQUEST_TYPE_PROBY INT		--Rev. #2.8
	DECLARE @REQUEST_TYPE_ECR INT		--Rev. #2.9
	DECLARE @REQUEST_TYPE_CEA INT		--Rev. #3.0

	SELECT @REQUEST_TYPE_LEAVE	= 4
	SELECT @REQUEST_TYPE_PR		= 5
	SELECT @REQUEST_TYPE_TSR	= 6
	SELECT @REQUEST_TYPE_PAF	= 7
	SELECT @REQUEST_TYPE_EPA	= 11
	SELECT @REQUEST_TYPE_CLRFRM	= 16
	SELECT @REQUEST_TYPE_ECR	= 20	--Rev. #2.9
	SELECT @REQUEST_TYPE_PROBY	= 21	--Rev. #2.8
	SELECT @REQUEST_TYPE_CEA	= 22	--Rev. #3.0

	-- Declare necesary variables
	DECLARE @actProcessID int
	DECLARE @actNextCode varchar(10)
	DECLARE @actSeq int
	DECLARE @actType int

	DECLARE @reqType int
	DECLARE @reqTypeNo int

	-- Activity Action
	DECLARE @actionType int
	DECLARE @actionAutoApprove bit
	DECLARE @actionDistListID int

	DECLARE @reqTypeEmpNo int
	DECLARE @reqTypeEmpName varchar(50)
	DECLARE @reqStatusID int
	DECLARE @reqStatusCode varchar(10)

	-- Activity Condition
	DECLARE @condValid bit

	-- Update the activity
	UPDATE secuser.TransActivity SET ActCurrent = 0, ActStatusID = @actStatusID,
			ActModifiedBy = @actCreatedModifiedBy, ActModifiedDate = GETDATE()
		WHERE ActID = @actID

	-- Check error
	IF @@ERROR = @RETURN_OK
	BEGIN

		-- Update also the Specific Activity
		SELECT @actType = a.ActType
			FROM secuser.TransActivity AS a
			WHERE a.ActID = @actID

		-- Check the Activity Type
		IF @actType = @ACTIVITY_TYPE_ACTION
			UPDATE secuser.ActivityAction SET ActionStatusID = @actStatusID, ActionModifiedDate = GETDATE()
				WHERE ActionActID = @actID

		ELSE IF @actType = @ACTIVITY_TYPE_CONDITION
			UPDATE secuser.ActivityCondition SET CondStatusID = @actStatusID, CondModifiedDate = GETDATE()
				WHERE CondActID = @actID

		ELSE IF @actType = @ACTIVITY_TYPE_FUNCTION
			UPDATE secuser.ActivityFunction SET FuncStatusID = @actStatusID, FuncModifiedDate = GETDATE()
				WHERE FuncActID = @actID

		ELSE IF @actType = @ACTIVITY_TYPE_PROCESS
			UPDATE secuser.ActivityProcess SET ActProcessStatusID = @actStatusID, ActProcessModifiedDate = GETDATE()
				WHERE ActProcessActID = @actID

		ELSE IF @actType = @ACTIVITY_TYPE_SENDMAIL
			UPDATE secuser.ActivityMailMessage SET MailStatusID = @actStatusID, MailModifiedDate = GETDATE()
				WHERE MailActID = @actID

		IF @@ERROR = @RETURN_OK
		BEGIN

			-- Retrieve the next activity specified
			SELECT @actProcessID = a.ActProcessID, @actNextCode = ISNULL(a.ActNextCode, ''), @actSeq = a.ActSeq,
					@reqType = b.ProcessReqType, @reqTypeNo = b.ProcessReqTypeNo,
					@condValid = ISNULL(c.CondValid, 1)
				FROM secuser.TransActivity AS a WITH (NOLOCK) INNER JOIN
					secuser.ProcessWF AS b WITH (NOLOCK) ON a.ActProcessID = b.ProcessID LEFT JOIN
					secuser.ActivityCondition AS c WITH (NOLOCK) ON a.ActID = CondActID
				WHERE a.ActID = @actID

			SELECT a.ActID, a.ActProcessID, ISNULL(a.ActNextCode, ''), a.ActSeq,
					b.ProcessReqType, b.ProcessReqTypeNo,
					ISNULL(c.CondValid, 1)
				FROM secuser.TransActivity AS a WITH (NOLOCK) INNER JOIN
					secuser.ProcessWF AS b WITH (NOLOCK) ON a.ActProcessID = b.ProcessID LEFT JOIN
					secuser.ActivityCondition AS c WITH (NOLOCK) ON a.ActID = CondActID
				WHERE a.ActID = @actID
				
			-- Reset the Activity ID
			SELECT @actID = 0

			-- Check next activity is specified
			IF LEN(@actNextCode) > 0 AND @condValid = 1
			BEGIN

				-- Retrieve the next activity
				SELECT @actID = a.ActID, @actType = a.ActType, @actSeq = a.ActSeq
					FROM secuser.TransActivity AS a WITH (NOLOCK)
					WHERE a.ActProcessID = @actProcessID AND a.ActCode = @actNextCode
					
				SELECT a.ActID, a.ActType, a.ActSeq
					FROM secuser.TransActivity AS a WITH (NOLOCK)
					WHERE a.ActProcessID = @actProcessID AND a.ActCode = @actNextCode

			END

			-- Retrieve the next activity in the sequence
			ELSE IF (LEN(@actNextCode) = 0 AND @condValid = 1) OR
				(LEN(@actNextCode) > 0 AND @condValid = 0)
			BEGIN

				-- Retrieve the next activity
				SELECT @actID = a.ActID, @actType = a.ActType, @actSeq = a.ActSeq
					FROM secuser.TransActivity AS a WITH (NOLOCK)
					WHERE a.ActProcessID = @actProcessID AND a.ActSeq = (@actSeq + 1)

			END

			-- Retrieve the next activity after the if condition statement
			ELSE
			BEGIN

				-- Retrieve the next activity
				SELECT @actID = a.ActID, @actType = a.ActType, @actSeq = a.ActSeq
					FROM secuser.TransActivity AS a WITH (NOLOCK)
					WHERE a.ActProcessID = @actProcessID AND a.ActSeq = (@actSeq + 2)

			END
			
			SELECT @actID, @actType, @actSeq

			-- Set the next activity
			IF @actID > 0
			BEGIN

				-- Update the Transaction Parameters
				EXEC secuser.pr_UpdateAllTransactionParameters @reqType, @reqTypeNo, @actCreatedModifiedBy,
					@retError output

				-- Checks for error
				IF @retError = @RETURN_OK
				BEGIN

					-- Set the status of the next activity
					SELECT @actStatusID = a.UDCID
						FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
						WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'IN'

					UPDATE secuser.TransActivity SET ActCurrent = 1, ActStatusID = @actStatusID,
							ActModifiedBy = @actCreatedModifiedBy, ActModifiedDate = GETDATE()
						WHERE ActID = @actID

					-- Check for error
					IF @@ERROR = @RETURN_OK
					BEGIN

						-- Update other activities that have been skipped
						UPDATE secuser.TransActivity SET ActStatusID = (SELECT a.UDCID
																			FROM secuser.UserDefinedCode AS a
																			WHERE a.UDCUDCGID = 16 AND
																				a.UDCCode = 'S')
							WHERE ActID IN
								(SELECT b.ActID
									FROM secuser.ProcessWF AS a WITH (NOLOCK) INNER JOIN
										secuser.TransActivity AS b WITH (NOLOCK) ON a.ProcessID = b.ActProcessID INNER JOIN
										secuser.UserDefinedCode AS c WITH (NOLOCK) ON b.ActStatusID = c.UDCID AND c.UDCCode = 'CR'
									WHERE a.ProcessReqType = @reqType AND a.ProcessReqTypeNo = @reqTypeNo AND
										b.ActSeq < @actSeq)

						-- Check for error
						IF @@ERROR = @RETURN_OK
						BEGIN

							-- Check the activity type
							-- Activity Action
							IF @actType = @ACTIVITY_TYPE_ACTION
							BEGIN

								-- Retrieve Action Type and Distribution List
								SELECT @actionType = a.ActionType, @actionAutoApprove = a.ActionAutoApprove,
										@actionDistListID = a.ActionDistListID
									FROM secuser.ActivityAction AS a WITH (NOLOCK)
									WHERE a.ActionActID = @actID

								-- Set the current distribution members
								EXEC secuser.pr_SetCurrentDistributionMember @reqType, @reqTypeNo,
									@actionType, @actionDistListID, 1,
									@actCreatedModifiedBy, @retError output

								-- Update the status of the service request
								IF @retError = @RETURN_OK
								BEGIN

									-- Checks if Current Distribution Member has been set
									IF NOT EXISTS(SELECT a.CurrentDistMemEmpNo
													FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
													WHERE a.CurrentDistMemReqType = @reqType AND
														a.CurrentDistMemReqTypeNo = @reqTypeNo AND
														a.CurrentDistMemCurrent = 1)
									BEGIN

										-- Retrieve the Activity Status ID
										SELECT @actStatusID = a.UDCID
											FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
											WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'

										-- Update the Transaction Activity
										EXEC secuser.pr_UpdateTransactionActivity @actID, @actStatusID,
											@actCreatedModifiedBy, @retError output

									END

									-- Set the request status
									ELSE
									BEGIN

										DECLARE @reqStatus int
										IF @actionType = @SERV_ROLE_APPROVER
											SELECT @reqStatus = a.UDCID
												FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
												WHERE a.UDCUDCGID = 9 AND a.UDCField = '02' AND a.UDCCode = '05'

										ELSE IF @actionType = @SERV_ROLE_PROVIDER
											SELECT @reqStatus = a.UDCID
												FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
												WHERE a.UDCUDCGID = 9 AND a.UDCField = '03' AND a.UDCCode = '10'
		
										ELSE IF @actionType = @SERV_ROLE_VALIDATOR
											SELECT @reqStatus = a.UDCID
												FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
												WHERE a.UDCUDCGID = 9 AND a.UDCField = '04' AND a.UDCCode = '16'

										EXEC secuser.pr_UpdateServiceRequestStatus  @reqType, @reqTypeNo, @reqStatus,
											@actCreatedModifiedBy, @retError output

										-- Checks for error, and if auto approve
										IF @retError = @RETURN_OK AND @actionAutoApprove = 1 AND
											@actionType = @SERV_ROLE_APPROVER
										BEGIN

											-- Retrieve the Employee No of the Requestor
											IF @reqType = @REQUEST_TYPE_LEAVE
												SELECT @reqTypeEmpNo = a.EmpNo, @reqTypeEmpName = a.EmpName
													FROM secuser.LeaveRequisition AS a WITH (NOLOCK)
													WHERE a.RequisitionNo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_PR
												SELECT @reqTypeEmpNo = a.PREmpNo, @reqTypeEmpName = a.PREmpName
													FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK)
													WHERE a.PRDocNo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_TSR
												SELECT @reqTypeEmpNo = a.TSREmpNo, @reqTypeEmpName = a.TSREmpName
													FROM secuser.TSRWF AS a WITH (NOLOCK)
													WHERE a.TSRNo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_PAF
												SELECT @reqTypeEmpNo = a.PAFEmpNo, @reqTypeEmpName = a.PAFEmpName
													FROM secuser.PAFWF AS a WITH (NOLOCK)
													WHERE a.PAFNo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_EPA
												SELECT @reqTypeEmpNo = a.EPAEmpNo, @reqTypeEmpName = a.EPAEmpName
													FROM secuser.EPAWF AS a WITH (NOLOCK)
													WHERE a.EPANo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_CLRFRM
												SELECT @reqTypeEmpNo = a.ClrFormEmpNo, @reqTypeEmpName = a.ClrFormEmpName
													FROM secuser.ClearanceFormWF AS a WITH (NOLOCK)
													WHERE a.ClrFormNo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_PROBY
												SELECT @reqTypeEmpNo = a.PAREmpNo, @reqTypeEmpName = a.PAREmpName
													FROM secuser.ProbationaryRequisitionWF AS a WITH (NOLOCK)
													WHERE a.PARRequisitionNo = @reqTypeNo

											IF @reqType = @REQUEST_TYPE_ECR
												SELECT @reqTypeEmpNo = a.ECREmpNo, @reqTypeEmpName = a.ECREmpName
													FROM secuser.EmployeeContractRenewalWF AS a WITH (NOLOCK)
													WHERE a.ECRNo = @reqTypeNo

											--Start of Rev. #3.0
											IF @reqType = @REQUEST_TYPE_CEA
												SELECT	@reqTypeEmpNo = a.CEAEmpNo, 
														@reqTypeEmpName = a.CEAEmpName
												FROM secuser.CEAWF AS a WITH (NOLOCK)
												WHERE a.CEARequisitionNo = @reqTypeNo
											--End of Rev. #3.0

											-- Checks if the requestor is one of the current distribution member
											IF EXISTS(SELECT a.CurrentDistMemEmpNo
												FROM secuser.CurrentDistributionMember AS a WITH (NOLOCK)
												WHERE a.CurrentDistMemEmpNo = @reqTypeEmpNo AND
													a.CurrentDistMemReqType = @reqType AND
													a.CurrentDistMemReqTypeNo = @reqTypeNo AND
													a.CurrentDistMemActionType = @SERV_ROLE_APPROVER AND
													a.CurrentDistMemCurrent = 1)
											BEGIN

												-- Add some delays
												WAITFOR DELAY '00:00:01'

												SELECT @reqStatusID	= 0
												SELECT @reqStatusCode = ''

												-- Create auto approval
												EXEC secuser.pr_ApproveRejectServiceRequest @reqType, @reqTypeNo, 1,
													'Approve (Automatic Approval)', @actID,
													@actStatusID output, @reqStatusID output, @reqStatusCode output, 1,
													@reqTypeEmpNo, @reqTypeEmpName, @retError output
												
											END
										END
									END
								END
							END
						END

						ELSE
							SELECT @retError = @RETURN_ERROR

					END

					ELSE
						SELECT @retError = @RETURN_ERROR
				END
			END

			ELSE
			BEGIN

				-- Process Complete
				SELECT @actStatusID = a.UDCID
					FROM secuser.UserDefinedCode AS a
					WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'
				UPDATE secuser.ProcessWF SET ProcessStatusID = @actStatusID
					WHERE ProcessID = @actProcessID

				-- Checks for error
				IF @@ERROR = @RETURN_OK
				BEGIN

					SELECT @actStatusID = a.UDCID
						FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
						WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'S'

					-- Update other Activities that have been skipped
					UPDATE secuser.TransActivity SET ActStatusID = @actStatusID
						WHERE ActStatusID IN (SELECT a.UDCID
												FROM secuser.UserDefinedCode AS a
												WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'CR') AND
							ActProcessID = @actProcessID

					-- Checks for error
					IF @@ERROR = @RETURN_OK
					BEGIN

						-- Update other Distribution Members that have been skipped
						UPDATE secuser.DistributionMember SET DistMemStatusID = @actStatusID
							WHERE DistMemID IN (SELECT c.DistMemID
												FROM secuser.TransActivity AS a WITH (NOLOCK) INNER JOIN
													secuser.ActivityAction AS b WITH (NOLOCK) ON a.ActID = b.ActionActID AND
														a.ActProcessID = @actProcessID INNER JOIN
													secuser.DistributionMember AS c WITH (NOLOCK) ON b.ActionDistListID = c.DistMemDistListID INNER JOIN
													secuser.UserDefinedCode AS d WITH (NOLOCK) ON c.DistMemStatusID = d.UDCID AND (d.UDCCode = 'CR' OR d.UDCCode = 'IN'))

						-- Checks for error
						IF @@ERROR <> @RETURN_OK
							SELECT @retError = @RETURN_ERROR

					END

					ELSE
						SELECT @retError = @RETURN_ERROR

				END

				ELSE
					SELECT @retError = @RETURN_ERROR

			END
		END

		ELSE
			SELECT @retError = @RETURN_ERROR

	END

	ELSE
		SELECT @retError = @RETURN_ERROR

END

