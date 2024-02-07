/*****************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetApproverEmail
*	Description: Mapped to the following stored procedure: Gen_Purpose.genuser.fnGetApproverEmail
*
*	Date:			Author:		Rev.#:		Comments:
*	22/05/2023		Ervin		1.0			Created
*****************************************************************************************************************************************************/

	IF OBJECT_ID ('Projectuser.fnGetApproverEmail') IS NOT NULL
		DROP SYNONYM Projectuser.fnGetApproverEmail
	GO

	CREATE SYNONYM Projectuser.fnGetApproverEmail FOR JDE_CRP.secuser.fnGetApproverEmail

GO


/*	Testing

	SELECT Projectuser.fnGetApproverEmail(20230128)

*/

