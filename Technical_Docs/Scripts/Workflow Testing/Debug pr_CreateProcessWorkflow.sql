

	DECLARE	@return_value int,
			@retError int

	SELECT	@retError = 0

	EXEC	@return_value = [secuser].[pr_CreateProcessWorkflow]
			@reqType = 22,
			@reqTypeNo = 20230047,
			@createdModifiedBy = 10003632,
			@retError = @retError OUTPUT

	SELECT	@retError AS N'@retError'
	SELECT	'Return Value' = @return_value
