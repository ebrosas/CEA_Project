/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_WFSubstituteAuthorizationSetting
*	Description: Retrieves workflow distribution list 
*
*	Date:			Author:		Rev.#:		Comments:
*	11/09/2023		Ervin		1.0			Created
**********************************************************************************/

	--IF OBJECT_ID ('Projectuser.sy_WFSubstituteAuthorizationSetting') IS NOT NULL
	--	DROP SYNONYM Projectuser.sy_WFSubstituteAuthorizationSetting
	--GO

	CREATE SYNONYM Projectuser.sy_WFSubstituteAuthorizationSetting FOR Gen_Purpose.genuser.WFSubstituteAuthorizationSetting

GO


/*	Testing

	SELECT * FROM Projectuser.sy_WFSubstituteAuthorizationSetting

*/

