/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_ActivityAction
*	Description: Retrieves data from "secuser.ActivityAction" table
*
*	Date:			Author:		Rev.#:		Comments:
*	01/11/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_ActivityAction') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_ActivityAction
	--GO

	--CREATE SYNONYM Projectuser.sy_ActivityAction FOR JDE_PRODUCTION.secuser.ActivityAction		--Live
	CREATE SYNONYM Projectuser.sy_ActivityAction FOR JDE_CRP.secuser.ActivityAction					--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_ActivityAction

*/

