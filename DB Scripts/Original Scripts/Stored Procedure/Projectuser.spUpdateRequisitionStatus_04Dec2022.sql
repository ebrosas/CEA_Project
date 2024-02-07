USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spUpdateRequisitionStatus]    Script Date: 04/12/2022 10:37:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO











/***********************************************************************************************************
Procedure Name 	: spUpdateRequisitionStatus
Purpose		: This SP set the status of the requisition

Author		: Zaharan Haleed
Date		: 09 May 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1.

************************************************************************************************************/



ALTER       Procedure [Projectuser].[spUpdateRequisitionStatus]
	(	@RequisitionID		as int,
		@StatusCode		as varchar(50),
		@EmpNo			as int,
		@ApproverComment	as varchar(500)) --,
		--@NextSequence		as int Out )
As		

declare @StatusID 			as int
declare @CurrentSequence		as int
declare @RequisitionStatusID		as int
declare @ApplicationUserID		as int
declare @LastSubmittedDate		as datetime
declare @GroupRountingSequence		as int
declare @UploaderApprovalGroupID	as int


--get the requistion StatusID
select @StatusID = ApprovalStatusID from ApprovalStatus where StatusCode = @StatusCode

--get applicationuser id
select @ApplicationUserID = ApplicationUserID from ApplicationUser where employeeno = @EmpNo

--get the requisition status id
select @RequisitionStatusID = RequisitionStatusID from RequisitionStatus where requisitionid = @RequisitionID

--get the current sequence
Select @CurrentSequence = CurrentSequence From RequisitionStatus Where RequisitionID = @RequisitionID

--get the next sequence
--Select @NextSequence = Projectuser.GetNextSequence(@RequisitionID,@CurrentSequence)

select @LastSubmittedDate = SubmittedDate from RequisitionStatusDetail where RequisitionStatusID = @RequisitionStatusID

--get the routing sequence
select @GroupRountingSequence = max(GroupRountingSequence) from RequisitionStatusDetail where RequisitionStatusID = @RequisitionStatusID
set @GroupRountingSequence = @GroupRountingSequence + 1

--get the approvalgroup id
select top 1 @UploaderApprovalGroupID = ag.approvalGroupId from approvalgroup ag
inner join approvalgroupdetail agd on agd.approvalgrouptypeid = ag.approvalgrouptypeid
where agd.usergrouptypecode = 'uploader'



--Insert Requisition status detail statuses
Insert into RequisitionStatusDetail 
(RequisitionStatusID, SubmittedDate, ApprovalGroupID, ApplicationUserID, ApprovalStatusID, 
	StatusDate, RoutingSequence, PermanentStatus, ApproverComment, GroupRountingSequence)
Values (@RequisitionStatusID, @LastSubmittedDate, @UploaderApprovalGroupID, @ApplicationUserID, @StatusID,
 getdate(), 1, 1, @ApproverComment, @GroupRountingSequence)

--update the requisition status
Update RequisitionStatus
	Set ApprovalStatusID = @StatusID,
	CurrentSequence = @GroupRountingSequence
Where RequisitionID = @RequisitionID












