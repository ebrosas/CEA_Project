/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_CEAWF
*	Description: Retrieves data from "F0101" table
*
*	Date:			Author:		Rev.#:		Comments:
*	28/08/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_CEAWF') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_CEAWF
	--GO

	--CREATE SYNONYM Projectuser.sy_CEAWF FOR JDE_PRODUCTION.PRODDTA.F0101		--Live
	CREATE SYNONYM Projectuser.sy_CEAWF FOR JDE_CRP.secuser.CEAWF				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_CEAWF

*/

