
	BEGIN TRAN T1

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICADMIN'
	WHERE RTRIM(RequisitionCategoryCode) = 'ADMIN'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICCIVIL'
	WHERE RTRIM(RequisitionCategoryCode) = 'CIVIL'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICELECTRL'
	WHERE RTRIM(RequisitionCategoryCode) = 'ELECTRICAL'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICFURNITRE'
	WHERE RTRIM(RequisitionCategoryCode) = 'FURNITURE'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICHR'
	WHERE RTRIM(RequisitionCategoryCode) = 'HR'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICICT'
	WHERE RTRIM(RequisitionCategoryCode) = 'ICT'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICMAINTAIN'
	WHERE RTRIM(RequisitionCategoryCode) = 'MAINTAIN'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICMECHANCL'
	WHERE RTRIM(RequisitionCategoryCode) = 'MECHANICAL'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICMEDICAL'
	WHERE RTRIM(RequisitionCategoryCode) = 'MEDICAL'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICOFFICE'
	WHERE RTRIM(RequisitionCategoryCode) = 'OFFICEEQIP'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICPROJECT'
	WHERE RTRIM(RequisitionCategoryCode) = 'PRODUCTION'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICPROJECT'
	WHERE RTRIM(RequisitionCategoryCode) = 'PROJECT'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICQUALITY'
	WHERE RTRIM(RequisitionCategoryCode) = 'QUALITY'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICSAFETY'
	WHERE RTRIM(RequisitionCategoryCode) = 'SAFETY'

	UPDATE dbo.ApplicationUserRequisitionCategory
	SET DistGroupCode = 'ICTRANSPRT'
	WHERE RTRIM(RequisitionCategoryCode) = 'TRANSPORT'

	ROLLBACK TRAN T1
	COMMIT TRAN T1


/*	Debug:

	SELECT * FROM dbo.ApplicationUserRequisitionCategory a WITH (NOLOCK)
	ORDER BY a.RequisitionCategoryCode

	SELECT * FROM dbo.RequisitionCategory a

*/