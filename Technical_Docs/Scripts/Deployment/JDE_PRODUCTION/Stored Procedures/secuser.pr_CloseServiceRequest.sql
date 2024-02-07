/**************************************************************************************************************************************************

Stored Procedure Name	:	secuser.pr_CloseServiceRequest
Description				:	This stored procedure closes the service request and updates the workflow.

							This SP is part of the Transaction Workflow that can be used from different
							projects.

Created By				:	Noel G. Francisco
Date Created			:	14 February 2008

Parameters
	@reqType			:	The Request Type to close
	@reqTypeNo			:	The Request Type No to close
	@reqModifiedBy		:	The employee no. of the user that calls this SP
	@reqModifiedName	:	The employee name of the user that calls this SP

	@retError			:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2008.02.14 12:56
	Created

	1.1					NGF					2008.04.27 10:25
	Update the return error field of request table

	1.2					NGF					2008.08.12 16:16
	Added the Cash Advance Request functionality

	1.3					NGF					2009.08.30 07:57
	Added the Personal Action Form functionality

	1.4					NGF					2009.11.08 08:59
	Added the Employee Performance Appraisal form

	1.5					NGF					2010.08.01 12:18
	Change the status of OQ

	1.6					NGF					2011.10.02 09:31
	Added necessary execution for TSR

	1.7					NGF					2012.06.13 09:11
	Added the Clearance Form

	1.8					NGF					2013.02.04 13:31
	Added the changing of statuses for PO

	1.9					SAK					2013.04.02 10.03
	Modified to update the tables F4301 and F4209 after approval
	and if the PO was on hold.

	2.0					NGF					2013.04.06 13:31
	Insert order history to F43199 table

	2.1					SAK					2013..5.20 12:37
	Modified to update tables for held orders for all document types

	2.2					NGF					2013.05.21 15:18
	Insert order detail history after updating the order details

	2.3					NGF					2013.10.21 07:57
	Truncates the last modified name

	2.4					EOB					2014.11.13 03:30
	Get the value of @reqModifiedBy and @reqModifiedName parameters from the "TransActivity" table. Applied only in EPA module

	2.5					SAK					2014.12.25 14:25
	Modified to handle the Material Orders.

	2.6					SAK					2015.04.15 09:25
	Modified to handle the new Recruitment Request.

	2.7					SAK					20-Mar-2016 03:52PM
	Modified to handle Invoice Requesition.

	2.8					SAK					06-Aug-2018 10:45 AM
	Modified to handle Stores Issue Requesition.

	2.9					SAK					25-Feb-2020 03:52PM
	Modified to handle Employee Contract Renewal Requesition.

	3.0					EOB					29-May-2023 12:19 PM
	Fixed bug reported t=in Helpdesk #196425 where the total amount in the order header does not tally with the total amount in the order details

	3.1					EOB					22-Aug-2023 01:54 PM
	Implemented the workflow for CEA

***************************************************************************************************************************************************/

ALTER PROCEDURE secuser.pr_CloseServiceRequest
(
	@reqType				INT,
	@reqTypeNo				FLOAT,
	@reqStatusCode			VARCHAR(10),
	@reqModifiedBy			INT,
	@reqModifiedName		VARCHAR(50),
	@retError				INT OUTPUT
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
	DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT	-- ver 2.7
	DECLARE @REQUEST_TYPE_SIR INT	-- ver 2.8
	DECLARE @REQUEST_TYPE_ECR INT	-- ver 2.9
	DECLARE @REQUEST_TYPE_CEA INT	-- ver 3.1

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17	-- ver 2.8
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19	-- ver 2.7
	SET @REQUEST_TYPE_ECR		= 20	-- ver 2.9
	SET @REQUEST_TYPE_CEA		= 22	-- ver 3.1

	-- Declare necessary variables
	DECLARE @reqStatusID INT
	DECLARE @reqStatusDesc VARCHAR(300)
	DECLARE @reqStatusHandlingCode VARCHAR(50)

	DECLARE @actID INT
	DECLARE @actStatusID INT

	DECLARE @historyDate DATETIME

	DECLARE @leaveEmpNo INT
	DECLARE @leaveType CHAR(5)
	DECLARE @leaveDuration FLOAT
	DECLARE @leaveWorkstationID CHAR(10)

	DECLARE @uniqueID FLOAT
	DECLARE @totalOrders INT
	
	--Variables used in EPA
	DECLARE @reqModifiedByTemp INT,
			@reqModifiedNameTemp VARCHAR(50)

	--Initialize variables
	SELECT	@reqModifiedByTemp = 0,
			@reqModifiedNameTemp = NULL

	-- End of necessary variables

	SET XACT_ABORT ON

	-- Truncates the modified name
	SET @reqModifiedName = LEFT(@reqModifiedName, 10)

	IF @reqType = @REQUEST_TYPE_EPA
	BEGIN

		--Get the person who closed the requisition
		SELECT TOP 1 @reqModifiedByTemp = b.ActModifiedBy, @reqModifiedNameTemp = RTRIM(c.EmpName)
		FROM SecUser.ProcessWF a WITH (NOLOCK) 
			INNER JOIN SecUser.TransActivity b WITH (NOLOCK) ON a.ProcessID = b.ActProcessID
			INNER JOIN secuser.EmployeeMaster c WITH (NOLOCK) ON b.ActModifiedBy = c.EmpNo
		WHERE 
			a.ProcessReqType = @reqType 
			AND a.ProcessReqTypeNo = @reqTypeNo
			AND RTRIM(b.ActCode) = 'FUNC_CLOSE'
		ORDER BY b.ActID DESC

		IF ISNULL(@reqModifiedByTemp, 0) <> 0 AND ISNULL(@reqModifiedNameTemp, '') <> ''
		BEGIN

			SELECT	@reqModifiedBy = @reqModifiedByTemp,
					@reqModifiedName = @reqModifiedNameTemp
		END
	END

	-- Update all current distribution members
	UPDATE secuser.CurrentDistributionMember 
	SET CurrentDistMemCurrent = 0
	WHERE CurrentDistMemReqType = @reqType 
		AND CurrentDistMemReqTypeNo = @reqTypeNo

	-- Check for errors
	IF @@ERROR = @RETURN_OK
	BEGIN

		SELECT	@reqStatusID = a.UDCID, 
				@reqStatusDesc = a.UDCSpecialHandlingCode + ' - ' + a.UDCDesc1,
				@reqStatusHandlingCode = RTRIM(a.UDCSpecialHandlingCode) 
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 9 
			AND a.UDCCode = @reqStatusCode

		-- Update the Service Request
		IF @reqType = @REQUEST_TYPE_LEAVE
		BEGIN

			-- Retrieve leave requisition details
			SELECT	@leaveEmpNo = EmpNo, 
					@leaveType = a.LeaveType, 
					@leaveDuration = a.LeaveDuration, 
					@leaveWorkstationID = a.WorkstationID
			FROM secuser.LeaveRequisition AS a WITH (NOLOCK)
			WHERE a.RequisitionNo = @reqTypeNo

			-- Update the leave balance
			EXEC secuser.pr_UpdateLeaveBalance @reqTypeNo, @leaveEmpNo, @leaveType, @leaveDuration, @reqModifiedName, @leaveWorkstationID, @retError output

			-- Checks for error
			IF @retError = @RETURN_OK
			BEGIN

				-- Update F58LV13
				UPDATE F58LV13 
				SET LRY58VCAFG = 'N', 
					LRY58VCADT = dbo.ConvertToJulian(GETDATE()),
					LRUSER = @reqModifiedName,
					LRUPMT = CONVERT(float, REPLACE(CONVERT(varchar(100), GETDATE(), 108), ':', '')),
					LRUPMJ = dbo.ConvertToJulian(GETDATE())
				WHERE LRY58VCRQN = @reqTypeNo 
					AND LRAN8 = @leaveEmpNo

				-- Checks for error
				IF @@ERROR = @RETURN_OK
					UPDATE secuser.LeaveRequisitionWF 
					SET LeaveApprovalFlag = 'N',
						LeaveReqStatusID = @reqStatusID, 
						LeaveReqStatusCode = @reqStatusCode,
						LeaveModifiedBy = @reqModifiedBy, 
						LeaveModifiedName = @reqModifiedName,
						LeaveModifiedEmail = '', 
						LeaveModifiedDate = GETDATE()
					WHERE LeaveNo = @reqTypeNo

			END
		END

		ELSE IF @reqType = @REQUEST_TYPE_PR
		BEGIN

			UPDATE secuser.PurchaseRequisitionWF 
			SET PRReqStatusID = @reqStatusID, 
				PRReqStatusCode = @reqStatusCode,
				PRModifiedBy = @reqModifiedBy, 
				PRModifiedName = @reqModifiedName,
				PRModifiedEmail = '', 
				PRModifiedDate = GETDATE()
			WHERE PRDocNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR = @RETURN_OK
			BEGIN

				DECLARE @prDocType varchar(2)

				SELECT @prDocType = LTRIM(RTRIM(a.PHDCTO))
				FROM secuser.F4301 AS a WITH (NOLOCK)
				WHERE a.PHDOCO = @reqTypeNo 
					AND LTRIM(RTRIM(a.PHSFXO)) = '000'
				
				IF RTRIM(@reqStatusCode) <> '110'
				BEGIN

					-- Update the status of each order
					IF @prDocType = 'OR'
					BEGIN
                    
						UPDATE secuser.F4311 
						SET PDNXTR = '220', 
							PDLTTR = '139'
						WHERE PDDOCO = @reqTypeNo 
							AND LTRIM(RTRIM(PDDCTO)) = @prDocType 
							AND LTRIM(RTRIM(PDSFXO)) = '000' 
							AND LTRIM(RTRIM(PDNXTR)) <> '999'
					END 

					ELSE IF @prDocType = 'OQ'
					BEGIN
                    
						UPDATE secuser.F4311 
						SET PDNXTR = '999', 
							PDLTTR = '160'
							--PDNXTR = '160', PDLTTR = '150'--PDNXTR = '999', PDLTTR = '155'
						WHERE PDDOCO = @reqTypeNo 
							AND LTRIM(RTRIM(PDDCTO)) = @prDocType 
							AND LTRIM(RTRIM(PDSFXO)) = '000' 
							AND LTRIM(RTRIM(PDNXTR)) <> '999'
					END 

					ELSE IF @prDocType IN ('OP', 'MO')
					BEGIN
                    
						UPDATE secuser.F4311 
						SET PDNXTR = '310', 
							PDLTTR = '300'
						WHERE PDDOCO = @reqTypeNo 
							AND LTRIM(RTRIM(PDDCTO)) = @prDocType 
							AND LTRIM(RTRIM(PDSFXO)) = '000' 
							AND LTRIM(RTRIM(PDNXTR)) <> '999'
					END 				
				END

					-- Checks for error
					IF @@ERROR = @RETURN_OK
					BEGIN

						IF EXISTS
						(
							SELECT PHHOLD 
							FROM secuser.F4301 WITH (NOLOCK) 
							WHERE PHDOCO = @reqTypeNo 
								AND LTRIM(RTRIM(PHDCTO)) = @prDocType 
								AND LTRIM(RTRIM(PHHOLD)) = 'A1'
						)
						BEGIN

							UPDATE secuser.F4301 
							SET PHHOLD = ''
							WHERE PHDOCO = @reqTypeNo 
								AND LTRIM(RTRIM(PHDCTO)) = @prDocType 
								AND LTRIM(RTRIM(PHHOLD)) = 'A1'

							-- Checks for error
							IF @@ERROR = @RETURN_OK
							BEGIN

								DECLARE	@poTotalAmtBD		FLOAT = 0,
										@poTotalAmtFC		FLOAT = 0

								--Release the hold amount in all order lines
								UPDATE secuser.F4311 
								SET PDUORG = PDUORG + PDUCHG, 
									PDUCHG = 0, 
									PDAEXP = PDAEXP + PDACHG, 
									PDACHG = 0, 
									PDFEA = PDFEA + PDFCHG, 
									PDFCHG = 0
								WHERE PDDOCO = @reqTypeNo 
									AND LTRIM(RTRIM(PDDCTO)) = @prDocType

								--Start of Rev. #3.0
								--Get the PO order lines total amount in BD and foreign currency
								SELECT	@poTotalAmtBD = SUM(PDAEXP + PDACHG),
										@poTotalAmtFC = SUM(PDFEA + PDFCHG) 
								FROM secuser.F4311 a WITH (NOLOCK) 
								WHERE LTRIM(RTRIM(a.PDKCOO)) = '00100' 
									AND a.PDDOCO = @reqTypeNo 
									AND LTRIM(RTRIM(a.PDDCTO)) = @prDocType
									AND LTRIM(RTRIM(a.PDSFXO)) = '000'
									AND LTRIM(RTRIM(ISNULL(a.PDLTTR, ''))) <> '980'

								--Update order header total amount in BD and foreign currency
								UPDATE secuser.F4301
								SET PHOTOT = @poTotalAmtBD,
									PHFAP = @poTotalAmtFC
								WHERE PHDOCO = @reqTypeNo 
									AND LTRIM(RTRIM(PHSFXO)) = '000'
								--End of Rev. #3.0

								-- Checks for error
								IF @@ERROR = @RETURN_OK
								BEGIN

									UPDATE h 
									SET h.HORDC = 'PD', 
										h.HORDB = UPPER(a.AppModifiedName), 
										h.HORDJ = dbo.ConvertToJulian(a.AppModifiedDate),
										h.HORDT = secuser.GetTime(AppModifiedDate)
									FROM secuser.F4209 AS h WITH (NOLOCK) 
										INNER JOIN secuser.Approval AS a WITH (NOLOCK) ON h.HODOCO = a.AppReqTypeNo
									WHERE h.HODOCO = @reqTypeNo 
										AND LTRIM(RTRIM(h.HODCTO)) = @prDocType 
										AND LTRIM(RTRIM(h.HOHCOD)) = 'A1' 
										AND a.AppModifiedBy IN
											(
												SELECT TOP 1 AppModifiedBy 
												FROM secuser.Approval WITH (NOLOCK)
												WHERE AppReqType = 5 
													AND AppReqTypeNo = @reqTypeNo 
												ORDER BY AppModifiedDate DESC
											)

								END
								ELSE
									SET @retError = @RETURN_ERROR

							END
							ELSE
								SET @retError = @RETURN_ERROR

						END
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
				UPDATE secuser.F4801 SET WASRST = 'MK'
					WHERE WADOCO = @reqTypeNo AND WADCTO = 'WO'

				-- Checks for error
				IF @@ERROR = @RETURN_OK
				BEGIN

					DECLARE @woEquipNo float
					DECLARE @currentDate datetime

					SET @currentDate = GETDATE()
					SELECT @woEquipNo = a.WANUMB
						FROM secuser.F4801 AS a
						WHERE a.WADCTO = 'WO' AND a.WADOCO = @reqTypeNo

					EXEC secuser.pr_InsertUpdateDeleteWorkOrderStatus @woEquipNo, 0, '2', @reqTypeNo, 'MK',
						@currentDate, NULL, 'Work Order Closed',
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

			UPDATE secuser.F55PAF SET PAY58VCAFG = 'N', PAUSER = @reqModifiedName, PAUPMJ = dbo.ConvertToJulian(GETDATE()),
					PAUPMT = CONVERT(float, REPLACE(CONVERT(varchar(100), GETDATE(), 108), ':', ''))
				WHERE PAG55AUTO = (SELECT a.PAFAutoID
									FROM secuser.PAFWF AS a
									WHERE a.PAFNo = @reqTypeNo)

			-- Checks for error
			IF @@ERROR = @RETURN_OK
			BEGIN

				UPDATE secuser.PAFWF SET PAFReqStatusID = @reqStatusID, PAFReqStatusCode = @reqStatusCode,
						PAFModifiedBy = @reqModifiedBy, PAFModifiedName = @reqModifiedName,
						PAFModifiedEmail = '', PAFModifiedDate = GETDATE()
					WHERE PAFNo = @reqTypeNo

				-- Checks for error
				IF @@ERROR <> @RETURN_OK
					SET @retError = @RETURN_ERROR

			END

			ELSE
				SET @retError = @RETURN_ERROR

		END

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

		-- *** ver 2.6 Start
		ELSE IF @reqType = @REQUEST_TYPE_RR
		BEGIN
			-- Update the main table first
			UPDATE secuser.RecruitmentRequisition SET RRStatus = 'Closed' WHERE RRNo = @reqTypeNo

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
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR			
		END
		-- *** ver 2.6 End

		-- *** ver 2.7 StarT
		ELSE IF @reqType = @REQUEST_TYPE_IR
		BEGIN	
			-- Update the main table
			UPDATE secuser.InvoiceRequisition 
				SET IsClosed=1, ClosedDate=GETDATE(), StatusID = @reqStatusID, StatusCode = @reqStatusCode
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

		-- *** ver 2.7 End

		-- *** ver 2.8 Start
		ELSE IF @reqType = @REQUEST_TYPE_SIR
		BEGIN
			-- Update the main table first
			UPDATE secuser.StoresIssueRequisitionWF
				SET SIRReqStatusID = @reqStatusID, SIRReqStatusCode = @reqStatusCode, 
					SIRLastModifiedBy = @reqModifiedBy, SIRLastModifiedDate = GETDATE()
			WHERE SIRNo = @reqTypeNo

			-- Checks for error
			IF @@ERROR <> @RETURN_OK
				SET @retError = @RETURN_ERROR			
		END
		-- *** ver 2.8 End

		-- *** ver 2.9 Start
		ELSE IF @reqType = @REQUEST_TYPE_ECR
		BEGIN
			IF @@ERROR = @RETURN_OK
			BEGIN
				-- Now update the workflow table
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
		-- *** ver 2.9 End

		-- *** ver 3.1 Start
		ELSE IF @reqType = @REQUEST_TYPE_CEA
		BEGIN

			IF @@ERROR = @RETURN_OK
			BEGIN

				-- Now update the workflow table
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
		-- *** ver 3.1 End

		-- Checks for errors
		IF @retError = @RETURN_OK
		BEGIN			

			-- Add History Routine Record
			SET @historyDate = DATEADD(ss, -1, GETDATE())
			EXEC secuser.pr_InsertRequestHistory @reqType, @reqTypeNo, @reqStatusDesc,
				@reqModifiedBy, @reqModifiedName, @historyDate, @retError output

			IF @retError = @RETURN_OK
			BEGIN

				-- Retrieve the Activity Status ID
				SELECT @actStatusID = a.UDCID
					FROM secuser.UserDefinedCode AS a
					WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'C'

				-- Retrieve the current activity
				SELECT @actID = a.ActID
					FROM secuser.TransActivity AS a INNER JOIN
						secuser.ProcessWF AS b ON a.ActProcessID = b.ProcessID
					WHERE a.ActCurrent = 1 AND b.ProcessReqType = @reqType AND b.ProcessReqTypeNo = @reqTypeNo

				-- End the Activity Action
				EXEC secuser.pr_UpdateTransactionActivity @actID, @actStatusID, @reqModifiedBy, @retError OUTPUT

			END
		END

		ELSE
			SET @retError = @RETURN_ERROR

	END

	ELSE
		SET @retError = @RETURN_ERROR

	-- Update all parameters
	IF @retError = @RETURN_OK
		EXEC secuser.pr_UpdateAllTransactionParameters @reqType, @reqTypeNo, @reqModifiedBy, @retError OUTPUT

	-- Update the return error of the status
	IF @retError <> @RETURN_OK
	BEGIN

		IF @reqType = @REQUEST_TYPE_LEAVE
			UPDATE secuser.LeaveRequisitionWF SET LeaveModifiedDate = GETDATE(), LeaveRetError = @retError
				WHERE LeaveNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_PR
			UPDATE secuser.PurchaseRequisitionWF SET PRModifiedDate = GETDATE(), PRRetError = @retError
				WHERE PRDocNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_TSR
			UPDATE secuser.TSRWF SET TSRModifiedDate = GETDATE(), TSRRetError = @retError
				WHERE TSRNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_PAF
			UPDATE secuser.PAFWF SET PAFModifiedDate = GETDATE(), PAFRetError = @retError
				WHERE PAFNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_EPA
			UPDATE secuser.EPAWF SET EPAModifiedDate = GETDATE(), EPARetError = @retError
				WHERE EPANo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
			UPDATE secuser.ClearanceFormWF SET ClrFormModifiedDate = GETDATE(), ClrFormRetError = @retError
				WHERE ClrFormNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_IR
			UPDATE secuser.InvoiceRequisitionWF SET IRLastModifiedDate = GETDATE(), IRRetError = @retError
				WHERE IRNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_SIR
			UPDATE secuser.StoresIssueRequisitionWF SET SIRLastModifiedDate = GETDATE(), SIRRetError = @retError
				WHERE SIRNo = @reqTypeNo

		ELSE IF @reqType = @REQUEST_TYPE_ECR
			UPDATE secuser.EmployeeContractRenewalWF SET ECRLastModifiedDate = GETDATE()
				WHERE ECRNo = @reqTypeNo

		-- *** ver 3.1 Start
		ELSE IF @reqType = @REQUEST_TYPE_CEA
		BEGIN
		 
			UPDATE secuser.CEAWF 
			SET CEAModifiedDate = GETDATE()
			WHERE CEARequisitionNo = @reqTypeNo
		END 
		-- *** ver 3.1 End

	END


	SET XACT_ABORT OFF

END


/*	Debug:

PARAMETERS:
	@reqType				INT,
	@reqTypeNo				FLOAT,
	@reqStatusCode			VARCHAR(10),
	@reqModifiedBy			INT,
	@reqModifiedName		VARCHAR(50),
	@retError				INT OUTPUT

	EXEC secuser.pr_CloseServiceRequest 5, 60054091, '133', 10003873, 'salmutawa'

	DECLARE	@return_value int,
			@retError int

	SELECT	@retError = 0

	EXEC	@return_value = secuser.pr_CloseServiceRequest
			@reqType = 5,
			@reqTypeNo = 60054091,
			@reqStatusCode = N'133',
			@reqModifiedBy = 10003873,
			@reqModifiedName = N'salmutawa',
			@retError = @retError OUTPUT

	SELECT	@retError as N'@retError'

*/









