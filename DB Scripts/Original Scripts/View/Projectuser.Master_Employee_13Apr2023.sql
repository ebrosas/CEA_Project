USE [ProjectRequisition]
GO

/****** Object:  View [Projectuser].[Master_Employee]    Script Date: 13/04/2023 02:32:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/************************************************************************************************************

View Name				:	Master_Employee
Description				:	This view returns employee details from the employee master setup

Created By				:	
Date Created			:	

Column Names
	EmpNo				:	(int) Employee No.
	EmpName				:	(varchar 40) Employee Name
	Cost Center			:	(varrchar 12) Cost Center of the employee
	WorkCostCenter		:	(varchar 12) Cost Center where the employee is currently working
	Company				:	(varchar 5) Company code of the Cost Center
	SupervisorNo		:	(int) Employee No. of the employee's supervisor
	TelephoneExt		:	(int) Telephone Extension of the employee
	Status				:	(char 1) Current Employment Status of the employee, active if numeric otherwise not

Revision History:
	1.0										
	Created	

	1.1					Shoukhat			2015.11.25 10:10
	Fetch the working cost center into the "Cost Center" field. Added "Actual_CostCenter" field
************************************************************************************************************/
ALTER     VIEW [Projectuser].[Master_Employee]
AS
SELECT  CAST(A.ABAN8 AS INT) AS EmpNo, 
		A.ABALPH AS EmpName, 
		--RTRIM(LTRIM(C.YAHMCU)) AS CostCenter, 
		--ver 1.1 Start
		CASE WHEN ISNULL(b.WorkingBusinessUnit, '') <> ''
				THEN LTRIM(RTRIM(b.WorkingBusinessUnit))
			 ELSE
				CASE WHEN a.ABAT1 = 'E' THEN LTRIM(RTRIM(c.YAHMCU))
					 WHEN a.ABAT1 = 'UG' THEN LTRIM(RTRIM(a.ABMCU)) 
				END
		END AS CostCenter,	
		--ver 1.1 End
		RTRIM(LTRIM(B.WorkingBusinessUnit)) AS WorkCostCenter, 
		C.YAHMCO AS Company, 
		CAST(C.YAANPA AS INT) AS SupervisorNo, 
		0 AS TelephoneExt,
		C.YAPAST AS Status,
		--ver 1.1 Start
		CASE WHEN a.ABAT1 = 'E' THEN LTRIM(RTRIM(c.YAHMCU))
			 WHEN a.ABAT1 = 'UG' THEN LTRIM(RTRIM(a.ABMCU)) 
		END AS Actual_CostCenter	
		--ver 1.1 End
FROM    JDE_PRODUCTION.PRODDTA.F0101 A 
		LEFT OUTER JOIN tas2.tas.Master_EmployeeAdditional B ON CAST(A.ABAN8 AS INT) = B.EmpNo 
		LEFT OUTER JOIN JDE_PRODUCTION.PRODDTA.F060116 C ON A.ABAN8 = C.YAAN8 
		WHERE     (A.ABAT1 = 'E') AND (A.ABAN8 > 10000000) OR
                      (A.ABAT1 = 'UG' )





GO


