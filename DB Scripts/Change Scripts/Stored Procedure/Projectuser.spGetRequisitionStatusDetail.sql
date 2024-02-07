/******************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.spGetRequisitionStatusDetail 
*	Description: his SP will save a new Requisition or update an existing Requisition
*
*	Date:			Author:		Rev.#:		Comments:
*	22/03/2007		Zaharan		1.0			Created
*	02/12/2022		Ervin		1.1			Fixed the bug wherein the cancelled status is not shown in the approval history
*******************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.spGetRequisitionStatusDetail 
(
    @RequisitionID  INT
)
AS
BEGIN

	SET NOCOUNT ON 

	SELECT  DISTINCT 
			e.ApprovalGroupType 'Approval Group',
			g.FullName + ' | (' + ISNULL(RTRIM(Projectuser.GetEmployeeDesignation(g.EmployeeNo)),'Designation Unknown') + ')' 'Approver',
			a.PermanentStatus 'Permanent',
			a.RoutingSequence 'Routing Seq.',
			a.SubmittedDate 'Submit Date',
			(SELECT ApprovalStatus FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE ApprovalStatusID = a.ApprovalStatusID) 'Current Status',
			a.StatusDate 'Approved Date',
			a.ApprovalGroupID,
			(SELECT RTRIM(CostCenter) FROM dbo.ApprovalGroup WITH (NOLOCK) WHERE ApprovalGroupID = a.ApprovalGroupID) 'CostCenter',
			a.ApproverComment 'Approval Comment',
			d.ApprovalGroupTypeID,
			(SELECT RTRIM(StatusCode) FROM dbo.ApprovalStatus WITH (NOLOCK) WHERE ApprovalStatusID = a.ApprovalStatusID) 'StatusCode',
			(SELECT RTRIM(CostCenterName) FROM Projectuser.Master_CostCenter WITH (NOLOCK) WHERE RTRIM(CostCenter) = RTRIM(f.CostCenter)) 'CostCenterName',
			c.CreateBy AS 'CreatedBy',
			ISNULL(
			(
			SELECT CASE COUNT(*)
						WHEN 0 THEN 'Available'
						WHEN NULL THEN 'Available'
						ELSE 'On Leave - from ' + CONVERT(VARCHAR, yy.FromDate, 103) + ' to ' + CONVERT(VARCHAR, yy.ToDate, 103)
					END	
				FROM (
						SELECT TOP 1
							EmpNo,
							FromDate,
							ToDate
						FROM Projectuser.Tran_Leave_JDE WITH (NOLOCK)
						WHERE EmpNo = g.EmployeeNo AND
							(CONVERT(VARCHAR, GETDATE(), 110) BETWEEN FromDate AND ToDate OR FromDate BETWEEN GETDATE() AND CONVERT(VARCHAR, GETDATE() + 3, 110))
					ORDER BY FromDate DESC
					) yy
			GROUP BY EmpNo,
					FromDate,
					ToDate
			), 'Available') 'LeaveStatus',
			a.ApplicationUserID,
			ISNULL(h.SubstituteUserID, 0) 'SubstituteUserID',
			(SELECT RTRIM(FullName) FROM dbo.ApplicationUser WITH (NOLOCK) WHERE ApplicationUserID = h.SubstituteUserID) 'Substitute',
			(SELECT EmployeeNo FROM dbo.ApplicationUser WITH (NOLOCK) WHERE ApplicationUserID = h.SubstituteUserID) 'SubstituteEmpNo',
			a.GroupRountingSequence
     FROM 
		(
			SELECT	a.PermanentStatus,
					a.RoutingSequence,
					a.SubmittedDate,
					a.ApprovalStatusID,
					a.StatusDate,
					a.ApprovalGroupID,
					a.ApproverComment,
					a.ApplicationUserID,
					a.RequisitionStatusID,
					a.GroupRountingSequence
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = 
				(
					SELECT RequisitionStatusID
					FROM dbo.RequisitionStatus WITH (NOLOCK)
					WHERE RequisitionID = @RequisitionID 
				)
				AND a.ApprovalStatusID <> 10

			UNION 	

			SELECT TOP 1 
				a.PermanentStatus,
				a.RoutingSequence,
				a.SubmittedDate,
				a.ApprovalStatusID,
				a.StatusDate,
				a.ApprovalGroupID,
				a.ApproverComment,
				a.ApplicationUserID,
				a.RequisitionStatusID,
				--a.GroupRountingSequence
				CASE WHEN a.GroupRountingSequence < 0 
					THEN (SELECT MAX(GroupRountingSequence) + 1 FROM dbo.RequisitionStatusDetail WITH (NOLOCK) WHERE RequisitionStatusID = a.RequisitionStatusID ) 
					ELSE a.GroupRountingSequence 
				END AS GroupRountingSequence		--Note: Display the Cancelled state always at the last row
			FROM dbo.RequisitionStatusDetail a WITH (NOLOCK)
			WHERE a.RequisitionStatusID = 
				(
					SELECT RequisitionStatusID
					FROM dbo.RequisitionStatus WITH (NOLOCK)
					WHERE RequisitionID = @RequisitionID	
				)
				AND a.ApprovalStatusID = 10
			ORDER BY a.StatusDate DESC
		) a
        INNER JOIN dbo.RequisitionStatus b WITH (NOLOCK) ON a.RequisitionStatusID = b.RequisitionStatusID
        INNER JOIN dbo.Requisition c WITH (NOLOCK) ON c.RequisitionID = b.RequisitionID
        LEFT JOIN dbo.ApprovalGroup d WITH (NOLOCK) ON d.ApprovalGroupID = a.ApprovalGroupID
        LEFT JOIN dbo.ApprovalGroupType e WITH (NOLOCK) ON e.ApprovalGroupTypeID = d.ApprovalGroupTypeID
        INNER JOIN dbo.Project f WITH (NOLOCK) ON RTRIM(f.ProjectNo) = RTRIM(c.ProjectNo)
        INNER JOIN dbo.ApplicationUser g WITH (NOLOCK) ON a.ApplicationUserID = g.ApplicationUserID
        LEFT JOIN dbo.ApplicationUserSubstitute h WITH (NOLOCK) ON g.ApplicationUserID = h.ApplicationUserID
    WHERE b.RequisitionID = @RequisitionID
	ORDER BY a.GroupRountingSequence, a.RoutingSequence

	/*	Old code:

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
	*/

END

/*	Debug:

	EXEC Projectuser.spGetRequisitionStatusDetail  4127

*/