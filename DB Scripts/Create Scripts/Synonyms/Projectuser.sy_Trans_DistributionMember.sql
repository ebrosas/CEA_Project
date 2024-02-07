/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_Trans_DistributionMember
*	Description: Retrieves data from "secuser.DistributionMember" table
*
*	Date:			Author:		Rev.#:		Comments:
*	01/11/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.sy_Trans_DistributionMember') IS NOT NULL
		DROP SYNONYM Projectuser.sy_Trans_DistributionMember
	GO

	--CREATE SYNONYM Projectuser.sy_Trans_DistributionMember FOR JDE_PRODUCTION.secuser.DistributionMember			--Live
	CREATE SYNONYM Projectuser.sy_Trans_DistributionMember FOR JDE_CRP.secuser.DistributionMember					--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_Trans_DistributionMember

	SELECT * FROM JDE_CRP.secuser.DistributionMember

*/

