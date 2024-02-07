/************************************************************************************************************

Stored Procedure Name	:	secuser.pr_RejectServiceRequest
Description				:	This stored procedure rejects a request by the current assigned person

							This SP is part of the Travel and Expense Management Module Project.

Created By				:	Noel G. Francisco	
Date Created			:	15 May 2013

Parameters
	@reqType					:	The request type
	@reqTypeNo					:	The Request No
	@appRemarks					:	The remark why the request is not approved
	@currentDistMemRoutineSeq	:	The current routine sequence
	@reqModifiedBy				:	The employee no. of the user who calls the SP
	@reqModifiedName			:	The employee name/username of the use who calls the Sp

	@retError					:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2013.05.15 12:08
	Created

	1.1					NGF					2013.05.21 15:22
	Insert order detail history after updating the order details

	1.2					NGF					2013.08.28 08:46
	Added SIR Request Type

	1.3					SAK					2015.04.15 10:25
	Modified the code to handle the new Recruitment Request type

	1.4					SAK					20-Mar-2016 4:00PM
	Modified the code to handle the new Invoice Request type

	1.5					SAK					06-Aug-2018 11:00AM
	Modified the code to handle the new Stores Issue Requisition

	1.6					SAK					27-Feb-2020 4:00PM
	Modified the code to handle the Employee Contract Renewal 

	1.7					EOB					30-Aug-2023 09:52 AM
    Implemented the CEA workflow
************************************************************************************************************/

ALTER PROCEDURE secuser.pr_RejectServiceRequest
(
	@reqType INT,
	@reqTypeNo INT,
	@appRemarks VARCHAR(300),
	@currentDistMemRoutineSeq INT,
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
	DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT		-- ver 1.4
	DECLARE @REQUEST_TYPE_ECR INT		-- ver 1.6
	DECLARE @REQUEST_TYPE_CEA INT		-- ver 1.7

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19	-- ver 1.4
	SET @REQUEST_TYPE_ECR		= 20	-- ver 1.6
	SET @REQUEST_TYPE_CEA		= 22	-- ver 1.7

	-- Define Approver Role
	DECLARE @SERV_ROLE_APPROVER int
	DECLARE @SERV_ROLE_VALIDATOR int

	SELECT @SERV_ROLE_APPROVER = a.UDCID
		FROM secuser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'APP'

	SELECT @SERV_ROLE_VALIDATOR = a.UDCID
		FROM secuser.UserDefinedCode AS a
		WHERE a.UDCUDCGID = 11 AND a.UDCCode = 'VAL'

	-- Declare necessary variables
	DECLARE @currentDistMemID int
	DECLARE @currentDistMemActionType int
	DECLARE @distMemID int

	DECLARE @currentDate datetime
	DECLARE @reqStatusID int
	DECLARE @reqStatusCode varchar(10)
	DECLARE @reqStatusDesc varchar(300)
	DECLARE @reqStatusHandlingCode varchar(50)
	DECLARE @approvalFlag char(1)
	-- End of necessary variables

	-- Trim input
	SET @appRemarks = LTRIM(RTRIM(@appRemarks))

	-- Craetes an approval record
	INSERT INTO secuser.Approval(AppReqType, AppReqTypeNo, AppApproved, AppRemarks, AppActID, AppRoutineSeq,
			AppCreatedBy, AppCreatedName, AppCreatedDate,
			AppModifiedBy, AppModifiedName, AppModifiedDate)
		VALUES(@reqType, @reqTypeNo, 0, @appRemarks,
			0, @currentDistMemRoutineSeq,
			@reqModifiedBy, @reqModifiedName, GETDATE(),
			@reqModifiedBy, @reqModifiedName, GETDATE())

	-- Checks for error
	IF @@ERROR = @RETURN_OK
	BEGIN

		-- Retrieves the action type
		IF EXISTS(SELECT a.CurrentDistMemID
					FROM secuser.CurrentDistributionMember AS a
					WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
						a.CurrentDistMemCurrent = 1 AND a.CurrentDistMemEmpNo = @reqModifiedBy)
		BEGIN

			SELECT TOP 1 @currentDistMemID = a.CurrentDistMemID, @distMemID = a.CurrentDistMemRefID,
					@currentDistMemActionType = a.CurrentDistMemActionType
				FROM secuser.CurrentDistributionMember AS a
				WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
					a.CurrentDistMemCurrent = 1 AND a.CurrentDistMemEmpNo = @reqModifiedBy

		END

		ELSE
		BEGIN

			SELECT TOP 1 @currentDistMemID = a.CurrentDistMemID, @distMemID = a.CurrentDistMemRefID,
					@currentDistMemActionType = a.CurrentDistMemActionType
				FROM secuser.CurrentDistributionMember AS a
				WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo AND
					a.CurrentDistMemEmpNo = @reqModifiedBy
				ORDER BY a.CurrentDistMemModifiedDate DESC

		END

		-- Sets the request status
		IF @currentDistMemActionType = @SERV_ROLE_VALIDATOR OR @currentDistMemActionType = 0
			SELECT @reqStatusID = a.UDCID, @reqStatusCode = a.UDCCode,
					@reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1, @approvalFlag = 'R',
					@reqStatusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
				FROM secuser.UserDefinedCode AS a
				WHERE a.UDCUDCGID = 9 AND a.UDCCode = '112'

		ELSE
			SELECT @reqStatusID = a.UDCID, @reqStatusCode = a.UDCCode,
					@reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1, @approvalFlag = 'R',
					@reqStatusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
				FROM secuser.UserDefinedCode AS a
				WHERE a.UDCUDCGID = 9 AND a.UDCCode = '110'

		-- Creates a log history
		SET @currentDate	= GETDATE()
		SET @reqStatusDesc	= @reqStatusDesc + ' (' + @reqModifiedName + ')'
		EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @reqStatusDesc,
			@reqModifiedBy, @reqModifiedName, @currentDate, @retError output

		-- Checks the error
		IF @retError = @RETURN_OK
		BEGIN

			-- Updates the status of the Current Distribution Member
			UPDATE secuser.CurrentDistributionMember SET CurrentDistMemCurrent = 0, CurrentDistMemStatusID = @reqStatusID,
					CurrentDistMemModifiedBy = @reqModifiedBy, CurrentDistMemModifiedDate = GETDATE()
				WHERE CurrentDistMemID = @currentDistMemID

			-- Checks for errors
			IF @@ERROR = @RETURN_OK
			BEGIN

				-- Updates the status of the Distribution Member
				UPDATE secuser.DistributionMember SET DistMemStatusID = (SELECT a.UDCID
																			FROM secuser.UserDefinedCode AS a
																			WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C')
					WHERE DistMemID = @distMemID

				-- Checks for errors
				IF @@ERROR = @RETURN_OK
				BEGIN

					-- Updates the request status
					IF @reqType = @REQUEST_TYPE_PR
					BEGIN

						-- Retrieves the document type
						DECLARE @prDocType varchar(2)
						SELECT @prDocType = a.PHDCTO
							FROM secuser.F4301 AS a
							WHERE a.PHDOCO = @reqTypeNo AND PHSFXO = '000'

						-- Updates the Purchase Requisition WF
						UPDATE secuser.PurchaseRequisitionWF SET PRReqStatusID = @reqStatusID, PRReqStatusCode = @reqStatusCode,
								PRModifiedBy = @reqModifiedBy, PRModifiedName = @reqModifiedName,
								PRModifiedEmail = '', PRModifiedDate = GETDATE()
							WHERE PRDocNo = @reqTypeNo

						-- Checks for error
						IF @@ERROR = @RETURN_OK
						BEGIN

							-- Updates the next and last status codes
							IF @prDocType = 'OP'
								UPDATE secuser.F4311 SET PDLTTR = PDNXTR, PDNXTR = '360', PDPODC01 = 'R'
									WHERE PDDOCO = @reqTypeNo AND PDDCTO = @prDocType AND PDSFXO = '000' AND PDNXTR <> '999'

							ELSE
							BEGIN

								-- Checks if order is a PR Stock Item
								IF @prDocType = 'OR' AND EXISTS(SELECT a.PDDOCO
																	FROM secuser.F4311 AS a
																	WHERE PDDOCO = @reqTypeNo AND PDDCTO = @prDocType AND PDSFXO = '000' AND PDNXTR <> '999' AND PDLNTY = 'S')
									UPDATE secuser.F4311 SET PDLTTR = PDNXTR, PDNXTR = '135', PDPODC01 = 'R'
										WHERE PDDOCO = @reqTypeNo AND PDDCTO = @prDocType AND PDSFXO = '000' AND PDNXTR <> '999'

								ELSE
									UPDATE secuser.F4311 SET PDLTTR = '980', PDNXTR = '999', PDPODC01 = 'R'
										WHERE PDDOCO = @reqTypeNo AND PDDCTO = @prDocType AND PDSFXO = '000' AND PDNXTR <> '999'

							END

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
					-- *** ver 1.3 Start
					ELSE IF @reqType = @REQUEST_TYPE_RR
					BEGIN
						-- Update the main table first
						UPDATE secuser.RecruitmentRequisition SET RRStatus = 'Rejected' WHERE RRNo = @reqTypeNo

						IF @@ERROR = @RETURN_OK
						BEGIN
							-- Now update the workflow table
							UPDATE secuser.RecruitmentRequisitionWF
								SET RRReqStatusID = @reqStatusID, RRReqStatusCode = @reqStatusCode, 
									RRModifiedBy = @reqModifiedBy, RRModifiedName = @reqModifiedName, 
									RRModifiedEmail = (SELECT EmpEmail FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy), 
									RRModifiedDate = GETDATE()
							WHERE RRNo = @reqTypeNo
						END
						ELSE
							SET @retError = @RETURN_ERROR

						-- Checks for error
						IF @@ERROR = @RETURN_OK
							-- Inserts order detail history
							EXEC secuser.pr_InsertOrderDetailHistory @reqTypeNo, @prDocType, @reqModifiedBy, @reqModifiedName, @retError output
						ELSE
							SET @retError = @RETURN_ERROR

						-- Checks for error
						IF @@ERROR <> @RETURN_OK
							SET @retError = @RETURN_ERROR	
					END
					-- *** ver 1.3 End

					-- *** ver 1.4 Start
					ELSE IF @reqType = @REQUEST_TYPE_IR
					BEGIN
					   -- Update the main table
						UPDATE secuser.InvoiceRequisition 
							SET IsClosed = 1, ClosedDate = GETDATE(), StatusID = @reqStatusID, StatusCode = @reqStatusCode
						WHERE InvoiceRequisitionNo = @reqTypeNo

						IF @@ERROR = @RETURN_OK
						BEGIN
							-- Update the workflow table
							UPDATE secuser.InvoiceRequisitionWF 
								SET IRStatusID = @reqStatusID, IRStatusCode = @reqStatusCode,
									IRLastModifiedByEmpNo = @reqModifiedBy, IRLastModifiedByEmpName =  @reqModifiedName, 
									IRLastModifiedByEmpEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy), 
									IRLastModifiedDate = GETDATE()
							WHERE IRNo = @reqTypeNo
						END
						ELSE
							SET @retError = @RETURN_ERROR

						-- Checks for error
						IF @@ERROR <> @RETURN_OK
							SET @retError = @RETURN_ERROR	

					END
					-- *** ver 1.4 End

					-- *** ver 1.5 Start
					--ELSE IF @reqType = @REQUEST_TYPE_SIR
					--BEGIN
					--   -- Update the main table
					--	UPDATE secuser.StoresIssueRequisitionWF 
					--		SET SIRReqStatusID = @reqStatusID, SIRReqStatusCode = @reqStatusCode,
					--			SIRLastModifiedBy = @reqModifiedBy, SIRLastModifiedDate = GETDATE()
					--	WHERE SIRNo = @reqTypeNo

					--	-- Checks for error
					--	IF @@ERROR <> @RETURN_OK
					--		SET @retError = @RETURN_ERROR	

					--END
					-- *** ver 1.5 End

					-- *** ver 1.6 Start
					ELSE IF @reqType = @REQUEST_TYPE_ECR
					BEGIN
						IF @@ERROR = @RETURN_OK
						BEGIN
							-- Update the workflow table
							UPDATE secuser.EmployeeContractRenewalWF 
								SET ECRStatusID = @reqStatusID, ECRStatusCode = @reqStatusCode,
									ECRLastModifiedBy = @reqModifiedBy, ECRLastModifiedDate = GETDATE()
							WHERE ECRNo = @reqTypeNo
						END
						ELSE
							SET @retError = @RETURN_ERROR

						-- Checks for error
						IF @@ERROR <> @RETURN_OK
							SET @retError = @RETURN_ERROR	

					END
					-- *** ver 1.6 End

					-- *** ver 1.7 Start
					ELSE IF @reqType = @REQUEST_TYPE_CEA
					BEGIN

						IF @@ERROR = @RETURN_OK
						BEGIN
							-- Update the workflow table
							UPDATE secuser.CEAWF 
							SET CEAStatusID = @reqStatusID, 
								CEAStatusCode = @reqStatusCode,
								CEAStatusHandlingCode = @reqStatusHandlingCode,
								CEAModifiedBy = @reqModifiedBy, 
								CEAModifiedDate = GETDATE()
							WHERE CEARequisitionNo = @reqTypeNo
						END
						ELSE
							SET @retError = @RETURN_ERROR

						-- Checks for error
						IF @@ERROR <> @RETURN_OK
							SET @retError = @RETURN_ERROR	

					END
					-- *** ver 1.7 End
				END

				ELSE
					SET @retError = @RETURN_ERROR

			END

			ELSE
				SET @retError = @RETURN_ERROR

		END
	END

	ELSE
		SET @retError = @RETURN_ERROR

END





