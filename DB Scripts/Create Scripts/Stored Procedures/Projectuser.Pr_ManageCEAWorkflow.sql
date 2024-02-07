/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_ManageCEAWorkflow
*	Description: This stored procedure performs create, retrieve, update, and delete operations in "secuser.CEAWF" table
*
*	Date			Author		Rev. #		Comments:
*	28/08/2023		Ervin		1.0			Created
*	02/11/2023		Ervin		1.1			Added logic to check if CEO and Chairman approval is required in the workflow
*		
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_ManageCEAWorkflow 
(
	@actionType				TINYINT = 1,			--(Notes: 1 = Submit request, 2 = Validate request, 3 = Approve request, 4 = Reject request, 5 = Cancel request, 6 = Close request)
	@requisitionNo			VARCHAR(50),
	@statusCode				VARCHAR(10),
	@isDraft				BIT,	
	@userEmpNo				INT,
	@userEmpName			VARCHAR(100),	
	@userID					VARCHAR(50),
	@rowsAffected			INT OUTPUT,
	@hasError				BIT OUTPUT,
	@retError				INT OUTPUT,
	@retErrorDesc			VARCHAR(200) OUTPUT,
	@approverRemarks		VARCHAR(1000) = '',	
	@reassignEmpNo			INT = 0
)
AS
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK					INT	= 0,
			@CONST_RETURN_ERROR					INT	= -1,
			@CONST_ERROR_WF_EXIST				INT	= 1001,
			@CONST_REQUEST_TYPE_CEA				INT	= 22,
			@CONST_AMOUNT_THRESHOLD_CEO			DECIMAL(18,3) = 20000,
			@CONST_AMOUNT_THRESHOLD_CHAIRMAIN	DECIMAL(18,3) = 100000

	--Initialize variables
	SELECT  @rowsAffected	= 0,
			@hasError		= 0,
			@retError		= @CONST_RETURN_OK,
			@retErrorDesc	= ''

	--Define application logic variables
	DECLARE	@projectNo					VARCHAR(12) = '',
			@reqTypeID					INT = 0,
			@reqTypeName				VARCHAR(50) = 'CEA/MRE Requisition',
			@reqTypeCode				VARCHAR(10) = 'CEAREQ',
			@ceaDescription				VARCHAR(40) = '',
			@costCenter					VARCHAR(12) = '',
			@originatorNo				INT = 0,
			@originatorName				VARCHAR(50) = '',
			@empNo						INT = 0,
			@empName					VARCHAR(50) = '',
			@empEmail					VARCHAR(50) = '',
			@totalAmount				DECIMAL(18,3) = 0, 
			@isBudgeted					BIT = 0,		
			@requireItemApp				BIT = 0,
			@itemCode					VARCHAR(10) = '',
			@isUnderGMO					BIT = 0,
			@rejectEmailGroup			VARCHAR(300) = '',			
			@statusID					INT = 0,			
			@statusDesc					VARCHAR(50) = '',
			@statusHandlingCode			VARCHAR(50) = '',
			@userEmpEmail				VARCHAR(50)	= '',
			@isCEORequired				BIT = 0,
			@isChairmanRequired			BIT = 0

	--Get the CEA request type id
	SELECT @reqTypeID = a.ReqTypeID
	FROM Projectuser.sy_RequestType a WITH (NOLOCK)
	WHERE RTRIM(a.ReqTypeCode) = 'CEAREQ'

	--Get the user email address
	SELECT @userEmpEmail = RTRIM(a.EmpEmail)
	FROM Projectuser.Vw_MasterEmployeeJDE a WITH (NOLOCK)
	WHERE a.EmpNo = @userEmpNo

	--Get the request status details
	SELECT	@statusID = a.UDCID,
			@statusDesc = RTRIM(a.UDCDesc1),
			@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
	FROM Projectuser.UserDefinedCode a WITH (NOLOCK) 
	WHERE a.UDCUDCGID = 9 
		AND RTRIM(a.UDCCOde) = RTRIM(@statusCode)

	IF @actionType = 1
	BEGIN

		--Set the cost center equal to the cost center of the Originator if the person belongs to the engineering department
		SELECT @costCenter = RTRIM(b.CostCenter)
		FROM dbo.Requisition a WITH (NOLOCK) 
			INNER JOIN dbo.ApplicationUser b WITH (NOLOCK) ON a.OriginatorEmpNo = b.EmployeeNo
		WHERE RTRIM(a.RequisitionNo) = @requisitionNo
			AND RTRIM(b.CostCenter) IN ('3250', '5200', '5300', '5400')

		IF ISNULL(@costCenter, '') <> ''
		BEGIN

			--Set the flag that enables the approval of the GMO
			SET @isUnderGMO = 1
        END
		ELSE 
		BEGIN
			
			--Set the cost center equals to the cost center defined in the Project details
			SELECT @costCenter = RTRIM(b.CostCenter)
			FROM dbo.Requisition a WITH (NOLOCK)
				INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
			WHERE RTRIM(a.RequisitionNo) = @requisitionNo
        END 

		--Get the CEA details
		SELECT	@projectNo = RTRIM(a.ProjectNo),
				@ceaDescription = RTRIM(a.RequisitionDescription), 
				@costCenter = RTRIM(b.CostCenter),
				@originatorNo = a.OriginatorEmpNo,
				@originatorName = RTRIM(c.EmpName),
				@empNo = CASE WHEN @isUnderGMO = 1 THEN a.OriginatorEmpNo ELSE a.CreatedByEmpNo END,
				@empName = CASE WHEN @isUnderGMO = 1 THEN RTRIM(c.EmpName) ELSE RTRIM(d.EmpName) END,
				@empEmail = CASE WHEN @isUnderGMO = 1 THEN RTRIM(c.EmpEmail) ELSE d.EmpEmail END,
				@totalAmount = a.RequestedAmt,
				@isBudgeted = CASE WHEN RTRIM(ISNULL(b.ProjectType, '')) = 'Budgeted' THEN 1 ELSE 0 END,
				@requireItemApp = CASE WHEN ISNULL(a.CategoryCode1, '') <> '' THEN 1 ELSE 0 END,
				@itemCode = RTRIM(a.CategoryCode1)
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
			INNER JOIN Projectuser.Vw_MasterEmployeeJDE c WITH (NOLOCK) ON a.OriginatorEmpNo = c.EmpNo
			INNER JOIN Projectuser.Vw_MasterEmployeeJDE d WITH (NOLOCK) ON a.CreatedByEmpNo = d.EmpNo
		WHERE RTRIM(a.RequisitionNo) = @requisitionNo

		--Determine if CEO's approval is required
		IF @totalAmount > @CONST_AMOUNT_THRESHOLD_CEO
			SET @isCEORequired = 1

		--Determine if CEO's approval is required
		IF @totalAmount > @CONST_AMOUNT_THRESHOLD_CHAIRMAIN
			SET @isChairmanRequired = 1

		IF EXISTS
		(
			SELECT 1 FROM Projectuser.sy_CEAWF a WITH (NOLOCK)
			WHERE a.CEARequisitionNo = @requisitionNo
				AND a.CEAReqTypeID = @reqTypeID
				AND RTRIM(a.CEACostCenter) = @costCenter
				AND a.CEAOriginatorNo = @originatorNo
		)
		BEGIN 

			SELECT	@hasError		= 1,
					@retError		= @CONST_ERROR_WF_EXIST,
					@retErrorDesc	= 'The workflow instance for this CEA requisition already exist!'

			--Delete existing record
			--DELETE FROM Projectuser.sy_CEAWF
			--WHERE CEARequisitionNo = @requisitionNo
			--	AND CEAReqTypeID = @reqTypeID
			--	AND RTRIM(CEACostCenter) = @costCenter
			--	AND CEAOriginatorNo = @originatorNo
		END 
		ELSE 
		BEGIN 

			--Populate the workflow transaction record
			INSERT INTO Projectuser.sy_CEAWF
			(
				CEARequisitionNo,
				CEAProjectNo,
				CEAReqTypeID,
				CEAReqTypeName,
				CEAReqTypeCode,		
				CEAEmpNo,
				CEAEmpName,
				CEAEmpEmail,
				CEADescription,
				CEACostCenter,
				CEAOriginatorNo,
				CEAOriginatorName,
				CEATotalAmount, 
				CEAIsBudgeted,		
				CEARequireItemApp,
				CEAItemCatCode,
				CEAIsUnderGMO,
				CEAIsDraft,
				CEAStatusID,
				CEAStatusCode,
				CEAStatusHandlingCode,
				CEARetError,
				CEACreatedDate,		
				CEACreatedBy,
				CEACreatedName,	
				CEACreatedUserID,		
				CEACreatedEmail,
				CEARequireCEOApv,
				CEARequireChairmanApv
			)
			VALUES
			(
				@requisitionNo,
				@projectNo,
				@reqTypeID,
				@reqTypeName,
				@reqTypeCode,
				@empNo,
				@empName,
				@empEmail,
				@ceaDescription,
				@costCenter,
				@originatorNo,
				@originatorName,
				@totalAmount,
				@isBudgeted,
				@requireItemApp,
				@itemCode,
				@isUnderGMO,
				@isDraft,
				@statusID,
				@statusCode,
				@statusHandlingCode,
				@retError,
				GETDATE(),
				@userEmpNo,
				@userEmpName,
				@userID,
				@userEmpEmail,
				@isCEORequired,
				@isChairmanRequired			
			)

			--Get the number of affected rows
			SELECT @rowsAffected = @@rowcount

			--Checks for error
			IF @@ERROR <> @CONST_RETURN_OK
			BEGIN
				
				SELECT	@retError = @CONST_RETURN_ERROR,
						@hasError = 1
			END
			ELSE BEGIN

				--Set the flag that determines using the workflow
				UPDATE dbo.Requisition
				SET UseNewWF = 1
				WHERE RTRIM(RequisitionNo) = @requisitionNo

				--Insert rounte history record
				IF	ISNULL(@statusDesc, '') <> '' AND 
					ISNULL(@statusHandlingCode, '') <> ''
				BEGIN
                
					--Insert routine history record
					INSERT INTO Projectuser.sy_History
					(
						HistReqType,
						HistReqNo,
						HistDesc,
						HistCreatedBy,
						HistCreatedName,
						HistCreatedDate
					)
					SELECT	@CONST_REQUEST_TYPE_CEA,	
							@requisitionNo,
							RTRIM(@statusHandlingCode) + ' - ' + RTRIM(@statusDesc),
							@userEmpNo,
							CASE WHEN @userEmpNo > 0 THEN @userEmpName ELSE @userID END,
							GETDATE()		
				END 
			END 	
		END 
	END 
END 

/*	Debug:

PARAMETERS:
	@actionType				TINYINT = 1,			--(Notes: 1 = Submit request, 2 = Validate request, 3 = Approve request, 4 = Reject request, 5 = Cancel request, 6 = Close request)
	@requisitionNo			VARCHAR(50),
	@statusCode				VARCHAR(10),
	@isDraft				BIT,	
	@userEmpNo				INT,
	@userEmpName			VARCHAR(100),	
	@userID					VARCHAR(50),
	@rowsAffected			INT OUTPUT,
	@hasError				BIT OUTPUT,
	@retError				INT OUTPUT,
	@retErrorDesc			VARCHAR(200) OUTPUT,
	@approverRemarks		VARCHAR(1000) = '',	
	@reassignEmpNo			INT = 0

	DECLARE	@return_value int,
			@rowsAffected int,
			@hasError bit,
			@retError int,
			@retErrorDesc varchar(200)

	SELECT	@retError = 0

	EXEC	@return_value = Projectuser.Pr_ManageCEAWorkflow
			@actionType = 1,
			@requisitionNo = N'20230048',
			@statusCode = N'01',
			@isDraft = 0,
			@userEmpNo = 10003632,
			@userEmpName = N'ERVIN BROSAS',
			@userID = N'ervin',
			@rowsAffected = @rowsAffected OUTPUT,
			@hasError = @hasError OUTPUT,
			@retError = @retError OUTPUT,
			@retErrorDesc = @retErrorDesc OUTPUT,
			@approverRemarks = NULL,
			@reassignEmpNo = NULL

	SELECT	@rowsAffected as N'@rowsAffected',
			@hasError as N'@hasError',
			@retError as N'@retError',
			@retErrorDesc as N'@retErrorDesc'

*/