/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_TransDistributionMember
*	Description: Retrieves data from "secuser.DistributionMember" table
*
*	Date:			Author:		Rev.#:		Comments:
*	06/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_TransDistributionMember') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_TransDistributionMember
	--GO

	--CREATE SYNONYM Projectuser.sy_TransDistributionMember FOR JDE_PRODUCTION.secuser.DistributionMember		--Live
	CREATE SYNONYM Projectuser.sy_TransDistributionMember FOR JDE_CRP.secuser.DistributionMember				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_TransDistributionMember

*/

