/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_CurrentDistributionMember
*	Description: Retrieves data from "secuser.CurrentDistributionMember" table
*
*	Date:			Author:		Rev.#:		Comments:
*	06/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_CurrentDistributionMember') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_CurrentDistributionMember
	--GO

	--CREATE SYNONYM Projectuser.sy_CurrentDistributionMember FOR JDE_PRODUCTION.secuser.CurrentDistributionMember		--Live
	CREATE SYNONYM Projectuser.sy_CurrentDistributionMember FOR JDE_CRP.secuser.CurrentDistributionMember				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_CurrentDistributionMember a
	WHERE CurrentDistMemReqTypeNo = 20230090

*/

