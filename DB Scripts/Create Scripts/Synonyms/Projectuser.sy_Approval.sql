/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_Approval
*	Description: Retrieves data from "secuser.Approval" table
*
*	Date:			Author:		Rev.#:		Comments:
*	14/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_Approval') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_Approval
	--GO

	--CREATE SYNONYM Projectuser.sy_Approval FOR JDE_PRODUCTION.secuser.Approval		--Live
	CREATE SYNONYM Projectuser.sy_Approval FOR JDE_CRP.secuser.Approval				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_Approval

*/

