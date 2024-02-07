/**************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetActiveSubstitute
*	Description: Get the substitute information which was defined through the Workflow Substitute Settings form in ISMS
*
*	Date:			Author:		Helpdesk Ref#:		Comments:
*	11/09/2023		Ervin		N/A					Created

**************************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetActiveSubstitute
(
	@EmpNo				int,
	@WFObjectCode		varchar(20),
	@CostCenter			varchar(12)
)
RETURNS  @rtnTable TABLE  
(     
	SubstituteSettingID				int,
	AuthorizationTypeID				int,
	WFObjectCode					varchar(20),
	SubstituteEmpNo					int,
	SubstituteEmpName				varchar(50),
	SubstituteEmpEmail				varchar(50)
) 
AS
BEGIN

	IF ISNULL(@CostCenter, '') = ''
		SET @CostCenter = NULL

	DECLARE @myTable table
	(
		SubstituteSettingID				int,
		AuthorizationTypeID				int,
		WFObjectCode					varchar(20),
		SubstituteEmpNo					int,
		SubstituteEmpName				varchar(50),
		SubstituteEmpEmail				varchar(50)
	)  

	DECLARE	@SubstituteSettingID			int,
			@AuthorizationTypeID			int,
			@WorkFlowObjectCode				varchar(20),
			@SubstituteEmpNo				int,
			@SubstituteEmpName				varchar(50),
			@SubstituteEmpEmail				varchar(50)
		
	SELECT	@SubstituteSettingID = 0,
			@AuthorizationTypeID = 0,
			@WorkFlowObjectCode = '',
			@SubstituteEmpNo = 0,
			@SubstituteEmpName = '',
			@SubstituteEmpEmail	= ''

	--Get the current WF activity
	SELECT TOP 1 
		@SubstituteSettingID = SubstituteSettingID,
		@AuthorizationTypeID = AuthorizationTypeID,
		@WorkFlowObjectCode = WFObjectCode,
		@SubstituteEmpNo = SubstituteEmpNo,
		@SubstituteEmpName = SubstituteEmpName,
		@SubstituteEmpEmail = SubstituteEmpEmail
	FROM
	(
		--Get the active substitute filtered by Request Type
		SELECT TOP 1 
			a.SubstituteSettingID,
			b.AuthorizationTypeID,
			b.WFObjectCode,
			b.SubstituteEmpNo,
			b.SubstituteEmpName,
			b.SubstituteEmpEmail
		FROM Projectuser.sy_WFSubstituteSetting a WITH (NOLOCK)
			INNER JOIN Projectuser.sy_WFSubstituteAuthorizationSetting b WITH (NOLOCK) ON a.SubstituteSettingID = b.SubstituteSettingID
		WHERE 
			a.WFFromEmpNo = @EmpNo
			AND 
			(
				(CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 126)) BETWEEN a.EffectiveFrom AND a.EffectiveTo AND ISNULL(a.IsPermanent, 0) = 0)			
				OR (a.IsPermanent = 1)
			)
			AND RTRIM(b.WFObjectCode) = RTRIM(@WFObjectCode)
			AND b.AuthorizationTypeID = 1

		UNION 

		--Get the active substitute filtered by Cost Center
		SELECT TOP 1 
			a.SubstituteSettingID,
			b.AuthorizationTypeID,
			b.WFObjectCode,
			b.SubstituteEmpNo,
			b.SubstituteEmpName,
			b.SubstituteEmpEmail
		FROM Projectuser.sy_WFSubstituteSetting a WITH (NOLOCK)
			INNER JOIN Projectuser.sy_WFSubstituteAuthorizationSetting b WITH (NOLOCK) ON a.SubstituteSettingID = b.SubstituteSettingID
		WHERE 
			a.WFFromEmpNo = @EmpNo
			AND 
			(
				(CONVERT(DATETIME, CONVERT(VARCHAR, GETDATE(), 126)) BETWEEN a.EffectiveFrom AND a.EffectiveTo AND ISNULL(a.IsPermanent, 0) = 0)			
				OR (a.IsPermanent = 1)
			)
			AND RTRIM(b.WFObjectCode) = RTRIM(@CostCenter)
			AND b.AuthorizationTypeID = 0
	) tblMain
	ORDER BY AuthorizationTypeID DESC
	
	IF @SubstituteSettingID > 0
	BEGIN

		INSERT INTO @myTable  
		SELECT	@SubstituteSettingID,
				@AuthorizationTypeID,
				@WorkFlowObjectCode,
				@SubstituteEmpNo,
				@SubstituteEmpName,
				@SubstituteEmpEmail	

		INSERT INTO @rtnTable 
		SELECT * FROM @mytable  
	END

	RETURN 
END


/*	Debugging:
	
	SELECT * FROM Projectuser.fnGetActiveSubstitute(10003662, 'WFCEA', '')
	SELECT * FROM Projectuser.fnGetActiveSubstitute(10003838, '', '7400')
	SELECT * FROM Projectuser.fnGetActiveSubstitute(10003838, 'WFCEA', '7400')

*/
