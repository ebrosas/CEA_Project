/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F0101
*	Description: Retrieves data from "F0101" table
*
*	Date:			Author:		Rev.#:		Comments:
*	13/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_F0101') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_F0101
	--GO

	--CREATE SYNONYM Projectuser.sy_F0101 FOR JDE_PRODUCTION.PRODDTA.F0101		--Live
	CREATE SYNONYM Projectuser.sy_F0101 FOR JDE_CRP.CRPDTA.F0101				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_F0101

*/

