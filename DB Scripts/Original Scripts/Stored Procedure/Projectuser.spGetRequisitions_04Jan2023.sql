USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spGetRequisitions]    Script Date: 04/01/2023 12:22:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***********************************************************************************************************
Procedure Name 	: spGetRequisitions
Purpose		: This SP will return a list of Requisitions

Author		: Zaharan Haleed
Date		: 10 April 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1. June 5th 2007 - Added a new status check 'DraftAndSubmitted' to fetch Draft and Submitted requisitions

************************************************************************************************************/
ALTER                            Procedure [Projectuser].[spGetRequisitions]
	( 	@ProjectNo		as varchar(12) = '',
		@CostCenter		as varchar(12) = '0',
		@ExpenditureType	as varchar(10) = '',	
		@FiscalYear		as smallint,
		@StatusCode		as varchar(50) = '',
		@RequisitionNo		as varchar(12) = '',
		@FilterToUser		as bit = 0,
		@EmployeeNo		as Int = 0,
		@KeyWords		as varchar(50) = '' )
As

Declare @ApplicationUserID 	as int
Declare @ApprovalStatusID	as int
Declare @RequisitionTotal 	as numeric(18,3)

Select @ApplicationUserID = ApplicationUserID from ApplicationUser Where EmployeeNo = @EmployeeNo

set @RequisitionTotal = 0

--if RequisitionNo is selected
if(len(@RequisitionNo)>0)
Begin
	Select 	Distinct a.RequisitionID, 
		a.ProjectNo as 'Project No', 
		a.RequisitionNo as 'Requisition No', 
		convert(varchar,a.RequestDate,103) as 'Requisition Date', 
		a.Description, 
		convert(varchar,a.DateofComission,103) as 'Date of Commission', 
		a.RequestedAmt as 'Amount' ,
		(	Select CostCenterName
			From Master_CostCenter
			Where CostCenterType = 'AL'
			And CostCenter = a.PlantLocationID) as 'Plant',
		AST.ApprovalStatus as 'Status',
		b.CostCenter,
		b.CompanyCode,
	 	b.ObjectCode,
		b.SubjectCode,
		b.AccountCode,
		AST.StatusCode,
		@RequisitionTotal, 
		Projectuser.RequisitionUsedAmt(a.RequisitionNo) as 'Used Amt'
	From Requisition a
		Inner Join Project b On a.ProjectNo = b.ProjectNo
		Inner Join RequisitionStatus RS on a.RequisitionID = RS.RequisitionID
		Inner Join ApprovalStatus AST on AST.ApprovalStatusID = RS.ApprovalStatusID
		Inner Join RequisitionStatusDetail RSD on RS.RequisitionStatusID = RSD.RequisitionStatusID
		Inner Join Requisition R On R.RequisitionID = RS.RequisitionID
	Where R.RequisitionNo like '%' + @RequisitionNo + '%'
	Order by a.RequisitionNo desc  

	return 1
End

--If project no is typed
if len(@ProjectNo)>0 and len(@RequisitionNo)=0
Begin
	Select 	Distinct a.RequisitionID, 
		a.ProjectNo as 'Project No', 
		a.RequisitionNo as 'Requisition No', 
		convert(varchar,a.RequestDate,103) as 'Requisition Date', 
		a.Description, 
		convert(varchar,a.DateofComission,103) as 'Date of Commission', 
		a.RequestedAmt as 'Amount' ,
		(	Select CostCenterName
			From Master_CostCenter
			Where CostCenterType = 'AL'
			And CostCenter = a.PlantLocationID) as 'Plant',
		AST.ApprovalStatus as 'Status',
		b.CostCenter,
		b.CompanyCode,
	 	b.ObjectCode,
		b.SubjectCode,
		b.AccountCode,
		AST.StatusCode,
		@RequisitionTotal,
		Projectuser.RequisitionUsedAmt(a.RequisitionNo) as 'Used Amt'
	From Requisition a
		Inner Join Project b On a.ProjectNo = b.ProjectNo
		Inner Join RequisitionStatus RS on a.RequisitionID = RS.RequisitionID
		Inner Join ApprovalStatus AST on AST.ApprovalStatusID = RS.ApprovalStatusID
		Inner Join RequisitionStatusDetail RSD on RS.RequisitionStatusID = RSD.RequisitionStatusID
	Where b.ProjectNo like '%' + @ProjectNo + '%'
	Order by a.RequisitionNo desc  

	return 1
End

--If the 'Filter My Pending approvals' is selected
if @FilterToUser = 1
Begin

	Set @ApprovalStatusID = (Select ApprovalStatusID From ApprovalStatus Where StatusCode in ('SubmittedForApproval'))

	Select 	Distinct a.RequisitionID, 
		a.ProjectNo as 'Project No', 
		a.RequisitionNo as 'Requisition No', 
		convert(varchar,a.RequestDate,103) as 'Requisition Date', 
		a.Description, 
		convert(varchar,a.DateofComission,103) as 'Date of Commission', 
		a.RequestedAmt as 'Amount' ,
		(	Select CostCenterName
			From Master_CostCenter
			Where CostCenterType = 'AL'
			And CostCenter = a.PlantLocationID) as 'Plant',
		AST.ApprovalStatus as 'Status',
		b.CostCenter,
		b.CompanyCode,
	 	b.ObjectCode,
		b.SubjectCode,
		b.AccountCode,
		AST.StatusCode,
		@RequisitionTotal,
		Projectuser.RequisitionUsedAmt(a.RequisitionNo) as 'Used Amt'
	From Requisition a
		Inner Join Project b On a.ProjectNo = b.ProjectNo
		Inner Join RequisitionStatus RS on a.RequisitionID = RS.RequisitionID
		Inner Join ApprovalStatus AST on AST.ApprovalStatusID = RS.ApprovalStatusID
		Inner Join RequisitionStatusDetail RSD on RS.RequisitionStatusID = RSD.RequisitionStatusID
	Where RSD.ApplicationUserID = @ApplicationUserID 
	And RSD.ApprovalStatusID = @ApprovalStatusID
	Order by a.RequisitionNo desc  

	print @ApprovalStatusID
	print @ApplicationUserID
	return 1
End

---------- All other query conditions --------------
declare @query	as varchar(8000)

Set @query = 'Select Distinct a.RequisitionID,'
Set @query = @query + char(10) + ' a.ProjectNo as ''Project No'','
Set @query = @query + char(10) + ' a.RequisitionNo as ''Requisition No'',' 
Set @query = @query + char(10) + ' convert(varchar,a.RequestDate,103) as ''Requisition Date'',' 
Set @query = @query + char(10) + ' b.ExpenditureType + '' - '' + a.Description as ''Description'','
Set @query = @query + char(10) + ' convert(varchar,a.DateofComission,103) as ''Date of Commission'',' 
Set @query = @query + char(10) + ' a.RequestedAmt as ''Amount'','
Set @query = @query + char(10) + '(Select CostCenterName'
Set @query = @query + char(10) + ' From ProjectUser.Master_CostCenter'
Set @query = @query + char(10) + ' Where CostCenterType = ''AL'''
Set @query = @query + char(10) + ' And CostCenter = a.PlantLocationID) as ''Plant'','
Set @query = @query + char(10) + ' AST.ApprovalStatus as ''Status'','
Set @query = @query + char(10) + ' b.CostCenter,'
Set @query = @query + char(10) + ' b.CompanyCode,'
Set @query = @query + char(10) + ' b.ObjectCode,'
Set @query = @query + char(10) + ' b.SubjectCode,'
Set @query = @query + char(10) + ' b.AccountCode,'
Set @query = @query + char(10) + ' AST.StatusCode,'
Set @query = @query + char(10) +  convert(varchar,@RequisitionTotal) + ',' 			
Set @query = @query + char(10) + ' Projectuser.RequisitionUsedAmt(a.RequisitionNo) as ''Used Amt'''
Set @query = @query + char(10) + ' From Requisition a'
Set @query = @query + char(10) + ' Inner Join Project b On a.ProjectNo = b.ProjectNo'
Set @query = @query + char(10) + ' Inner Join RequisitionStatus RS on a.RequisitionID = RS.RequisitionID'
Set @query = @query + char(10) + ' Inner Join ApprovalStatus AST on AST.ApprovalStatusID = RS.ApprovalStatusID'
--Set @query = @query + char(10) + ' Inner Join RequisitionStatusDetail RSD on RS.RequisitionStatusID = RSD.RequisitionStatusID'


if @CostCenter <> '0'
	Set @query = @query + char(10) + ' Where b.CostCenter = ''' + @CostCenter + ''''
else
	Set @query = @query + char(10) + ' Where a.RequisitionID > 0'

if @ExpenditureType = '' or @ExpenditureType = '0'
	Set @query = @query + char(10) + ' And b.ExpenditureType in (''CEA'',''MRE'',''INC'',''SPR'')'
else
	Set @query = @query + char(10) + ' And b.ExpenditureType = ''' + @ExpenditureType + ''''

if @FiscalYear != 0
	Set @query = @query + char(10) + ' And ((b.FiscalYear = ' + convert(varchar,@FiscalYear) + ') or (year(a.CreateDate) =' + convert(varchar,@FiscalYear) + '))'

if @KeyWords != ''
	Set @query = @query + char(10) + ' And (a.Description like ''%' + @KeyWords + '%'') And (a.Reason like ''%' + @KeyWords + '%'')'

if @StatusCode = 'DraftAndSubmitted'
	Set @query = @query + char(10) + ' And AST.StatusCode in (''Draft'', ''Submitted'', ''AwaitingChairmanApproval'', ''Approved'',''UploadedToOneWorld'')'
else if @StatusCode = 'RequisitionAdministration'
	Set @query = @query + char(10) + ' And AST.StatusCode in (''AwaitingChairmanApproval'', ''Approved'')'
else if @StatusCode = ''
	Set @query = @query
else
	Set @query = @query + char(10) + ' And AST.StatusCode = ''' + @StatusCode + ''''  

Set @query = @query + char(10) + ' Order by a.RequisitionNo desc'
		

exec (@query)

print @query

-- exec spGetRequisitions @ProjectNo, @CostCenter, @ExpenditureType, @FiscalYear, @StatusCode, @RequisitionNo, @FilterToUser,@EmployeeNo,@KeyWords 

-- exec spGetRequisitions '', '7600','0',2008, 'DraftAndSubmitted', '',  0, 10003479, ''

-- fiscalYear 2008, costCenter 7600, expenditureType '', projectNo '', statusCode 'DraftAndSubmitted', 
-- requisitionNo '', filterToUser 0, employeeNo 0, keyWords ''
	



