/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_TransParameter
*	Description: Retrieves data from "secuser.TransParameter" table
*
*	Date:			Author:		Rev.#:		Comments:
*	14/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_TransParameter') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_TransParameter
	--GO

	--CREATE SYNONYM Projectuser.sy_TransParameter FOR JDE_PRODUCTION.secuser.TransParameter		--Live
	CREATE SYNONYM Projectuser.sy_TransParameter FOR JDE_CRP.secuser.TransParameter				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_TransParameter

*/

