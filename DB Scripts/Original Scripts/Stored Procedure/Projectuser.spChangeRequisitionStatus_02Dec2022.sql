USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spChangeRequisitionStatus]    Script Date: 02/12/2022 08:36:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/***********************************************************************************************************
Procedure Name 	: spChangeRequisitionStatus
Purpose		: This SP changes the current state of a Requisition

Author		: Zaharan Haleed
Date		: 08 Nov 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1. 2008.08.10 10:12		NGF
		-- Update the JDE also when recalling a requisition
************************************************************************************************************/
/*
declare @return as int
exec @return = spChangeRequisitionStatus '20072136', 'RecallRequisition', 10003479, 'test'

print @return
*/

ALTER   Procedure [Projectuser].[spChangeRequisitionStatus]
	(	@RequisitionNo		as Varchar(12),
		@ActionType			as Varchar(50),
		@EmpNo				as int,
		@Comment			as varchar(500))
As		

declare @NewStatusID 				as int
declare @CurrentSequence			as int
declare @RequisitionStatusID		as int
declare @ApplicationUserID			as int
declare @LastSubmittedDate			as datetime
declare @GroupRountingSequence		as int
declare @UploaderApprovalGroupID	as int
declare @RequisitionID				as int
declare @RejectorEmpNo				as int
declare @POCount					as int
declare @SysteAdminCount			as int
declare @RejectStatusID				as int
declare @CreatedByEmpNo				as int
declare @CostCenter					as varchar(12)
declare @CostCenterManagerEmpNo		as int
declare @count						as int

--get the requisition id
Select @RequisitionID = RequisitionID, @CreatedByEmpNo = CreatedByEmpNo From Requisition Where RequisitionNo = @RequisitionNo
--get applicationuser id
select @ApplicationUserID = ApplicationUserID from ApplicationUser where employeeno = @EmpNo
--get the requisition status id
select @RequisitionStatusID = RequisitionStatusID from RequisitionStatus where requisitionid = @RequisitionID
--get the current sequence
select @CurrentSequence = CurrentSequence From RequisitionStatus Where RequisitionID = @RequisitionID
--get last submitted date
select @LastSubmittedDate = SubmittedDate from RequisitionStatusDetail where RequisitionStatusID = @RequisitionStatusID
--reject status ID
select @RejectStatusID = ApprovalStatusID from ApprovalStatus where StatusCode = 'Rejected'
--
Select @CostCenter From Project Where ProjectNo = (Select ProjectNo From Requisition Where RequisitionNo = @RequisitionNo)
--
select top 1 @CostCenterManagerEmpNo = ManagerNo From Projectuser.Master_CostCenter Where CostCenter = @CostCenter

set @POCount		= 0
set @count		= 0
set @SysteAdminCount	= 0

--The Requisition is currently in 'Reject' state, Change to state 'Submitted for Approval'
if @ActionType = 'ActivateRequisition'
Begin					
	--:BUSINESS RULE 1. Only the Rejector can re-activate the Rejected Requisition.
	-------------------------------------------------------------------------------
	--Get the rejector empNo and Name
	Select top 1 @RejectorEmpNo = AU.EmployeeNo
	From ApplicationUser AU
		Inner Join RequisitionStatusDetail RSD on RSD.ApplicationUserID = AU.ApplicationUserID
	Where RSD.ApprovalStatusID = @RejectStatusID
	And RSD.RequisitionStatusID = @RequisitionStatusID

	--Check current user EmpNo with rejector empNo, if not same, then raise error.
	if @RejectorEmpNo<>@EmpNo
	Begin
		return -1;	--only rejector can reactivate the requisition
	end

	--get the requistion StatusID for 'Submitted for Approval'
	select @NewStatusID = ApprovalStatusID from ApprovalStatus where StatusCode = 'Reactivated'
	--get the routing sequence of the rejected user (approval cannot go beyond this line, so its safe to get sequence from here)
	select @GroupRountingSequence = GroupRountingSequence from RequisitionStatusDetail where RequisitionStatusID = @RequisitionStatusID
	And ApprovalStatusID = (Select ApprovalStatusID from ApprovalStatus Where StatusCode = 'Rejected')

	--get the approvalgroup id though it is ignorant here
	select top 1 @UploaderApprovalGroupID = ApprovalGroupID from RequisitionStatusDetail where RequisitionStatusID = @RequisitionStatusID
	And ApprovalStatusID = (Select ApprovalStatusID from ApprovalStatus Where StatusCode = 'Rejected')

	--the rejected Requisition is activated and it should reflect in OneWorld
	--UPDATE JDE_PRODUCTION.PRODDTA.F0101_ADT // commented by Zaharan on 30th June 2009
	UPDATE JDE_PRODUCTION.PRODDTA.F0101	
	SET	ABAT1 = 'JA'	
	WHERE ABAN8 = @RequisitionNo

	Select @Comment = 'Re-activated - ' + @Comment
End

--The Requisition is currently in 'Submitted' or 'Approved' state, Change to state 'Cancel'	
if @ActionType = 'RecallRequisition' 	
Begin		
	--:BUSINESS RULE 1. A requisition can be recalled if no PO's are raised.
	-------------------------------------------------------------------------------		
	--Check if the Requisition has any PO's. If there any, then cannot be recalled. Raise error.
	Declare @CEANumber as varchar(8)
	Declare @CEANumberTmp as int
	
	Select @CEANumberTmp = convert(int,OneWorldABNo) From Requisition Where RequisitionNo = @RequisitionNo
	Select @CEANumber = Projectuser.lpad(convert(varchar,@CEANumberTmp),8,'0')
	
	Select @POCount = (select count(*) from Projectuser.PurchaseOrders_JDE where ceanumber = @CEANumber)
	
	--Check the total PO for the current RequisitionNo, if not 0, then raise error.
	if @POCount>0
	Begin
		return -2;	--there should be no PO's
	end

	--:BUSINESS RULE 2. Only the creator or cost center manager or a system admin can recall a requisition
	-------------------------------------------------------------------------------		
	select @count = (select count(*) from
			 (select 1 col1 from Requisition where requisitionno=@RequisitionNo and CreatedByEmpNo=@EmpNo
			  union all
			  select 1 col1 from projectuser.Master_CostCenter where costcenter=@CostCenter and ManagerNo=@EmpNo
			  union all
			  select 1 col1 from ApplicationUser AUB
			 	Inner Join ApprovalGroupAssignment AGA on AUB.ApplicationUserID = AGA.ApplicationUserID
				Inner Join ApprovalGroupDetail AGD on AGD.ApprovalGroupTypeID = AGA.ApprovalGroupTypeID
			  Where AGD.UserGroupTypeCode = 'Admin' and AUB.EmployeeNo = @EmpNo
			  )tbl
			 )

	if @count<0
	Begin
		return -3; --The caller should be either an admin, secretary or cost center manager
	end
	
	--get the requistion StatusID for 'Cancelled'
	select @NewStatusID = ApprovalStatusID from ApprovalStatus where StatusCode = 'Cancelled'
	--once the Requisition is recalled, the sequencing should stop
	select @GroupRountingSequence = -1
	--get the approvalgroup id though it is ignorant here
	select @UploaderApprovalGroupID = -1

	-- Added by NGF 2008.08.10 10:12
	-- Update the JDE also
	--UPDATE JDE_PRODUCTION.PRODDTA.F0101_ADT // commented by Zaharan on 30th June 2009
	UPDATE JDE_PRODUCTION.PRODDTA.F0101
	SET	ABAT1 = 'JR'	
	WHERE ABAN8 = @RequisitionNo

End

--The Requisition is currently in 'Close' state, Change to state 'Uploaded to OneWorld'
if @ActionType = 'OpenRequisition' 	 
Begin		
	--:BUSINESS RULE 1. Only the Rejector can re-activate the Rejected Requisition.
	-------------------------------------------------------------------------------	
	-------Check if the current user is a System Admin, if not raise error---------
		
	select @count = (select count(*) From ApplicationUser AUB
			 	Inner Join ApprovalGroupAssignment AGA on AUB.ApplicationUserID = AGA.ApplicationUserID
				Inner Join ApprovalGroupDetail AGD on AGD.ApprovalGroupTypeID = AGA.ApprovalGroupTypeID
			 where AGD.UserGroupTypeCode = 'Admin' and AUB.EmployeeNo = @EmpNo) 

	if @count>0
	Begin
		return -4; --The caller should be a system admin
	end

	--get the requistion StatusID for 'UploadedToOneWorld'
	select @NewStatusID = ApprovalStatusID from ApprovalStatus where StatusCode = 'UploadedToOneWorld'
	--this is re-opened only to create PR's or similar purpose, but there wont be a sequencing!
	select @GroupRountingSequence = -1
	--get the approvalgroup id though it is ignorant here
	select @UploaderApprovalGroupID = -1
End

--Insert Requisition status detail indicating the current action
Insert into RequisitionStatusDetail 
(RequisitionStatusID, SubmittedDate, ApprovalGroupID, ApplicationUserID, ApprovalStatusID, 
	StatusDate, RoutingSequence, PermanentStatus, ApproverComment, GroupRountingSequence)
Values (@RequisitionStatusID, @LastSubmittedDate, @UploaderApprovalGroupID, @ApplicationUserID, @NewStatusID,
 getdate(), 1, 1, @Comment, @GroupRountingSequence)

--Add another line for 'Submitted for Approval' if the Requisition is reactivated
if @ActionType = 'ActivateRequisition'
Begin	
	--get the requistion StatusID for 'Submitted for Approval'
	select @NewStatusID = ApprovalStatusID from ApprovalStatus where StatusCode = 'Submitted'
End

--update the requisition status to reflect the new action
Update RequisitionStatus
	Set ApprovalStatusID = @NewStatusID,
	CurrentSequence = @GroupRountingSequence
Where RequisitionID = @RequisitionID

--Add another line for 'Submitted for Approval' if the Requisition is reactivated
if @ActionType = 'ActivateRequisition'
Begin	
	--get the requistion StatusID for 'Submitted for Approval'
	select @NewStatusID = ApprovalStatusID from ApprovalStatus where StatusCode = 'SubmittedForApproval'

	--Insert Requisition status detail indicating the current action
	Insert into RequisitionStatusDetail 
	(RequisitionStatusID, SubmittedDate, ApprovalGroupID, ApplicationUserID, ApprovalStatusID, 
		StatusDate, RoutingSequence, PermanentStatus, ApproverComment, GroupRountingSequence)
	Values (@RequisitionStatusID, @LastSubmittedDate, @UploaderApprovalGroupID, @ApplicationUserID, @NewStatusID,
	 	getdate(), 1, 1, '', @GroupRountingSequence)

End

return 0









