DECLARE	@return_value int,
		@processID int,
		@retError int

SELECT	@processID = 344
SELECT	@retError = 0

EXEC	@return_value = [secuser].[pr_CreateProcess]
		@reqType = 22,
		@reqTypeID = 60,
		@reqTypeNo = 20230047,
		@processID = @processID OUTPUT,
		@statusID = 106,
		@createdModifiedBy = 10003632,
		@retError = @retError OUTPUT

SELECT	@processID as N'@processID',
		@retError as N'@retError'

SELECT	'Return Value' = @return_value

GO
