/*******************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetCostCenterEmailList
*	Description: This stored procedure is used to fetch the CEA approvers who will be notified about the completion of approval process
*
*	Date			Author		Rev. #		Comments:
*	05/09/2023		Ervin		1.0			Created
********************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetCostCenterEmailList 
(
	@ceaNo	VARCHAR(50)
)
AS 
BEGIN 

    DECLARE @originatorCostCenter	VARCHAR(12) = '',
            @projectCostCenter		VARCHAR(12) = '',
			@ceaDesc				VARCHAR(40) = ''

	SELECT	@originatorCostCenter = RTRIM(b.CostCenter),
			@projectCostCenter = RTRIM(c.CostCenter),
			@ceaDesc = RTRIM(a.RequisitionDescription)
    FROM dbo.Requisition a WITH (NOLOCK)
        INNER JOIN dbo.ApplicationUser b WITH (NOLOCK) ON a.OriginatorEmpNo = b.EmployeeNo
		INNER JOIN dbo.Project c WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(c.ProjectNo)
		INNER JOIN dbo.RequisitionStatus d WITH (NOLOCK) ON a.RequisitionID = d.RequisitionID
    WHERE RTRIM(a.RequisitionNo) = @ceaNo

	SELECT DISTINCT x.EmpNo, x.EmpName, x.EmpEmail, x.PayGrade, @ceaDesc AS CEADescription
	FROM
    (
		--Get the Originator information
		SELECT	a.OriginatorEmpNo AS EmpNo, 
				b.EmpName,
				b.EmpEmail,
				b.GradeCode AS PayGrade,
				'Originator' AS RoleType
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER JOIN Projectuser.Vw_MasterEmployeeJDE b WITH (NOLOCK) ON a.OriginatorEmpNo = b.EmpNo
		WHERE RTRIM(a.RequisitionNo) = @ceaNo

		UNION 

		--Get user who created the requisition
		SELECT	a.OriginatorEmpNo AS EmpNo, 
				b.EmpName,
				b.EmpEmail,
				b.GradeCode AS PayGrade,
				'Creator' AS RoleType
		FROM dbo.Requisition a WITH (NOLOCK)
			INNER JOIN Projectuser.Vw_MasterEmployeeJDE b WITH (NOLOCK) ON a.CreatedByEmpNo = b.EmpNo
		WHERE RTRIM(a.RequisitionNo) = @ceaNo

		UNION 

		--Get the Superintendent roles
		SELECT	CAST(f.EmployeeNo AS INT) AS EmpNo, 
				g.EmpName, 
				g.EmpEmail,
				g.GradeCode AS PayGrade,
				e.ApprovalGroupType AS RoleType
		FROM dbo.Requisition a WITH (NOLOCK)
			Inner Join dbo.RequisitionStatus b WITH (NOLOCK) on a.RequisitionID = b.RequisitionID
			Inner Join dbo.RequisitionStatusDetail c WITH (NOLOCK) on b.RequisitionStatusID = c.RequisitionStatusID
			Inner Join dbo.ApprovalGroup d WITH (NOLOCK) on c.ApprovalGroupID = d.ApprovalGroupID
			Inner Join dbo.ApprovalGroupType e WITH (NOLOCK) on e.ApprovalGroupTypeID = d.ApprovalGroupTypeID
			INNER JOIN dbo.ApplicationUser f WITH (NOLOCK) ON c.ApplicationUserID = f.ApplicationUserID
			INNER JOIN Projectuser.Vw_MasterEmployeeJDE g WITH (NOLOCK) ON f.EmployeeNo = g.EmpNo
		WHERE RTRIM(a.RequisitionNo) = @ceaNo
			AND e.IsCostCenterSpecific = 1

		 UNION

		--Get all other approvers
		SELECT b.EmpNo, b.EmpName, b.EmpEmail, b.GradeCode AS PayGrade, 'Executives' AS RoleType
		FROM dbo.ApprovalGroup a WITH (NOLOCK)
			CROSS APPLY
			(
				SELECT CAST(y.EmployeeNo AS INT) AS EmpNo, z.EmpName, z.EmpEmail, z.GradeCode 
				FROM dbo.ApprovalGroupAssignment x WITH (NOLOCK) 
					INNER JOIN dbo.ApplicationUser y WITH (NOLOCK) ON x.ApplicationUserID = y.ApplicationUserID
					INNER JOIN Projectuser.Vw_MasterEmployeeJDE z WITH (NOLOCK) ON y.EmployeeNo = z.EmpNo
				WHERE x.ApprovalGroupID = a.ApprovalGroupID 
			) b
		WHERE RTRIM(a.CostCenter) = @projectCostCenter 
			AND RTRIM(a.ApprovalGroup) NOT IN ('Executive Manager – Finance', 'Chief Executive Officer', 'Chairman', 'General Manager') 
			AND @projectCostCenter <> @originatorCostCenter 
			AND @originatorCostCenter IN ('5200', '5300', '5400', '3250')
	) x
	ORDER BY x.PayGrade ASC
END 	


/*	Debug:

	EXEC Projectuser.Pr_GetCostCenterEmailList '20210029'

*/