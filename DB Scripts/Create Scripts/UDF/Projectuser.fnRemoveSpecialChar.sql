/*****************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnRemoveSpecialChar
*	Description: This function is used to remove the apostrophe character in the string input
*
*	Date:			Author:		Rev.#:		Comments:
*	23/03/2023		Ervin		1.0			Created
*
******************************************************************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnRemoveSpecialChar
(
	@strInput	VARCHAR(500)
)
RETURNS VARCHAR(500)
AS
BEGIN
 
	WHILE PATINDEX('%&%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%&%', @strInput),1,'')

	WHILE PATINDEX('%#%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%#%', @strInput),1,'')

	WHILE PATINDEX('%/%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%/%', @strInput),1,'')

	WHILE PATINDEX('%\%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%\%', @strInput),1,'')

	WHILE PATINDEX('%<%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%<%', @strInput),1,'')

	WHILE PATINDEX('%>%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%>%', @strInput),1,'')

	WHILE PATINDEX('%(%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%(%', @strInput),1,'')

	WHILE PATINDEX('%)%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%)%', @strInput),1,'')

	WHILE PATINDEX('%.%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%.%', @strInput),1,'')

	WHILE PATINDEX('%-%', @strInput) > 0
		SET @strInput = Stuff(@strInput,PATINDEX('%-%', @strInput),1,'')

	RETURN @strInput

END


/*	Testing:

	SELECT Projectuser.fnRemoveSpecialChar('6100 - Sales & Marketing-Subsidiaries')

*/