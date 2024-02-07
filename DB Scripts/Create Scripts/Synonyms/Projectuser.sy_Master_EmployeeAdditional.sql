/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_Master_EmployeeAdditional
*	Description: Retrieves data from "Master_EmployeeAdditional" table
*
*	Date:			Author:		Rev.#:		Comments:
*	13/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_Master_EmployeeAdditional') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_Master_EmployeeAdditional
	--GO

	--CREATE SYNONYM Projectuser.sy_Master_EmployeeAdditional FOR tas2.tas.Master_EmployeeAdditional			--Live
	CREATE SYNONYM Projectuser.sy_Master_EmployeeAdditional FOR tas2.tas.Master_EmployeeAdditional				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_Master_EmployeeAdditional

*/

