/*********************************************************************************
*	Revision RequestType
*
*	Name: Projectuser.sy_RequestType
*	Description: Retrieves data from "F0101" table
*
*	Date:			Author:		Rev.#:		Comments:
*	29/08/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_RequestType') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_RequestType
	--GO

	--CREATE SYNONYM Projectuser.sy_RequestType FOR JDE_PRODUCTION.secuser.RequestType		--Live
	CREATE SYNONYM Projectuser.sy_RequestType FOR JDE_CRP.secuser.RequestType				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_RequestType

*/

