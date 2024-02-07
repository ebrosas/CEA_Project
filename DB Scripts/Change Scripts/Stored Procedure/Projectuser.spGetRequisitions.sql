/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.spGetRequisitions 
*	Description: This SP will return a list of Requisitions
*
*	Date:			Author:		Rev.#:		Comments:
*	05/06/2007		Zaharan		1.0			Created
*	04/01/2023		Ervin		1.1			Exclude the following statuses in @FilterToUser = 1: 8 = Rejected, 10 = Cancelled, 11 = Closed, 15 = Uploaded to OneWorld
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.spGetRequisitions
( 	
	@ProjectNo			AS varchar(12) = '',
	@CostCenter			AS varchar(12) = '0',
	@ExpenditureType	AS varchar(10) = '',	
	@FiscalYear			AS smallint,
	@StatusCode			AS varchar(50) = '',
	@RequisitionNo		AS varchar(12) = '',
	@FilterToUser		AS bit = 0,
	@EmployeeNo			AS Int = 0,
	@KeyWords			AS varchar(50) = '' 
)
AS 
BEGIN 

	Declare @ApplicationUserID 	as int
	Declare @ApprovalStatusID	as int
	Declare @RequisitionTotal 	as numeric(18,3)

	SELECT @ApplicationUserID = ApplicationUserID 
	FROM dbo.ApplicationUser WITH (NOLOCK) 
	WHERE EmployeeNo = @EmployeeNo

	set @RequisitionTotal = 0

	--if RequisitionNo is selected
	IF LEN(@RequisitionNo) > 0
	BEGIN
    
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
		From dbo.Requisition a WITH (NOLOCK)
			Inner Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
			Inner Join dbo.RequisitionStatus RS WITH (NOLOCK) on a.RequisitionID = RS.RequisitionID
			Inner Join dbo.ApprovalStatus AST WITH (NOLOCK) on AST.ApprovalStatusID = RS.ApprovalStatusID
			Inner Join dbo.RequisitionStatusDetail RSD WITH (NOLOCK) on RS.RequisitionStatusID = RSD.RequisitionStatusID
			Inner Join dbo.Requisition R WITH (NOLOCK) On R.RequisitionID = RS.RequisitionID
		Where RTRIM(R.RequisitionNo) like '%' + @RequisitionNo + '%'
		Order by a.RequisitionNo desc  

		return 1
	End

	--If project no is typed
	ELSE IF LEN(@ProjectNo) > 0 AND  LEN(@RequisitionNo) = 0
	BEGIN
    
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
		From dbo.Requisition a WITH (NOLOCK)
			Inner Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
			Inner Join dbo.RequisitionStatus RS WITH (NOLOCK) on a.RequisitionID = RS.RequisitionID
			Inner Join dbo.ApprovalStatus AST WITH (NOLOCK) on AST.ApprovalStatusID = RS.ApprovalStatusID
			Inner Join dbo.RequisitionStatusDetail RSD WITH (NOLOCK) on RS.RequisitionStatusID = RSD.RequisitionStatusID
		WHERE RTRIM(b.ProjectNo) like '%' + @ProjectNo + '%'
		Order by a.RequisitionNo desc  

		return 1
	End

	--If the 'Filter My Pending approvals' is selected
	ELSE IF @FilterToUser = 1
	BEGIN 

		Set @ApprovalStatusID = (Select ApprovalStatusID From ApprovalStatus Where StatusCode in ('SubmittedForApproval'))

		Select 	Distinct a.RequisitionID, 
			a.ProjectNo as 'Project No', 
			a.RequisitionNo as 'Requisition No', 
			convert(varchar,a.RequestDate,103) as 'Requisition Date', 
			a.Description, 
			convert(varchar,a.DateofComission,103) as 'Date of Commission', 
			a.RequestedAmt as 'Amount' ,
			(	Select CostCenterName
				From Projectuser.Master_CostCenter WITH (NOLOCK)
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
		From dbo.Requisition a WITH (NOLOCK)
			Inner Join dbo.Project b WITH (NOLOCK) On a.ProjectNo = b.ProjectNo
			Inner Join dbo.RequisitionStatus RS WITH (NOLOCK) on a.RequisitionID = RS.RequisitionID
			Inner Join dbo.ApprovalStatus AST WITH (NOLOCK) on AST.ApprovalStatusID = RS.ApprovalStatusID
			Inner Join dbo.RequisitionStatusDetail RSD WITH (NOLOCK) on RS.RequisitionStatusID = RSD.RequisitionStatusID
		WHERE RSD.ApplicationUserID = @ApplicationUserID 
			AND RSD.ApprovalStatusID = @ApprovalStatusID
			AND RS.ApprovalStatusID NOT IN		--Rev. #1.1
			(
				8,			--Rejected
				10,			--Cancelled
				11,			--Closed
				15			--Uploaded to OneWorld
			)
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

	--print @query

END 	



