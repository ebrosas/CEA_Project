/***********************************************************************************************************
Procedure Name 	: spGetCostCenterName
Purpose		: This SP will get the cost center name for the given cost center code

Author		: Zaharan Haleed
Date		: 15 April 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1. 

************************************************************************************************************/

ALTER PROCEDURE Projectuser.spGetCostCenterName
(	
	@CostCenter	VARCHAR(100)
)
AS
BEGIN 

	SET NOCOUNT ON 

	SELECT CostCenterName FROM Projectuser.Master_CostCenter a WITH (NOLOCK)
	Where (TRIM(a.CostCenter) = @CostCenter OR UPPER(TRIM(a.CostCenterName)) = UPPER(TRIM(@CostCenter)))

END 


/*	Debug:

	EXEC Projectuser.spGetCostCenterName '7600'
	EXEC Projectuser.spGetCostCenterName 'Information & Comm. Technology'

*/






