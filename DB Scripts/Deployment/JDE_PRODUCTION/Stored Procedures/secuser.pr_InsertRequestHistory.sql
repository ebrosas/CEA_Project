/************************************************************************************************************

Stored Procedure Name	:	SecUser.pr_InsertRequestHistory
Description				:	This stored procedure insert history record

							This SP is part of the GARMCO Application Portal Project.

Created By				:	Noel G. Francisco
Date Created			:	18 February 2009

Parameters
	@histReqType		:	The type of requisition
	@histReqNo			:	The leave requisition no.
	@histDesc			:	The description of the history
	@histCreatedBy		:	The employee no. of the user creating the history
	@histCreatedName	:	The username of user creating the history
	@retError			:	The error returned

Revision History:
	1.0					NGF					2009.02.18 15:45
	Created

	1.1					Ervin				2023.09.09 03:00 PM
	Get the employee name from the Employee Master if the value of @histCreatedName parameter is null

************************************************************************************************************/

ALTER PROCEDURE secuser.pr_InsertRequestHistory
(
	@histReqType				INT,
	@histReqNo					INT,
	@histDesc					VARCHAR(300),
	@histCreatedBy				FLOAT,
	@histCreatedName			VARCHAR(50),
	@historyDate				DATETIME,
	@retError					INT OUTPUT
)
AS
BEGIN 

	-- Define error codes
	DECLARE @RETURN_OK int
	DECLARE @RETURN_ERROR int

	SELECT @RETURN_OK			= 0
	SELECT @RETURN_ERROR		= -1

	-- Initialize output
	SELECT @retError = @RETURN_OK

	-- Trim inputs
	SELECT @histDesc		= LTRIM(RTRIM(@histDesc))
	SELECT @histCreatedName	= LTRIM(RTRIM(@histCreatedName))

	--Start of Rev. #1.1
	IF ISNULL(@histCreatedName, '') = '' AND @histCreatedBy > 0
	BEGIN

		SELECT @histCreatedName = RTRIM(a.EmpName) 
		FROM secuser.EmployeeMaster a 
		WHERE a.EmpNo = @histCreatedBy
    END 
	--End of Rev. #1.1

	INSERT INTO SecUser.History
	(
		HistReqNo, 
		HistReqType, 
		HistDesc,
		HistCreatedBy, 
		HistCreatedName, 
		HistCreatedDate
	)
	VALUES
	(
		@histReqNo, 
		@histReqType, 
		@histDesc,
		@histCreatedBy, 
		@histCreatedName, 
		@historyDate
	)

	-- Check error
	IF @@ERROR <> @RETURN_OK
		SELECT @retError = @RETURN_ERROR

END 










