/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F0911
*	Description: Retrieves data from "F0911" table
*
*	Date:			Author:		Rev.#:		Comments:
*	27/04/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.sy_F0911') IS NOT NULL
		DROP SYNONYM Projectuser.sy_F0911
	GO

	CREATE SYNONYM Projectuser.sy_F0911 FOR JDE_PRODUCTION.PRODDTA.F0911		--Live
	--CREATE SYNONYM Projectuser.sy_F0911 FOR JDE_CRP.CRPDTA.F0911				--Test

GO


/*	Testing

	SELECT TOP 10 * FROM Projectuser.sy_F0911

*/

