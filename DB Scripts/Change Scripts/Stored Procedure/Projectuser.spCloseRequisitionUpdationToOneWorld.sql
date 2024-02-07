/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.spCloseRequisitionUpdationToOneWorld 
*	Description: This SP will Close all the uploaded requisitions from the OneWorld database
*
*	Date:			Author:		Rev.#:		Comments:
*	03/06/2007		Zaharan		1.0			Created
*	04/12/2022		Ervin		1.1			Refactored the code to clean-up and enhance performance
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.spCloseRequisitionUpdationToOneWorld 
( 	
	@RequisitionID	INT 	
)
AS
BEGIN 

	DECLARE @RequisitionNo AS VARCHAR(8),
			@OneWorldABNo AS FLOAT

	SELECT @RequisitionNo = RequisitionNo 
	FROM dbo.Requisition a WITH (NOLOCK) 
	WHERE RequisitionID = @RequisitionID

	SELECT @OneWorldABNo = a.OneWorldABNo 
	FROM dbo.Requisition a WITH (NOLOCK) 
	WHERE RTRIM(a.RequisitionNo) = RTRIM(@RequisitionNo)

	UPDATE JDE_PRODUCTION.PRODDTA.F0101
	SET	ABCM = 'JC'			
	WHERE ABAN8 = @OneWorldABNo
    
END 
