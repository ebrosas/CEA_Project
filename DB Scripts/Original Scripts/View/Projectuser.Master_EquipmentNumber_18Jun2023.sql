USE [ProjectRequisition]
GO

/****** Object:  View [Projectuser].[Master_EquipmentNumber]    Script Date: 18/06/2023 05:02:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO







ALTER         VIEW [Projectuser].[Master_EquipmentNumber]
-- F1201
-- select * from Master_EquipmentNumber
AS
SELECT  FANUMB 'EquipmentID', FAAPID 'EquipmentNo',FAAAID 'ParentEquipmentID', FADL01 'Description'
FROM  JDE_PRODUCTION.PRODDTA.F1201 WHERE FAEQST <> 'R'






GO


