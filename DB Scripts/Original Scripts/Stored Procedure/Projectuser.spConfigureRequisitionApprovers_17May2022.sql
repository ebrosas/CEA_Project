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
************************************************************************************************************/

ALTER PROCEDURE [Projectuser].[spConfigureRequisitionApprovers] 
(
    @RequisitionID int
)
AS
    DECLARE @ApprovalCostCenter varchar(12)

     SELECT @ApprovalCostCenter = a.CostCenter
       FROM ApplicationUser AS a
            INNER JOIN Requisition AS b ON
            b.OriginatorEmpNo = a.EmployeeNo 
      WHERE b.RequisitionID = @RequisitionID AND
            a.CostCenter IN ('3250', '5200', '5300', '5400')

    IF @ApprovalCostCenter IS NULL
    BEGIN
        SELECT @ApprovalCostCenter = a.CostCenter
          FROM Project AS a
               INNER JOIN Requisition AS b ON
               b.ProjectNo = a.ProjectNo
         WHERE b.RequisitionID = @RequisitionID
    END

    DECLARE @RequisitionStatusID int,
            @InQueueID           int

     SELECT @RequisitionStatusID = RequisitionStatusID 
       FROM RequisitionStatus 
      WHERE RequisitionID = @RequisitionID

     SELECT @InQueueID = ApprovalStatusID
       FROM ApprovalStatus
      WHERE StatusCode = 'AwaitingApproval'

    INSERT INTO RequisitionStatusDetail (
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
         SELECT @RequisitionStatusID,
                getdate(),
                a.ApprovalGroupID,
                b.ApplicationUserID,
                @InQueueID,
                null,
                b.Sequence,
                b.PermanentStatus,
                a.ApprovalSequence
           FROM dbo.ApprovalGroup as a,
                dbo.ApprovalGroupAssignment AS b
          WHERE a.CostCenter = @ApprovalCostCenter AND
                a.ApprovalGroup NOT IN ('General Manager', 'Chief Restructuring Officer', 'Chairman') AND
                (
                    (
                        a.ApprovalGroupID = b.ApprovalGroupID AND
                        PermanentStatus = 0
                    ) OR
                    (
                        a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
                        b.ApprovalGroupID = -1 AND
                        PermanentStatus = 1
                    )
                )

    DECLARE @RequestedAmt numeric(18,3),
            @ProjectType  varchar(20)

     SELECT @RequestedAmt = RequestedAmt
       FROM Requisition
      WHERE RequisitionID = @RequisitionID

     SELECT @ProjectType = y.ProjectType
       FROM Requisition x inner join Project y ON
            x.ProjectNo = y.ProjectNo
      WHERE x.RequisitionID = @RequisitionID

	IF @ProjectType = 'Budgeted'
	BEGIN
		IF @RequestedAmt > 20000
		BEGIN
			INSERT INTO RequisitionStatusDetail (
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
					SELECT @RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						b.ApplicationUserID,
						@InQueueID,
						null,
						b.Sequence,
						b.PermanentStatus,
						a.ApprovalSequence
					FROM dbo.ApprovalGroup as a,
						dbo.ApprovalGroupAssignment AS b
					WHERE a.CostCenter = @ApprovalCostCenter AND
						a.ApprovalGroup = 'General Manager' AND
						(
							(
								a.ApprovalGroupID = b.ApprovalGroupID AND
								PermanentStatus = 0
							) OR
							(
								a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
								b.ApprovalGroupID = -1 AND
								PermanentStatus = 1
							)
						)

			INSERT INTO RequisitionStatusDetail (
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
					SELECT @RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						b.ApplicationUserID,
						@InQueueID,
						null,
						b.Sequence,
						b.PermanentStatus,
						a.ApprovalSequence
					FROM dbo.ApprovalGroup as a,
						dbo.ApprovalGroupAssignment AS b
					WHERE a.CostCenter = @ApprovalCostCenter AND
						a.ApprovalGroup = 'Chief Restructuring Officer' AND
						(
							(
								a.ApprovalGroupID = b.ApprovalGroupID AND
								PermanentStatus = 0
							) OR
							(
								a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
								b.ApprovalGroupID = -1 AND
								PermanentStatus = 1
							)
						)
		END

		IF @RequestedAmt > 100000
		BEGIN
			INSERT INTO RequisitionStatusDetail (
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
				 SELECT @RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						b.ApplicationUserID,
						@InQueueID,
						null,
						b.Sequence,
						b.PermanentStatus,
						a.ApprovalSequence
				   FROM dbo.ApprovalGroup as a,
						dbo.ApprovalGroupAssignment AS b
				  WHERE a.CostCenter = @ApprovalCostCenter AND
						a.ApprovalGroup = 'Chairman' AND
						(
							(
								a.ApprovalGroupID = b.ApprovalGroupID AND
								PermanentStatus = 0
							) OR
							(
								a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
								b.ApprovalGroupID = -1 AND
								PermanentStatus = 1
							)
						)
		END
	END

	IF @ProjectType = 'NonBudgeted'
	BEGIN
		IF @RequestedAmt > 5000
		BEGIN
			INSERT INTO RequisitionStatusDetail (
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
					SELECT @RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						b.ApplicationUserID,
						@InQueueID,
						null,
						b.Sequence,
						b.PermanentStatus,
						a.ApprovalSequence
					FROM dbo.ApprovalGroup as a,
						dbo.ApprovalGroupAssignment AS b
					WHERE a.CostCenter = @ApprovalCostCenter AND
						a.ApprovalGroup = 'General Manager' AND
						(
							(
								a.ApprovalGroupID = b.ApprovalGroupID AND
								PermanentStatus = 0
							) OR
							(
								a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
								b.ApprovalGroupID = -1 AND
								PermanentStatus = 1
							)
						)

			INSERT INTO RequisitionStatusDetail (
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
					SELECT @RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						b.ApplicationUserID,
						@InQueueID,
						null,
						b.Sequence,
						b.PermanentStatus,
						a.ApprovalSequence
					FROM dbo.ApprovalGroup as a,
						dbo.ApprovalGroupAssignment AS b
					WHERE a.CostCenter = @ApprovalCostCenter AND
						a.ApprovalGroup = 'Chief Restructuring Officer' AND
						(
							(
								a.ApprovalGroupID = b.ApprovalGroupID AND
								PermanentStatus = 0
							) OR
							(
								a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
								b.ApprovalGroupID = -1 AND
								PermanentStatus = 1
							)
						)
		END

		IF @RequestedAmt > 50000
		BEGIN
			INSERT INTO RequisitionStatusDetail (
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
				 SELECT @RequisitionStatusID,
						getdate(),
						a.ApprovalGroupID,
						b.ApplicationUserID,
						@InQueueID,
						null,
						b.Sequence,
						b.PermanentStatus,
						a.ApprovalSequence
				   FROM dbo.ApprovalGroup as a,
						dbo.ApprovalGroupAssignment AS b
				  WHERE a.CostCenter = @ApprovalCostCenter AND
						a.ApprovalGroup = 'Chairman' AND
						(
							(
								a.ApprovalGroupID = b.ApprovalGroupID AND
								PermanentStatus = 0
							) OR
							(
								a.ApprovalGroupTypeID = b.ApprovalGroupTypeID AND
								b.ApprovalGroupID = -1 AND
								PermanentStatus = 1
							)
						)
		END
	END

    DECLARE @OriginatorID int

     SELECT @OriginatorID = a.ApplicationUserID
       FROM ApplicationUser AS a
            INNER JOIN Requisition AS b ON
            b.OriginatorEmpNo = a.EmployeeNo
      WHERE b.RequisitionID = @RequisitionID

	IF ISNULL(@OriginatorID, 0) > 0		--Rev. #1.1
	BEGIN
    
		IF NOT EXISTS (
		   SELECT RequisitionStatusDetailID
			 FROM RequisitionStatusDetail
			WHERE RequisitionStatusID = @RequisitionStatusID AND
				  ApplicationUserID = @OriginatorID
		   )
		BEGIN
			INSERT INTO RequisitionStatusDetail (
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
				   FROM RequisitionStatusDetail AS a
						INNER JOIN ApprovalGroup AS b ON
						b.ApprovalGroupID = a.ApprovalGroupID
						INNER JOIN ApprovalGroupType AS c ON
						c.ApprovalGroupTypeID = b.ApprovalGroupTypeID
				  WHERE a.RequisitionStatusID = @RequisitionStatusID AND
						b.CostCenter = @ApprovalCostCenter AND
						c.IsCostCenterSpecific = 1
		END
	END 

    DECLARE @CategoryApproverID int

     SELECT @CategoryApproverID = a.ApplicationUserID
       FROM ApplicationUser AS a 
            INNER JOIN ApplicationUserRequisitionCategory AS b ON
            b.EmployeeNo = a.EmployeeNo
            INNER JOIN Requisition AS c ON
            c.CategoryCode1 = b.RequisitionCategoryCode
      WHERE c.RequisitionID = @RequisitionID

	IF ISNULL(@CategoryApproverID, 0) > 0		--Rev. #1.1
	BEGIN
    
		IF NOT EXISTS (
		   SELECT RequisitionStatusDetailID
			 FROM RequisitionStatusDetail
			WHERE RequisitionStatusID = @RequisitionStatusID AND
				  ApplicationUserID = @CategoryApproverID
		   )
		BEGIN
				DECLARE @MaxRoutingSequence int

				 SELECT @MaxRoutingSequence = MAX(a.RoutingSequence) + 1
				   FROM RequisitionStatusDetail AS a
						INNER JOIN ApprovalGroup AS b ON
						b.ApprovalGroupID = a.ApprovalGroupID
				  WHERE a.RequisitionStatusID = @RequisitionStatusID AND
						b.CostCenter = @ApprovalCostCenter AND
						b.ApprovalGroupTypeID = (
							SELECT CategoryApproverGroupTypeID
							  FROM AppConfiguration
						)

			INSERT INTO RequisitionStatusDetail (
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
						@CategoryApproverID, 
						@InQueueID,
						null,
						@MaxRoutingSequence,
						1,
						a.GroupRountingSequence
				   FROM RequisitionStatusDetail AS a
						INNER JOIN ApprovalGroup AS b ON
						b.ApprovalGroupID = a.ApprovalGroupID
				  WHERE a.RequisitionStatusID = @RequisitionStatusID AND
						b.CostCenter = @ApprovalCostCenter AND
						b.ApprovalGroupTypeID = (
							SELECT CategoryApproverGroupTypeID
							  FROM AppConfiguration
						)
		END
	END 
