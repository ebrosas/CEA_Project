/***********************************************************************************************************
Procedure Name 	: RequisitionUsedAmt
Purpose		: This function will return the used amount of a given requisition

Author		: Zaharan Haleed
Date		: 24th June 2008
------------------------------------------------------------------------------------------------------------
Modification History:
	1.

************************************************************************************************************/
ALTER FUNCTION Projectuser.RequisitionUsedAmt
(
	@RequisitionNo as varchar(12)
)
RETURNS	NUMERIC(18,3)
BEGIN 

	Declare @CEANumber 	as varchar(8)
	Declare @POTotal 	as numeric(18,3)
	Declare @GLTotal 	as numeric(18,3)
	Declare @ReqUsed 	as numeric(18,3)
	Declare @CEANumberTmp 	as int

	SELECT @CEANumberTmp = CASE WHEN ISNUMERIC(a.OneWorldABNo) = 1 THEN CONVERT(INT, a.OneWorldABNo) ELSE 0 END 
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE a.RequisitionNo = @RequisitionNo

	SET @CEANumber = Projectuser.lpad(convert(varchar, @CEANumberTmp),8,'0')

	SELECT @POTotal = SUM(a.OpnAmtInPO) 
	FROM Projectuser.ExpenceDetails_JDE a
	WHERE RTRIM(a.CEANumber) = RTRIM(@CEANumber)

	SELECT @GLTotal = SUM(GLAmount) 
	FROM Projectuser.ExpenceDetails_JDE a 
	WHERE RTRIM(a.CEANumber) = RTRIM(@CEANumber)

	SET @ReqUsed = ISNULL(@POTotal, 0) + ISNULL(@GLTotal, 0)


	RETURN ISNULL(@ReqUsed, 0)

END
