/******************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetEmployeePosition
*	Description: This function is used to get the job title of the specified employee
*
*	Date:			Author:		Rev.#:		Comments:
*	21/09/2023		Ervin		1.0			Created
*******************************************************************************************************************************************************/

CREATE FUNCTION Projectuser.fnGetEmployeePosition
(
	@empNo	INT
)
RETURNS VARCHAR(60)
AS
BEGIN

	DECLARE @jobTitle VARCHAR(60) = ''

	SELECT @jobTitle = LTRIM(RTRIM(b.DRDL01)) + ' ' + LTRIM(RTRIM(b.DRDL02)) 
	FROM Projectuser.sy_F060116 a WITH (NOLOCK)
		LEFT JOIN Projectuser.sy_F0005 b WITH (NOLOCK) ON LTRIM(RTRIM(a.YAJBCD)) = LTRIM(RTRIM(b.DRKY)) AND RTRIM(LTRIM(b.DRSY)) = '06' AND RTRIM(LTRIM(b.DRRT)) = 'G'	
	WHERE CAST(a.YAAN8 AS INT) = @empNo

	RETURN @jobTitle 

END

/*	Testing:

	SELECT Projectuser.fnGetEmployeePosition(10003512)

*/
