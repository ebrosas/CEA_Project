
	EXEC [Projectuser].[spGetRequisitions] '', '0', '', 2022, 'DraftAndSubmitted', '', 0, 10003632, ''		--All Open Status
	EXEC [Projectuser].[spGetRequisitions] '', '0', '', 2022, 'Draft', '', 0, 10003632, ''					--Draft
	EXEC [Projectuser].[spGetRequisitions] '', '0', '', 2022, 'Submitted', '', 0, 10003632, ''				--Submitted for Approval
	EXEC [Projectuser].[spGetRequisitions] '', '0', '', 2022, 'Rejected', '', 0, 10003632, ''				--Rejected
	EXEC [Projectuser].[spGetRequisitions] '', '0', '', 2022, 'Closed', '', 0, 10003632, ''				--Closed
	
/*

	@ProjectNo			AS varchar(12) = '',
	@CostCenter			AS varchar(12) = '0',
	@ExpenditureType	AS varchar(10) = '',	
	@FiscalYear			AS smallint,
	@StatusCode			AS varchar(50) = '',
	@RequisitionNo		AS varchar(12) = '',
	@FilterToUser		AS bit = 0,
	@EmployeeNo			AS Int = 0,
	@KeyWords			AS varchar(50) = '' 

*/