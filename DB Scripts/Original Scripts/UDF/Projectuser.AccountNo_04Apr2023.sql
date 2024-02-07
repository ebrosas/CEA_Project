USE [ProjectRequisition]
GO

/****** Object:  UserDefinedFunction [Projectuser].[AccountNo]    Script Date: 04/04/2023 03:05:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








ALTER    FUNCTION [Projectuser].[AccountNo](@ProjectNo AS VARCHAR(50))
RETURNS VARCHAR(50)

BEGIN

DECLARE @AccountID 		AS VARCHAR(50)
DECLARE @AccountNo 		AS VARCHAR(50)

--get the requested amounts
SELECT @AccountID = AccountID
FROM Project
WHERE ProjectNo = @ProjectNo

SELECT @AccountNo = LTRIM(RTRIM(CostCenter)) + '.' + LTRIM(RTRIM(ObjectAccount)) + '.' + LTRIM(RTRIM(SujectAccount))
FROM Projectuser.Master_AccountID
WHERE AccountID = @AccountID

RETURN @AccountNo

END







GO


