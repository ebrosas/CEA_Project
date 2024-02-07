/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_DistributionList
*	Description: Retrieves workflow distribution list 
*
*	Date:			Author:		Rev.#:		Comments:
*	11/08/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_DistributionList') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_DistributionList
	--GO

	CREATE SYNONYM Projectuser.sy_DistributionList FOR Gen_Purpose.genuser.DistributionList

GO


/*	Testing

	SELECT * FROM Projectuser.sy_DistributionList

*/

