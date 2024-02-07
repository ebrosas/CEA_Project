/*****************************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.Pr_SearchEquipment
*	Description: This stored procedure is used to search for equipments
*
*	Date			Author		Rev. #		Comments:
*	18/06/2023		Ervin		1.0			Created
******************************************************************************************************************************************************************************/

ALTER PROCEDURE Projectuser.Pr_SearchEquipment
(
	@equipmentNo	VARCHAR(12) = '',
	@equipmentDesc	VARCHAR(30) = ''
)
AS
BEGIN
	
	SET NOCOUNT ON 
		
	IF ISNULL(@equipmentNo, '') = ''
		SET @equipmentNo = NULL 

	IF ISNULL(@equipmentDesc, '') = ''
		SET @equipmentDesc = NULL 

	SELECT TOP 1000 * FROM
    (
		SELECT	RTRIM(a.EquipmentNo) AS EquipmentNo,
				RTRIM(a.[Description]) AS EquipmentDesc,
				RTRIM(a.EquipmentNo) AS ParentEquipmentNo,
				RTRIM(a.[Description]) AS ParentEquipmentDesc
		FROM Projectuser.Master_EquipmentNumber a WITH (NOLOCK)
		WHERE a.ParentEquipmentID NOT IN (SELECT EquipmentID FROM Projectuser.Master_EquipmentNumber WITH (NOLOCK))

		UNION 

		SELECT	DISTINCT
				RTRIM(a.EquipmentNo) AS EquipmentNo,
				RTRIM(a.[Description]) AS EquipmentDesc,
				RTRIM(b.EquipmentNo) AS ParentEquipmentNo,
				RTRIM(b.[Description]) AS ParentEquipmentDesc
		FROM Projectuser.Master_EquipmentNumber a WITH (NOLOCK)
			OUTER APPLY 
			(
				SELECT * FROM Projectuser.Master_EquipmentNumber WITH (NOLOCK)
				WHERE EquipmentID = a.ParentEquipmentID
			) b
		WHERE  a.ParentEquipmentID = b.EquipmentID  
	) x
	WHERE (RTRIM(x.EquipmentNo) = @equipmentNo OR @equipmentNo IS NULL)
		AND (UPPER(RTRIM(x.EquipmentDesc)) LIKE '%' + UPPER(@equipmentDesc) + '%' OR @equipmentDesc IS NULL)
	ORDER BY x.EquipmentDesc

END 

/*	Debug:

PARAMETERS:
	@equipmentNo	VARCHAR(12) = '',
	@equipmentDesc	VARCHAR(30) = ''

	EXEC Projectuser.Pr_SearchEquipment
	EXEC Projectuser.Pr_SearchEquipment 'COM00011'
	EXEC Projectuser.Pr_SearchEquipment '', 'dell'

*/