/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_UpdateCEAStatus
*	Description: This stored procedure is used to update the CEA requisition workflow status
*
*	Date			Author		Rev. #		Comments:
*	25/09/2023		Ervin		1.0			Created
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_UpdateCEAStatus 
(
	@ceaNo				VARCHAR(50),
	@statusCode			VARCHAR(10),
	@rowsAffected		INT OUTPUT,
	@hasError			BIT OUTPUT,
	@retError			INT OUTPUT,
	@retErrorDesc		VARCHAR(200) OUTPUT
)
AS
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK			INT	= 0,
			@CONST_RETURN_ERROR			INT	= -1,
			@CONST_REQUEST_TYPE_CEA		INT	= 22,
			@CONST_CLOSED_STATUS_CODE	VARCHAR(10) = '123'

	--Initialize variables
	SELECT  @rowsAffected	= 0,
			@hasError		= 0,
			@retError		= @CONST_RETURN_OK,
			@retErrorDesc	= ''

	DECLARE	@statusID				INT = 0,
			@statusHandlingCode		VARCHAR(50) = NULL,
			@currentStatusCode		VARCHAR(10) = '',
			@isCurrentlyAssigned	BIT = 0			
            
	--Get the current request status
	SELECT @currentStatusCode = RTRIM(a.CEAStatusCode)
	FROM Projectuser.sy_CEAWF a WITH (NOLOCK)
	WHERE a.CEARequisitionNo = CAST(@ceaNo AS INT)

	IF EXISTS	
	(
		SELECT 1 FROM Projectuser.sy_CurrentDistributionMember a WITH (NOLOCK)
		WHERE a.CurrentDistMemReqType = @CONST_REQUEST_TYPE_CEA 
			AND a.CurrentDistMemReqTypeNo = CAST(@ceaNo AS INT)
			AND a.CurrentDistMemCurrent = 1
	)
	BEGIN

		--Request is currently assigned to an approver
		SET @isCurrentlyAssigned = 1
    END 

	--Get the status details
	SELECT	@statusID = a.UDCID,
			@statusHandlingCode	= RTRIM(a.UDCSpecialHandlingCode)
	FROM projectuser.UserDefinedCode a WITH (NOLOCK)
	WHERE a.UDCUDCGID = 9
		AND RTRIM(a.UDCCode) = @statusCode

	--IF @currentStatusCode <> @CONST_CLOSED_STATUS_CODE
	IF @isCurrentlyAssigned = 1
	BEGIN
    
		--Change the request status into "05 - Waiting for Approval"
		UPDATE Projectuser.sy_CEAWF
		SET Projectuser.sy_CEAWF.CEAStatusID = @statusID,
			Projectuser.sy_CEAWF.CEAStatusCode = @statusCode,
			Projectuser.sy_CEAWF.CEAStatusHandlingCode = @statusHandlingCode
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER JOIN Projectuser.sy_CEAWF b WITH (NOLOCK) ON CAST(a.RequisitionNo AS INT) = b.CEARequisitionNo
		WHERE RTRIM(a.RequisitionNo) = @ceaNo

		--Get the number of affected rows
		SELECT @rowsAffected = @@rowcount

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@retError = @CONST_RETURN_ERROR,
					@retErrorDesc = 'An error has occured while trying to update the CEA status.',
					@hasError = 1
		END
	END 

END 

/*	Debug:

	DECLARE	@return_value int,
			@rowsAffected int,
			@hasError bit,
			@retError int,
			@retErrorDesc varchar(200)

	EXEC	@return_value = [Projectuser].[Pr_UpdateCEAStatus]
			@ceaNo = N'20230090',
			@statusCode = N'05',
			@rowsAffected = @rowsAffected OUTPUT,
			@hasError = @hasError OUTPUT,
			@retError = @retError OUTPUT,
			@retErrorDesc = @retErrorDesc OUTPUT

	SELECT	@rowsAffected as N'@rowsAffected',
			@hasError as N'@hasError',
			@retError as N'@retError',
			@retErrorDesc as N'@retErrorDesc'

*/