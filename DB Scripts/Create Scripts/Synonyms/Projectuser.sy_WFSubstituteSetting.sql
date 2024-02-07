/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_WFSubstituteSetting
*	Description: Retrieves workflow distribution list 
*
*	Date:			Author:		Rev.#:		Comments:
*	11/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_WFSubstituteSetting') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_WFSubstituteSetting
	--GO

	CREATE SYNONYM Projectuser.sy_WFSubstituteSetting FOR Gen_Purpose.genuser.WFSubstituteSetting

GO


/*	Testing

	SELECT * FROM Projectuser.sy_WFSubstituteSetting

*/

