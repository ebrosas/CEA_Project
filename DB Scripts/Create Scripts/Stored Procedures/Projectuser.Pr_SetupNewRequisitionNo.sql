/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_Requisition_CUD
*	Description: This stored procedure performs create, update, and delete operations against "Requisition" table
*
*	Date			Author		Rev. #		Comments:
*	13/07/2023		Ervin		1.0			Created
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_SetupNewRequisitionNo
(	
	@newRequisitionNo NUMERIC(8) OUTPUT
)
AS 
BEGIN


	DECLARE @configCurrentYear			INT = 0,
			@currentYear				INT = 0,
			@currentRequisitionIncr		INT = 0,
			@newRequisitionTmp			VARCHAR(8) = '',
			@requisitionStartingNo		INT = 0

	--Get current year
	SELECT @currentYear = YEAR(GETDATE())

	--Check for config year
	SELECT @configCurrentYear = a.CurrentYear 
	FROM dbo.AppConfiguration a WITH (NOLOCK)
		
	--Check if the years are matching, if the current year is greater, then update config
	IF @currentYear > @configCurrentYear 
	BEGIN
    
		UPDATE dbo.AppConfiguration
		SET CurrentYear = @currentYear,	
			CurrentRequisitionNo = @requisitionStartingNo

		SET @configCurrentYear = @currentYear
	END

	--Get last created Requisition incrementor for the year
	SELECT @currentRequisitionIncr = a.CurrentRequisitionNo 
	FROM dbo.AppConfiguration a WITH (NOLOCK)
	WHERE a.CurrentYear = @configCurrentYear

	--Create the new RequisitionNo
	SELECT	@currentRequisitionIncr =  @currentRequisitionIncr + 1,
			@newRequisitionTmp = convert(varchar, @configCurrentYear) + Projectuser.lpad(convert(varchar, @currentRequisitionIncr),4,'0'),
			@newRequisitionNo = convert(numeric, @newRequisitionTmp) 
	
	--Update the config table
	UPDATE dbo.AppConfiguration
	SET CurrentRequisitionNo = @currentRequisitionIncr
	WHERE CurrentYear = @configCurrentYear

	--Output the new requisition no
	SELECT @newRequisitionNo = CONVERT(numeric, @newRequisitionTmp) 

END 

/*	Debug:

	DECLARE	@return_value int,
			@newRequisitionNo numeric(8, 0)

	EXEC	@return_value = [Projectuser].[Pr_SetupNewRequisitionNo]
			@newRequisitionNo = @newRequisitionNo OUTPUT

	SELECT	@newRequisitionNo as N'@newRequisitionNo'

*/