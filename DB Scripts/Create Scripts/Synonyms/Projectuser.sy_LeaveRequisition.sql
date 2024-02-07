/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_LeaveRequisition
*	Description: Retrieves data from "LeaveRequisition" table
*
*	Date:			Author:		Rev.#:		Comments:
*	27/04/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_LeaveRequisition') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_LeaveRequisition
	--GO

	--CREATE SYNONYM Projectuser.sy_LeaveRequisition FOR JDE_PRODUCTION.secuser.LeaveRequisition		--Live
	CREATE SYNONYM Projectuser.sy_LeaveRequisition FOR JDE_CRP.secuser.LeaveRequisition				--Test

GO


/*	Testing

	SELECT TOP 10 * FROM Projectuser.sy_LeaveRequisition

*/

