USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spApproveRequisition]    Script Date: 07/09/2023 10:10:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
/***********************************************************************************************************
Procedure Name: spApproveRequisition
Purpose       : This SP will approve a requisition

Author        : Zaharan Haleed
Date          : 30 May 2007
------------------------------------------------------------------------------------------------------------
Modification History:
    05/10/2008
    1. Made the approval sequential: Added sequential checkings
************************************************************************************************************/

ALTER PROCEDURE [Projectuser].[spApproveRequisition] (
    @RequisitionID    int,
    @EmployeeNo       int,
    @StatusCode       varchar(50),
    @ApprovalComments varchar(512),
    @NextSequence     int OUTPUT
)
AS
    DECLARE @RequisitionStatusDetailID numeric,
            @RequisitionStatusID       numeric,
            @ApplicationUserID         int,
            @SubmittedForApprovalID    int,
            @ApprovalStatusID          numeric

     SELECT @RequisitionStatusID = RequisitionStatusID
       FROM RequisitionStatus
      WHERE RequisitionID = @RequisitionID

     SELECT @ApplicationUserID = ApplicationUserID
       FROM ApplicationUser
      WHERE EmployeeNo = @EmployeeNo

     SELECT @SubmittedForApprovalID = ApprovalStatusID
       FROM ApprovalStatus
      WHERE StatusCode = 'SubmittedForApproval'

     SELECT @RequisitionStatusDetailID = RequisitionStatusDetailID
       FROM RequisitionStatusDetail
      WHERE RequisitionStatusID = @RequisitionStatusID AND
            ApplicationUserID   = @ApplicationUserID AND
            ApprovalStatusID    = @SubmittedForApprovalID

     SELECT @ApprovalStatusID = ApprovalStatusID
       FROM ApprovalStatus
      WHERE StatusCode = @StatusCode

    DECLARE @AwaitingChairmanApprovalID  numeric

    IF @RequisitionStatusDetailID IS NOT NULL
    BEGIN
        UPDATE RequisitionStatusDetail
           SET ApprovalStatusID = @ApprovalStatusID,
               ApproverComment  = @ApprovalComments,
               StatusDate       = GETDATE()
         WHERE @RequisitionStatusDetailID = RequisitionStatusDetailID
    END

    ELSE
    BEGIN
        DECLARE @RequisitionApprovalStatusID numeric

         SELECT @RequisitionApprovalStatusID = ApprovalStatusID
           FROM RequisitionStatus
          WHERE RequisitionID = @RequisitionID

         SELECT @AwaitingChairmanApprovalID = ApprovalStatusID
           FROM ApprovalStatus
          WHERE StatusCode = 'AwaitingChairmanApproval'

        IF @RequisitionApprovalStatusID = @AwaitingChairmanApprovalID
        BEGIN
            SELECT @ApplicationUserID = a.ApplicationUserID
              FROM dbo.ApprovalGroupAssignment AS a
                   INNER JOIN ApprovalGroupType AS b ON
                   a.ApprovalGroupTypeID = b.ApprovalGroupTypeID
             WHERE b.ApprovalGroupType = 'Chairman'
        END

        ELSE
        BEGIN
            SELECT @ApplicationUserID = b.ApplicationUserID
              FROM RequisitionStatusDetail AS a
                   INNER JOIN ApplicationUser b ON
                   b.ApplicationUserID = a.ApplicationUserID
                   LEFT JOIN Gen_Purpose.genuser.fnGetActiveSubstitutes('WFCEA', '') AS c ON
                   c.WFFromEmpNo = b.EmployeeNo
                   LEFT JOIN Projectuser.syLeaveRequisition AS d ON
                   d.EmpNo = b.EmployeeNo AND
                   RTRIM(d.LeaveType) = 'AL' AND
                   RTRIM(d.RequestStatusSpecialHandlingCode) = 'Closed' AND
                   CONVERT(datetime, CONVERT(varchar, GETDATE(), 126)) BETWEEN d.ActualLeaveStartDate AND d.ActualLeaveReturnDate - 1
             WHERE a.RequisitionStatusID    = @RequisitionStatusID AND
                   a.ApprovalStatusID = @SubmittedForApprovalID AND
                   (
                       c.SubstituteEmpNo IS NOT NULL OR
                       d.SubEmpNo IS NOT NULL
                   ) AND
                   ISNULL(c.SubstituteEmpNo, d.SubEmpNo) = @EmployeeNo
        END

        UPDATE RequisitionStatusDetail
           SET ApprovalStatusID = @ApprovalStatusID,
               ApproverComment  = @ApprovalComments,
               StatusDate       = GETDATE()
         WHERE RequisitionStatusID = @RequisitionStatusID AND
               ApplicationUserID   = @ApplicationUserID AND
               ApprovalStatusID    = @SubmittedForApprovalID
    END
    
    IF @StatusCode = 'Rejected'
    BEGIN
       DECLARE @RequestedAmt numeric(18,3)

        SELECT @RequestedAmt = RequestedAmt
          FROM Requisition
         WHERE RequisitionID = @RequisitionID

        UPDATE RequisitionStatus
           SET ApprovalStatusID = @ApprovalStatusID,
               Description      = CONVERT(varchar, @RequestedAmt) + 'BD requisition is rejected.',
               LastUdatedDate   = GETDATE()
         WHERE RequisitionID = @RequisitionID

       DECLARE @RequisitionNo varchar(12)

        SELECT @RequisitionNo = RequisitionNo
          FROM Requisition
         WHERE RequisitionID = @RequisitionID

        UPDATE Projectuser.F0101
           SET ABAT1 = 'JR'
         WHERE ABAN8 = @RequisitionNo

        SELECT @NextSequence = -3
    END

    ELSE
    BEGIN
        DECLARE @InQueueID         int

         SELECT @InQueueID = ApprovalStatusID
           FROM ApprovalStatus
          WHERE StatusCode = 'AwaitingApproval'

        IF NOT EXISTS (
           SELECT RequisitionStatusDetailID
             FROM RequisitionStatusDetail
            WHERE RequisitionStatusID   = @RequisitionStatusID AND
                  ApprovalStatusID      = @InQueueID
           )
        BEGIN
            UPDATE RequisitionStatus
               SET ApprovalStatusID = @ApprovalStatusID,
                   LastUdatedDate   = GETDATE()
             WHERE RequisitionID = @RequisitionID

               SET @NextSequence = -2
        END

        ELSE
        BEGIN
            DECLARE @CurrentSequence int

             SELECT @CurrentSequence = CurrentSequence 
               FROM RequisitionStatus
              WHERE RequisitionID = @RequisitionID

            IF NOT EXISTS (
               SELECT RequisitionStatusDetailID
                 FROM RequisitionStatusDetail
                WHERE RequisitionStatusID   = @RequisitionStatusID AND
                      ApprovalStatusID      = @InQueueID AND
                      GroupRountingSequence = @CurrentSequence
               )
            BEGIN
                    SET @NextSequence = Projectuser.GetNextSequence(@RequisitionID, @CurrentSequence)

                DECLARE @ApprovalGroup          varchar(100),
                        @AwaitingCEOApprovalID  int,
                        @SubmittedID            int

                 SELECT TOP 1
                        @ApprovalGroup = b.ApprovalGroup
                   FROM RequisitionStatusDetail AS a
                        INNER JOIN ApprovalGroup AS b ON
                        b.ApprovalGroupID = a.ApprovalGroupID
                  WHERE a.RequisitionStatusID = @RequisitionStatusID and
                        a.GroupRountingSequence = @NextSequence

                IF @AwaitingChairmanApprovalID IS NULL
                    SELECT @AwaitingChairmanApprovalID = ApprovalStatusID
                      FROM ApprovalStatus
                     WHERE StatusCode = 'AwaitingChairmanApproval'

                 SELECT @AwaitingCEOApprovalID = ApprovalStatusID
                   FROM ApprovalStatus
                  WHERE StatusCode = 'AwaitingCEOApproval'

                 SELECT @SubmittedID = ApprovalStatusID
                   FROM ApprovalStatus
                  WHERE StatusCode = 'Submitted'

                 UPDATE RequisitionStatus
                    SET CurrentSequence = @NextSequence,
                        ApprovalStatusID = (
                        CASE
                            WHEN @ApprovalGroup = 'Chairman' THEN @AwaitingChairmanApprovalID
                            WHEN @ApprovalGroup = 'CEO' THEN @AwaitingCEOApprovalID
                            ELSE @SubmittedID
                        END
                        )
                  WHERE RequisitionStatusID = @RequisitionStatusID
            END

            ELSE
            BEGIN
                SET @NextSequence = @CurrentSequence
            END
        END
    END