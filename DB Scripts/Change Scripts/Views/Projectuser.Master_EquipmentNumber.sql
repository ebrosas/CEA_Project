ALTER VIEW Projectuser.Master_EquipmentNumber
AS

	SELECT  FANUMB 'EquipmentID', 
			FAAPID 'EquipmentNo',
			FAAAID 'ParentEquipmentID', 
			FADL01 'Description'
	FROM JDE_PRODUCTION.PRODDTA.F1201 a WITH (NOLOCK)
	WHERE FAEQST <> 'R'

GO


