/*****************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.pr_GetUserFormAccess
*	Description: Mapped to the following stored procedure: Gen_Purpose.genuser.pr_GetUserFormAccess
*
*	Date:			Author:		Rev.#:		Comments:
*	22/05/2023		Ervin		1.0			Created
*****************************************************************************************************************************************************/

	IF OBJECT_ID ('Projectuser.pr_GetUserFormAccess') IS NOT NULL
		DROP SYNONYM Projectuser.pr_GetUserFormAccess
	GO

	CREATE SYNONYM Projectuser.pr_GetUserFormAccess FOR Gen_Purpose.genuser.pr_GetUserFormAccess

GO


/*	Testing

	EXEC Projectuser.pr_GetUserFormAccess 1, 0, 'PROJECTINQ', '7600', 10003632, '', NULL
	EXEC Projectuser.pr_GetUserFormAccess 1, 0, 'PROJECTINQ', '', 10003632, '', NULL

*/

