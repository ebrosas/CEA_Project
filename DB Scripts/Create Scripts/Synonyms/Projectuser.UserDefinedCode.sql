/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.UserDefinedCode
*	Description: Retrieves data from "GrmHelpdeskDB.Helpdeskuser.UserDefinedCode" table
*
*	Date:			Author:		Rev.#:		Comments:
*	19/03/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.UserDefinedCode') IS NOT NULL
		DROP SYNONYM Projectuser.UserDefinedCode
	GO

	CREATE SYNONYM Projectuser.UserDefinedCode FOR Gen_Purpose.genuser.UserDefinedCode 
	--CREATE SYNONYM Projectuser.UserDefinedCode FOR GrmHelpdeskDB.Helpdeskuser.UserDefinedCode	

GO


/*	Testing

	SELECT * FROM Projectuser.UserDefinedCode

*/

