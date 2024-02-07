/******************************************************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Vw_CEAAdministrators
*	Description: Get the list of al CEA Administrators
*
*	Date:			Author:		Rev. #:		Comments:
*	08/11/2023		Ervin		1.0			Created
*
******************************************************************************************************************************************************************************************************************/

CREATE VIEW Projectuser.Vw_CEAAdministrators
AS

	SELECT * FROM Projectuser.fnGetWFActionMember('CEAADMIN', 'ALL', 0)			

GO 

/*	Debug:

	SELECT * FROM Projectuser.Vw_CEAAdministrators

*/