/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F0006
*	Description: Retrieves data from "F0006" table
*
*	Date:			Author:		Rev.#:		Comments:
*	07/05/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.sy_F0006') IS NOT NULL
		DROP SYNONYM Projectuser.sy_F0006
	GO

	--CREATE SYNONYM Projectuser.sy_F0006 FOR JDE_PRODUCTION.PRODDTA.F0006		--Live
	CREATE SYNONYM Projectuser.sy_F0006 FOR JDE_CRP.CRPDTA.F0006				--Test

GO


/*	Testing

	SELECT TOP 10 * FROM Projectuser.sy_F0006

*/

