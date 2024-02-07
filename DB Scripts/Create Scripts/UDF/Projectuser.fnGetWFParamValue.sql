/******************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetWFParamValue
*	Description: This function is used to get the workflow parameter value
*
*	Date:			Author:		Rev.#:		Comments:
*	14/09/2023		Ervin		1.0			Created
*******************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetWFParamValue
(
	@requisitionNo		INT,
	@paramName			VARCHAR(100)
)
RETURNS VARCHAR(4000)
AS
BEGIN

	DECLARE @paramValue VARCHAR(4000) = '',
			@CONST_REQUEST_TYPE_CEA INT = 22

	SELECT @paramValue = RTRIM(b.ParamValue)
	FROM Projectuser.sy_ProcessWF a WITH (NOLOCK) 
		INNER JOIN Projectuser.sy_TransParameter b WITH (NOLOCK) ON a.ProcessID = b.ParamProcessID
	WHERE a.ProcessReqType = @CONST_REQUEST_TYPE_CEA 
		AND a.ProcessReqTypeNo = @requisitionNo
		AND RTRIM(b.ParamName) = @paramName

	RETURN @paramValue 

END

/*	Testing:

PARAMETERS:
	@requisitionNo		INT,
	@paramName			VARCHAR(100)
	
	SELECT Projectuser.fnGetWFParamValue(20230063, 'RequestOrigEmpNo')

*/
