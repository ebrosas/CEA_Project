DECLARE	@ceaNo	VARCHAR(50) = '20230057'

	DECLARE @requisitionID	INT = 0

	SELECT @requisitionID = a.RequisitionID 
	FROM dbo.Requisition a WITH (NOLOCK)
	WHERE RTRIM(a.RequisitionNo) = @ceaNo

	SELECT b.CostCenter, a.OriginatorEmpNo, a.CreatedByEmpNo, a.* 
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
	WHERE RTRIM(a.RequisitionNo) = @ceaNo

	--Email to be sent for Administrative Task
	EXEC [Projectuser].[spGetCEAAdministratorEmailList] @requisitionID, 'Uploader'

	--Email to be sent to all approvers of the CEA
	EXEC Projectuser.spGetCostCenterEmailList @requisitionID