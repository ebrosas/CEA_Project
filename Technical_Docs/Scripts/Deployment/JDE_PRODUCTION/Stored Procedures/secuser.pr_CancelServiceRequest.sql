/************************************************************************************************************

Stored Procedure Name	:	secuser.pr_CancelServiceRequest
Description				:	This stored procedure closes the service request and updates the workflow.

							This SP is part of the Transaction Workflow that can be used from different
							projects.

Created By				:	Noel G. Francisco
Date Created			:	02 April 2008

Parameters
	@reqType			:	The Request Type to close
	@reqTypeNo			:	The Request Type No to close
	@reqModifiedBy		:	The employee no. of the user that calls this SP
	@reqModifiedName	:	The employee name of the user that calls this SP

	@retError			:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2008.04.02 09:42
	Created

	1.1					NGF					2008.06.29 10:11
	Added the resetting of Ticket Entitlement

	1.2					NGF					2008.10.12 16:25
	Added the Cash Advance Request functionality

	1.3					NGF					2009.08.30 07:54
	Added the Personal Action Form functionality

	1.4					NGF					2009.11.08 08:56
	Added the Employee Performance Appraisal form

	1.5					NGF					2011.10.02 09:15
	Added necessary execution for TSR

	1.6					NGF					2012.06.13 09:07
	Added the Clearance Form

	1.7					NGF					2013.04.28 12:07
	Added the inserting order detail history

	1.8					NGF					2013.05.21 15:03
	Insert order detail history after updating the order details

	1.9					EOB					2015.02.20 12:03
	Added code to set the leave approval flag "LRY58VCAFG" in F58LV13 table to 'C' for cancelling the leave request

	2.0					SAK					2015.04.13 09:48
	Modified the code to handle the cancellation of recruitment requisitions

	2.1					SAK					23-Mar-2016 3:40 PM
	Modified the code to handle the cancellation of invoice requisitions

	2.2					SAK					18-Apr-2016 11:40 AM
	Modified the code to get the closure activity ID instead of the last for invoice requisitions

	2.3					EOB					17-Feb-2019 02:48 PM
	Refactored the code to enhance data retrieval performance

	2.4					EOB					04-Mar-2019 11:18 AM
	Used substring function to get the first 10 chars of "@reqModifiedName" parameter value

	2.5					EOB					29-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	2.6					Shoukhat			27-Feb-2020 09:40 AM
	Modified the code to handle the cancellation of ECR

	2.7					Ervin				30-Aug-2023 09:52 AM
    Implemented the CEA workflow
**********************************************************************************************************************************/

ALTER PROCEDURE secuser.pr_CancelServiceRequest
(
	@reqType INT,
	@reqTypeNo INT,
	@reqStatusCode VARCHAR(10),
	@reqModifiedBy INT,
	@reqModifiedName VARCHAR(50),
	@retError INT OUTPUT
)
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

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
	DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT		-- ver 2.1
	DECLARE @REQUEST_TYPE_PROBY INT		-- ver 2.5
	DECLARE @REQUEST_TYPE_ECR INT		-- ver 2.6
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 2.7

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19	-- ver 2.1
	SET @REQUEST_TYPE_PROBY		= 21	-- ver 2.5
	SET @REQUEST_TYPE_ECR		= 20	-- ver 2.6
	SET @REQUEST_TYPE_CEA		= 22	-- ver 2.7

	-- Declare necessary variables
	DECLARE @reqStatusID int
	DECLARE @reqStatusDesc varchar(300)
	DECLARE @reqStatusHandlingCode VARCHAR(50)

	DECLARE @leaveApprovalFlag char(1)
	DECLARE @leaveEmpNo float
	DECLARE @leaveType varchar(5)
	DECLARE @leaveDuration float
	DECLARE @leavePlanRefNo float

	DECLARE @actID int
	DECLARE @actStatusID int

	DECLARE @historyDate datetime
	DECLARE @leaveCompany char(5)

	DECLARE @reqModifiedEmail varchar(150)
	-- End of necessary variables

	SET XACT_ABORT ON

	-- Update all current distribution members
	UPDATE secuser.CurrentDistributionMember 
	SET CurrentDistMemCurrent = 0
	WHERE CurrentDistMemReqType = @reqType 
		AND CurrentDistMemReqTypeNo = @reqTypeNo

	-- Check for errors
	IF @@ERROR = @RETURN_OK
	BEGIN

		SELECT	@reqStatusID = a.UDCID, 
				@reqStatusDesc = RTRIM(a.UDCSpecialHandlingCode) + ' - ' + RTRIM(a.UDCDesc1),
				@reqStatusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 9 
			AND RTRIM(a.UDCCode) = @reqStatusCode

		-- Update the Service Request
		IF @reqType = @REQUEST_TYPE_LEAVE
		BEGIN

			-- Store the current leave approval flag
			SELECT	@leaveApprovalFlag = a.ApprovalFlag, 
					@leaveEmpNo = a.EmpNo,
					@leaveType = a.LeaveType, 
					@leaveDuration = a.LeaveDuration * -1, 
					@leavePlanRefNo = a.LeavePlannedNo,
					@leaveCompany = LTRIM(RTRIM(a.Company))
			FROM secuser.LeaveRequisition AS a WITH (NOLOCK)
			WHERE a.RequisitionNo = @reqTypeNo

			-- Checks if the leave requisition is not yet approved and paid
			IF @leaveApprovalFlag <> 'A'
			BEGIN

				UPDATE secuser.LeaveRequisitionWF SET LeaveApprovalFlag = 'C', LeaveReqStatusID = @reqStatusID, LeaveReqStatusCode = @reqStatusCode,
						LeaveModifiedBy = @reqModifiedBy, LeaveModifiedName = LEFT(@reqModifiedName, 10),
						LeaveModifiedEmail = '', LeaveModifiedDate = GETDATE()
					WHERE LeaveNo = @reqTypeNo

				-- Checks for error
				IF @@ERROR = @RETURN_OK
				BEGIN

					-- Remove the Leave Planned Reference No.
					UPDATE secuser.F58LV21 SET LVNUM2 = 0
						WHERE LVAN8 = @leaveEmpNo AND LVY58VCTRN = @leavePlanRefNo

					-- Checks for error
					IF @@ERROR = @RETURN_OK
					BEGIN

						/****************************** Part of Revision No. 1.9 ***************************************/
						--Set the approval flag to 'C' to cancel the leave request	
						UPDATE secuser.F58LV13 
						SET LRY58VCAFG = 'C'
						WHERE LRY58VCRQN = @reqTypeNo 
							AND LTRIM(RTRIM(LRCO)) = @leaveCompany
							AND LRAN8 = @leaveEmpNo
						/****************************** End of Revision No. 1.9 ***************************************/

						-- Checks if leave has been deducted already
						IF @leaveApprovalFlag = 'N'
						BEGIN

							-- Update the balance
							EXEC secuser.pr_UpdateLeaveBalance @reqTypeNo, @leaveEmpNo, @leaveType, @leaveDuration,
								@reqModifiedName, '', @retError OUTPUT

							-- Checks for error
							IF @retError = @RETURN_OK
							BEGIN

								-- Update TAS
								EXEC secuser.pr_UpdateTASCancel @reqType, @reqTypeNo, @leaveEmpNo,
									@reqModifiedBy, @reqModifiedName, @retError OUTPUT

							END
						END
					END

					ELSE
						SET @retError = @RETURN_ERROR

				END
				ELSE
					SET @retError = @RETURN_ERROR

			END
		END

		ELSE IF @reqType = @REQUEST_TYPE_PR
		BEGIN

			DECLARE @prDocType VARCHAR(2)
			SELECT @prDocType = a.PHDCTO
				FROM secuser.F4301 AS a WITH (NOLOCK)
				WHERE a.PHDOCO = @reqTypeNo AND PHSFXO = '000'

			UPDATE secuser.PurchaseRequisitionWF SET PRReqStatusID = @reqStatusID, PRReqStatusCode = @reqStatusCode,
					PRModifiedBy = @reqModifiedBy, PRModifiedName = @reqModifiedName,
					PRModifiedEmail = '', PRModifiedDate = GETDATE()
				WHERE PRDocNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR = @RETURN_OK
			BEGIN

				-- Update the status of each order
				UPDATE secuser.F4311 SET PDNXTR = '999', PDLTTR = '980'
					WHERE PDDOCO = @reqTypeNo AND PDSFXO = '000'
					--WHERE PDDOCO = @reqTypeNo AND PDDCTO = 'OR' AND PDSFXO = '000'

				-- Checks for error
				IF @@ERROR = @RETURN_OK
				BEGIN

					-- Inserts order detail history
					EXEC secuser.pr_InsertOrderDetailHistory @reqTypeNo, @prDocType, @reqModifiedBy, @reqModifiedName, @retError output

				END

				ELSE
					SET @retError = @RETURN_ERROR

			END
			ELSE
				SET @retError = @RETURN_ERROR

		END
		
		ELSE IF @reqType = @REQUEST_TYPE_TSR
		BEGIN

			UPDATE secuser.TSRWF SET TSRReqStatusID = @reqStatusID, TSRReqStatusCode = @reqStatusCode,
					TSRModifiedBy = @reqModifiedBy, TSRModifiedName = @reqModifiedName,
					TSRModifiedEmail = '', TSRModifiedDate = GETDATE()
				WHERE TSRNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR = @RETURN_OK
			BEGIN

				-- Update the status of the work order
				UPDATE secuser.F4801 SET WASRST = 'MM'
					WHERE WADOCO = @reqTypeNo AND WADCTO = 'WO'

				-- Checks for error
				IF @@ERROR = @RETURN_OK
				BEGIN

					DECLARE @woEquipNo float
					DECLARE @currentDate datetime

					SET @currentDate = GETDATE()
					SELECT @woEquipNo = a.WANUMB
						FROM secuser.F4801 AS a WITH (NOLOCK)
						WHERE a.WADCTO = 'WO' AND a.WADOCO = @reqTypeNo

					EXEC secuser.pr_InsertUpdateDeleteWorkOrderStatus @woEquipNo, 0, '2', @reqTypeNo, 'MM',
						@currentDate, NULL, 'Work Order Cancelled',
						@reqModifiedName, GAP, '', @retError OUTPUT

				END

				ELSE
					SET @retError = @RETURN_ERROR

			END
			ELSE
				SET @retError = @RETURN_ERROR

		END

		ELSE IF @reqType = @REQUEST_TYPE_PAF
		BEGIN

			UPDATE secuser.F55PAF 
			SET PAY58VCAFG = 'C', 
				PAUSER = SUBSTRING(@reqModifiedName, 1, 10),	--Rev. #2.4
				PAUPMJ = dbo.ConvertToJulian(GETDATE()),
				PAUPMT = CONVERT(float, REPLACE(CONVERT(varchar(100), GETDATE(), 108), ':', ''))
			WHERE PAG55AUTO = (SELECT a.PAFAutoID
								FROM secuser.PAFWF AS a WITH (NOLOCK)
								WHERE a.PAFNo = @reqTypeNo)

			-- Checks for error
			IF @@ERROR = @RETURN_OK
			BEGIN

				UPDATE secuser.PAFWF 
				SET PAFReqStatusID = @reqStatusID, 
					PAFReqStatusCode = @reqStatusCode,
					PAFModifiedBy = @reqModifiedBy, 
					PAFModifiedName = @reqModifiedName,
					PAFModifiedEmail = '', 
					PAFModifiedDate = GETDATE()
				WHERE PAFNo = @reqTypeNo

				-- Checks for error
				IF @@ERROR <> @RETURN_OK
					SET @retError = @RETURN_ERROR

			END

			ELSE
				SET @retError = @RETURN_ERROR

		END

		--Start of Rev. #2.5
		ELSE IF @reqType = @REQUEST_TYPE_PROBY
		BEGIN

			DECLARE	@statusDesc VARCHAR(50),
					@statusHandlingCode	VARCHAR(50)

			--Get the status details
			SELECT	@statusDesc= RTRIM(a.UDCDesc1),
					@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
			FROM secuser.UserDefinedCode a WITH (NOLOCK) 
			WHERE UDCUDCGID = 9 
				AND RTRIM(a.UDCCOde) = RTRIM(@reqStatusCode)

			UPDATE secuser.ProbationaryRequisitionWF 
			SET PARStatusID = @reqStatusID, 
				PARStatusCode = @reqStatusCode,
				PARLastModifiedByEmpNo = @reqModifiedBy, 
				PARLastModifiedByEmpName = @reqModifiedName,
				PARLastModifiedByEmpEmail = secuser.fnGetEmployeeEmail(@reqModifiedBy), 
				PARLastModifiedDate = GETDATE()
			WHERE PARRequisitionNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR
		END
		--End of Rev. #2.5

		ELSE IF @reqType = @REQUEST_TYPE_EPA
		BEGIN

			UPDATE secuser.EPAWF SET EPAReqStatusID = @reqStatusID, EPAReqStatusCode = @reqStatusCode,
					EPAModifiedBy = @reqModifiedBy, EPAModifiedName = @reqModifiedName,
					EPAModifiedEmail = '', EPAModifiedDate = GETDATE()
				WHERE EPANo = @reqTypeNo

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR

		END

		ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
		BEGIN

			UPDATE secuser.ClearanceFormWF SET ClrFormStatusID = @reqStatusID, ClrFormStatusCode = @reqStatusCode,
					ClrFormModifiedBy = @reqModifiedBy, ClrFormModifiedName = @reqModifiedName,
					ClrFormModifiedEmail = '', ClrFormModifiedDate = GETDATE()
				WHERE ClrFormNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR

		END

		ELSE IF @reqType = @REQUEST_TYPE_RR
		BEGIN
			-- Retrieve the employee email
			SELECT @reqModifiedEmail = ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WITH (NOLOCK) WHERE EmpNo = @reqModifiedBy
			
			-- First update the mail table
			UPDATE secuser.RecruitmentRequisition 
				SET RRStatus = 'Cancelled', RRLastModifiedBy = @reqModifiedBy, RRLastModifiedDate = GETDATE()
			WHERE RRNo = @reqTypeNo

			-- -- Checks for error
			IF @@ERROR = @RETURN_OK		
			BEGIN		
				-- Update the workflow table
				UPDATE secuser.RecruitmentRequisitionWF 
					SET RRReqStatusID = @reqStatusID, RRReqStatusCode = @reqStatusCode,
						RRModifiedBy = @reqModifiedBy, RRModifiedName =  @reqModifiedName, 
						RRModifiedEmail = @reqModifiedEmail, RRModifiedDate = GETDATE()
				WHERE RRNo = @reqTypeNo
			END
			ELSE
				SET @retError = @RETURN_ERROR

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR
		END

		-- ver 2.1 Start
		ELSE IF @reqType = @REQUEST_TYPE_IR
		BEGIN
			-- Retrieve the employee email
			SELECT @reqModifiedEmail = ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WITH (NOLOCK) WHERE EmpNo = @reqModifiedBy
			
			-- First update the main table
			UPDATE secuser.InvoiceRequisition 
				SET IsClosed = 1, ClosedDate = GETDATE(), 
				StatusID = @reqStatusID, StatusCode = @reqStatusCode,
				StatusDesc = 'Cancelled', 
				LastUpdateEmpNo = @reqModifiedBy, LastUpdateDate = GETDATE()
			WHERE InvoiceRequisitionNo = @reqTypeNo

			-- -- Checks for error
			IF @@ERROR = @RETURN_OK		
			BEGIN		
				-- Update the workflow table
				UPDATE secuser.InvoiceRequisitionWF 
					SET IRStatusID = @reqStatusID, IRStatusCode = @reqStatusCode,
						IRLastModifiedByEmpNo = @reqModifiedBy, IRLastModifiedByEmpName =  @reqModifiedName, 
						IRLastModifiedByEmpEmail = @reqModifiedEmail, IRLastModifiedDate = GETDATE()
				WHERE IRNo = @reqTypeNo
			END
			ELSE
				SET @retError = @RETURN_ERROR

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR
		END
		-- ver 2.1 End

		ELSE IF @reqType = @REQUEST_TYPE_ECR  -- ver 2.6 Start
		BEGIN
			-- Retrieve the employee email
			SELECT @reqModifiedEmail = ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy
			
			-- First update the main table
			UPDATE secuser.EmployeeContractRenewal 
				SET LastModifiedBy = @reqModifiedBy, LastModifiedDate = GETDATE()
			WHERE ECRNo = @reqTypeNo

			-- -- Checks for error
			IF @@ERROR = @RETURN_OK		
			BEGIN		
				-- Update the workflow table
				UPDATE secuser.EmployeeContractRenewalWF 
					SET ECRStatusID = @reqStatusID, ECRStatusCode = @reqStatusCode,
						ECRLastModifiedBy = @reqModifiedBy, ECRLastModifiedDate =  GETDATE() 
				WHERE ECRNo = @reqTypeNo
			END
			ELSE
				SET @retError = @RETURN_ERROR

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR
		END  -- ver 2.6 End

		ELSE IF @reqType = @REQUEST_TYPE_CEA  -- ver 2.7 Start
		BEGIN

			-- Retrieve the employee email
			SELECT @reqModifiedEmail = ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy
			
			-- Update the workflow table
			UPDATE secuser.CEAWF 
			SET CEAStatusID = @reqStatusID, 
				CEAStatusCode = @reqStatusCode,
				CEAStatusHandlingCode = @reqStatusHandlingCode,
				CEAModifiedBy = @reqModifiedBy, 				
				CEAModifiedDate =  GETDATE() 
			WHERE CEARequisitionNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR
		END  -- ver 2.7 End
		
		-- Checks for errors
		IF @retError = @RETURN_OK
		BEGIN

			-- Add History Routine Record
			SET @historyDate = DATEADD(ss, -1, GETDATE())
			EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @reqStatusDesc,
				@reqModifiedBy, @reqModifiedName, @historyDate, @retError output

			-- Checks for error
			IF @retError = @RETURN_OK
			BEGIN

				SELECT @actStatusID = a.UDCID
				FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
				WHERE a.UDCUDCGID = 16 
					AND a.UDCCode = 'S'

				-- Update all Activities
				UPDATE secuser.TransActivity SET ActCurrent = 0, ActStatusID = @actStatusID
					WHERE ActProcessID IN (SELECT a.ProcessID
												FROM ProcessWF AS a WITH (NOLOCK)
												WHERE a.ProcessReqType = @reqType AND
													a.ProcessReqTypeNo = @reqTypeNo) AND
						ActStatusID IN (SELECT a.UDCID
											FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
											WHERE a.UDCUDCGID = 16 AND (a.UDCCode = 'CR' OR a.UDCCode = 'IN'))

				-- Checks for error
				IF @retError = @RETURN_OK
				BEGIN

					--ver 2.2 Start
					-- Gets the closing activity ID
					IF(@reqType = @REQUEST_TYPE_IR)
					BEGIN

						SELECT @actID = a.ActID
						FROM secuser.TransActivity AS a WITH (NOLOCK) INNER JOIN
							secuser.ProcessWF AS b WITH (NOLOCK) ON a.ActProcessID = b.ProcessID
						WHERE b.ProcessReqType = @reqType AND b.ProcessReqTypeNo = @reqTypeNo AND LTRIM(RTRIM(a.ActCode)) = 'SND_CLOSE'
					END

					--ver 2.2 End
					ELSE
					BEGIN

						-- Retrieve the last Activity
						SELECT TOP 1 @actID = a.ActID
							FROM secuser.TransActivity AS a WITH (NOLOCK) INNER JOIN
								secuser.ProcessWF AS b WITH (NOLOCK) ON a.ActProcessID = b.ProcessID
							WHERE b.ProcessReqType = @reqType AND b.ProcessReqTypeNo = @reqTypeNo
							ORDER BY a.ActSeq DESC
					END
					

					-- End the Activity Action
					EXEC secuser.pr_UpdateTransactionActivity @actID, @actStatusID, @reqModifiedBy, @retError OUTPUT

				END

				ELSE
					SET @retError = @RETURN_ERROR

			END
		END
	END

	ELSE
		SET @retError = @RETURN_ERROR

	-- Update all parameters
	IF @retError = @RETURN_OK
		EXEC secuser.pr_UpdateAllTransactionParameters @reqType, @reqTypeNo, @reqModifiedBy, @retError OUTPUT


	SET XACT_ABORT OFF

END


/*	Debug:

	DECLARE	@return_value int,
			@retError int

	EXEC	@return_value = secuser.pr_CancelServiceRequest
			@reqType = 7,
			@reqTypeNo = 155,
			@reqStatusCode = N'101',
			@reqModifiedBy = 10003632,
			@reqModifiedName = 'ervin',
			@retError = @retError OUTPUT

	SELECT	@retError as N'@retError'

*/






