/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_DistributionMember
*	Description: Retrieves workflow distribution group members
*
*	Date:			Author:		Rev.#:		Comments:
*	11/08/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_DistributionMember') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_DistributionMember
	--GO

	CREATE SYNONYM Projectuser.sy_DistributionMember FOR Gen_Purpose.genuser.DistributionMember

GO


/*	Testing

	SELECT * FROM Projectuser.sy_DistributionMember

*/

