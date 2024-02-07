/******************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetNextSequence
*	Description: This function is used to get the next approval sequence
*
*	Date:			Author:		Rev.#:		Comments:
*	05/10/2023		Ervin		1.0			Created
*******************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetNextSequence
(
	@requisitionID		INT,
	@currentSequence	INT 
)
RETURNS INT 
AS
BEGIN

	DECLARE @nextSequence INT = 0

	SELECT @NextSequence = min(b.GroupRountingSequence)
	FROM dbo.RequisitionStatus a WITH (NOLOCK)
		INNER JOIN dbo.RequisitionStatusDetail b WITH (NOLOCK) ON a.RequisitionStatusID = b.RequisitionStatusID
	WHERE a.RequisitionID = @requisitionID
		AND b.GroupRountingSequence > @currentSequence

	RETURN ISNULL(@nextSequence, -2) 

END

/*	Testing:

	SELECT Projectuser.fnGetNextSequence(3905, 3)

*/
