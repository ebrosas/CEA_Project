/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.UserDefinedCodeGroup
*	Description: Retrieves data from "GrmHelpdeskDB.Helpdeskuser.UserDefinedCodeGroup" table
*
*	Date:			Author:		Rev.#:		Comments:
*	19/03/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.UserDefinedCodeGroup') IS NOT NULL
		DROP SYNONYM Projectuser.UserDefinedCodeGroup
	GO

	CREATE SYNONYM Projectuser.UserDefinedCodeGroup FOR Gen_Purpose.genuser.UserDefinedCodeGroup
	--CREATE SYNONYM Projectuser.UserDefinedCodeGroup FOR GrmHelpdeskDB.Helpdeskuser.UserDefinedCodeGroup 

GO


/*	Testing

	SELECT * FROM Projectuser.UserDefinedCodeGroup

*/

