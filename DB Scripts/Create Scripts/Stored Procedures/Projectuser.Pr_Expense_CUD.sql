/******************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_Expense_CUD
*	Description: This stored procedure is used to perform CUD operations for "Expense" table
*
*	Date			Author		Revision No.	Comments:
*	07/20/2023		Ervin		1.0				Created
*******************************************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_Expense_CUD
(	
	@actionType				TINYINT,		--(Notes: 1 = Insert, 2 = Update, 3 = Delete)	
	@expenseID				INT OUTPUT, 
	@requisitionID			INT,
	@amount					DECIMAL = 0,
	@fiscalYear				SMALLINT = 0,
	@quarter				VARCHAR(2) = ''
)
AS	
BEGIN

	--Define constants
	DECLARE @CONST_RETURN_OK	INT = 0,
			@CONST_RETURN_ERROR	INT = -1

	--Define variables
	DECLARE @rowsAffected		INT = 0,
			@hasError			BIT = 0,
			@retError			INT = @CONST_RETURN_OK,
			@retErrorDesc		VARCHAR(200) = '',
			@return_value		INT = 0,
			@retErrorMessage	VARCHAR(1000) = ''

	IF @actionType = 1		--Insert record
	BEGIN

		INSERT INTO dbo.Expense
		(
			Amount,
			FiscalYear,
			[Quarter],
			RequisitionId
		)
		SELECT	@amount,
				@fiscalYear,
				@quarter,
				@requisitionID

		--Get the new ID
		SELECT @expenseID = @@IDENTITY 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END

		--Return error information to the caller
		SELECT	@expenseID AS NewIdentityID,
				@rowsAffected AS RowsAffected,
				@hasError AS HasError, 
				@retError AS ErrorCode, 
				@retErrorDesc AS ErrorDescription
	END 

	ELSE IF @actionType = 2		--Update existing record
	BEGIN

		UPDATE dbo.Expense
		SET Amount = @amount,
			FiscalYear = @fiscalYear,
			[Quarter] = @quarter
		WHERE Id = @expenseID

		SELECT @rowsAffected = @@rowcount 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END

		--Return error information to the caller
		SELECT	@rowsAffected AS RowsAffected,
				@hasError AS HasError, 
				@retError AS ErrorCode, 
				@retErrorDesc AS ErrorDescription
	END 

	ELSE IF @actionType = 3		--Delete record
	BEGIN

		--Check existing records
		DELETE FROM dbo.Expense
		WHERE RequisitionID = @requisitionID

		--Get the number of affected records 
		SELECT @rowsAffected = @@rowcount 

		--Checks for error
		IF @@ERROR <> @CONST_RETURN_OK
		BEGIN
				
			SELECT	@hasError = 1,
					@retError = CASE WHEN ERROR_NUMBER() > 0 THEN ERROR_NUMBER() ELSE @CONST_RETURN_ERROR END,
					@retErrorDesc = ERROR_MESSAGE()
		END

		--Return error information to the caller
		SELECT	@rowsAffected AS RowsAffected,
				@hasError AS HasError, 
				@retError AS ErrorCode, 
				@retErrorDesc AS ErrorDescription
	END 

END 

