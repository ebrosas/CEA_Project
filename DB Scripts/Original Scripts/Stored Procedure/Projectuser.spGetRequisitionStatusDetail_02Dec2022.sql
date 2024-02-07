USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spGetRequisitionStatusDetail]    Script Date: 02/12/2022 11:16:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/***********************************************************************************************************
Procedure Name: spSaveRequisition	
Purpose       : This SP will save a new Requisition or update an existing Requisition

Author        : Zaharan Haleed
Date          : 22 March 2007
************************************************************************************************************/

ALTER PROCEDURE [Projectuser].[spGetRequisitionStatusDetail] (
    @RequisitionID int
)
AS
  SELECT  AGT.ApprovalGroupType 'Approval Group',
          AU.FullName + ' | (' + ISNULL(RTRIM(Projectuser.GetEmployeeDesignation(AU.EmployeeNo)),'Designation Unknown') + ')' 'Approver',
          RSD.PermanentStatus 'Permanent',
          RSD.RoutingSequence 'Routing Seq.',
          RSD.SubmittedDate 'Submit Date',
          (SELECT ApprovalStatus FROM ApprovalStatus WHERE ApprovalStatusID = RSD.ApprovalStatusID) 'Current Status',
          RSD.StatusDate 'Approved Date',
          RSD.ApprovalGroupID,
          (SELECT CostCenter FROM ApprovalGroup WHERE ApprovalGroupID = RSD.ApprovalGroupID) 'CostCenter',
          RSD.ApproverComment 'Approval Comment',
          AG.ApprovalGroupTypeID,
          (Select StatusCode from ApprovalStatus where ApprovalStatusID = RSD.ApprovalStatusID) 'StatusCode',
          (Select CostCenterName From Projectuser.Master_CostCenter Where CostCenter = P.CostCenter) 'CostCenterName',
          R.CreateBy as 'CreatedBy',
          isnull(
          (
            SELECT CASE COUNT(*)
                       WHEN 0 THEN 'Available'
                       WHEN null THEN 'Available'
                       ELSE 'On Leave - from ' + CONVERT(varchar, yy.FromDate, 103) + ' to ' + CONVERT(varchar, yy.ToDate, 103)
                   END	
              FROM (
                     SELECT TOP 1
                            EmpNo,
                            FromDate,
                            ToDate
                       FROM Projectuser.Tran_Leave_JDE
                      WHERE EmpNo = AU.EmployeeNo AND
                            (CONVERT(varchar, GETDATE(), 110) BETWEEN FromDate AND ToDate OR FromDate BETWEEN GETDATE() AND CONVERT(varchar, GETDATE() + 3, 110))
                   ORDER BY FromDate DESC
                   ) yy
          GROUP BY EmpNo,
                   FromDate,
                   ToDate
          ), 'Available') 'LeaveStatus',
          RSD.ApplicationUserID,
          isnull(AUS.SubstituteUserID, 0) 'SubstituteUserID',
          (Select FullName from ApplicationUser where ApplicationUserID = AUS.SubstituteUserID) 'Substitute',
          (Select EmployeeNo from ApplicationUser where ApplicationUserID = AUS.SubstituteUserID) 'SubstituteEmpNo'
     FROM RequisitionStatusDetail RSD
          INNER JOIN RequisitionStatus AS RS ON
          RSD.RequisitionStatusID = RS.RequisitionStatusID
          INNER JOIN Requisition AS R ON
          R.RequisitionID = RS.RequisitionID
          INNER JOIN ApprovalGroup AS AG ON
          AG.ApprovalGroupID = RSD.ApprovalGroupID
          INNER JOIN ApprovalGroupType AS
          AGT ON AGT.ApprovalGroupTypeID = AG.ApprovalGroupTypeID
          INNER JOIN Project AS P ON
          P.ProjectNo = R.ProjectNo
          INNER JOIN ApplicationUser AS AU ON
          RSD.ApplicationUserID = AU.ApplicationUserID
          LEFT JOIN ApplicationUserSubstitute AS AUS ON
          AU.ApplicationUserID = AUS.ApplicationUserID
    WHERE RS.RequisitionID = @RequisitionID
 ORDER BY RSD.GroupRountingSequence, RSD.RoutingSequence