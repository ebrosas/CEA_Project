USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spConfigureRequisitionApprovers]    Script Date: 17/05/2022 12:20:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***********************************************************************************************************
Procedure Name: spConfigureRequisitionApprovers
Purpose       : This SP will configure the approvers for a Requisition

Author        : Zaharan Haleed
Date          : 25 April 2007
------------------------------------------------------------------------------------------------------------
Modification History:
    05/10/2008
    1. Set the Originator and Category approver routing sequence to 0 (zero) as they will be first in their
       groups to approve

	1.1					Ervin Brosas						03-Feb-2022 10:50 AM
	Added condition to check if Originator and Item Category Approver is null

	1.2					Ervin Brosas						17-mAY-2022 12:54 pm
	Renamed Chief Restructuring Officer to "Chied Executive Officer"
************************************************************************************************************/

ALTER PROCEDURE Projectuser.spConfigureRequisitionApprovers
(
    @RequisitionID int
)
AS
BEGIN

    DECLARE @ApprovalCostCenter varchar(12)

    SELECT @ApprovalCostCenter = RTRIM(a.CostCenter)
    FROM dbo.ApplicationUser a WITH (NOLOCK)
        INNER JOIN Requisition b WITH (NOLOCK) ON b.OriginatorEmpNo = a.EmployeeNo 
    WHERE b.RequisitionID = @RequisitionID 
		AND a.CostCenter IN ('3250', '5200', '5300', '5400')

    IF @ApprovalCostCenter IS NULL
    BEGIN

        SELECT @ApprovalCostCenter = RTRIM(a.CostCenter)
        FROM dbo.Project AS a WITH (NOLOCK)
            INNER JOIN Requisition AS b WITH (NOLOCK) ON b.ProjectNo = a.ProjectNo
         WHERE b.RequisitionID = @RequisitionID
    END

    DECLARE @RequisitionStatusID	INT,
            @InQueueID				INT

	SELECT @RequisitionStatusID = a.RequisitionStatusID 
    FROM dbo.RequisitionStatus a WITH (NOLOCK) 
    WHERE a.RequisitionID = @RequisitionID

    SELECT @InQueueID = a.ApprovalStatusID
    FROM dbo.ApprovalStatus a WITH (NOLOCK)
    WHERE RTRIM(a.StatusCode) = 'AwaitingApproval'

    INSERT INTO RequisitionStatusDetail 
	(
        RequisitionStatusID,
        SubmittedDate,
        ApprovalGroupID,
        ApplicationUserID,
        ApprovalStatusID,
        StatusDate,
        RoutingSequence,
        PermanentStatus,
        GroupRountingSequence
    )
    SELECT	@RequisitionStatusID,
			getdate(),
			a.ApprovalGroupID,
			b.ApplicationUserID,
			@InQueueID,
			null,
			b.Sequence,
			b.PermanentStatus,
			a.ApprovalSequence
	FROM dbo.ApprovalGroup as a WITH (NOLOCK),
		dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
	WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
		AND RTRIM(a.ApprovalGroup) NOT IN 
		(
			'General Manager', 
			'Chief Executive Officer', 
			'Chairman'
		) 
		AND
		(
			(
				a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
			) 
			OR
			(
				a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
				b.ApprovalGroupID = -1 AND PermanentStatus = 1
			)
		)

    DECLARE @RequestedAmt	NUMERIC(18,3),
            @ProjectType	VARCHAR(20)

    SELECT @RequestedAmt = a.RequestedAmt
    FROM dbo.Requisition a WITH (NOLOCK)
    WHERE a.RequisitionID = @RequisitionID

    SELECT @ProjectType = RTRIM(y.ProjectType)
    FROM dbo.Requisition x  WITH (NOLOCK)
		INNER JOIN dbo.Project y  WITH (NOLOCK) ON x.ProjectNo = y.ProjectNo
    WHERE x.RequisitionID = @RequisitionID

	IF @ProjectType = 'Budgeted'
	BEGIN

		IF @RequestedAmt > 20000
		BEGIN

			--Add the General Manager to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	@RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@InQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'General Manager' 
				AND
				(
					(
						a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
					) OR
					(
						a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
						b.ApprovalGroupID = -1 AND PermanentStatus = 1
					)
				)
			
			--Add the CEO to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	@RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@InQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chief Executive Officer' 
				AND
				(
					(
						a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
					) OR
					(
						a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
						b.ApprovalGroupID = -1 AND PermanentStatus = 1
					)
				)
		END

		IF @RequestedAmt > 100000
		BEGIN

			--Add the Chairman to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	@RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@InQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chairman' 
				AND
				(
					(
						a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
					) OR
					(
						a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
						b.ApprovalGroupID = -1 AND PermanentStatus = 1
					)
				)
		END
	END

	ELSE IF @ProjectType = 'NonBudgeted'
	BEGIN

		IF @RequestedAmt > 5000
		BEGIN

			--Add the General Manager to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	@RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@InQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'General Manager' 
				AND
				(
					(
						a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
					) OR
					(
						a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
						b.ApprovalGroupID = -1 AND PermanentStatus = 1
					)
				)

			--Add the CEO to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	@RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@InQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chief Executive Officer' 
				AND
				(
					(
						a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
					) OR
					(
						a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
						b.ApprovalGroupID = -1 AND PermanentStatus = 1
					)
				)
		END

		IF @RequestedAmt > 50000
		BEGIN

			--Add the Chairman to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	@RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					b.ApplicationUserID,
					@InQueueID,
					null,
					b.Sequence,
					b.PermanentStatus,
					a.ApprovalSequence
			FROM dbo.ApprovalGroup as a WITH (NOLOCK),
				dbo.ApprovalGroupAssignment AS b WITH (NOLOCK)
			WHERE RTRIM(a.CostCenter) = @ApprovalCostCenter 
				AND RTRIM(a.ApprovalGroup) = 'Chairman' 
				AND
				(
					(
						a.ApprovalGroupID = b.ApprovalGroupID AND PermanentStatus = 0
					) OR
					(
						a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
						b.ApprovalGroupID = -1 AND PermanentStatus = 1
					)
				)
		END
	END

    DECLARE @OriginatorID int

	SELECT @OriginatorID = a.ApplicationUserID
    FROM dbo.ApplicationUser AS a WITH (NOLOCK)
        INNER JOIN dbo.Requisition AS b WITH (NOLOCK) ON b.OriginatorEmpNo = a.EmployeeNo
    WHERE b.RequisitionID = @RequisitionID

	IF ISNULL(@OriginatorID, 0) > 0		--Rev. #1.1
	BEGIN
    
		IF NOT EXISTS 
		(
			SELECT RequisitionStatusDetailID
			FROM dbo.RequisitionStatusDetail a  WITH (NOLOCK)
			WHERE RequisitionStatusID = @RequisitionStatusID 
				AND ApplicationUserID = @OriginatorID
		)
		BEGIN

			--Add the Originator to the approver's list
			INSERT INTO RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID, 
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT TOP 1
				a.RequisitionStatusID,
				getdate(),
				a.ApprovalGroupID,
				@OriginatorID,
				@InQueueID,
				null,
				0,
				1,
				a.GroupRountingSequence
			FROM RequisitionStatusDetail AS a WITH (NOLOCK)
				INNER JOIN ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
				INNER JOIN ApprovalGroupType AS c WITH (NOLOCK) ON c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
			WHERE a.RequisitionStatusID = @RequisitionStatusID 
				AND RTRIM(b.CostCenter) = @ApprovalCostCenter 
				AND c.IsCostCenterSpecific = 1
		END
	END 

    DECLARE @CategoryApproverID int

	SELECT @CategoryApproverID = a.ApplicationUserID
    FROM dbo.ApplicationUser AS a WITH (NOLOCK) 
        INNER JOIN dbo.ApplicationUserRequisitionCategory AS b WITH (NOLOCK) ON b.EmployeeNo = a.EmployeeNo
        INNER JOIN dbo.Requisition AS c WITH (NOLOCK) ON RTRIM(c.CategoryCode1) = RTRIM(b.RequisitionCategoryCode)
    WHERE c.RequisitionID = @RequisitionID

	IF ISNULL(@CategoryApproverID, 0) > 0		--Rev. #1.1
	BEGIN
    
		IF NOT EXISTS 
		(
			SELECT RequisitionStatusDetailID
			FROM dbo.RequisitionStatusDetail a  WITH (NOLOCK)
			WHERE RequisitionStatusID = @RequisitionStatusID 
				AND ApplicationUserID = @CategoryApproverID
		)
		BEGIN

			DECLARE @MaxRoutingSequence int

			SELECT @MaxRoutingSequence = MAX(a.RoutingSequence) + 1
			FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
				INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
			WHERE a.RequisitionStatusID = @RequisitionStatusID 
				AND RTRIM(b.CostCenter) = @ApprovalCostCenter 
				AND b.ApprovalGroupTypeID = (
					SELECT CategoryApproverGroupTypeID
					FROM dbo.AppConfiguration WITH (NOLOCK)
				)

			--Add Item Category approver to the list
			INSERT INTO dbo.RequisitionStatusDetail 
			(
				RequisitionStatusID,
				SubmittedDate,
				ApprovalGroupID,
				ApplicationUserID,
				ApprovalStatusID,
				StatusDate,
				RoutingSequence,
				PermanentStatus,
				GroupRountingSequence
			)
			SELECT	TOP 1
					a.RequisitionStatusID,
					getdate(),
					a.ApprovalGroupID,
					@CategoryApproverID, 
					@InQueueID,
					null,
					@MaxRoutingSequence,
					1,
					a.GroupRountingSequence
			FROM dbo.RequisitionStatusDetail AS a WITH (NOLOCK)
				INNER JOIN dbo.ApprovalGroup AS b WITH (NOLOCK) ON b.ApprovalGroupID = a.ApprovalGroupID
			WHERE a.RequisitionStatusID = @RequisitionStatusID 
				AND RTRIM(b.CostCenter) = @ApprovalCostCenter 
				AND b.ApprovalGroupTypeID = (
					SELECT CategoryApproverGroupTypeID
					FROM dbo.AppConfiguration WITH (NOLOCK)
				)
		END
	END 
END
