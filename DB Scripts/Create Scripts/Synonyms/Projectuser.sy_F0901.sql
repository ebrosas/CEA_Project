/*********************************************************************************
*	Revision History
*
*	Name: Projectuser.sy_F0901
*	Description: Retrieves data from "F0901" table
*
*	Date:			Author:		Rev.#:		Comments:
*	04/04/2023		Ervin		1.0			Created
**********************************************************************************/

	IF OBJECT_ID ('Projectuser.sy_F0901') IS NOT NULL
		DROP SYNONYM Projectuser.sy_F0901
	GO

	--CREATE SYNONYM Projectuser.sy_F0901 FOR JDE_PRODUCTION.PRODDTA.F0901		--Live
	CREATE SYNONYM Projectuser.sy_F0901 FOR JDE_CRP.CRPDTA.F0901				--Test

GO


/*	Testing

	SELECT * FROM Projectuser.sy_F0901

*/

