/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_TransActivity
*	Description: Retrieves data from "secuser.TransActivity" table
*
*	Date:			Author:		Rev.#:		Comments:
*	14/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_TransActivity') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_TransActivity
	--GO

	--CREATE SYNONYM Projectuser.sy_TransActivity FOR JDE_PRODUCTION.secuser.TransActivity		--Live
	CREATE SYNONYM Projectuser.sy_TransActivity FOR JDE_CRP.secuser.TransActivity				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_TransActivity

*/

