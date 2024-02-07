/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F00092
*	Description: Retrieves data from "F00092" table
*
*	Date:			Author:		Rev.#:		Comments:
*	13/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_F00092') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_F00092
	--GO

	--CREATE SYNONYM Projectuser.sy_F00092 FOR JDE_PRODUCTION.PRODDTA.F00092		--Live
	CREATE SYNONYM Projectuser.sy_F00092 FOR JDE_CRP.CRPDTA.F00092				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_F00092

*/

