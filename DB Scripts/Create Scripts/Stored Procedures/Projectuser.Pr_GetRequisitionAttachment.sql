/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_GetRequisitionAttachment
*	Description: This stored procedure is used to fetch the attachments for the specified CEA requisition
*
*	Date			Author		Rev. #		Comments:
*	31/05/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_GetRequisitionAttachment
(
	@requisitionNo	VARCHAR(50) = '',
	@costCenter		VARCHAR(12) = '',
	@fiscalYear		INT = 0
)
AS 
BEGIN
	
	SET NOCOUNT ON 

	--Validate parameters
	IF ISNULL(@requisitionNo, '') = ''
		SET @requisitionNo = NULL

	IF ISNULL(@costCenter, '') = ''
		SET @costCenter = NULL

	IF ISNULL(@fiscalYear, 0) = 0
		SET @fiscalYear = NULL

	SELECT	c.RequisitionAttachmentID,
			a.RequisitionNo, 
			a.RequisitionID, 
			a.FiscalYear, 
			b.CostCenter,
			c.AttachmentFileName, 
			c.AttachmentDisplayName, 
			c.AttachmentSize,
			c.CreatedByEmpNo,
			c.CreatedBy, 
			c.CreatedDate,
			c.Base64File,
			c.Base64FileExt			
	FROM dbo.Requisition a WITH (NOLOCK)
		INNER JOIN dbo.Project b WITH (NOLOCK) ON RTRIM(a.ProjectNo) = RTRIM(b.ProjectNo)
		INNER JOIN dbo.RequisitionAttachments c WITH (NOLOCK) ON a.RequisitionID = c.RequisitionID
	WHERE (RTRIM(a.RequisitionNo) = RTRIM(@requisitionNo) OR @requisitionNo IS NULL)
		AND (RTRIM(b.CostCenter) = RTRIM(@costCenter) OR @costCenter IS NULL)
		AND (b.FiscalYear = @fiscalYear OR @fiscalYear IS NULL)
	ORDER BY b.FiscalYear, b.CostCenter, a.RequisitionNo

END 

/*	Debug:

PARAMETERS:
	@requisitionNo	VARCHAR(50) = '',
	@costCenter		VARCHAR(12) = '',
	@fiscalYear		INT = 0

	EXEC Projectuser.Pr_GetRequisitionAttachment '20220030'
	EXEC Projectuser.Pr_GetRequisitionAttachment '', '7600', 0

*/