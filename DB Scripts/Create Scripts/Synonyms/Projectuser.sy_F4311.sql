/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F4311
*	Description: Retrieves data from "F4311" table
*
*	Date:			Author:		Rev.#:		Comments:
*	27/04/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.sy_F4311') IS NOT NULL
		DROP SYNONYM Projectuser.sy_F4311
	GO

	--CREATE SYNONYM Projectuser.sy_F4311 FOR JDE_PRODUCTION.PRODDTA.F4311		--Live
	CREATE SYNONYM Projectuser.sy_F4311 FOR JDE_CRP.CRPDTA.F4311				--Test

GO


/*	Testing

	SELECT TOP 10 * FROM Projectuser.sy_F4311

*/

