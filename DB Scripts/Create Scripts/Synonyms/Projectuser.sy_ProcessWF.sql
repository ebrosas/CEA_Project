/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_ProcessWF
*	Description: Retrieves data from "secuser.ProcessWF" table
*
*	Date:			Author:		Rev.#:		Comments:
*	14/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_ProcessWF') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_ProcessWF
	--GO

	--CREATE SYNONYM Projectuser.sy_ProcessWF FOR JDE_PRODUCTION.secuser.ProcessWF		--Live
	CREATE SYNONYM Projectuser.sy_ProcessWF FOR JDE_CRP.secuser.ProcessWF				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_ProcessWF

*/

