/************************************************************************************************************

Stored Procedure Name	:	secuser.pr_UpdateServiceRequestInstanceID
Description				:	This stored procedure updates the Instance ID of the request.
							The instance ID is used to reference in the Workflow Process.

							This SP is part of the GARMCO Application Portal Project.

Created By				:	Noel G. Francisco
Date Created			:	08 January 2008

Parameters
	@reqType			:	The Request Type, Expense (1) or Travel (2)
	@reqTypeNo			:	The Reference Request No
	@reqTypenstanceID	:	The instance ID retrieved from Workflow Process

	@retError			:	The return code, 0 is successful otherwise -1

Revision History:
	1.0					NGF					2008.01.08 08:34
	Created

	1.1					NGF					2008.08.13 07:58
	Added the Cash Advance Request functionality

	1.2					NGF					2009.08.30 08:38
	Added the Personal Action Form functionality

	1.3					NGF					2009.11.08 09:13
	Added the Employee Performance Appraisal form

	1.4					NGF					2011.10.02 10:53
	Added necessary execution for TSR

	1.5					NGF					2012.06.13 09:32
	Added the Clearance Form

	1.6					NGF					2013.08.28 08:58
	Added SIR Request Type

	1.7					SAK					2015.04.12 13:58
	Added Recruitment Request Type

	1.8					SAK					10-Mar-2016 1:09PM
	Added Supplier Invoice Request Type

	1.9					EOB					29-Jul-2019 01:25PM
    Implemented the Probationary Assessment Request

	2.0					SAK					25-Feb-2020 3:00PM
	Added Employee Contract Renewal Request Type

	2.1					Ervin				22-Aug-2023 01:54 PM
	Implemented the workflow for CEA
************************************************************************************************************/

ALTER PROCEDURE secuser.pr_UpdateServiceRequestInstanceID
(
	@reqType			INT,
	@reqTypeNo			INT,
	@reqTypenstanceID	VARCHAR(255),
	@retError			INT OUTPUT
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
	DECLARE @REQUEST_TYPE_SIR int
	DECLARE @REQUEST_TYPE_RR INT
    DECLARE @REQUEST_TYPE_IR INT
    DECLARE @REQUEST_TYPE_PROBY INT		--Rev. #1.9
	DECLARE @REQUEST_TYPE_ECR INT		--Rev. #2.0
	DECLARE @REQUEST_TYPE_CEA INT		--Rev. #2.1

	SET @REQUEST_TYPE_LEAVE		= 4
	SET @REQUEST_TYPE_PR		= 5
	SET @REQUEST_TYPE_TSR		= 6
	SET @REQUEST_TYPE_PAF		= 7
	SET @REQUEST_TYPE_EPA		= 11
	SET @REQUEST_TYPE_CLRFRM	= 16
	SET @REQUEST_TYPE_SIR		= 17
	SET @REQUEST_TYPE_RR		= 18
	SET @REQUEST_TYPE_IR		= 19
	SET @REQUEST_TYPE_ECR		= 20	--ver 2.0
	SET @REQUEST_TYPE_PROBY		= 21	--Rev. #1.9
	SET @REQUEST_TYPE_CEA		= 22	--Rev. #2.1

	SET XACT_ABORT ON

	-- Check the Request Type
	IF @reqType = @REQUEST_TYPE_LEAVE
		UPDATE secuser.LeaveRequisitionWF SET LeaveInstanceID = @reqTypenstanceID
			WHERE LeaveNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_PR
		UPDATE secuser.PurchaseRequisitionWF SET PRInstanceID = @reqTypenstanceID
			WHERE PRDocNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_TSR
		UPDATE secuser.TSRWF SET TSRInstanceID = @reqTypenstanceID
			WHERE TSRNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_PAF
		UPDATE secuser.PAFWF SET PAFInstanceID = @reqTypenstanceID
			WHERE PAFNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_EPA
		UPDATE secuser.EPAWF SET EPAInstanceID = @reqTypenstanceID
			WHERE EPANo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_CLRFRM
		UPDATE secuser.ClearanceFormWF SET ClrFormInstanceID  = @reqTypenstanceID
			WHERE ClrFormNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_SIR
		UPDATE secuser.SIRWF SET SIRInstanceID = @reqTypenstanceID
			WHERE SIRNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_RR
		UPDATE secuser.RecruitmentRequisitionWF SET RRInstanceID = @reqTypenstanceID
			WHERE RRNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_IR
		UPDATE secuser.InvoiceRequisitionWF SET IRInstanceID = @reqTypenstanceID
			WHERE IRNo = @reqTypeNo

	ELSE IF @reqType = @REQUEST_TYPE_ECR --ver 2.0
		UPDATE secuser.EmployeeContractRenewalWF  SET ECRInstanceID = @reqTypenstanceID
			WHERE ECRNo = @reqTypeNo

	--Start of Rev. #1.9
	ELSE IF @reqType = @REQUEST_TYPE_PROBY
		UPDATE secuser.ProbationaryRequisitionWF SET PARWFInstanceID = @reqTypenstanceID
			WHERE PARRequisitionNo = @reqTypeNo
	--End of Rev. #1.9

	--Rev. #2.1 Start
	ELSE IF @reqType = @REQUEST_TYPE_CEA 
	BEGIN
    
		DECLARE @currentStatusCode	VARCHAR(10) = NULL,
				@statusID			INT = NULL,
				@statusCode			VARCHAR(10) = NULL,
				@statusHandlingCode	VARCHAR(50) = NULL 

		--Get the current CEA workflow status
		SELECT @currentStatusCode = RTRIM(a.CEAStatusCode)
		FROM secuser.CEAWF a WITH (NOLOCK)
		WHERE CEARequisitionNo = @reqTypeNo 

		--Get the "Waiting For Approval" status details
		SELECT	@statusID = a.UDCID,
				@statusCode = RTRIM(a.UDCCode),
				@statusHandlingCode = RTRIM(a.UDCSpecialHandlingCode)
		FROM secuser.UserDefinedCode a WITH (NOLOCK) 
		WHERE a.UDCUDCGID = 9 
			AND RTRIM(a.UDCCOde) = '05'

		-- Update the workflow instance id 
		UPDATE secuser.CEAWF
		SET CEAWFInstanceID = @reqTypenstanceID,
			CEAModifiedDate = GETDATE()
		WHERE CEARequisitionNo = @reqTypeNo

		IF @currentStatusCode = '02'
		BEGIN
        
			--Update the workflow status to "Waiting for Approval"
			UPDATE secuser.CEAWF
			SET CEAStatusID = @statusID,
				CEAStatusCode = @statusCode,
				CEAStatusHandlingCode = @statusHandlingCode
			WHERE CEARequisitionNo = @reqTypeNo
		END 

	END 
	--Rev. #2.1 End

	-- Check error
	IF @@ERROR <> @RETURN_OK
		SET @retError = @RETURN_ERROR

	SET XACT_ABORT OFF

END


