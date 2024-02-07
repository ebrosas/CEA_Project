USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spGetCostCenterName]    Script Date: 01/06/2021 11:00:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/***********************************************************************************************************
Procedure Name 	: spGetCostCenterName
Purpose		: This SP will get the cost center name for the given cost center code

Author		: Zaharan Haleed
Date		: 15 April 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1.

************************************************************************************************************/

ALTER  Procedure [Projectuser].[spGetCostCenterName]
		(	@CostCenter	As varchar(12))
As

	Select CostCenterName From Projectuser.Master_CostCenter 
	 Where CostCenter = @CostCenter






