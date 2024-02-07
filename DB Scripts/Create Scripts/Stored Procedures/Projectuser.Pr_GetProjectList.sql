/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetProject
*	Description: This stored procedure returns the list of all projects
*
*	Date			Author		Rev. #		Comments:
*	07/03/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetProjectList
(
	@fiscalYear			INT = 0,
	@projectNo			VARCHAR(12) = '',
	@costCenter			VARCHAR(12) = '',
	@expenditureType	VARCHAR(10) = '',
	@statusCode			VARCHAR(50) = '',
	@keywords			VARCHAR(50) = ''
)
AS 
BEGIN
	
	SET NOCOUNT ON 
		
	--Validate parameters
	IF ISNULL(@fiscalYear, 0) = 0
		SET @fiscalYear = NULL

	IF ISNULL(@projectNo, '') = ''
		SET @projectNo = NULL

	IF ISNULL(@costCenter, '') = ''
		SET @costCenter = NULL

	IF ISNULL(@expenditureType, '') = ''
		SET @expenditureType = NULL

	IF ISNULL(@statusCode, '') = ''
		SET @statusCode = NULL

	IF ISNULL(@keywords, '') = ''
		SET @keywords = NULL

	IF @projectNo IS NOT NULL
    BEGIN

		--Filter by Project No.
		SELECT	a.ProjectID,
			a.ProjectNo,
			a.ExpectedProjectDate AS ProjectDate,
			a.CompanyCode,
			a.CostCenter,
			a.ExpenditureType,
			a.[Description],
			a.DetailDescription,
			Projectuser.AccountNo(a.ProjectNo) AS AccountCode,
			a.ProjectType,
			a.FiscalYear,
			a.ProjectAmount,
			b.ProjectStatusID, 
			b.ProjectStatus,
			c.ApprovalStatus AS ProjectStatusDesc,
			a.CreateBy,
			a.CreateDate			
		FROM dbo.Project a WITH (NOLOCK)
			INNER JOIN dbo.ProjectStatus b WITH (NOLOCK) on a.ProjectID = b.ProjectID
			INNER JOIN dbo.ApprovalStatus c WITH (NOLOCK) ON b.ProjectStatus = c.ApprovalStatusID
		WHERE RTRIM(a.ProjectNo) = RTRIM(@projectNo)
    END
	ELSE 
	BEGIN

		SELECT	a.ProjectID,
				a.ProjectNo,
				a.ExpectedProjectDate AS ProjectDate,
				a.CompanyCode,
				a.CostCenter,
				a.ExpenditureType,
				a.[Description],
				a.DetailDescription,
				Projectuser.AccountNo(a.ProjectNo) AS AccountCode,
				a.ProjectType,
				a.FiscalYear,
				a.ProjectAmount,
				b.ProjectStatusID, 
				b.ProjectStatus,
				c.ApprovalStatus AS ProjectStatusDesc,
				a.CreateBy,
				a.CreateDate			
		FROM dbo.Project a WITH (NOLOCK)
			INNER JOIN dbo.ProjectStatus b WITH (NOLOCK) on a.ProjectID = b.ProjectID
			INNER JOIN dbo.ApprovalStatus c WITH (NOLOCK) ON b.ProjectStatus = c.ApprovalStatusID
		WHERE a.ProjectID > 0
			AND ISNULL(a.ProjectNo, '') <> ''
			AND (a.FiscalYear = @fiscalYear OR @fiscalYear IS NULL)
			AND (RTRIM(a.ProjectNo) = @projectNo OR @projectNo IS NULL)
			AND (RTRIM(a.CostCenter) = @costCenter OR @costCenter IS NULL)
			AND (RTRIM(a.ExpenditureType) = @expenditureType OR @expenditureType IS NULL)
			AND (RTRIM(c.StatusCode) = @statusCode OR @statusCode IS NULL)
			AND 
			(
				UPPER(LTRIM(RTRIM(a.[Description]))) LIKE + '%' + UPPER(@keywords) + '%'
				OR UPPER(LTRIM(RTRIM(CAST(a.DetailDescription AS VARCHAR(MAX))))) LIKE + '%' + UPPER(@keywords) + '%'
				OR @keywords IS null
			)
		ORDER BY a.ProjectNo DESC
	END 

END 


/*	Debug:

PARAMETERS:
	@fiscalYear			INT = 0,
	@projectNo			VARCHAR(12) = '',
	@costCenter			VARCHAR(12) = '',
	@expenditureType	VARCHAR(10) = '',
	@statusCode			VARCHAR(50) = '',
	@keywords			VARCHAR(50) = ''
	
	EXEC Projectuser.Pr_GetProjectList 2022, '', '7600', '', '', ''

*/
