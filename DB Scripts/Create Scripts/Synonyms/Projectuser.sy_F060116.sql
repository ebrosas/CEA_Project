/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F060116
*	Description: Retrieves data from "F060116" table
*
*	Date:			Author:		Rev.#:		Comments:
*	13/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_F060116') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_F060116
	--GO

	--CREATE SYNONYM Projectuser.sy_F060116 FOR JDE_PRODUCTION.PRODDTA.F060116		--Live
	CREATE SYNONYM Projectuser.sy_F060116 FOR JDE_CRP.CRPDTA.F060116				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_F060116

*/

