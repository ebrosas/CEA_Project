/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_Master_CurrentLeaves
*	Description: Retrieves data from "Master_CurrentLeaves" table
*
*	Date:			Author:		Rev.#:		Comments:
*	10/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_Master_CurrentLeaves') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_Master_CurrentLeaves
	--GO

	--CREATE SYNONYM Projectuser.sy_Master_CurrentLeaves FOR tas2.tas.Master_CurrentLeaves			--Live
	CREATE SYNONYM Projectuser.sy_Master_CurrentLeaves FOR tas2.tas.Master_CurrentLeaves			--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_Master_CurrentLeaves

*/

