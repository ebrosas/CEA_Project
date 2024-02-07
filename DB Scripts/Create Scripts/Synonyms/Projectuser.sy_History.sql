/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_History
*	Description: Retrieves data from "F0101" table
*
*	Date:			Author:		Rev.#:		Comments:
*	28/08/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_History') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_History
	--GO

	--CREATE SYNONYM Projectuser.sy_History FOR JDE_PRODUCTION.PRODDTA.F0101		--Live
	CREATE SYNONYM Projectuser.sy_History FOR JDE_CRP.secuser.History				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_History

*/

