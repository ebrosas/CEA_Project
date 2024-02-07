USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spCloseRequisitionUpdationToOneWorld]    Script Date: 04/12/2022 12:14:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***********************************************************************************************************
Procedure Name 	: [spCloseRequisitionUpdationToOneWorld]
Purpose		: This SP will Close all the uploaded requisitions from the OneWorld database

Author		: Zaharan Haleed
Date		: 03 June 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1.

************************************************************************************************************/

ALTER        Procedure [Projectuser].[spCloseRequisitionUpdationToOneWorld] 
	( 	@RequisitionID		as Int	)
As


Declare @RequisitionNo as varchar(8)
Declare @OneWorldABNo as float

Select @RequisitionNo = RequisitionNo From Requisition Where RequisitionID = @RequisitionID

Set @OneWorldABNo = (Select OneWorldABNo From Requisition Where RequisitionNo = @RequisitionNo)

UPDATE JDE_PRODUCTION.PRODDTA.F0101
SET	ABCM = 'JC'			
WHERE ABAN8 = @OneWorldABNo
