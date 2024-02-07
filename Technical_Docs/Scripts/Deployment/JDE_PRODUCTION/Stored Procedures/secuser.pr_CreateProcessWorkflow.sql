/*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	Description	:
	Parameters	:
		@reqType - The type of request which can be Travel Request or Expense Request
		@reqTypeNo - The request no of either from Travel Request or Expense Request

	Revision History:
		1.1					SHOUKHAT ALI KHAN					2015.04.12 15:45
		Modified to include recruitment requisitions

		1.2					SHOUKHAT ALI KHAN					13-Mar-2016 12:30 PM
		Modified to include Invoice requisitions

		1.3					ERVIN BROSAS						30-Jul-2019 13:20 PM
		Modified to include Probationary Assessment Requisition

		1.4					SHOUKHAT ALI KHAN					25-Feb-2020 14:30 PM
		Modified to include Employee Contract Renewal requisitions

		1.5					ERVIN BROSAS						12-Dec-2021	15:29
		Update the value of "WorkflowStatusID" field to 46 - Waiting for approval for EPMS request

		1.6					ERVIN BROSAS						29-Aug-2023	12:00 PM
		Implemented the CEA workflow
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

ALTER PROCEDURE secuser.pr_CreateProcessWorkflow
(
	@reqType			INT,
	@reqTypeNo			INT,
	@createdModifiedBy	INT,
	@retError			INT OUTPUT
)
AS
BEGIN

	--Tell SQL Engine not to return the row-count information
	SET NOCOUNT ON 

	-- Define error codes
	DECLARE @RETURN_OK int
	DECLARE @RETURN_ERROR int

	SET @RETURN_OK			= 0
	SET @RETURN_ERROR		= -1

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
    DECLARE @REQUEST_TYPE_IR INT
	DECLARE @REQUEST_TYPE_PROBY INT		--Rev. #1.3
	DECLARE @REQUEST_TYPE_ECR INT		--Rev. #1.4
	DECLARE @REQUEST_TYPE_CEA INT		--Rev. #1.6
    

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19
	SET @REQUEST_TYPE_ECR		= 20	--Rev. #1.4
	SET @REQUEST_TYPE_PROBY		= 21	--Rev. #1.3
	SET @REQUEST_TYPE_CEA		= 22	--Rev. #1.6

	-- Declare necessary variables
	DECLARE @statusID int
	DECLARE @processID int
	DECLARE @reqTypeID int

	-- End of necessary variables

	-- Initialize Activity Status
	SELECT @statusID = a.UDCID
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 16 AND a.UDCCode = 'CR'

	-- Determine the Request Type 
	IF @reqType = @REQUEST_TYPE_LEAVE
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.LeaveRequisition AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.RequestTypeID = b.ReqTypeID
			WHERE a.RequisitionNo = @reqTypeNo
	 
	END

	ELSE IF @reqType = @REQUEST_TYPE_PR
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.PurchaseRequisitionWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.PRReqTypeID = b.ReqTypeID
			WHERE a.PRDocNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_TSR
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.TSRWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.TSRReqTypeID = b.ReqTypeID
			WHERE a.TSRNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_PAF
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.PAFWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.PAFReqTypeID = b.ReqTypeID
			WHERE a.PAFNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_EPA
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.EPAWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.EPAReqTypeID = b.ReqTypeID
			WHERE a.EPANo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.ClearanceFormWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.ClrFormReqTypeID = b.ReqTypeID
			WHERE a.ClrFormNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_SIR
	BEGIN

		-- Retrieve Process ID
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.SIRWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.SIRReqTypeID = b.ReqTypeID
			WHERE a.SIRNo = @reqTypeNo

	END

	ELSE IF @reqType = @REQUEST_TYPE_RR --RECRUITMENT REQUISITION
	BEGIN
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.RecruitmentRequisitionWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.RRReqTypeID = b.ReqTypeID
			WHERE a.RRNo = @reqTypeNo
	END

	ELSE IF @reqType = @REQUEST_TYPE_IR --SUPPLIER INVOICE REQUISITION
	BEGIN
		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.InvoiceRequisitionWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.IRReqTypeID = b.ReqTypeID
			WHERE a.IRNo = @reqTypeNo
	END

	--Start of Rev. #1.3
	ELSE IF @reqType = @REQUEST_TYPE_PROBY	
	BEGIN

		SELECT	@processID = a.ReqTypeProcessID, 
				@reqTypeID = a.ReqTypeID
		FROM secuser.RequestType AS a WITH (NOLOCK)
		WHERE RTRIM(a.ReqTypeCode) = 'PROBATNREQ'
	END
	--End of Rev. #1.3

	--ver 1.4 START
	ELSE IF @reqType = @REQUEST_TYPE_ECR --EMPLOYEE CONTRACT RENEWAL REQUISITION
	BEGIN

		IF(@createdModifiedBy = 0)
		BEGIN
		    SELECT @createdModifiedBy = secuser.fnGetDistributionListMember('HR_ADMIN') 
		END

		SELECT @processID = b.ReqTypeProcessID, @reqTypeID = b.ReqTypeID
			FROM secuser.EmployeeContractRenewalWF AS a WITH (NOLOCK) INNER JOIN
				secuser.RequestType AS b WITH (NOLOCK) ON a.ECRReqTypeID = b.ReqTypeID
			WHERE a.ECRNo = @reqTypeNo
	END
	--ver 1.4 END

	--Start of Rev. #1.6
	ELSE IF @reqType = @REQUEST_TYPE_CEA	
	BEGIN

		SELECT	@processID = b.ReqTypeProcessID, 
				@reqTypeID = b.ReqTypeID
		FROM secuser.CEAWF a WITH (NOLOCK) 
			INNER JOIN secuser.RequestType b WITH (NOLOCK) ON a.CEAReqTypeID = b.ReqTypeID
		WHERE a.CEARequisitionNo = @reqTypeNo
	END
	--End of Rev. #1.6

	-- Create Process
	EXEC secuser.pr_CreateProcess @reqType, @reqTypeID, @reqTypeNo, @processID OUTPUT, @statusID, @createdModifiedBy, @retError OUTPUT

	-- Set the status of the first activity to in progress
	IF @retError = @RETURN_OK
	BEGIN

		SELECT @statusID = a.UDCID
		FROM secuser.UserDefinedCode AS a WITH (NOLOCK)
		WHERE a.UDCUDCGID = 16 
			AND a.UDCCode = 'IN'

		UPDATE secuser.TransActivity 
		SET ActStatusID = @statusID
		WHERE ActProcessID = @processID 
			AND ActSeq = 1

		--Start of Rev. #1.5
		IF @reqType = @REQUEST_TYPE_EPA
		BEGIN

			UPDATE secuser.Appraisal
			SET secuser.Appraisal.WorkflowStatusID = 46		--Waiting For Approval
			FROM secuser.Appraisal a WITH (NOLOCK)
				INNER JOIN secuser.EPAWF b WITH (NOLOCK) ON a.EmployeeNo = b.EPAEmpNo AND a.ID = b.EPAAppraisalID
			WHERE b.EPANo = @reqTypeNo
		END 
		--End of Rev. #1.5

		-- Check for errors
		IF @@ERROR <> @RETURN_OK
			SET @retError = @RETURN_ERROR

	END

END


/*	Debug:

	DECLARE	@return_value int,
			@retError int

	SELECT	@retError = 0

	EXEC	@return_value = [secuser].[pr_CreateProcessWorkflow]
			@reqType = 22,
			@reqTypeNo = 20230047,
			@createdModifiedBy = 10003632,
			@retError = @retError OUTPUT

	SELECT	@retError as N'@retError'
	SELECT	'Return Value' = @return_value

*/