/************************************************************************************************************
Revision History:
	2.0					Shoukhat			2015.06.09 09:10
	Modified the code to handle the new Recruitment Requisition

	2.1					Shoukhat			20-Mar-2016 03:30PM
	Modified the code to handle Invoice Requisition

	2.2					Shoukhat			27-Feb-2020 03:30PM
	Modified the code to handle Employee Contract Renewal Requisition

	2.3					Ervin				22-Aug-2023 01:54 PM
	Implemented the workflow for CEA
*************************************************************************************************************/

ALTER PROCEDURE secuser.pr_UpdateServiceRequestStatusByCode
(
	@reqType				INT,
	@reqTypeNo				INT,
	@reqStatusCode			VARCHAR(10),
	@reqModifiedBy			INT,
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
	DECLARE @REQUEST_TYPE_SIR int
	DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT		--ver 2.1
	DECLARE @REQUEST_TYPE_ECR INT		--ver 2.2
	DECLARE @REQUEST_TYPE_CEA INT		--ver 2.3

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19	--ver 2.1
	SET @REQUEST_TYPE_ECR		= 20	--ver 2.2
	SET @REQUEST_TYPE_CEA		= 22	--ver 2.3


	-- Declare necessary variables
	DECLARE @reqStatus INT
    DECLARE @reqStatusDesc VARCHAR(150)
	DECLARE @reqStatusHandlingCode VARCHAR(50)
	DECLARE @reqModifiedName varchar(50)
	SET @reqModifiedName = ''

	-- Retrieve the name of the modifier
	SELECT @reqModifiedName = a.EmpName
		FROM secuser.EmployeeMaster AS a
		WHERE a.EmpNo = @reqModifiedBy

	-- Retrieve Status ID
	SELECT	@reqStatus = a.UDCID, 
			@reqStatusDesc = RTRIM(a.UDCDesc1),
			@reqStatusHandlingCode = RTRIM(a.UDCSpecialHandlingCode) 
	FROM secuser.UserDefinedCode a WITH (NOLOCK) 
	WHERE a.UDCUDCGID = 9 
		AND a.UDCCode = @reqStatusCode

	-- Check the Request Type
	IF @reqType = @REQUEST_TYPE_LEAVE
		UPDATE secuser.LeaveRequisitionWF SET LeaveReqStatusID = @reqStatus, LeaveReqStatusCode = @reqStatusCode,
				LeaveModifiedBy = @reqModifiedBy, LeaveModifiedName = @reqModifiedName,
				LeaveModifiedEmail = '', LeaveModifiedDate = GETDATE()
			WHERE LeaveNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_PR
		UPDATE secuser.PurchaseRequisitionWF SET PRReqStatusID = @reqStatus, PRReqStatusCode = @reqStatusCode,
				PRModifiedBy = @reqModifiedBy, PRModifiedName = @reqModifiedName,
				PRModifiedEmail = '', PRModifiedDate = GETDATE()
			WHERE PRDocNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_TSR
		UPDATE secuser.TSRWF SET TSRReqStatusID = @reqStatus, TSRReqStatusCode = @reqStatusCode,
				TSRModifiedBy = @reqModifiedBy, TSRModifiedName = @reqModifiedName,
				TSRModifiedEmail = '', TSRModifiedDate = GETDATE()
			WHERE TSRNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_PAF
		UPDATE secuser.PAFWF SET PAFReqStatusID = @reqStatus, PAFReqStatusCode = @reqStatusCode,
				PAFModifiedBy = @reqModifiedBy, PAFModifiedName = @reqModifiedName,
				PAFModifiedEmail = '', PAFModifiedDate = GETDATE()
			WHERE PAFNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_EPA
		UPDATE secuser.EPAWF SET EPAReqStatusID = @reqStatus, EPAReqStatusCode = @reqStatusCode,
				EPAModifiedBy = @reqModifiedBy, EPAModifiedName = @reqModifiedName,
				EPAModifiedEmail = '', EPAModifiedDate = GETDATE()
			WHERE EPANo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
		UPDATE secuser.ClearanceFormWF SET ClrFormStatusID = @reqStatus, ClrFormStatusCode = @reqStatusCode,
				ClrFormModifiedBy = @reqModifiedBy, ClrFormModifiedName = @reqModifiedName,
				ClrFormModifiedEmail = '',  ClrFormModifiedDate= GETDATE()
			WHERE ClrFormNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_SIR
		UPDATE secuser.SIRWF SET SIRReqStatusID = @reqStatus, SIRReqStatusCode = @reqStatusCode,
				SIRModifiedBy = @reqModifiedBy, SIRModifiedName = @reqModifiedName,
				SIRModifiedEmail = '', SIRModifiedDate = GETDATE()
			WHERE SIRNo = @reqTypeNo

	-- ver 2.0 Start
	ELSE IF @reqType = @REQUEST_TYPE_RR
		-- Update the workflow table
		UPDATE secuser.RecruitmentRequisitionWF 
			SET RRReqStatusID = @reqStatus, RRReqStatusCode = @reqStatusCode,
				RRModifiedBy = @reqModifiedBy, RRModifiedName =  @reqModifiedName, 
				RRModifiedEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy), 
				RRModifiedDate = GETDATE()
		WHERE RRNo = @reqTypeNo
	-- ver 2.0 End

	-- ver 2.1 Start
	ELSE IF @reqType = @REQUEST_TYPE_IR
	BEGIN
		-- Update the main table
		UPDATE secuser.InvoiceRequisition
			SET StatusID = @reqStatus, StatusCode = @reqStatusCode, StatusDesc = @reqStatusDesc 
		WHERE InvoiceRequisitionNo = @reqTypeNo

		-- Update the workflow table
		UPDATE secuser.InvoiceRequisitionWF 
			SET IRStatusID = @reqStatus, IRStatusCode = @reqStatusCode,
				IRLastModifiedByEmpNo = @reqModifiedBy, IRLastModifiedByEmpName =  @reqModifiedName, 
				IRLastModifiedByEmpEmail = (SELECT ISNULL(EmpEmail, '') FROM secuser.EmployeeMaster WHERE EmpNo = @reqModifiedBy), 
				IRLastModifiedDate = GETDATE()
		WHERE IRNo = @reqTypeNo
	END	
	-- ver 2.1 End

	
	ELSE IF @reqType = @REQUEST_TYPE_ECR -- ver 2.2 Start
		-- Update the workflow table
		UPDATE secuser.EmployeeContractRenewalWF 
			SET ECRStatusID = @reqStatus, ECRStatusCode = @reqStatusCode,
				ECRLastModifiedBy = @reqModifiedBy, ECRLastModifiedDate = GETDATE()
		WHERE ECRNo = @reqTypeNo -- ver 2.2 End

	--ver 2.3 Start
	ELSE IF @reqType = @REQUEST_TYPE_CEA 
	BEGIN
    
		-- Update the workflow table
		UPDATE secuser.CEAWF
		SET CEAStatusID = @reqStatus, 
			CEAStatusCode = @reqStatusCode, 
			CEAStatusHandlingCode = @reqStatusHandlingCode,
			CEAModifiedBy = @reqModifiedBy, 
			CEAModifiedDate = GETDATE()
		WHERE CEARequisitionNo = @reqTypeNo
	END 
	-- ver 2.3 End
	
	-- Check for errors
	IF @@ERROR <> @RETURN_OK
		SET @retError = @RETURN_ERROR

END



