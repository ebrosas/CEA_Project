/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F01151
*	Description: Retrieves data from "F01151" table
*
*	Date:			Author:		Rev.#:		Comments:
*	13/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_F01151') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_F01151
	--GO

	--CREATE SYNONYM Projectuser.sy_F01151 FOR JDE_PRODUCTION.PRODDTA.F01151		--Live
	CREATE SYNONYM Projectuser.sy_F01151 FOR JDE_CRP.CRPDTA.F01151				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_F01151

*/

