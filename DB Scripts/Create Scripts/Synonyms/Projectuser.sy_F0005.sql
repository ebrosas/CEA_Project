/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F0005
*	Description: Retrieves data from "F0005" table
*
*	Date:			Author:		Rev.#:		Comments:
*	13/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_F0005') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_F0005
	--GO

	--CREATE SYNONYM Projectuser.sy_F0005 FOR JDE_PRODUCTION.PRODCTL.F0005		--Live
	CREATE SYNONYM Projectuser.sy_F0005 FOR JDE_CRP.CRPCTL.F0005				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_F0005

*/

